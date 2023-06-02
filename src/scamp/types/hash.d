module scamp.types.hash;

public:

/// Determine whether it's possible to hash values of some type
/// using the `hash` function.
enum bool isHashable(T) = is(typeof({size_t i = hash(T.init);}));

/// Get a hash of some value.
size_t hash(T)(auto ref T value) {
    static if(is(typeof({size_t i = value.toHash;}))) {
        return cast(size_t) value.toHash;
    }
    else {
        size_t gethash() @trusted {
            return cast(size_t) typeid(value).getHash(&value);
        }
        return gethash();
    }
}

unittest {
    struct HashableType0 {
        int x;
    }
    struct HashableType1 {
        int toHash;
    }
    struct HashableType2 {
        @disable this();
        int toHash;
    }
    static assert(isHashable!string);
    static assert(isHashable!int);
    static assert(!isHashable!void);
    static assert(isHashable!HashableType0);
    static assert(isHashable!HashableType1);
    static assert(isHashable!HashableType2);
}

unittest {
    string str0 = "hello world";
    string str1 = "hello world";
    string str2 = "hello worlds";
    assert(str0.hash == str1.hash);
    assert(str0.hash != str2.hash);
    assert(0.hash == 0.hash);
    assert(0.hash != 1.hash);
}
