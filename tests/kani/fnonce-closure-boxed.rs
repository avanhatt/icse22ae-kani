fn takes_dyn_fun(fun: Box<dyn FnOnce() -> i32>) {
    let x = fun();
    assert!(x == 5);
}

pub fn main() {
    let closure = || 5;
    takes_dyn_fun(Box::new(closure))
}
