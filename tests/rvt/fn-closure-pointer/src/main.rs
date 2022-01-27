#[cfg(not(verify))]
use proptest::prelude::*;
#[cfg(verify)]
use propverify::prelude::*;

fn takes_dyn_fun(fun: &dyn Fn() -> i32) {
    let x = fun();
    assert!(x == 5);
}


proptest! {
    #[test]
    fn test_trait(a in 1..2) {
        let closure = || 5;
        takes_dyn_fun(&closure)
    }
}
