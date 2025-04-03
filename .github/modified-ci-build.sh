#!/bin/sh

PACKAGE_VERSION="$1"

NDK_VER=r20
curl -LOs https://dl.google.com/android/repository/android-ndk-${NDK_VER}-linux-x86_64.zip
unzip -q android-ndk-${NDK_VER}-linux-x86_64.zip -d ${HOME}
rm android-ndk-${NDK_VER}-linux-x86_64.zip
NDK_TOOLS=${HOME}/android-ndk-${NDK_VER}
export PATH=${PATH}:${NDK_TOOLS}/toolchains/llvm/prebuilt/linux-x86_64/bin

build_android() {
    ARCH=$1
    CC=$2
    CXX=$3
    GOARCH=$4

    go clean
    env CC=${CC} CXX=${CXX} CGO_ENABLED=1 GOOS=android GOARCH=${GOARCH} go build -mod vendor -ldflags="-s -w"
    mv dnscrypt-proxy dnscrypt-proxy-${ARCH}
}

build_android "arm" "armv7a-linux-androideabi19-clang" "armv7a-linux-androideabi19-clang++" "arm"
build_android "arm64" "aarch64-linux-android21-clang" "aarch64-linux-android21-clang++" "arm64"
build_android "i386" "i686-linux-android19-clang" "i686-linux-android19-clang++" "386"
build_android "x86_64" "x86_64-linux-android21-clang" "x86_64-linux-android21-clang++" "amd64"

rm -rf ${NDK_TOOLS}
