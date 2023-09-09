import scamp.io.stdio : stdio;
import scamp.range.pad : pad_front;
import scamp.text.write_int : write_int;
import scamp.time.monotonic : monotonic_ns;

enum string[/+d_unittest_betterc_modules_length+/] TestModules = [
    /+d_unittest_betterc_modules_list+/
];

extern(C) void test_module(string module_name)(
    size_t* all_tests_count,
    size_t* all_tests_ns,
) {
    mixin("import " ~ module_name ~ ";");
    alias tests = __traits(getUnitTests, mixin(module_name));
    static if(tests.length) {
        size_t tests_count = 0;
        size_t tests_start_ns = monotonic_ns();
        static foreach(test; tests) {
            //test();
            tests_count++;
            (*all_tests_count)++;
        }
        size_t tests_end_ns = monotonic_ns();
        size_t tests_ns = tests_end_ns - tests_start_ns;
        size_t tests_ms = tests_ns / 1_000_000;
        auto tests_ms_str = write_int(tests_ms).pad_front(4, '0');
        *all_tests_ns += tests_ns;
        stdio.writeln(
            module_name, ": ",
            "Ran ", write_int(tests_count), " ",
            (tests_count == 1 ? "test" : "tests"), " in ",
            tests_ms_str[0 .. $ - 3], ".", tests_ms_str[$ - 3 .. $], " seconds."
        );
        stdio.flush();
    }
}

extern(C) int main() {
    stdio.writeln("Running tests.");
    size_t tests_count = 0;
    size_t tests_ns = 0;
    static foreach(module_name; TestModules) {
        test_module!module_name(&tests_count, &tests_ns);
    }
    size_t tests_ms = tests_ns / 1_000_000;
    auto tests_ms_str = write_int(tests_ms).pad_front(4, '0');
    stdio.writeln(
        "Finished running ", write_int(tests_count), " ",
        (tests_count == 1 ? "test" : "tests"), " in ",
        tests_ms_str[0 .. $ - 3], ".", tests_ms_str[$ - 3 .. $], " seconds. ",
        "(", write_int(tests_ns), " nanoseconds)"
    );
    return 0;
}
