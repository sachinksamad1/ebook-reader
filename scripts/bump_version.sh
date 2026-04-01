#!/bin/bash

# Extract current version from pubspec.yaml
VERSION_LINE=$(grep "version: " pubspec.yaml)
VERSION=$(echo $VERSION_LINE | cut -d' ' -f2)

# Split version and build number (e.g., 1.0.0+1)
VERSION_BASE=$(echo $VERSION | cut -d'+' -f1)
BUILD_NUMBER=$(echo $VERSION | cut -d'+' -f2)

# Increment build number
NEW_BUILD=$((BUILD_NUMBER + 1))
NEW_VERSION="$VERSION_BASE+$NEW_BUILD"

# Update pubspec.yaml
sed -i "s/version: $VERSION/version: $NEW_VERSION/" pubspec.yaml

# Update CHANGELOG.md
DATE=$(date +%Y-%m-%d)
COMMIT_MSG=$(git log -1 --pretty=%s)

# Insert new version entry at the top of CHANGELOG.md (after the header)
sed -i "/# Changelog/a \\\n## [$NEW_VERSION] - $DATE\n### Changed\n- $COMMIT_MSG" CHANGELOG.md

echo $NEW_VERSION
