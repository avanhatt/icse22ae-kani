#[cfg(crux)] extern crate crucible;
#[cfg(crux)] use crucible::*;

trait Foo<T> {
    fn method(&self, t: T) -> T;
}

trait Bar: Foo<u32> + Foo<i32> {}

impl<T> Foo<T> for () {
    fn method(&self, t: T) -> T {
        t
    }
}

impl Bar for () {}

#[crux_test]
pub fn main() {
    let b: &dyn Bar = &();
    // The vtable for b will now have two Foo::method entries,
    // one for Foo<u32> and one for Foo<i32>.
    let result = <dyn Bar as Foo<u32>>::method(b, 22_u32);
    assert!(result == 22_u32);
}
