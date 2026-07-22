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

# Use a base image
FROM ubuntu:24.04

# crosstool-NG version. Defined once in docker_build_and_run.sh (TAG) and passed
# in via --build-arg VERSION=...; intentionally has no default so the version
# lives in a single place and cannot drift between the two files.
ARG VERSION

# Set non-interactive environment variables to avoid prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive
ENV DEBCONF_NONINTERACTIVE_SEEN=true

# Set timezone
RUN { echo 'tzdata tzdata/Areas select Etc'; echo 'tzdata tzdata/Zones/Etc select UTC'; } | debconf-set-selections

# Install required dependencies (without prompts)
RUN apt-get update && apt-get install -y \
    autoconf \
    automake \
    bison \
    bzip2 \
    flex \
    g++ \
    gawk \
    gcc \
    git \
    gperf \
    help2man \
    libncurses5-dev \
    libstdc++6 \
    libtool \
    libtool-bin \
    make \
    meson \
    ninja-build \
    patch \
    python3-dev \
    rsync \
    texinfo \
    unzip \
    wget \
    xz-utils

# Fail early with a clear message if the version was not supplied.
RUN test -n "${VERSION}" || { echo "ERROR: build-arg VERSION is required, e.g. --build-arg VERSION=1.28.0"; exit 1; }

# Download the version of Crosstool-NG and unpackage the archive
RUN wget "http://crosstool-ng.org/download/crosstool-ng/crosstool-ng-${VERSION}.tar.bz2"
RUN mkdir ctng && tar -xf crosstool-ng-${VERSION}.tar.bz2 --strip-components=1 -C ctng

# The ct-ng has only one major version so we have to move the 12.5.0 to 12.2.0 to match the version of the toolchain we are building.
RUN mv /ctng/packages/gcc/12.5.0 /ctng/packages/gcc/12.2.0
RUN rm -rf /ctng/packages/gcc/12.2.0/chksum
COPY additional_packages/gcc/12.2.0/chksum /ctng/packages/gcc/12.2.0/chksum

RUN mv /ctng/packages/gcc/15.2.0 /ctng/packages/gcc/15.3.0
RUN rm -rf /ctng/packages/gcc/15.3.0/chksum
COPY additional_packages/gcc/15.3.0/chksum /ctng/packages/gcc/15.3.0/chksum

# binutils
COPY additional_packages/binutils/2.46.1 /ctng/packages/binutils/2.46.1

# glibc
COPY additional_packages/glibc/2.43 /ctng/packages/glibc/2.43

#linux-kernel
COPY additional_packages/linux/7.1.4 /ctng/packages/linux/7.1.4

# Teach the kernel.org mirror resolver about Linux 7.x. In ct-ng 1.28.0 the
# CT_Mirrors version glob only matches 3.x-6.x ([3456].*), so a 7.x version
# resolves to "-unknown-" and the download aborts. Widen it to [34567].* so
# CT_LINUX_MIRRORS defaults to https://cdn.kernel.org/pub/linux/kernel/v7.x
# (this matches the fix later applied upstream).
RUN sed -i 's/\[3456\]\.\*)/[34567].*)/' /ctng/scripts/functions

# Install the crosstool-ng tool
RUN cd ctng && \
    ./bootstrap && \
    ./configure --prefix=/usr/local && \
    make && \
    make install

# Remove archive and install directory
RUN rm -rf crosstool-ng-${VERSION}.tar.bz2
RUN rm -rf ctng
