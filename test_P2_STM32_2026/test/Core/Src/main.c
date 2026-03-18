/* USER CODE BEGIN Header */
/**
  ******************************************************************************
  * @file           : main.c
  * @brief          : Main program body
  ******************************************************************************
  * @attention
  *
  * Copyright (c) 2026 STMicroelectronics.
  * All rights reserved.
  *
  * This software is licensed under terms that can be found in the LICENSE file
  * in the root directory of this software component.
  * If no LICENSE file comes with this software, it is provided AS-IS.
  *
  ******************************************************************************
  */
/* USER CODE END Header */
/* Includes ------------------------------------------------------------------*/
#include "main.h"

/* Private includes ----------------------------------------------------------*/
/* USER CODE BEGIN Includes */

/* USER CODE END Includes */

/* Private typedef -----------------------------------------------------------*/
/* USER CODE BEGIN PTD */
typedef enum
{
  ARM_STATE_WAIT_RELEASE = 0,
  ARM_STATE_WAIT_PRESS,
  ARM_STATE_TRANSMIT
} ArmState_t;

/* USER CODE END PTD */

/* Private define ------------------------------------------------------------*/
/* USER CODE BEGIN PD */

/* USER CODE END PD */

/* Private macro -------------------------------------------------------------*/
/* USER CODE BEGIN PM */

/* USER CODE END PM */

/* Private variables ---------------------------------------------------------*/
TIM_HandleTypeDef htim2;

/* USER CODE BEGIN PV */
static volatile uint8_t g_sampledCommand;
static volatile uint8_t g_prgLevel;
static volatile uint8_t g_tickReady;
static volatile uint8_t g_lastCommand;
static ArmState_t g_armState = ARM_STATE_WAIT_RELEASE;

/* USER CODE END PV */

/* Private function prototypes -----------------------------------------------*/
void SystemClock_Config(void);
static void MX_GPIO_Init(void);
static void MX_TIM2_Init(void);
/* USER CODE BEGIN PFP */
static uint8_t ARM_ReadCommand(void);
static void ARM_WriteLedBus(uint8_t value);
static void ARM_WriteCommandBus(uint8_t value);
static void ARM_TransmitCommand(uint8_t value);

/* USER CODE END PFP */

/* Private user code ---------------------------------------------------------*/
/* USER CODE BEGIN 0 */
/* Timer2 Interrupt Service Routine*/
void HAL_TIM_PeriodElapsedCallback(TIM_HandleTypeDef *htim)
{
  if (htim->Instance != TIM2)
  {
    return;
  }

  g_sampledCommand = ARM_ReadCommand();
  g_prgLevel = (HAL_GPIO_ReadPin(PRG_GPIO_Port, PRG_Pin) == GPIO_PIN_SET) ? 1U : 0U;
  g_tickReady = 1U;
}
/* USER CODE END 0 */

/**
  * @brief  The application entry point.
  * @retval int
  */
int main(void)
{

  /* USER CODE BEGIN 1 */

  /* USER CODE END 1 */

  /* MCU Configuration--------------------------------------------------------*/

  /* Reset of all peripherals, Initializes the Flash interface and the Systick. */
  HAL_Init();

  /* USER CODE BEGIN Init */

  /* USER CODE END Init */

  /* Configure the system clock */
  SystemClock_Config();

  /* USER CODE BEGIN SysInit */

  /* USER CODE END SysInit */

  /* Initialize all configured peripherals */
  MX_GPIO_Init();
  MX_TIM2_Init();
  /* USER CODE BEGIN 2 */
  ARM_WriteLedBus(0U);
  ARM_WriteCommandBus(0U);
  HAL_TIM_Base_Start_IT(&htim2); //enable Timer 2 interrupt
  /* USER CODE END 2 */

  /* Infinite loop */
  /* USER CODE BEGIN WHILE */
  while (1)
  {
    /* USER CODE END WHILE */

    /* USER CODE BEGIN 3 */
    if (g_tickReady == 0U)
    {
      continue;
    }

    __disable_irq();
    uint8_t sampledCommand = g_sampledCommand;
    uint8_t prgLevel = g_prgLevel;
    g_tickReady = 0U;
    __enable_irq();

    switch (g_armState)
    {
      case ARM_STATE_WAIT_RELEASE:
        if (prgLevel == 0U)
        {
          g_armState = ARM_STATE_WAIT_PRESS;
        }
        break;

      case ARM_STATE_WAIT_PRESS:
        if (prgLevel != 0U)
        {
          g_armState = ARM_STATE_TRANSMIT;
        }
        break;

      case ARM_STATE_TRANSMIT:
        ARM_TransmitCommand(sampledCommand);
        g_armState = ARM_STATE_WAIT_RELEASE;
        break;

      default:
        g_armState = ARM_STATE_WAIT_RELEASE;
        break;
    }
  }
  /* USER CODE END 3 */
}

