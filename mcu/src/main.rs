#![no_std]
#![no_main]

use cortex_m_rt::entry;
use cortex_m_semihosting::hprintln;
use panic_halt as _;

#[entry]
fn main() -> ! {
    hprintln!("Hello from STM32U585 MCU (Arm Cortex-M33)!");

    let mut count: u32 = 0;
    loop {
        count += 1;
        hprintln!("tick {}", count);

        // ~1 second delay at default clock speed (4 MHz MSI)
        cortex_m::asm::delay(4_000_000);
    }
}
