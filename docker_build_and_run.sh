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

# Define the repository name (hardcoded)
REPO="ctng-image"

# Define the tag name (set Crosstool-NG version)
TAG="1.28.0"

# Define the full name (e.g. "ctng-image:1.27.0")
FULL_IMAGE_NAME="${REPO}:${TAG}"

# Build the Docker image
docker build --build-arg VERSION=$TAG -t $FULL_IMAGE_NAME .

# Check if the build was successful
if [ $? -eq 0 ]; then
    echo "Image $FULL_IMAGE_NAME built successfully!"
else
    echo "Failed to build $FULL_IMAGE_NAME."
    exit 1
fi

# Parse command line arguments
ARCH=${1:-x86_64}
GCC_VERSION=${2:-12}

echo "Building toolchain for architecture: $ARCH with GCC version: $GCC_VERSION"

# Check if we're in a CI environment
if [ -n "$CI" ] || [ ! -t 0 ]; then
    # CI environment - no interactive/tty
    docker run --rm --user "$(id -u):$(id -g)" -v ${PWD}:/workspace $FULL_IMAGE_NAME /bin/bash -c "
        set -e
        cd /workspace
        GCC=$GCC_VERSION ARCH=$ARCH ./build.sh
    "
else
    # Local development - interactive mode
    docker run --rm -it --user "$(id -u):$(id -g)" -v ${PWD}:/workspace $FULL_IMAGE_NAME /bin/bash -c "
        set -e
        cd /workspace
        GCC=$GCC_VERSION ARCH=$ARCH ./build.sh
    "
fi
