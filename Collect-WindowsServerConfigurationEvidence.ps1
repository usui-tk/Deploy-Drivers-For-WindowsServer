#Requires -Version 5.1
<#
.SYNOPSIS
    Collects read-only Windows Server configuration evidence for the
    driver-deployment areas operated on by the Deploy-* scripts in this
    repository.

.DESCRIPTION
    Collects the running OS identity and build state, pending-reboot state,
    the PnP device inventory (including problem devices and the AMD / BthPan
    device classes this repository targets), the driver store inventory
    (pnputil /enum-drivers plus Win32_PnPSignedDriver), the project
    code-signing certificate presence in the LocalMachine Root and
    TrustedPublisher stores (public certificate properties only - private
    keys are never read or exported), boot-security state (Secure Boot,
    UEFI CA 2023 servicing registry state, test-signing / integrity-check
    boot options, HVCI, WDAC SiPolicy.p7b file evidence and CiTool policy
    enumeration where available), recent CodeIntegrity events, the Windows
    driver setup logs (setupapi.dev.log / setupapi.setup.log), the
    repository script inventory (versions and SHA-256 of the four Deploy-*
    scripts and this collector) and a workspace inventory (the four
    WorkRoot trees and run-artifact archives, inventoried by name only -
    bulk payload is never copied).

    The collector is standalone and read-only: it does not install anything
    and does not change system state. Evidence is written to a timestamped
    directory, summarized in summary.json (schema-versioned), summary.txt
    and assessment-report.txt, then zipped. At completion a color-coded
    assessment report with PASS, FAIL, REVIEW and INFO items, the final
    result, exit code and artifact paths is printed.

    The collector can be run manually at any time, and the four Deploy-*
    scripts invoke it automatically before and after their run when their
    -CollectEvidence switch is set (stages 'pre' and 'post'). The stage and
    the invoking script are recorded in the evidence and in the ZIP name so
    pre/post pairs can be diffed.

    Exit code 0 means collection completed and every assessment item is
    PASS or INFO. Exit code 2 means evidence was created but at least one
    item is FAIL or REVIEW. Exit code 1 means a fatal collector error.

.PARAMETER OutputRoot
    Directory under which the timestamped evidence directory and ZIP are
    created. The only permitted locations are the directory containing this
    script and C:\Temp. When omitted, the script directory is used.

.PARAMETER Stage
    Collection stage recorded in the evidence and the ZIP name:
    'pre' (before a deployment run), 'post' (after a deployment run) or
    'standalone' (default; manual execution).

.PARAMETER InvokedBy
    Free-form identity of the invoking context (e.g.
    'Deploy-AMDChipsetDriverOnWindowsServer_Install'). Recorded in the
    evidence; a sanitized form is appended to the ZIP name.

.PARAMETER SkipSetupApiLog
    Skips copying C:\Windows\INF\setupapi.dev.log and setupapi.setup.log
    into the evidence. By default both logs are copied (size-capped at
    50 MB each).

.EXAMPLE
    .\Collect-WindowsServerConfigurationEvidence.ps1

