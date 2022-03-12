#!/bin/bash

echo "Running build-android.sh"

# Switch to android directory
cd platform/android

# Create a local.properties file with the SDK directory
echo "sdk.dir=$ANDROID_HOME" > local.properties

# Build the library
BUILDTYPE=Release make apackage
