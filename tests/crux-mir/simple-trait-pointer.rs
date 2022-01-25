#[cfg(crux)] extern crate crucible;
#[cfg(crux)] use crucible::*;

trait Foo {
    fn f(&self)->bool;
}

impl Foo for i32 {
    fn f(&self)->bool {
        true
    }
}

#[crux_test]
pub fn main() {
    let x = &3 as &dyn Foo;
    assert!(x.f())
}