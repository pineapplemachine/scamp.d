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
    
    /// When freeing a pointer, any pointers that were allocated
    /// after the one being freed are also freed.
    void free(void[] buffer) {
        if(this.owns(buffer)) {
            this.next = buffer.ptr;
        }
    }
}
