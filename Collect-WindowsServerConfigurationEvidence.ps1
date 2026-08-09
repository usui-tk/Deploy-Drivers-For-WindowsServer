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

$Script:ScriptVersion  = 'collector-2026.08.09-c11'
$Script:ScriptTag      = 'windows-server-configuration-evidence-collector'
$Script:ScriptHash     = 'unavailable'
try {
    $Script:ScriptHash = (Get-FileHash -LiteralPath $MyInvocation.MyCommand.Path -Algorithm SHA256 -ErrorAction Stop).Hash.Substring(0, 12).ToLowerInvariant()
} catch { } # psa-disable-line PSA3004 -- self-hash is identity metadata only; collection must proceed without it
$Script:ScriptShortTag = ('{0}/{1}' -f $Script:ScriptVersion, $Script:ScriptHash)
$script:SchemaVersion = 'windows-server-configuration-evidence/1.7'
# Per-stage outcome ledger (SPEC D.45). Populated by Invoke-EvidenceStage,
# written to stage-results.json, and surfaced in the assessment so a bundle
# always declares its own completeness.
$script:StageResults = New-Object 'System.Collections.Generic.List[object]'
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
        # Substring test, not -like: in a PowerShell wildcard '[' opens a
        # character class, so '>>>*[Device Install*' is an unterminated
        # class and throws WildcardPatternException on the first line it
        # is applied to. .Contains carries no pattern semantics at all,
        # which is what this test actually wants.
        $lineText = [string]$lines[$i]
        if ($lineText.StartsWith('>>>') -and $lineText.Contains('[Device Install')) { $startIndexes.Add($i) | Out-Null }
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
            if ($line.StartsWith('>>>') -and $line.Contains('Section start')) {
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
            if ($line.Contains('[Exit status: FAILURE')) { $failed = $true }
            # A '!!!' marker is setupapi's own failure flag and is the ONLY
            # failure signal some sections carry: a device that installs
            # cleanly but will not START logs '!!! Device not started' with a
            # CM problem code and still exits SUCCESS. Those sections are the
            # load failures - exactly what this extract is for - and keying
            # only off 'Error 0x' and the exit status silently drops them.
            if ($line.StartsWith('!!!')) { $failed = $true }
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
        # Resolve the device's service via the registry snapshot helper.
        # Get-NamedRegistryValue takes a SNAPSHOT produced by
        # Get-RegistryKeySnapshot, not a path - passing -Path binds nothing
        # and throws ParameterBindingException at every problem device.
        $imagePath = ''
        $imagePathResolved = ''
        $imagePathExists = $null
        $serviceStartType = ''
        try {
            $enumSnapshot = Get-RegistryKeySnapshot -Path ('HKLM:\SYSTEM\CurrentControlSet\Enum\' + $id)
            $serviceName = [string](Get-NamedRegistryValue -Snapshot $enumSnapshot -Name 'Service' -DefaultValue '')
        } catch {
            $serviceName = ''
        }
        if (-not [string]::IsNullOrWhiteSpace($serviceName)) {
            try {
                $svcSnapshot = Get-RegistryKeySnapshot -Path ('HKLM:\SYSTEM\CurrentControlSet\Services\' + $serviceName)
                $imagePath = [string](Get-NamedRegistryValue -Snapshot $svcSnapshot -Name 'ImagePath' -DefaultValue '')
                $startValue = Get-NamedRegistryValue -Snapshot $svcSnapshot -Name 'Start'
                if ($null -ne $startValue) { $serviceStartType = [string]$startValue }
            } catch {
                $imagePath = ''
            }
        }
        if (-not [string]::IsNullOrWhiteSpace($imagePath)) {
            $candidate = Resolve-ServiceImagePath -ImagePath $imagePath
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

function Resolve-ServiceImagePath {
    # Turn a service ImagePath registry value into a testable filesystem path.
    #
    # ImagePath is stored in several shapes and the differences are not
    # cosmetic - a caller that skips this normalisation silently concludes
    # that every driver binary is missing:
    #   \SystemRoot\System32\drivers\x.sys   (kernel drivers, most common)
    #   \??\C:\path\x.sys                    (NT object-manager prefix)
    #   system32\drivers\x.sys               (relative, no leading separator)
    #   "C:\path\svc.exe" -k netsvcs         (user-mode services, quoted + args)
    #
    # A regression this function exists to prevent: the earlier inline
    # version used the regex '^\SystemRoot', in which \S is the
    # non-whitespace character class, so it never matched anything and the
    # \SystemRoot form was returned untouched.
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter()]
        [AllowEmptyString()]
        [string]$ImagePath
    )
    if ([string]::IsNullOrWhiteSpace($ImagePath)) { return '' }
    $value = $ImagePath.Trim()
    # Plain concatenation rather than Join-Path: Join-Path resolves the
    # drive qualifier, which makes this function untestable anywhere but a
    # Windows host with that drive present. The separator handling here is
    # trivial and the testability is not.
    $root = [string]$env:SystemRoot
    if ([string]::IsNullOrWhiteSpace($root)) { $root = 'C:\Windows' }
    $root = $root.TrimEnd('\')

    # User-mode services quote the executable and append arguments. Take the
    # quoted span when present, otherwise everything up to the first space
    # that is followed by a switch-looking token.
    if ($value.StartsWith('"')) {
        $closing = $value.IndexOf('"', 1)
        if ($closing -gt 1) { $value = $value.Substring(1, $closing - 1) }
    } elseif ($value -match '^(?<path>\S+\.(exe|sys|dll))\s') {
        $value = $Matches['path']
    }

    if ($value.StartsWith('\??\')) {
        $value = $value.Substring(4)
    } elseif ($value -match '^\\SystemRoot\\') {
        $value = $root + '\' + $value.Substring('\SystemRoot\'.Length)
    } elseif ($value.StartsWith('\')) {
        # Any other leading-separator form is relative to the system root.
        $value = $root + '\' + $value.TrimStart('\')
    } elseif ($value -notmatch '^[A-Za-z]:\\') {
        $value = $root + '\' + $value
    }
    return $value
}

function Get-ServiceConfigurationEvidence {
    # Complete Windows service configuration, every service, no filter.
    #
    # WHY the whole set and not just driver services: the failure that
    # motivated this stage was a Windows Server DEFAULT CONFIGURATION issue -
    # an inbox wireless component whose binary is not staged on Server SKUs,
    # which broke an unrelated third-party adapter during a driver install.
    # Narrowing the census to driver services, or to this project's own
    # services, would have recorded everything except the thing that
    # mattered. The evidence bundle is read by people and by language models
    # trying to explain a host they cannot log into; a partial census invites
    # confident wrong answers about what is present.
    #
    # Cost is bounded: a Server install carries a few hundred services, and
    # the record per service is small.
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param()

    $records = New-Object 'System.Collections.Generic.List[object]'
    $missingBinaries = New-Object 'System.Collections.Generic.List[object]'
    $collectionErrors = New-Object 'System.Collections.Generic.List[string]'

    $services = @()
    try {
        $services = @(Get-CimInstance -ClassName Win32_Service -ErrorAction Stop)
    } catch {
        $collectionErrors.Add(('Win32_Service query failed: {0}' -f $_.Exception.Message)) | Out-Null
    }

    # Win32_Service covers user-mode services and drivers registered as
    # services, but NOT every kernel driver: those live in
    # Win32_SystemDriver. Both are needed for a complete picture, and the
    # missing-binary case that motivated this stage is a kernel driver.
    $systemDrivers = @()
    try {
        $systemDrivers = @(Get-CimInstance -ClassName Win32_SystemDriver -ErrorAction Stop)
    } catch {
        $collectionErrors.Add(('Win32_SystemDriver query failed: {0}' -f $_.Exception.Message)) | Out-Null
    }

    # Registry is the authority for ImagePath, Group, ErrorControl and for
    # services that exist as keys but are not surfaced by either CIM class.
    $registryByName = @{}
    try {
        $servicesRoot = 'HKLM:\SYSTEM\CurrentControlSet\Services'
        foreach ($key in @(Get-ChildItem -LiteralPath $servicesRoot -ErrorAction Stop)) {
            $props = $null
            try {
                $props = Get-ItemProperty -LiteralPath $key.PSPath -ErrorAction Stop
            } catch {
                continue
            }
            $registryByName[$key.PSChildName] = $props
        }
    } catch {
        $collectionErrors.Add(('Services registry enumeration failed: {0}' -f $_.Exception.Message)) | Out-Null
    }

    $startTypeName = @{ 0 = 'Boot'; 1 = 'System'; 2 = 'Automatic'; 3 = 'Manual'; 4 = 'Disabled' }
    $serviceTypeName = @{
        1 = 'KernelDriver'; 2 = 'FileSystemDriver'; 4 = 'Adapter'; 8 = 'RecognizerDriver'
        16 = 'Win32OwnProcess'; 32 = 'Win32ShareProcess'; 256 = 'InteractiveProcess'
    }

    $seen = New-Object 'System.Collections.Generic.HashSet[string]' ([System.StringComparer]::OrdinalIgnoreCase)
    $sources = @()
    foreach ($s in $services) { $sources += , @($s, 'Win32_Service') }
    foreach ($s in $systemDrivers) { $sources += , @($s, 'Win32_SystemDriver') }

    foreach ($pair in $sources) {
        $svc = $pair[0]
        $origin = [string]$pair[1]
        $name = [string](Get-PropertyValue -InputObject $svc -Name 'Name')
        if ([string]::IsNullOrWhiteSpace($name)) { continue }
        if (-not $seen.Add($name)) { continue }

        $reg = $null
        if ($registryByName.ContainsKey($name)) { $reg = $registryByName[$name] }

        $rawImagePath = [string](Get-PropertyValue -InputObject $svc -Name 'PathName')
        if ([string]::IsNullOrWhiteSpace($rawImagePath) -and $null -ne $reg) {
            $rawImagePath = [string](Get-PropertyValue -InputObject $reg -Name 'ImagePath')
        }
        $resolved = Resolve-ServiceImagePath -ImagePath $rawImagePath
        $exists = $null
        if (-not [string]::IsNullOrWhiteSpace($resolved)) {
            try { $exists = [bool](Test-Path -LiteralPath $resolved) } catch { $exists = $null }
        }

        $startNumeric = $null
        $groupName = ''
        $errorControl = $null
        if ($null -ne $reg) {
            $startValue = Get-PropertyValue -InputObject $reg -Name 'Start'
            if ($null -ne $startValue) { $startNumeric = [int]$startValue }
            $groupName = [string](Get-PropertyValue -InputObject $reg -Name 'Group')
            $ecValue = Get-PropertyValue -InputObject $reg -Name 'ErrorControl'
            if ($null -ne $ecValue) { $errorControl = [int]$ecValue }
        }
        $typeNumeric = $null
        if ($null -ne $reg) {
            $typeValue = Get-PropertyValue -InputObject $reg -Name 'Type'
            if ($null -ne $typeValue) { $typeNumeric = [int]$typeValue }
        }

        $dependsOn = @()
        $rawDeps = $null
        if ($null -ne $reg) { $rawDeps = Get-PropertyValue -InputObject $reg -Name 'DependOnService' }
        if ($null -ne $rawDeps) { $dependsOn = @($rawDeps | ForEach-Object { [string]$_ } | Where-Object { $_ }) }

        $record = [pscustomobject][ordered]@{
            Name = $name
            DisplayName = [string](Get-PropertyValue -InputObject $svc -Name 'DisplayName')
            Description = [string](Get-PropertyValue -InputObject $svc -Name 'Description')
            Source = $origin
            State = [string](Get-PropertyValue -InputObject $svc -Name 'State')
            Status = [string](Get-PropertyValue -InputObject $svc -Name 'Status')
            StartMode = [string](Get-PropertyValue -InputObject $svc -Name 'StartMode')
            StartTypeNumeric = $startNumeric
            StartTypeName = $(if ($null -ne $startNumeric -and $startTypeName.ContainsKey($startNumeric)) { $startTypeName[$startNumeric] } else { '' })
            ServiceTypeNumeric = $typeNumeric
            ServiceTypeName = $(if ($null -ne $typeNumeric -and $serviceTypeName.ContainsKey($typeNumeric)) { $serviceTypeName[$typeNumeric] } else { [string](Get-PropertyValue -InputObject $svc -Name 'ServiceType') })
            IsDriverService = ($typeNumeric -eq 1 -or $typeNumeric -eq 2 -or $typeNumeric -eq 8)
            Group = $groupName
            ErrorControl = $errorControl
            StartName = [string](Get-PropertyValue -InputObject $svc -Name 'StartName')
            ProcessId = (Get-PropertyValue -InputObject $svc -Name 'ProcessId')
            ExitCode = (Get-PropertyValue -InputObject $svc -Name 'ExitCode')
            DelayedAutoStart = [bool](Get-PropertyValue -InputObject $svc -Name 'DelayedAutoStart' -DefaultValue $false)
            ImagePathRaw = $rawImagePath
            ImagePathResolved = $resolved
            ImagePathExists = $exists
            DependsOnService = $dependsOn
        }
        $records.Add($record) | Out-Null
        if ($exists -eq $false) { $missingBinaries.Add($record) | Out-Null }
    }

    # Services that exist only as a registry key (no CIM projection).
    foreach ($name in $registryByName.Keys) {
        if ($seen.Contains($name)) { continue }
        $reg = $registryByName[$name]
        $rawImagePath = [string](Get-PropertyValue -InputObject $reg -Name 'ImagePath')
        if ([string]::IsNullOrWhiteSpace($rawImagePath)) { continue }
        $resolved = Resolve-ServiceImagePath -ImagePath $rawImagePath
        $exists = $null
        if (-not [string]::IsNullOrWhiteSpace($resolved)) {
            try { $exists = [bool](Test-Path -LiteralPath $resolved) } catch { $exists = $null }
        }
        $startNumeric = $null
        $startValue = Get-PropertyValue -InputObject $reg -Name 'Start'
        if ($null -ne $startValue) { $startNumeric = [int]$startValue }
        $typeNumeric = $null
        $typeValue = Get-PropertyValue -InputObject $reg -Name 'Type'
        if ($null -ne $typeValue) { $typeNumeric = [int]$typeValue }
        $record = [pscustomobject][ordered]@{
            Name = $name
            DisplayName = [string](Get-PropertyValue -InputObject $reg -Name 'DisplayName')
            Description = ''
            Source = 'Registry'
            State = ''
            Status = ''
            StartMode = ''
            StartTypeNumeric = $startNumeric
            StartTypeName = $(if ($null -ne $startNumeric -and $startTypeName.ContainsKey($startNumeric)) { $startTypeName[$startNumeric] } else { '' })
            ServiceTypeNumeric = $typeNumeric
            ServiceTypeName = $(if ($null -ne $typeNumeric -and $serviceTypeName.ContainsKey($typeNumeric)) { $serviceTypeName[$typeNumeric] } else { '' })
            IsDriverService = ($typeNumeric -eq 1 -or $typeNumeric -eq 2 -or $typeNumeric -eq 8)
            Group = [string](Get-PropertyValue -InputObject $reg -Name 'Group')
            ErrorControl = $(if ($null -ne (Get-PropertyValue -InputObject $reg -Name 'ErrorControl')) { [int](Get-PropertyValue -InputObject $reg -Name 'ErrorControl') } else { $null })
            StartName = [string](Get-PropertyValue -InputObject $reg -Name 'ObjectName')
            ProcessId = $null
            ExitCode = $null
            DelayedAutoStart = $false
            ImagePathRaw = $rawImagePath
            ImagePathResolved = $resolved
            ImagePathExists = $exists
            DependsOnService = @()
        }
        $records.Add($record) | Out-Null
        if ($exists -eq $false) { $missingBinaries.Add($record) | Out-Null }
    }

    # Reverse dependency index: for each service, who needs it. The
    # forward list alone does not answer "what breaks if this is absent",
    # which is the question a missing binary raises.
    $requiredBy = @{}
    foreach ($r in $records) {
        foreach ($dep in @($r.DependsOnService)) {
            if ([string]::IsNullOrWhiteSpace($dep)) { continue }
            if (-not $requiredBy.ContainsKey($dep)) { $requiredBy[$dep] = New-Object 'System.Collections.Generic.List[string]' }
            $requiredBy[$dep].Add($r.Name) | Out-Null
        }
    }
    $dependencyIndex = New-Object 'System.Collections.Generic.List[object]'
    foreach ($key in ($requiredBy.Keys | Sort-Object)) {
        $dependencyIndex.Add([pscustomobject][ordered]@{
            ServiceName = [string]$key
            RequiredBy = @($requiredBy[$key].ToArray() | Sort-Object)
        }) | Out-Null
    }

    $driverCount = 0
    $runningCount = 0
    $disabledCount = 0
    foreach ($r in $records) {
        if ($r.IsDriverService) { $driverCount++ }
        if ($r.State -eq 'Running') { $runningCount++ }
        if ($r.StartTypeNumeric -eq 4) { $disabledCount++ }
    }

    return [pscustomobject][ordered]@{
        CollectedAtUtc = Get-UtcTimestamp
        ServiceCount = $records.Count
        DriverServiceCount = $driverCount
        RunningCount = $runningCount
        DisabledCount = $disabledCount
        MissingBinaryCount = $missingBinaries.Count
        CollectionErrors = $collectionErrors.ToArray()
        MissingBinaryServices = $missingBinaries.ToArray()
        DependencyIndex = $dependencyIndex.ToArray()
        Services = @($records.ToArray() | Sort-Object -Property Name)
    }
}

function Get-ServerFeatureServiceEvidence {
    # Windows Server optional-feature state, paired with the services those
    # features stage.
    #
    # WHY this pairing exists: a Server SKU ships many inbox components as
    # OPTIONAL, and a device INF that assumes a client SKU can declare a
    # service whose binary is only present once the corresponding feature is
    # installed. The observed case: an Intel Wi-Fi INF declares a vwifibus
    # service, the binary is staged by the wireless networking feature, that
    # feature is not installed by default on Server, and the device install
    # therefore failed with 0xe0000217 - on a host where nothing about the
    # driver package itself was wrong. That diagnosis takes seconds with this
    # table and a long time without it.
    #
    # The watch list is deliberately small and evidence-driven rather than an
    # attempt to enumerate every feature-to-service mapping in Windows.
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter()]
        $ServiceEvidence
    )
    $features = @()
    $featureError = ''
    try {
        if (Get-Command -Name 'Get-WindowsFeature' -ErrorAction SilentlyContinue) {
            $features = @(Get-WindowsFeature -ErrorAction Stop | ForEach-Object {
                [pscustomobject][ordered]@{
                    Name = [string]$_.Name
                    DisplayName = [string]$_.DisplayName
                    InstallState = [string]$_.InstallState
                    FeatureType = [string]$_.FeatureType
                }
            })
        } else {
            $featureError = 'Get-WindowsFeature is not available (not a Server SKU, or ServerManager module absent)'
        }
    } catch {
        $featureError = $_.Exception.Message
    }

    $byName = @{}
    if ($null -ne $ServiceEvidence -and $ServiceEvidence.PSObject.Properties['Services']) {
        foreach ($s in @($ServiceEvidence.Services)) { $byName[[string]$s.Name] = $s }
    }

    $watchList = @(
        [pscustomobject]@{ Feature = 'Wireless-Networking'; Services = @('vwifibus', 'vwifimp', 'vwififlt', 'NativeWifiP', 'WlanSvc', 'wlansvc', 'dot3svc') }
        [pscustomobject]@{ Feature = 'BITS'; Services = @('BITS') }
        [pscustomobject]@{ Feature = 'Windows-Defender'; Services = @('WinDefend', 'WdNisSvc') }
        [pscustomobject]@{ Feature = 'Hyper-V'; Services = @('vmms', 'vmcompute') }
        [pscustomobject]@{ Feature = 'BitLocker'; Services = @('BDESVC') }
        [pscustomobject]@{ Feature = 'Server-Media-Foundation'; Services = @('') }
    )

    $findings = New-Object 'System.Collections.Generic.List[object]'
    foreach ($entry in $watchList) {
        # FeatureNameKnown separates 'this feature is not installed' from
        # 'this feature name does not exist on this SKU'. The watch list is
        # written from one Server version's naming; a name that is simply
        # absent elsewhere would otherwise report Unknown forever and quietly
        # stop being a check (SPEC SS D.46.3).
        $state = 'Unknown'
        $featureNameKnown = $false
        foreach ($f in $features) {
            if ($f.Name -eq $entry.Feature) { $state = $f.InstallState; $featureNameKnown = $true; break }
        }
        foreach ($svcName in @($entry.Services)) {
            if ([string]::IsNullOrWhiteSpace($svcName)) { continue }
            $present = $byName.ContainsKey($svcName)
            $binaryPresent = $null
            $imagePath = ''
            if ($present) {
                $binaryPresent = $byName[$svcName].ImagePathExists
                $imagePath = [string]$byName[$svcName].ImagePathResolved
            }
            $classification = if (-not $present) { 'ServiceKeyAbsent' }
                elseif ($binaryPresent -eq $false) { 'ServiceKeyPresentBinaryMissing' }
                elseif ($binaryPresent -eq $true) { 'Healthy' }
                else { 'Indeterminate' }
            $findings.Add([pscustomobject][ordered]@{
                Feature = [string]$entry.Feature
                FeatureNameKnown = $featureNameKnown
                FeatureInstallState = [string]$state
                ServiceName = [string]$svcName
                ServiceKeyPresent = $present
                BinaryPresent = $binaryPresent
                ImagePathResolved = $imagePath
                Classification = $classification
            }) | Out-Null
        }
    }

    $atRisk = 0
    $unknownNames = New-Object 'System.Collections.Generic.List[string]'
    foreach ($f in $findings) {
        if ($f.Classification -eq 'ServiceKeyPresentBinaryMissing') { $atRisk++ }
        if (-not $f.FeatureNameKnown -and -not $unknownNames.Contains([string]$f.Feature)) {
            $unknownNames.Add([string]$f.Feature) | Out-Null
        }
    }

    return [pscustomobject][ordered]@{
        CollectedAtUtc = Get-UtcTimestamp
        FeatureQueryError = $featureError
        FeatureCount = @($features).Count
        InstalledFeatureCount = @($features | Where-Object { $_.InstallState -eq 'Installed' }).Count
        BinaryMissingWatchCount = $atRisk
        UnknownFeatureNameCount = $unknownNames.Count
        UnknownFeatureNames = $unknownNames.ToArray()
        WatchedServices = $findings.ToArray()
        Features = $features
    }
}

function Invoke-EvidenceStage {
    # Run one collection stage in isolation.
    #
    # WHY (SPEC D.45): the collector previously ran all stages inside a
    # single try block whose catch skipped straight past the archive step.
    # One stage throwing therefore cost every later stage AND the evidence
    # ZIP - the operator was left with a loose directory of partial results
    # and no bundle to hand over. The four deploy scripts already archive
    # their run artifacts from a top-level finally regardless of outcome;
    # this brings the collector to the same contract.
    #
    # A stage that throws is recorded as a failed stage and collection
    # continues. Evidence collection is diagnostic: partial evidence with an
    # honest note about what is missing beats no evidence at all.
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory = $true)] [ValidateNotNullOrEmpty()] [string]$Label,
        [Parameter(Mandatory = $true)] [ValidateNotNullOrEmpty()] [scriptblock]$Body,
        [Parameter()] [AllowNull()] [object]$Fallback = $null
    )
    Write-Host $Label -ForegroundColor DarkGray
    try {
        $value = & $Body
        $script:StageResults.Add([pscustomobject][ordered]@{
            Label = $Label
            Succeeded = $true
            ErrorMessage = ''
        }) | Out-Null
        return $value
    }
    catch {
        $message = $_.Exception.Message
        Write-Host ('    STAGE FAILED: {0}' -f $message) -ForegroundColor Red
        if ($null -ne $_.ScriptStackTrace) {
            foreach ($line in (($_.ScriptStackTrace -split "`n") | Select-Object -First 4)) {
                Write-Host ('      {0}' -f $line.TrimEnd()) -ForegroundColor DarkRed
            }
        }
        Write-Host '    Collection continues; this stage''s evidence will be absent from the bundle.' -ForegroundColor DarkYellow
        $script:StageResults.Add([pscustomobject][ordered]@{
            Label = $Label
            Succeeded = $false
            ErrorMessage = [string]$message
        }) | Out-Null
        return $Fallback
    }
}

