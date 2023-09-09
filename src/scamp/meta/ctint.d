module scamp.meta.ctint;

private:

/++ Docs

This module provides a zero-dependency integer stringification
function optimized for use at compile time, e.g. in functions
generating mixin strings

+/

unittest{ /// Example
    static assert(ctint(1234) == "1234");
}

public:

string ctint(N)(in N value) {
    if(value == 0) return "0";
    N x = value;
    string result = "";
    while(x != 0){
        immutable d = x % 10;
        result = cast(char)('0' + (d > 0 ? d : -d)) ~ result;
        x /= 10;
    }
    return value > 0 ? result : "-" ~ result;
}

unittest { /// At runtime
    assert(ctint(0) == "0");
    assert(ctint(1) == "1");
    assert(ctint(-1) == "-1");
    assert(ctint(1u) == "1");
    assert(ctint(2) == "2");
    assert(ctint(-2) == "-2");
    assert(ctint(2u) == "2");
    assert(ctint(100) == "100");
    assert(ctint(-100) == "-100");
    assert(ctint(int.max) == "2147483647");
    assert(ctint(int.min) == "-2147483648");
}

unittest { /// At compile time
    static assert(ctint(0) == "0");
    static assert(ctint(1) == "1");
    static assert(ctint(-1) == "-1");
    static assert(ctint(1u) == "1");
    static assert(ctint(2) == "2");
    static assert(ctint(-2) == "-2");
    static assert(ctint(2u) == "2");
    static assert(ctint(100) == "100");
    static assert(ctint(-100) == "-100");
    static assert(ctint(int.max) == "2147483647");
    static assert(ctint(int.min) == "-2147483648");
}
