#[cfg(not(verify))]
use proptest::prelude::*;
#[cfg(verify)]
use propverify::prelude::*;

trait Foo {
    fn f(&self)->bool;
}

impl Foo for i32 {
    fn f(&self)->bool {
        true
    }
}

proptest! {
    #[test]
    fn test_trait(a in 1..2) {
        let x = &3 as &dyn Foo;
        assert!(x.f())
    }
}
