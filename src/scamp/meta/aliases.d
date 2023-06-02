module scamp.meta.aliases;

private:

/++ Docs

The `Alias` template can be used to generate an alias to a specific value,
even ones that could not be aliased using `alias x = y;` because `y` is a
value but not a symbol.

+/

unittest { /// Example
    alias int_alias = Alias!int;
    static assert(is(int_alias == int));
}

unittest { /// Example
    alias zero = Alias!0;
    static assert(zero == 0);
}

/++ Docs

The `Aliases` template can be used to produce an alias for a sequence of
values.

+/

unittest { /// Example
    alias seq = Aliases!(0, 1, void);
    static assert(seq[0] == 0);
    static assert(seq[1] == 1);
    static assert(is(seq[2] == void));
}

unittest { /// Example
    alias empty_seq = Aliases!();
    static assert(empty_seq.length == 0);
}

unittest { /// Example
    alias ints = Aliases!(int, int, int);
    static assert(ints.length == 3);
    auto fn0(int, int, int) {}
    static assert(is(typeof({fn0(ints.init);})));
    auto fn1(ints) {}
    static assert(is(typeof({fn1(ints.init);})));
}

public:

/// Produce an alias referring to a sequence of types or values.
template Aliases(T...) {
    alias Aliases = T;
}

/// Produce an alias referring to a type or value.
template Alias(T) {
    alias Alias = T;
}

/// Produce an alias referring to a type or value.
template Alias(alias T) {
    static if(__traits(compiles, {alias A = T;})) {
        alias Alias = T;
    }else static if(__traits(compiles, {enum A = T;})) {
        enum Alias = T;
    }else{
        static assert(false, "Failed to alias type " ~ a.stringof ~ ".");
    }
}

unittest {
    alias Nums = Aliases!(int, long);
    void nums_test(Nums nums) {
        static assert(nums.length == 2);
        static assert(is(typeof(nums[0]) == int));
        static assert(is(typeof(nums[1]) == long));
    }
}

unittest {
    alias Ints = Aliases!int;
    void ints_test(Ints i) {
        static assert(is(typeof(i[0]) == int));
    }
}

unittest {
    alias Int = Alias!int;
    void int_test(Int i) {
        static assert(is(typeof(i) == int));
    }
    alias Four = Alias!4;
}
