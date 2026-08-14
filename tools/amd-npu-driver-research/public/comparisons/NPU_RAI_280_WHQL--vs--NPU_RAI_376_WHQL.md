# AMD NPU Driver Release Comparison

- Left: `NPU_RAI_280_WHQL.zip` / `803afe1e2d75b717f60a368453306ccbd4877cdd936b6531b946b95109a22144`
- Right: `NPU_RAI_376_WHQL.zip` / `aa836cbfcad5d0782c79b58f197aa50624af37e7cb8311c5f94d85b0dc3ccaad`
- Installer binary relationship: **ByteIdentical**
- Installer recovered-routing relationship: **ExactHashIdentical**
- Driver binary relationship: **DifferentOrMissing**
- Driver identity-logic relationship: **FirmwareRevisionRefinementDiffers**

| Relationship | Count |
|---|---:|
| Common identical | 50 |
| Common changed | 48 |
| Left only | 49 |
| Right only | 4 |

## Right-only files
- `npu_mcdm_stack_prod/Runner/xrt_smi_phx.a`
- `npu_mcdm_stack_prod/Runner/xrt_smi_strx.a`
- `npu_mcdm_stack_prod/pyxrt.pyd`
- `npu_mcdm_stack_prod/xclbinutil.exe`

## Left-only files
- `npu_mcdm_stack_prod/DPU_Sequence/aie_reconfig_overhead.txt`
- `npu_mcdm_stack_prod/DPU_Sequence/df_bw.txt`
- `npu_mcdm_stack_prod/DPU_Sequence/gemm_int8.txt`
- `npu_mcdm_stack_prod/DPU_Sequence/tct_1col.txt`
- `npu_mcdm_stack_prod/DPU_Sequence/tct_4col.txt`
- `npu_mcdm_stack_prod/ELF/aie_reconfig_overhead_17f0_10.elf`
- `npu_mcdm_stack_prod/ELF/aie_reconfig_overhead_17f0_11.elf`
- `npu_mcdm_stack_prod/ELF/aie_reconfig_overhead_17f0_20.elf`
- `npu_mcdm_stack_prod/ELF/df_bw_17f0_10.elf`
- `npu_mcdm_stack_prod/ELF/df_bw_17f0_11.elf`
- `npu_mcdm_stack_prod/ELF/df_bw_17f0_20.elf`
- `npu_mcdm_stack_prod/ELF/gemm_int8_17f0_10.elf`
- `npu_mcdm_stack_prod/ELF/gemm_int8_17f0_11.elf`
- `npu_mcdm_stack_prod/ELF/gemm_int8_17f0_20.elf`
- `npu_mcdm_stack_prod/ELF/mobilenet_4col_17f0_10.elf`
- `npu_mcdm_stack_prod/ELF/mobilenet_4col_17f0_11.elf`
- `npu_mcdm_stack_prod/ELF/mobilenet_4col_17f0_20.elf`
- `npu_mcdm_stack_prod/ELF/nop_17f0_10.elf`
- `npu_mcdm_stack_prod/ELF/nop_17f0_11.elf`
- `npu_mcdm_stack_prod/ELF/nop_17f0_20.elf`
- `npu_mcdm_stack_prod/ELF/tct_1col_17f0_10.elf`
- `npu_mcdm_stack_prod/ELF/tct_1col_17f0_11.elf`
- `npu_mcdm_stack_prod/ELF/tct_1col_17f0_20.elf`
- `npu_mcdm_stack_prod/ELF/tct_4col_17f0_10.elf`
- `npu_mcdm_stack_prod/ELF/tct_4col_17f0_11.elf`
- `npu_mcdm_stack_prod/ELF/tct_4col_17f0_20.elf`
- `npu_mcdm_stack_prod/Mobilenet/buffer_sizes.json`
- `npu_mcdm_stack_prod/Mobilenet/mobilenet_ifm.bin`
- `npu_mcdm_stack_prod/Mobilenet/mobilenet_param.bin`
- `npu_mcdm_stack_prod/benchmark_17f0_10.json`
- `npu_mcdm_stack_prod/benchmark_17f0_11.json`
- `npu_mcdm_stack_prod/benchmark_17f0_20.json`
- `npu_mcdm_stack_prod/gemm_17f0_10.xclbin`
- `npu_mcdm_stack_prod/gemm_17f0_11.xclbin`
- `npu_mcdm_stack_prod/gemm_17f0_20.xclbin`
- `npu_mcdm_stack_prod/gemm_elf_17f0_10.xclbin`
- `npu_mcdm_stack_prod/gemm_elf_17f0_11.xclbin`
- `npu_mcdm_stack_prod/gemm_elf_17f0_20.xclbin`
- `npu_mcdm_stack_prod/mobilenet_elf_17f0_10.xclbin`
- `npu_mcdm_stack_prod/mobilenet_elf_17f0_11.xclbin`
- `npu_mcdm_stack_prod/mobilenet_elf_17f0_20.xclbin`
- `npu_mcdm_stack_prod/validate_1502_00.xclbin`
- `npu_mcdm_stack_prod/validate_17f0_00.xclbin`
- `npu_mcdm_stack_prod/validate_17f0_10.xclbin`
- `npu_mcdm_stack_prod/validate_17f0_11.xclbin`
- `npu_mcdm_stack_prod/validate_17f0_20.xclbin`
- `npu_mcdm_stack_prod/validate_elf_17f0_10.xclbin`
- `npu_mcdm_stack_prod/validate_elf_17f0_11.xclbin`
- `npu_mcdm_stack_prod/validate_elf_17f0_20.xclbin`
