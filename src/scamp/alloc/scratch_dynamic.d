module scamp.alloc.scratch_dynamic;

private:

/++ Docs

This module implements `ScratchAllocatorDynamic`, a scratch allocator
which may grow its buffer if its initial capacity is exceeded.

+/

import core.stdc.stdlib : free, malloc;

import scamp.alloc.scratch : ScratchAllocator;

public:

struct ScratchAllocatorDynamic {
    /// Size of first ScratchAllocator buffer
    size_t buffer_size_initial;
    /// Maximum size for any individual ScratchAllocator buffer
    size_t buffer_size_max;
    /// Number of ScratchAllocator buffers in use
    size_t buffers_size;
    /// Total size of allocations so far
    size_t alloc_count;
    /// Pointer to first ScratchAllocator buffer
    ScratchAllocator* buffers;
    /// Pointer to current ScratchAllocator buffer
    ScratchAllocator* head;
    
    @disable this(this);
    
    this(
        size_t buffer_size_initial,
        size_t buffer_size_max = uint.max,
        size_t buffers_size = 256,
    ) {
        assert(buffer_size_initial > 0);
        assert(buffer_size_max >= buffer_size_initial);
        assert(buffers_size > 0);
        this.buffer_size_initial = buffer_size_initial;
        this.buffer_size_max = buffer_size_max;
        this.buffers_size = buffers_size;
        this.alloc_count = 0;
        this.buffers = cast(ScratchAllocator*) malloc(
            buffers_size * ScratchAllocator.sizeof
        );
        this.head = this.buffers;
        this.head[0] = ScratchAllocator(buffer_size_initial);
    }
    
    ~this() {
        this.destroy();
    }
    
    bool ok() {
        return (
            this.buffers !is null &&
            this.head !is null &&
            this.head - this.buffers < this.buffers_size
        );
    }
    
    bool empty() {
        return this.buffers is null || this.buffers_size == 0;
    }
    
    bool owns(void[] buffer) {
        size_t i_max = this.head - this.buffers;
        for(size_t i = 0; i <= i_max; i++) {
            if(this.buffers[i].owns(buffer)) {
                return true;
            }
        }
        return false;
    }
    
    bool allocated(void[] buffer) {
        size_t i_max = this.head - this.buffers;
        for(size_t i = 0; i <= i_max; i++) {
            if(this.buffers[i].allocated(buffer)) {
                return true;
            }
        }
        return false;
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
    
    private ScratchAllocator* find_allocator(Filter)(
        scope Filter filter, size_t size
    ) {
        size_t size_head = this.head.buffer_size;
        if(filter(this.head, size)) {
            return this.head;
        }
        else if(size > this.buffer_size_max) {
            return null;
        }
        while(1 + this.head - this.buffers < this.buffers_size) {
            this.head++;
            if(this.head.ok) {
                if(filter(this.head, size)) {
                    this.alloc_count += size;
                    return this.head;
                }
                else {
                    size_head = this.head.buffer_size;
                }
            }
            else {
                size_t size_new = (
                    size_head >= this.buffer_size_max / 2 ?
                    this.buffer_size_max :
                    2 * size_head
                );
                while(size_new < size) {
                    size_new = (
                        size_new >= this.buffer_size_max / 2 ?
                        this.buffer_size_max :
                        2 * size_new
                    );
                }
                this.head[0] = ScratchAllocator(size_new);
                if(this.head.ok && filter(this.head, size)) {
                    return this.head;
                }
                else {
                    return null;
                }
            }
        }
        return null;
    }
    
    void[] alloc(size_t size) {
        bool filter(ScratchAllocator* allocator, size_t size) {
            return allocator.fits(size);
        }
        ScratchAllocator* head = this.find_allocator(&filter, size);
        return head is null ? null : head.alloc(size);
    }
    
    void[] alloc_align(size_t size, size_t alignment) {
        bool filter(ScratchAllocator* allocator, size_t size) {
            return allocator.fits_align(size, alignment);
        }
        ScratchAllocator* head = this.find_allocator(&filter, size);
        return head is null ? null : head.alloc_align(size, alignment);
    }
    
    void free(void[] buffer) {
        return;
    }
    
    void reset() {
        for(size_t i = 0; i < this.buffers_size; i++) {
            this.buffers[i].reset();
        }
        this.alloc_count = 0;
        this.head = this.buffers;
    }
    
    void destroy() {
        for(size_t i = 0; i < this.buffers_size; i++) {
            this.buffers[i].destroy();
        }
        if(this.buffers !is null) {
            .free(this.buffers);
        }
        this.buffers_size = 0;
        this.alloc_count = 0;
        this.buffers = null;
        this.head = null;
    }
}
