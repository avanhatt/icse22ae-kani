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
# NOTE: currently failing
# RUN cabal v2-install exe:crux-mir --overwrite-policy=always

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
    wllvm


# Placeholder args that are expected to be passed in at image build time.
# See https://code.visualstudio.com/docs/remote/containers-advanced#_creating-a-nonroot-user
ARG USERNAME=user-name-goes-here
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

# # Install minisat solver

# RUN mkdir ${USER_HOME}/minisat
# WORKDIR ${USER_HOME}/minisat

# ARG MINISAT_VERSION
# RUN git clone --no-checkout https://github.com/stp/minisat.git \
#   && cd minisat \
#   && git checkout ${MINISAT_VERSION} \
#   && git submodule init \
#   && git submodule update \
#   && mkdir build \
#   && cd build \
#   && cmake .. \
#   && make -j4 \
#   && sudo make install \
#   && make clean

# # Install stp solver

# RUN mkdir ${USER_HOME}/stp
# WORKDIR ${USER_HOME}/stp

# ARG STP_VERSION
# RUN git clone --no-checkout https://github.com/stp/stp.git \
#   && cd stp \
#   && git checkout tags/${STP_VERSION} \
#   && mkdir build \
#   && cd build \
#   && cmake .. \
#   && make -j4 \
#   && sudo make install \
#   && make clean

# # Install yices solver

# RUN mkdir ${USER_HOME}/yices
# WORKDIR ${USER_HOME}/yices

# ARG YICES_VERSION
# RUN curl --location https://yices.csl.sri.com/releases/${YICES_VERSION}/yices-${YICES_VERSION}-x86_64-pc-linux-gnu-static-gmp.tar.gz > yices.tgz \
#   && tar xf yices.tgz \
#   && rm yices.tgz \
#   && cd "yices-${YICES_VERSION}" \
#   && sudo ./install-yices \
#   && cd .. \
#   && rm -r "yices-${YICES_VERSION}"

# ENV YICES_DIR=${USER_HOME}/yices/yices-${YICES_VERSION}

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
COPY build_googletest .
COPY build_klee .
RUN chown ${USERNAME} -R build_googletest build_klee

USER ${USERNAME}
WORKDIR ${USER_HOME}

ARG GTEST_VERSION=1.7.0
ENV GTEST_DIR=${USER_HOME}/googletest-release-${GTEST_VERSION}
RUN sh build_googletest

ARG UCLIBC_VERSION=klee_uclibc_v1.2

ARG LLVM_VERSION=10
ENV LLVM_VERSION=${LLVM_VERSION}

ARG KLEE_VERSION=c51ffcd377097ee80ec9b0d6f07f8ea583a5aa1d
RUN sh build_klee