.EXAMPLE
    .\Collect-WindowsServerConfigurationEvidence.ps1 -Stage pre `
        -InvokedBy 'Deploy-AMDGraphicsDriverOnWindowsServer_PrepareVerify'
#>
[CmdletBinding()]
param(
    [Parameter()]
    [AllowEmptyString()]
    [string]$OutputRoot,

    [Parameter()]
    [ValidateSet('pre', 'post', 'standalone')]
    [string]$Stage = 'standalone',

    [Parameter()]
    [AllowEmptyString()]
    [string]$InvokedBy,

    [Parameter()]
    [switch]$SkipSetupApiLog
)

Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'

$Script:ScriptVersion  = 'collector-2026.08.08-c2'
$Script:ScriptTag      = 'windows-server-configuration-evidence-collector'
$Script:ScriptHash     = 'unavailable'
try {
    $Script:ScriptHash = (Get-FileHash -LiteralPath $MyInvocation.MyCommand.Path -Algorithm SHA256 -ErrorAction Stop).Hash.Substring(0, 12).ToLowerInvariant()
} catch { } # psa-disable-line PSA3004 -- self-hash is identity metadata only; collection must proceed without it
$Script:ScriptShortTag = ('{0}/{1}' -f $Script:ScriptVersion, $Script:ScriptHash)
$script:SchemaVersion = 'windows-server-configuration-evidence/1.1'
$script:CollectorVersion = $Script:ScriptVersion
$script:MaxCopiedLogBytes = 50MB

#region Generic helpers (adapted from the iso-project post-install collector)

function Get-UtcTimestamp {
    [CmdletBinding()]
    [OutputType([string])]
    param()
    return [datetime]::UtcNow.ToString('o')
}

function Get-PropertyValue {
    [CmdletBinding()]
    [OutputType([object])]
    param(
        [Parameter()] [AllowNull()] [object]$InputObject,
        [Parameter(Mandatory = $true)] [ValidateNotNullOrEmpty()] [string]$Name,
        [Parameter()] [AllowNull()] [object]$DefaultValue = $null
    )

    if ($null -eq $InputObject) { return $DefaultValue }
    $property = $InputObject.PSObject.Properties[$Name]
    if ($null -eq $property) { return $DefaultValue }
    return $property.Value
}

function Get-FileEvidence {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory = $true)] [ValidateNotNullOrEmpty()] [string]$Path,
        [Parameter()] [switch]$SkipHash,
        [Parameter()] [switch]$SkipAuthenticode
    )

    $result = [pscustomobject][ordered]@{
        Path = $Path
        FileName = $null
        Present = $false
        SizeBytes = $null
        CreationTimeUtc = $null
        LastWriteTimeUtc = $null
        FileVersion = $null
        ProductVersion = $null
        CompanyName = $null
        Sha256 = $null
        HashErrorMessage = $null
        AuthenticodeStatus = $null
        AuthenticodeStatusMessage = $null
        SignerSubject = $null
        SignerIssuer = $null
        SignerThumbprint = $null
        SignerNotAfter = $null
        TimeStamperSubject = $null
        AuthenticodeErrorMessage = $null
        ReadErrorMessage = $null
    }

    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { return $result }

    try {
        $item = Get-Item -LiteralPath $Path -Force -ErrorAction Stop
        $result.Path = $item.FullName
        $result.FileName = [string]$item.Name
        $result.Present = $true
        $result.SizeBytes = [int64]$item.Length
        $result.CreationTimeUtc = $item.CreationTimeUtc.ToString('o')
        $result.LastWriteTimeUtc = $item.LastWriteTimeUtc.ToString('o')

        try {
            $versionInfo = $item.VersionInfo
            if ($null -ne $versionInfo) {
                $result.FileVersion = [string]$versionInfo.FileVersion
                $result.ProductVersion = [string]$versionInfo.ProductVersion
                $result.CompanyName = [string]$versionInfo.CompanyName
            }
        }
        catch { } # psa-disable-line PSA3004 -- version resource is optional for data files

        if (-not $SkipHash) {
            try {
                $result.Sha256 = (Get-FileHash -LiteralPath $item.FullName -Algorithm SHA256 -ErrorAction Stop).Hash.ToLowerInvariant()
            }
            catch {
                $result.HashErrorMessage = $_.Exception.Message
            }
        }

        if (-not $SkipAuthenticode) {
            try {
                $signature = Get-AuthenticodeSignature -LiteralPath $item.FullName -ErrorAction Stop
                $result.AuthenticodeStatus = [string]$signature.Status
                $result.AuthenticodeStatusMessage = [string]$signature.StatusMessage
                if ($null -ne $signature.SignerCertificate) {
                    $result.SignerSubject = [string]$signature.SignerCertificate.Subject
                    $result.SignerIssuer = [string]$signature.SignerCertificate.Issuer
                    $result.SignerThumbprint = [string]$signature.SignerCertificate.Thumbprint
                    $result.SignerNotAfter = $signature.SignerCertificate.NotAfter.ToString('o')
                }
                $timeStamper = Get-PropertyValue -InputObject $signature -Name 'TimeStamperCertificate'
                if ($null -ne $timeStamper) {
                    $result.TimeStamperSubject = [string]$timeStamper.Subject
                }
            }
            catch {
                $result.AuthenticodeErrorMessage = $_.Exception.Message
            }
        }
    }
    catch {
        $result.ReadErrorMessage = $_.Exception.Message
    }

    return $result
}

function Read-CapturedText {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory = $true)] [ValidateNotNullOrEmpty()] [string]$Path
    )

    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { return [string]::Empty }
    $content = Get-Content -LiteralPath $Path -Raw -ErrorAction SilentlyContinue
    if ($null -eq $content) { return [string]::Empty }
    return [string]$content
}

function Invoke-CapturedCommand {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory = $true)] [ValidateNotNullOrEmpty()] [string]$FilePath,
        [Parameter()] [AllowNull()] [AllowEmptyCollection()] [string[]]$ArgumentList = @()
    )

    $arguments = @()
    if ($null -ne $ArgumentList) { $arguments = @($ArgumentList) }

    $stdout = [System.IO.Path]::GetTempFileName()
    $stderr = [System.IO.Path]::GetTempFileName()
    try {
        $startParameters = @{
            FilePath = $FilePath
            Wait = $true
            PassThru = $true
            NoNewWindow = $true
            RedirectStandardOutput = $stdout
            RedirectStandardError = $stderr
            ErrorAction = 'Stop'
        }
        # Windows PowerShell 5.1 rejects Start-Process -ArgumentList @().
        if ($arguments.Count -gt 0) { $startParameters['ArgumentList'] = $arguments }

        $process = Start-Process @startParameters

        return [pscustomobject][ordered]@{
            FilePath = $FilePath
            Arguments = @($arguments)
            Started = $true
            Succeeded = ([int]$process.ExitCode -eq 0)
            ExitCode = [int]$process.ExitCode
            StdOut = Read-CapturedText -Path $stdout
            StdErr = Read-CapturedText -Path $stderr
            ErrorMessage = $null
        }
    }
    catch {
        return [pscustomobject][ordered]@{
            FilePath = $FilePath
            Arguments = @($arguments)
            Started = $false
            Succeeded = $false
            ExitCode = $null
            StdOut = Read-CapturedText -Path $stdout
            StdErr = Read-CapturedText -Path $stderr
            ErrorMessage = $_.Exception.Message
        }
    }
    finally {
        Remove-Item -LiteralPath $stdout, $stderr -Force -ErrorAction SilentlyContinue
    }
}

function Get-RegistryKeySnapshot {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory = $true)] [ValidateNotNullOrEmpty()] [string]$Path
    )

    $result = [pscustomobject][ordered]@{
        Path = $Path
        Present = $false
        Available = $false
        ErrorMessage = $null
        Values = [pscustomobject][ordered]@{}
    }

    if (-not (Test-Path -LiteralPath $Path)) { return $result }

    try {
        $key = Get-Item -LiteralPath $Path -ErrorAction Stop
        $values = [ordered]@{}
        foreach ($name in @($key.GetValueNames() | Sort-Object)) {
            $value = $key.GetValue($name, $null, [Microsoft.Win32.RegistryValueOptions]::DoNotExpandEnvironmentNames)
            $values[$name] = [pscustomobject][ordered]@{
                Type = [string]$key.GetValueKind($name)
                Value = $value
            }
        }
        $result.Present = $true
        $result.Available = $true
        $result.Values = [pscustomobject]$values
    }
    catch {
        $result.Present = $true
        $result.ErrorMessage = $_.Exception.Message
    }

    return $result
}

function Get-NamedRegistryValue {
    [CmdletBinding()]
    [OutputType([object])]
    param(
        [Parameter(Mandatory = $true)] [object]$Snapshot,
        [Parameter(Mandatory = $true)] [ValidateNotNullOrEmpty()] [string]$Name,
        [Parameter()] [AllowNull()] [object]$DefaultValue = $null
    )

    if ($null -eq $Snapshot -or -not $Snapshot.Available) { return $DefaultValue }
    $property = $Snapshot.Values.PSObject.Properties[$Name]
    if ($null -eq $property -or $null -eq $property.Value) { return $DefaultValue }
    return $property.Value.Value
}

function Write-EvidenceJson {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)] [AllowNull()] [object]$InputObject,
        [Parameter(Mandatory = $true)] [ValidateNotNullOrEmpty()] [string]$Directory,
        [Parameter(Mandatory = $true)] [ValidateNotNullOrEmpty()] [string]$FileName
    )

    $InputObject | ConvertTo-Json -Depth 20 |
        Set-Content -LiteralPath (Join-Path $Directory $FileName) -Encoding UTF8
}

#endregion

#region Pending reboot (adapted; advisory allow-list retained from the iso collector)

function Test-PendingFileRenameAdvisoryCleanup {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory = $true)] [ValidateNotNullOrEmpty()] [string]$SourcePath
    )

    $normalized = $SourcePath -replace '^(?:\*1)?\\\?\?\\', ''
    $patterns = @(
        '(?i)^[A-Z]:\\Windows\\SystemTemp\\MicrosoftEdgeUpdate\.exe\.old\{[0-9A-F]{8}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{12}\}$',
        '(?i)^[A-Z]:\\Windows\\SystemTemp\\CopilotUpdate\.exe\.old\{[0-9A-F]{8}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{12}\}$',
        '(?i)^[A-Z]:\\Program Files \(x86\)\\Microsoft\\EdgeUpdate\\[0-9][^\\]*$'
    )

    foreach ($pattern in $patterns) {
        if ($normalized -match $pattern) { # psa-disable-line PSA2003 -- $pattern iterates a non-null literal array defined above
            return [pscustomobject][ordered]@{
                IsAdvisory = $true
                NormalizedSource = $normalized
                Reason = 'RecognizedMicrosoftUpdaterCleanup'
            }
        }
    }

    return [pscustomobject][ordered]@{
        IsAdvisory = $false
        NormalizedSource = $normalized
        Reason = 'UnrecognizedPendingFileOperation'
    }
}

function Convert-PendingFileRenameOperationsEvidence {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter()] [AllowNull()] [object]$Value
    )

    $rawValues = @()
    if ($null -ne $Value) {
        if ($Value -is [System.Array]) {
            $rawValues = @($Value | ForEach-Object { if ($null -eq $_) { '' } else { [string]$_ } })
        }
        else {
            $rawValues = @([string]$Value)
        }
    }

    $records = New-Object 'System.Collections.Generic.List[object]'
    $malformed = (($rawValues.Count % 2) -ne 0)
    for ($index = 0; $index -lt $rawValues.Count; $index += 2) {
        $source = [string]$rawValues[$index]
        $hasTarget = (($index + 1) -lt $rawValues.Count)
        $target = if ($hasTarget) { [string]$rawValues[$index + 1] } else { $null }
        $operation = if (-not $hasTarget) { 'Malformed' }
        elseif ([string]::IsNullOrEmpty($target)) { 'Delete' }
        else { 'RenameOrMove' }

        $advisory = [pscustomobject][ordered]@{
            IsAdvisory = $false
            NormalizedSource = ($source -replace '^(?:\*1)?\\\?\?\\', '')
            Reason = if ($operation -eq 'Malformed') { 'MalformedPair' } else { 'NotEligibleForAdvisoryClassification' }
        }
        if ($operation -eq 'Delete' -and -not [string]::IsNullOrWhiteSpace($source)) {
            $advisory = Test-PendingFileRenameAdvisoryCleanup -SourcePath $source
        }

        $records.Add([pscustomobject][ordered]@{
            PairIndex = [int]($index / 2)
            Source = $source
            Target = $target
            Operation = $operation
            NormalizedSource = $advisory.NormalizedSource
            AdvisoryCleanup = [bool]$advisory.IsAdvisory
            ClassificationReason = [string]$advisory.Reason
        }) | Out-Null
    }

    $advisoryCount = @($records | Where-Object AdvisoryCleanup).Count
    $blockingCount = @($records | Where-Object { -not $_.AdvisoryCleanup }).Count
    return [pscustomobject][ordered]@{
        RawValueCount = $rawValues.Count
        PairCount = $records.Count
        Malformed = [bool]$malformed
        AdvisoryOperationCount = $advisoryCount
        BlockingOperationCount = $blockingCount
        AdvisoryCleanupOnly = [bool]($records.Count -gt 0 -and -not $malformed -and $blockingCount -eq 0)
        Records = $records.ToArray()
    }
}

function Get-PendingRebootEvidence {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param()

    $readErrors = New-Object 'System.Collections.Generic.List[string]'

    $cbsPending = $false
    try {
        $cbsPending = Test-Path -LiteralPath 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending'
    }
    catch { $readErrors.Add('CBS: ' + $_.Exception.Message) }

    $wuPending = $false
    try {
        $wuPending = Test-Path -LiteralPath 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired'
    }
    catch { $readErrors.Add('WU: ' + $_.Exception.Message) }

    $pfroPresent = $false
    $pfroEvidence = Convert-PendingFileRenameOperationsEvidence -Value $null
    try {
        $sessionManager = Get-RegistryKeySnapshot -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager'
        $pfroValue = Get-NamedRegistryValue -Snapshot $sessionManager -Name 'PendingFileRenameOperations'
        if ($null -ne $pfroValue) {
            $pfroPresent = $true
            $pfroEvidence = Convert-PendingFileRenameOperationsEvidence -Value $pfroValue
        }
    }
    catch { $readErrors.Add('PFRO: ' + $_.Exception.Message) }

    $pfroBlocking = [bool]($pfroPresent -and -not $pfroEvidence.AdvisoryCleanupOnly)
    $blockingPending = [bool]($cbsPending -or $wuPending -or $pfroBlocking)
    $advisoryPending = [bool](-not $blockingPending -and $pfroPresent -and $pfroEvidence.AdvisoryCleanupOnly)
    $classification = if ($blockingPending) { 'Blocking' }
    elseif ($advisoryPending) { 'Advisory' }
    elseif ($readErrors.Count -gt 0) { 'Unknown' }
    else { 'None' }

    return [pscustomobject][ordered]@{
        CollectedAtUtc = Get-UtcTimestamp
        CbsRebootPending = $cbsPending
        WindowsUpdateRebootPending = $wuPending
        PendingFileRenamePresent = $pfroPresent
        PendingFileRenameOperations = $pfroEvidence
        ReadErrors = $readErrors.ToArray()
        RebootPending = [bool]($blockingPending -or $advisoryPending)
        BlockingRebootPending = $blockingPending
        AdvisoryRebootPending = $advisoryPending
        Classification = $classification
    }
}

#endregion

#region Domain collectors (driver-deployment areas of this repository)

function Get-OperatingSystemEvidence {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param()

    $os = Get-CimInstance -ClassName Win32_OperatingSystem
    $computer = Get-CimInstance -ClassName Win32_ComputerSystem
    $cv = Get-RegistryKeySnapshot -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion'
    $ubrValue = Get-NamedRegistryValue -Snapshot $cv -Name 'UBR'

    return [pscustomobject][ordered]@{
        CollectedAtUtc = Get-UtcTimestamp
        ComputerName = [string]$env:COMPUTERNAME
        Manufacturer = [string](Get-PropertyValue -InputObject $computer -Name 'Manufacturer')
        Model = [string](Get-PropertyValue -InputObject $computer -Name 'Model')
        OsCaption = [string]$os.Caption
        OsVersion = [string]$os.Version
        OsBuildNumber = [string]$os.BuildNumber
        Ubr = if ($null -ne $ubrValue) { [int]$ubrValue } else { $null }
        ProductName = [string](Get-NamedRegistryValue -Snapshot $cv -Name 'ProductName')
        DisplayVersion = [string](Get-NamedRegistryValue -Snapshot $cv -Name 'DisplayVersion')
        InstallationType = [string](Get-NamedRegistryValue -Snapshot $cv -Name 'InstallationType')
        ProductType = [int]$os.ProductType
        OsArchitecture = [string]$os.OSArchitecture
        LastBootUpTimeUtc = $os.LastBootUpTime.ToUniversalTime().ToString('o')
        InstallDateUtc = $os.InstallDate.ToUniversalTime().ToString('o')
        PowerShellVersion = [string]$PSVersionTable.PSVersion
        PowerShellEdition = [string](Get-PropertyValue -InputObject $PSVersionTable -Name 'PSEdition' -DefaultValue 'Desktop')
        IsElevated = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
        CurrentVersionKey = $cv
    }
}

function Get-PnpDeviceEvidence {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param()

    $devices = @(Get-CimInstance -ClassName Win32_PnPEntity -ErrorAction Stop)
    $records = New-Object 'System.Collections.Generic.List[object]'
    $problems = New-Object 'System.Collections.Generic.List[object]'
    $targeted = New-Object 'System.Collections.Generic.List[object]'

    # HWID families this repository's four deploy scripts operate on:
    #   PCI\VEN_1022 (AMD), PCI\VEN_1002 (AMD/ATI display + HDMI audio),
    #   ACP\ (AMD audio co-processor), HDAUDIO\FUNC_01...VEN_1002,
    #   BTH\MS_BTHPAN (Microsoft Bluetooth PAN).
    $targetPattern = '^(PCI\\VEN_1022|PCI\\VEN_1002|ACP\\|HDAUDIO\\FUNC_01&VEN_1002|BTH\\MS_BTHPAN)'

    foreach ($device in $devices) {
        $hardwareIds = @()
        $rawIds = Get-PropertyValue -InputObject $device -Name 'HardwareID'
        if ($null -ne $rawIds) { $hardwareIds = @($rawIds | ForEach-Object { [string]$_ }) }
        $errorCode = Get-PropertyValue -InputObject $device -Name 'ConfigManagerErrorCode'
        $record = [pscustomobject][ordered]@{
            Name = [string](Get-PropertyValue -InputObject $device -Name 'Name')
            PnpDeviceId = [string](Get-PropertyValue -InputObject $device -Name 'PNPDeviceID')
            PnpClass = [string](Get-PropertyValue -InputObject $device -Name 'PNPClass')
            Status = [string](Get-PropertyValue -InputObject $device -Name 'Status')
            ConfigManagerErrorCode = if ($null -ne $errorCode) { [int]$errorCode } else { $null }
            ConfigManagerErrorName = (Get-ConfigManagerErrorName -Code $errorCode)
            Present = [bool](Get-PropertyValue -InputObject $device -Name 'Present' -DefaultValue $true)
            HardwareIds = $hardwareIds
        }
        $records.Add($record) | Out-Null
        if ($null -ne $record.ConfigManagerErrorCode -and $record.ConfigManagerErrorCode -ne 0) {
            $problems.Add($record) | Out-Null
        }
        $isTargeted = $false
        foreach ($hardwareId in $hardwareIds) {
            if ($hardwareId -match $targetPattern) { $isTargeted = $true; break } # psa-disable-line PSA2003 -- $targetPattern is a non-null literal assigned above in this function
        }
        if (-not $isTargeted -and [string]$record.PnpDeviceId -match $targetPattern) { $isTargeted = $true } # psa-disable-line PSA2003 -- $targetPattern is a non-null literal assigned above in this function
        if ($isTargeted) { $targeted.Add($record) | Out-Null }
    }

    return [pscustomobject][ordered]@{
        CollectedAtUtc = Get-UtcTimestamp
        DeviceCount = $records.Count
        ProblemDeviceCount = $problems.Count
        TargetedDeviceCount = $targeted.Count
        TargetHardwareIdPattern = $targetPattern
        ProblemDevices = $problems.ToArray()
        TargetedDevices = $targeted.ToArray()
        Devices = $records.ToArray()
    }
}

function Get-ConfigManagerErrorName {
    # CM_PROB_* name for a ConfigManagerErrorCode. Names are from the
    # Windows CM_PROB_ constants and are stable across locales, which the
    # localized Win32_PnPEntity.Status string is not.
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter()]
        $Code
    )
    if ($null -eq $Code) { return '' }
    switch ([int]$Code) {
        0  { 'OK' }
        1  { 'CM_PROB_NOT_CONFIGURED - no driver configured for this device' }
        3  { 'CM_PROB_OUT_OF_MEMORY - driver may be corrupted or memory is low' }
        9  { 'CM_PROB_INVALID_DATA - device information is invalid' }
        10 { 'CM_PROB_FAILED_START - device failed to start' }
        12 { 'CM_PROB_NORMAL_CONFLICT - insufficient free resources' }
        14 { 'CM_PROB_NEED_RESTART - restart required to take effect' }
        18 { 'CM_PROB_REINSTALL - drivers must be reinstalled' }
        19 { 'CM_PROB_REGISTRY - registry configuration is damaged' }
        21 { 'CM_PROB_WILL_BE_REMOVED - device is being removed' }
        22 { 'CM_PROB_DISABLED - device is disabled' }
        24 { 'CM_PROB_DEVICE_NOT_THERE - device is not present or is failing' }
        28 { 'CM_PROB_FAILED_INSTALL - drivers are not installed for this device' }
        29 { 'CM_PROB_HARDWARE_DISABLED - disabled by firmware' }
        31 { 'CM_PROB_FAILED_ADD - Windows cannot load the required drivers' }
        32 { 'CM_PROB_DISABLED_SERVICE - start type of the driver service is disabled' }
        35 { 'CM_PROB_HELD_FOR_EJECT - firmware does not include enough information' }
        37 { 'CM_PROB_DRIVER_FAILED_PRIOR_UNLOAD - driver returned failure on unload' }
        38 { 'CM_PROB_DRIVER_BLOCKED - a previous instance is still in memory' }
        39 { 'CM_PROB_FAILED_DRIVER_LOAD - driver is corrupted, missing, or rejected' }
        40 { 'CM_PROB_INVALID_DATA - registry service key information is invalid' }
        41 { 'CM_PROB_FAILED_POST_START - driver loaded but no PnP device was found' }
        43 { 'CM_PROB_HALTED - the device reported a problem and was stopped' }
        45 { 'CM_PROB_PHANTOM - device is not currently connected' }
        51 { 'CM_PROB_WAITING_ON_DEPENDENCY - waiting on another device or service' }
        52 { 'CM_PROB_UNSIGNED_DRIVER - cannot verify the digital signature' }
        54 { 'CM_PROB_DEVICE_RESET - device is failing or being reset' }
        default { ('CM_PROB (code {0}) - see Device Manager for detail' -f [int]$Code) }
    }
}

function Get-DriverLoadStatusName {
    # NTSTATUS values that appear beside CM_PROB codes in setupapi.dev.log.
    # The signature-related ones are called out explicitly because
    # distinguishing "kernel rejected the signature" from "the driver does
    # not fit this OS build" is the first fork in any load-failure triage,
    # and the two look identical at the Device Manager level.
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter()]
        [string]$Status
    )
    if ([string]::IsNullOrWhiteSpace($Status)) { return '' }
    switch ($Status.ToLowerInvariant().Replace('0x', '')) {
        'c0000428' { 'STATUS_INVALID_IMAGE_HASH - SIGNATURE: the kernel refused the image signature' }
        'c0000603' { 'STATUS_IMAGE_CERT_REVOKED - SIGNATURE: the signing certificate is revoked' }
        'c000036b' { 'STATUS_IMAGE_CERT_EXPIRED - SIGNATURE: the signing certificate has expired' }
        'c0000262' { 'STATUS_DRIVER_ORDINAL_NOT_FOUND - NOT a signature problem: the driver imports an ordinal this OS build does not export' }
        'c0000263' { 'STATUS_DRIVER_ENTRYPOINT_NOT_FOUND - NOT a signature problem: the driver imports an entry point this OS build does not export' }
        'c0000365' { 'STATUS_FAILED_DRIVER_ENTRY - the driver''s DriverEntry returned failure' }
        'c000009c' { 'STATUS_DEVICE_DATA_ERROR - device data error' }
        'c0000490' { 'STATUS_DEVICE_HARDWARE_ERROR - device reported a hardware error' }
        'c0000493' { 'STATUS_DEVICE_NOT_CONNECTED - the device was not connected when evaluated' }
        'c0000001' { 'STATUS_UNSUCCESSFUL' }
        default    { ('NTSTATUS {0} - undecoded' -f $Status) }
    }
}

function Get-SetupApiFailureEvidence {
    # Extract failure records from setupapi.dev.log.
    #
    # setupapi.dev.log is already copied verbatim into the bundle, but a
    # multi-megabyte verbatim copy is not evidence anyone reads under
    # pressure. This pulls out the parts that matter: per-device-install
    # sections that ended in failure, the SetupAPI error code, any
    # "Binary '<path>' for service '<name>' is not present" line (a missing
    # OS component the device's own INF requires), and any CM problem plus
    # NT status pair.
    #
    # Parsing keys off tokens that do not change with the display language.
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter()]
        [string]$LogPath,

        [Parameter()]
        [int]$MaxSections = 40
    )
    $result = [pscustomobject][ordered]@{
        CollectedAtUtc = Get-UtcTimestamp
        LogPath = [string]$LogPath
        LogPresent = $false
        SectionsScanned = 0
        FailureSections = @()
        MissingServiceBinaries = @()
        ParseError = ''
    }
    if ([string]::IsNullOrWhiteSpace($LogPath) -or -not (Test-Path -LiteralPath $LogPath)) {
        return $result
    }
    $result.LogPresent = $true
    try {
        $lines = @(Get-Content -LiteralPath $LogPath -ErrorAction Stop)
    } catch {
        $result.ParseError = $_.Exception.Message
        return $result
    }

    $sections = New-Object 'System.Collections.Generic.List[object]'
    $missing = New-Object 'System.Collections.Generic.List[object]'
    $startIndexes = New-Object 'System.Collections.Generic.List[int]'
    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -like '>>>*[Device Install*') { $startIndexes.Add($i) | Out-Null }
    }
    $result.SectionsScanned = $startIndexes.Count

    foreach ($start in $startIndexes) {
        $end = $lines.Count - 1
        foreach ($candidate in $startIndexes) {
            if ($candidate -gt $start) { $end = $candidate - 1; break }
        }
        $header = [string]$lines[$start]
        $timestamp = ''
        $errors = New-Object 'System.Collections.Generic.List[string]'
        $problem = ''
        $problemStatus = ''
        $failed = $false
        for ($j = $start; $j -le $end; $j++) {
            $line = [string]$lines[$j]
            if ($line -like '>>>*Section start*') {
                $timestamp = ($line -split 'Section start')[-1].Trim()
            }
            if ($line -match 'Error 0x[0-9a-fA-F]+') {
                $failed = $true
                $token = ([regex]::Match($line, 'Error 0x[0-9a-fA-F]+')).Value
                if (-not $errors.Contains($token)) { $errors.Add($token) | Out-Null }
            }
            if ($line -match "Binary '([^']+)' for service '([^']+)' is not present") {
                $failed = $true
                $binary = $Matches[1]
                $service = $Matches[2]
                $missing.Add([pscustomobject][ordered]@{
                    ServiceName = [string]$service
                    ExpectedBinary = [string]$binary
                    BinaryExists = (Test-Path -LiteralPath ([string]$binary))
                    SeenInSection = $header
                }) | Out-Null
            }
            if ($line -match 'Problem: 0x([0-9a-fA-F]+) \(0x([0-9a-fA-F]+)\)') {
                $problem = [string]([Convert]::ToInt32($Matches[1], 16))
                $problemStatus = '0x' + $Matches[2]
            }
            if ($line -like '*[Exit status: FAILURE*') { $failed = $true }
        }
        if (-not $failed) { continue }
        $sections.Add([pscustomobject][ordered]@{
            Header = $header
            SectionStart = $timestamp
            SetupApiErrors = $errors.ToArray()
            ConfigManagerErrorCode = $problem
            ConfigManagerErrorName = (Get-ConfigManagerErrorName -Code $(if ($problem -ne '') { [int]$problem } else { $null }))
            DriverLoadStatus = $problemStatus
            DriverLoadStatusName = (Get-DriverLoadStatusName -Status $problemStatus)
        }) | Out-Null
    }

    $keep = @($sections.ToArray())
    if ($keep.Count -gt $MaxSections) {
        $keep = @($keep[($keep.Count - $MaxSections)..($keep.Count - 1)])
    }
    $result.FailureSections = $keep
    $result.MissingServiceBinaries = $missing.ToArray()
    return $result
}

function Get-DeviceLoadDiagnosticEvidence {
    # Per-problem-device diagnostics: what is bound, what service backs it,
    # and whether that service's binary is actually on disk.
    #
    # The last item is the one the field run needed and did not have. A
    # device install can fail because the INF declares a service whose
    # binary ships with an OS feature that is not installed on this SKU -
    # a state that is invisible in the device record and obvious the moment
    # you test the ImagePath.
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter()]
        $PnpEvidence,

        [Parameter()]
        [string]$SetupApiLogPath
    )
    $records = New-Object 'System.Collections.Generic.List[object]'
    $signedDrivers = @{}
    try {
        foreach ($d in @(Get-CimInstance -ClassName Win32_PnPSignedDriver -ErrorAction Stop)) {
            $id = [string](Get-PropertyValue -InputObject $d -Name 'DeviceID')
            if (-not [string]::IsNullOrWhiteSpace($id) -and -not $signedDrivers.ContainsKey($id)) {
                $signedDrivers[$id] = $d
            }
        }
    } catch {
        $signedDrivers = @{}
    }

    $problemDevices = @()
    if ($null -ne $PnpEvidence -and $PnpEvidence.PSObject.Properties['ProblemDevices']) {
        $problemDevices = @($PnpEvidence.ProblemDevices)
    }

    foreach ($device in $problemDevices) {
        $id = [string]$device.PnpDeviceId
        $serviceName = ''
        $infName = ''
        $driverVersion = ''
        $driverProvider = ''
        if ($signedDrivers.ContainsKey($id)) {
            $sd = $signedDrivers[$id]
            $infName = [string](Get-PropertyValue -InputObject $sd -Name 'InfName')
            $driverVersion = [string](Get-PropertyValue -InputObject $sd -Name 'DriverVersion')
            $driverProvider = [string](Get-PropertyValue -InputObject $sd -Name 'DriverProviderName')
        }
        # The device's service name lives under the device's Enum key.
        $imagePath = ''
        $imagePathResolved = ''
        $imagePathExists = $null
        $serviceStartType = ''
        try {
            $enumKey = 'HKLM:\SYSTEM\CurrentControlSet\Enum' + $id
            if (Test-Path -LiteralPath $enumKey) {
                $serviceName = [string](Get-NamedRegistryValue -Path $enumKey -Name 'Service')
            }
        } catch {
            $serviceName = ''
        }
        if (-not [string]::IsNullOrWhiteSpace($serviceName)) {
            try {
                $svcKey = 'HKLM:\SYSTEM\CurrentControlSet\Services' + $serviceName
                if (Test-Path -LiteralPath $svcKey) {
                    $imagePath = [string](Get-NamedRegistryValue -Path $svcKey -Name 'ImagePath')
                    $startValue = Get-NamedRegistryValue -Path $svcKey -Name 'Start'
                    if ($null -ne $startValue) { $serviceStartType = [string]$startValue }
                }
            } catch {
                $imagePath = ''
            }
        }
        if (-not [string]::IsNullOrWhiteSpace($imagePath)) {
            $candidate = $imagePath
            if ($candidate -like '\SystemRoot\*') {
                $candidate = $candidate -replace '^\SystemRoot', $env:SystemRoot
            } elseif ($candidate -like 'system32\*' -or $candidate -like 'System32\*') {
                $candidate = Join-Path $env:SystemRoot $candidate
            } elseif ($candidate -like '\??\*') {
                $candidate = $candidate.Substring(4)
            }
            $imagePathResolved = $candidate
            try {
                $imagePathExists = [bool](Test-Path -LiteralPath $candidate)
            } catch {
                $imagePathExists = $null
            }
        }
        $records.Add([pscustomobject][ordered]@{
            Name = [string]$device.Name
            PnpDeviceId = $id
            ConfigManagerErrorCode = $device.ConfigManagerErrorCode
            ConfigManagerErrorName = (Get-ConfigManagerErrorName -Code $device.ConfigManagerErrorCode)
            BoundInfName = $infName
            DriverVersion = $driverVersion
            DriverProvider = $driverProvider
            ServiceName = $serviceName
            ServiceStartType = $serviceStartType
            ServiceImagePath = $imagePath
            ServiceImagePathResolved = $imagePathResolved
            ServiceBinaryPresent = $imagePathExists
            HardwareIds = @($device.HardwareIds)
        }) | Out-Null
    }

    $setupApi = Get-SetupApiFailureEvidence -LogPath $SetupApiLogPath

    $missingBinaryCount = 0
    foreach ($r in $records) {
        if ($r.ServiceBinaryPresent -eq $false) { $missingBinaryCount++ }
    }
    $signatureRelated = 0
    foreach ($s in @($setupApi.FailureSections)) {
        if ([string]$s.DriverLoadStatusName -like '*SIGNATURE:*') { $signatureRelated++ }
    }

    return [pscustomobject][ordered]@{
        CollectedAtUtc = Get-UtcTimestamp
        ProblemDeviceCount = $records.Count
        MissingServiceBinaryCount = $missingBinaryCount
        SignatureRelatedFailureCount = $signatureRelated
        ProblemDevices = $records.ToArray()
        SetupApi = $setupApi
    }
}

function Get-DriverStoreEvidence {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory = $true)] [ValidateNotNullOrEmpty()] [string]$EvidenceDirectory
    )

    $pnputilPath = Join-Path $env:SystemRoot 'System32\pnputil.exe'
    $capture = Invoke-CapturedCommand -FilePath $pnputilPath -ArgumentList @('/enum-drivers')
    Set-Content -LiteralPath (Join-Path $EvidenceDirectory 'pnputil_enum-drivers.txt') `
        -Value ($capture.StdOut + $capture.StdErr) -Encoding UTF8

    # Parse the /enum-drivers block format into records. The output is
    # locale-dependent free text; parsing is best-effort and the raw
    # capture above remains the authoritative artifact.
    $entries = New-Object 'System.Collections.Generic.List[object]'
    $current = $null
    foreach ($line in ($capture.StdOut -split "`r?`n")) {
        if ($line -match '^\s*$') {
            if ($null -ne $current) { $entries.Add([pscustomobject]$current) | Out-Null; $current = $null }
            continue
        }
        if ($line -match '^\s*([^:]+):\s*(.*)$') {
            $label = $Matches[1].Trim()
            $value = $Matches[2].Trim()
            if ($null -eq $current) { $current = [ordered]@{} }
            if ($label -match '(?i)published|oem') { $current['PublishedName'] = $value }
            elseif ($label -match '(?i)original') { $current['OriginalName'] = $value }
            elseif ($label -match '(?i)provider') { $current['Provider'] = $value }
            elseif ($label -match '(?i)class name|クラス名') { $current['ClassName'] = $value }
            elseif ($label -match '(?i)version|バージョン') { $current['DriverVersion'] = $value }
            elseif ($label -match '(?i)signer|署名') { $current['SignerName'] = $value }
        }
    }
    if ($null -ne $current) { $entries.Add([pscustomobject]$current) | Out-Null }

    $signedDrivers = @()
    $signedDriverError = $null
    try {
        $signedDrivers = @(
            Get-CimInstance -ClassName Win32_PnPSignedDriver -ErrorAction Stop |
                Select-Object DeviceName, DeviceClass, DriverVersion, DriverDate, DriverProviderName,
                    InfName, IsSigned, Signer, HardWareID
        )
    }
    catch {
        $signedDriverError = $_.Exception.Message
    }

    return [pscustomobject][ordered]@{
        CollectedAtUtc = Get-UtcTimestamp
        PnputilCapture = [pscustomobject][ordered]@{
            Started = $capture.Started
            ExitCode = $capture.ExitCode
            Succeeded = $capture.Succeeded
            ErrorMessage = $capture.ErrorMessage
        }
        ParsedEntryCount = $entries.Count
        ParsedEntries = $entries.ToArray()
        SignedDriverCount = $signedDrivers.Count
        SignedDriverCollectionError = $signedDriverError
        SignedDrivers = $signedDrivers
    }
}

