module scamp.range.mixins;

public:

mixin template IterableInheritLengthMixin() {
    static if(is(typeof({enum x = Source.ends;}))) {
        enum ends = Source.ends;
    }
    else static if(is(typeof(Source.init.ends))) {
        auto ends() {
            return this.source.ends;
        }
    }
    
    static if(is(typeof({enum x = Source.empty;}))) {
        enum empty = Source.empty;
    }
    else static if(is(typeof({enum x = Source.length <= 0;}))) {
        enum empty = Source.length <= 0;
    }
    else static if(is(typeof(Source.init.empty))) {
        auto empty() {
            return this.source.empty;
        }
    }
    else static if(is(typeof(Source.init.length <= 0))) {
        auto empty() {
            return this.source.length <= 0;
        }
    }
    
    static if(is(typeof({enum x = Source.length;}))) {
        alias opDollar = length;
        enum length = Source.length;
    }
    else static if(is(typeof(Source.init.length))) {
        alias opDollar = length;
        auto length() {
            return this.source.length;
        }
    }
}
