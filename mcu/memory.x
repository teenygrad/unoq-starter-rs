/* STM32U585 memory layout */
MEMORY
{
    /* Flash: 2 MB */
    FLASH : ORIGIN = 0x08000000, LENGTH = 2M

    /* SRAM1 (192KB) + SRAM2 (64KB) + SRAM3 (512KB) = 768KB contiguous
       Note: SRAM4 (16KB) is at 0x28000000 and is NOT contiguous */
    RAM : ORIGIN = 0x20000000, LENGTH = 768K
}