function Get-ProjectCertificateEvidence {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param()

    # The four deploy scripts create per-family self-signed code-signing
    # certificates with subjects of the form
    #   CN=<Family> Driver Self-Sign (<OSCode> Lab, At Own Risk)
    # and import the PUBLIC certificate into LocalMachine\Root and
    # LocalMachine\TrustedPublisher during I01. Only public certificate
    # properties are read here; private keys are never touched.
    $subjectPattern = 'Driver Self-Sign'
    $stores = @('Root', 'TrustedPublisher')
    $found = New-Object 'System.Collections.Generic.List[object]'
    $storeErrors = New-Object 'System.Collections.Generic.List[string]'

    foreach ($storeName in $stores) {
        try {
            $certificates = @(Get-ChildItem -Path ('Cert:\LocalMachine\{0}' -f $storeName) -ErrorAction Stop |
                Where-Object { $_.Subject -match $subjectPattern }) # psa-disable-line PSA2003 -- $subjectPattern is a non-null literal assigned above in this function
            foreach ($certificate in $certificates) {
                $found.Add([pscustomobject][ordered]@{
                    Store = $storeName
                    Subject = [string]$certificate.Subject
                    Issuer = [string]$certificate.Issuer
                    Thumbprint = [string]$certificate.Thumbprint
                    SerialNumber = [string]$certificate.SerialNumber
                    NotBefore = $certificate.NotBefore.ToString('o')
                    NotAfter = $certificate.NotAfter.ToString('o')
                    HasPrivateKey = [bool]$certificate.HasPrivateKey
                }) | Out-Null
            }
        }
        catch {
            $storeErrors.Add(('{0}: {1}' -f $storeName, $_.Exception.Message))
        }
    }

    $rootThumbprints = @($found | Where-Object { $_.Store -eq 'Root' } | ForEach-Object Thumbprint | Sort-Object -Unique)
    $publisherThumbprints = @($found | Where-Object { $_.Store -eq 'TrustedPublisher' } | ForEach-Object Thumbprint | Sort-Object -Unique)
    $onlyInRoot = @($rootThumbprints | Where-Object { $publisherThumbprints -notcontains $_ })
    $onlyInPublisher = @($publisherThumbprints | Where-Object { $rootThumbprints -notcontains $_ })

    return [pscustomobject][ordered]@{
        CollectedAtUtc = Get-UtcTimestamp
        SubjectPattern = $subjectPattern
        StoreErrors = $storeErrors.ToArray()
        CertificateCount = $found.Count
        RootThumbprints = $rootThumbprints
        TrustedPublisherThumbprints = $publisherThumbprints
        ThumbprintsOnlyInRoot = $onlyInRoot
        ThumbprintsOnlyInTrustedPublisher = $onlyInPublisher
        StoresConsistent = [bool]($onlyInRoot.Count -eq 0 -and $onlyInPublisher.Count -eq 0)
        Certificates = $found.ToArray()
    }
}

