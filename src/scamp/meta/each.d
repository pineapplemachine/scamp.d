module scamp.meta.each;

public:

/// Check if a type can be iterated using a `foreach` loop.
template isForEachIterable(T) {
    enum isForEachIterable = is(typeof({foreach(item; T.init) {}}));
}

template ForEachElementType(T) {
    static assert(is(typeof({foreach(item; T.init) {}})),
        "Type is not iterable."
    );
    alias ForEachElementType = typeof(
        (() {foreach(item; T.init) return item; assert(false);})()
    );
}

unittest {
    static assert(isForEachIterable!string);
    static assert(isForEachIterable!(int[4]));
    static assert(!isForEachIterable!int);
    static assert(is(ForEachElementType!(int[4]) == int));
}
