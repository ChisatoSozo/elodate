use serde::Deserialize;

pub trait Gen<'a, T>: Deserialize<'a> {
    fn gen(arg: &T) -> Self;
}
