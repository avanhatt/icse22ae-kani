// rmc rmc/simple-trait-pointer.rs
trait Foo {
    fn f(&self)->bool;
}

impl Foo for i32 {
    fn f(&self)->bool {
        true
    }
}

pub fn main() {
    let x = &3 as &dyn Foo;
    assert!(x.f())
}