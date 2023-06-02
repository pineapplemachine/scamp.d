module scamp.alloc.scratch;

private:

/++ Docs

This module implements `ScratchAllocator`, a scratch allocator.

+/
    
import core.stdc.stdlib : free, malloc;

public:

struct ScratchAllocator {
    /// Length of buffer
    size_t buffer_size;
    /// Whether this allocator is responsible for freeing its buffer
    bool buffer_owned;
    /// Pointer to start of buffer
    void* buffer;
    /// Pointer to next available portion of the buffer
    void* next;
    
    @disable this(this);
    
    this(size_t buffer_size, bool buffer_owned, void* buffer) {
        this.buffer_size = buffer_size;
        this.buffer = buffer;
        this.next = this.buffer;
        this.buffer_owned = buffer_owned;
        assert(this.ok);
    }
    
    this(size_t buffer_size) {
        this(buffer_size, true, malloc(buffer_size));
    }
    
    this(T, size_t size)(T[size] buffer) {
        this(size * T.sizeof, false, buffer.ptr);
    }
    
    ~this() {
        this.destroy();
    }
    
    bool ok() {
        return (
            this.buffer !is null &&
            this.next !is null &&
            this.buffer_size > 0
        );
    }
    
    bool empty() {
        return !this.ok;
    }
    
    bool fits(size_t size) {
        return (
            this.buffer !is null &&
            this.next !is null &&
            this.buffer_size - (this.next - this.buffer) >= size
        );
    }
    
    bool fits_align(size_t size, size_t alignment) {
        size_t align_rem = (cast(size_t) this.next) % alignment;
        size_t align_extra = (alignment - align_rem) % alignment;
        return this.fits(size + align_extra);
    }
    
    bool owns(void[] buffer) {
        return (
            this.buffer !is null &&
            buffer.ptr >= this.buffer &&
            buffer.ptr + buffer.length <= this.buffer + this.buffer_size
        );
    }
    
    bool allocated(void[] buffer) {
        return (
            this.buffer !is null &&
            this.next !is null &&
            buffer.ptr >= this.buffer &&
            buffer.ptr + buffer.length <= this.next
        );
    }
    
    void reset() {
        this.next = this.buffer;
    }
    
    void destroy() {
        if(this.buffer_owned && this.buffer !is null) {
            .free(this.buffer);
        }
        this.buffer_size = 0;
        this.buffer = null;
        this.next = null;
        this.buffer_owned = false;
    }
    
    void[] realloc(void[] buffer, size_t size) {
        if(size <= buffer.length) {
            return buffer[0 .. size];
        }
        void[] new_buffer = this.alloc(size);
        if(new_buffer is null) {
            return null;
        }
        assert(size >= buffer.length);
        for(size_t i = 0; i < buffer.length; i++) {
            (cast(ubyte*) new_buffer)[i] = (cast(ubyte*) buffer)[i];
        }
        return new_buffer;
    }
    
    void[] realloc_align(void[] buffer, size_t size, size_t alignment) {
        if(size <= buffer.length && (cast(size_t) buffer.ptr % alignment) == 0) {
            return buffer[0 .. size];
        }
        void[] new_buffer = this.alloc_align(size, alignment);
        if(new_buffer is null) {
            return null;
        }
        assert(size >= buffer.length);
        for(size_t i = 0; i < buffer.length; i++) {
            (cast(ubyte*) new_buffer)[i] = (cast(ubyte*) buffer)[i];
        }
        return new_buffer;
    }
    
    void[] alloc(size_t size) {
        if(!this.fits(size)) {
            return null;
        }
        void* pointer = this.next;
        this.next += size;
        return pointer[0 .. size];
    }
    
    void[] alloc_align(size_t size, size_t alignment) {
        size_t align_rem = (cast(size_t) this.next) % alignment;
        size_t align_extra = (alignment - align_rem) % alignment;
        void[] buffer = this.alloc(size + align_extra);
        return buffer is null ? null : (buffer.ptr + align_extra)[0 .. size];
    }
    
    size_t alloc_count() {
        if(this.buffer !is null && this.next !is null) {
            return this.next - this.buffer;
        }
        else {
            return 0;
        }
    }
    
    void free(void[] buffer) {
        return;
    }
}
