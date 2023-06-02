module scamp.alloc.stack;

private:

/++ Docs

This module implements `StackAllocator`, a stack allocator.

+/

import core.stdc.stdlib : free, malloc;

import scamp.alloc.scratch : ScratchAllocator;

public:

struct StackAllocator {
    ScratchAllocator scratch;
    alias scratch this;
    
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
    
    /// When freeing a pointer, any pointers that were allocated
    /// after the one being freed are also freed.
    void free(void[] buffer) {
        if(this.owns(buffer)) {
            this.next = buffer.ptr;
        }
    }
}
