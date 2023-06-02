module scamp.io.stdio;

private:

import core.stdc.stdio : stdin, stdout, stderr;
import core.stdc.stdio : fwrite, fflush, putc, getc;

import scamp.meta.range : isRangeIterable;
import scamp.range.range : range;

/++ Docs

This module provides functions for writing to stdout and stderr and
for reading from stdin, the standard input and output streams.

https://en.wikipedia.org/wiki/Standard_streams

+/

public nothrow @safe @nogc:

void putc_stdout(in char ch) @trusted {
    putc(ch, stdout);
}

void putc_stderr(in char ch) @trusted {
    putc(ch, stderr);
}

int getc_stdin() @trusted {
    return getc(stdin);
}

/// Namespace containing standard input and output functions.
struct stdio {
    public nothrow @safe @nogc:
    
    /// Print character to stdout.
    static void write(in char text) {
        putc_stdout(text);
    }
    
    /// Print string to stdout.
    static void write(in char[] text) @trusted {
        fwrite(text.ptr, char.sizeof, text.length, stdout); 
    }
    
    /// Print iterable of characters to stdout.
    static void write(T)(auto ref T text) if(isRangeIterable!T) {
        foreach(ch; text.range) {
            putc_stdout(cast(char) ch);
        }
    }
    
    /// Print each argument to stdout.
    static void write(T...)(auto ref T items) if(T.length >= 2) {
        foreach(item; items) {
            stdio.write(item);
        }
    }

    /// Print each argument to stdout, followed by a newline '\n'.
    static void writeln(T...)(auto ref T text) {
        stdio.write(text);
        stdio.write('\n');
    }
    
    /// Print character to stderr.
    static void error(in char text) {
        putc_stderr(text);
    }
    
    /// Print string to stderr.
    static void error(in char[] text) @trusted {
        fwrite(text.ptr, char.sizeof, text.length, stderr); 
    }
    
    /// Print iterable of characters to stderr.
    static void error(T)(auto ref T text) if(isRangeIterable!T) {
        foreach(ch; text.range) {
            putc_stderr(ch);
        }
    }
    
    /// Print each argument to stderr.
    static void error(T...)(auto ref T items) if(T.length >= 2) {
        foreach(item; items) {
            stdio.error(item);
        }
    }

    /// Print each argument to stderr, followed by a newline '\n'.
    static void errorln(T...)(auto ref T text) {
        stdio.error(text);
        stdio.error('\n');
    }
    
    /// Flush stdout and stderr.
    static void flush() @trusted {
        fflush(stdout);
        fflush(stderr);
    }
    
    /// Flush stdout.
    static void flush_stdout() @trusted {
        fflush(stdout);
    }
    
    /// Flush stderr.
    static void flush_stderr() @trusted {
        fflush(stderr);
    }
    
    /// Get the next character from stdin via `getc`.
    static int getchar() {
        return getc_stdin();
    }
    
    /// Get a range for reading characters from stdin until EOF.
    static StdinRange read() {
        return StdinRange(getc_stdin());
    }
    
    /// Get a range for reading characters from stdin until EOF
    /// or the next newline character '\n'.
    static StdinLineRange readln() {
        return StdinLineRange(getc_stdin());
    }
    
    /**
     * Read characters from stdin into a buffer, until EOF
     * or the next newline character '\n' or the capacity of
     * the buffer, whichever comes first.
     * 
     * The terminating newline character will be included in the
     * buffer, if there was one.
     * 
     * @param buffer Read characters into this buffer.
     * @return The number of characters read.
     */
    static size_t readln(char[] buffer) {
        size_t length = 0;
        while(length < buffer.length) {
            const ch = getc_stdin();
            if(ch < 0) break;
            buffer[length++] = cast(char) ch;
            if(ch == '\n') break;
        }
        return length;
    }
}

/// Read characters from stdin until EOF.
struct StdinRange {
    public nothrow @safe @nogc:
    
    int front_int;
    
    bool empty() const {
        return this.front < 0;
    }
    
    char front() const {
        return cast(char) this.front_int;
    }
    
    void popFront() {
        this.front_int = getc_stdin();
    }
}

/// Read characters from stdin until EOF or a newline character '\n'.
alias StdinLineRange = StdinUntilRange!('\n');

/// Read characters from stdin until EOF or a given character.
struct StdinUntilRange(char Until) {
    public nothrow @safe @nogc:
    
    enum until_char = Until;
    
    int front_int;
    
    bool empty() const {
        return this.front < 0 || this.front == until_char;
    }
    
    char front() const {
        return cast(char) this.front_int;
    }
    
    void popFront() {
        this.front_int = getc_stdin();
    }
}

unittest {
    import scamp.text.write_int : write_int;
    static assert(is(typeof(stdio.writeln("hello"))));
    static assert(is(typeof(stdio.writeln("hello", ' ', "world"))));
    static assert(is(typeof(stdio.writeln(write_int(1)))));
    static assert(is(typeof(stdio.writeln(write_int(1), "!"))));
    //stdio.writeln("Hello world!");
}
