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
import argparse
import tabulate
import numpy

TOOLS = [
    "kani", 
    "crux-mir",
    "rvt-klee",
    "rvt-sh",
    "smack",
]


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
SMACK_DIR = "smack"

FAILURE = "FAILURE"
SUCCESS = "SUCCESS"
UNKNOWN = "UNKNOWN"

def check_verification_result(cmd, success_str, failure_strs):
    """Run a command with subprocess and check whether the result contains
    the tool-specific verification success string, or any of the possible
    failure strings (passed as a list).
    """
    print("\tRunning command:", " ".join(cmd))
    result = subprocess.run(cmd, capture_output=True)
    output = str(result.stdout)
    success_found = success_str in output
    failure_found = any([f in output for f in failure_strs])

    if success_found and not failure_found:
        print("\t\tSUCCESS, found:", success_str)
        return SUCCESS
    elif not success_found and failure_found:
        print("\t\tFAILURE, found:", "/".join(failure_strs))
        return FAILURE
    elif success_found and failure_found:
        print("\t\tUNKNOWN, expected either success or failure, found both: {} {}".format(success_str, "/".join(failure_strs)))
        print(output)
        return UNKNOWN
    else:
        print("\t\tUNKNOWN, Expected either success or failure, found neither: {} {}".format(success_str, "/".join(failure_strs)))
        print(output)
        return UNKNOWN


def check_kani(results):
    """Check results for Kani run on the single Rust test files.
    """
    print("\n---------------------- Checking results for Kani ----------------------")
    res = ["Kani"]
    for test_name in TESTS:
        test = os.path.join(TEST_DIR, KANI_DIR, test_name + ".rs")
        cmd = ["kani", test]
        with open(test) as f:
            first = f.readline().rstrip()
            if "// kani-args:" in first:
                cmd += first.replace("// kani-args:", "").split(" ") 
        res.append(check_verification_result(cmd, "VERIFICATION SUCCESSFUL", ["VERIFICATION FAILED"]))
    results.append(res)

def check_crux_mir(results):
    """Check results for Crux-MIR run on the single Rust test files.
    """
    print("\n------------------- Checking results for Crux-MIR ---------------------")
    res = ["Crux-MIR"]
    for test_name in TESTS:
        test = os.path.join(TEST_DIR, CRUX_MIR_DIR, test_name + ".rs")
        res.append(check_verification_result(["/root/.cabal/bin/crux-mir", test], "Overall status: Valid.", ["Overall status: Invalid."]))
    results.append(res)

def check_rvt_klee(results):
    """Check results for Rust Verification Tools - KLEE, which needs to be run 
    on crates where each case is a propverify test.
    """
    print("\n------------------ Checking results for RVT - KLEE --------------------")
    res = ["RVT-KLEE"]
    for test_name in TESTS:
        test = os.path.join(TEST_DIR, RVT_DIR, test_name, "Cargo.toml")
        res.append(check_verification_result(["cargo-verify", "--backend=klee", "--tests", "--manifest-path", test], "VERIFICATION_RESULT: VERIFIED", ["VERIFICATION_RESULT: ERROR", "VERIFICATION_RESULT: UNKNOWN"]))
        result = subprocess.run(["cargo", "clean", "--manifest-path", test], capture_output=True)
    results.append(res)


def check_rvt_seahorn(results):
    """Check results for Rust Verification Tools - Seahorn, which needs to be run 
    on crates where each case is a propverify test.
    """
    print("\n---------------- Checking results for RVT - Seahorn -------------------")
    res = ["RVT-SH"]
    for test_name in TESTS:
        test = os.path.join(TEST_DIR, RVT_DIR, test_name, "Cargo.toml")
        res.append(check_verification_result(["cargo-verify", "--backend=seahorn", "--tests", "--manifest-path", test], "VERIFICATION_RESULT: VERIFIED", ["VERIFICATION_RESULT: ERROR", "VERIFICATION_RESULT: UNKNOWN"]))
        result = subprocess.run(["cargo", "clean", "--manifest-path", test], capture_output=True)
    results.append(res)

def check_smack(results):
    """Check results for SMACK run on the single Rust test files.
    """
    print("\n---------------- Checking results for SMACK - RUST --------------------")
    res = ["SMACK"]
    for test_name in TESTS:
        test = os.path.join(TEST_DIR, SMACK_DIR, test_name + ".rs")
        res.append(check_verification_result(["smack", "--unroll", "3",  test], "SMACK found no errors with unroll bound 3", ["doesn't have a size known at compile-time"]))
    results.append(res)

def main():
    """Parse arguments, run each tool, collect and format results.
    """
    parser = argparse.ArgumentParser()
    parser.add_argument("--tools", action="extend", nargs="+", type=str, 
        help='specify which tools to run ({})'.format(", ".join(TOOLS)))
    args = parser.parse_args()

    if args.tools:
        for t in args.tools:
            if t not in TOOLS:
                print("Tools {} not found in options: {}".format(t, ", ".join(TOOLS)))


    results = [["Tests"] + [i+1 for i in range(len(TESTS))]]
    
    if args.tools == None or "kani" in args.tools:
        check_kani(results)
    
    if args.tools == None or "crux-mir" in args.tools:
        check_crux_mir(results)

    if args.tools == None or "rvt-sh" in args.tools:
        check_rvt_seahorn(results)

    if args.tools == None or "rvt-klee" in args.tools:
        check_rvt_klee(results)

    if args.tools == None or "smack" in args.tools:
        check_smack(results)

    results = numpy.transpose(results)

    print("\n---------------------- Results summary table --------------------------")
    print("Tests:")
    for i, test in enumerate(TESTS):
        print("{} : {}".format(i, test))
    print()
    print(tabulate.tabulate(results,headers="firstrow"))

if __name__ == main():
    main()