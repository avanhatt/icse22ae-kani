pub fn main() {
    let _ = Box::new(3) as Box<dyn Send>;
}