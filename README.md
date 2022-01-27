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
1. **Kani Rust Verifier (Kani)** This is our publicly available verifier for Rust. Kani (formerly known as the Rust Model Checker (RMC)) contains code from the Rust compiler and is distributed under the terms of both the MIT license and the Apache License (Version 2.0).
2. **Verification test cases and comparison to related work** Our contributions include an open-source 
  
We estimate the required components of this artifact to take around 1 hour of reviewer time.

----

# Prerequisites

## Docker

We provide our artifact as a [Docker][docker] instance. Users should install Docker based on their system's instructions.

#### Time estimate: 5 minutes.

## Machine requirements

Our full docker image contains 3 related work projects that each have many dependencies (Crux-MIR, Rust Verification Tools, and SMACK), which increases both the size of the instance and the requirements for the host machine.

We also provide a smaller instance that just contains our Kani system and the _results_ of other tools run on each test cases.

----

# Part 1: Section 4.1: Prevalence of dynamic trait objects.

This section includes a simple study to get a rough estimate of the prevalence of our feature of interest, dynamic trait objects, within the Rust ecosystem. 

This component of the artifact consists of a python script that (1) downloads the top 500 crates sorted by greatest number of downloads, (2) counts the number of explicit trait objects 

 on October 2, 2021. 

To estimate the use of explicit dynamic trait objects, 
To estimate the implicit use of dynamic trait objects, we invoked a debug build of the Rust compiler via
735 cargo build and searched the debug output for the line get_vtable,
736 which is logged at vtable use. This is likely an over-estimate of the
737 dynamic trait objects that are actually used in functionality a user
738 might want to verify for these crates, but it does provide an indica-
739 tion of how often verification tools that integrate with Cargo will
740 encounter linked dynamically dispatched code.

# Part 2: Section 4.2: Case study: Firecracker.

# Part 3: 4.3: Dynamic Dispatch Test Suite.