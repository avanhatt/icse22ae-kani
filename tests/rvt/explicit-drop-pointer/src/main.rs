#[cfg(not(verify))]
use proptest::prelude::*;
#[cfg(verify)]
use propverify::prelude::*;

use std::any::Any;


pub fn downcast_to_concrete(a: &dyn Any) {
    match a.downcast_ref::<i32>() {
        Some(i) => {
            assert!(*i == 7);
        }
        None => {
            assert!(false);
        }
    }
}

pub fn downcast_to_fewer_traits(s: &(dyn Any + Send)) {
    let c = s as &dyn Any;
    downcast_to_concrete(c);
}

proptest! {
    #[test]
    fn multiply(a in 1..=2, b in 1..=2) {
        let i: i32 = 7;
        downcast_to_fewer_traits(&i);
    }
}