/**
  * @brief System Clock Configuration
  * @retval None
  */
void SystemClock_Config(void)
{
  RCC_OscInitTypeDef RCC_OscInitStruct = {0};
  RCC_ClkInitTypeDef RCC_ClkInitStruct = {0};

  /** Initializes the RCC Oscillators according to the specified parameters
  * in the RCC_OscInitTypeDef structure.
  */
  RCC_OscInitStruct.OscillatorType = RCC_OSCILLATORTYPE_HSE;
  RCC_OscInitStruct.HSEState = RCC_HSE_ON;
  RCC_OscInitStruct.HSEPredivValue = RCC_HSE_PREDIV_DIV1;
  RCC_OscInitStruct.HSIState = RCC_HSI_ON;
  RCC_OscInitStruct.PLL.PLLState = RCC_PLL_ON;
  RCC_OscInitStruct.PLL.PLLSource = RCC_PLLSOURCE_HSE;
  RCC_OscInitStruct.PLL.PLLMUL = RCC_PLL_MUL9;
  if (HAL_RCC_OscConfig(&RCC_OscInitStruct) != HAL_OK)
  {
    Error_Handler();
  }

  /** Initializes the CPU, AHB and APB buses clocks
  */
  RCC_ClkInitStruct.ClockType = RCC_CLOCKTYPE_HCLK|RCC_CLOCKTYPE_SYSCLK
                              |RCC_CLOCKTYPE_PCLK1|RCC_CLOCKTYPE_PCLK2;
  RCC_ClkInitStruct.SYSCLKSource = RCC_SYSCLKSOURCE_PLLCLK;
  RCC_ClkInitStruct.AHBCLKDivider = RCC_SYSCLK_DIV1;
  RCC_ClkInitStruct.APB1CLKDivider = RCC_HCLK_DIV2;
  RCC_ClkInitStruct.APB2CLKDivider = RCC_HCLK_DIV1;

  if (HAL_RCC_ClockConfig(&RCC_ClkInitStruct, FLASH_LATENCY_2) != HAL_OK)
  {
    Error_Handler();
  }
}

/**
  * @brief TIM2 Initialization Function
  * @param None
  * @retval None
  */
static void MX_TIM2_Init(void)
{

  /* USER CODE BEGIN TIM2_Init 0 */

  /* USER CODE END TIM2_Init 0 */

  TIM_ClockConfigTypeDef sClockSourceConfig = {0};
  TIM_MasterConfigTypeDef sMasterConfig = {0};
  TIM_OC_InitTypeDef sConfigOC = {0};

  /* USER CODE BEGIN TIM2_Init 1 */

  /* USER CODE END TIM2_Init 1 */
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
  sClockSourceConfig.ClockSource = TIM_CLOCKSOURCE_INTERNAL;
  if (HAL_TIM_ConfigClockSource(&htim2, &sClockSourceConfig) != HAL_OK)
  {
    Error_Handler();
  }
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
  /* USER CODE BEGIN TIM2_Init 2 */

  /* USER CODE END TIM2_Init 2 */
  HAL_TIM_MspPostInit(&htim2);

}

/**
  * @brief GPIO Initialization Function
  * @param None
  * @retval None
  */
