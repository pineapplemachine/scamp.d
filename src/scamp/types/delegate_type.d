module scamp.types.delegate_type;

private:

/++ Docs

This module defines a type that may be used to synthesize a
delegate function, with a `this` pointer and a function pointer.

+/

unittest { /// Example
    struct ExampleType {
        int sum = 0;
        int add(int num) {
            this.sum += num;
            return this.sum;
        }
    }
    alias ExampleDelegate = Delegate!(int, int);
    ExampleType adder;
    assert(adder.sum == 0);
    adder.add(2);
    assert(adder.sum == 2);
    ExampleDelegate.create(&adder, &ExampleType.add)(4);
    assert(adder.sum == 6);
}

public:

struct Delegate(ReturnType, ParameterTypes...) {
    alias DelegateType = ReturnType delegate(ParameterTypes);
    
    void* instance;
    void* func;
    
    static typeof(this) create(void* instance, void* func) {
        typeof(this) del;
        del.instance = instance;
        del.func = func;
        return del;
    }
    
    auto opCast(T: DelegateType)() {
        return *(cast(DelegateType*) &this);
    }
    
    auto opCall(ParameterTypes arguments) {
        return (*(cast(DelegateType*) &this))(arguments);
    }
}
