module scamp.alloc;

private:

/++ Docs

Modules in this package implement memory allocators.

All allocators implement these methods:

```
bool ok()
void[] alloc(size_t size)
void[] realloc(void[] buffer, size_t size)
void free(void[] buffer)
void reset()
```

They may also commonly implement these methods:

```
void[] alloc_align(size_t size, size_t alignment)
void[] realloc_align(void[] buffer, size_t size, size_t alignment)
bool owns(void[] buffer)
bool allocated(void[] buffer)
```

The `ok` method returns `true` when an allocator has been initialized
and has any memory available to it to allocate, and `false` otherwise.

+/

unittest { /// Example
    import scamp.alloc.scratch : ScratchAllocator;
    ScratchAllocator* allocator_ptr;
    {
        // Not ok: Allocator hasn't been initialized yet
        ScratchAllocator allocator;
        allocator_ptr = &allocator;
        assert(!allocator.ok);
        assert(!allocator_ptr.ok);
        // Initialize it!
        allocator = ScratchAllocator(256);
        // Allocator ok
        assert(allocator.ok);
        assert(allocator_ptr.ok);
    }
    // Not ok: Allocator was destroyed when it went out of scope
    assert(!allocator_ptr.ok);
}

/++

The `alloc` method can be used to reserve memory with the
allocator. It returns a `void[]` slice representing the
allocated memory.

The method returns `null` if allocation failed for any reason.

+/

unittest { /// Example
    import scamp.alloc.scratch : ScratchAllocator;
    // Initialize a scratch allocator with 256 bytes
    auto allocator = ScratchAllocator(256);
    assert(allocator.ok);
    // Allocating 512 bytes fails
    assert(allocator.alloc(512) is null);
    // Allocating 128 bytes twice succeeds
    void[] buffer_a = allocator.alloc(128);
    void[] buffer_b = allocator.alloc(128);
    assert(buffer_a !is null && buffer_a.length == 128);
    assert(buffer_b !is null && buffer_b.length == 128);
    assert(buffer_a.ptr !is buffer_b.ptr);
    // Allocating 128 bytes a third time fails
    assert(allocator.alloc(128) is null);
}

/++

The `alloc_align` method can be used similarly to `alloc`.
The pointer to the beginning of the allocated memory will
be aligned on the specified byte boundary.

The method returns `null` if allocation failed for any reason.

+/

unittest { /// Example
    import scamp.alloc.scratch : ScratchAllocator;
    auto allocator = ScratchAllocator(256);
    assert(allocator.ok);
    // Allocate 64 bytes aligned on a 16-byte boundary
    void[] buffer_a = allocator.alloc_align(64, 16);
    assert(buffer_a !is null && buffer_a.length == 64);
    assert((cast(size_t) buffer_a.ptr) % 16 == 0);
    // Allocate 64 bytes aligned on a 128-byte boundary
    void[] buffer_b = allocator.alloc_align(64, 128);
    assert(buffer_b !is null && buffer_b.length == 64);
    assert((cast(size_t) buffer_b.ptr) % 128 == 0);
}
    
import core.stdc.stdlib : free, malloc, realloc;

public nothrow:

static assert(void.sizeof == 1);

import scamp.alloc.block;
import scamp.alloc.block_typed;
import scamp.alloc.scratch;
import scamp.alloc.scratch_dynamic;
import scamp.alloc.stack;
