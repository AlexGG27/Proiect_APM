# PDF Audit

All PDFs in the repository were read before creating `Var2`.

## Files Reviewed

1. `adsp21xx._instruction_set.pdf`
2. `Interrupts Simulating.pdf`
3. `IO Streams Simulating.pdf`
4. `plot.pdf`
5. `Setarea intreruperilor.pdf`
6. `Tema P2-2026.pdf`
7. `test_P2_STM32_2026/test/test.pdf`

## What Each PDF Contributed

### `Tema P2-2026.pdf`

- Defines the full project architecture: ARM subsystem + DSP subsystem.
- Confirms the three DSP functions: `AGC`, `ALE`, and `MF`.
- Confirms the deliverable is a complete two-subsystem system.

### `Setarea intreruperilor.pdf`

- Confirms the STM32 side uses `TIM2`.
- Confirms `HAL_TIM_PeriodElapsedCallback()` is the intended user callback in `main.c`.
- Confirms `HAL_TIM_Base_Start_IT(&htim2);` is required at initialization.

### `test_P2_STM32_2026/test/test.pdf`

- Confirms the STM32F103 pinout and labels used by the ARM subsystem.
- Confirms `B0...B7`, `PRG`, `LED0...LED7`, and `PCDA0...PCDA7`.
- Confirms `TIM2` timing-base configuration and NVIC enable.

### `IO Streams Simulating.pdf`

- Confirms the VisualDSP stream workflow for input/output simulation.
- Confirms the use of a serial input file, a serial output file, and an interrupt-driven talk-through style run.

### `Interrupts Simulating.pdf`

- Confirms the VisualDSP interrupt injection workflow.
- Supports the IRQ-driven DSP simulation flow used by the example projects.

### `plot.pdf`

- Confirms how a data set is attached to a VisualDSP plot window.
- Used as the basis for the plotting notes in `docs/VISUALDSP_SIMULATION_NOTES.md`.

### `adsp21xx._instruction_set.pdf`

- Confirms ADSP-21xx assembly syntax and instruction categories.
- Contains the LLMS/LMS-style adaptive-filter code fragment transcribed into `ADSP/llms_fragment_from_instruction_set.asm`.

## Code Source Policy Used For `Var2`

- When a repository file already matched the documented example project, it was copied verbatim into `Var2`.
- When the only available source was a PDF snippet, it was transcribed into a dedicated reference file and clearly labeled as such.
- New explanatory files in `docs/` were authored only to document how the copied code fits into the full ARM + DSP system.
