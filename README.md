# Artifact Evaluation: Kani Rust Verifier (Kani)


# Abstract
This directory contains the evaluation scripts for our ICSE SEIP paper, Verifying Dynamic Trait Objects in Rust.

The Kani Rust Verifier (Kani) is a new tool for Rust that can verify important safety properties, from memory faults in unsafe Rust code to user-defined correctness assertions. 
To our knowledge, our tool is the first symbolic modeling checking tool for Rust that can verify correctness while supporting the breadth of dynamic trait objects, including dynamic closures. 
Our ICSE SEIP focuses on the challenges in reasoning about Rust's _dynamic trait objects_, a feature that provides dynamic dispatch for function abstractions.
In this artifact, we provide instructions for reproducing each of a major empirical results in the paper: (1) our analysis of the use of dynamic objects in popular crates (packages), (2) two case studies using Kani on an open source virtualization project, and (3) a comparison of Kani and other Rust verification tools on our new open source suite of test cases. 


# Empirical results

This artifact includes steps to replicate the following results:

1. **Section 4.1: Prevalence of dynamic trait objects.** We conducted a simple study to estimate the prevalence of dynamic trait objects in the 500 most downloaded crates (packages) on crates.io, the Rust package repository.  This artifact should reproduce that 37% of crates use explicit dynamic trait objects, and 70% of crates use them implicitly.
2. **Section 4.2: Case study: Firecracker.** We conduct case studies on Firecracker, an open source virtualization technology.
We compare two versions of Kani, one with our new function pointer restriction algorithm and one without. Reviewers should be able to reproduce an improvement of 5% in verification time for the first case, and an improvement of 15X for the second case.
3. **4.3: Dynamic Dispatch Test Suite.** We compare the cases handled by Kani and other related Rust verification tools. For 8 selected cases, we compare Kani with Crux-MIR, Rust Verification Tools - Seahorn, Rust Verification Tools - KLEE, SMACK - Rust, Prusti, and CRUST. We also present our suite of 40 total verification test cases for other researchers to use. For this artifact, reviewers should be able to reproduce the results of Table 1.

There are two components to this artifact:
1. **Kani Rust Verifier (Kani)** This is our publicly available verifier for Rust. Kani (formerly known as the Rust Model Checker (kani)) contains code from the Rust compiler and is distributed under the terms of both the MIT license and the Apache License (Version 2.0).
2. **Verification test cases and comparison to related work** Our contributions include an open-source 
  
We estimate the required components of this artifact to take around 1 hour of reviewer time.

----

# Prerequisites

## Docker
#### Time estimate: 5 minutes.

We provide our artifact as a [Docker][docker] instance. Users should install Docker based on their system's instructions.

## Machine requirements

Our full docker image contains 3 related work projects that each have many dependencies (Crux-MIR, Rust Verification Tools, and SMACK), which increases both the size of the instance and the requirements for the host machine.

We also provide a smaller instance that just contains our Kani system and the _results_ of other tools run on each test cases.

----

# Part 1: Section 4.1: Prevalence of dynamic trait objects.
#### Time estimate: XX minutes.

This section includes a simple study to get a rough estimate of the prevalence of our feature of interest, dynamic trait objects, within the Rust ecosystem. 

This component of the artifact consists of a python script that (1) downloads the top 500 crates sorted by greatest number of downloads, (2) estimates the number of explicit trait objects by search for the `dyn` keywords, and (3) estimates the number of implicit dynamic trait objects by searching a debug output of compiling with Rust for the line `get_vtable`, which is logged at vtable use.


# Part 2: Section 4.2: Case study: Firecracker.
#### Time estimate: 30 minutes.

In these case studies, we consider how two different variants of Kani—--one with our new vtable function pointer restrictions, and one
without--—perform on examples from the open source Firecracker hypervisor written in Rust.

### Case Study 1: Firecracker Serial Device

