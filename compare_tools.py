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

def check_verification_result(cmd, success_str, failure_str):
    result = subprocess.run(cmd, capture_output=True)
    output = str(result.stdout)
    print(output)
    success_found = success_str in output
    failure_found = failure_str in output

    if success_found and not failure_found:
        print("Command {} succeeded", cmd)
        return SUCCESS
    elif not success_found and failure_found:
        print("Command {} failed", cmd)
        return FAILURE
    elif success_found and failure_found:
        print("Expected either success or failure for command {}, found both", cmd)
        return UNKNOWN
    else:
        print("Expected either success or failure for command {}, found neither", cmd)
        return UNKNOWN


def check_kani():
    for test_name in TESTS:
        test = os.path.join(TEST_DIR, KANI_DIR, test_name + ".rs")
        res = check_verification_result(["kani", test], "SUCCEEDED", "FAILED")
        print(res)

def check_crux_mir():
    for test_name in TESTS:
        test = os.path.join(TEST_DIR, CRUX_MIR_DIR, test_name + ".rs")
        res = check_verification_result(["cabal", "v2-exec", "--", "crux-mir", test], "Overall status: Valid.", "Overall status: Invalid.")
        print(res)

def check_rvt_klee():
    pass

def check_rvt_smack():
    pass


def main():
    check_kani()
    check_crux_mir()

if __name__ == main():
    main()