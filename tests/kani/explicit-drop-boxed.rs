// kani-args:--cbmc-args --unwind 2
static mut CELL: i32 = 0;

struct Concrete;

impl Drop for Concrete {
    fn drop(&mut self) {
        unsafe {
            CELL += 1;
        }
    }
}

pub fn main() {
    // Check normal box
    {
        let _x: Box<dyn Send> = Box::new(Concrete {});
    }
    unsafe {
        assert!(CELL == 1);
    }

    // Reset global
    unsafe {
        CELL = 0;
    }

    // Check nested box, still only incremented once
    {
        let x: Box<dyn Send> = Box::new(Concrete {});
        let _nested: Box<dyn Send> = Box::new(x);
    }
    unsafe {
        assert!(CELL == 1);
    }
}
