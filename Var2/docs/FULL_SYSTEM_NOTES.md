# Full System Notes

`Var2` rebuilds the ADSP / VisualDSP code side from documented sources, but the complete system still has two subsystems.

## System Blocks

- ARM subsystem: `STM32F103`
- DSP subsystem: `ADSP-2181` on EZ-Kit LITE + IO DSP extension
- DSP functions: `AGC`, `ALE`, `MF`

## ARM Side From Documentation

From `Tema P2-2026.pdf`, `Setarea intreruperilor.pdf`, and `test_P2_STM32_2026/test/test.pdf`:

- The ARM side samples inputs with `TIM2`.
- The ARM side reads command inputs from `B0...B7` and the trigger from `PRG`.
- The ARM side drives `LED0...LED7` and the outgoing command bus `PCDA0...PCDA7`.

## DSP Side From Documentation

From the VisualDSP example projects and the ADSP instruction-set PDF:

- `AGC` is represented by `VisualDSP/test_AGC/agc.asm`.
- `ALE` is represented by `VisualDSP/test_ALE/ALE_TEST.DSP`, `ALE_FCT.DSP`, and `ALE_IO.DSP`.
- `MF` is represented by `VisualDSP/test_MF/median.asm`.
- The adaptive-filter instruction style is represented by `ADSP/llms_fragment_from_instruction_set.asm`.

## How The Full System Fits Together

1. The ARM subsystem samples the user command and waits for the command trigger.
2. The ARM subsystem places the command on the DSP-facing command bus.
3. The DSP subsystem receives an interrupt/event and selects the active processing routine.
4. The DSP subsystem processes the audio stream with one documented routine: `AGC`, `ALE`, or `MF`.
5. Both subsystems expose state through their own outputs:
   - ARM: LEDs
   - DSP: audio output and display / simulator views

## Why `Var2` Stops At The DSP Rebuild

- Your request explicitly asked for the ADSP / VisualDSP code to be redone from documentation.
- The STM32 project is therefore left in its original project location.
- The diagrams in this folder keep the ARM + DSP relation visible so the rebuilt DSP code still reads as part of one complete system.
