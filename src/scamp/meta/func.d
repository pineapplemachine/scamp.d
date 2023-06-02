module scamp.meta.func;

private:

unittest { /// Example
    import scamp.meta.aliases : Aliases;
    size_t sum_length(string a, int[] b) {
        return a.length + b.length;
    }
    static assert(is(FunctionReturnType!(typeof(sum_length)) == size_t));
    static assert(is(
        FunctionParameterTypes!(typeof(sum_length)) ==
        Aliases!(string, int[])
    ));
}

public:

template FunctionReturnType(T) {
    static if (is(T Return == return)) {
        alias FunctionReturnType = Return;
    }
    else static if(is(T Pointer : Pointer*) && is(Pointer Return == return)) {
        alias FunctionReturnType = Return;
    }
    else static if(is(T DelFunc == delegate) && is(DelFunc Return == return)) {
        alias FunctionReturnType = Return;
    }
    else {
        static assert(false, "Type is not a function: " ~ T.stringof);
    }
}

template FunctionParameterTypes(T) {
    static if (is(T Params == function)) {
        alias FunctionParameterTypes = Params;
    }
    else static if(is(T Pointer : Pointer*) && is(Pointer Params == function)) {
        alias FunctionParameterTypes = Params;
    }
    else static if(is(T DelFunc == delegate) && is(DelFunc Params == function)) {
        alias FunctionParameterTypes = Params;
    }
    else {
        static assert(false, "Type is not a function: " ~ T.stringof);
    }
}

version(unittest) {
    private import scamp.meta.aliases : Aliases;
}

unittest {
    size_t fn(int a, float b, string c) {return 0;}
    static assert(is(FunctionReturnType!(typeof(fn)) == size_t));
    static assert(is(FunctionReturnType!(typeof(&fn)) == size_t));
    static assert(is(FunctionParameterTypes!(typeof(fn)) == Aliases!(int, float, string)));
    static assert(is(FunctionParameterTypes!(typeof(&fn)) == Aliases!(int, float, string)));
}
