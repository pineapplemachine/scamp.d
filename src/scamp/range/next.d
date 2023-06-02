module scamp.range.next;

private:

import scamp.meta.range : isRange;

/++

This module implements a convenience function for getting the
front of a range and then popping it, in a single call.

+/

public:

auto ref next(Range)(ref Range range) if(isRange!Range) {
    auto front = range.front;
    range.popFront();
    return front;
}
