#[macro_use]
extern crate smack;
use smack::*;

pub fn main() {
    let _ = &3 as &dyn Send;
}