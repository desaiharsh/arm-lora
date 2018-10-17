// <header files>
#include "test.h"

typedef struct
{
  uint32_t SYSCLK_Frequency;
  uint32_t HCLK_Frequency;
  uint32_t PCLK1_Frequency;
  uint32_t PCLK2_Frequency;
}RCC_ClocksTypeDef1;

void SystemInit(void);
static void SetSysClock(void);
void TimingDelay_Decrement(void);
void Delay(__IO uint32_t nTime);
void SysTick_CLKSourceConfig(uint32_t SysTick_CLKSource);
void RCC_GetClocksFreq1(RCC_ClocksTypeDef1* RCC_Clocks);

#define VECT_TAB_OFFSET  0x0 /*!< Vector Table base offset field. 
                                  This value must be a multiple of 0x200. */
#define SysTick_CLKSource_HCLK_Div8    ((uint32_t)0xFFFFFFFB)
#define SysTick_CLKSource_HCLK         ((uint32_t)0x00000004)

static __IO uint32_t TimingDelay;
uint32_t SystemCoreClock    = 32000000;
__I uint8_t PLLMulTable[9] = {3, 4, 6, 8, 12, 16, 24, 32, 48};
__I uint8_t AHBPrescTable[16] = {0, 0, 0, 0, 0, 0, 0, 0, 1, 2, 3, 4, 6, 7, 8, 9};

RCC_ClocksTypeDef1 RCC_Clocks;

int main(){

	/*
		Setup code goes here
	*/
	
	SystemInit();
	
	RCC_GetClocksFreq1(&RCC_Clocks);
	SysTick_Config(RCC_Clocks.HCLK_Frequency / 1000);
	
	
	/* GPIOA Periph clock enable */
		// RCC_AHBPeriphClockCmd(RCC_AHBPeriph_GPIOA, ENABLE);
	RCC->AHBENR |= RCC_AHBENR_GPIOAEN;
	
	// Configure Pin Mode
		// GPIO_InitStructure.GPIO_Mode = GPIO_Mode_OUT;
	GPIOA->MODER |= GPIO_MODER_MODER5_0;		// LED2 is on PA.5; Configured to output
	
	// Configure Pin Type
		// GPIO_InitStructure.GPIO_OType = GPIO_OType_PP;
	GPIOA->OTYPER |= GPIO_OTYPER_OT_5;
	
	// Configure Pin Speed
		// GPIO_InitStructure.GPIO_Speed = GPIO_Speed_40MHz;
	GPIOA->OSPEEDR |= GPIO_OSPEEDER_OSPEEDR5_1;
	
	// Configure Pin Pullup/Pulldown
		// GPIO_InitStructure.GPIO_PuPd = GPIO_PuPd_NOPULL;
	GPIOA->PUPDR &= GPIO_PUPDR_PUPDR5;
	
	
	/*
		Pin Toggle/actual blink goes here
	*/

	while (1)
	{
		GPIOA->ODR |= GPIO_ODR_ODR_5;
		Delay(100);
		GPIOA->ODR &= ~GPIO_ODR_ODR_5;
		Delay(100);
	}
	
}


//-----------------------------------------------------------------------------------------------------------------------------
/* Function Definitions */
//-----------------------------------------------------------------------------------------------------------------------------