function Get-StageFailureEvidence {
    # Machine-readable record of which stages ran and which did not. Written
    # unconditionally so a bundle always states its own completeness rather
    # than leaving the reader to infer it from missing files.
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param()
    # .ToArray(), never @( ): the array-subexpression binder throws
    # ArgumentException on a List[object] - that exact element type, even
    # when empty (SPEC SS D.42.4).
    $stages = $script:StageResults.ToArray()
    $failed = @($stages | Where-Object { -not $_.Succeeded })
    return [pscustomobject][ordered]@{
        CollectedAtUtc = Get-UtcTimestamp
        StageCount = $stages.Count
        FailedStageCount = $failed.Count
        Complete = ($failed.Count -eq 0)
        Stages = $stages
    }
}

function Get-OsCapabilityEvidence {
    # Record the OS-version-dependent facts this project's scripts branch on,
    # measured rather than inferred.
    #
    # WHY: the deploy scripts adapt to the host OS in several places - the
    # inf2cat target name, certificate parameters, which PnP cmdlets exist,
    # whether a CIM class is present, which optional-feature names are valid.
    # Every one of those is currently something a troubleshooter has to look
    # up in SPEC and then assume held on the host in front of them. When a
    # run misbehaves on a Server SKU nobody has exercised recently, the first
    # question is always "which of these differed", and the bundle could not
    # answer it.
    #
    # Nothing here is a judgement about whether a capability SHOULD be
    # present. It records what IS present, so a later diagnosis can be
    # checked against the host instead of against an expectation.
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param()

    $build = 0
    $caption = ''
    $ubr = $null
    try {
        $os = Get-CimInstance -ClassName Win32_OperatingSystem -ErrorAction Stop
        $caption = [string](Get-PropertyValue -InputObject $os -Name 'Caption')
        $buildText = [string](Get-PropertyValue -InputObject $os -Name 'BuildNumber')
        if ($buildText -match '^\d+$') { $build = [int]$buildText }
    } catch {
        $caption = ''
    }
    try {
        $cv = Get-RegistryKeySnapshot -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion'
        $ubrValue = Get-NamedRegistryValue -Snapshot $cv -Name 'UBR'
        if ($null -ne $ubrValue) { $ubr = [int]$ubrValue }
    } catch {
        $ubr = $null
    }

    # Build-to-profile mapping mirrored from the deploy scripts. Recorded so a
    # bundle states which profile the scripts WOULD select on this host,
    # without the troubleshooter having to run one to find out.
    $profileTable = @{
        14393 = @{ Code = 'WS2016'; Inf2catOsArg = 'Server2016_X64'; CertKeyLength = 2048; CertValidYears = 3 }
        17763 = @{ Code = 'WS2019'; Inf2catOsArg = 'ServerRS5_X64';  CertKeyLength = 4096; CertValidYears = 5 }
        20348 = @{ Code = 'WS2022'; Inf2catOsArg = 'ServerFE_X64';   CertKeyLength = 4096; CertValidYears = 5 }
        26100 = @{ Code = 'WS2025'; Inf2catOsArg = 'Server2025_X64'; CertKeyLength = 4096; CertValidYears = 5 }
    }
    $matched = $null
    $exactMatch = $false
    if ($profileTable.ContainsKey($build)) {
        $matched = $profileTable[$build]
        $exactMatch = $true
    }
    else {
        $lower = @($profileTable.Keys | Sort-Object | Where-Object { $_ -le $build })
        if ($lower.Count -gt 0) { $matched = $profileTable[$lower[-1]] }
    }

    # Cmdlets the scripts probe for and degrade around. Restart-PnpDevice is
    # the documented WS2019+ boundary; the rest are recorded because a
    # missing one changes which rebind strategy runs.
    $cmdletNames = @(
        'Restart-PnpDevice', 'Disable-PnpDevice', 'Enable-PnpDevice',
        'Get-PnpDevice', 'Get-WindowsDriver', 'Get-WindowsFeature',
        'Install-WindowsFeature', 'Compress-Archive', 'Expand-Archive',
        'Get-AuthenticodeSignature', 'New-SelfSignedCertificate',
        'Get-CimInstance', 'ConvertTo-Json', 'Get-FileHash'
    )
    $cmdlets = New-Object 'System.Collections.Generic.List[object]'
    foreach ($n in $cmdletNames) {
        $cmd = $null
        try { $cmd = Get-Command -Name $n -ErrorAction SilentlyContinue } catch { $cmd = $null }
        $cmdlets.Add([pscustomobject][ordered]@{
            Name = $n
            Present = ($null -ne $cmd)
            Source = $(if ($null -ne $cmd) { [string]$cmd.Source } else { '' })
            Version = $(if ($null -ne $cmd -and $cmd.Version) { [string]$cmd.Version } else { '' })
        }) | Out-Null
    }

    # CIM classes the scripts try and catch around. A class that is absent is
    # the difference between an immediate-activate policy path and a reboot
    # fallback, and the two look nothing alike in a log.
    $classNames = @(
        @{ Namespace = 'root\Microsoft\Windows\CI'; Class = 'PS_UpdateAndCompareCIPolicy' },
        @{ Namespace = 'root\cimv2'; Class = 'Win32_PnPEntity' },
        @{ Namespace = 'root\cimv2'; Class = 'Win32_PnPSignedDriver' },
        @{ Namespace = 'root\cimv2'; Class = 'Win32_SystemDriver' },
        @{ Namespace = 'root\cimv2'; Class = 'Win32_Service' },
        @{ Namespace = 'root\wmi';   Class = 'MS_SystemInformation' }
    )
    $classes = New-Object 'System.Collections.Generic.List[object]'
    foreach ($entry in $classNames) {
        $present = $false
        $errorText = ''
        try {
            $null = Get-CimClass -Namespace $entry.Namespace -ClassName $entry.Class -ErrorAction Stop
            $present = $true
        } catch {
            $errorText = $_.Exception.Message
        }
        $classes.Add([pscustomobject][ordered]@{
            Namespace = [string]$entry.Namespace
            Class = [string]$entry.Class
            Present = $present
            ErrorMessage = $errorText
        }) | Out-Null
    }

    # signtool / inf2cat: the two tools P05 and P08 depend on. Their absence
    # changes the WHQL verdict from a measurement to a conservative default,
    # which is a distinction the analysis output alone does not make obvious.
    $tools = New-Object 'System.Collections.Generic.List[object]'
    foreach ($tool in @('signtool.exe', 'inf2cat.exe', 'pnputil.exe', 'bcdedit.exe', 'certutil.exe')) {
        $found = ''
        try {
            $cmd = Get-Command -Name $tool -ErrorAction SilentlyContinue
            if ($null -ne $cmd) { $found = [string]$cmd.Source }
        } catch {
            $found = ''
        }
        if ([string]::IsNullOrWhiteSpace($found)) {
            foreach ($root in @('C:\Program Files (x86)\Windows Kits\10\bin', 'C:\Program Files\Windows Kits\10\bin')) {
                if (-not (Test-Path -LiteralPath $root)) { continue }
                try {
                    $hit = Get-ChildItem -LiteralPath $root -Filter $tool -Recurse -ErrorAction SilentlyContinue |
                           Where-Object { $_.FullName -like '*x64*' } | Select-Object -First 1
                    if ($null -ne $hit) { $found = [string]$hit.FullName; break }
                } catch {
                    continue
                }
            }
        }
        $version = ''
        if (-not [string]::IsNullOrWhiteSpace($found) -and (Test-Path -LiteralPath $found)) {
            try { $version = [string](Get-Item -LiteralPath $found).VersionInfo.ProductVersion } catch { $version = '' }
        }
        $tools.Add([pscustomobject][ordered]@{
            Tool = [string]$tool
            Path = $found
            Present = (-not [string]::IsNullOrWhiteSpace($found))
            ProductVersion = $version
        }) | Out-Null
    }

    $missingCmdlets = @($cmdlets | Where-Object { -not $_.Present } | ForEach-Object { $_.Name })
    $missingClasses = @($classes | Where-Object { -not $_.Present } | ForEach-Object { $_.Class })
    $missingTools = @($tools | Where-Object { -not $_.Present } | ForEach-Object { $_.Tool })

    return [pscustomobject][ordered]@{
        CollectedAtUtc = Get-UtcTimestamp
        OsCaption = $caption
        OsBuild = $build
        Ubr = $ubr
        PowerShellVersion = [string]$PSVersionTable.PSVersion
        PowerShellEdition = [string]$PSVersionTable.PSEdition
        Culture = [string](Get-Culture).Name
        ProfileCode = $(if ($null -ne $matched) { [string]$matched.Code } else { '' })
        ProfileExactBuildMatch = $exactMatch
        ExpectedInf2catOsArg = $(if ($null -ne $matched) { [string]$matched.Inf2catOsArg } else { '' })
        ExpectedCertKeyLength = $(if ($null -ne $matched) { [int]$matched.CertKeyLength } else { 0 })
        ExpectedCertValidYears = $(if ($null -ne $matched) { [int]$matched.CertValidYears } else { 0 })
        MissingCmdletCount = $missingCmdlets.Count
        MissingCmdlets = $missingCmdlets
        MissingCimClassCount = $missingClasses.Count
        MissingCimClasses = $missingClasses
        MissingToolCount = $missingTools.Count
        MissingTools = $missingTools
        Cmdlets = $cmdlets.ToArray()
        CimClasses = $classes.ToArray()
        Tools = $tools.ToArray()
    }
}

