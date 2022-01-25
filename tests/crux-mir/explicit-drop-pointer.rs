
#[cfg(crux)] extern crate crucible;
#[cfg(crux)] use crucible::*;


static mut CELL: i32 = 0;

trait T {
    fn t(&self) {}
}

struct Concrete1;

impl T for Concrete1 {}

impl Drop for Concrete1 {
    fn drop(&mut self) {
        unsafe {
            CELL = 1;
        }
    }
}

struct Concrete2;

impl T for Concrete2 {}

impl Drop for Concrete2 {
    fn drop(&mut self) {
        unsafe {
            CELL = 2;
        }
    }
}

#[crux_test]
pub fn main() {
    {
        let _x1: &dyn T = &Concrete1 {};
    }
    unsafe {
        assert!(CELL == 1);
    }
    {
        let _x2: &dyn T = &Concrete2 {};
    }
    unsafe {
        assert!(CELL == 2);
    }
}
