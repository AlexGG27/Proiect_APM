#include "stm32f1xx_hal.h"

TIM_HandleTypeDef htim2;

/*
 * Configurare TIM2 pentru esantionare periodica:
 * - timer pe baza de clock intern
 * - prescaler = 7199
 * - period = 100
 * - counter mode = up
 * - fara preload pe autoreload
 *
 * Pentru un clock de 72 MHz:
 * - frecventa dupa prescaler = 72 MHz / 7200 = 10 kHz
 * - eveniment de update = 10 kHz / 101 ~= 99 Hz
 *
 * Timerul este folosit pentru a declansa periodic callback-ul
 * HAL_TIM_PeriodElapsedCallback(), unde se citesc B7..B0 si PRG.
 */
static void MX_TIM2_Init(void)
{
    TIM_ClockConfigTypeDef sClockSourceConfig = {0};
    TIM_MasterConfigTypeDef sMasterConfig = {0};
    TIM_OC_InitTypeDef sConfigOC = {0};

    htim2.Instance = TIM2;
    htim2.Init.Prescaler = 7199;
    htim2.Init.CounterMode = TIM_COUNTERMODE_UP;
    htim2.Init.Period = 100;
    htim2.Init.ClockDivision = TIM_CLOCKDIVISION_DIV1;
    htim2.Init.AutoReloadPreload = TIM_AUTORELOAD_PRELOAD_DISABLE;

    if (HAL_TIM_Base_Init(&htim2) != HAL_OK)
    {
        Error_Handler();
    }

    /* Timerul foloseste sursa interna de ceas. */
    sClockSourceConfig.ClockSource = TIM_CLOCKSOURCE_INTERNAL;
    if (HAL_TIM_ConfigClockSource(&htim2, &sClockSourceConfig) != HAL_OK)
    {
        Error_Handler();
    }

    /* Canalul CH1 este configurat in modul timing deoarece a fost generat
     * automat de CubeMX. In aplicatia noastra, TIM2 este folosit in primul
     * rand ca baza de timp pentru intreruperea periodica.
     */
    if (HAL_TIM_OC_Init(&htim2) != HAL_OK)
    {
        Error_Handler();
    }

    sMasterConfig.MasterOutputTrigger = TIM_TRGO_RESET;
    sMasterConfig.MasterSlaveMode = TIM_MASTERSLAVEMODE_DISABLE;
    if (HAL_TIMEx_MasterConfigSynchronization(&htim2, &sMasterConfig) != HAL_OK)
    {
        Error_Handler();
    }

    sConfigOC.OCMode = TIM_OCMODE_TIMING;
    sConfigOC.Pulse = 0;
    sConfigOC.OCPolarity = TIM_OCPOLARITY_HIGH;
    sConfigOC.OCFastMode = TIM_OCFAST_DISABLE;
    if (HAL_TIM_OC_ConfigChannel(&htim2, &sConfigOC, TIM_CHANNEL_1) != HAL_OK)
    {
        Error_Handler();
    }

    HAL_TIM_MspPostInit(&htim2);
}
