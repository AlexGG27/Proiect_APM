# Var2

`Var2` is a documentation-faithful rebuild of the ADSP / VisualDSP side of the project.

What is inside:

- Exact VisualDSP code copies for `AGC`, `ALE`, and `MF`, taken from the existing documented example projects already present in the repository.
- One ADSP-21xx instruction-set code fragment transcribed from `adsp21xx._instruction_set.pdf`.
- Notes that map every PDF to the files created here.
- A verification script that checks the copied VisualDSP files are byte-for-byte identical to their documented source files.
- A system graph and an organigram that describe the full ARM + DSP flow.

Folder layout:

- `ADSP/`
- `VisualDSP/`
- `docs/`
- `test_inputs/`
- `VERIFY_DOC_IDENTITY.ps1`

Exact-copy files:

- `VisualDSP/test_AGC/agc.asm`
- `VisualDSP/test_AGC/agc.dpj`
- `VisualDSP/test_AGC/agc.mak`
- `VisualDSP/test_AGC/ADSP-2181.ldf`
- `VisualDSP/test_AGC/def2181.h`
- `VisualDSP/test_ALE/ALE.H`
- `VisualDSP/test_ALE/ALE_FCT.DSP`
- `VisualDSP/test_ALE/ALE_IO.DSP`
- `VisualDSP/test_ALE/ALE_TEST.DSP`
- `VisualDSP/test_ALE/ale.dpj`
- `VisualDSP/test_ALE/ale.mak`
- `VisualDSP/test_ALE/ADSP-2181_ASM.ldf`
- `VisualDSP/test_MF/median.asm`
- `VisualDSP/test_MF/median_filter.dpj`
- `VisualDSP/test_MF/median_filter.mak`
- `VisualDSP/test_MF/ADSP-2181.ldf`
- `VisualDSP/test_MF/def2181.h`
- `ADSP/def2181.h`
- `test_inputs/input_agc.dat`
- `test_inputs/input_ALE.dat`
- `test_inputs/input_imp.dat`

New authored files:

- `ADSP/llms_fragment_from_instruction_set.asm`
- `PDF_AUDIT.md`
- `docs/FULL_SYSTEM_NOTES.md`
- `docs/VISUALDSP_SIMULATION_NOTES.md`
- `docs/SYSTEM_GRAPH.md`
- `docs/SYSTEM_ORGANIGRAM.md`
- `VERIFY_DOC_IDENTITY.ps1`

Important boundary:

- I rebuilt only the ADSP / VisualDSP side in `Var2`, because that is what you requested.
- The full system diagrams still include the STM32 side, using the PDF-described STM32 configuration from `test_P2_STM32_2026/test/test.pdf` and `Setarea intreruperilor.pdf`.
- The local environment still does not contain the VisualDSP assembler license or the STM32 build toolchain, so exactness is verified here by file identity checks, not by rebuilding both IDE projects.

To verify the copied code matches the documented source files, run:

```powershell
powershell -ExecutionPolicy Bypass -File .\Var2\VERIFY_DOC_IDENTITY.ps1
```
