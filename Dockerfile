# Use a recent Ubuntu as the parent image.
FROM ubuntu:20.04

########################### Kani Rust Model Checker ###########################

USER root
# Install some system level dependencies
RUN apt-get update -y && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y sudo git lsb-release universal-ctags time parallel vim emacs

# Clone Kani itself 
RUN git clone -b ae https://github.com/avanhatt/rmc.git
WORKDIR /rmc
RUN git config --global user.email "placeholder"
RUN git config --global user.name "placeholder"
RUN git pull -f

# Install Kani's dependencies, including Python and CBMC dependencies
RUN ./scripts/setup/ubuntu-20.04/install_deps.sh
RUN ./scripts/setup/ubuntu-20.04/install_cbmc.sh
RUN ./scripts/setup/install_viewer.sh 2.6
RUN ./scripts/setup/install_rustup.sh

RUN git submodule update --init --depth 1

# Add .cargo/bin to PATH
ENV RUST_BACKTRACE=1
ENV PATH="/root/.cargo/bin:${PATH}"
RUN rustup default nightly-2022-01-19

RUN cargo --version
RUN cargo clean
RUN cargo build -p kani-compiler

# Build tool for linking Kani pointer restrictions
RUN cargo build --release -p kani-link-restrictions

# Add Kani scripts to path
ENV PATH=/rmc/scripts:$PATH

###########################    Crucible's Crux-mir   ###########################

USER root
WORKDIR /
# Get repo 
RUN git clone https://github.com/GaloisInc/crucible.git
WORKDIR crucible/crux-mir
RUN git checkout 34514237599e2dd6e0ed2b9a895e5dcd52201b7a
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

WORKDIR ../../crux-mir

# Build crux-mir
RUN cabal v2-install exe:crux-mir --overwrite-policy=always

RUN ./translate_libs.sh

WORKDIR ../../

##################### Google's Rust Verification Tools ########################
RUN git clone https://github.com/project-oak/rust-verification-tools.git
WORKDIR rust-verification-tools
RUN git checkout b179e90daa9ec77c2a81b903ff832aaca4f87b5b

# BASE

# Install Debian and Python dependencies
ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get --yes update \
  && apt-get install --no-install-recommends --yes \
  bison \
  build-essential \
  clang-10 \
  clang-format-10 \
  clang-tools-10 \
  clang-11 \
  clang-format-11 \
  clang-tools-11 \
  gcc-multilib \
  g++-7-multilib \
  cmake \
  curl \
  doxygen \
  expect \
  flex \
  git \
  libboost-all-dev \
  libcap-dev \
  libffi-dev \
  libgoogle-perftools-dev \
  libncurses5-dev \
  libsqlite3-dev \
  libssl-dev \
  libtcmalloc-minimal4 \
  lib32stdc++-7-dev \
  libgmp-dev \
  libgmpxx4ldbl \
  lld-10 \
  lld-11 \
  llvm-10 \
  llvm-10-dev \
  llvm-11 \
  llvm-11-dev \
  ncurses-doc \
  ninja-build \
  perl \
  pkg-config \
  python \
  python3 \
  python3-minimal \
  python3-pip \
  subversion \
  sudo \
  unzip \
  wget \
  # Cleanup
  && apt-get clean \
  # Install Python packages
  && pip3 install --no-cache-dir setuptools \
  && pip3 install --no-cache-dir \
    argparse \
    colored \
    lit \
    pyyaml \
    tabulate \
    termcolor \
    toml \
    wllvm \
    numpy


# Placeholder args that are expected to be passed in at image build time.
# See https://code.visualstudio.com/docs/remote/containers-advanced#_creating-a-nonroot-user
ARG USERNAME=usr
ARG USER_UID=1000
ARG USER_GID=${USER_UID}
ENV USER_HOME=/home/${USERNAME}

# Create the specified user and group and add them to sudoers list
#
# Ignore errors if the user or group already exist (it should only happen if the image is being
# built as root, which happens on GCB).
RUN (groupadd --gid=${USER_GID} ${USERNAME} || true) \
  && (useradd --shell=/bin/bash --uid=${USER_UID} --gid=${USER_GID} --create-home ${USERNAME} || true) \
  && echo "${USERNAME}  ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

# SOLVERS
USER ${USERNAME}

# Install minisat solver

RUN mkdir ${USER_HOME}/minisat
WORKDIR ${USER_HOME}/minisat

ARG MINISAT_VERSION=37158a35c62d448b3feccfa83006266e12e5acb7
RUN git clone --no-checkout https://github.com/stp/minisat.git \
  && cd minisat \
  && git checkout ${MINISAT_VERSION} \
  && git submodule init \
  && git submodule update \
  && mkdir build \
  && cd build \
  && cmake .. \
  && make -j4 \
  && sudo make install \
  && make clean

# Install stp solver

RUN mkdir ${USER_HOME}/stp
WORKDIR ${USER_HOME}/stp

