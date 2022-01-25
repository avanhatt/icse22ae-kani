#[cfg(not(verify))]
use proptest::prelude::*;
#[cfg(verify)]
use propverify::prelude::*;

proptest! {
    #[test]
    fn trait_test(a in 1..2) {
        let _ = &3 as &dyn Send;
    }
}
