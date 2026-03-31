#!/usr/bin/env /tmp/kopi-tools/bin/python3
"""Add a Swift file to the Kopi Xcode project target.

Usage: ./scripts/add-to-xcode.py <relative-path-from-Kopi-dir> [target]

Examples:
    ./scripts/add-to-xcode.py Kopi/Models/ClipboardItem.swift
    ./scripts/add-to-xcode.py KopiTests/MyTests.swift KopiTests
"""
import sys
from pbxproj import XcodeProject

PROJECT_PATH = '/Users/eduardo/Projects/Personal/Repositories/kopi-app/Kopi/Kopi.xcodeproj/project.pbxproj'

def add_file(relative_path, target_name='Kopi'):
    project = XcodeProject.load(PROJECT_PATH)

    # Check if file already exists in project
    filename = relative_path.split('/')[-1]
    existing = project.get_files_by_name(filename)
    if existing:
        print(f"SKIP: {filename} already in project")
        return True

    result = project.add_file(relative_path, target_name=target_name)
    if result:
        project.save()
        print(f"ADDED: {relative_path} -> {target_name}")
        return True
    else:
        print(f"FAILED: Could not add {relative_path}")
        return False

if __name__ == '__main__':
    if len(sys.argv) < 2:
        print(__doc__)
        sys.exit(1)

    path = sys.argv[1]
    target = sys.argv[2] if len(sys.argv) > 2 else 'Kopi'
    success = add_file(path, target)
    sys.exit(0 if success else 1)
