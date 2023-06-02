module scamp.range.number;

private:

/++

This module implements a range type for iterating numbers from a low
bound to a high bound, incrementing by a step value each time.

TODO: Actually only an implicit step of 1 is supported so far.

+/

unittest { /// Example
    import scamp.range.next : next;
    auto numbers = number_range(4).range;
    assert(numbers.length == 4);
    assert(numbers.next == 0);
    assert(numbers.next == 1);
    assert(numbers.next == 2);
    assert(numbers.next == 3);
    assert(numbers.empty);
}

public:

auto number_range(T)(T end) {
    return NumberRangeIncrement!T(T(0), end);
}

auto number_range(T)(T start, T end) {
    return NumberRangeIncrement!T(start, end);
}

struct NumberRangeIncrement(T) {
    static assert(
        is(typeof({
            if(T.init >= T.init || T.init == T.init) {}
            T x = T.init;
            x++;
            size_t y = cast(size_t) x;
        })),
        "NumberRangeIncrement number type must support postfix " ~
        "increment, comparison to itself, subtraction from itself, " ~
        "and casting to size_t."
    );
    
    alias opDollar = length;
    alias opSlice = range;
    enum bool ends = true;
    
    T start;
    T end;
    
    auto range() {
        return NumberRangeIncrementRange!T(this.start, this.end);
    }
    
    bool empty() {
        return this.start >= this.end;
    }
    
    size_t length() {
        if(this.end >= this.start) {
            return cast(size_t) (this.end - this.start);
        }
        else {
            return 0;
        }
    }
}

struct NumberRangeIncrementRange(T) {
    T start;
    T end;
    T front;
    
    this(T start, T end) {
        this.start = start;
        this.end = end;
        this.front = start;
    }
    
    bool empty() {
        return this.front >= this.end;
    }
    
    size_t length() {
        if(this.end >= this.front) {
            return cast(size_t) (this.end - this.front);
        }
        else {
            return 0;
        }
    }
    
    void popFront() {
        this.front++;
    }
}
