#!/bin/bash
set -euo pipefail

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

ATTR_VERSION=${ATTR_VERSION:-2.5.2}
ACL_VERSION=${ACL_VERSION:-2.3.2}

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

PROJECTR_ROOT="${PWD}"

mkdir -p "${PWD}/output/downloads"
mkdir -p "${PWD}/output/${TARGET_TRIPLET}_gcc${GCC}"

###############################################################################
#
# Build toolchain
#
###############################################################################
export CT_PREFIX="${PWD}/output/${TARGET_TRIPLET}_gcc${GCC}"
DEFCONFIG="configs/${TARGET_TRIPLET}_gcc${GCC}" ct-ng defconfig
ct-ng -j"$(nproc)" build

###############################################################################
#
# Install attr + acl into sysroot
#
###############################################################################
SYSROOT="${CT_PREFIX}/${TARGET_TRIPLET}/${TARGET_TRIPLET}/sysroot"
TOOLCHAIN_BIN="${CT_PREFIX}/${TARGET_TRIPLET}/bin"

export PATH="${TOOLCHAIN_BIN}:${PATH}"
export CC="${TARGET_TRIPLET}-gcc"
export AR="${TARGET_TRIPLET}-ar"
export RANLIB="${TARGET_TRIPLET}-ranlib"
export STRIP="${TARGET_TRIPLET}-strip"
export PKG_CONFIG=false

BUILD_DIR="${PWD}/output/build-extra"
mkdir -p "${BUILD_DIR}"

chmod -R u+w "${SYSROOT}"
chmod -R u+w "${SYSROOT}/usr"
chmod -R u+w "${SYSROOT}/usr/lib"
chmod -R u+w "${SYSROOT}/usr/include"

download_if_missing() {
  local url="$1"
  local out="$2"

  if [ ! -f "$out" ]; then
    curl -L "$url" -o "$out"
  fi
}

build_attr() {
  cd "${BUILD_DIR}"

  download_if_missing \
    "https://download.savannah.nongnu.org/releases/attr/attr-${ATTR_VERSION}.tar.gz" \
    "${PWD}/../downloads/attr-${ATTR_VERSION}.tar.gz"

  rm -rf "attr-${ATTR_VERSION}"
  tar xf "${PWD}/../downloads/attr-${ATTR_VERSION}.tar.gz"

  cd "attr-${ATTR_VERSION}"

  ./configure \
    --host="${TARGET_TRIPLET}" \
    --prefix=/usr \
    --disable-nls \
    --disable-shared \
    --enable-static

  make -j"$(nproc)"
  make DESTDIR="${SYSROOT}" install

}

build_acl() {
  cd "${BUILD_DIR}"

  download_if_missing \
    "https://download.savannah.nongnu.org/releases/acl/acl-${ACL_VERSION}.tar.gz" \
    "${PWD}/../downloads/acl-${ACL_VERSION}.tar.gz"

  rm -rf "acl-${ACL_VERSION}"
  tar xf "${PWD}/../downloads/acl-${ACL_VERSION}.tar.gz"

  cd "acl-${ACL_VERSION}"

  CPPFLAGS="-I${SYSROOT}/usr/include" \
  CFLAGS="-fPIC --sysroot=${SYSROOT}" \
  LDFLAGS="-L${SYSROOT}/usr/lib -L${SYSROOT}/lib" \
  ./configure \
    --host="${TARGET_TRIPLET}" \
    --prefix=/usr \
    --disable-nls \
    --disable-shared \
    --enable-static

  make -j"$(nproc)"
  make DESTDIR="${SYSROOT}" install

}

build_attr
build_acl

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

SOURCE_EPOCH="$(get_commit_time)"

cd "${PROJECTR_ROOT}"

tar -c \
    --sort=name \
    --mtime="${SOURCE_EPOCH}" \
    --owner=0 \
    --group=0 \
    --numeric-owner \
    -C "output/${TARGET_TRIPLET}_gcc${GCC}" . \
    | gzip -n > "output/${TARGET_TRIPLET}_gcc${GCC}.tar.gz"

cd output
sha256sum "${TARGET_TRIPLET}_gcc${GCC}.tar.gz" > "${TARGET_TRIPLET}_gcc${GCC}.tar.gz.sha256"
cd ..