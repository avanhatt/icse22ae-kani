#[macro_use]
extern crate smack;
use smack::*;

pub fn main() {
    let _ = Box::new(3) as Box<dyn Send>;
}