function Get-BootSecurityEvidence {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory = $true)] [ValidateNotNullOrEmpty()] [string]$EvidenceDirectory
    )

    $secureBootEnabled = $null
    $secureBootError = $null
    try {
        $secureBootEnabled = [bool](Confirm-SecureBootUEFI -ErrorAction Stop)
    }
    catch {
        $secureBootError = $_.Exception.Message
    }

    $uefiCa2023 = Get-RegistryKeySnapshot -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\SecureBoot'
    $sbServicing = Get-RegistryKeySnapshot -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\SecureBoot\Servicing'
    $hvci = Get-RegistryKeySnapshot -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity'

    $bcdCapture = Invoke-CapturedCommand -FilePath (Join-Path $env:SystemRoot 'System32\bcdedit.exe') -ArgumentList @('/enum', '{current}')
    Set-Content -LiteralPath (Join-Path $EvidenceDirectory 'bcdedit_current.txt') `
        -Value ($bcdCapture.StdOut + $bcdCapture.StdErr) -Encoding UTF8
    $testSigning = $null
    $noIntegrityChecks = $null
    if ($bcdCapture.Succeeded) {
        $testSigning = [bool]($bcdCapture.StdOut -match '(?im)^\s*testsigning\s+Yes\s*$')
        $noIntegrityChecks = [bool]($bcdCapture.StdOut -match '(?im)^\s*nointegritychecks\s+Yes\s*$')
    }

    $siPolicyPath = Join-Path $env:SystemRoot 'System32\CodeIntegrity\SiPolicy.p7b'
    $siPolicy = Get-FileEvidence -Path $siPolicyPath -SkipAuthenticode

    $ciToolPath = Join-Path $env:SystemRoot 'System32\CiTool.exe'
    $ciToolCapture = $null
    if (Test-Path -LiteralPath $ciToolPath -PathType Leaf) {
        $ciToolCapture = Invoke-CapturedCommand -FilePath $ciToolPath -ArgumentList @('-lp')
        Set-Content -LiteralPath (Join-Path $EvidenceDirectory 'citool_list-policies.txt') `
            -Value ($ciToolCapture.StdOut + $ciToolCapture.StdErr) -Encoding UTF8
    }

    return [pscustomobject][ordered]@{
        CollectedAtUtc = Get-UtcTimestamp
        SecureBootEnabled = $secureBootEnabled
        SecureBootQueryError = $secureBootError
        SecureBootKey = $uefiCa2023
        SecureBootServicingKey = $sbServicing
        HvciKey = $hvci
        BcdCaptureSucceeded = [bool]$bcdCapture.Succeeded
        TestSigningEnabled = $testSigning
        NoIntegrityChecksEnabled = $noIntegrityChecks
        WdacSiPolicyFile = $siPolicy
        CiToolPresent = [bool](Test-Path -LiteralPath $ciToolPath -PathType Leaf)
        CiToolExitCode = if ($null -ne $ciToolCapture) { $ciToolCapture.ExitCode } else { $null }
    }
}

