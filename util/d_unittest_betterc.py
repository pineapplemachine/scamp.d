"""

This is a Python script which can be used to generate a D source file
which will run unittest blocks within modules, then compile and run this
file.

Usage:

Test whole package:
python util\d_unittest_betterc.py src/scamp

Test only files ending in "map.d":
python util\d_unittest_betterc.py src/scamp */map.d

Test files ending in "map.d" and their imported dependencies, recursively:
python util\d_unittest_betterc.py src/scamp */map.d --deps scamp.*

"""

import argparse
import fnmatch
import os
import platform
import re
import subprocess
import sys

__version__ = "1.0.0"

re_module = re.compile(r'\bmodule\s+([\w\.]+)\s*;');
re_dep = re.compile(r'^depsImport\s+([\w\.]+)\s+');

def run_command(command, silent=False, each_line=None):
    if not silent:
        print("$", *command)
    process = subprocess.Popen(command,
        shell=True,
        text=True,
        encoding="utf-8",
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
    )
    for line in iter(process.stdout.readline, ""):
        if each_line is not None:
            each_line(line)
        if not silent:
            print(line, end="")
    status = process.wait()
    process.stdout.close()
    if status:
        raise subprocess.CalledProcessError(status, command)
    return status

def get_argument_parser():
    parser = argparse.ArgumentParser(
        prog="d_unittest_betterc",
        add_help=False,
        description=("""
            Utility program that can be used to run unittest blocks
            in a D package using the -betterC compilation flag.
        """),
    )
    parser.add_argument("--help",
        help=("""
            Show help text.
        """),
        action="store_true",
    )
    parser.add_argument("--version",
        help=("""
            Show version name.
        """),
        action="store_true",
    )
    parser.add_argument("-v", "--verbose",
        help=("""
            Log more information than usual.
        """),
        action="store_true",
    )
    parser.add_argument("package",
        help=("""
            Look for modules recursively within this directory
            path.
        """),
        type=str,
    )
    parser.add_argument("modules",
        help=("""
            One or more module names, file names, or glob
            patterns to match either module or file names.
            Unittests will be run in all matching modules.
            If no modules are specified, then tests will
            be run for all modules in the given package.
        """),
        type=str,
        nargs="*",
    )
    parser.add_argument("-o", "--output",
        help=("""
            Specify an output directory where generated test
            files should be stored.
        """),
        type=str,
    )
    parser.add_argument("-d", "--deps",
        help=("""
            Additionally run unittests for imported modules
            within the same package, provided they match one of
            these module names or glob patterns.
        """),
        type=str,
        nargs="+",
    )
    parser.add_argument("-c", "--compiler",
        help=("""
            Specify a D compiler to use when building with
            unittests.
        """),
        type=str,
        default="dmd",
    )
    parser.add_argument("-cargs", "--compiler-args",
        help=("""
            Additional arguments to pass to the D compiler when
            building with unittests.
        """),
        type=str,
    )
    parser.add_argument("-t", "--template",
        help=("""
            Specify a test runner template file to use instead of
            the default.
        """),
        type=str,
    )
    parser.add_argument("--render-only",
        help=("""
            Render a D source file for a unittest runner in the
            output directory, but don't compile or run it.
        """),
        action="store_true",
    )
    parser.add_argument("--build-only",
        help=("""
            Build a unittest runner binary in the output
            directory, but don't run it.
        """),
        action="store_true",
    )
    return parser