static void MX_GPIO_Init(void)
{
  GPIO_InitTypeDef GPIO_InitStruct = {0};
/* USER CODE BEGIN MX_GPIO_Init_1 */
/* USER CODE END MX_GPIO_Init_1 */

  /* GPIO Ports Clock Enable */
  __HAL_RCC_GPIOD_CLK_ENABLE();
  __HAL_RCC_GPIOA_CLK_ENABLE();
  __HAL_RCC_GPIOB_CLK_ENABLE();

  /*Configure GPIO pin Output Level */
  HAL_GPIO_WritePin(GPIOB, LED0_Pin|LED1_Pin|LED2_Pin|PCDA2_Pin
                          |PCDA3_Pin|PCDA4_Pin|PCDA5_Pin|PCDA6_Pin
                          |PCDA7_Pin|LED3_Pin|LED4_Pin|LED5_Pin
                          |LED6_Pin|LED7_Pin|PCDA0_Pin|PCDA1_Pin, GPIO_PIN_RESET);

  /*Configure GPIO pins : B0_Pin B1_Pin B2_Pin B3_Pin
                           B4_Pin B5_Pin B6_Pin B7_Pin
                           PRG_Pin */
  GPIO_InitStruct.Pin = B0_Pin|B1_Pin|B2_Pin|B3_Pin
                          |B4_Pin|B5_Pin|B6_Pin|B7_Pin
                          |PRG_Pin;
  GPIO_InitStruct.Mode = GPIO_MODE_INPUT;
  GPIO_InitStruct.Pull = GPIO_NOPULL;
  HAL_GPIO_Init(GPIOA, &GPIO_InitStruct);

  /*Configure GPIO pins : LED0_Pin LED1_Pin LED2_Pin PCDA2_Pin
                           PCDA3_Pin PCDA4_Pin PCDA5_Pin PCDA6_Pin
                           PCDA7_Pin LED3_Pin LED4_Pin LED5_Pin
                           LED6_Pin LED7_Pin PCDA0_Pin PCDA1_Pin */
  GPIO_InitStruct.Pin = LED0_Pin|LED1_Pin|LED2_Pin|PCDA2_Pin
                          |PCDA3_Pin|PCDA4_Pin|PCDA5_Pin|PCDA6_Pin
                          |PCDA7_Pin|LED3_Pin|LED4_Pin|LED5_Pin
                          |LED6_Pin|LED7_Pin|PCDA0_Pin|PCDA1_Pin;
  GPIO_InitStruct.Mode = GPIO_MODE_OUTPUT_PP;
  GPIO_InitStruct.Pull = GPIO_NOPULL;
  GPIO_InitStruct.Speed = GPIO_SPEED_FREQ_LOW;
  HAL_GPIO_Init(GPIOB, &GPIO_InitStruct);

/* USER CODE BEGIN MX_GPIO_Init_2 */
/* USER CODE END MX_GPIO_Init_2 */
}

/* USER CODE BEGIN 4 */
static uint8_t ARM_ReadCommand(void)
{
  uint8_t value = 0U;

  value |= (HAL_GPIO_ReadPin(B0_GPIO_Port, B0_Pin) == GPIO_PIN_SET) ? (1U << 0) : 0U;
  value |= (HAL_GPIO_ReadPin(B1_GPIO_Port, B1_Pin) == GPIO_PIN_SET) ? (1U << 1) : 0U;
  value |= (HAL_GPIO_ReadPin(B2_GPIO_Port, B2_Pin) == GPIO_PIN_SET) ? (1U << 2) : 0U;
  value |= (HAL_GPIO_ReadPin(B3_GPIO_Port, B3_Pin) == GPIO_PIN_SET) ? (1U << 3) : 0U;
  value |= (HAL_GPIO_ReadPin(B4_GPIO_Port, B4_Pin) == GPIO_PIN_SET) ? (1U << 4) : 0U;
  value |= (HAL_GPIO_ReadPin(B5_GPIO_Port, B5_Pin) == GPIO_PIN_SET) ? (1U << 5) : 0U;
  value |= (HAL_GPIO_ReadPin(B6_GPIO_Port, B6_Pin) == GPIO_PIN_SET) ? (1U << 6) : 0U;
  value |= (HAL_GPIO_ReadPin(B7_GPIO_Port, B7_Pin) == GPIO_PIN_SET) ? (1U << 7) : 0U;

  return value;
}

