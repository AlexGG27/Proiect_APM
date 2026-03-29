# Snippet STM32 - Callback Timer TIM2 / Masina de Stari TRS_CDA

Acest fisier contine exact bucata de cod relevanta pentru:

- `Callback Timer TIM2`
- `Masina de Stari TRS_CDA`

Poti da copy-paste direct din blocurile de mai jos in documentatie.

## 1. Definirea starilor


typedef enum
{
  ARM_STATE_WAIT_PRG_LOW = 0,
  ARM_STATE_WAIT_PRG_HIGH,
  ARM_STATE_SEND_COMMAND
} ArmState_t;
```

## 2. Variabilele folosite de TIM2


static volatile uint8_t g_sampledCommand;
static volatile uint8_t g_prgLevel;
static volatile uint8_t g_tickReady;
static ArmState_t g_armState = ARM_STATE_WAIT_PRG_LOW;
```

## 3. Callback-ul TIM2


void HAL_TIM_PeriodElapsedCallback(TIM_HandleTypeDef *htim)
{
  (void)htim;
  g_sampledCommand = ARM_ReadCommand();
  g_prgLevel = ARM_ReadPrg();
  g_tickReady = 1U;
}
```

## 4. Bucata din main loop care porneste automatul


while (1)
{
  if (g_tickReady == 0U)
  {
    continue;
  }

  __disable_irq();
  uint8_t sampledCommand = g_sampledCommand;
  uint8_t prgLevel = g_prgLevel;
  g_tickReady = 0U;
  __enable_irq();

  ARM_ProcessTick(sampledCommand, prgLevel);
}
```

## 5. Citirea intrarilor


static uint8_t ARM_ReadCommand(void)
{
  return (uint8_t)((GPIOA->IDR >> 1U) & 0x00FFU);
}

static uint8_t ARM_ReadPrg(void)
{
  return (uint8_t)((GPIOA->IDR >> 9U) & 0x01U);
}
```

## 6. Tranzitiile masinii de stari TRS_CDA


static ArmState_t ARM_NextState(ArmState_t currentState, uint8_t prgLevel)
{
  switch (currentState)
  {
    case ARM_STATE_WAIT_PRG_LOW:
      return (prgLevel == 0U) ? ARM_STATE_WAIT_PRG_HIGH : ARM_STATE_WAIT_PRG_LOW;

    case ARM_STATE_WAIT_PRG_HIGH:
      return (prgLevel != 0U) ? ARM_STATE_SEND_COMMAND : ARM_STATE_WAIT_PRG_HIGH;

    case ARM_STATE_SEND_COMMAND:
    default:
      return ARM_STATE_WAIT_PRG_LOW;
  }
}
```

## 7. Scrierea comenzii pe LED-uri si pe magistrala PCDA


static void ARM_WriteOutputBus(uint8_t value)
{
  GPIOB->ODR = (uint16_t)(((uint16_t)value << 8U) | value);
}
```

## 8. Functia care executa automatul


static void ARM_ProcessTick(uint8_t sampledCommand, uint8_t prgLevel)
{
  g_armState = ARM_NextState(g_armState, prgLevel);

  if (g_armState == ARM_STATE_SEND_COMMAND)
  {
    ARM_WriteOutputBus(sampledCommand);
    g_armState = ARM_STATE_WAIT_PRG_LOW;
  }
}
```

## 9. Varianta compacta pentru documentatie


typedef enum
{
  ARM_STATE_WAIT_PRG_LOW = 0,
  ARM_STATE_WAIT_PRG_HIGH,
  ARM_STATE_SEND_COMMAND
} ArmState_t;

static volatile uint8_t g_sampledCommand;
static volatile uint8_t g_prgLevel;
static volatile uint8_t g_tickReady;
static ArmState_t g_armState = ARM_STATE_WAIT_PRG_LOW;

void HAL_TIM_PeriodElapsedCallback(TIM_HandleTypeDef *htim)
{
  (void)htim;
  g_sampledCommand = ARM_ReadCommand();
  g_prgLevel = ARM_ReadPrg();
  g_tickReady = 1U;
}

static uint8_t ARM_ReadCommand(void)
{
  return (uint8_t)((GPIOA->IDR >> 1U) & 0x00FFU);
}

static uint8_t ARM_ReadPrg(void)
{
  return (uint8_t)((GPIOA->IDR >> 9U) & 0x01U);
}

static ArmState_t ARM_NextState(ArmState_t currentState, uint8_t prgLevel)
{
  switch (currentState)
  {
    case ARM_STATE_WAIT_PRG_LOW:
      return (prgLevel == 0U) ? ARM_STATE_WAIT_PRG_HIGH : ARM_STATE_WAIT_PRG_LOW;

    case ARM_STATE_WAIT_PRG_HIGH:
      return (prgLevel != 0U) ? ARM_STATE_SEND_COMMAND : ARM_STATE_WAIT_PRG_HIGH;

    case ARM_STATE_SEND_COMMAND:
    default:
      return ARM_STATE_WAIT_PRG_LOW;
  }
}

static void ARM_WriteOutputBus(uint8_t value)
{
  GPIOB->ODR = (uint16_t)(((uint16_t)value << 8U) | value);
}

static void ARM_ProcessTick(uint8_t sampledCommand, uint8_t prgLevel)
{
  g_armState = ARM_NextState(g_armState, prgLevel);

  if (g_armState == ARM_STATE_SEND_COMMAND)
  {
    ARM_WriteOutputBus(sampledCommand);
    g_armState = ARM_STATE_WAIT_PRG_LOW;
  }
}
```

