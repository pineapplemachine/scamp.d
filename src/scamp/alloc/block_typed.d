module scamp.alloc.block_typed;

private:
    
import core.stdc.stdlib : free, malloc;

public:

struct AllocatorBlockTypedRange(T) {
    AllocatorBlockTyped!T* allocator;
    size_t index;
    
    @disable this(this);
    
    this(AllocatorBlockTyped!T* allocator) {
        this.allocator = allocator;
        this.index = 0;
        while(this.index < this.allocator.block_count &&
            !this.allocator.buffer_alloc[this.index]
        ) {
            this.index++;
        }
    }
    
    bool empty() {
        return this.index >= this.allocator.block_count;
    }
    
    ref T front() {
        assert(this.index < this.allocator.block_count);
        assert(this.allocator.buffer_alloc[this.index]);
        return this.allocator.buffer[index];
    }
    
    void popFront() {
        this.index++;
        while(this.index < this.allocator.block_count &&
            !this.allocator.buffer_alloc[this.index]
        ) {
            this.index++;
        }
    }
}

struct AllocatorBlockTyped(T) {
    public nothrow @nogc:
    
    enum size_t block_size = T.sizeof;
    
    size_t block_count;
    size_t next_offset;
    size_t alloc_count;
    bool buffer_owned;
    T* buffer;
    ubyte* buffer_alloc;
    
    this(
        size_t block_count,
        bool buffer_owned,
        T* buffer,
        ubyte* buffer_alloc,
    ) {
        this.block_count = block_count;
        this.next_offset = 0;
        this.alloc_count = 0;
        this.buffer = buffer;
        this.buffer_alloc = buffer_alloc;
        this.buffer_owned = buffer_owned;
        assert(this.ok);
    }
    
    this(size_t block_count) {
        this(
            block_count,
            true,
            cast(T*) malloc(block_count * block_size),
            cast(ubyte*) malloc(block_count),
        );
    }
    
    ~this() {
        this.destroy();
    }
    
    size_t buffer_size() {
        return this.block_count * this.block_size;
    }
    
    bool ok() {
        return (
            this.buffer !is null &&
            this.buffer_alloc !is null &&
            this.next_offset < this.block_count
        );
    }
    
    AllocatorBlockTypedRange!T values() {
        return AllocatorBlockTypedRange!T(&this);
    }
    
    bool contains(T* pointer) {
        if(this.buffer is null || pointer < this.buffer) {
            return false;
        }
        size_t offset = pointer - this.buffer;
        return (offset < this.block_count && this.buffer_alloc[offset]);
    }
    
    void reset() {
        this.next_offset = 0;
        this.alloc_count = 0;
    }
    
    void destroy() {
        if(this.buffer_owned) {
            if(this.buffer !is null) {
                .free(this.buffer);
            }
            if(this.buffer_alloc !is null) {
                .free(this.buffer_alloc);
            }
        }
        this.block_count = 0;
        this.next_offset = 0;
        this.alloc_count = 0;
        this.buffer = null;
        this.buffer_alloc = null;
        this.buffer_owned = false;
    }
    
    void* alloc(size_t size) {
        if(!this.ok || this.alloc_count >= this.block_count) {
            return null;
        }
        for(size_t i = 0; i < this.block_count; i++) {
            if(!this.buffer_alloc[this.next_offset]) {
                void* pointer = this.buffer + this.next_offset;
                this.buffer_alloc[this.next_offset] = 1;
                this.next_offset = (this.next_offset + 1) % this.block_count;
                this.alloc_count++;
                return pointer;
            }
            this.next_offset = (this.next_offset + 1) % this.block_count;
        }
        this.alloc_count = this.block_count;
        return null;
    }
    
    void free(T* pointer) {
        if(this.buffer is null || pointer < this.buffer) {
            return;
        }
        size_t offset = pointer - this.buffer;
        if(offset < this.block_count && this.buffer_alloc[offset]) {
            assert(this.alloc_count > 0);
            .destroy(this.buffer[offset]);
            this.buffer_alloc[offset] = 0;
            this.alloc_count--;
        }
    }
}