In this first example, we consider a case that uses explicit dynamic trait object types.

This component of Firecracker defines the following trait:

```rust
// Docker at: /icse22ae-kani/case-study-1/firecracker/src/devices/src/bus.rs
pub trait BusDevice: AsAny + Send {
    /// Reads at `offset` from this device
    fn read(&mut self, offset: u64, data: &mut [u8]) {}
    /// Writes at `offset` into this device
    fn write(&mut self, offset: u64, data: &[u8]) {}
}
```

We add a straightforward test harness with Kani to check that `read` and `write` can be dynamically dispatched. First, the test sets up necessary structs, then checks the value from `read` and `write` dispatched dynamically through an explicit `dyn BusDevice` trait object.

```rust
// Docker at: /icse22ae-kani/case-study-1/firecracker/src/devices/src/legacy/serial.rs
fn serial_harness() {
    // --------------------------------- SETUP --------------------------------
    // This test requires the Serial device be in loopback mode, i.e., 
    // setting is_in_loop_mode to return true in 
    // https://github.com/rust-vmm/vm-superio/blob/main/crates/vm-superio/src/serial.rs
    let serial_out = SharedBuffer::new();
    let intr_evt = EventFdTrigger::new(EventFd{}); 
    let mut serial = SerialDevice {
    serial: Serial::new(
            intr_evt,
            Box::new(serial_out.clone()),
        ),
        input: None,
    };
    let bytes: [u8; 1] = kani::any();

    // ------------------------- Dynamic trait objects ------------------------
    // Dynamic dispatch through `dyn BusDevice`
    <dyn BusDevice>::write(&mut serial, 0u64, &bytes);

    let mut read = [0x00; 1];

    // Dynamic dispatch through `dyn BusDevice`
    <dyn BusDevice>::read(&mut serial, 0u64, &mut read);

    // Verify expected value is read
    assert!(bytes[0] == read[0]);
}
```

First, we'll run Kani on this harness without restrictions. `serial-no-restrictions.sh` is a bash script that runs Kani by invoking the custom Kani backend to the Rust compiler, combining the produced CBMC files per crate, anf finally invoking the solver.

Run the script with:
```bash
cd /icse22ae-kani/case-study-1/firecracker/
time case-study-1/firecracker/serial-no-restrictions.sh
```

This should complete with `VERIFICATION SUCCESSFUL` in around 2 minutes.

The second version of this script, `serial-no-restrictions.sh`, adds a flag to restrict function pointers based on Rust-level type information.  

Run the script with:
```bash
cd /icse22ae-kani/case-study-1/firecracker/
time case-study-1/firecracker/serial-no-restrictions.sh
```

Depending on the host machine, this will complete with `VERIFICATION SUCCESSFUL` in a time 5%-50% faster than the example without restrictions.

# Part 3: 4.3: Dynamic Dispatch Test Suite.
#### Time estimate: 5 minutes.

Table 1 includes a summary of how related Rust verifications tools perform on a representative subset of our verification test cases.

To reproduce this table, we have written versions of each test per tool. Each test is modified for the syntax expected by that tool. For example, SMACK requires asserts be written as `smack::assert!(...)`, and Rust Verification Tools requires an entire crate to execute rather than a single Rust file. Each test is within `/icse22ae-kani/<tool name>/*`. 

To compare each tool, we provide a Python `compare_tools.py` script. This script runs each test and checks for tool-specific success or failure strings. You should see results printed for each tool, then a `Results summary table` printed to standard out. All results should be either `SUCCESS` is verification succeeds or `FAILURE` if it does not. An `UNKNOWN` result indicates the tool has failed to run as expected, or did not produce the expected success or failure string(s) in its output.

To reproduce Table 1, run the following inside the Docker:
```
cd /icse22ae-kani
python3 compare_tools.py
```

To rerun any specific tool(s), you can run, for example, `python3 compare_tools.py --tool kani smack`.