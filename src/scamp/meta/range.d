module scamp.meta.range;

private:

import scamp.range.range : range;

/++ Docs

This module implements range-related templates.

+/

unittest { /// Example
    import scamp.range.repeat.element : repeat_element;
    // repeat_element returns an iterable with a `range` property
    auto bangs = repeat_element(8, '!');
    auto bangs_range = bangs.range;
    // bangs is not iteself a range
    static assert(!isRange!(typeof(bangs)));
    // but bangs_range is
    static assert(isRange!(typeof(bangs_range)));
    // bangs has a `range` property that produces a range
    static assert(isRangeIterable!(typeof(bangs)));
    // ditto bangs_range (the property produces the range itself)
    static assert(isRangeIterable!(typeof(bangs_range)));
    // element type is char
    static assert(!isRangeOf!(char, typeof(bangs)));
    static assert(isRangeOf!(char, typeof(bangs_range)));
    static assert(isRangeIterableOf!(char, typeof(bangs)));
    static assert(isRangeIterableOf!(char, typeof(bangs_range)));
    // check range types
    static assert(is(RangeElementType!(typeof(bangs_range)) == char));
    static assert(is(RangeIterableElementType!(typeof(bangs_range)) == char));
    static assert(is(RangeIterableRangeType!(typeof(bangs)) == typeof(bangs_range)));
}

public:

private void range_test(T)(auto ref T range) {
    if(range.empty) {}
    auto element = range.front;
    range.popFront();
}

private void range_test(Element, T)(auto ref T range) {
    if(range.empty) {}
    Element element = range.front;
    range.popFront();
}

/// Check if a type is a range.
enum bool isRange(T) = __traits(compiles, {
    range_test(*(cast(T*) null));
});

/// Check if a type is a range, and the range has a given element type.
enum bool isRangeOf(Element, T) = __traits(compiles, {
    range_test!Element(*(cast(T*) null));
});

/// Check if a type has a `range` property which produces a range.
enum bool isRangeIterable(T) = __traits(compiles, {
    range_test((*(cast(T*) null)).range);
});

/// Check if a type has a `range` property which produces a range
/// with elements of a given type.
enum bool isRangeIterableOf(Element, T) = __traits(compiles, {
    range_test!Element((*(cast(T*) null)).range);
});

template RangeIterableRangeType(T) {
    static assert(is(typeof(T.init.range)),
        "Cannot get iterable range type."
    );
    alias RangeIterableRangeType = typeof((() => (T.init.range))());
}

template RangeElementType(T) {
    static assert(is(typeof(T.init.front)),
        "Cannot get range element type."
    );
    alias RangeElementType = typeof((() => (T.init.front))());
}

template RangeIterableElementType(T) {
    static assert(is(typeof(T.init.range.front)),
        "Cannot get iterable range element type."
    );
    alias RangeIterableElementType = typeof((() => (T.init.range.front))());
}

unittest {
    struct TestRange {
        enum bool empty = true;
        enum int front = 0;
        void popFront() {}
    }
    struct TestRangeIterable {
        TestRange range() {
            return TestRange.init;
        }
    }
    struct TestRangeIterableSlice {
        TestRange opSlice() {
            return TestRange.init;
        }
    }
    int[] ints_empty;
    auto r0 = TestRange.init.range;
    auto r1 = TestRangeIterable.init.range;
    auto r2 = TestRangeIterableSlice.init.range;
    static assert(isRange!TestRange);
    static assert(isRange!(typeof(r0)));
    static assert(isRange!(typeof(r1)));
    static assert(isRange!(typeof(r2)));
    static assert(isRangeIterable!(typeof(ints_empty)));
    static assert(isRangeIterable!(int[4]));
    static assert(isRangeIterable!TestRange);
    static assert(isRangeIterable!TestRangeIterable);
    static assert(!isRange!TestRangeIterable);
    static assert(isRangeIterable!TestRangeIterableSlice);
    static assert(!isRange!TestRangeIterableSlice);
    static assert(is(RangeIterableRangeType!TestRangeIterable == TestRange));
    static assert(is(RangeIterableElementType!TestRangeIterable == int));
    static assert(is(RangeElementType!TestRange == int));
}