function Get-CodeIntegrityEventEvidence {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory = $true)] [ValidateNotNullOrEmpty()] [string]$EvidenceDirectory,
        [Parameter()] [ValidateRange(1, 1000)] [int]$MaxEvents = 200
    )

    $records = New-Object 'System.Collections.Generic.List[object]'
    $queryError = $null
    try {
        $events = @(Get-WinEvent -FilterHashtable @{
            LogName = 'Microsoft-Windows-CodeIntegrity/Operational'
            Id = @(3076, 3077, 3089, 3091)
        } -MaxEvents $MaxEvents -ErrorAction Stop)
        foreach ($event in $events) {
            $records.Add([pscustomobject][ordered]@{
                TimeCreatedUtc = $event.TimeCreated.ToUniversalTime().ToString('o')
                Id = [int]$event.Id
                Level = [string]$event.LevelDisplayName
                Message = [string]$event.Message
            }) | Out-Null
        }
    }
    catch {
        # NoMatchingEventsFound surfaces as an exception; that is a normal,
        # healthy state and is recorded as zero events with the message.
        $queryError = $_.Exception.Message
    }

    $blockEventCount = @($records | Where-Object { $_.Id -eq 3077 }).Count
    $auditEventCount = @($records | Where-Object { $_.Id -eq 3076 }).Count

    $records.ToArray() | ForEach-Object { $_ | ConvertTo-Json -Compress -Depth 5 } |
        Set-Content -LiteralPath (Join-Path $EvidenceDirectory 'codeintegrity-events.jsonl') -Encoding UTF8

    return [pscustomobject][ordered]@{
        CollectedAtUtc = Get-UtcTimestamp
        QueriedEventIds = @(3076, 3077, 3089, 3091)
        MaxEvents = $MaxEvents
        EventCount = $records.Count
        EnforcementBlockEventCount = $blockEventCount
        AuditEventCount = $auditEventCount
        QueryError = $queryError
    }
}

function Get-BthPanRuntimeEvidence {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param()

    $driverFile = Get-FileEvidence -Path (Join-Path $env:SystemRoot 'System32\drivers\bthpan.sys')
    $serviceKey = Get-RegistryKeySnapshot -Path 'HKLM:\SYSTEM\CurrentControlSet\Services\BthPan'
    $panAdapter = $null
    $adapterError = $null
    try {
        $panAdapter = @(Get-CimInstance -ClassName Win32_NetworkAdapter -ErrorAction Stop |
            Where-Object { [string]$_.Name -match 'Bluetooth' -and [string]$_.Name -match '(PAN|Personal Area)' } |
            Select-Object Name, NetEnabled, PNPDeviceID)
    }
    catch {
        $adapterError = $_.Exception.Message
    }

    return [pscustomobject][ordered]@{
        CollectedAtUtc = Get-UtcTimestamp
        BthPanSysFile = $driverFile
        BthPanServiceKey = $serviceKey
        BluetoothPanAdapters = $panAdapter
        AdapterQueryError = $adapterError
    }
}

function Get-DriverSetupLogEvidence {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory = $true)] [ValidateNotNullOrEmpty()] [string]$EvidenceDirectory
    )

    $targetDir = Join-Path $EvidenceDirectory 'setupapi'
    New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
    $results = New-Object 'System.Collections.Generic.List[object]'

    foreach ($logName in @('setupapi.dev.log', 'setupapi.setup.log')) {
        $sourcePath = Join-Path $env:SystemRoot ('INF\{0}' -f $logName)
        $entry = [ordered]@{
            LogName = $logName
            SourcePath = $sourcePath
            Present = $false
            Copied = $false
            SizeBytes = $null
            SkippedReason = $null
            ErrorMessage = $null
        }
        try {
            if (Test-Path -LiteralPath $sourcePath -PathType Leaf) {
                $entry['Present'] = $true
                $size = (Get-Item -LiteralPath $sourcePath -Force).Length
                $entry['SizeBytes'] = [int64]$size
                if ($size -le $script:MaxCopiedLogBytes) {
                    Copy-Item -LiteralPath $sourcePath -Destination (Join-Path $targetDir $logName) -Force
                    $entry['Copied'] = $true
                }
                else {
                    $entry['SkippedReason'] = ('size {0} exceeds cap {1}' -f $size, $script:MaxCopiedLogBytes)
                }
            }
        }
        catch {
            $entry['ErrorMessage'] = $_.Exception.Message
        }
        $results.Add([pscustomobject]$entry) | Out-Null
    }

    return [pscustomobject][ordered]@{
        CollectedAtUtc = Get-UtcTimestamp
        Logs = $results.ToArray()
    }
}

