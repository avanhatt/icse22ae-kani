"""
Compare the results of several verification tools on a subset of test cases
that we have translated into the syntax of each tool. 

Tools covered:
1. Kani Rust Verifier (kani; our tool)
2. Crucible's Crux-MIR 
3. Rust Verification Tools - Seahorn (RVT-SH) 
4. Rust Verification Tools - KLEE (RVT-KLEE)
5. Smack - Rust 
"""
import os
import subprocess

TESTS = [
    "simple-trait-pointer",
    "simple-trait-boxed",
    "auto-trait-pointer",
    "fn-closure-pointer",
    "fnonce-closure-boxed",
    "generic-trait-pointer",
    "explicit-drop-boxed",
    "explicit-drop-pointer",
]

TEST_DIR = "tests"

KANI_DIR = "kani"
CRUX_MIR_DIR = "crux-mir"
RVT_DIR = "rvt"

FAILURE = "FAILURE"
SUCCESS = "SUCCESS"
UNKNOWN = "UNKNOWN"

def check_verification_result(cmd, success_str, failure_strs):
    print("RUNNING command:", " ".join(cmd))
    result = subprocess.run(cmd, capture_output=True)
    output = str(result.stdout)
    success_found = success_str in output
    failure_found = any([f in output for f in failure_strs])

    if success_found and not failure_found:
        print("\tCommand succeeded, found:", success_str)
        return SUCCESS
    elif not success_found and failure_found:
        print("\tCommand failed, found:", "/".join(failure_str))
        return FAILURE
    elif success_found and failure_found:
        print("\tExpected either success or failure, found both: {} {}", success_str, "/".join(failure_strs))
        print(output)
        return UNKNOWN
    else:
        print("\tExpected either success or failure, found neither: {} {}",  success_str, "/".join(failure_strs))
        print(output)
        return UNKNOWN


def check_kani():
    for test_name in TESTS:
        test = os.path.join(TEST_DIR, KANI_DIR, test_name + ".rs")
        cmd = ["kani", test]
        with open(test) as f:
            first = f.readline().rstrip()
            if "// kani-args:" in first:
                cmd += first.replace("// kani-args:", "").split(" ") 
        res = check_verification_result(cmd, "VERIFICATION SUCCESSFUL", ["VERIFICATION FAILED"])

def check_crux_mir():
    for test_name in TESTS:
        test = os.path.join(TEST_DIR, CRUX_MIR_DIR, test_name + ".rs")
        res = check_verification_result(["/root/.cabal/bin/crux-mir", test], "Overall status: Valid.", ["Overall status: Invalid."])

def check_rvt_klee():
    for test_name in TESTS:
        test = os.path.join(TEST_DIR, RVT_DIR, test_name, "Cargo.toml")
        res = check_verification_result(["cargo-verify", "--backend=klee", "--tests", "--manifest-path", test], "VERIFICATION_RESULT: VERIFIED", ["VERIFICATION_RESULT: ERROR", "VERIFICATION_RESULT: UNKNOWN"])
        result = subprocess.run(["cargo", "clean", "--manifest-path", test], capture_output=True)


def check_rvt_seahorn():
    for test_name in TESTS:
        test = os.path.join(TEST_DIR, RVT_DIR, test_name, "Cargo.toml")
        res = check_verification_result(["cargo-verify", "--backend=seahorn", "--tests", "--manifest-path", test], "VERIFICATION_RESULT: VERIFIED", "VERIFICATION_RESULT: ERROR")
        result = subprocess.run(["cargo", "clean", "--manifest-path", test], capture_output=True)

def main():
    check_kani()
    check_crux_mir()
    check_rvt_klee()
    check_rvt_seahorn()

if __name__ == main():
    main()