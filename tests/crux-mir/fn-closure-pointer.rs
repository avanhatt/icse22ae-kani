#[cfg(crux)] extern crate crucible;
#[cfg(crux)] use crucible::*;

fn takes_dyn_fun(fun: &dyn Fn() -> i32) {
    let x = fun();
    assert!(x == 5);
}

#[crux_test]
pub fn main() {
    let closure = || 5;
    takes_dyn_fun(&closure)
}
