module scamp.alloc.malloc;

private:

/++ Docs

This module implements `MallocAllocator`, an allocator which relies
on `malloc`, `realloc`, and `free` from stdlib.

+/
    
import core.stdc.stdlib : free, malloc, realloc;

public:

struct MallocAllocator {
    enum bool ok = true;
    
    void[] realloc(void[] buffer, size_t size) {
        void* pointer = .realloc(buffer.ptr, size);
        return pointer is null ? null : pointer[0 .. size];
    }
    
    void[] alloc(size_t size) {
        void* pointer = .malloc(size);
        return pointer is null ? null : pointer[0 .. size];
    }
    
    void free(void[] buffer) {
        .free(buffer.ptr);
    }
}
