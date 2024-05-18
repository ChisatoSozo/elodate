pub trait FakeGen<T> {
    fn fake_gen(arg: &T) -> Self;
}