static void ARM_WriteLedBus(uint8_t value)
{
  HAL_GPIO_WritePin(LED0_GPIO_Port, LED0_Pin, (value & (1U << 0)) ? GPIO_PIN_SET : GPIO_PIN_RESET);
  HAL_GPIO_WritePin(LED1_GPIO_Port, LED1_Pin, (value & (1U << 1)) ? GPIO_PIN_SET : GPIO_PIN_RESET);
  HAL_GPIO_WritePin(LED2_GPIO_Port, LED2_Pin, (value & (1U << 2)) ? GPIO_PIN_SET : GPIO_PIN_RESET);
  HAL_GPIO_WritePin(LED3_GPIO_Port, LED3_Pin, (value & (1U << 3)) ? GPIO_PIN_SET : GPIO_PIN_RESET);
  HAL_GPIO_WritePin(LED4_GPIO_Port, LED4_Pin, (value & (1U << 4)) ? GPIO_PIN_SET : GPIO_PIN_RESET);
  HAL_GPIO_WritePin(LED5_GPIO_Port, LED5_Pin, (value & (1U << 5)) ? GPIO_PIN_SET : GPIO_PIN_RESET);
  HAL_GPIO_WritePin(LED6_GPIO_Port, LED6_Pin, (value & (1U << 6)) ? GPIO_PIN_SET : GPIO_PIN_RESET);
  HAL_GPIO_WritePin(LED7_GPIO_Port, LED7_Pin, (value & (1U << 7)) ? GPIO_PIN_SET : GPIO_PIN_RESET);
}

static void ARM_WriteCommandBus(uint8_t value)
{
  HAL_GPIO_WritePin(PCDA0_GPIO_Port, PCDA0_Pin, (value & (1U << 0)) ? GPIO_PIN_SET : GPIO_PIN_RESET);
  HAL_GPIO_WritePin(PCDA1_GPIO_Port, PCDA1_Pin, (value & (1U << 1)) ? GPIO_PIN_SET : GPIO_PIN_RESET);
  HAL_GPIO_WritePin(PCDA2_GPIO_Port, PCDA2_Pin, (value & (1U << 2)) ? GPIO_PIN_SET : GPIO_PIN_RESET);
  HAL_GPIO_WritePin(PCDA3_GPIO_Port, PCDA3_Pin, (value & (1U << 3)) ? GPIO_PIN_SET : GPIO_PIN_RESET);
  HAL_GPIO_WritePin(PCDA4_GPIO_Port, PCDA4_Pin, (value & (1U << 4)) ? GPIO_PIN_SET : GPIO_PIN_RESET);
  HAL_GPIO_WritePin(PCDA5_GPIO_Port, PCDA5_Pin, (value & (1U << 5)) ? GPIO_PIN_SET : GPIO_PIN_RESET);
  HAL_GPIO_WritePin(PCDA6_GPIO_Port, PCDA6_Pin, (value & (1U << 6)) ? GPIO_PIN_SET : GPIO_PIN_RESET);
  HAL_GPIO_WritePin(PCDA7_GPIO_Port, PCDA7_Pin, (value & (1U << 7)) ? GPIO_PIN_SET : GPIO_PIN_RESET);
}

static void ARM_TransmitCommand(uint8_t value)
{
  g_lastCommand = value;
  ARM_WriteLedBus(g_lastCommand);
  ARM_WriteCommandBus(g_lastCommand);
}

/* USER CODE END 4 */

/**
  * @brief  This function is executed in case of error occurrence.
  * @retval None
  */
void Error_Handler(void)
{
  /* USER CODE BEGIN Error_Handler_Debug */
  /* User can add his own implementation to report the HAL error return state */
  __disable_irq();
  while (1)
  {
  }
  /* USER CODE END Error_Handler_Debug */
}

#ifdef  USE_FULL_ASSERT
/**
  * @brief  Reports the name of the source file and the source line number
  *         where the assert_param error has occurred.
  * @param  file: pointer to the source file name
  * @param  line: assert_param error line source number
  * @retval None
  */
void assert_failed(uint8_t *file, uint32_t line)
{
  /* USER CODE BEGIN 6 */
  /* User can add his own implementation to report the file name and line number,
     ex: printf("Wrong parameters value: file %s on line %d\r\n", file, line) */
  /* USER CODE END 6 */
}
#endif /* USE_FULL_ASSERT */
