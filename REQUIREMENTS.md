# Requirements

Our system itself, the Kani Rust Verifier, can be installed from source using the `cargo` build system and a few external dependencies. 
However, to aide in evaluation times and the installation of related tools that we compare against, we have prepared our artifact as a Docker container.

Our Docker instance is based on Ubuntu 20.04 and will be tested on Ubuntu 20.04 and macOS 11.5.2 (and should work as expected on any system with a Docker installation).

## Host system requirements


## Optional: Installing Kani from source

To install Kani itself from source outside of Docker, see the [Kani Installation Guide][kani-install].

[kani-install]: https://model-checking.github.io/kani/install-guide.html