function Get-DeployScriptInventory {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory = $true)] [ValidateNotNullOrEmpty()] [string]$ScriptDirectory
    )

    $names = @(
        'Deploy-AMDChipsetDriverOnWindowsServer.ps1',
        'Deploy-AMDGraphicsDriverOnWindowsServer.ps1',
        'Deploy-AMDNpuDriverOnWindowsServer.ps1',
        'Deploy-MSBthPanInboxOnWindowsServer.ps1',
        'Collect-WindowsServerConfigurationEvidence.ps1'
    )
    $records = New-Object 'System.Collections.Generic.List[object]'
    foreach ($name in $names) {
        $path = Join-Path $ScriptDirectory $name
        $fileEvidence = Get-FileEvidence -Path $path -SkipAuthenticode
        $scriptVersion = $null
        $scriptTag = $null
        if ($fileEvidence.Present) {
            try {
                $head = Get-Content -LiteralPath $path -TotalCount 900 -ErrorAction Stop
                foreach ($line in $head) {
                    if ($null -eq $scriptVersion -and $line -match "ScriptVersion\s*=\s*'([^']+)'") { $scriptVersion = $Matches[1] }
                    if ($null -eq $scriptTag -and $line -match "ScriptTag\s*=\s*'([^']+)'") { $scriptTag = $Matches[1] }
                    if ($null -ne $scriptVersion -and $null -ne $scriptTag) { break }
                }
            }
            catch { } # psa-disable-line PSA3004 -- identity parse is best-effort; file evidence above still records the hash
        }
        $records.Add([pscustomobject][ordered]@{
            FileName = $name
            ScriptVersion = $scriptVersion
            ScriptTag = $scriptTag
            File = $fileEvidence
        }) | Out-Null
    }

    return [pscustomobject][ordered]@{
        CollectedAtUtc = Get-UtcTimestamp
        ScriptDirectory = $ScriptDirectory
        Scripts = $records.ToArray()
    }
}

function Get-WorkspaceInventoryEvidence {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory = $true)] [ValidateNotNullOrEmpty()] [string]$ScriptDirectory
    )

    $workRoots = @(
        'C:\Temp\Workspace_AMD-Chipset',
        'C:\Temp\Workspace_AMD-Graphics',
        'C:\Temp\Workspace_AMD-NPU',
        'C:\Temp\Workspace_Microsoft-BthPan'
    )
    $records = New-Object 'System.Collections.Generic.List[object]'
    foreach ($workRoot in $workRoots) {
        $entry = [ordered]@{
            WorkRoot = $workRoot
            Present = (Test-Path -LiteralPath $workRoot)
            LogFileNames = @()
            SubdirectoryNames = @()
        }
        if ($entry['Present']) {
            try {
                $entry['SubdirectoryNames'] = @(Get-ChildItem -LiteralPath $workRoot -Directory -Force -ErrorAction SilentlyContinue | ForEach-Object Name)
                $logsDir = Join-Path $workRoot 'logs'
                if (Test-Path -LiteralPath $logsDir) {
                    $entry['LogFileNames'] = @(Get-ChildItem -LiteralPath $logsDir -File -Force -ErrorAction SilentlyContinue | ForEach-Object Name)
                }
            }
            catch { } # psa-disable-line PSA3004 -- inventory is best-effort; Present is already recorded
        }
        $records.Add([pscustomobject]$entry) | Out-Null
    }

    $runArtifactZipNames = @()
    try {
        $runArtifactZipNames = @(Get-ChildItem -LiteralPath $ScriptDirectory -Filter '*_run-artifacts_*.zip' -File -ErrorAction SilentlyContinue |
            Sort-Object LastWriteTime -Descending | ForEach-Object Name)
    }
    catch { } # psa-disable-line PSA3004 -- inventory is best-effort

    return [pscustomobject][ordered]@{
        CollectedAtUtc = Get-UtcTimestamp
        WorkRoots = $records.ToArray()
        RunArtifactZipNames = $runArtifactZipNames
    }
}

#endregion

#region Assessment, reporting, output-root resolution and main flow

function Get-NormalizedDirectoryPath {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory = $true)] [ValidateNotNullOrEmpty()] [string]$Path
    )
    return [System.IO.Path]::GetFullPath($Path).TrimEnd('\')
}

function Resolve-OutputRoot {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter()] [AllowEmptyString()] [string]$Requested,
        [Parameter(Mandatory = $true)] [ValidateNotNullOrEmpty()] [string]$ScriptDirectory
    )

    if ([string]::IsNullOrWhiteSpace($Requested)) {
        return $ScriptDirectory
    }

    $normalized = Get-NormalizedDirectoryPath -Path $Requested
    $allowed = @($ScriptDirectory, 'C:\Temp')
    foreach ($candidate in $allowed) {
        if ($normalized -ieq (Get-NormalizedDirectoryPath -Path $candidate)) {
            if (-not (Test-Path -LiteralPath $normalized)) {
                New-Item -ItemType Directory -Path $normalized -Force | Out-Null
            }
            return $normalized
        }
    }
    throw ('OutputRoot {0} is not permitted. Allowed locations: the script directory ({1}) or C:\Temp.' -f $Requested, $ScriptDirectory)
}

function Get-SanitizedNameFragment {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter()] [AllowEmptyString()] [string]$Value
    )

    if ([string]::IsNullOrWhiteSpace($Value)) { return '' }
    $sanitized = ($Value -replace '[^A-Za-z0-9._-]', '-')
    if ($sanitized.Length -gt 64) { $sanitized = $sanitized.Substring(0, 64) }
    return $sanitized.Trim('-')
}

function New-AssessmentItem {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory = $true)] [ValidateNotNullOrEmpty()] [string]$Name,
        [Parameter(Mandatory = $true)] [ValidateSet('PASS', 'FAIL', 'REVIEW', 'INFO')] [string]$Status,
        [Parameter()] [AllowEmptyString()] [string]$Detail = ''
    )

    return [pscustomobject][ordered]@{
        Name = $Name
        Status = $Status
        Detail = $Detail
    }
}