function Get-ArchiveCapabilityEvidence {
    # Prove, on this host, that the archive mechanism the collector depends on
    # actually works - by using it.
    #
    # WHY: the bundle's own ZIP is produced by Compress-Archive in a finally
    # block. If that call fails, the finally reports a warning and the
    # operator gets a loose directory. Working out afterwards WHY it failed
    # means guessing at PowerShell version, item count, path length, or free
    # space. This probe writes a handful of small files to a temp directory,
    # compresses them, reads the result back, and records what happened -
    # measured on the host, before the real archive is attempted.
    #
    # The probe is deliberately tiny. It answers "does this work at all here",
    # not "how does it scale", and it must never be the reason a collection
    # fails: every path is caught.
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param()

    $result = [pscustomobject][ordered]@{
        CollectedAtUtc = Get-UtcTimestamp
        CompressArchiveAvailable = $false
        CompressArchiveVersion = ''
        ProbeAttempted = $false
        ProbeSucceeded = $false
        ProbeEntryCount = 0
        ProbeArchiveBytes = 0
        MaxPathLengthSeen = 0
        LongPathsEnabled = $null
        TempPath = ''
        FreeBytesOnTempDrive = $null
        ErrorMessage = ''
    }

    try {
        $cmd = Get-Command -Name 'Compress-Archive' -ErrorAction SilentlyContinue
        if ($null -ne $cmd) {
            $result.CompressArchiveAvailable = $true
            if ($cmd.Version) { $result.CompressArchiveVersion = [string]$cmd.Version }
        }
    } catch {
        $result.CompressArchiveAvailable = $false
    }

    try {
        $lp = Get-RegistryKeySnapshot -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem'
        $lpValue = Get-NamedRegistryValue -Snapshot $lp -Name 'LongPathsEnabled'
        if ($null -ne $lpValue) { $result.LongPathsEnabled = ([int]$lpValue -eq 1) }
    } catch {
        $result.LongPathsEnabled = $null
    }

    # $env:TEMP can be empty (service contexts, constrained runspaces, and
    # non-Windows hosts running the extracted functions under test). An empty
    # value makes every Join-Path below throw on a mandatory parameter, which
    # would report 'archive unavailable' when the real answer is 'nowhere to
    # probe'. Fall back through the documented alternatives and record which
    # one was used.
    $temp = [string]$env:TEMP
    if ([string]::IsNullOrWhiteSpace($temp)) { $temp = [string]$env:TMP }
    if ([string]::IsNullOrWhiteSpace($temp)) {
        try { $temp = [string][System.IO.Path]::GetTempPath() } catch { $temp = '' }
    }
    $result.TempPath = $temp
    # Free space is best-effort. Split-Path -Qualifier throws outright on a
    # path with no drive qualifier, so the qualifier is matched rather than
    # parsed - free space is a diagnostic detail and must never be the reason
    # this probe reports failure.
    try {
        if ($temp -match '^(?<q>[A-Za-z]):') {
            $drive = Get-PSDrive -Name $Matches['q'] -ErrorAction Stop
            if ($null -ne $drive.Free) { $result.FreeBytesOnTempDrive = [int64]$drive.Free }
        }
    } catch {
        $result.FreeBytesOnTempDrive = $null
    }

    if (-not $result.CompressArchiveAvailable) {
        $result.ErrorMessage = 'Compress-Archive is not available on this host'
        return $result
    }

    if ([string]::IsNullOrWhiteSpace($temp)) {
        $result.ErrorMessage = 'no writable temp directory could be resolved (TEMP, TMP and GetTempPath all empty)'
        return $result
    }

    $probeDir = ''
    $probeZip = ''
    try {
        $result.ProbeAttempted = $true
        $stamp = (Get-Date).ToString('yyyyMMddHHmmssfff')
        $probeDir = Join-Path $temp ('evidence-archive-probe-{0}' -f $stamp)
        $probeZip = Join-Path $temp ('evidence-archive-probe-{0}.zip' -f $stamp)
        $null = New-Item -Path $probeDir -ItemType Directory -Force -ErrorAction Stop
        $nested = Join-Path $probeDir 'nested'
        $null = New-Item -Path $nested -ItemType Directory -Force -ErrorAction Stop
        for ($i = 1; $i -le 3; $i++) {
            $leaf = Join-Path $probeDir ('probe-{0}.json' -f $i)
            # Plain concatenation, not -f: the format operator treats { and }
            # as placeholder delimiters, so a JSON literal on its left side
            # fails to parse before any file is written.
            Set-Content -LiteralPath $leaf -Value ('probe ' + $i) -Encoding UTF8 -ErrorAction Stop
            if ($leaf.Length -gt $result.MaxPathLengthSeen) { $result.MaxPathLengthSeen = $leaf.Length }
        }
        $deep = Join-Path $nested 'probe-nested.txt'
        Set-Content -LiteralPath $deep -Value 'nested' -Encoding UTF8 -ErrorAction Stop
        if ($deep.Length -gt $result.MaxPathLengthSeen) { $result.MaxPathLengthSeen = $deep.Length }

        Compress-Archive -Path (Join-Path $probeDir '*') -DestinationPath $probeZip -Force -ErrorAction Stop

        if (Test-Path -LiteralPath $probeZip) {
            $result.ProbeArchiveBytes = [int64](Get-Item -LiteralPath $probeZip).Length
            try {
                Add-Type -AssemblyName 'System.IO.Compression.FileSystem' -ErrorAction SilentlyContinue
                $zip = [System.IO.Compression.ZipFile]::OpenRead($probeZip)
                try { $result.ProbeEntryCount = $zip.Entries.Count } finally { $zip.Dispose() }
            } catch {
                # Entry count is a bonus; producing the archive is the claim.
                $result.ProbeEntryCount = 0
            }
            $result.ProbeSucceeded = ($result.ProbeArchiveBytes -gt 0)
        }
    }
    catch {
        $result.ErrorMessage = $_.Exception.Message
    }
    finally {
        foreach ($path in @($probeDir, $probeZip)) {
            if (-not [string]::IsNullOrWhiteSpace($path)) {
                try { Remove-Item -LiteralPath $path -Recurse -Force -ErrorAction SilentlyContinue } catch { $null = $null }
            }
        }
    }
    return $result
}

function Get-FileVersionInfoSafe {
    # File version for a driver binary, tolerant of every way this can fail.
    # Used for framework binaries whose version is the whole point of the
    # record, so an unreadable file must produce an explicit 'unknown' rather
    # than an absent property.
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter()]
        [AllowEmptyString()]
        [string]$Path
    )
    $record = [pscustomobject][ordered]@{
        Path = [string]$Path
        Exists = $false
        FileVersion = ''
        ProductVersion = ''
        FileVersionRaw = ''
        SizeBytes = $null
        LastWriteTimeUtc = ''
        ErrorMessage = ''
    }
    if ([string]::IsNullOrWhiteSpace($Path)) { return $record }
    try {
        if (-not (Test-Path -LiteralPath $Path)) { return $record }
        $item = Get-Item -LiteralPath $Path -ErrorAction Stop
        $record.Exists = $true
        $record.SizeBytes = [int64]$item.Length
        $record.LastWriteTimeUtc = $item.LastWriteTimeUtc.ToString('o')
        $vi = $item.VersionInfo
        if ($null -ne $vi) {
            $record.FileVersion = [string]$vi.FileVersion
            $record.ProductVersion = [string]$vi.ProductVersion
            # FileMajorPart etc. are the authoritative numeric fields; the
            # string form is localized on some builds and can carry
            # decoration the numeric parts do not.
            $record.FileVersionRaw = ('{0}.{1}.{2}.{3}' -f $vi.FileMajorPart, $vi.FileMinorPart, $vi.FileBuildPart, $vi.FilePrivatePart)
        }
    }
    catch {
        $record.ErrorMessage = $_.Exception.Message
    }
    return $record
}

