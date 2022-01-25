#[cfg(crux)] extern crate crucible;
#[cfg(crux)] use crucible::*;

#[crux_test]
pub fn main() {
    let _ = Box::new(3) as Box<dyn Send>;
}