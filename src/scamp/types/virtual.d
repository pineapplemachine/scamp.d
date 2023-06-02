module scamp.types.virtual;

private:

import scamp.meta.func : FunctionParameterTypes;
import scamp.meta.func : FunctionReturnType;
import scamp.text.write_int : write_int;
import scamp.types.delegate_type : Delegate;

/++ Docs

This module implements a `VirtualStruct` type which uses a vtable
to dispatch methods to a wrapped struct.

+/

unittest { /// Example
    import scamp.meta.aliases : Aliases;
    struct TypeA {
        long i;
        long op(int x, int y) {
            return this.i + x + y;
        }
    }
    struct TypeB {
        long i;
        long op(int x, int y) {
            return this.i + x * y;
        }
    }
    alias TypeVirtual = VirtualStruct!(
        ["op"], Aliases!(long function(int, int)),
    );
    TypeA a = TypeA(10);
    TypeB b = TypeB(20);
    TypeVirtual a_virtual = TypeVirtual.create(&a);
    TypeVirtual b_virtual = TypeVirtual.create(&b);
    assert(a_virtual.op(2, 3) == 15);
    assert(b_virtual.op(2, 3) == 26);
}

public:

private string VirtualStructMixin(string[] Names)() {
    string code = "";
    for(size_t i = 0; i < Names.length; i++) {
        auto i_str = write_int(i);
        code ~= `auto ` ~ Names[i] ~ `(FunctionParameterTypes!(Functions[` ~ i_str[] ~ `]) args) {
            alias DelegateType = Delegate!(
                FunctionReturnType!(Functions[` ~ i_str[] ~ `]),
                FunctionParameterTypes!(Functions[` ~ i_str[] ~ `]),
            );
            return DelegateType.create(this.instance, this.functions[` ~ i_str[] ~ `])(args);
        }`;
    }
    return code;
}

struct VirtualStruct(string[] Names, Functions...) {
    mixin(VirtualStructMixin!Names);
    
    void* instance;
    Functions functions;
    
    static typeof(this) create(T)(T* instance) {
        typeof(this) virtual;
        virtual.instance = instance;
        static foreach(i, name; Names) {
            virtual.functions[i] = mixin(`&T.` ~ name);
        }
        return virtual;
    }
}
