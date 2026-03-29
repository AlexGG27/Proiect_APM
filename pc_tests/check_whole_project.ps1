$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path -Parent $PSScriptRoot
$dspAsm = Join-Path $repoRoot 'DSP test\DSP test\test_ext\test_ext.asm'
$dspDxe = Join-Path $repoRoot 'DSP test\DSP test\test_ext\Debug\test_ext.dxe'
$stmMain = Join-Path $repoRoot 'test_P2_STM32_2026\test\Core\Src\main.c'
$stmIoc = Join-Path $repoRoot 'test_P2_STM32_2026\test\test.ioc'
$stmElf = Join-Path $repoRoot 'test_P2_STM32_2026\test\Debug\test.elf'
$stmTest = Join-Path $PSScriptRoot 'stm32_logic_sim.c'

$failures = 0

function Check-Pattern {
    param(
        [string]$Path,
        [string]$Pattern,
        [string]$Name
    )

    if (Select-String -Path $Path -Pattern $Pattern -Quiet) {
        Write-Host "PASS $Name"
    }
    else {
        Write-Host "FAIL $Name"
        $script:failures++
    }
}

function Check-File {
    param(
        [string]$Path,
        [string]$Name
    )

    if (Test-Path $Path) {
        Write-Host "PASS $Name"
    }
    else {
        Write-Host "FAIL $Name"
        $script:failures++
    }
}

Check-File $dspAsm 'dsp_source_exists'
Check-File $dspDxe 'dsp_binary_exists'
Check-Pattern $dspAsm '^\.global simulator_mode;' 'dsp_simulator_symbol_exported'
Check-Pattern $dspAsm '^\.var    simulator_mode = 0x0000;' 'dsp_simulator_variable_present'
Check-Pattern $dspAsm '^setup_simulator:' 'dsp_simulator_path_present'
Check-Pattern $dspAsm '^simulator_wait:' 'dsp_simulator_loop_present'
Check-Pattern $dspAsm '^run_simulation_frame:' 'dsp_plot_runner_present'
Check-Pattern $dspAsm '^\.global sim_run_request;' 'dsp_plot_control_symbol_exported'
Check-Pattern $dspAsm '^\.global sim_input_plot;' 'dsp_plot_input_symbol_exported'
Check-Pattern $dspAsm '^\.global sim_output_plot;' 'dsp_plot_output_symbol_exported'
Check-Pattern $dspAsm '^cmd_interrupt_hw:' 'dsp_hw_interrupt_path_present'

Check-File $stmMain 'stm32_main_exists'
Check-File $stmIoc 'stm32_ioc_exists'
Check-File $stmElf 'stm32_elf_exists'
Check-Pattern $stmMain 'HAL_TIM_PeriodElapsedCallback' 'stm32_tim2_callback_present'
Check-Pattern $stmMain '\(void\)htim;' 'stm32_tim2_callback_has_no_timer_if'
Check-Pattern $stmMain 'ARM_ReadCommand\(\)' 'stm32_command_reader_present'
Check-Pattern $stmMain 'ARM_ReadPrg\(\)' 'stm32_prg_reader_present'
Check-Pattern $stmMain 'ARM_WriteOutputBus\(0U\)' 'stm32_output_bus_init_present'
Check-Pattern $stmMain 'ARM_ProcessTick\(sampledCommand, prgLevel\)' 'stm32_state_machine_outside_isr'
Check-Pattern $stmMain 'HAL_TIM_Base_Start_IT\(&htim2\)' 'stm32_tim2_started'
Check-Pattern $stmIoc 'NVIC\.TIM2_IRQn=true' 'stm32_tim2_irq_enabled'
Check-Pattern $stmIoc 'TIM2\.Prescaler=7199' 'stm32_tim2_prescaler_expected'
Check-Pattern $stmIoc 'TIM2\.Period=100' 'stm32_tim2_period_expected'
Check-File $stmTest 'pc_stm32_logic_test_exists'

if ($failures -eq 0) {
    Write-Host 'PASS all_project_checks'
    exit 0
}

Write-Host 'FAIL project_checks'
exit 1
