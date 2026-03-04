#!/bin/bash
set -e

# *******************************************************************************
# Copyright (c) 2025 Contributors to the Eclipse Foundation
#
# See the NOTICE file(s) distributed with this work for additional
# information regarding copyright ownership.
#
# This program and the accompanying materials are made available under the
# terms of the Apache License Version 2.0 which is available at
# https://www.apache.org/licenses/LICENSE-2.0
#
# SPDX-License-Identifier: Apache-2.0
# *******************************************************************************

export GCC=${GCC:?Please set GCC variable to desired gcc major version}
export ARCH=${ARCH:-x86_64}

# Map architecture to target triplet
case $ARCH in
  x86_64)
    TARGET_TRIPLET="x86_64-unknown-linux-gnu"
    ;;
  arm64|aarch64)
    TARGET_TRIPLET="aarch64-unknown-linux-gnu"
    ;;
  *)
    echo "Unsupported architecture: $ARCH"
    echo "Supported architectures: x86_64, arm64/aarch64"
    exit 1
    ;;
esac

mkdir -p ${PWD}/output/downloads
mkdir -p ${PWD}/output/${TARGET_TRIPLET}_gcc${GCC}

###############################################################################
#
# Build
#
###############################################################################
# export CT_PREFIX="${PWD}/output/${TARGET_TRIPLET}_gcc${GCC}"
# DEFCONFIG=configs/${TARGET_TRIPLET}_gcc${GCC} ct-ng defconfig
# ct-ng -j$(nproc) build

###############################################################################
#
# Package
#
###############################################################################
function get_commit_time() {
  TZ=UTC0 git log -1 \
    --format=tformat:%cd \
    --date=format:%Y-%m-%dT%H:%M:%SZ
}

SOURCE_EPOCH=$get_commit_time


chmod -R a+w output/${TARGET_TRIPLET}_gcc${GCC}/
cp third_party/aborts_upon_exceptiion/libs/linux/${ARCH}/libabortsuponexception.a output/${TARGET_TRIPLET}_gcc${GCC}/${TARGET_TRIPLET}/${TARGET_TRIPLET}/sysroot/lib/
cp third_party/aborts_upon_exceptiion/libs/linux/${ARCH}/libabortsuponexception.so output/${TARGET_TRIPLET}_gcc${GCC}/${TARGET_TRIPLET}/${TARGET_TRIPLET}/sysroot/lib/
ln -s ../../${TARGET_TRIPLET}/sysroot/lib64/libabortsuponexception.a output/${TARGET_TRIPLET}_gcc${GCC}/${TARGET_TRIPLET}/${TARGET_TRIPLET}/lib64/libabortsuponexception.a
ln -s ../../${TARGET_TRIPLET}/sysroot/lib64/libabortsuponexception.so output/${TARGET_TRIPLET}_gcc${GCC}/${TARGET_TRIPLET}/${TARGET_TRIPLET}/lib64/libabortsuponexception.so
chmod -R a-w output/${TARGET_TRIPLET}_gcc${GCC}/

tar -c \
    --sort=name \
    --mtime="${SOURCE_EPOCH}" \
    --owner=0 \
    --group=0 \
    --numeric-owner \
    -C "output/${TARGET_TRIPLET}_gcc${GCC}" . \
    | gzip -n > "output/${TARGET_TRIPLET}_gcc${GCC}.tar.gz"
    
cd output
sha256sum ${TARGET_TRIPLET}_gcc${GCC}.tar.gz > ${TARGET_TRIPLET}_gcc${GCC}.tar.gz.sha256
cd ..    
