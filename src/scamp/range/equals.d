module scamp.range.equals;

private:

import scamp.meta.range : isRangeIterable;
import scamp.range.range : range;

/++

This module implements a range type for iterating numbers from a low
bound to a high bound, incrementing by a step value each time.

+/

unittest { /// Example
    import scamp.range.number : number_range;
    auto numbers = number_range(0, 4);
    int[4] a = [0, 1, 2, 3];
    assert(equals(numbers, a));
    int[4] b = [4, 5, 6, 7];
    assert(!equals(numbers, b));
    int[0] c = [];
    assert(!equals(numbers, c));
}

public:

bool equals(A, B)(A a, B b) if(
    isRangeIterable!A && isRangeIterable!B
) {
    return equals!((a_item, b_item) => (a_item == b_item))(a, b);
}

bool equals(alias compare, A, B)(A a, B b) if(
    isRangeIterable!A && isRangeIterable!B
) {
    auto a_range = a.range;
    auto b_range = b.range;
    static if(is(typeof(a.length != b.length))) {
        if(a.length != b.length) {
            return false;
        }
    }
    static if(is(typeof(a_range.ends)) && is(typeof(b_range.ends))) {
        assert(a_range.ends > 0 || b_range.ends > 0,
            "Cannot compare two ranges that are known to never end."
        );
        if(a_range.ends == 0 || b_range.ends == 0) {
            return false;
        }
    }
    while(!a_range.empty && !b_range.empty) {
        if(!compare(a_range.front, b_range.front)) {
            return false;
        }
        a_range.popFront();
        b_range.popFront();
    }
    return a_range.empty && b_range.empty;
}
