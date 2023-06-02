module scamp.alloc.block;

private:

/++ Docs

This module implements `AllocatorBlock`, a block allocator.

+/

import core.stdc.stdlib : free, malloc;

public:

struct AllocatorBlock {
    size_t block_count;
    size_t block_size;
    size_t next_offset;
    size_t alloc_count;
    bool buffer_owned;
    void* buffer;
    ubyte* buffer_usage;
    
    @disable this(this);
    
    this(
        size_t block_count,
        size_t block_size,
        bool buffer_owned,
        void* buffer,
        ubyte* buffer_usage,
    ) {
        this.block_count = block_count;
        this.block_size = block_size;
        this.next_offset = 0;
        this.alloc_count = 0;
        this.buffer = buffer;
        this.buffer_usage = buffer_usage;
        this.buffer_owned = buffer_owned;
        assert(this.ok);
    }
    
    this(size_t block_count, size_t block_size) {
        this(
            block_count,
            block_size,
            true,
            malloc(block_count * block_size),
            cast(ubyte*) malloc(block_count),
        );
    }
    
    ~this() {
        this.destroy();
    }
    
    /// Helper to find the pointer to the next unallocated block.
    /// The instance's `next_offset` property will hold the index of
    /// the returned block.
    private void* find_block() {
        for(size_t i = 0; i < this.block_count; i++) {
            if(!this.buffer_usage[this.next_offset]) {
                void* pointer = this.buffer + (
                    this.next_offset * this.block_size
                );
                return pointer;
            }
            this.next_offset = (this.next_offset + 1) % this.block_count;
        }
        return null;
    }
    
    /// Claim the block previously found via `find_block`.
    private void claim_block() {
        this.alloc_count++;
        this.buffer_usage[this.next_offset] = 1;
        this.next_offset = (this.next_offset + 1) % this.block_count;
    }
    
    size_t buffer_size() {
        return this.block_count * this.block_size;
    }
    
    bool ok() {
        return (
            this.buffer !is null &&
            this.buffer_usage !is null &&
            this.next_offset < this.block_count
        );
    }
    
    bool fits(size_t size) {
        return this.ok && (
            size <= this.block_size &&
            this.alloc_count < this.block_count
        );
    }
    
    bool contains(void[] pointer) {
        return this.contains(pointer.ptr);
    }
    
    bool contains(void* pointer) {
        if(this.buffer is null || pointer < this.buffer) {
            return false;
        }
        size_t block_offset = (pointer - this.buffer) / this.block_size;
        return (block_offset < this.block_count && this.buffer_usage[block_offset]);
    }
    
    void reset() {
        this.next_offset = 0;
        this.alloc_count = 0;
        for(size_t i = 0; i < this.block_count; i++) {
            this.buffer_usage[i] = 0;
        }
    }
    
    void destroy() {
        if(this.buffer_owned) {
            if(this.buffer !is null) {
                .free(this.buffer);
            }
            if(this.buffer_usage !is null) {
                .free(this.buffer_usage);
            }
        }
        this.block_count = 0;
        this.next_offset = 0;
        this.alloc_count = 0;
        this.buffer = null;
        this.buffer_usage = null;
        this.buffer_owned = false;
    }
    
    void[] realloc(void[] buffer, size_t size) {
        if(this.buffer is null || buffer.ptr < this.buffer) {
            return null;
        }
        else if(size <= buffer.length) {
            return buffer[0 .. size];
        }
        size_t offset = buffer.ptr - this.buffer;
        size_t block_offset = offset / this.block_size;
        if(block_offset >= this.block_count ||
            !this.buffer_usage[block_offset]
        ) {
            return null;
        }
        size_t pointer_offset = offset % this.block_size;
        if(size + pointer_offset > this.block_size) {
            return null;
        }
        return buffer[0 .. size];
    }
    
    void[] alloc(size_t size) {
        if(!this.fits(size)) {
            return null;
        }
        void* pointer = this.find_block();
        if(pointer is null) {
            this.alloc_count = this.block_count;
            return null;
        }
        this.claim_block();
        return pointer[0 .. size];
    }
    
    void[] alloc_align(size_t size, size_t alignment) {
        if(!this.fits(size)) {
            return null;
        }
        void* pointer = this.find_block();
        if(pointer is null) {
            this.alloc_count = this.block_count;
            return null;
        }
        size_t align_rem = (cast(size_t) pointer) % alignment;
        size_t align_extra = (alignment - align_rem) % alignment;
        if(size + align_extra > this.block_size) {
            return null;
        }
        this.claim_block();
        return (pointer + align_extra)[0 .. size];
    }
    
    void free(void[] buffer) {
        if(this.buffer is null || buffer.ptr < this.buffer) {
            return;
        }
        size_t offset = buffer.ptr - this.buffer;
        if(offset < this.block_count && this.buffer_usage[offset]) {
            assert(this.alloc_count > 0);
            this.buffer_usage[offset] = 0;
            this.alloc_count--;
        }
    }
}
