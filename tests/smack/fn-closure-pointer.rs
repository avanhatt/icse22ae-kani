#[macro_use]
extern crate smack;
use smack::*;

fn takes_dyn_fun(fun: &dyn Fn() -> i32) {
    let x = fun();
    smack::assert!(x == 5);
}

pub fn main() {
    let closure = || 5;
    takes_dyn_fun(&closure)
}
