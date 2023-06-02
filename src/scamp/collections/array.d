module scamp.collections.array;

private:

import core.stdc.stdlib : free, malloc, realloc;

import scamp.range.range.array : range;

/++ Docs

This module implements a `@nogc` array type.
It uses `malloc`, `realloc`, and `free` stdc functions to manage
array memory.

The `Array` type exported by this module can be used more or less
like a normal D array.

+/

unittest { /// Example
    // Initialize an array of ints with an initial buffer capacity of 256 ints.
    // This array will be automatically reallocated to fit more, if needed.
    auto ints = Array!int(256);
    assert(ints.length == 0);
    // Add an item to the array
    ints ~= 1234;
    assert(ints.length == 1);
    assert(ints[0] == 1234);
    foreach(int i; ints) {
        assert(i == 1234);
    }
    // Overwrite the item in the array
    ints[0] = 5678;
    assert(ints[0] == 5678);
    // Remove the item from the array
    assert(ints.pop() == 5678);
    assert(ints.length == 0);
}

/++

The `Array` type implements a `~this` destructor which will free the
memory used by the array, if it owns that memory.

+/

unittest { /// Example
    Array!string* array_ptr;
    {
        // Not ok: Array hasn't been initialized yet
        Array!string array;
        array_ptr = &array;
        assert(!array.ok);
        assert(!array_ptr.ok);
        // Initialize the array
        array = Array!string(256);
        array ~= "foo";
        assert(array[0] == "foo");
        // Array ok!
        assert(array.ok);
        assert(array_ptr.ok);
    }
    // Not ok: Array memory was freed when the scope was exited
    assert(!array_ptr.ok);
}

public:
    
struct Array(T) {
    size_t length;
    size_t buffer_size;
    bool dynamic;
    bool buffer_owned;
    T* buffer;
    
    @disable this(this);
    
    this(size_t length, size_t buffer_size, bool dynamic, bool buffer_owned, T* buffer) {
        this.length = length;
        this.buffer_size = buffer_size;
        this.dynamic = dynamic;
        this.buffer_owned = buffer_owned;
        this.buffer = buffer;
    }
    
    this(size_t buffer_size, bool dynamic = true) {
        T* buffer = cast(T*) malloc(buffer_size * T.sizeof);
        this(0, buffer_size, dynamic, true, buffer);
    }
    
    this(size_t size)(T[size] buffer) {
        this(0, size, false, false, buffer.ptr);
    }
    
    ~this() {
        this.destroy();
    }
    
    bool ok() const nothrow @safe @nogc {
        return this.buffer !is null;
    }
    
    T* ptr() {
        return this.buffer;
    }
    
    size_t opDollar() const nothrow @safe @nogc {
        return this.length;
    }
    
    auto range() {
        return this.opSlice().range;
    }
    
    Array!T copy() {
        Array!T array = Array!T(
            this.dynamic ? this.length : this.buffer_size,
            this.dynamic,
        );
        if(array.ok) {
            array.length = this.length;
            for(size_t i = 0; i < this.length; i++) {
                array.buffer[i] = this.buffer[i];
            }
        }
        return array;
    }
    
    void destroy() {
        if(this.buffer_owned && this.buffer !is null) {
            .free(this.buffer);
        }
        this.buffer_size = 0;
        this.length = 0;
        this.buffer = null;
        this.buffer_owned = false;
    }
    
    void resize(size_t size) {
        assert(this.dynamic && this.buffer_owned);
        this.buffer = cast(T*) realloc(this.buffer, size);
        this.buffer_size = size;
    }
    
    void fit(size_t size) {
        assert(this.dynamic && this.buffer_owned);
        if(size <= this.buffer_size) {
            return;
        }
        size_t new_size = 2 * this.buffer_size;
        assert(new_size > this.buffer_size);
        while(new_size < size) {
            new_size *= 2;
            assert(new_size > this.buffer_size);
        }
        this.resize(new_size);
    }
    
    void push(T value) {
        if(this.dynamic && this.buffer_owned &&
            this.length >= this.buffer_size
        ) {
            size_t new_size = 2 * this.buffer_size;
            assert(new_size > this.buffer_size);
            this.resize(new_size);
        }
        assert(this.length < this.buffer_size);
        this.buffer[this.length++] = value;
    }
    
    void extend(X)(auto ref X values) {
        if(this.dynamic && this.buffer_owned) {
            this.fit(this.length + values.length);
        }
        assert(this.length + values.length <= this.buffer_size);
        for(size_t i = 0; i < values.length; i++) {
            this.buffer[this.length + i] = values[i];
        }
        this.length += values.length;
    }
    
    T pop() {
        assert(this.length > 0);
        return this.buffer[--this.length];
    }
    
    T[] opSlice() {
        return this.buffer[0 .. this.length];
    }
    
    ref T opIndex(size_t index) {
        assert(index >= 0 && index < this.length);
        return this.buffer[index];
    }
    
    void opIndexAssign(T value, size_t index) {
        assert(index >= 0 && index < this.length);
        this.buffer[index] = value;
    }
    
    T[] opSlice(size_t low, size_t high) {
        assert(low >= 0 && low <= high && high <= this.length);
        return this.buffer[low .. high];
    }
    
    void opOpAssign(string op: "~")(T value) {
        this.push(value);
    }
    
    bool opEquals(X)(auto ref X array) {
        if(this.length != array.length) {
            return false;
        }
        for(size_t i = 0; i < this.length; i++) {
            if(this.buffer[i] != array[i]) {
                return false;
            }
        }
        return true;
    }
}

unittest {
    auto ints = Array!int(16);
    for(int i = 0; i < 16; i++) {
        ints.push(i);
    }
    assert(ints.buffer_size == 16);
    assert(ints.length == 16);
    assert(ints[0] == 0);
    assert(ints[$ - 1] == 15);
    size_t value_index = 0;
    foreach(value; ints) {
        assert(value == value_index++);
    }
    assert(ints.pop() == 15);
    assert(ints.length == 15);
    ints[0] = 16;
    assert(ints[0] == 16);
    auto copy = ints.copy();
    copy[0] = 32;
    assert(ints[0] == 16);
    assert(copy[0] == 32);
    auto array = ints[];
    assert(array.length == ints.length);
}

unittest {
    auto array = Array!char(8);
    array.extend("TESTSTR\0");
    assert(array == "TESTSTR\0");
    assert(array[] == "TESTSTR\0");
    assert(array[0] == 'T');
}
