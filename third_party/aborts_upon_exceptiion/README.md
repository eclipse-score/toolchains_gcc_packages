## Compile flags:
```bash
x86_64-unknown-linux-gnu-g++ -U_FORTIFY_SOURCE '-D_XOPEN_SOURCE=700' -fstack-protector '-fdiagnostics-color=always' -fno-omit-frame-pointer -ffunction-sections -fdata-sections -fno-canonical-system-headers -no-canonical-prefixes '-z noexecstack' -m64 '-std=c++17' -MD -MF bazel-out/k8-fastbuild/bin/score/language/safecpp/aborts_upon_exception/_objs/abortsuponexception/aborts_upon_exception.pic.d '-frandom-seed=bazel-out/k8-fastbuild/bin/score/language/safecpp/aborts_upon_exception/_objs/abortsuponexception/aborts_upon_exception.pic.o' -fPIC -iquote . -iquote bazel-out/k8-fastbuild/bin '-D__DATE__="redacted"' '-D__TIMESTAMP__="redacted"' '-D__TIME__="redacted"' -Wno-builtin-macro-redefined -Wall -Wcast-align -Wcast-qual -Wformat-nonliteral -Wformat-signedness '-Wformat=2' -Wmissing-format-attribute -Wpointer-arith -Wredundant-decls -Wreturn-local-addr -Wsizeof-array-argument -Wundef -Wwrite-strings -Wodr -Wreorder -Werror '-Wno-error=deprecated-declarations' '--sysroot=external/score_bazel_cpp_toolchains++gcc+score_gcc_x86_64_toolchain_pkg/x86_64-unknown-linux-gnu/sysroot'
```

# Link flags:
```bash
-shared
-o
bazel-out/k8-fastbuild/bin/score/language/safecpp/aborts_upon_exception/libabortsuponexception.so
bazel-out/k8-fastbuild/bin/score/language/safecpp/aborts_upon_exception/_objs/abortsuponexception/aborts_upon_exception.pic.o
-Wl,-S
-lm
-ldl
-lrt
-static-libstdc++
-static-libgcc
-Wl,--compress-debug-sections=zlib
-pthread
--sysroot=external/score_bazel_cpp_toolchains++gcc+score_gcc_x86_64_toolchain_pkg/x86_64-unknown-linux-gnu/sysroot
```