function Get-DriverFrameworkEvidence {
    # KMDF / UMDF runtime versions, and the co-installer versions present on
    # the host.
    #
    # WHY (SPEC D.47): the framework version is a hard ceiling. A driver whose
    # INF declares KmdfLibraryVersion newer than the runtime the OS provides
    # cannot load, and the failure has nothing to do with signing - so neither
    # Path A nor Path B moves it. On Windows Server 2016 the in-box KMDF is
    # older than what current driver packages are built against, which makes
    # this the first thing to check when a legacy-Server run misbehaves and
    # the last thing anyone thinks to look up.
    #
    # inf2cat /os:Server2016_X64 changes the catalog's target OS. It does not
    # lower a KMDF requirement. Recording the runtime version here is what
    # lets an INF's declared requirement be compared against the host instead
    # of assumed compatible.
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param()

    # $env:SystemRoot can be empty outside a normal Windows session, and
    # Join-Path throws on a null mandatory parameter rather than returning
    # nothing. Every path below is built by concatenation from a resolved
    # root so an unset variable produces empty records, not an exception.
    $winRoot = [string]$env:SystemRoot
    if ([string]::IsNullOrWhiteSpace($winRoot)) { $winRoot = [string]$env:windir }
    $winRoot = $winRoot.TrimEnd('\')
    $system32 = $(if ([string]::IsNullOrWhiteSpace($winRoot)) { '' } else { $winRoot + '\System32' })
    $drivers = $(if ([string]::IsNullOrWhiteSpace($system32)) { '' } else { $system32 + '\drivers' })

    $kmdf = Get-FileVersionInfoSafe -Path $(if ($drivers) { $drivers + '\Wdf01000.sys' } else { '' })
    $umdfPf = Get-FileVersionInfoSafe -Path $(if ($drivers) { $drivers + '\WudfPf.sys' } else { '' })
    $umdfRd = Get-FileVersionInfoSafe -Path $(if ($drivers) { $drivers + '\WUDFRd.sys' } else { '' })
    $umdfHost = Get-FileVersionInfoSafe -Path $(if ($system32) { $system32 + '\WUDFHost.exe' } else { '' })
    # The UMDF 2 framework library itself. WudfPf/WUDFRd/WUDFHost are the
    # platform driver, reflector and host process; this is the library an
    # UMDF 2 driver actually binds to, so its presence is the evidence that
    # a UMDF 2 runtime exists at all. Its version is a Windows component
    # version and is still not a framework version - it is recorded, not
    # converted.
    $umdfLib = Get-FileVersionInfoSafe -Path $(if ($system32) { $system32 + '\WUDFx02000.dll' } else { '' })
    if (-not $umdfLib.Exists -and $drivers) {
        $umdfLib = Get-FileVersionInfoSafe -Path ($drivers + '\UMDF\WUDFx02000.dll')
    }

    # The KMDF library version an INF may request is expressed as major.minor
    # (1.15, 1.31, ...). The runtime binary carries that in its first two
    # version parts, so it can be compared directly with an INF declaration.
    $kmdfLibraryVersion = ''
    if ($kmdf.Exists -and -not [string]::IsNullOrWhiteSpace($kmdf.FileVersionRaw)) {
        $parts = $kmdf.FileVersionRaw.Split('.')
        if ($parts.Count -ge 2) { $kmdfLibraryVersion = ('{0}.{1}' -f $parts[0], $parts[1]) }
    }
    # UMDF has no binary that carries the library version, and this code
    # used to invent one. Measured on Windows Server 2019: WudfPf.sys,
    # WUDFRd.sys and WUDFHost.exe all report 10.0.17763.9020 - the operating
    # system version - while the documented UMDF version for that build is
    # 2.27. Keeping the first two parts of one of them produced '10.0',
    # which is not a UMDF version, and which compares ABOVE every real
    # requirement - so a consumer of this field satisfies every UMDF driver
    # it looks at. Reported as unknown. The raw file versions below are kept
    # because they are evidence; the derived number was not.
    $umdfLibraryVersion = ''

    # Co-installer DLLs shipped by the WDK. A driver package that carries a
    # co-installer for a framework version the host does not have is the
    # other half of the same problem.
    $coInstallers = New-Object 'System.Collections.Generic.List[object]'
    try {
        $found = @()
        if (-not [string]::IsNullOrWhiteSpace($system32) -and (Test-Path -LiteralPath $system32)) {
            $found = @(Get-ChildItem -LiteralPath $system32 -Filter 'WdfCoInstaller*.dll' -ErrorAction SilentlyContinue)
        }
        foreach ($f in $found) {
            $coInstallers.Add((Get-FileVersionInfoSafe -Path $f.FullName)) | Out-Null
        }
    }
    catch {
        $coInstallers = New-Object 'System.Collections.Generic.List[object]'
    }

    # Service-key view of the framework, for the start type and group. A
    # framework driver that is not Boot-start is itself a finding.
    $kmdfService = [pscustomobject][ordered]@{ Present = $false; StartTypeNumeric = $null; Group = ''; ImagePath = '' }
    try {
        $snap = Get-RegistryKeySnapshot -Path 'HKLM:\SYSTEM\CurrentControlSet\Services\Wdf01000'
        if ($null -ne $snap -and $snap.Available) {
            $kmdfService.Present = $true
            $startValue = Get-NamedRegistryValue -Snapshot $snap -Name 'Start'
            if ($null -ne $startValue) { $kmdfService.StartTypeNumeric = [int]$startValue }
            $kmdfService.Group = [string](Get-NamedRegistryValue -Snapshot $snap -Name 'Group' -DefaultValue '')
            $kmdfService.ImagePath = [string](Get-NamedRegistryValue -Snapshot $snap -Name 'ImagePath' -DefaultValue '')
        }
    }
    catch {
        $kmdfService.Present = $false
    }

    return [pscustomobject][ordered]@{
        CollectedAtUtc = Get-UtcTimestamp
        KmdfLibraryVersion = $kmdfLibraryVersion
        UmdfLibraryVersion = $umdfLibraryVersion
        KmdfRuntime = $kmdf
        UmdfPlatformDriver = $umdfPf
        UmdfReflector = $umdfRd
        UmdfHost = $umdfHost
        Umdf2FrameworkLibrary = $umdfLib
        Umdf2RuntimePresent = $umdfLib.Exists
        KmdfService = $kmdfService
        CoInstallerCount = $coInstallers.Count
        CoInstallers = $coInstallers.ToArray()
    }
}

function Get-CrashEvidence {
    # Bugcheck history and dump configuration.
    #
    # WHY (SPEC D.47): a host that bugchecks during driver installation gives
    # the operator a stop code on screen for a few seconds and then reboots.
    # Everything needed to attribute it is on disk - the bugcheck parameters
    # in the System event log, the minidump, the dump configuration that
    # decides whether a dump exists at all - and none of it was in the
    # bundle. This stage records the parameters and the dump inventory so a
    # BSOD becomes an analysable event rather than a recollection.
    #
    # WDF_VIOLATION (0x10D) is the case this was written for: its first
    # parameter names the kind of framework contract that was violated, which
    # is the difference between a driver bug, a handle misuse, and an IRQL
    # error. That parameter is in event 1001 and nowhere else the bundle
    # looked.
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter()]
        [int]$MaxEvents = 20
    )

    $result = [pscustomobject][ordered]@{
        CollectedAtUtc = Get-UtcTimestamp
        CrashControl = [pscustomobject][ordered]@{
            CrashDumpEnabled = $null
            CrashDumpEnabledName = ''
            DumpFile = ''
            MinidumpDir = ''
            AutoReboot = $null
            Overwrite = $null
        }
        MemoryDumpPresent = $false
        MemoryDumpPath = ''
        MemoryDumpBytes = $null
        MinidumpCount = 0
        Minidumps = @()
        BugCheckEventCount = 0
        BugCheckEvents = @()
        UnexpectedShutdownCount = 0
        QueryError = ''
    }

    # Dump configuration. CrashDumpEnabled 0 means no dump is written at all,
    # which explains an empty Minidump directory without any further theory.
    try {
        $snap = Get-RegistryKeySnapshot -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\CrashControl'
        if ($null -ne $snap -and $snap.Available) {
            $enabled = Get-NamedRegistryValue -Snapshot $snap -Name 'CrashDumpEnabled'
            if ($null -ne $enabled) {
                $result.CrashControl.CrashDumpEnabled = [int]$enabled
                $result.CrashControl.CrashDumpEnabledName = switch ([int]$enabled) {
                    0 { 'None - no dump is written' }
                    1 { 'Complete memory dump' }
                    2 { 'Kernel memory dump' }
                    3 { 'Small memory dump (minidump)' }
                    7 { 'Automatic memory dump' }
                    default { ('Unrecognised value {0}' -f [int]$enabled) }
                }
            }
            $result.CrashControl.DumpFile = [string](Get-NamedRegistryValue -Snapshot $snap -Name 'DumpFile' -DefaultValue '')
            $result.CrashControl.MinidumpDir = [string](Get-NamedRegistryValue -Snapshot $snap -Name 'MinidumpDir' -DefaultValue '')
            $auto = Get-NamedRegistryValue -Snapshot $snap -Name 'AutoReboot'
            if ($null -ne $auto) { $result.CrashControl.AutoReboot = ([int]$auto -eq 1) }
            $ow = Get-NamedRegistryValue -Snapshot $snap -Name 'Overwrite'
            if ($null -ne $ow) { $result.CrashControl.Overwrite = ([int]$ow -eq 1) }
        }
    }
    catch {
        $result.QueryError = ('CrashControl read failed: {0}' -f $_.Exception.Message)
    }

    # Dump files. Recorded as an inventory, never copied: a kernel dump can be
    # gigabytes and this collector produces a bundle meant to be attached to
    # a message.
    $crashWinRoot = [string]$env:SystemRoot
    if ([string]::IsNullOrWhiteSpace($crashWinRoot)) { $crashWinRoot = [string]$env:windir }
    $crashWinRoot = $crashWinRoot.TrimEnd('\')
    $memoryDump = $(if ($crashWinRoot) { $crashWinRoot + '\MEMORY.DMP' } else { '' })
    try {
        if (-not [string]::IsNullOrWhiteSpace($memoryDump) -and (Test-Path -LiteralPath $memoryDump)) {
            $item = Get-Item -LiteralPath $memoryDump -ErrorAction Stop
            $result.MemoryDumpPresent = $true
            $result.MemoryDumpPath = $memoryDump
            $result.MemoryDumpBytes = [int64]$item.Length
        }
    }
    catch {
        $result.MemoryDumpPresent = $false
    }

    $minidumps = New-Object 'System.Collections.Generic.List[object]'
    try {
        $minidumpDir = $(if ($crashWinRoot) { $crashWinRoot + '\Minidump' } else { '' })
        if (-not [string]::IsNullOrWhiteSpace($minidumpDir) -and (Test-Path -LiteralPath $minidumpDir)) {
            foreach ($f in @(Get-ChildItem -LiteralPath $minidumpDir -Filter '*.dmp' -ErrorAction SilentlyContinue |
                             Sort-Object LastWriteTimeUtc -Descending | Select-Object -First 25)) {
                $minidumps.Add([pscustomobject][ordered]@{
                    Name = [string]$f.Name
                    FullName = [string]$f.FullName
                    SizeBytes = [int64]$f.Length
                    LastWriteTimeUtc = $f.LastWriteTimeUtc.ToString('o')
                }) | Out-Null
            }
        }
    }
    catch {
        $minidumps = New-Object 'System.Collections.Generic.List[object]'
    }
    $result.Minidumps = $minidumps.ToArray()
    $result.MinidumpCount = $minidumps.Count

    # Event 1001 from BugCheck carries the stop code and all four parameters.
    # The message is localized, so the numbers are extracted positionally from
    # the event's own property array rather than parsed out of the text.
    $events = New-Object 'System.Collections.Generic.List[object]'
    try {
        if (-not (Get-Command -Name 'Get-WinEvent' -ErrorAction SilentlyContinue)) {
            throw 'Get-WinEvent is not available on this host'
        }
    # NO MATCHING EVENTS IS THE HEALTHY ANSWER, NOT AN ERROR.
    # Get-WinEvent reports 'no events found' as an error record, and
    # -ErrorAction Stop turns that into a terminating error. The enclosing
    # try/catch handles it correctly and the JSON produced is right - but a
    # Windows PowerShell 5.1 transcript records terminating errors even when
    # they are caught, so every run of every script on a healthy machine
    # printed alarming red text about a query that behaved exactly as
    # expected. Probe instead: SilentlyContinue plus a null check, with
    # -ErrorVariable kept because the difference between 'no events' and a
    # real query failure carries meaning here.
        $bugCheckErr = $null
        $raw = @(Get-WinEvent -FilterHashtable @{ LogName = 'System'; ProviderName = 'Microsoft-Windows-WER-SystemErrorReporting' } `
                 -MaxEvents $MaxEvents -ErrorAction SilentlyContinue -ErrorVariable bugCheckErr)
        if ($null -ne $bugCheckErr -and @($bugCheckErr).Count -gt 0) {
            $firstMessage = [string]@($bugCheckErr)[0]
            if ($firstMessage -notmatch 'No events were found') {
                $result.QueryError = (($result.QueryError + ' ') + ('BugCheck event query: {0}' -f $firstMessage)).Trim()
            }
        }
        foreach ($e in $raw) {
            $props = @($e.Properties | ForEach-Object { [string]$_.Value })
            $events.Add([pscustomobject][ordered]@{
                TimeCreatedUtc = $e.TimeCreated.ToUniversalTime().ToString('o')
                Id = [int]$e.Id
                LevelDisplayName = [string]$e.LevelDisplayName
                BugCheckText = $(if ($props.Count -gt 0) { $props[0] } else { '' })
                Properties = $props
                Message = [string]$e.Message
            }) | Out-Null
        }
    }
    catch {
        # No matching events is the common case and is not an error.
        if ($_.Exception.Message -notmatch 'No events were found') {
            $result.QueryError = (($result.QueryError + ' ') + ('BugCheck event query: {0}' -f $_.Exception.Message)).Trim()
        }
    }
    $result.BugCheckEvents = $events.ToArray()
    $result.BugCheckEventCount = $events.Count

    # Event 41 (Kernel-Power) counts unexpected shutdowns, which catches a
    # reboot loop even when no dump was written.
    try {
        if (-not (Get-Command -Name 'Get-WinEvent' -ErrorAction SilentlyContinue)) {
            throw 'Get-WinEvent is not available on this host'
        }
        # Same probe form as above: an absent event 41 means the machine has
        # not had an unexpected shutdown, which is the good outcome.
        $kernelPowerErr = $null
        $kp = @(Get-WinEvent -FilterHashtable @{ LogName = 'System'; ProviderName = 'Microsoft-Windows-Kernel-Power'; Id = 41 } `
                -MaxEvents $MaxEvents -ErrorAction SilentlyContinue -ErrorVariable kernelPowerErr)
        $result.UnexpectedShutdownCount = $kp.Count
    }
    catch {
        $result.UnexpectedShutdownCount = 0
    }

    return $result
}

