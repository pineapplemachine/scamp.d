module scamp.types.tuple;

private:

/++ Docs

This module defines a tuple type.

https://dlang.org/tuple.html

+/

unittest { /// Example
    Tuple!(int, string) tup = tuple(16, "hello");
    assert(tup.length == 2);
    assert(tup[0] == 16);
    assert(tup[1] == "hello");
    assert(tup == tuple(16, "hello"));
    assert(tup[0 .. 1] == tuple(16));
    void test_fn(int i, string str) {}
    test_fn(tup.values);
}

public:

/// Construct a tuple from the given values.
auto tuple(T...)(auto ref T values) {
    return Tuple!T(values);
}

/// Tuple type.
struct Tuple(T...) {
    T values;
    alias values this;
    
    this(T values) {
        this.values = values;
    }
}