static void SetSysClock(void)
{
  __IO uint32_t StartUpCounter = 0, HSEStatus = 0;
  
  /* SYSCLK, HCLK, PCLK2 and PCLK1 configuration ---------------------------*/
  /* Enable HSE */
  RCC->CR |= ((uint32_t)RCC_CR_HSEON);
 
  /* Wait till HSE is ready and if Time out is reached exit */
  do
  {
    HSEStatus = RCC->CR & RCC_CR_HSERDY;
    StartUpCounter++;
  } while((HSEStatus == 0) && (StartUpCounter != HSE_STARTUP_TIMEOUT));

  if ((RCC->CR & RCC_CR_HSERDY) != RESET)
  {
    HSEStatus = (uint32_t)0x01;
  }
  else
  {
    HSEStatus = (uint32_t)0x00;
  }
  
  if (HSEStatus == (uint32_t)0x01)
  {
    /* Enable 64-bit access */
    FLASH->ACR |= FLASH_ACR_ACC64;
    
    /* Enable Prefetch Buffer */
    FLASH->ACR |= FLASH_ACR_PRFTEN;

    /* Flash 1 wait state */
    FLASH->ACR |= FLASH_ACR_LATENCY;
    
    /* Power enable */
    RCC->APB1ENR |= RCC_APB1ENR_PWREN;
  
    /* Select the Voltage Range 1 (1.8 V) */
    PWR->CR = PWR_CR_VOS_0;
  
    /* Wait Until the Voltage Regulator is ready */
    while((PWR->CSR & PWR_CSR_VOSF) != RESET)
    {
    }
        
    /* HCLK = SYSCLK /1*/
    RCC->CFGR |= (uint32_t)RCC_CFGR_HPRE_DIV1;
  
    /* PCLK2 = HCLK /1*/
    RCC->CFGR |= (uint32_t)RCC_CFGR_PPRE2_DIV1;
    
    /* PCLK1 = HCLK /1*/
    RCC->CFGR |= (uint32_t)RCC_CFGR_PPRE1_DIV1;
    
    /*  PLL configuration */
    RCC->CFGR &= (uint32_t)((uint32_t)~(RCC_CFGR_PLLSRC | RCC_CFGR_PLLMUL |
                                        RCC_CFGR_PLLDIV));
    RCC->CFGR |= (uint32_t)(RCC_CFGR_PLLSRC_HSE | RCC_CFGR_PLLMUL12 | RCC_CFGR_PLLDIV3);

    /* Enable PLL */
    RCC->CR |= RCC_CR_PLLON;

    /* Wait till PLL is ready */
    while((RCC->CR & RCC_CR_PLLRDY) == 0)
    {
    }
        
    /* Select PLL as system clock source */
    RCC->CFGR &= (uint32_t)((uint32_t)~(RCC_CFGR_SW));
    RCC->CFGR |= (uint32_t)RCC_CFGR_SW_PLL;

    /* Wait till PLL is used as system clock source */
    while ((RCC->CFGR & (uint32_t)RCC_CFGR_SWS) != (uint32_t)RCC_CFGR_SWS_PLL)
    {
    }
  }
  else
  {
    /* If HSE fails to start-up, the application will have wrong clock
       configuration. User can add here some code to deal with this error */
  }
}

void SystemInit(void){
  RCC->CR |= (uint32_t)0x00000100;

  /*!< Reset SW[1:0], HPRE[3:0], PPRE1[2:0], PPRE2[2:0], MCOSEL[2:0] and MCOPRE[2:0] bits */
	/*!< Set MSION bit */
  RCC->CFGR &= (uint32_t)0x88FFC00C;
  
  /*!< Reset HSION, HSEON, CSSON and PLLON bits */
  RCC->CR &= (uint32_t)0xEEFEFFFE;

  /*!< Reset HSEBYP bit */
  RCC->CR &= (uint32_t)0xFFFBFFFF;

  /*!< Reset PLLSRC, PLLMUL[3:0] and PLLDIV[1:0] bits */
  RCC->CFGR &= (uint32_t)0xFF02FFFF;

  /*!< Disable all interrupts */
  RCC->CIR = 0x00000000;

#ifdef DATA_IN_ExtSRAM
  SystemInit_ExtMemCtl(); 
#endif /* DATA_IN_ExtSRAM */
    
  /* Configure the System clock frequency, AHB/APBx prescalers and Flash settings */
  SetSysClock();

#ifdef VECT_TAB_SRAM
  SCB->VTOR = SRAM_BASE | VECT_TAB_OFFSET; /* Vector Table Relocation in Internal SRAM. */
#else
  SCB->VTOR = FLASH_BASE | VECT_TAB_OFFSET; /* Vector Table Relocation in Internal FLASH. */
#endif
}