function Get-ExpectedWdfVersion {
    # The KMDF / UMDF versions an OS build ships in-box.
    #
    # Source: Microsoft's KMDF and UMDF version history tables. Recorded here
    # rather than inferred, because the number is the ceiling every driver on
    # the host has to fit under and an approximation is worse than nothing.
    # An earlier revision of this project asserted 1.15 for Windows Server
    # 2016 from memory; the documented value is 1.19 (SPEC D.52).
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter()]
        [int]$Build = 0
    )
    $table = @{
        14393 = @{ Os = 'Windows Server 2016 / Windows 10 1607'; Kmdf = '1.19'; Umdf = '2.19' }
        17763 = @{ Os = 'Windows Server 2019 / Windows 10 1809'; Kmdf = '1.27'; Umdf = '2.27' }
        20348 = @{ Os = 'Windows Server 2022';                   Kmdf = '1.33'; Umdf = '2.33' }
        26100 = @{ Os = 'Windows Server 2025';                   Kmdf = '1.33'; Umdf = '2.33' }
    }
    $exact = $table.ContainsKey($Build)
    $entry = $null
    if ($exact) {
        $entry = $table[$Build]
    }
    else {
        $lower = @($table.Keys | Sort-Object | Where-Object { $_ -le $Build })
        if ($lower.Count -gt 0) { $entry = $table[$lower[-1]] }
    }
    return [pscustomobject][ordered]@{
        Build = $Build
        ExactBuildMatch = $exact
        OsName = $(if ($null -ne $entry) { [string]$entry.Os } else { '' })
        ExpectedKmdfVersion = $(if ($null -ne $entry) { [string]$entry.Kmdf } else { '' })
        ExpectedUmdfVersion = $(if ($null -ne $entry) { [string]$entry.Umdf } else { '' })
    }
}

function ConvertTo-WdfVersionNumber {
    # Turn a major.minor WDF version into a comparable number.
    #
    # String comparison is wrong here and quietly so: '1.9' sorts above
    # '1.19', which would report a driver requesting 1.19 as satisfied by a
    # 1.9 runtime. The minor part is scaled so ordering matches the real
    # version sequence.
    [CmdletBinding()]
    [OutputType([int])]
    param(
        [Parameter()]
        [AllowEmptyString()]
        [string]$Version
    )
    if ([string]::IsNullOrWhiteSpace($Version)) { return -1 }
    $m = [regex]::Match($Version.Trim(), '^(\d+)\.(\d+)')
    if (-not $m.Success) { return -1 }
    return ([int]$m.Groups[1].Value * 1000) + [int]$m.Groups[2].Value
}

function Get-WdfCoInstallerInventory {
    # Every WdfCoInstallerNNNNN.dll on the host, with the KMDF version its
    # name encodes.
    #
    # A co-installer is shipped by a driver package and names the framework
    # version that package was built for. Finding WdfCoInstaller01031.dll on
    # a host whose runtime is 1.19 states a mismatch that no other single
    # artefact does.
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param()
    $found = New-Object 'System.Collections.Generic.List[object]'
    $roots = @()
    $winRoot = [string]$env:SystemRoot
    if ([string]::IsNullOrWhiteSpace($winRoot)) { $winRoot = [string]$env:windir }
    if (-not [string]::IsNullOrWhiteSpace($winRoot)) {
        $winRoot = $winRoot.TrimEnd('\')
        $roots = @($winRoot + '\System32', $winRoot + '\System32\DriverStore\FileRepository')
    }
    foreach ($root in $roots) {
        if ([string]::IsNullOrWhiteSpace($root)) { continue }
        try {
            if (-not (Test-Path -LiteralPath $root)) { continue }
            foreach ($f in @(Get-ChildItem -LiteralPath $root -Filter 'WdfCoInstaller*.dll' -Recurse -ErrorAction SilentlyContinue)) {
                # WdfCoInstaller01031.dll -> 01031 -> 1.31
                $ver = ''
                $m = [regex]::Match($f.Name, 'WdfCoInstaller(\d{2})(\d{3})\.dll', 'IgnoreCase')
                if ($m.Success) {
                    $ver = ('{0}.{1}' -f [int]$m.Groups[1].Value, [int]$m.Groups[2].Value)
                }
                $found.Add([pscustomobject][ordered]@{
                    Name = [string]$f.Name
                    FullName = [string]$f.FullName
                    KmdfVersion = $ver
                    KmdfVersionNumber = (ConvertTo-WdfVersionNumber -Version $ver)
                    SizeBytes = [int64]$f.Length
                    LastWriteTimeUtc = $f.LastWriteTimeUtc.ToString('o')
                }) | Out-Null
            }
        }
        catch {
            continue
        }
    }
    $versions = @($found | Where-Object { $_.KmdfVersion } | ForEach-Object { $_.KmdfVersion } | Sort-Object -Unique)
    return [pscustomobject][ordered]@{
        CollectedAtUtc = Get-UtcTimestamp
        CoInstallerCount = $found.Count
        DistinctKmdfVersions = $versions
        CoInstallers = $found.ToArray()
    }
}

function Get-WdfDependentServiceInventory {
    # Services that depend on Wdf01000 - that is, the WDF-based drivers.
    #
    # WHY this list exists: WDF_VIOLATION means the framework caught one of
    # these misbehaving. Without the list, "which driver" starts from every
    # driver on the box; with it, the suspect pool is bounded and usually
    # small. Start type matters too: a boot-start WDF driver can bugcheck
    # before anything can be logged.
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter()]
        $ServiceEvidence
    )
    $records = New-Object 'System.Collections.Generic.List[object]'
    $services = @()
    if ($null -ne $ServiceEvidence -and $ServiceEvidence.PSObject.Properties['Services']) {
        $services = @($ServiceEvidence.Services)
    }
    foreach ($s in $services) {
        $deps = @($s.DependsOnService)
        $isWdf = $false
        foreach ($d in $deps) {
            if ([string]$d -eq 'Wdf01000') { $isWdf = $true; break }
        }
        if (-not $isWdf) { continue }
        $records.Add([pscustomobject][ordered]@{
            Name = [string]$s.Name
            DisplayName = [string]$s.DisplayName
            State = [string]$s.State
            StartTypeName = [string]$s.StartTypeName
            StartTypeNumeric = $s.StartTypeNumeric
            ServiceTypeName = [string]$s.ServiceTypeName
            ImagePathResolved = [string]$s.ImagePathResolved
            ImagePathExists = $s.ImagePathExists
        }) | Out-Null
    }
    $bootStart = @($records | Where-Object { $_.StartTypeNumeric -eq 0 -or $_.StartTypeNumeric -eq 1 })
    return [pscustomobject][ordered]@{
        CollectedAtUtc = Get-UtcTimestamp
        WdfServiceCount = $records.Count
        BootOrSystemStartCount = $bootStart.Count
        BootOrSystemStartNames = @($bootStart | ForEach-Object { $_.Name })
        Services = $records.ToArray()
    }
}

function Get-WdfAssessment {
    # Compare what the host provides against what is installed on it.
    #
    # Two distinct failure modes hang off this comparison and they are worth
    # keeping apart, because only the first is predictable from static data:
    #
    #   A driver requesting a NEWER framework version than the runtime
    #   provides cannot load at all. That is not a signing failure - no
    #   amount of re-signing moves it - and it presents as a device error,
    #   not a bugcheck.
    #
    #   A driver that DOES load and then breaks the framework contract
    #   produces WDF_VIOLATION. Nothing here predicts that; what this does
    #   is bound the suspect pool when it happens.
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter()]
        $DriverFramework,

        [Parameter()]
        $OsCapability,

        [Parameter()]
        $CoInstallers,

        [Parameter()]
        $WdfServices
    )
    $build = 0
    if ($null -ne $OsCapability -and $OsCapability.PSObject.Properties['OsBuild']) {
        $build = [int]$OsCapability.OsBuild
    }
    $expected = Get-ExpectedWdfVersion -Build $build

    $actualKmdf = ''
    if ($null -ne $DriverFramework -and $DriverFramework.PSObject.Properties['KmdfLibraryVersion']) {
        $actualKmdf = [string]$DriverFramework.KmdfLibraryVersion
    }
    $actualUmdf = ''
    if ($null -ne $DriverFramework -and $DriverFramework.PSObject.Properties['UmdfLibraryVersion']) {
        $actualUmdf = [string]$DriverFramework.UmdfLibraryVersion
    }

    $actualNum = ConvertTo-WdfVersionNumber -Version $actualKmdf
    $expectedNum = ConvertTo-WdfVersionNumber -Version $expected.ExpectedKmdfVersion

    # A runtime BELOW the documented value means the file is older than the
    # build should carry, which is worth surfacing. Above is normal: servicing
    # updates the framework.
    $kmdfMatchesExpectation = $null
    if ($actualNum -ge 0 -and $expectedNum -ge 0) {
        $kmdfMatchesExpectation = ($actualNum -ge $expectedNum)
    }

    $exceeding = New-Object 'System.Collections.Generic.List[object]'
    if ($null -ne $CoInstallers -and $CoInstallers.PSObject.Properties['CoInstallers']) {
        foreach ($c in @($CoInstallers.CoInstallers)) {
            if ($c.KmdfVersionNumber -lt 0 -or $actualNum -lt 0) { continue }
            if ($c.KmdfVersionNumber -gt $actualNum) {
                $exceeding.Add([pscustomobject][ordered]@{
                    Name = [string]$c.Name
                    RequestedKmdfVersion = [string]$c.KmdfVersion
                    HostKmdfVersion = $actualKmdf
                    FullName = [string]$c.FullName
                }) | Out-Null
            }
        }
    }

    $wdfServiceCount = 0
    $bootWdfCount = 0
    if ($null -ne $WdfServices) {
        if ($WdfServices.PSObject.Properties['WdfServiceCount']) { $wdfServiceCount = [int]$WdfServices.WdfServiceCount }
        if ($WdfServices.PSObject.Properties['BootOrSystemStartCount']) { $bootWdfCount = [int]$WdfServices.BootOrSystemStartCount }
    }

    return [pscustomobject][ordered]@{
        CollectedAtUtc = Get-UtcTimestamp
        OsBuild = $build
        OsName = [string]$expected.OsName
        ExactBuildMatch = $expected.ExactBuildMatch
        ExpectedKmdfVersion = [string]$expected.ExpectedKmdfVersion
        ExpectedUmdfVersion = [string]$expected.ExpectedUmdfVersion
        ActualKmdfVersion = $actualKmdf
        ActualUmdfVersion = $actualUmdf
        # Observed and documented are kept apart on purpose. The UMDF value
        # below is documented only, and is marked usable only when THIS
        # host's measured KMDF equals its documented KMDF - that agreement
        # is the evidence the published table has kept up with this build.
        # Where measured KMDF already exceeds the documented one, the
        # documented UMDF comes from the same table and is the same age.
        KmdfDocumentationComparison = $(
            if ([string]::IsNullOrWhiteSpace($actualKmdf) -or [string]::IsNullOrWhiteSpace([string]$expected.ExpectedKmdfVersion)) { 'NotCompared' }
            elseif ($actualNum -eq $expectedNum) { 'Match' }
            elseif ($actualNum -gt $expectedNum) { 'ObservedNewerThanDocumented' }
            else { 'ObservedOlderThanDocumented' })
        Umdf2RuntimePresent = $(if ($null -ne $DriverFramework -and $DriverFramework.PSObject.Properties['Umdf2RuntimePresent']) { [bool]$DriverFramework.Umdf2RuntimePresent } else { $false })
        DocumentedUmdfUsable = $(
            ($null -ne $DriverFramework -and $DriverFramework.PSObject.Properties['Umdf2RuntimePresent'] -and
             [bool]$DriverFramework.Umdf2RuntimePresent -and
             -not [string]::IsNullOrWhiteSpace($actualKmdf) -and $actualNum -eq $expectedNum))
        KmdfMeetsExpectation = $kmdfMatchesExpectation
        CoInstallerCount = $(if ($null -ne $CoInstallers) { [int]$CoInstallers.CoInstallerCount } else { 0 })
        CoInstallersExceedingHostCount = $exceeding.Count
        CoInstallersExceedingHost = $exceeding.ToArray()
        WdfBasedServiceCount = $wdfServiceCount
        WdfBootOrSystemStartCount = $bootWdfCount
        Note = 'A co-installer above the host version indicates a package built for a newer framework. It does not predict WDF_VIOLATION, which comes from a driver that loaded and then broke the framework contract; this assessment bounds the suspect pool rather than naming a cause.'
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
        # --json is mandatory: without it CiTool blocks on a "Press Enter
        # to Exit" stdin prompt (SPEC D.16 defect class; latent here until
        # the first run on a CiTool-bearing host).
        $ciToolCapture = Invoke-CapturedCommand -FilePath $ciToolPath -ArgumentList @('-lp', '--json')
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

function ConvertFrom-CiToolPolicyList {
    # Parse `CiTool.exe --list-policies --json` output. Pure function over
    # -Content (ruling Q3) so the offline Linux harness can test it against
    # fixtures. Tolerates banner text before the JSON payload and both the
    # object ({"Policies":[...]}) and bare-array shapes. GUIDs are returned
    # brace-stripped and upper-cased so callers compare against constants.
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter()] [AllowEmptyString()] [string]$Content
    )
    $result = [pscustomobject][ordered]@{
        ParseSucceeded = $false
        PolicyCount    = $null
        PolicyIds      = @()
        ParseError     = $null
    }
    if ([string]::IsNullOrWhiteSpace($Content)) {
        $result.ParseError = 'empty content'
        return $result
    }
    try {
        $objIdx = $Content.IndexOf('{')
        $arrIdx = $Content.IndexOf('[')
        $start = if ($objIdx -lt 0) { $arrIdx }
                 elseif ($arrIdx -lt 0) { $objIdx }
                 else { [Math]::Min($objIdx, $arrIdx) }
        if ($start -lt 0) {
            $result.ParseError = 'no JSON payload found'
            return $result
        }
        $json = $Content.Substring($start) | ConvertFrom-Json -ErrorAction Stop
        $policies = @()
        if ($null -ne $json -and $json -is [System.Array]) {
            $policies = @($json)
        }
        elseif ($null -ne $json -and $json.PSObject.Properties['Policies']) {
            $policies = @($json.Policies)
        }
        $ids = @()
        foreach ($p in $policies) {
            if ($null -eq $p) { continue }
            if (-not $p.PSObject.Properties['PolicyID']) { continue }
            $idText = [string]$p.PolicyID
            if (-not [string]::IsNullOrWhiteSpace($idText)) {
                $ids += $idText.Trim('{', '}', ' ').ToUpperInvariant()
            }
        }
        $result.PolicyCount = @($policies).Count
        $result.PolicyIds = $ids
        $result.ParseSucceeded = $true
    }
    catch {
        $result.ParseError = $_.Exception.Message
    }
    return $result
}

