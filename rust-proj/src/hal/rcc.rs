use ch32v3::ch32v30x::RCC;

pub struct Rcc<'a> {
    rcc: &'a RCC
}

impl Rcc<'_> {
    pub fn APB2(self) {

    }
}

pub trait Constrainable {
    fn constrain(&self) -> Rcc;
}

impl Constrainable for RCC {
    fn constrain(&self) -> Rcc {
        return Rcc{
            rcc: self
        };
    }
}
