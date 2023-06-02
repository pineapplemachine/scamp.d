module scamp.text.string_builder;

private:

import scamp.collections.array : Array;

public nothrow @nogc:

alias StringBuilder = StringBuilderTemplate!char;
alias WStringBuilder = StringBuilderTemplate!wchar;
alias DStringBuilder = StringBuilderTemplate!dchar;

struct StringBuilderRange(Char) {
    public nothrow @nogc:
    
    alias String = const(Char)[];
    
    Array!String* parts;
    size_t part_index;
    size_t char_index;
    
    this(Array!String* parts) {
        this.parts = parts;
        this.part_index = 0;
        this.char_index = 0;
        while(this.part_index < this.parts.length &&
            (*this.parts)[this.part_index].length <= 0
        ) {
            this.part_index++;
        }
    }
    
    bool empty() {
        return this.part_index >= this.parts.length;
    }
    
    Char front() {
        return (*this.parts)[this.part_index][this.char_index];
    }
    
    void popFront() {
        this.char_index++;
        while(this.part_index < this.parts.length &&
            this.char_index >= (*this.parts)[this.part_index].length
        ) {
            this.char_index = 0;
            this.part_index++;
        }
    }
}

struct StringBuilderRangeSep(Char) {
    public nothrow @nogc:
    
    alias String = const(Char)[];
    
    Array!String* parts;
    String sep;
    size_t part_index;
    size_t char_index;
    
    this(Array!String* parts, String sep) {
        this.parts = parts;
        this.sep = sep;
        this.part_index = 0;
        this.char_index = 0;
        if(this.sep.length <= 0) {
            while(this.part_index < this.parts.length &&
                (*this.parts)[this.part_index].length <= 0
            ) {
                this.part_index++;
            }
        }
    }
    
    bool empty() {
        return this.part_index >= this.parts.length;
    }
    
    Char front() {
        assert(this.part_index < this.parts.length);
        if(this.char_index < (*this.parts)[this.part_index].length) {
            return (*this.parts)[this.part_index][this.char_index];
        }
        else {
            size_t sep_index = (
                this.char_index -
                (*this.parts)[this.part_index].length
            );
            assert(sep_index < this.sep.length);
            return this.sep[sep_index];
        }
    }
    
    void popFront() {
        this.char_index++;
        size_t part_length = (*this.parts)[this.part_index].length;
        if(this.part_index + 1 < this.parts.length) {
            part_length += this.sep.length;
        }
        if(this.char_index >= part_length) {
            this.char_index = 0;
            this.part_index++;
            if(this.sep.length <= 0) {
                while(this.part_index < this.parts.length &&
                    (*this.parts)[this.part_index].length <= 0
                ) {
                    this.part_index++;
                }
            }
        }
    }
}
    
struct StringBuilderTemplate(Char) {
    public nothrow @nogc:
    
    alias String = const(Char)[];
    
    Array!String parts;
    size_t length;
    
    @disable this(this);
    
    this(size_t size) {
        this.parts = Array!String(size);
        this.length = 0;
    }
    
    ~this() {
        this.parts.destroy();
    }
    
    bool ok() {
        return this.parts.ok;
    }
    
    StringBuilderRange!Char chars() {
        return StringBuilderRange!Char(&this.parts);
    }
    
    StringBuilderRangeSep!Char chars(String sep) {
        return StringBuilderRangeSep!Char(&this.parts, sep);
    }
    
    void append(String str) {
        if(str.length <= 0) {
            return;
        }
        this.parts.push(str);
        this.length += str.length;
    }
    
    void append(typeof(this) builder) {
        this.parts.extend(builder.parts);
        this.length += builder.length;
    }
    
    void append(T)(T buildable) if(is(typeof(buildable.string_builder_append(&this)))) {
        buildable.string_builder_append(&this);
    }
    
    void append(A, B, C...)(A part_a, B part_b, C parts_c) {
        this.append(part_a);
        this.append(part_b);
        foreach(part_c; parts_c) {
            this.append(part_c);
        }
    }
    
    Array!Char join() {
        Array!Char result = Array!Char(this.length, false);
        result.length = this.length;
        bool ok = this.join(result.buffer, result.buffer_size);
        assert(ok);
        return result;
    }
    
    Array!Char join(String sep) {
        size_t result_length = this.join_length(sep);
        Array!Char result = Array!Char(result_length, false);
        result.length = result_length;
        bool ok = this.join(sep, result.buffer, result.buffer_size);
        assert(ok);
        return result;
    }
    
    bool join(Char* buffer, size_t buffer_size) {
        size_t part_offset = 0;
        for(size_t i = 0; i < this.parts.length; i++) {
            for(size_t j = 0; j < this.parts[i].length; j++) {
                if(part_offset + j >= buffer_size) {
                    return false;
                }
                buffer[part_offset + j] = this.parts[i][j];
            }
            part_offset += this.parts[i].length;
        }
        return true;
    }
    
    bool join(String sep, Char* buffer, size_t buffer_size) {
        size_t part_offset = 0;
        for(size_t i = 0; i < this.parts.length; i++) {
            if(i > 0) {
                for(size_t j = 0; j < sep.length; j++) {
                    if(part_offset + j >= buffer_size) {
                        return false;
                    }
                    buffer[part_offset + j] = sep[j];
                }
                part_offset += sep.length;
            }
            for(size_t j = 0; j < this.parts[i].length; j++) {
                if(part_offset + j >= buffer_size) {
                    return false;
                }
                buffer[part_offset + j] = this.parts[i][j];
            }
            part_offset += this.parts[i].length;
        }
        return true;
    }
    
    size_t join_length(String sep) {
        return this.join_length(sep.length);
    }
    
    size_t join_length(size_t sep_length) {
        if(this.parts.length <= 1) {
            return this.length;
        }
        else {
            return this.length + (sep_length * (this.parts.length - 1));
        }
    }
}

unittest {
    StringBuilder sb = StringBuilder(16);
    sb.append("");
    sb.append("hello");
    sb.append(" ", "world", "!");
    auto str = sb.join();
    assert(str == "hello world!");
    assert(sb.length == str.length);
    size_t char_index = 0;
    foreach(ch; sb.chars) {
        assert(ch == str[char_index++]);
    }
    sb.append("");
    assert(sb.join() == "hello world!");
}

unittest {
    import scamp.io.stdio : stdio;
    StringBuilder sb = StringBuilder(16);
    sb.append("abc");
    sb.append("123");
    sb.append("xyz");
    auto str = sb.join(", ");
    assert(str == "abc, 123, xyz");
    size_t char_index = 0;
    foreach(ch; sb.chars(", ")) {
        assert(ch == str[char_index++]);
    }
}