function ConvertTo-WindowsDriverPolicyMode {
    # Pure mapping (ruling Q3). The mode is never derived from the OS build
    # number alone - capability tables are expectations, not facts
    # (SPEC D.47.2): only what `CiTool` actually listed decides.
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter()] [bool]$ParseSucceeded = $false,
        [Parameter()] [bool]$AuditPresent = $false,
        [Parameter()] [bool]$EnforcePresent = $false
    )
    if (-not $ParseSucceeded) { return 'unknown' }
    if ($EnforcePresent) { return 'enforce' }
    if ($AuditPresent) { return 'audit' }
    return 'absent'
}

function Get-WindowsDriverPolicyEvidence {
    # Windows Driver Policy (Layer E, SPEC D.58.6; audit H-06 / gate G-02).
    # Detection is CiTool-only: the EFI system partition is never mounted by
    # this read-only collector (ruling Q2) - assigning a drive letter to the
    # ESP is a host mutation, and `CiTool --list-policies` lists the same
    # policy IDs without one. `--json` is mandatory: without it CiTool blocks
    # on a "Press Enter to Exit" stdin prompt (SPEC D.16 defect class).
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory = $true)] [ValidateNotNullOrEmpty()] [string]$EvidenceDirectory,
        [Parameter()] [AllowNull()] $CodeIntegrityEvidence
    )
    $auditGuid   = '784C4414-79F4-4C32-A6A5-F0FB42A51D0D'
    $enforceGuid = '8F9CB695-5D48-48D6-A329-7202B44607E3'
    $queryError = $null

    $build = $null; $ubr = $null; $displayVersion = $null
    try {
        $cv = Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion' -ErrorAction SilentlyContinue
        if ($null -ne $cv) {
            if ($cv.PSObject.Properties['CurrentBuildNumber']) { $build = [string]$cv.CurrentBuildNumber }
            if ($cv.PSObject.Properties['UBR'])                { $ubr = [int]$cv.UBR }
            if ($cv.PSObject.Properties['DisplayVersion'])     { $displayVersion = [string]$cv.DisplayVersion }
        }
    }
    catch { $queryError = $_.Exception.Message }
    $applicable = if ($null -ne $build) { ([int]$build) -ge 26100 } else { $null }

    $ciToolPath = Join-Path $env:SystemRoot 'System32\CiTool.exe'
    $ciToolPresent = [bool](Test-Path -LiteralPath $ciToolPath -PathType Leaf)
    $parse = $null
    $method = 'none-available'
    $rawSavedTo = $null
    if ($ciToolPresent) {
        $method = 'citool-lp-json'
        $capture = Invoke-CapturedCommand -FilePath $ciToolPath -ArgumentList @('--list-policies', '--json')
        $rawSavedTo = 'windows-driver-policy_citool.txt'
        Set-Content -LiteralPath (Join-Path $EvidenceDirectory $rawSavedTo) `
            -Value ($capture.StdOut + $capture.StdErr) -Encoding UTF8
        $parse = ConvertFrom-CiToolPolicyList -Content ([string]$capture.StdOut)
    }
    $parseSucceeded = ($null -ne $parse -and $parse.ParseSucceeded)
    $auditPresent   = if ($parseSucceeded) { @($parse.PolicyIds) -contains $auditGuid }   else { $null }
    $enforcePresent = if ($parseSucceeded) { @($parse.PolicyIds) -contains $enforceGuid } else { $null }
    $mode = ConvertTo-WindowsDriverPolicyMode -ParseSucceeded ([bool]$parseSucceeded) `
        -AuditPresent ([bool]$auditPresent) -EnforcePresent ([bool]$enforcePresent)

    $event3076 = $null; $event3077 = $null
    $observedPaths = @()
    if ($null -ne $CodeIntegrityEvidence) {
        if ($CodeIntegrityEvidence.PSObject.Properties['AuditEventCount'])            { $event3076 = $CodeIntegrityEvidence.AuditEventCount }
        if ($CodeIntegrityEvidence.PSObject.Properties['EnforcementBlockEventCount']) { $event3077 = $CodeIntegrityEvidence.EnforcementBlockEventCount }
        if ($CodeIntegrityEvidence.PSObject.Properties['ObservedDriverPaths'])        { $observedPaths = @($CodeIntegrityEvidence.ObservedDriverPaths) }
    }

    return [pscustomobject][ordered]@{
        CollectedAtUtc       = Get-UtcTimestamp
        Applicable           = $applicable
        OsBuildAndUpdate     = [pscustomobject][ordered]@{ Build = $build; Ubr = $ubr; DisplayVersion = $displayVersion }
        AuditPolicyId        = $auditGuid
        EnforcePolicyId      = $enforceGuid
        Detection            = [pscustomobject][ordered]@{
            Method         = $method
            CiToolPresent  = $ciToolPresent
            ParseSucceeded = $parseSucceeded
            PolicyCount    = if ($null -ne $parse) { $parse.PolicyCount } else { $null }
            RawSavedTo     = $rawSavedTo
            ParseError     = if ($null -ne $parse) { $parse.ParseError } else { $null }
        }
        AuditPolicyPresent   = $auditPresent
        EnforcePolicyPresent = $enforcePresent
        Mode                 = $mode
        EspProbe             = [pscustomobject][ordered]@{ Attempted = $false; Reason = 'read-only-contract' }
        Event3076Count       = $event3076
        Event3077Count       = $event3077
        ObservedDriverPaths  = $observedPaths
        QueryError           = $queryError
    }
}

function Get-KernelImageTrustClassification {
    # Pure classifier (ruling Q3) mapping signature observations onto the
    # SPEC D.58.3 trust vocabulary. LegacyCrossSignedAllowListed is NEVER
    # emitted (ruling Q4): allow-list membership cannot be proven yet, so a
    # cross-signed chain always classifies as ...NotProven. Branch order
    # matters: the WHQL-publisher subject also matches the inbox-Microsoft
    # pattern, so the WHQL branch must come first.
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter()] [AllowEmptyString()] [string]$AuthenticodeStatus = '',
        [Parameter()] [AllowEmptyString()] [string]$PrimarySignerSubject = '',
        [Parameter()] [AllowNull()] [string[]]$ChainSubjects = @(),
        [Parameter()] [bool]$NestedWhqlPresent = $false,
        [Parameter()] [bool]$MatchesProjectCertificate = $false
    )
    $classification = 'Unknown'
    $source = 'unknown'
    $crossSigned = (@(@($ChainSubjects) | Where-Object { $_ -match 'Microsoft Code Verification Root' }).Count -gt 0)
    if ($AuthenticodeStatus -eq 'NotSigned') {
        $classification = 'Unsigned'; $source = 'none'
    }
    elseif ([string]::IsNullOrWhiteSpace($AuthenticodeStatus)) {
        $classification = 'Unknown'; $source = 'unknown'
    }
    elseif ($MatchesProjectCertificate) {
        $classification = 'PrivateOrTestSigned'; $source = 'catalog'
    }
    elseif ($NestedWhqlPresent -or $PrimarySignerSubject -match 'Microsoft Windows Hardware Compatibility') {
        $classification = 'WhcpHdc'; $source = 'embedded-whql'
    }
    elseif ($PrimarySignerSubject -match 'CN=Microsoft Windows') {
        # Microsoft production-signed inbox binaries: same stable production
        # trust bucket as WHCP/HDC, distinguished by TrustSource.
        $classification = 'WhcpHdc'; $source = 'embedded-other'
    }
    elseif ($crossSigned) {
        $classification = 'LegacyCrossSignedNotProven'; $source = 'embedded-other'
    }
    elseif ($AuthenticodeStatus -eq 'Valid') {
        # A vendor Authenticode signature with no Microsoft chain element
        # carries no kernel production trust of its own.
        $classification = 'PrivateOrTestSigned'; $source = 'embedded-other'
    }
    return [pscustomobject][ordered]@{
        TrustClassification = $classification
        TrustSource         = $source
    }
}

