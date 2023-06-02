module scamp.range.repeat.element;

private:

/++ Docs

This module implements a `repeat_element` function which can be used
to get a range whose contents are a given element repeated either
endlessly or a given number of times.

+/

unittest { /// Example
    import scamp.range.equals : equals;
    auto bangs = repeat_element(8, '!');
    assert(bangs.length == 8);
    assert(bangs.equals("!!!!!!!!"));
}

unittest { /// Example
    import scamp.range.next : next;
    auto ones = repeat_element(1);
    assert(!ones.ends);
    assert(ones.next == 1);
    assert(ones.next == 1);
    assert(ones.next == 1);
    assert(ones.next == 1);
    // etc...
}

public:

auto repeat_element(T)(T element) {
    return RepeatElementEndlessRange!T(element);
}

auto repeat_element(T)(size_t length, T element) {
    return RepeatElementIterable!T(length, element);
}

struct RepeatElementEndlessRange(T) {
    enum bool empty = false;
    enum bool ends = false;
    
    T front;
    
    void popFront() pure nothrow @safe @nogc {}
}

struct RepeatElementIterable(T) {
    alias opDollar = length;
    alias opSlice = range;
    enum bool ends = true;
    
    size_t length;
    T front;
    
    bool empty() pure const nothrow @safe @nogc {
        return this.length > 0;
    }
    
    auto range() {
        return RepeatElementRange!T(this.length, this.front);
    }
}

struct RepeatElementRange(T) {
    alias opDollar = length;
    enum bool ends = true;
    
    size_t index_end;
    size_t index;
    T front;
    
    this(size_t length, T front) {
        this.index_end = length;
        this.index = 0;
        this.front = front;
    }
    
    size_t length() pure const nothrow @safe @nogc {
        return this.index_end - this.index;
    }
    
    bool empty() pure const nothrow @safe @nogc {
        return this.index >= this.index_end;
    }
    
    void popFront() nothrow @safe @nogc {
        this.index++;
    }
}