void Delay(__IO uint32_t nTime)
{
  TimingDelay = nTime;
  
  while(TimingDelay != 0) TimingDelay_Decrement();
}


void TimingDelay_Decrement(void)
{
  if (TimingDelay != 0x00)
  { 
    TimingDelay--;
  }
}

void SysTick_CLKSourceConfig(uint32_t SysTick_CLKSource)
{
  /* Check the parameters */
  
  if (SysTick_CLKSource == SysTick_CLKSource_HCLK)
  {
    SysTick->CTRL |= SysTick_CLKSource_HCLK;
  }
  else
  {
    SysTick->CTRL &= SysTick_CLKSource_HCLK_Div8;
  }
}

void RCC_GetClocksFreq1(RCC_ClocksTypeDef1* RCC_Clocks)
{
  uint32_t tmp = 0, pllmul = 0, plldiv = 0, pllsource = 0, presc = 0, msirange = 0;

  /* Get SYSCLK source -------------------------------------------------------*/
  tmp = RCC->CFGR & RCC_CFGR_SWS;
  
  switch (tmp)
  {
    case 0x00:  /* MSI used as system clock */
      msirange = (RCC->ICSCR & RCC_ICSCR_MSIRANGE ) >> 13;
      RCC_Clocks->SYSCLK_Frequency = (32768 * (1 << (msirange + 1)));
      break;
    case 0x04:  /* HSI used as system clock */
      RCC_Clocks->SYSCLK_Frequency = HSI_VALUE;
      break;
    case 0x08:  /* HSE used as system clock */
      RCC_Clocks->SYSCLK_Frequency = HSE_VALUE;
      break;
    case 0x0C:  /* PLL used as system clock */
      /* Get PLL clock source and multiplication factor ----------------------*/
      pllmul = RCC->CFGR & RCC_CFGR_PLLMUL;
      plldiv = RCC->CFGR & RCC_CFGR_PLLDIV;
      pllmul = PLLMulTable[(pllmul >> 18)];
      plldiv = (plldiv >> 22) + 1;
      
      pllsource = RCC->CFGR & RCC_CFGR_PLLSRC;

      if (pllsource == 0x00)
      {
        /* HSI oscillator clock selected as PLL clock source */
        RCC_Clocks->SYSCLK_Frequency = (((HSI_VALUE) * pllmul) / plldiv);
      }
      else
      {
        /* HSE selected as PLL clock source */
        RCC_Clocks->SYSCLK_Frequency = (((HSE_VALUE) * pllmul) / plldiv);
      }
      break;
    default: /* MSI used as system clock */
      msirange = (RCC->ICSCR & RCC_ICSCR_MSIRANGE ) >> 13;
      RCC_Clocks->SYSCLK_Frequency = (32768 * (1 << (msirange + 1)));
      break;
  }
  /* Compute HCLK, PCLK1, PCLK2 and ADCCLK clocks frequencies ----------------*/
  /* Get HCLK prescaler */
  tmp = RCC->CFGR & RCC_CFGR_HPRE;
  tmp = tmp >> 4;
  presc = AHBPrescTable[tmp]; 
  /* HCLK clock frequency */
  RCC_Clocks->HCLK_Frequency = RCC_Clocks->SYSCLK_Frequency >> presc;

  /* Get PCLK1 prescaler */
  tmp = RCC->CFGR & RCC_CFGR_PPRE1;
  tmp = tmp >> 8;
  presc = AHBPrescTable[tmp];
  /* PCLK1 clock frequency */
  RCC_Clocks->PCLK1_Frequency = RCC_Clocks->HCLK_Frequency >> presc;

  /* Get PCLK2 prescaler */
  tmp = RCC->CFGR & RCC_CFGR_PPRE2;
  tmp = tmp >> 11;
  presc = AHBPrescTable[tmp];
  /* PCLK2 clock frequency */
  RCC_Clocks->PCLK2_Frequency = RCC_Clocks->HCLK_Frequency >> presc;
}