function Get-KernelImageTrustEvidence {
    # Kernel image trust census (SPEC D.58.3 vocabulary; audit P1-B / gate
    # G-03). One record per kernel-driver service binary, classification plus
    # trust source - deliberately NO can-load boolean anywhere in this schema
    # (G-03). Nested/WHQL co-signature inspection needs signtool and is a
    # later-wave extension; this census records the primary signer and, for
    # non-Microsoft signers, the built chain subjects.
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter()] [AllowNull()] [string[]]$ProjectThumbprints = @()
    )
    $records = New-Object 'System.Collections.Generic.List[object]'
    $queryError = $null
    $drivers = @()
    try {
        $drivers = @(Get-CimInstance -ClassName Win32_SystemDriver -ErrorAction Stop)
    }
    catch {
        try { $drivers = @(Get-WmiObject -Class Win32_SystemDriver -ErrorAction Stop) }
        catch { $queryError = $_.Exception.Message }
    }
    $thumbs = @(@($ProjectThumbprints) | Where-Object { $_ } | ForEach-Object { ([string]$_).ToUpperInvariant() })
    foreach ($drv in $drivers) {
        $svcName = if ($drv.PSObject.Properties['Name']) { [string]$drv.Name } else { $null }
        $rawPath = if ($drv.PSObject.Properties['PathName']) { [string]$drv.PathName } else { '' }
        $resolved = Resolve-ServiceImagePath -ImagePath $rawPath
        $path = if ($resolved -and (Test-Path -LiteralPath $resolved -PathType Leaf)) { $resolved } else { $null }
        $sha256 = $null
        $status = ''
        $primarySubject = ''
        $thumbMatch = $false
        $chainSubjects = @()
        if ($null -ne $path) {
            try { $sha256 = (Get-FileHash -LiteralPath $path -Algorithm SHA256 -ErrorAction Stop).Hash } catch { $sha256 = $null }
            try {
                $sig = Get-AuthenticodeSignature -LiteralPath $path -ErrorAction Stop
                $status = [string]$sig.Status
                if ($null -ne $sig.SignerCertificate) {
                    $primarySubject = [string]$sig.SignerCertificate.Subject
                    $thumbMatch = ($thumbs -contains ([string]$sig.SignerCertificate.Thumbprint).ToUpperInvariant())
                    if ($primarySubject -notmatch 'Microsoft') {
                        try {
                            $chain = New-Object System.Security.Cryptography.X509Certificates.X509Chain
                            $chain.ChainPolicy.RevocationMode = [System.Security.Cryptography.X509Certificates.X509RevocationMode]::NoCheck
                            $null = $chain.Build($sig.SignerCertificate)
                            $chainSubjects = @($chain.ChainElements | ForEach-Object { [string]$_.Certificate.Subject })
                            $chain.Dispose()
                        }
                        catch {
                            Set-DebugStep ('kernel-image-trust: chain build failed for {0}: {1}' -f $path, $_.Exception.Message)
                        }
                    }
                }
            }
            catch { $status = '' }
        }
        $verdict = Get-KernelImageTrustClassification -AuthenticodeStatus $status `
            -PrimarySignerSubject $primarySubject -ChainSubjects $chainSubjects `
            -NestedWhqlPresent $false -MatchesProjectCertificate $thumbMatch
        $records.Add([pscustomobject][ordered]@{
            Path                   = $path
            Sha256                 = $sha256
            AuthenticodeStatus     = $status
            PrimarySignerSubject   = $primarySubject
            EmbeddedSignerSubjects = @(@($primarySubject) | Where-Object { $_ })
            CatalogSignerSubject   = $null
            TrustClassification    = $verdict.TrustClassification
            TrustSource            = $verdict.TrustSource
            ServiceName            = $svcName
            ServiceState           = if ($drv.PSObject.Properties['State'])     { [string]$drv.State }     else { $null }
            StartType              = if ($drv.PSObject.Properties['StartMode']) { [string]$drv.StartMode } else { $null }
            LoadedImagePath        = $rawPath
            InDriverStore          = ($null -ne $path -and $path -match '(?i)DriverStore\\FileRepository')
        }) | Out-Null
    }
    return [pscustomobject][ordered]@{
        CollectedAtUtc = Get-UtcTimestamp
        DriverCount    = @($drivers).Count
        InspectedCount = $records.Count
        Records        = $records.ToArray()
        QueryError     = $queryError
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
    $ciEventErr = $null
        $events = @(Get-WinEvent -FilterHashtable @{
            LogName = 'Microsoft-Windows-CodeIntegrity/Operational'
            Id = @(3076, 3077, 3089, 3091)
        } -MaxEvents $MaxEvents -ErrorAction SilentlyContinue -ErrorVariable ciEventErr)
        foreach ($event in $events) {
            # EventData via ToXml(): Message is locale-dependent (a ja-JP
            # host renders Japanese), so machine-read fields must come from
            # the XML payload (SPEC D.19 lesson). Field names are recorded
            # verbatim rather than assumed.
            $eventDataFields = [ordered]@{}
            try {
                [xml]$eventXml = $event.ToXml()
                foreach ($dataNode in @($eventXml.Event.EventData.Data)) {
                    if ($null -eq $dataNode) { continue }
                    $fieldName = [string]$dataNode.Name
                    if ([string]::IsNullOrWhiteSpace($fieldName)) { continue }
                    $fieldValue = ''
                    if ($dataNode.PSObject.Properties['#text']) { $fieldValue = [string]$dataNode.'#text' }
                    $eventDataFields[$fieldName] = $fieldValue
                }
            }
            catch {
                $eventDataFields['XmlParseError'] = $_.Exception.Message
            }
            $records.Add([pscustomobject][ordered]@{
                TimeCreatedUtc = $event.TimeCreated.ToUniversalTime().ToString('o')
                Id = [int]$event.Id
                Level = [string]$event.LevelDisplayName
                Message = [string]$event.Message
                EventDataFields = [pscustomobject]$eventDataFields
            }) | Out-Null
        }
    }
    catch {
        $queryError = $_.Exception.Message
    }
    if ($null -ne $ciEventErr -and @($ciEventErr).Count -gt 0) {
        # An absent CodeIntegrity/Operational log and an empty one are both
        # normal; only anything else is worth recording.
        $ciFirst = [string]@($ciEventErr)[0]
        if ($ciFirst -notmatch 'No events were found' -and $ciFirst -notmatch 'There is not an event log') {
            $queryError = $ciFirst
        }
    }

    $blockEventCount = @($records | Where-Object { $_.Id -eq 3077 }).Count
    $auditEventCount = @($records | Where-Object { $_.Id -eq 3076 }).Count

    # Driver paths observed by Windows Driver Policy / WDAC events, from the
    # locale-independent EventData fields (never from Message). Field-name
    # match is deliberately loose ('file name' with or without separators)
    # because the exact name is recorded evidence, not an assumption.
    $observedPathList = New-Object 'System.Collections.Generic.List[object]'
    foreach ($record in $records) {
        if ($record.Id -ne 3076 -and $record.Id -ne 3077) { continue }
        foreach ($prop in $record.EventDataFields.PSObject.Properties) {
            if ($prop.Name -notmatch '(?i)file\s*name') { continue }
            $pathValue = [string]$prop.Value
            if (-not [string]::IsNullOrWhiteSpace($pathValue)) { $observedPathList.Add($pathValue) | Out-Null }
        }
    }
    $observedDriverPaths = @($observedPathList.ToArray() | Sort-Object -Unique)

    $records.ToArray() | ForEach-Object { $_ | ConvertTo-Json -Compress -Depth 5 } |
        Set-Content -LiteralPath (Join-Path $EvidenceDirectory 'codeintegrity-events.jsonl') -Encoding UTF8

    return [pscustomobject][ordered]@{
        CollectedAtUtc = Get-UtcTimestamp
        QueriedEventIds = @(3076, 3077, 3089, 3091)
        MaxEvents = $MaxEvents
        EventCount = $records.Count
        EnforcementBlockEventCount = $blockEventCount
        AuditEventCount = $auditEventCount
        ObservedDriverPaths = $observedDriverPaths
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
        [Parameter(Mandatory = $true)] [object]$ServiceEvidence,
        [Parameter(Mandatory = $true)] [object]$FeatureServices,
        [Parameter(Mandatory = $true)] [object]$ScriptInventory,
        [Parameter(Mandatory = $true)] [object]$BthPanRuntime,
        [Parameter(Mandatory = $true)] [object]$StageEvidence,
        [Parameter(Mandatory = $true)] [object]$OsCapability,
        [Parameter(Mandatory = $true)] [object]$ArchiveCapability,
        [Parameter(Mandatory = $true)] [object]$DriverFramework,
        [Parameter(Mandatory = $true)] [object]$CrashEvidence,
        [Parameter(Mandatory = $true)] [object]$WdfAssessment
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


    # 0) Collection completeness. Placed first because every row below is
    # only as trustworthy as the stage that produced it: a bundle with a
    # failed stage can still show PASS everywhere else and mean much less
    # than it appears to.
    $stageFailed = [int]$StageEvidence.FailedStageCount
    $stageDetail = if ($stageFailed -eq 0) {
        ('all {0} collection stage(s) completed' -f $StageEvidence.StageCount)
    }
    else {
        $names = @($StageEvidence.Stages | Where-Object { -not $_.Succeeded } | ForEach-Object { $_.Label.Trim() })
        ('{0} of {1} stage(s) FAILED - this bundle is incomplete: {2}' -f $stageFailed, $StageEvidence.StageCount, ($names -join '; '))
    }
    $items.Add((New-AssessmentItem -Name 'Collection completeness' `
        -Status $(if ($stageFailed -eq 0) { 'PASS' } else { 'FAIL' }) -Detail $stageDetail)) | Out-Null

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
    # 3d) OS capability matrix. Reported as INFO rather than PASS/FAIL because
    # a capability absent on an older Server SKU is expected, not a fault. The
    # value is that the bundle STATES it, so a cross-version diagnosis rests
    # on the host's own measurements instead of on an assumption about what
    # that SKU has.
    $capDetail = ('{0} (build {1}); missing cmdlets={2} CIM classes={3} tools={4}' -f `
        $OsCapability.ProfileCode, $OsCapability.OsBuild, `
        $OsCapability.MissingCmdletCount, $OsCapability.MissingCimClassCount, $OsCapability.MissingToolCount)
    if ($OsCapability.MissingToolCount -gt 0) {
        $capDetail += ('; tools absent: {0}' -f (@($OsCapability.MissingTools) -join ', '))
    }
    $items.Add((New-AssessmentItem -Name 'OS capability matrix' `
        -Status $(if ($OsCapability.MissingToolCount -gt 0) { 'REVIEW' } else { 'INFO' }) -Detail $capDetail)) | Out-Null

    # 3e) Archive capability. The collector's own ZIP depends on this working.
    # Probing it explicitly turns 'the archive did not appear' from a guess
    # into a recorded fact with a reason attached.
    $archiveDetail = if (-not $ArchiveCapability.CompressArchiveAvailable) { 'Compress-Archive is not available on this host' }
    elseif ($ArchiveCapability.ProbeSucceeded) { ('probe archived {0} entry/entries, {1} byte(s)' -f $ArchiveCapability.ProbeEntryCount, $ArchiveCapability.ProbeArchiveBytes) }
    else { ('probe FAILED: {0}' -f $ArchiveCapability.ErrorMessage) }
    $items.Add((New-AssessmentItem -Name 'Archive capability' `
        -Status $(if ($ArchiveCapability.ProbeSucceeded) { 'PASS' } else { 'FAIL' }) -Detail $archiveDetail)) | Out-Null
    # 3f) Driver framework ceiling. Reported as INFO because a version is not
    # a fault - but it IS the ceiling every driver package on this host has
    # to fit under, and a package requesting a newer KMDF than this cannot
    # load no matter how it is signed.
    $kmdfDetail = if ([string]::IsNullOrWhiteSpace($DriverFramework.KmdfLibraryVersion)) {
        'KMDF runtime version could not be read'
    }
    else {
        ('KMDF {0} (Wdf01000.sys {1}); UMDF version is not readable from any binary - see the raw UmdfReflector / UmdfHost entries in driver-framework.json' -f $DriverFramework.KmdfLibraryVersion, $DriverFramework.KmdfRuntime.FileVersionRaw)
    }
    $items.Add((New-AssessmentItem -Name 'Driver framework versions' `
        -Status $(if ([string]::IsNullOrWhiteSpace($DriverFramework.KmdfLibraryVersion)) { 'REVIEW' } else { 'INFO' }) `
        -Detail $kmdfDetail)) | Out-Null

    # 3g) Bugcheck history. A host that has bugchecked recently is a different
    # host from one that has not, and the difference belongs at the top of any
    # investigation rather than in a recollection.
    $bugCount = [int]$CrashEvidence.BugCheckEventCount
    $crashDetail = if ($bugCount -eq 0 -and [int]$CrashEvidence.MinidumpCount -eq 0) {
        ('no bugcheck events or minidumps; dump setting = {0}' -f $CrashEvidence.CrashControl.CrashDumpEnabledName)
    }
    else {
        $latest = if ($bugCount -gt 0) { @($CrashEvidence.BugCheckEvents)[0].BugCheckText } else { '(no event, dump only)' }
        ('{0} bugcheck event(s), {1} minidump(s); most recent: {2}' -f $bugCount, $CrashEvidence.MinidumpCount, $latest)
    }
    $items.Add((New-AssessmentItem -Name 'Bugcheck history' `
        -Status $(if ($bugCount -eq 0 -and [int]$CrashEvidence.MinidumpCount -eq 0) { 'PASS' } else { 'REVIEW' }) `
        -Detail $crashDetail)) | Out-Null
    # 3h) WDF version assessment. INFO by default: a framework version is a
    # property of the OS, not a fault. REVIEW when a co-installer on the host
    # was built for a newer framework than the host provides - a package that
    # cannot load, whose failure looks nothing like a signing problem.
    $wdfExceed = [int]$WdfAssessment.CoInstallersExceedingHostCount
    $wdfDetail = if ([string]::IsNullOrWhiteSpace($WdfAssessment.ActualKmdfVersion)) {
        'KMDF runtime version could not be read'
    }
    else {
        ('KMDF {0} (expected {1} for {2}); {3} WDF-based service(s), {4} boot/system-start' -f `
            $WdfAssessment.ActualKmdfVersion, $WdfAssessment.ExpectedKmdfVersion, $WdfAssessment.OsName, `
            $WdfAssessment.WdfBasedServiceCount, $WdfAssessment.WdfBootOrSystemStartCount)
    }
    if ($wdfExceed -gt 0) {
        $names = @($WdfAssessment.CoInstallersExceedingHost | Select-Object -First 3 | ForEach-Object { '{0} wants {1}' -f $_.Name, $_.RequestedKmdfVersion })
        $wdfDetail = $wdfDetail + ('; {0} co-installer(s) exceed the host: {1}' -f $wdfExceed, ($names -join ', '))
    }
    $items.Add((New-AssessmentItem -Name 'WDF version assessment' `
        -Status $(if ([string]::IsNullOrWhiteSpace($WdfAssessment.ActualKmdfVersion) -or $wdfExceed -gt 0) { 'REVIEW' } else { 'INFO' }) `
        -Detail $wdfDetail)) | Out-Null




    # 3b) Service binary integrity. Distinct from the device-level check
    # above: a service can be declared, referenced by an INF, and have no
    # binary on disk without any device yet being in an error state. That
    # latent condition is what turns an unrelated driver install into a
    # broken adapter, so it is reported on its own terms.
    $svcMissing = [int]$ServiceEvidence.MissingBinaryCount
    $svcMissingDetail = if ($svcMissing -eq 0) {
        ('all {0} service(s) resolve to an existing binary' -f $ServiceEvidence.ServiceCount)
    }
    else {
        $names = @($ServiceEvidence.MissingBinaryServices | Select-Object -First 5 | ForEach-Object { '{0} -> {1}' -f $_.Name, $_.ImagePathResolved })
        ('{0} of {1} service(s) reference an absent binary: {2}' -f $svcMissing, $ServiceEvidence.ServiceCount, ($names -join '; '))
    }
    $items.Add((New-AssessmentItem -Name 'Service binary integrity' `
        -Status $(if ($svcMissing -eq 0) { 'PASS' } else { 'REVIEW' }) -Detail $svcMissingDetail)) | Out-Null

    # 3c) Server feature-dependent services. A Server SKU stages many inbox
    # components only when the corresponding optional feature is installed.
    # A device INF written for a client SKU can declare one of those services
    # and fail to install on a default Server image with nothing wrong in the
    # driver package itself.
    $featRisk = [int]$FeatureServices.BinaryMissingWatchCount
    $featDetail = if (-not [string]::IsNullOrWhiteSpace($FeatureServices.FeatureQueryError)) {
        ('feature state unavailable: {0}' -f $FeatureServices.FeatureQueryError)
    }
    elseif ($featRisk -eq 0) { ('{0} feature(s) installed; no watched service is missing its binary' -f $FeatureServices.InstalledFeatureCount) }
    else {
        $wn = @($FeatureServices.WatchedServices | Where-Object { $_.Classification -eq 'ServiceKeyPresentBinaryMissing' } |
                Select-Object -First 5 | ForEach-Object { '{0} (feature {1}={2})' -f $_.ServiceName, $_.Feature, $_.FeatureInstallState })
        ('{0} watched service(s) declared but binary absent: {1}' -f $featRisk, ($wn -join '; '))
    }
    $items.Add((New-AssessmentItem -Name 'Server feature-dependent services' `
        -Status $(if (-not [string]::IsNullOrWhiteSpace($FeatureServices.FeatureQueryError)) { 'INFO' } elseif ($featRisk -eq 0) { 'PASS' } else { 'REVIEW' }) `
        -Detail $featDetail)) | Out-Null

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
# Read by the top-level finally, which archives whatever was collected even
# when a stage or the assessment threw (SPEC D.45).
$evidenceDir = ''
$zipPath = ''
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

    $osEvidence = Invoke-EvidenceStage -Label '[1/20] Operating system identity...' -Body {
        $v = Get-OperatingSystemEvidence
        Write-EvidenceJson -InputObject $v -Directory $evidenceDir -FileName 'environment.json'
        $v
    }

    $pendingReboot = Invoke-EvidenceStage -Label '[2/20] Pending reboot state...' -Body {
        $v = Get-PendingRebootEvidence
        Write-EvidenceJson -InputObject $v -Directory $evidenceDir -FileName 'pending-reboot.json'
        $v
    }

    $pnpEvidence = Invoke-EvidenceStage -Label '[3/20] PnP device inventory...' -Body {
        $v = Get-PnpDeviceEvidence
        Write-EvidenceJson -InputObject $v -Directory $evidenceDir -FileName 'pnp-devices.json'
        $v
    } -Fallback ([pscustomobject][ordered]@{ CollectedAtUtc = Get-UtcTimestamp; DeviceCount = 0; ProblemDeviceCount = 0; TargetedDeviceCount = 0; ProblemDevices = @(); TargetedDevices = @(); Devices = @() })

    $driverStore = Invoke-EvidenceStage -Label '[4/20] Driver store inventory...' -Body {
        $v = Get-DriverStoreEvidence -EvidenceDirectory $evidenceDir
        Write-EvidenceJson -InputObject $v -Directory $evidenceDir -FileName 'driver-store.json'
        $v
    } -Fallback ([pscustomobject][ordered]@{ CollectedAtUtc = Get-UtcTimestamp; PnputilExitCode = $null; PackageCount = 0; SignedDriverCount = 0; Packages = @() })

    $certificateEvidence = Invoke-EvidenceStage -Label '[5/20] Project certificate stores...' -Body {
        $v = Get-ProjectCertificateEvidence
        Write-EvidenceJson -InputObject $v -Directory $evidenceDir -FileName 'project-certificates.json'
        $v
    } -Fallback ([pscustomobject][ordered]@{ CollectedAtUtc = Get-UtcTimestamp; CertificateCount = 0; StoresConsistent = $null; StoreErrors = @('stage failed'); RootThumbprints = @(); TrustedPublisherThumbprints = @(); ThumbprintsOnlyInRoot = @(); ThumbprintsOnlyInTrustedPublisher = @(); Certificates = @() })

    $bootSecurity = Invoke-EvidenceStage -Label '[6/20] Boot security state...' -Body {
        $v = Get-BootSecurityEvidence -EvidenceDirectory $evidenceDir
        Write-EvidenceJson -InputObject $v -Directory $evidenceDir -FileName 'boot-security.json'
        $v
    } -Fallback ([pscustomobject][ordered]@{ CollectedAtUtc = Get-UtcTimestamp; SecureBootEnabled = $null; TestSigningEnabled = $null; NoIntegrityChecksEnabled = $null; BcdCaptured = $false; WdacPolicyPresent = $null })

    $codeIntegrityEvents = Invoke-EvidenceStage -Label '[7/20] CodeIntegrity events...' -Body {
        $v = Get-CodeIntegrityEventEvidence -EvidenceDirectory $evidenceDir
        Write-EvidenceJson -InputObject $v -Directory $evidenceDir -FileName 'codeintegrity-events.json'
        $v
    } -Fallback ([pscustomobject][ordered]@{ CollectedAtUtc = Get-UtcTimestamp; EventCount = 0; EnforcementBlockEventCount = 0; AuditEventCount = 0; QueryError = 'stage failed' })

    $windowsDriverPolicyEvidence = Invoke-EvidenceStage -Label '[8/20] Windows Driver Policy (Layer E)...' -Body {
        $v = Get-WindowsDriverPolicyEvidence -EvidenceDirectory $evidenceDir -CodeIntegrityEvidence $codeIntegrityEvents
        Write-EvidenceJson -InputObject $v -Directory $evidenceDir -FileName 'windows-driver-policy.json'
        $v
    } -Fallback ([pscustomobject][ordered]@{ CollectedAtUtc = Get-UtcTimestamp; Applicable = $null; Mode = 'unknown'; QueryError = 'stage failed' })
    Set-DebugStep ('windows-driver-policy: mode={0}' -f $windowsDriverPolicyEvidence.Mode)

    $kernelImageTrustEvidence = Invoke-EvidenceStage -Label '[9/20] Kernel image trust census...' -Body {
        $projectThumbprints = @()
        if ($null -ne $certificateEvidence) {
            if ($certificateEvidence.PSObject.Properties['RootThumbprints'])             { $projectThumbprints += @($certificateEvidence.RootThumbprints) }
            if ($certificateEvidence.PSObject.Properties['TrustedPublisherThumbprints']) { $projectThumbprints += @($certificateEvidence.TrustedPublisherThumbprints) }
        }
        $v = Get-KernelImageTrustEvidence -ProjectThumbprints @($projectThumbprints | Where-Object { $_ } | Sort-Object -Unique)
        Write-EvidenceJson -InputObject $v -Directory $evidenceDir -FileName 'kernel-image-trust.json'
        $v
    } -Fallback ([pscustomobject][ordered]@{ CollectedAtUtc = Get-UtcTimestamp; DriverCount = 0; InspectedCount = 0; Records = @(); QueryError = 'stage failed' })
    Set-DebugStep ('kernel-image-trust: inspected={0}' -f $kernelImageTrustEvidence.InspectedCount)

    $setupLogEvidence = Invoke-EvidenceStage -Label '[10/20] Driver setup logs...' -Body {
        $v = if (-not $SkipSetupApiLog) {
            Get-DriverSetupLogEvidence -EvidenceDirectory $evidenceDir
        }
        else {
            [pscustomobject][ordered]@{ CollectedAtUtc = Get-UtcTimestamp; Logs = @() }
        }
        Write-EvidenceJson -InputObject $v -Directory $evidenceDir -FileName 'driver-setup-logs.json'
        $v
    } -Fallback ([pscustomobject][ordered]@{ CollectedAtUtc = Get-UtcTimestamp; Logs = @() })

    $loadDiagnostics = Invoke-EvidenceStage -Label '[11/20] Device load diagnostics...' -Body {
        # Reads the copy inside the bundle when one was made, so the parse and
        # the archived text are the same bytes; falls back to the live log when
        # the copy was skipped (size cap) or -SkipSetupApiLog was passed.
        $setupApiForParse = Join-Path (Join-Path $evidenceDir 'setupapi') 'setupapi.dev.log'
        if (-not (Test-Path -LiteralPath $setupApiForParse)) {
            $setupApiForParse = Join-Path $env:SystemRoot 'INF\setupapi.dev.log'
        }
        $v = Get-DeviceLoadDiagnosticEvidence -PnpEvidence $pnpEvidence -SetupApiLogPath $setupApiForParse
        Write-EvidenceJson -InputObject $v -Directory $evidenceDir -FileName 'device-load-diagnostics.json'
        $v
    } -Fallback ([pscustomobject][ordered]@{ CollectedAtUtc = Get-UtcTimestamp; ProblemDeviceCount = 0; MissingServiceBinaryCount = 0; SignatureRelatedFailureCount = 0; ProblemDevices = @(); SetupApi = [pscustomobject][ordered]@{ LogPresent = $false; SectionsScanned = 0; FailureSections = @(); MissingServiceBinaries = @(); ParseError = 'stage failed' } })

    $serviceEvidence = Invoke-EvidenceStage -Label '[12/20] Windows service configuration...' -Body {
        $v = Get-ServiceConfigurationEvidence
        Write-EvidenceJson -InputObject $v -Directory $evidenceDir -FileName 'services.json'
        $v
    } -Fallback ([pscustomobject][ordered]@{ CollectedAtUtc = Get-UtcTimestamp; ServiceCount = 0; DriverServiceCount = 0; RunningCount = 0; DisabledCount = 0; MissingBinaryCount = 0; CollectionErrors = @('stage failed'); MissingBinaryServices = @(); DependencyIndex = @(); Services = @() })

    $featureServices = Invoke-EvidenceStage -Label '[13/20] Server feature-to-service mapping...' -Body {
        $v = Get-ServerFeatureServiceEvidence -ServiceEvidence $serviceEvidence
        Write-EvidenceJson -InputObject $v -Directory $evidenceDir -FileName 'server-feature-services.json'
        $v
    } -Fallback ([pscustomobject][ordered]@{ CollectedAtUtc = Get-UtcTimestamp; FeatureQueryError = 'stage failed'; FeatureCount = 0; InstalledFeatureCount = 0; BinaryMissingWatchCount = 0; WatchedServices = @(); Features = @() })

    $scriptInventory = Invoke-EvidenceStage -Label '[14/20] Repository script and workspace inventory...' -Body {
        $v = Get-DeployScriptInventory -ScriptDirectory $scriptDirectory
        Write-EvidenceJson -InputObject $v -Directory $evidenceDir -FileName 'deploy-scripts.json'
        $workspaceInventory = Get-WorkspaceInventoryEvidence -ScriptDirectory $scriptDirectory
        Write-EvidenceJson -InputObject $workspaceInventory -Directory $evidenceDir -FileName 'workspace-inventory.json'
        $v
    } -Fallback ([pscustomobject][ordered]@{ CollectedAtUtc = Get-UtcTimestamp; PresentCount = 0; ExpectedCount = 0; Scripts = @() })

    $bthPanRuntime = Invoke-EvidenceStage -Label '[15/20] BthPan runtime state...' -Body {
        $v = Get-BthPanRuntimeEvidence
        Write-EvidenceJson -InputObject $v -Directory $evidenceDir -FileName 'bthpan-runtime.json'
        $v
    } -Fallback ([pscustomobject][ordered]@{ CollectedAtUtc = Get-UtcTimestamp; BthPanSysPresent = $false; ServiceKeyPresent = $false; PanAdapterCount = 0 })


    $osCapability = Invoke-EvidenceStage -Label '[16/20] OS capability matrix...' -Body {
        $v = Get-OsCapabilityEvidence
        Write-EvidenceJson -InputObject $v -Directory $evidenceDir -FileName 'os-capability.json'
        $v
    } -Fallback ([pscustomobject][ordered]@{ CollectedAtUtc = Get-UtcTimestamp; OsBuild = 0; ProfileCode = ''; MissingCmdletCount = 0; MissingCmdlets = @(); MissingCimClassCount = 0; MissingCimClasses = @(); MissingToolCount = 0; MissingTools = @(); Cmdlets = @(); CimClasses = @(); Tools = @() })

    $archiveCapability = Invoke-EvidenceStage -Label '[17/20] Archive capability probe...' -Body {
        $v = Get-ArchiveCapabilityEvidence
        Write-EvidenceJson -InputObject $v -Directory $evidenceDir -FileName 'archive-capability.json'
        $v
    } -Fallback ([pscustomobject][ordered]@{ CollectedAtUtc = Get-UtcTimestamp; CompressArchiveAvailable = $false; ProbeAttempted = $false; ProbeSucceeded = $false; ErrorMessage = 'stage failed' })


    $driverFramework = Invoke-EvidenceStage -Label '[18/20] Driver framework versions...' -Body {
        $v = Get-DriverFrameworkEvidence
        Write-EvidenceJson -InputObject $v -Directory $evidenceDir -FileName 'driver-framework.json'
        $v
    } -Fallback ([pscustomobject][ordered]@{ CollectedAtUtc = Get-UtcTimestamp; KmdfLibraryVersion = ''; UmdfLibraryVersion = ''; CoInstallerCount = 0; CoInstallers = @() })

    $crashEvidence = Invoke-EvidenceStage -Label '[19/20] Crash dump and bugcheck history...' -Body {
        $v = Get-CrashEvidence
        Write-EvidenceJson -InputObject $v -Directory $evidenceDir -FileName 'crash-evidence.json'
        $v
    } -Fallback ([pscustomobject][ordered]@{ CollectedAtUtc = Get-UtcTimestamp; MinidumpCount = 0; Minidumps = @(); BugCheckEventCount = 0; BugCheckEvents = @(); UnexpectedShutdownCount = 0; MemoryDumpPresent = $false; QueryError = 'stage failed' })


    $wdfAssessment = Invoke-EvidenceStage -Label '[20/20] WDF version assessment...' -Body {
        $co = Get-WdfCoInstallerInventory
        $wdfSvc = Get-WdfDependentServiceInventory -ServiceEvidence $serviceEvidence
        $v = Get-WdfAssessment -DriverFramework $driverFramework -OsCapability $osCapability -CoInstallers $co -WdfServices $wdfSvc
        Write-EvidenceJson -InputObject $co -Directory $evidenceDir -FileName 'wdf-coinstallers.json'
        Write-EvidenceJson -InputObject $wdfSvc -Directory $evidenceDir -FileName 'wdf-services.json'
        Write-EvidenceJson -InputObject $v -Directory $evidenceDir -FileName 'wdf-assessment.json'
        $v
    } -Fallback ([pscustomobject][ordered]@{ CollectedAtUtc = Get-UtcTimestamp; OsName = ''; ExpectedKmdfVersion = ''; ActualKmdfVersion = ''; CoInstallerCount = 0; CoInstallersExceedingHostCount = 0; CoInstallersExceedingHost = @(); WdfBasedServiceCount = 0; WdfBootOrSystemStartCount = 0 })

    # Stage ledger is written before the assessment so the bundle states its
    # own completeness even if a later step fails (SPEC D.45).
    $stageEvidence = Get-StageFailureEvidence
    Write-EvidenceJson -InputObject $stageEvidence -Directory $evidenceDir -FileName 'stage-results.json'

    $assessmentItems = Get-ConfigurationAssessment `
        -OsEvidence $osEvidence -PendingReboot $pendingReboot -PnpEvidence $pnpEvidence `
        -DriverStore $driverStore -CertificateEvidence $certificateEvidence -BootSecurity $bootSecurity `
        -CodeIntegrityEvents $codeIntegrityEvents -SetupLogEvidence $setupLogEvidence `
        -LoadDiagnostics $loadDiagnostics -ServiceEvidence $serviceEvidence -FeatureServices $featureServices `
        -ScriptInventory $scriptInventory -BthPanRuntime $bthPanRuntime -StageEvidence $stageEvidence `
        -OsCapability $osCapability -ArchiveCapability $archiveCapability `
        -DriverFramework $driverFramework -CrashEvidence $crashEvidence -WdfAssessment $wdfAssessment

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
finally {
    # ALWAYS archive (SPEC D.45). The four deploy scripts archive their run
    # artifacts from a top-level finally regardless of outcome; the collector
    # previously archived from inside the try, so any failure cost the
    # operator the bundle as well as the run. Whatever was collected before
    # the failure is worth handing over - it is usually the part that
    # explains the failure.
    try {
        if (-not [string]::IsNullOrWhiteSpace($evidenceDir) -and (Test-Path -LiteralPath $evidenceDir)) {
            if (-not (Test-Path -LiteralPath (Join-Path $evidenceDir 'stage-results.json'))) {
                Write-EvidenceJson -InputObject (Get-StageFailureEvidence) -Directory $evidenceDir -FileName 'stage-results.json'
            }
            if (-not [string]::IsNullOrWhiteSpace($zipPath)) {
                if (Test-Path -LiteralPath $zipPath) { Remove-Item -LiteralPath $zipPath -Force -ErrorAction SilentlyContinue }
                Compress-Archive -Path (Join-Path $evidenceDir '*') -DestinationPath $zipPath -CompressionLevel Optimal -Force -ErrorAction Stop
                Write-Host ''
                Write-Host ('EVIDENCE ZIP  : {0}' -f $zipPath) -ForegroundColor Cyan
            }
        }
    }
    catch {
        # The archive itself failing must not mask the original outcome, and
        # must not throw out of a finally block.
        Write-Host ('WARNING: evidence archive could not be created: {0}' -f $_.Exception.Message) -ForegroundColor Yellow
        Write-Host ('         The evidence directory is still on disk: {0}' -f $evidenceDir) -ForegroundColor Yellow
    }
}

exit $exitCode

#endregion