ARG STP_VERSION=2.3.3
RUN git clone --no-checkout https://github.com/stp/stp.git \
  && cd stp \
  && git checkout tags/${STP_VERSION} \
  && mkdir build \
  && cd build \
  && cmake .. \
  && make -j4 \
  && sudo make install \
  && make clean

# Install yices solver

RUN mkdir ${USER_HOME}/yices
WORKDIR ${USER_HOME}/yices

ARG YICES_VERSION=2.6.2
RUN curl --location https://yices.csl.sri.com/releases/${YICES_VERSION}/yices-${YICES_VERSION}-x86_64-pc-linux-gnu-static-gmp.tar.gz > yices.tgz \
  && tar xf yices.tgz \
  && rm yices.tgz \
  && cd "yices-${YICES_VERSION}" \
  && sudo ./install-yices \
  && cd .. \
  && rm -r "yices-${YICES_VERSION}"

ENV YICES_DIR=${USER_HOME}/yices/yices-${YICES_VERSION}

# Install the binary version of Z3.
# (Changing this to build from source would be fine - but slow)
#
# The Ubuntu version is a little out of date but that doesn't seem to cause any problems

RUN mkdir ${USER_HOME}/z3
WORKDIR ${USER_HOME}/z3
ARG Z3_VERSION=4.8.7
RUN curl --location https://github.com/Z3Prover/z3/releases/download/z3-${Z3_VERSION}/z3-${Z3_VERSION}-x64-ubuntu-16.04.zip > z3.zip \
  && unzip -q z3.zip \
  && rm z3.zip

ENV Z3_DIR=${USER_HOME}/z3/z3-${Z3_VERSION}-x64-ubuntu-16.04

# KLEE
USER root
WORKDIR ${USER_HOME}
COPY build_scripts build_scripts
RUN chown ${USERNAME} -R build_scripts

USER ${USERNAME}
WORKDIR ${USER_HOME}

ARG GTEST_VERSION=1.7.0
ENV GTEST_DIR=${USER_HOME}/googletest-release-${GTEST_VERSION}
RUN sh build_scripts/build_googletest

ARG UCLIBC_VERSION=klee_uclibc_v1.2

ARG LLVM_VERSION=10
ENV LLVM_VERSION=${LLVM_VERSION}

ARG KLEE_VERSION=c51ffcd377097ee80ec9b0d6f07f8ea583a5aa1d
RUN sh build_scripts/build_klee

# SEAHORN
USER ${USERNAME}
WORKDIR ${USER_HOME}

ARG SEAHORN_VERIFY_C_COMMON_VERSION=70129bf47c421d8283785a8fb13cdb216424ef91
ARG SEAHORN_VERSION=ccdc529f81a02e9236ffa00ff57eef4487f0fc9a

# cargo-verify relies on this variable to find the yaml files
ENV SEAHORN_VERIFY_C_COMMON_DIR=${USER_HOME}/verify-c-common

RUN git clone --no-checkout https://github.com/seahorn/verify-c-common.git ${SEAHORN_VERIFY_C_COMMON_DIR} \
  && cd ${SEAHORN_VERIFY_C_COMMON_DIR} \
  && git checkout ${SEAHORN_VERIFY_C_COMMON_VERSION}

ENV SEAHORN_DIR=${USER_HOME}/seahorn

RUN git clone --no-checkout https://github.com/seahorn/seahorn.git ${SEAHORN_DIR} \
  && cd ${SEAHORN_DIR} \
  && git checkout ${SEAHORN_VERSION}

# Configure, build and install SeaHorn
# Afterwards, clean up large files but not configuration files
# so that RVT developers can easily tweak the configuration and rebuild.
RUN mkdir ${SEAHORN_DIR}/build \
  && cd ${SEAHORN_DIR}/build \
  && cmake \
     # -DCMAKE_VERBOSE_MAKEFILE:BOOL=ON \
     -DCMAKE_INSTALL_PREFIX=run \
     # -DCMAKE_BUILD_TYPE="Debug" \
     -DCMAKE_BUILD_TYPE="Release" \
     -DCMAKE_CXX_COMPILER="clang++-${LLVM_VERSION}" \
     -DCMAKE_C_COMPILER="clang-${LLVM_VERSION}" \
     -DZ3_ROOT=${Z3_DIR} \
     -DYICES2_HOME=${YICES_DIR} \
     -DSEA_ENABLE_LLD="ON" \
     -GNinja \
     -DCMAKE_EXPORT_COMPILE_COMMANDS=1 \
     -DLLVM_DIR=/usr/lib/llvm-${LLVM_VERSION}/lib/cmake/llvm \
     .. \
  && cmake --build . -j4 --target extra \
  && cmake --build . -j4 --target crab \
  && cmake .. \
  && sudo cmake --build . -j4 --target install \
  && sudo cmake --build . --target clean

ENV PATH="${SEAHORN_DIR}/build/run/bin:$PATH"

