module scamp.meta.tuple;

private:

/++ Docs

This module implements an `isTuple` template, for checking whether a
type is a tuple type.

+/

unittest { /// Example
    import scamp.types.tuple : Tuple;
    static assert(isTuple!(Tuple!(int, string)));
    static assert(!isTuple!int);
}

public:

/**
 * Determine whether a type is a tuple type.
 * 
 * To qualify as a tuple, a value must:
 * 1. Have a `length` of type `size_t` that is known at compile-time.
 * 2. When iterating with `foreach(i, item; tuple)`, `i` must be known
 *    at compile-time.
 * 3. Support indexing with compile-time constants.
 * 4. Accessing an out-of-bounds index must produce a compile error.
 */
template isTuple(T) {
    enum bool isTuple = is(typeof({
        enum size_t length = T.init.length;
        foreach(i, _; T.init){
            enum j = i;
            auto x = T.init[i];
        }
        static assert(!is(typeof({
            T[0].init[length];
        })));
    }));
}
