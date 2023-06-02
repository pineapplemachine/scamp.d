module scamp.range.range.range;

private:

import scamp.meta.range : isRange;

/++ Docs

This module implements `range` function for things that are
already ranges. The function returns the range itself.

+/

public:

auto range(Range)(auto ref Range range) if(isRange!Range) {
    return range;
}

auto range(Range)(auto ref Range range) if(
    is(typeof(range[])) && isRange!(typeof(range[])) && !isRange!Range
) {
    return range[];
}