# RVT itself
# Switch to USERNAME and install tools / set environment
USER ${USERNAME}
WORKDIR ${USER_HOME}
ENV USER=${USERNAME}

ENV PATH="${PATH}:${USER_HOME}/bin"
ENV PATH="${PATH}:${USER_HOME}/.cargo/bin"

# Install rustup
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y

# Install the nightly toolchain - we use it to build some of our tools.
# We do not set it as the default though because we want to use the
# version of rustc and lib{core,std} that we built before
# and, in particular, we have to use a version of rustc that uses LLVM-10.
USER root
RUN rustup toolchain install nightly

# Version of rustc that our tools support
# This is the default
ARG RUSTC_VERSION=nightly-2020-08-03
ENV RUSTC_VERSION=${RUSTC_VERSION}
RUN echo Installing ${RUSTC_VERSION}
RUN rustup toolchain install ${RUSTC_VERSION} --profile=minimal
RUN rustup default ${RUSTC_VERSION}

# Directory we mount RVT repo in
USER root
ENV RVT_DIR=/rust-verification-tools
RUN chown ${USERNAME} -R ${RVT_DIR}
RUN chown ${USERNAME} -R ${USER_HOME}
# USER ${USERNAME}

ENV PATH="${PATH}:${RVT_DIR}/scripts"
ENV PATH="${PATH}:${RVT_DIR}/scripts/bin"

# Create a bashrc file
RUN echo "export PATH=\"${PATH}\":\${PATH}" >> ${USER_HOME}/.bashrc \
  && echo "ulimit -c0" >> ${USER_HOME}/.bashrc

RUN make -C ${RVT_DIR}/runtime TGT=klee
RUN make -C ${RVT_DIR}/runtime TGT=seahorn
RUN make -C ${RVT_DIR}/simd_emulation

# Build tools
RUN mkdir -p ${USER_HOME}/bin
RUN cargo +nightly install --root=${USER_HOME} --path=${RVT_DIR}/rust2calltree
RUN cargo +nightly install --features=llvm${LLVM_VERSION} --root=${USER_HOME} --path=${RVT_DIR}/rvt-patch-llvm
RUN cargo +nightly install --root=${USER_HOME} --path=${RVT_DIR}/cargo-verify

RUN cargo-verify --version

###########################      SMACK - RUST       ###########################
WORKDIR /home/usr
RUN git clone https://github.com/smackers/smack.git
WORKDIR smack
RUN git checkout c7d0694f08cefb422ebcc67c23824727b06b370e
RUN git submodule update --init

ENV SMACKDIR /home/usr/smack

RUN apt-get update && \
      apt-get -y install \
      software-properties-common \
      wget \
      sudo \
      g++

USER usr
ADD --chown=usr . $SMACKDIR

# Set the work directory
WORKDIR $SMACKDIR

# Add appropriate Rust toolchain
RUN rustup install nightly-2021-03-01-x86_64-unknown-linux-gnu

# Build SMACK
RUN sudo bin/build.sh

USER root
# Add envinronment
ENV PATH=/home/usr/smack-deps/corral:$PATH

RUN rustup install nightly-2021-03-01-x86_64-unknown-linux-gnu
RUN smack --version

###########################    Sanity check tools    ###########################
USER root
RUN mkdir /icse22ae-kani
WORKDIR /icse22ae-kani

RUN touch foo.rs
RUN kani --help
# RUN cabal v2-exec -- crux-mir foo.rs
RUN cargo-verify --help
RUN smack --help

###########################    Copy tests    ###########################
COPY tests tests

###########################     Crate data     ###########################

COPY crate-data crate-data

WORKDIR /
# Check out the Rust commit we used.
RUN git clone https://github.com/rust-lang/rust.git
WORKDIR rust
RUN git checkout 0a56eb11fafdd3c9d86c100b6b90505f5f9fdb00
# Configure for debug build.
RUN printf 'profile = "user"\n\
changelog-seen = 2\n\
[rust]\n\
debug-logging = true' >> config.toml
# Dependencies.
RUN apt-get install -y cmake ninja-build
# Build the Rust toolchain.
RUN python3 x.py build --stage 1 -j 40

###########################     Case studies     ###########################

WORKDIR /icse22ae-kani
RUN mkdir case-study-1
WORKDIR case-study-1 
RUN git clone https://github.com/avanhatt/firecracker.git
WORKDIR firecracker
RUN git checkout case-study-1

WORKDIR .. 
RUN git clone https://github.com/avanhatt/vm-superio.git
WORKDIR vm-superio
RUN git checkout is_in_loop_mode_true

WORKDIR /icse22ae-kani
RUN mkdir case-study-2
WORKDIR case-study-2
RUN git clone https://github.com/avanhatt/firecracker.git
WORKDIR firecracker
RUN git checkout case-study-2

###########################     Final landing spot     ###########################

WORKDIR /icse22ae-kani