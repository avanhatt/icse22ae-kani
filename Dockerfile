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
WORKDIR ..

###########################    Crucible's Crux-mir   ###########################

# Get repo 
RUN git clone https://github.com/GaloisInc/crucible.git
WORKDIR crucible/crux-mir
RUN git checkout 91b989217bdef55b89742a24fb12885e9a9fe3c6
RUN git submodule update --init

# Add Haskell/cabal
RUN curl --proto '=https' --tlsv1.2 -sSf https://get-ghcup.haskell.org | sh

# Add cabal to PATH
ENV PATH="/root/.ghcup/bin/:${PATH}"
RUN cabal update

# Install GHC
RUN bash -c "ghcup upgrade"
RUN bash -c "ghcup install cabal 3.4.0.0"
RUN bash -c "ghcup set cabal 3.4.0.0"
RUN bash -c "ghcup install ghc 8.10.7"
RUN bash -c "ghcup set ghc 8.10.7"

# More system dependenices
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y libgmp3-dev libtinfo-dev

# Build mir-json
WORKDIR ../dependencies/mir-json
RUN rustup toolchain install nightly-2020-03-22 --force
RUN rustup component add --toolchain nightly-2020-03-22 rustc-dev
RUN rustup default nightly-2020-03-22
RUN cargo install --locked
RUN mir-json --version

WORKDIR ../../crux-mmir

# Build crux-mir
RUN cabal v2-install exe:crux-mir --overwrite-policy=always

##################### Google's Rust Verification Tools ########################