function Get-ConfigurationAssessment {
    [CmdletBinding()]
    [OutputType([object[]])]
    param(
        [Parameter(Mandatory = $true)] [object]$OsEvidence,
        [Parameter(Mandatory = $true)] [object]$PendingReboot,
        [Parameter(Mandatory = $true)] [object]$PnpEvidence,
        [Parameter(Mandatory = $true)] [object]$DriverStore,
        [Parameter(Mandatory = $true)] [object]$CertificateEvidence,
        [Parameter(Mandatory = $true)] [object]$BootSecurity,
        [Parameter(Mandatory = $true)] [object]$CodeIntegrityEvents,
        [Parameter(Mandatory = $true)] [object]$SetupLogEvidence,
        [Parameter(Mandatory = $true)] [object]$LoadDiagnostics,
        [Parameter(Mandatory = $true)] [object]$ScriptInventory,
        [Parameter(Mandatory = $true)] [object]$BthPanRuntime
    )

    $items = New-Object 'System.Collections.Generic.List[object]'

    # 1) OS identity
    $osOk = (-not [string]::IsNullOrWhiteSpace([string]$OsEvidence.OsCaption)) -and ($OsEvidence.ProductType -eq 3)
    $items.Add((New-AssessmentItem -Name 'OS identity' `
        -Status $(if ($osOk) { 'PASS' } else { 'REVIEW' }) `
        -Detail ('{0} build {1} UBR {2} ProductType {3}' -f $OsEvidence.OsCaption, $OsEvidence.OsBuildNumber, $OsEvidence.Ubr, $OsEvidence.ProductType))) | Out-Null

    # 2) Pending reboot
    $pendingStatus = switch ([string]$PendingReboot.Classification) {
        'None' { 'PASS' }
        'Advisory' { 'INFO' }
        default { 'REVIEW' }
    }
    $items.Add((New-AssessmentItem -Name 'Pending reboot state' -Status $pendingStatus `
        -Detail ('classification={0}; cbs={1}; wu={2}; pfroBlocking={3}' -f $PendingReboot.Classification, $PendingReboot.CbsRebootPending, $PendingReboot.WindowsUpdateRebootPending, ($PendingReboot.PendingFileRenamePresent -and -not $PendingReboot.PendingFileRenameOperations.AdvisoryCleanupOnly)))) | Out-Null

    # 3) Problem PnP devices
    $problemCount = [int]$PnpEvidence.ProblemDeviceCount
    $problemDetail = if ($problemCount -eq 0) { ('0 problem devices of {0}' -f $PnpEvidence.DeviceCount) }
    else {
        $names = @($PnpEvidence.ProblemDevices | Select-Object -First 3 | ForEach-Object { '{0}(code {1} {2})' -f $_.Name, $_.ConfigManagerErrorCode, (($_.ConfigManagerErrorName -split ' - ')[0]) })
        ('{0} problem device(s): {1}' -f $problemCount, ($names -join '; '))
    }
    $items.Add((New-AssessmentItem -Name 'Problem PnP devices' `
        -Status $(if ($problemCount -eq 0) { 'PASS' } else { 'REVIEW' }) -Detail $problemDetail)) | Out-Null

    # 3a) Driver load diagnostics. Separated from the raw problem-device
    # count because the two answer different questions: how many devices
    # are unhappy, versus what kind of unhappy. A missing service binary
    # and a rejected signature both surface as a problem code, and the
    # remedies have nothing in common.
    $missingBinary = [int]$LoadDiagnostics.MissingServiceBinaryCount
    $missingDetail = if ($missingBinary -eq 0) { 'no problem device references an absent driver binary' }
    else {
        $mb = @($LoadDiagnostics.ProblemDevices | Where-Object { $_.ServiceBinaryPresent -eq $false } |
                Select-Object -First 3 | ForEach-Object { '{0} -> {1}' -f $_.ServiceName, $_.ServiceImagePathResolved })
        ('{0} device(s) bound to a service whose binary is absent: {1}' -f $missingBinary, ($mb -join '; '))
    }
    $items.Add((New-AssessmentItem -Name 'Driver binary presence' `
        -Status $(if ($missingBinary -eq 0) { 'PASS' } else { 'FAIL' }) -Detail $missingDetail)) | Out-Null

    $sigFail = [int]$LoadDiagnostics.SignatureRelatedFailureCount
    $setupFailSections = @($LoadDiagnostics.SetupApi.FailureSections).Count
    $items.Add((New-AssessmentItem -Name 'Driver load failure classification' `
        -Status $(if ($setupFailSections -eq 0) { 'PASS' } elseif ($sigFail -gt 0) { 'FAIL' } else { 'REVIEW' }) `
        -Detail ('setupapi failure sections={0}; signature-attributable={1}' -f $setupFailSections, $sigFail))) | Out-Null

    # 4) Targeted devices (informational context for the deploy scripts)
    $items.Add((New-AssessmentItem -Name 'Targeted AMD/BthPan devices' -Status 'INFO' `
        -Detail ('{0} device(s) match the deploy-target HWID families' -f $PnpEvidence.TargetedDeviceCount))) | Out-Null

    # 5) Driver store enumeration
    $storeOk = [bool]$DriverStore.PnputilCapture.Succeeded
    $items.Add((New-AssessmentItem -Name 'Driver store enumeration' `
        -Status $(if ($storeOk) { 'PASS' } else { 'FAIL' }) `
        -Detail ('pnputil exit={0}; parsed {1} package(s); Win32_PnPSignedDriver {2} row(s)' -f $DriverStore.PnputilCapture.ExitCode, $DriverStore.ParsedEntryCount, $DriverStore.SignedDriverCount))) | Out-Null

    # 6) Project certificate stores
    $certificateCount = [int]$CertificateEvidence.CertificateCount
    $certStatus = if ($certificateCount -eq 0) { 'INFO' }
    elseif ($CertificateEvidence.StoresConsistent) { 'PASS' }
    else { 'REVIEW' }
    $certDetail = if ($certificateCount -eq 0) { 'no project self-sign certificate installed (expected before I01)' }
    else {
        ('root={0} publisher={1} consistent={2}' -f @($CertificateEvidence.RootThumbprints).Count, @($CertificateEvidence.TrustedPublisherThumbprints).Count, $CertificateEvidence.StoresConsistent)
    }
    $items.Add((New-AssessmentItem -Name 'Project certificate stores' -Status $certStatus -Detail $certDetail)) | Out-Null

    # 7) Secure Boot state
    $secureBootDetail = if ($null -ne $BootSecurity.SecureBootEnabled) { ('enabled={0}' -f $BootSecurity.SecureBootEnabled) }
    else { ('unavailable: {0}' -f $BootSecurity.SecureBootQueryError) }
    $items.Add((New-AssessmentItem -Name 'Secure Boot state' -Status 'INFO' -Detail $secureBootDetail)) | Out-Null

    # 8) Test signing / integrity checks
    $bootOptionStatus = if ($null -eq $BootSecurity.TestSigningEnabled) { 'REVIEW' }
    elseif ($BootSecurity.TestSigningEnabled -or ($BootSecurity.NoIntegrityChecksEnabled -eq $true)) { 'REVIEW' }
    else { 'PASS' }
    $items.Add((New-AssessmentItem -Name 'Boot signing options' -Status $bootOptionStatus `
        -Detail ('testsigning={0}; nointegritychecks={1}; bcdCaptured={2}' -f $BootSecurity.TestSigningEnabled, $BootSecurity.NoIntegrityChecksEnabled, $BootSecurity.BcdCaptureSucceeded))) | Out-Null

    # 9) WDAC policy file
    $wdacDetail = if ($BootSecurity.WdacSiPolicyFile.Present) { ('SiPolicy.p7b present; sha256={0}' -f $BootSecurity.WdacSiPolicyFile.Sha256) }
    else { 'SiPolicy.p7b not present' }
    $items.Add((New-AssessmentItem -Name 'WDAC policy file' -Status 'INFO' -Detail $wdacDetail)) | Out-Null

    # 10) CodeIntegrity enforcement blocks
    $blockCount = [int]$CodeIntegrityEvents.EnforcementBlockEventCount
    $ciDetail = ('block(3077)={0}; audit(3076)={1}; collected={2}' -f $blockCount, $CodeIntegrityEvents.AuditEventCount, $CodeIntegrityEvents.EventCount)
    if (-not [string]::IsNullOrEmpty([string]$CodeIntegrityEvents.QueryError)) {
        $ciDetail = $ciDetail + ('; query: {0}' -f $CodeIntegrityEvents.QueryError)
    }
    $items.Add((New-AssessmentItem -Name 'CodeIntegrity block events' `
        -Status $(if ($blockCount -eq 0) { 'PASS' } else { 'REVIEW' }) -Detail $ciDetail)) | Out-Null

    # 11) Driver setup log collection
    $devLog = @($SetupLogEvidence.Logs | Where-Object { $_.LogName -eq 'setupapi.dev.log' } | Select-Object -First 1)
    $devLogEntry = if ($devLog.Count -gt 0) { $devLog[0] } else { $null }
    $setupStatus = if ($null -ne $devLogEntry -and $devLogEntry.Copied) { 'PASS' }
    elseif ($null -ne $devLogEntry -and $devLogEntry.Present) { 'REVIEW' }
    else { 'INFO' }
    $setupDetail = if ($null -eq $devLogEntry) { 'collection disabled or unavailable' }
    elseif ($devLogEntry.Copied) { ('setupapi.dev.log copied ({0} bytes)' -f $devLogEntry.SizeBytes) }
    elseif (-not $devLogEntry.Present) { 'setupapi.dev.log not present' }
    else { ('setupapi.dev.log not copied: {0}{1}' -f $devLogEntry.SkippedReason, $devLogEntry.ErrorMessage) }
    $items.Add((New-AssessmentItem -Name 'Driver setup log' -Status $setupStatus -Detail $setupDetail)) | Out-Null

    # 12) Deploy script inventory
    $presentScripts = @($ScriptInventory.Scripts | Where-Object { $_.File.Present })
    $versionSummary = (@($presentScripts | ForEach-Object {
        if ($null -ne $_.ScriptVersion) { $_.ScriptVersion } else { $_.FileName }
    }) -join ', ')
    $items.Add((New-AssessmentItem -Name 'Repository script inventory' -Status 'INFO' `
        -Detail ('{0} of {1} present: {2}' -f $presentScripts.Count, @($ScriptInventory.Scripts).Count, $versionSummary))) | Out-Null

    # 13) BthPan runtime state
    $bthDetail = ('bthpan.sys={0}; service key={1}; PAN adapter(s)={2}' -f `
        $BthPanRuntime.BthPanSysFile.Present, $BthPanRuntime.BthPanServiceKey.Present, @($BthPanRuntime.BluetoothPanAdapters).Count)
    $items.Add((New-AssessmentItem -Name 'BthPan runtime state' -Status 'INFO' -Detail $bthDetail)) | Out-Null

    return $items.ToArray()
}

function Get-AssessmentReportText {
    [CmdletBinding()]
    [OutputType([string[]])]
    param(
        [Parameter(Mandatory = $true)] [object[]]$AssessmentItems,
        [Parameter(Mandatory = $true)] [string]$OverallStatus,
        [Parameter(Mandatory = $true)] [int]$ExitCode,
        [Parameter(Mandatory = $true)] [string]$EvidenceDirectory,
        [Parameter(Mandatory = $true)] [string]$ZipPath
    )

    $passCount = @($AssessmentItems | Where-Object { $_.Status -eq 'PASS' }).Count
    $failCount = @($AssessmentItems | Where-Object { $_.Status -eq 'FAIL' }).Count
    $reviewCount = @($AssessmentItems | Where-Object { $_.Status -eq 'REVIEW' }).Count
    $infoCount = @($AssessmentItems | Where-Object { $_.Status -eq 'INFO' }).Count
    $displayStatus = switch ($OverallStatus) {
        'Pass' { 'PASS' }
        'Fail' { 'FAIL' }
        'ReviewRequired' { 'REVIEW REQUIRED' }
        'FatalError' { 'FATAL ERROR' }
        default { $OverallStatus.ToUpperInvariant() }
    }

    $lines = New-Object 'System.Collections.Generic.List[string]'
    $lines.Add('')
    $lines.Add('================================================================================================================')
    $lines.Add(' WINDOWS SERVER CONFIGURATION EVIDENCE REPORT')
    $lines.Add('================================================================================================================')
    foreach ($item in $AssessmentItems) {
        $statusLabel = ('[{0}]' -f $item.Status).PadRight(9)
        $lines.Add(('{0}{1,-34} {2}' -f $statusLabel, $item.Name, $item.Detail))
    }
    $lines.Add('----------------------------------------------------------------------------------------------------------------')
    $lines.Add(('RESULT COUNTS : PASS={0}  FAIL={1}  REVIEW={2}  INFO={3}' -f $passCount, $failCount, $reviewCount, $infoCount))
    $lines.Add(('FINAL RESULT  : {0}' -f $displayStatus))
    $lines.Add(('EXIT CODE     : {0}' -f $ExitCode))
    $lines.Add(('EVIDENCE DIR  : {0}' -f $EvidenceDirectory))
    $lines.Add(('EVIDENCE ZIP  : {0}' -f $ZipPath))
    $lines.Add('================================================================================================================')
    return $lines.ToArray()
}

function Write-AssessmentConsoleReport {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)] [object[]]$AssessmentItems,
        [Parameter(Mandatory = $true)] [string]$OverallStatus,
        [Parameter(Mandatory = $true)] [int]$ExitCode,
        [Parameter(Mandatory = $true)] [string]$EvidenceDirectory,
        [Parameter(Mandatory = $true)] [string]$ZipPath
    )

    Write-Host ''
    Write-Host '================================================================================================================' -ForegroundColor Cyan
    Write-Host ' WINDOWS SERVER CONFIGURATION EVIDENCE REPORT' -ForegroundColor Cyan
    Write-Host '================================================================================================================' -ForegroundColor Cyan

    foreach ($item in $AssessmentItems) {
        $color = switch ($item.Status) {
            'PASS' { 'Green' }
            'FAIL' { 'Red' }
            'REVIEW' { 'Yellow' }
            default { 'Cyan' }
        }
        $statusLabel = ('[{0}]' -f $item.Status).PadRight(9)
        Write-Host $statusLabel -NoNewline -ForegroundColor $color
        Write-Host ('{0,-34} {1}' -f $item.Name, $item.Detail)
    }

    $passCount = @($AssessmentItems | Where-Object { $_.Status -eq 'PASS' }).Count
    $failCount = @($AssessmentItems | Where-Object { $_.Status -eq 'FAIL' }).Count
    $reviewCount = @($AssessmentItems | Where-Object { $_.Status -eq 'REVIEW' }).Count
    $infoCount = @($AssessmentItems | Where-Object { $_.Status -eq 'INFO' }).Count
    $displayStatus = switch ($OverallStatus) {
        'Pass' { 'PASS' }
        'Fail' { 'FAIL' }
        'ReviewRequired' { 'REVIEW REQUIRED' }
        'FatalError' { 'FATAL ERROR' }
        default { $OverallStatus.ToUpperInvariant() }
    }
    $finalColor = switch ($OverallStatus) {
        'Pass' { 'Green' }
        'Fail' { 'Red' }
        'FatalError' { 'Red' }
        default { 'Yellow' }
    }

    Write-Host '----------------------------------------------------------------------------------------------------------------' -ForegroundColor DarkGray
    Write-Host ('RESULT COUNTS : PASS={0}  FAIL={1}  REVIEW={2}  INFO={3}' -f $passCount, $failCount, $reviewCount, $infoCount)
    Write-Host 'FINAL RESULT  : ' -NoNewline
    Write-Host $displayStatus -ForegroundColor $finalColor
    Write-Host ('EXIT CODE     : {0}' -f $ExitCode)
    Write-Host ('EVIDENCE DIR  : {0}' -f $EvidenceDirectory)
    Write-Host ('EVIDENCE ZIP  : {0}' -f $ZipPath)
    Write-Host '================================================================================================================' -ForegroundColor Cyan
}

