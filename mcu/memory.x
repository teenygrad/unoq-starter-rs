/* STM32U585 memory layout */
MEMORY
{
    /* Flash: 2 MB */
    FLASH : ORIGIN = 0x08000000, LENGTH = 2048K

    /* SRAM1: 192 KB (primary RAM) */
    RAM : ORIGIN = 0x20000000, LENGTH = 192K
}
