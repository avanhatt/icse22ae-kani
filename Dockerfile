# Use a recent Rust as the parent image.
FROM ubuntu:20.04

########################### Kani Rust Model Checker ###########################

# Install some system level dependencies
RUN apt-get update -y && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y sudo git lsb-release universal-ctags

# Clone Kani itself 
# TODO: clone specifc branch/tag
RUN git clone -b ae https://github.com/avanhatt/rmc.git
WORKDIR rmc
RUN git submodule update --init

# Install Kani's dependencies, including Python and CBMC dependencies
RUN ./scripts/setup/ubuntu-20.04/install_deps.sh
RUN ./scripts/setup/ubuntu-20.04/install_cbmc.sh
RUN ./scripts/setup/install_viewer.sh 2.6
RUN ./scripts/setup/install_rustup.sh

# Add .cargo/bin to PATH
ENV PATH="/root/.cargo/bin:${PATH}"

RUN ./configure \
    --enable-debug \
    --set=llvm.download-ci-llvm=true \
    --set=rust.debug-assertions-std=false \
    --set=rust.deny-warnings=false

WORKDIR src/kani-compiler
RUN cargo build

WORKDIR ../..

# Build tool for linking Kani pointer restrictions
RUN cargo build --release --manifest-path src/tools/kani-link-restrictions/Cargo.toml

###########################    Crucible's Crux-mir   ###########################