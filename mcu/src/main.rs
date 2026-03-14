#![no_std]
#![no_main]

use cortex_m_rt::entry;
use defmt_rtt as _;
use panic_probe as _;

#[entry]
fn main() -> ! {
    defmt::info!("Hello from STM32U585 MCU (Arm Cortex-M33)!");

    loop {
        for _ in 0..1_000_000 {
            cortex_m::asm::nop();
        }
        defmt::info!("Hello from STM32U585 MCU (Arm Cortex-M33)!");
    }
}