# ---------------------------------------------------------------------------
# Main flow
# ---------------------------------------------------------------------------

$scriptDirectory = if (-not [string]::IsNullOrWhiteSpace($PSScriptRoot)) {
    Get-NormalizedDirectoryPath -Path $PSScriptRoot
}
else {
    Get-NormalizedDirectoryPath -Path (Split-Path -Parent $MyInvocation.MyCommand.Path)
}

$exitCode = 1
try {
    $resolvedOutputRoot = Resolve-OutputRoot -Requested $OutputRoot -ScriptDirectory $scriptDirectory
    $timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'
    $invokedByFragment = Get-SanitizedNameFragment -Value $InvokedBy
    $baseName = if ([string]::IsNullOrEmpty($invokedByFragment)) {
        ('WindowsServerConfigurationEvidence_{0}_{1}' -f $Stage, $timestamp)
    }
    else {
        ('WindowsServerConfigurationEvidence_{0}_{1}_{2}' -f $Stage, $invokedByFragment, $timestamp)
    }
    $evidenceDir = Join-Path $resolvedOutputRoot $baseName
    $zipPath = Join-Path $resolvedOutputRoot ($baseName + '.zip')
    New-Item -ItemType Directory -Path $evidenceDir -Force | Out-Null

    Write-Host ''
    Write-Host ('Windows Server configuration evidence collector {0} (schema {1})' -f $script:CollectorVersion, $script:SchemaVersion) -ForegroundColor Cyan
    Write-Host ('Stage: {0}   InvokedBy: {1}' -f $Stage, $(if ([string]::IsNullOrWhiteSpace($InvokedBy)) { '(none)' } else { $InvokedBy }))
    Write-Host ('Evidence directory: {0}' -f $evidenceDir)
    Write-Host ''

    Write-Host '[1/11] Operating system identity...' -ForegroundColor DarkGray
    $osEvidence = Get-OperatingSystemEvidence
    Write-EvidenceJson -InputObject $osEvidence -Directory $evidenceDir -FileName 'environment.json'

    Write-Host '[2/11] Pending reboot state...' -ForegroundColor DarkGray
    $pendingReboot = Get-PendingRebootEvidence
    Write-EvidenceJson -InputObject $pendingReboot -Directory $evidenceDir -FileName 'pending-reboot.json'

    Write-Host '[3/11] PnP device inventory...' -ForegroundColor DarkGray
    $pnpEvidence = Get-PnpDeviceEvidence
    Write-EvidenceJson -InputObject $pnpEvidence -Directory $evidenceDir -FileName 'pnp-devices.json'

    Write-Host '[4/11] Driver store inventory...' -ForegroundColor DarkGray
    $driverStore = Get-DriverStoreEvidence -EvidenceDirectory $evidenceDir
    Write-EvidenceJson -InputObject $driverStore -Directory $evidenceDir -FileName 'driver-store.json'

    Write-Host '[5/11] Project certificate stores...' -ForegroundColor DarkGray
    $certificateEvidence = Get-ProjectCertificateEvidence
    Write-EvidenceJson -InputObject $certificateEvidence -Directory $evidenceDir -FileName 'project-certificates.json'

    Write-Host '[6/11] Boot security state...' -ForegroundColor DarkGray
    $bootSecurity = Get-BootSecurityEvidence -EvidenceDirectory $evidenceDir
    Write-EvidenceJson -InputObject $bootSecurity -Directory $evidenceDir -FileName 'boot-security.json'

    Write-Host '[7/11] CodeIntegrity events...' -ForegroundColor DarkGray
    $codeIntegrityEvents = Get-CodeIntegrityEventEvidence -EvidenceDirectory $evidenceDir
    Write-EvidenceJson -InputObject $codeIntegrityEvents -Directory $evidenceDir -FileName 'codeintegrity-events.json'

    Write-Host '[8/11] Driver setup logs...' -ForegroundColor DarkGray
    $setupLogEvidence = if (-not $SkipSetupApiLog) {
        Get-DriverSetupLogEvidence -EvidenceDirectory $evidenceDir
    }
    else {
        [pscustomobject][ordered]@{ CollectedAtUtc = Get-UtcTimestamp; Logs = @() }
    }
    Write-EvidenceJson -InputObject $setupLogEvidence -Directory $evidenceDir -FileName 'driver-setup-logs.json'

    Write-Host '[9/11] Device load diagnostics...' -ForegroundColor DarkGray
    # Reads the copy inside the bundle when one was made, so the parse and
    # the archived text are the same bytes; falls back to the live log when
    # the copy was skipped (size cap) or -SkipSetupApiLog was passed.
    $setupApiForParse = Join-Path (Join-Path $evidenceDir 'setupapi') 'setupapi.dev.log'
    if (-not (Test-Path -LiteralPath $setupApiForParse)) {
        $setupApiForParse = Join-Path $env:SystemRoot 'INF\setupapi.dev.log'
    }
    $loadDiagnostics = Get-DeviceLoadDiagnosticEvidence -PnpEvidence $pnpEvidence -SetupApiLogPath $setupApiForParse
    Write-EvidenceJson -InputObject $loadDiagnostics -Directory $evidenceDir -FileName 'device-load-diagnostics.json'

    Write-Host '[10/11] Repository script and workspace inventory...' -ForegroundColor DarkGray
    $scriptInventory = Get-DeployScriptInventory -ScriptDirectory $scriptDirectory
    Write-EvidenceJson -InputObject $scriptInventory -Directory $evidenceDir -FileName 'deploy-scripts.json'
    $workspaceInventory = Get-WorkspaceInventoryEvidence -ScriptDirectory $scriptDirectory
    Write-EvidenceJson -InputObject $workspaceInventory -Directory $evidenceDir -FileName 'workspace-inventory.json'

    Write-Host '[11/11] BthPan runtime state...' -ForegroundColor DarkGray
    $bthPanRuntime = Get-BthPanRuntimeEvidence
    Write-EvidenceJson -InputObject $bthPanRuntime -Directory $evidenceDir -FileName 'bthpan-runtime.json'

    $assessmentItems = Get-ConfigurationAssessment `
        -OsEvidence $osEvidence -PendingReboot $pendingReboot -PnpEvidence $pnpEvidence `
        -DriverStore $driverStore -CertificateEvidence $certificateEvidence -BootSecurity $bootSecurity `
        -CodeIntegrityEvents $codeIntegrityEvents -SetupLogEvidence $setupLogEvidence `
        -LoadDiagnostics $loadDiagnostics `
        -ScriptInventory $scriptInventory -BthPanRuntime $bthPanRuntime

    $failCount = @($assessmentItems | Where-Object { $_.Status -eq 'FAIL' }).Count
    $reviewCount = @($assessmentItems | Where-Object { $_.Status -eq 'REVIEW' }).Count
    $overallStatus = if ($failCount -gt 0) { 'Fail' }
    elseif ($reviewCount -gt 0) { 'ReviewRequired' }
    else { 'Pass' }
    $exitCode = if ($overallStatus -eq 'Pass') { 0 } else { 2 }

    $summary = [pscustomobject][ordered]@{
        SchemaVersion = $script:SchemaVersion
        CollectorVersion = $script:CollectorVersion
        CollectorIdentity = $Script:ScriptShortTag
        GeneratedAtUtc = Get-UtcTimestamp
        Stage = $Stage
        InvokedBy = $InvokedBy
        ComputerName = [string]$env:COMPUTERNAME
        OsCaption = [string]$osEvidence.OsCaption
        OsBuildNumber = [string]$osEvidence.OsBuildNumber
        Ubr = $osEvidence.Ubr
        OverallStatus = $overallStatus
        ExitCode = $exitCode
        AssessmentItems = @($assessmentItems)
    }
    Write-EvidenceJson -InputObject $summary -Directory $evidenceDir -FileName 'summary.json'

    @(
        ('SchemaVersion: {0}' -f $summary.SchemaVersion)
        ('CollectorVersion: {0}' -f $summary.CollectorVersion)
        ('GeneratedAtUtc: {0}' -f $summary.GeneratedAtUtc)
        ('Stage: {0}' -f $summary.Stage)
        ('InvokedBy: {0}' -f $summary.InvokedBy)
        ('ComputerName: {0}' -f $summary.ComputerName)
        ('Os: {0} build {1} UBR {2}' -f $summary.OsCaption, $summary.OsBuildNumber, $summary.Ubr)
        ('OverallStatus: {0}' -f $summary.OverallStatus)
        ('ExitCode: {0}' -f $summary.ExitCode)
    ) | Set-Content -LiteralPath (Join-Path $evidenceDir 'summary.txt') -Encoding UTF8

    Get-AssessmentReportText -AssessmentItems @($assessmentItems) -OverallStatus $overallStatus `
        -ExitCode $exitCode -EvidenceDirectory $evidenceDir -ZipPath $zipPath |
        Set-Content -LiteralPath (Join-Path $evidenceDir 'assessment-report.txt') -Encoding UTF8

    if (Test-Path -LiteralPath $zipPath) { Remove-Item -LiteralPath $zipPath -Force }
    Compress-Archive -Path (Join-Path $evidenceDir '*') -DestinationPath $zipPath -CompressionLevel Optimal -Force

    Write-AssessmentConsoleReport -AssessmentItems @($assessmentItems) -OverallStatus $overallStatus `
        -ExitCode $exitCode -EvidenceDirectory $evidenceDir -ZipPath $zipPath
}
catch {
    Write-Host ''
    Write-Host ('FATAL: configuration evidence collection failed: {0}' -f $_.Exception.Message) -ForegroundColor Red
    if ($null -ne $_.ScriptStackTrace) {
        foreach ($line in ($_.ScriptStackTrace -split "`n")) {
            Write-Host ('    {0}' -f $line.TrimEnd()) -ForegroundColor DarkRed
        }
    }
    $exitCode = 1
}

exit $exitCode

#endregion
