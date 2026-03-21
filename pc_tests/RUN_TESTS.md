# Run Tests

This folder contains the PC-only tests you can use without hardware.

## 1. STM32 logic test

File:

- `pc_tests/stm32_logic_sim.c`

This is a small desktop simulation of the STM32 command state machine from `Core/Src/main.c`.

It checks:

- no transmit while the sequence is incomplete
- one transmit for a valid `PRG` sequence
- transmitted value matches the sampled 8-bit command

### How to run

If you have GCC on Windows:

```powershell
gcc .\pc_tests\stm32_logic_sim.c -o .\pc_tests\stm32_logic_sim.exe
.\pc_tests\stm32_logic_sim.exe
```

Expected output:

```text
PASS idle_does_not_transmit
PASS agc_left_transmit
PASS mf_right_transmit
PASS
```

## 2. DSP simulator test

Use VisualDSP++ with the `ADSP-2181 Simulation` target.

The DSP source now exports these symbols:

- `simulator_mode`
- `debug_override_enable`
- `debug_command`
- `debug_switches`
- `current_command`
- `current_switches`
- `current_mode`
- `current_channel`

### Values to set

In `Memory -> Data`:

- `simulator_mode = 0001`
- `debug_override_enable = 0001`
- `debug_switches = 0000`

Then test these commands one by one:

- `debug_command = 00C0`
- `debug_command = 00C1`
- `debug_command = 00C2`
- `debug_command = 00C8`
- `debug_command = 00C9`
- `debug_command = 00CA`
- `debug_command = 0000`

### Expected decode results

- `00C0` -> `current_mode = 0000`, `current_channel = 0000`
- `00C1` -> `current_mode = 0001`, `current_channel = 0000`
- `00C2` -> `current_mode = 0002`, `current_channel = 0000`
- `00C8` -> `current_mode = 0000`, `current_channel = 0001`
- `00C9` -> `current_mode = 0001`, `current_channel = 0001`
- `00CA` -> `current_mode = 0002`, `current_channel = 0001`
- `0000` -> `current_mode = 0003`

### How to trigger the command path

1. Put a breakpoint on `cmd_interrupt_done` or `update_display`.
2. Go to `Settings -> Interrupts`.
3. Add `IRQ2` with:
   - `Offset = 100`
   - `Min cycles = 100`
   - `Max cycles = 100`
4. Run.

## 3. STM32 build test

From STM32CubeIDE:

1. Open the project.
2. `Project -> Clean`
3. `Project -> Build Project`

Checks:

- project builds
- `TIM2` is configured
- the callback exists
- the transmit path is compiled

## 4. Whole-project no-hardware verdict

Without boards, the most you can prove is:

1. STM32 compiles and its command-state logic is correct.
2. DSP compiles and decodes commands correctly in simulation.
3. The command bytes match between STM32 and DSP.

Without hardware, you cannot fully prove:

- GPIO electrical behavior
- codec audio path
- real STM32 to DSP wiring
- real-time end-to-end behavior
