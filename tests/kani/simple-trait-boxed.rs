// rmc rmc/simple-trait-boxed.rs
pub fn main() {
    let _ = Box::new(3) as Box<dyn Send>;
}