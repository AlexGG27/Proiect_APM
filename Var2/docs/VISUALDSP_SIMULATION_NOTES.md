# VisualDSP Simulation Notes

These notes were derived from:

- `IO Streams Simulating.pdf`
- `Interrupts Simulating.pdf`
- `plot.pdf`

## Input / Output Streams

The documented VisualDSP simulation flow is:

1. Build the DSP executable in VisualDSP++.
2. Start an `ADSP-2181` simulation session.
3. Load the executable.
4. Open `Settings -> Streams`.
5. Add an output stream from the debug target SPORT device to a file.
6. Add an input stream from a file to the debug target SPORT device.

Suggested local inputs for `Var2`:

- `test_inputs/input_agc.dat`
- `test_inputs/input_ALE.dat`
- `test_inputs/input_imp.dat`

## Interrupt Simulation

The documented interrupt flow is:

1. Open `Settings -> Interrupts`.
2. Select the external interrupt to simulate.
3. Set an offset and cycle interval.
4. Add the interrupt event.
5. Run the program with a breakpoint at the interrupt vector table when needed.

Use this for:

- periodic receive events in stream tests
- command / event stimulation when validating the DSP projects

## Plot Window Workflow

The documented plot flow is:

1. Open a plot configuration window.
2. Add a data set.
3. Select memory type and symbol/address.
4. Set count, stride, and data type.
5. Apply style/settings and enable the data set.

This is useful for:

- inspecting delay lines
- viewing filter coefficients
- viewing processed output buffers
