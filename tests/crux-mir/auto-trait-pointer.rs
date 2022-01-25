// cabal v2-exec -- crux-mir 
#[cfg(crux)] extern crate crucible;
#[cfg(crux)] use crucible::*;

#[crux_test]
pub fn main() {
    let _ = &3 as &dyn Send;
}