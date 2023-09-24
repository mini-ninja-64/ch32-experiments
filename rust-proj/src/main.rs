#![no_main]
#![no_std]

use core::panic::PanicInfo;
use core::arch::global_asm;
use ch32v3::ch32v30x::{self, RCC};

mod hal;

use hal::rcc::Constrainable;

global_asm!(include_str!("../bootstrap.S"));

#[panic_handler]
fn panic(_panic: &PanicInfo<'_>) -> ! {
    loop {}
}

#[no_mangle]
pub extern "C" fn entry_point() -> ! {
    // TODO: Skip proper taking of peripherals for now as the default riscv impl requires 
    //       running in machine mode to disable interrupts by modifying mstatus, we could
    //       utilise WCH's gintenr register to modify MIE and MPIE in user mode
    let peripherals = unsafe { ch32v30x::Peripherals::steal() };
    
    let rcc = peripherals.RCC;
    // Activate HSE
    rcc.ctlr.write(|w|
        w.hseon().set_bit()
    );

    // TODO: BLOCK UNTIL READY & ERROR CHECK

    // Using an 8MHz HSE
    rcc.cfgr0.write(|w| unsafe { 
        w
            // Set APB1 clock to be divided by 2
            .ppre1().bits(0b100)
            // Set APB2 clock to not be divided
            .ppre2().bits(0)
            // Set PREDIV1SRC to HSE
            .hpre().bits(0)
            // Set PLL as systemclk source
            .sw().bits(0b10)
            // Set PLL Multiplier to 18
            .pllmul().bits(0b1111)
            // Set PLL division to 1
            .pllxtpre().clear_bit()
            // Set PLL source to HSE
            .pllsrc().set_bit()
    });

    rcc.ctlr.write(|w|
        w.pllon().set_bit()
    );

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
