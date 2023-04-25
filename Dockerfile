FROM cartesi/toolchain as toolchain

FROM ubuntu:latest
ENV TOOLS_BASE "/opt/riscv/riscv64-cartesi-linux-gnu"
RUN mkdir -p /opt/riscv
COPY --from=toolchain /opt/riscv/ /opt/riscv/

RUN \
	apt update && \
	apt -y install \
	binutils build-essential libtool texinfo \
	gzip zip unzip patchutils curl git \
	make cmake ninja-build automake bison flex gperf \
	grep sed gawk python3 bc \
	zlib1g-dev libexpat1-dev libmpc-dev \
	libglib2.0-dev libfdt-dev libpixman-1-dev \
	scons \
	pkg-config \
	libx11-dev \
	libxcursor-dev \
	libxinerama-dev \
	libgl1-mesa-dev \
	libglu-dev \
	libasound2-dev \
	libpulse-dev \
	libudev-dev \
	libxi-dev \
	libxrandr-dev

WORKDIR /opt/riscv
RUN git clone https://github.com/llvm/llvm-project.git riscv-llvm
RUN git clone https://github.com/godotengine/godot.git


RUN mkdir -p riscv-llvm/_build
WORKDIR /opt/riscv/riscv-llvm/_build

RUN cmake -G Ninja -DCMAKE_BUILD_TYPE="Debug" \
  -DCMAKE_SYSTEM_NAME=Linux \
  -DCMAKE_C_COMPILER=$TOOLS_BASE/bin/riscv64-cartesi-linux-gnu-gcc \
  -DCMAKE_CXX_COMPILER=$TOOLS_BASE/bin/riscv64-cartesi-linux-gnu-g++ \
  -DCMAKE_INSTALL_PREFIX=$TOOLS_BASE \
  -DDEFAULT_SYSROOT=$TOOLS_BASE \
  -DLLVM_ENABLE_PROJECTS="clang" \
  -DCMAKE_CXX_FLAGS='--sysroot=/opt/riscv/riscv64-cartesi-linux-gnu/riscv64-cartesi-linux-gnu/sysroot -march=rv64ima -mabi=lp64' \
  -DLLVM_DEFAULT_TARGET_TRIPLE="riscv64-cartesi-linux-gnu" \
  -DLLVM_TARGETS_TO_BUILD="RISCV" \
  ../llvm

RUN cmake --build . --target install
ENV SYSROOT=/opt/riscv/riscv64-cartesi-linux-gnu/riscv64-cartesi-linux-gnu/sysroot
ENV SYSINCLUDE=/opt/riscv/riscv64-cartesi-linux-gnu/riscv64-cartesi-linux-gnu/include
RUN ninja install
ENV PATH $TOOLS_BASE/bin:$PATH
WORKDIR /opt/riscv/godot

ENV CCFLAGS="-isysroot $SYSROOT --sysroot=$SYSROOT -isystem $SYSINCLUDE/riscv64-cartesi-linux-gnu -isystem $SYSROOT/usr/include -isystem $SYSINCLUDE"
ENV LINKFLAGS="--sysroot=$SYSROOT"
ENV GODOTFLAGS="use_llvm=yes arch=rv64 dbus=false alsa=false pulseaudio=false use_sowrap=false fontconfig=false udev=false x11=false touch=false"

# RUN scons -Q --debug=explain CCFLAGS="$CCFLAGS" LINKFLAGS="$LINKFLAGS" $GODOTFLAGS