module scamp.range.range.array;

private:

import scamp.meta.array : isArray;

/++ Docs

This module implements an `range` function for arrays and slices.

+/

unittest { /// Example
    int[8] ints = [0, 1, 2, 3, 4, 5, 6, 7];
    auto range = ints.range;
    assert(range.length == ints.length);
    assert(!range.empty);
    assert(range.front == 0);
    range.popFront();
    assert(range.front == 1);
}

public:

auto range(Array)(auto ref Array array) if(isArray!Array) {
    return ArrayRange!Array(array);
}

auto reverse(Array)(auto ref Array array) if(isArray!Array) {
    return ArrayRange!(Array, true)(array);
}

struct ArrayRange(Array, bool isReversed = false) {
    static assert(
        is(Array == typeof([])) || is(typeof({
            size_t x = Array.init.length - size_t(0);
            if(size_t(0) >= Array.init.length) {}
            auto e(size_t i) {return Array.init[i];}
        })),
        "ArrayRange source type must have an integer length, " ~
        "and it must implement `opIndex` accepting a size_t index."
    );
    
    alias opDollar = length;
    enum bool ends = true;
    
    Array array;
    size_t index = 0;
    
    size_t length() {
        return this.array.length - this.index;
    }
    
    bool empty() {
        return this.index >= this.array.length;
    }
    
    auto ref front() {
        static if(is(Array == typeof([]))) {
            assert(false, "Range is empty.");
        }
        else static if(isReversed) {
            return this.array[this.array.length - this.index - 1];
        }
        else {
            return this.array[this.index];
        }
    }
    
    void popFront() nothrow @safe @nogc {
        this.index++;
    }
}

private version(unittest) {
    import scamp.range.next : next;
}

unittest {
    auto a = [].range;
    assert(a.empty);
}

unittest {
    int[4] ints = [0, 2, 4, 3];
    auto a = ints.range;
    assert(a.length == 4);
    assert(a.next == 0);
    assert(a.next == 2);
    assert(a.next == 4);
    assert(a.next == 3);
    assert(a.empty);
}
