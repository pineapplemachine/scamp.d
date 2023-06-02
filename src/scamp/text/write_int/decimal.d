module scamp.text.write_int.decimal;

private:

import scamp.range.range.array : range;

/++ Docs

The `write_int` function returns a struct containing the serialized
integer string in a static array buffer.
The struct itself behaves more or less like a `char[]` array.

+/

unittest { /// Example
    import scamp.range.equals : equals;
    assert(write_int(0) == "0");
    assert(write_int(1234) == "1234");
    assert(write_int(-25) == "-25");
}

public nothrow @safe @nogc:

alias IntWriter = DecimalIntWriter;

auto write_int(T)(T number) {
    return DecimalIntWriter!T(number);
}

struct DecimalIntWriter(T) {
    public nothrow @safe @nogc:
    
    alias opDollar = length;
    
    static if(T.sizeof <= 1) enum BufferSize = 4;
    else static if(T.sizeof <= 2) enum BufferSize = 8;
    else static if(T.sizeof <= 4) enum BufferSize = 16;
    else static if(T.sizeof <= 8) enum BufferSize = 32;
    else enum BufferSize = 256;
    
    char[BufferSize] buffer;
    size_t length;
    
    this(T number) {
        this.length = 0;
        T n = number;
        // Serialize a positive number from last to first character
        if(number > 0) {
            while(n > 0) {
                assert(this.length < this.buffer.length);
                this.buffer[this.length++] = cast(char) ('0' + n % 10);
                n /= 10;
            }
        }
        // Serialize a negative number from last to first character
        else if(number < 0) {
            while(n < 0) {
                assert(this.length < this.buffer.length);
                this.buffer[this.length++] = cast(char) ('0' - n % 10);
                n /= 10;
            }
            assert(this.length < this.buffer.length);
            this.buffer[this.length++] = '-';
        }
        // Serialize zero
        else {
            this.buffer[0] = '0';
            this.length = 1;
            return;
        }
        // Reverse characters
        size_t half_length = this.length / 2;
        for(size_t i = 0; i < half_length; i++) {
            size_t j = this.length - i - 1;
            char t = this.buffer[i];
            this.buffer[i] = this.buffer[j];
            this.buffer[j] = t;
        }
    }
    
    bool empty() const {
        return this.length == 0;
    }
    
    auto opSlice() {
        return this.buffer[0 .. this.length];
    }
    
    auto range() {
        return this.buffer[0 .. this.length].range;
    }
    
    char opIndex(size_t index) const {
        assert(index >= 0 && index < this.length);
        return this.buffer[index];
    }
    
    char[] opSlice(size_t low, size_t high) {
        assert(low >= 0 && low <= high && high <= this.length);
        return this.buffer[low .. high];
    }
    
    bool opEquals(Iter)(auto ref Iter iter) {
        static if(is(typeof({iter.length != this.length;}))) {
            if(iter.length != this.length) {
                return false;
            }
        }
        size_t i = 0;
        foreach(ch; iter) {
            if(i >= this.length || ch != this.buffer[i++]) {
                return false;
            }
        }
        return i == this.length;
    }
}
