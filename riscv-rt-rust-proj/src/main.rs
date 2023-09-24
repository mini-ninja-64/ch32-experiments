#![no_main]
#![no_std]

use core::panic::PanicInfo;
use ch32v3::ch32v30x;
use riscv::{self as _};
use riscv_rt::entry;

#[panic_handler]
fn panic(_panic: &PanicInfo<'_>) -> ! {
    loop {}
}

#[entry]
fn main() -> ! {
    let peripherals = ch32v30x::Peripherals::take().unwrap();
    
    let rcc = peripherals.RCC;
    rcc.apb2pcenr.write(|w| 
        w.iopcen().set_bit()
    );
    
    let gpioc = peripherals.GPIOC;

    unsafe {
        gpioc
            .cfghr
            .write(|w| 
                w
                    .cnf8().bits(0b00)
                    .mode8().bits(0b11)
            );
    }
    
    gpioc
        .outdr
        .write(|w| w.odr8().set_bit());
    loop { 
        gpioc
            .outdr
            .modify(|r,w| w.odr8().bit(!r.odr8().bit()));
        
        for _ in 0..10000 {
            unsafe { riscv::asm::nop(); }
         }
    }
}
