swift test --enable-code-coverage
xcrun llvm-cov export \
    -instr-profile=.build/debug/codecov/default.profdata  \
    -format="lcov" \
    .build/debug/ShaftPackageTests.xctest/Contents/MacOS/ShaftPackageTests > lcov.info 