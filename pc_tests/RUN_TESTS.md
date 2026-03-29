# Run Tests

This folder contains the PC-only tests you can use without hardware.

## 1. STM32 logic and build

The STM32 code was simplified so the `TIM2` callback only samples inputs and sets a flag.

What changed conceptually:

- command read is hardcoded from `GPIOA->IDR`
- LED + PCDA output is hardcoded to `GPIOB->ODR`
- the `TIM2` callback no longer contains an `if`
- the state machine runs in the main loop

### What to verify in STM32CubeIDE

1. Open the STM32 project.
2. `Project -> Clean`
3. `Project -> Build Project`
4. Open `Core/Src/main.c` and verify:
   - `HAL_TIM_PeriodElapsedCallback()` only samples command and `PRG`
   - `ARM_ReadCommand()` uses `GPIOA->IDR`
   - `ARM_ReadPrg()` uses `GPIOA->IDR`
   - `ARM_WriteOutputBus()` writes the whole 16-bit LED+PCDA bus
   - `ARM_ProcessTick()` handles the state machine outside the interrupt

## 2. DSP simulator with graph plotting

The DSP source now has a plot-friendly simulator mode.

Important symbols:

- `simulator_mode`
- `debug_override_enable`
- `debug_command`
- `debug_switches`
- `sim_decode_request`
- `sim_run_request`
- `sim_run_done`
- `sim_state`
- `sim_counter`
- `sim_input_plot`
- `sim_output_plot`
- `sim_plot_count`
- `current_mode`
- `current_channel`

### Goal

You trigger a command decode in software, then trigger a simulation run, and finally plot:

- `sim_input_plot`
- `sim_output_plot`

This lets you see the algorithm response directly in VisualDSP.

### Step-by-step in VisualDSP++

1. Open `test_ext.dpj`.
2. Build the DSP project.
3. Use target `ADSP-2181 Simulation`.
4. `Debug -> Load Program` and load `Debug/test_ext.dxe`.
5. `Debug -> Restart`.
6. Open `Memory -> Data`.
7. Before changing anything, check the defaults from the loaded binary:
   - `debug_command = 00C0`
   - `sim_state = 0000`
   If `debug_command` is not `00C0`, the wrong `.dxe` is loaded.
8. Set:
   - `simulator_mode = 0001`
   - `debug_override_enable = 0001`
   - `debug_switches = 0000`
9. Choose one command:
   - `debug_command = 00C0` for AGC left
   - `debug_command = 00C1` for ALE left
   - `debug_command = 00C2` for MF left
   - `debug_command = 00C8` for AGC right
   - `debug_command = 00C9` for ALE right
   - `debug_command = 00CA` for MF right
10. Set:
   - `sim_decode_request = 0001`
11. Run once.
12. Halt.
13. In `Memory -> Data`, verify:
   - `current_mode`
   - `current_channel`
   - `sim_state = 0000`
14. Set:
   - `sim_run_request = 0001`
15. Run again.
16. Halt after a short moment and verify:
   - `sim_run_done = 0001`
   - `sim_state = 0007`
   - `sim_counter = 0000`

If `sim_run_done` does not become `0001`, inspect `sim_state`:

- `0000` = idle, request was not consumed yet
- `0001` = decode in progress
- `0002` = run was requested and frame is starting
- `0003` = AGC frame
- `0004` = ALE frame
- `0005` = MF frame
- `0006` = bypass frame
- `0007` = frame done

For the plot-only flow you do not need `IRQ2` anymore.

### If `current_mode` stays `0003`

`0003` means bypass. The decode path saw an invalid command or did not use the debug override values.

Check these values right after `sim_decode_request = 0001`, `Run`, `Halt`:

- `debug_override_enable`
- `current_command`
- `current_mode`
- `current_channel`
- `sim_state`

Interpretation:

- `current_command = 0000` means the debug command was not latched. Usually this means `debug_override_enable` was `0000`, `simulator_mode` was `0000`, or `Restart` was pressed after editing the variables.
- `current_command = 00C0` and `current_mode = 0000` means AGC left decode is correct.
- `current_command = 00C1` and `current_mode = 0001` means ALE left decode is correct.
- `current_command = 00C2` and `current_mode = 0002` means MF left decode is correct.
- `current_command = 00C0` but `current_mode = 0003` usually means the wrong `.dxe` was loaded.

To isolate plotting from decode, you can manually set:

- `current_mode = 0000`
- `current_channel = 0000`
- `sim_run_request = 0001`

Then `Run`, `Halt`, and verify:

- `sim_run_done = 0001`
- `sim_state = 0007`

### Plotting in VisualDSP

Use `plot.pdf` as reference for the Plot window.

1. Open a Plot window.
2. Add a data set named `input`.
3. Set:
   - Memory = `Data`
   - Address = `sim_input_plot`
   - Count = `128`
   - Stride = `1`
   - Data = `int`
4. Add a second data set named `output`.
5. Set:
   - Memory = `Data`
   - Address = `sim_output_plot`
   - Count = `128`
   - Stride = `1`
   - Data = `int`
6. Enable both data sets.

### What you should see

- AGC: output amplitude should be more uniform than input
- ALE: output should be smoother / more predictable than noisy input
- MF: output should suppress impulse spikes better than input

## 3. Extra project checks from PowerShell

You can run:

```powershell
powershell -ExecutionPolicy Bypass -File .\pc_tests\check_whole_project.ps1
```

## 4. MATLAB / Octave checks

You can also run:

- `run_all_matlab_tests.m`
- `test_stm32_logic.m`
- `test_dsp_decode.m`

And the example scripts from:

- `Exemple prelucrari de semnal/Exemple prelucrari de semnal/matlab/test_AGC.m`
- `Exemple prelucrari de semnal/Exemple prelucrari de semnal/matlab/test_ALE.m`
- `Exemple prelucrari de semnal/Exemple prelucrari de semnal/matlab/test_MF.m`

For the standalone VisualDSP examples, see:

- `pc_tests/EXEMPLE_VISUALDSP.md`

## 5. No-hardware verdict

Without boards, the strongest proof you can obtain is:

1. STM32 builds and its state machine is clear and correct.
2. DSP builds and decodes commands correctly.
3. DSP simulator produces input/output plots for the selected mode.
4. Command encoding matches between STM32 and DSP.

What still cannot be fully proven without hardware:

- electrical GPIO behavior
- codec behavior
- real STM32 <-> DSP wiring
- real-time behavior on the board
