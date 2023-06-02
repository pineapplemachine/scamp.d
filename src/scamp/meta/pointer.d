module scamp.meta.pointer;

public:

enum bool isPointer(T) = is(T == X*, X);

alias PointerTargetType(T : T*) = T;

unittest {
    interface TestInterface {}
    class TestClass {}
    struct TestStruct {}
    union TestUnion {}
    static assert(isPointer!(int*));
    static assert(isPointer!(void*));
    static assert(isPointer!(TestStruct*));
    static assert(!isPointer!int);
    static assert(!isPointer!size_t);
    static assert(!isPointer!TestInterface);
    static assert(!isPointer!TestClass);
    static assert(!isPointer!TestStruct);
    static assert(!isPointer!TestUnion);
}

unittest {
    static assert(is(PointerTargetType!(int*) == int));
    static assert(is(PointerTargetType!(void*) == void));
}
