module scamp.range.map;

private:

import scamp.meta.range : isRangeIterable;
import scamp.range.mixins : IterableInheritLengthMixin;
import scamp.range.range: range;

/++

This module implements a standard `map` higher-order function which
operates on ranges.

+/

unittest { /// Example
    import scamp.range.equals : equals;
    int[8] values = [0, 1, 2, 3, 4, 5, 6, 7];
    int[8] squares = [0, 1, 4, 9, 16, 25, 36, 49];
    assert(values.map!(n => n * n).equals(squares));
}

public:

auto map(alias transform, Source)(auto ref Source source) if(isRangeIterable!Source) {
    return MapIterable!(Source, transform)(source);
}

private template MapMixin() {
    mixin IterableInheritLengthMixin;
    
    auto ref opIndex(T)(T item) if(is(typeof((T t) => source[t]))) {
        return transform(this.source[item]);
    }
}

struct MapIterable(Source, alias transform) {
    mixin MapMixin;
    
    Source source;
    
    auto range() {
        return MapRange!(typeof(source.range), transform)(source.range);
    }
    
    auto opSlice() {
        return this.range;
    }
    
    static if(is(typeof((size_t i) => source[i .. i]))) {
        auto opSlice(size_t low, size_t high) {
            auto source_slice = this.source[low .. high];
            return MapIterable!(typeof(source_slice), transform)(source_slice);
        }
    }
    
    static if(is(typeof(source.reverse)) &&
        isRangeIterable!(typeof(() => source.reverse))
    ) {
        auto reverse() {
            return map!transform(source.reverse);
        }
    }
}

struct MapRange(Source, alias transform) {
    mixin MapMixin;
    
    Source source;
    
    auto ref front() {
        return transform(this.source.front);
    }
    
    void popFront() {
        this.source.popFront();
    }
}
