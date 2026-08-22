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
- `c0001/npu_mcdm_stack_prod/Runner/xrt_smi_phx.a`
- `c0001/npu_mcdm_stack_prod/Runner/xrt_smi_strx.a`
- `c0001/npu_mcdm_stack_prod/pyxrt.pyd`
- `c0001/npu_mcdm_stack_prod/xclbinutil.exe`

## Left-only files
- `c0001/npu_mcdm_stack_prod/DPU_Sequence/aie_reconfig_overhead.txt`
- `c0001/npu_mcdm_stack_prod/DPU_Sequence/df_bw.txt`
- `c0001/npu_mcdm_stack_prod/DPU_Sequence/gemm_int8.txt`
- `c0001/npu_mcdm_stack_prod/DPU_Sequence/tct_1col.txt`
- `c0001/npu_mcdm_stack_prod/DPU_Sequence/tct_4col.txt`
- `c0001/npu_mcdm_stack_prod/ELF/aie_reconfig_overhead_17f0_10.elf`
- `c0001/npu_mcdm_stack_prod/ELF/aie_reconfig_overhead_17f0_11.elf`
- `c0001/npu_mcdm_stack_prod/ELF/aie_reconfig_overhead_17f0_20.elf`
- `c0001/npu_mcdm_stack_prod/ELF/df_bw_17f0_10.elf`
- `c0001/npu_mcdm_stack_prod/ELF/df_bw_17f0_11.elf`
- `c0001/npu_mcdm_stack_prod/ELF/df_bw_17f0_20.elf`
- `c0001/npu_mcdm_stack_prod/ELF/gemm_int8_17f0_10.elf`
- `c0001/npu_mcdm_stack_prod/ELF/gemm_int8_17f0_11.elf`
- `c0001/npu_mcdm_stack_prod/ELF/gemm_int8_17f0_20.elf`
- `c0001/npu_mcdm_stack_prod/ELF/mobilenet_4col_17f0_10.elf`
- `c0001/npu_mcdm_stack_prod/ELF/mobilenet_4col_17f0_11.elf`
- `c0001/npu_mcdm_stack_prod/ELF/mobilenet_4col_17f0_20.elf`
- `c0001/npu_mcdm_stack_prod/ELF/nop_17f0_10.elf`
- `c0001/npu_mcdm_stack_prod/ELF/nop_17f0_11.elf`
- `c0001/npu_mcdm_stack_prod/ELF/nop_17f0_20.elf`
- `c0001/npu_mcdm_stack_prod/ELF/tct_1col_17f0_10.elf`
- `c0001/npu_mcdm_stack_prod/ELF/tct_1col_17f0_11.elf`
- `c0001/npu_mcdm_stack_prod/ELF/tct_1col_17f0_20.elf`
- `c0001/npu_mcdm_stack_prod/ELF/tct_4col_17f0_10.elf`
- `c0001/npu_mcdm_stack_prod/ELF/tct_4col_17f0_11.elf`
- `c0001/npu_mcdm_stack_prod/ELF/tct_4col_17f0_20.elf`
- `c0001/npu_mcdm_stack_prod/Mobilenet/buffer_sizes.json`
- `c0001/npu_mcdm_stack_prod/Mobilenet/mobilenet_ifm.bin`
- `c0001/npu_mcdm_stack_prod/Mobilenet/mobilenet_param.bin`
- `c0001/npu_mcdm_stack_prod/benchmark_17f0_10.json`
- `c0001/npu_mcdm_stack_prod/benchmark_17f0_11.json`
- `c0001/npu_mcdm_stack_prod/benchmark_17f0_20.json`
- `c0001/npu_mcdm_stack_prod/gemm_17f0_10.xclbin`
- `c0001/npu_mcdm_stack_prod/gemm_17f0_11.xclbin`
- `c0001/npu_mcdm_stack_prod/gemm_17f0_20.xclbin`
- `c0001/npu_mcdm_stack_prod/gemm_elf_17f0_10.xclbin`
- `c0001/npu_mcdm_stack_prod/gemm_elf_17f0_11.xclbin`
- `c0001/npu_mcdm_stack_prod/gemm_elf_17f0_20.xclbin`
- `c0001/npu_mcdm_stack_prod/mobilenet_elf_17f0_10.xclbin`
- `c0001/npu_mcdm_stack_prod/mobilenet_elf_17f0_11.xclbin`
- `c0001/npu_mcdm_stack_prod/mobilenet_elf_17f0_20.xclbin`
- `c0001/npu_mcdm_stack_prod/validate_1502_00.xclbin`
- `c0001/npu_mcdm_stack_prod/validate_17f0_00.xclbin`
- `c0001/npu_mcdm_stack_prod/validate_17f0_10.xclbin`
- `c0001/npu_mcdm_stack_prod/validate_17f0_11.xclbin`
- `c0001/npu_mcdm_stack_prod/validate_17f0_20.xclbin`
- `c0001/npu_mcdm_stack_prod/validate_elf_17f0_10.xclbin`
- `c0001/npu_mcdm_stack_prod/validate_elf_17f0_11.xclbin`
- `c0001/npu_mcdm_stack_prod/validate_elf_17f0_20.xclbin`