class TestUtil:
    def __init__(self,
        verbose,
        compiler,
        compiler_args,
        render_only,
        build_only,
        module_patterns,
        dependency_patterns,
        package_path,
        output_path,
        template_path,
    ):
        self.verbose = verbose
        self.compiler = compiler
        self.compiler_args = compiler_args
        self.render_only = render_only
        self.build_only = build_only
        self.module_patterns = module_patterns
        self.dependency_patterns = dependency_patterns
        self.package_path = package_path
        self.output_path = output_path
        self.template_path = template_path
        self.output_main_path = os.path.join(
            self.output_path, "d_unittest_betterc.d"
        )
        self.output_main_binary_path = self.output_main_path[:-2]
        if platform.system() == "Windows":
            self.output_main_binary_path += ".exe"
        self.modules = dict()
        self.module_deps = set()
        self.test_modules = set()
        self.template = None
        if not os.path.exists(self.package_path):
            raise ValueError(
                "Input package path does not exist."
            )
        if not os.path.isdir(self.package_path):
            raise ValueError(
                "Input package path is not a directory path."
            )
        if not os.path.exists(self.template_path):
            raise ValueError(
                "Template path does not exist."
            )
    
    def run(self):
        self.scan_package_modules()
        if self.dependency_patterns:
            self.scan_module_deps()
        self.render_template()
        if not self.render_only:
            self.build_tests()
            if not self.build_only:
                self.run_tests()
    
    def print_verbose(self, *args):
        if self.verbose:
            print(*args)
    
    def scan_package_modules(self):
        self.print_verbose("Scanning for modules in directory", self.package_path)
        for root, dirs, files in os.walk(self.package_path):
            for file_name in files:
                if len(file_name) > 2 and file_name[-2:].lower() == ".d":
                    file_path = os.path.join(root, file_name)
                    self.scan_package_module_file(file_path)
    
    def scan_package_module_file(self, file_path):
        with open(file_path, "rt", encoding="utf-8") as d_file:
            d_source = d_file.read()
        match_module = re_module.search(d_source)
        if match_module is not None:
            module_name = match_module.group(1)
            self.modules[module_name] = file_path
            self.print_verbose("Found module", module_name)
    
    def scan_module_deps(self):
        def each_line(line):
            match_dep = re_dep.match(line)
            if match_dep is None:
                return
            name = match_dep.group(1)
            self.module_deps.add(name)
            if name in self.modules and name not in queued_modules:
                queue.append((name, self.modules[name]))
                queued_modules.add(name)
        queue = self.get_matched_modules()
        queued_modules = set(name for name, path in queue)
        queue_index = 0
        while queue_index < len(queue):
            module_name, module_path = queue[queue_index]
            queue_index += 1
            command = list(filter(lambda opt: opt, [
                self.compiler,
                module_path,
                "-I" + os.path.dirname(self.package_path),
                "-i",
                "-main",
                "-deps",
                self.compiler_args,
            ]))
            run_command(command, silent=True, each_line=each_line)
    
    def get_matched_modules(self):
        if not self.module_patterns:
            return list(self.modules.items())
        return list(filter(
            lambda item: any(
                fnmatch.fnmatch(item[0], pattern) or
                fnmatch.fnmatch(item[1], pattern)
                for pattern in self.module_patterns
            ),
            self.modules.items(),
        ))
    
    def get_test_modules(self):
        test_modules = set(name for name, path in self.get_matched_modules())
        if self.dependency_patterns:
            for dep in self.module_deps:
                if any(
                    fnmatch.fnmatch(dep, pattern)
                    for pattern in self.dependency_patterns
                ):
                    test_modules.add(dep)
        return test_modules
    
    def render_template(self):
        test_modules = sorted(self.get_test_modules())
        self.print_verbose("Building tests for", len(test_modules), "modules")
        self.print_verbose("Reading template from", self.template_path)
        with open(self.template_path, "rt", encoding="utf-8") as d_file:
            self.template = d_file.read()
        render = self.template.replace(
            "/+d_unittest_betterc_modules_length+/",
            str(len(test_modules)),
        ).replace(
            "/+d_unittest_betterc_modules_list+/",
            ", ".join(map(lambda name: "\"%s\"" % name, test_modules))
        )
        self.print_verbose("Writing rendered template to", self.output_main_path)
        os.makedirs(self.output_path, exist_ok=True)
        with open(self.output_main_path, "wt", encoding="utf-8") as d_file:
            d_file.write(render)
    
    def build_tests(self):
        command = list(filter(lambda opt: opt, [
            self.compiler,
            self.output_main_path,
            "-I" + os.path.dirname(self.package_path),
            "-od" + self.output_path,
            "-of" + self.output_main_binary_path,
            "-i",
            "-unittest",
            self.compiler_args,
        ]))
        status = run_command(command)
        self.print_verbose("Compilation finished with status code", status)
        if not os.path.exists(self.output_main_binary_path):
            raise ValueError(
                "Compiled binary not found. " +
                "Expected a binary at %s" % self.output_main_binary_path
            )
    
    def run_tests(self):
        status = run_command([os.path.abspath(self.output_main_binary_path)])
        self.print_verbose("Execution finished with status code", status)

def __main__():
    parser = get_argument_parser()
    args = parser.parse_args()
    if args.help:
        parser.print_help()
        sys.exit(0)
    elif args.version:
        print("d_unittest_betterc version", __version__)
        sys.exit(0)
    output_path = args.output if args.output else (
        os.path.join(os.path.dirname(__file__), "bin")
    )
    template_path = args.template if args.template else __file__[:-2] + "d"
    util = TestUtil(
        verbose=args.verbose,
        compiler=args.compiler,
        compiler_args=args.compiler_args,
        render_only=args.render_only,
        build_only=args.build_only,
        module_patterns=args.modules,
        dependency_patterns=args.deps,
        package_path=args.package,
        output_path=output_path,
        template_path=template_path,
    )
    util.run()

if __name__ == "__main__":
    __main__()
