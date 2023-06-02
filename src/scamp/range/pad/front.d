module scamp.range.pad.front;

private:

import scamp.meta.range : RangeIterableElementType;
import scamp.range.range : range;

unittest { /// Example
    import scamp.range.equals : equals;
    import scamp.text.write_int : write_int;
    assert(write_int(123).pad_front(6, '0').equals("000123"));
    assert(write_int(123123).pad_front(6, '0').equals("123123"));
    assert(write_int(1234567).pad_front(6, '0').equals("1234567"));
}

public:

auto pad_front(Source, Element)(
    auto ref Source source,
    size_t length,
    auto ref Element element,
) {
    size_t add_length = source.length < length ? length - source.length : 0;
    return PadFrontIterable!(Source)(source, add_length, element);
}

auto pad_add_front(Source, Element)(
    auto ref Source source,
    size_t add_length,
    auto ref Element element,
) {
    return PadFrontIterable!(Source)(source, add_length, element);
}

struct PadFrontIterable(Source) {
    alias Element = RangeIterableElementType!Source;
    
    Source source;
    size_t pad_front_length;
    Element pad_front_element;
    
    static if(is(typeof(source.empty))) {
        bool empty() {
            return this.pad_front_length == 0 && this.source.empty;
        }
    }
    else static if(is(typeof({if(source.length <= 0) {}}))) {
        bool empty() {
            return this.pad_front_length == 0 && this.source.length <= 0;
        }
    }
    
    static if(is(typeof({size_t i = cast(size_t) source.length;}))) {
        alias opDollar = length;
        size_t length() {
            return this.pad_front_length + cast(size_t) this.source.length;
        }
    }
    
    static if(is(typeof((size_t i) => source[i]))) {
        auto ref opIndex(size_t index) {
            if(index < this.pad_front_length) {
                return this.pad_front_element;
            }
            else {
                return this.source[index - this.pad_front_length];
            }
        }
    }
    
    static if(is(typeof((size_t i) => source[i .. i]))) {
        auto ref opSlice(size_t low, size_t high) {
            assert(low <= high);
            size_t source_low = void;
            size_t source_high = void;
            size_t pad_low = void;
            size_t pad_high = void;
            if(low >= this.pad_front_length) {
                source_low = low - this.pad_front_length;
                pad_low = this.pad_front_length;
            }
            else {
                source_low = 0;
                pad_low = low;
            }
            if(high >= this.pad_front_length) {
                source_high = high - this.pad_front_length;
                pad_high = this.pad_front_length;
            }
            else {
                source_high = 0;
                pad_high = high;
            }
            assert(source_low <= source_high);
            assert(pad_low <= pad_high);
            return pad_add_front(
                this.source[source_low .. source_high],
                pad_high - pad_low,
                this.pad_front_element,
            );
        }
    }
    
    auto range() {
        return PadFrontRange!(typeof((() => this.source.range)()))(
            this.source.range,
            this.pad_front_length,
            this.pad_front_element,
        );
    }
    
    auto opSlice() {
        return this.range;
    }
}

struct PadFrontRange(Source) {
    alias Element = RangeIterableElementType!Source;
    
    Source source;
    size_t pad_front_length;
    size_t pad_front_index;
    Element pad_front_element;
    
    this(
        Source source,
        size_t pad_front_length,
        Element pad_front_element,
    ) {
        this.source = source;
        this.pad_front_length = pad_front_length;
        this.pad_front_index = 0;
        this.pad_front_element = pad_front_element;
    }
    
    bool empty() {
        if(this.pad_front_index < this.pad_front_length) {
            return false;
        }
        else {
            return this.source.empty;
        }
    }
    
    auto ref front() {
        if(this.pad_front_index < this.pad_front_length) {
            return this.pad_front_element;
        }
        else {
            return this.source.front;
        }
    }
    
    void popFront() {
        if(this.pad_front_index < this.pad_front_length) {
            this.pad_front_index++;
        }
        else {
            this.source.popFront();
        }
    }
}

version(unittest) {
    private import scamp.range.equals : equals;
}

unittest {
    auto str = "10".pad_front(8, '_');
    assert(!str.empty);
    assert(str.length == 8);
    assert(str[0] == '_');
    assert(str[$ - 1] == '0');
    assert(str[$ - 2] == '1');
    size_t i = 0;
    foreach(ch; str) {
        assert(ch == "______10"[i++]);
    }
    assert(str[0 .. 4].equals("____"));
    assert(str[4 .. 8].equals("__10"));
}
