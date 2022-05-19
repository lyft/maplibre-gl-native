#!/bin/bash

set -euo pipefail

# Set the version here! This should be updated on every patch and every MapLibre version change.
readonly VERSION_NAME="9.5.2-patch-5"

# Set the artifact ID, artifact name, & artifactory URL here. This shouldn't change.
readonly ARTIFACT_ID="android-sdk"
readonly ARTIFACT_NAME="${ARTIFACT_ID}-${VERSION_NAME}"
readonly ARTIFACTORY_URL="https://artifactory-n.lyft.net/artifactory/local-maven-maplibre-gl-native-private/org/maplibre/gl/${ARTIFACT_ID}/${VERSION_NAME}"

# Set user & password variables
readonly ARTIFACTORY_USER="$CREDENTIALS_ARTIFACTORY_PROD_MAPLIBRE_GLNATIVE_PRIVATE_READWRITE_RELEASES_USER"
readonly ARTIFACTORY_PASS="$CREDENTIALS_ARTIFACTORY_PROD_MAPLIBRE_GLNATIVE_PRIVATE_READWRITE_RELEASES_PASS"

# Echo md5 of artifactory credentials to the log to ensure they are set. Don't log sensitive values here!
echo "ARTIFACTORY_USER=$ARTIFACTORY_USER"
echo "ARTIFACTORY_PASS.MD5=`echo $ARTIFACTORY_PASS | md5sum | cut -f 1 -d ' '`"

# Switch to android directory
cd platform/android

# Create a local.properties file with the SDK directory
echo "sdk.dir=$ANDROID_HOME" > local.properties

# Build the library
BUILDTYPE=Release make apackage

# Create dist directory for uploading to artifactory
mkdir -p "dist/symbols/"

# For debugging: investigate which objdump binaries are available
# find $NDK_HOME -iname "*objdump"

# Use objdump to create symbol mapping files in objdump_files directory
$NDK_HOME/toolchains/arm-linux-androideabi-4.9/prebuilt/linux-x86_64/bin/arm-linux-androideabi-objdump \
    --dwarf=info --dwarf=rawline \
    MapboxGLAndroidSDK/build/intermediates/cmake/release/obj/armeabi-v7a/libmapbox-gl.so \
    | gzip -k \
    > dist/symbols/armeabi-v7a.objdump.gz

$NDK_HOME/toolchains/aarch64-linux-android-4.9/prebuilt/linux-x86_64/bin/aarch64-linux-android-objdump \
    --dwarf=info --dwarf=rawline \
    MapboxGLAndroidSDK/build/intermediates/cmake/release/obj/arm64-v8a/libmapbox-gl.so \
    | gzip -k \
    > dist/symbols/arm64-v8a.objdump.gz

# Create tar file in dist directory from symbol mapping files
tar -cvf "dist/${ARTIFACT_NAME}.tar" "dist/symbols/"

# Update VERSION_NAME property in gradle.properties. Some of this is copied from .github/workflows/android-release.yml
sed -i -e "s/^VERSION_NAME=.*/VERSION_NAME=${VERSION_NAME}/" MapboxGLAndroidSDK/gradle.properties
echo "MapboxGLAndroidSDK/gradle.properties:"
cat MapboxGLAndroidSDK/gradle.properties

# Create pom file
./gradlew generatePomFileForReleasePublication -Pmapbox.abis=all
echo "pom-default.xml:"
cat MapboxGLAndroidSDK/build/publications/release/pom-default.xml

# Copy pom file to dist directory and rename to pom.xml
mv MapboxGLAndroidSDK/build/publications/release/pom-default.xml "dist/${ARTIFACT_NAME}.pom"

# Move library to dist directory
mv MapboxGLAndroidSDK/build/outputs/aar/MapboxGLAndroidSDK-release.aar "dist/${ARTIFACT_NAME}.aar"

# Print contents of dist directory
echo "Printing contents of dist directory:"
ls -a dist

# Uploads an artifact to artifactory using curl
# $1 - Path to the file to upload
# $2 - Destination within artifactory to upload to
function upload_to_artifactory() {
  local -r artifact="$1"
  local -r dst="$2"
  local -r checksum_sha256=$(shasum -a 256 "$artifact" | cut -d ' ' -f 1)

  curl -u "${ARTIFACTORY_USER}:${ARTIFACTORY_PASS}" \
    -X PUT "$dst" \
    --header "X-Checksum-Sha256:$checksum_sha256" \
    -T "$artifact"
}

upload_to_artifactory "dist/${ARTIFACT_NAME}.pom" "${ARTIFACTORY_URL}/${ARTIFACT_NAME}.pom"
upload_to_artifactory "dist/${ARTIFACT_NAME}.aar" "${ARTIFACTORY_URL}/${ARTIFACT_NAME}.aar"
upload_to_artifactory "dist/${ARTIFACT_NAME}.tar" "${ARTIFACTORY_URL}/${ARTIFACT_NAME}.tar"
