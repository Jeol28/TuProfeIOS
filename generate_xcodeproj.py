#!/usr/bin/env python3
"""
Generates TuProfeIOS.xcodeproj/project.pbxproj from the source tree.
Run: python3 generate_xcodeproj.py
"""

import os
import uuid
import json

PROJECT_DIR = os.path.dirname(os.path.abspath(__file__))
SOURCE_ROOT = os.path.join(PROJECT_DIR, "TuProfeIOS")
OUTPUT_DIR = os.path.join(PROJECT_DIR, "TuProfeIOS.xcodeproj")
OUTPUT_FILE = os.path.join(OUTPUT_DIR, "project.pbxproj")

def make_uuid():
    return uuid.uuid4().hex.upper()[:24]

# Collect all source files
swift_files = []
resource_files = []

for root, dirs, files in os.walk(SOURCE_ROOT):
    # Skip Supporting folder source files (they're handled separately)
    for f in sorted(files):
        path = os.path.join(root, f)
        rel = os.path.relpath(path, PROJECT_DIR)
        if f.endswith('.swift'):
            swift_files.append((f, rel, path))
        elif f in ['GoogleService-Info.plist', 'Info.plist']:
            resource_files.append((f, rel, path))

# Assign UUIDs
file_refs = {}    # filename -> fileRef UUID
build_files = {}  # filename -> buildFile UUID

for name, rel, path in swift_files + resource_files:
    file_refs[rel] = make_uuid()
    build_files[rel] = make_uuid()

# Project-level UUIDs
PROJECT_UUID = make_uuid()
MAIN_GROUP_UUID = make_uuid()
PRODUCTS_GROUP_UUID = make_uuid()
TARGET_UUID = make_uuid()
SOURCES_BUILD_PHASE = make_uuid()
RESOURCES_BUILD_PHASE = make_uuid()
FRAMEWORKS_BUILD_PHASE = make_uuid()
DEBUG_CONFIG_UUID = make_uuid()
RELEASE_CONFIG_UUID = make_uuid()
DEBUG_PROJECT_CONFIG = make_uuid()
RELEASE_PROJECT_CONFIG = make_uuid()
PROJECT_CONFIG_LIST = make_uuid()
TARGET_CONFIG_LIST = make_uuid()
PRODUCT_REF = make_uuid()

BUNDLE_ID = "com.tuprofe.ios"
PRODUCT_NAME = "TuProfeIOS"
MIN_IOS = "16.0"
SWIFT_VERSION = "5.9"

def generate():
    os.makedirs(OUTPUT_DIR, exist_ok=True)

    # Build group structure
    # We'll create groups based on directory structure
    groups = {}  # dir_path -> UUID

    def get_group_uuid(dir_path):
        if dir_path not in groups:
            groups[dir_path] = make_uuid()
        return groups[dir_path]

    # Pre-assign group UUIDs
    for name, rel, path in swift_files + resource_files:
        dir_path = os.path.dirname(rel)
        get_group_uuid(dir_path)

    lines = []
    lines.append("// !$*UTF8*$!")
    lines.append("{")
    lines.append("\tarchiveVersion = 1;")
    lines.append("\tclasses = {")
    lines.append("\t};")
    lines.append("\tobjectVersion = 56;")
    lines.append("\tobjects = {")
    lines.append("")

    # PBXBuildFile
    lines.append("/* Begin PBXBuildFile section */")
    for name, rel, path in swift_files:
        lines.append(f'\t\t{build_files[rel]} /* {name} in Sources */ = {{isa = PBXBuildFile; fileRef = {file_refs[rel]} /* {name} */; }};')
    for name, rel, path in resource_files:
        if name == 'GoogleService-Info.plist':
            lines.append(f'\t\t{build_files[rel]} /* {name} in Resources */ = {{isa = PBXBuildFile; fileRef = {file_refs[rel]} /* {name} */; }};')
    lines.append("/* End PBXBuildFile section */")
    lines.append("")

    # PBXFileReference
    lines.append("/* Begin PBXFileReference section */")
    lines.append(f'\t\t{PRODUCT_REF} /* {PRODUCT_NAME}.app */ = {{isa = PBXFileReference; explicitFileType = wrapper.application; includeInIndex = 0; path = {PRODUCT_NAME}.app; sourceTree = BUILT_PRODUCTS_DIR; }};')
    for name, rel, path in swift_files:
        lines.append(f'\t\t{file_refs[rel]} /* {name} */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = {name}; sourceTree = "<group>"; }};')
    for name, rel, path in resource_files:
        lines.append(f'\t\t{file_refs[rel]} /* {name} */ = {{isa = PBXFileReference; lastKnownFileType = text.plist.xml; path = {name}; sourceTree = "<group>"; }};')
    lines.append("/* End PBXFileReference section */")
    lines.append("")

    # PBXGroup - build a hierarchy
    # Group all files by their parent directory
    dir_children = {}  # dir -> list of (name, rel)
    for name, rel, path in swift_files + resource_files:
        parent = os.path.dirname(rel)
        if parent not in dir_children:
            dir_children[parent] = []
        dir_children[parent].append((name, rel))

    # Build dir hierarchy
    dir_parents = {}
    for d in dir_children:
        parts = d.split(os.sep)
        for i in range(1, len(parts)):
            child = os.sep.join(parts[:i+1])
            parent = os.sep.join(parts[:i])
            dir_parents[child] = parent
            get_group_uuid(parent)

    lines.append("/* Begin PBXGroup section */")

    # Main group
    top_dirs = set()
    for d in dir_children:
        top = d.split(os.sep)[0]
        top_dirs.add(top)

    # Collect direct children of TuProfeIOS root
    tu_profe_subdirs = set()
    for d in dir_children:
        if os.sep in d:
            first_level = os.sep.join(d.split(os.sep)[:2])
            tu_profe_subdirs.add(first_level)
        else:
            tu_profe_subdirs.add(d)

    lines.append(f'\t\t{MAIN_GROUP_UUID} = {{')
    lines.append('\t\t\tisa = PBXGroup;')
    lines.append('\t\t\tchildren = (')
    lines.append(f'\t\t\t\t{get_group_uuid("TuProfeIOS")} /* TuProfeIOS */,')
    lines.append(f'\t\t\t\t{PRODUCTS_GROUP_UUID} /* Products */,')
    lines.append('\t\t\t);')
    lines.append('\t\t\tsourceTree = "<group>";')
    lines.append('\t\t};')

    lines.append(f'\t\t{PRODUCTS_GROUP_UUID} = {{')
    lines.append('\t\t\tisa = PBXGroup;')
    lines.append('\t\t\tchildren = (')
    lines.append(f'\t\t\t\t{PRODUCT_REF} /* {PRODUCT_NAME}.app */,')
    lines.append('\t\t\t);')
    lines.append('\t\t\tname = Products;')
    lines.append('\t\t\tsourceTree = "<group>";')
    lines.append('\t\t};')

    # Write all groups
    # Find all unique directories
    all_dirs = set()
    for name, rel, path in swift_files + resource_files:
        d = os.path.dirname(rel)
        while d:
            all_dirs.add(d)
            d = os.path.dirname(d)
            if not d or d == '.':
                break

    for d in sorted(all_dirs):
        uuid_d = get_group_uuid(d)
        basename = os.path.basename(d)
        lines.append(f'\t\t{uuid_d} /* {basename} */ = {{')
        lines.append('\t\t\tisa = PBXGroup;')
        lines.append('\t\t\tchildren = (')

        # Direct sub-directories
        for other_d in sorted(all_dirs):
            if os.path.dirname(other_d) == d:
                lines.append(f'\t\t\t\t{get_group_uuid(other_d)} /* {os.path.basename(other_d)} */,')

        # Files in this directory
        for name, rel, path in sorted(swift_files + resource_files, key=lambda x: x[0]):
            if os.path.dirname(rel) == d:
                lines.append(f'\t\t\t\t{file_refs[rel]} /* {name} */,')

        lines.append('\t\t\t);')
        lines.append(f'\t\t\tpath = {basename};')
        lines.append('\t\t\tsourceTree = "<group>";')
        lines.append('\t\t};')

    lines.append("/* End PBXGroup section */")
    lines.append("")

    # PBXNativeTarget
    lines.append("/* Begin PBXNativeTarget section */")
    lines.append(f'\t\t{TARGET_UUID} /* {PRODUCT_NAME} */ = {{')
    lines.append('\t\t\tisa = PBXNativeTarget;')
    lines.append('\t\t\tbuildConfigurationList = ' + TARGET_CONFIG_LIST + ' /* Build configuration list for PBXNativeTarget "{}" */;'.format(PRODUCT_NAME))
    lines.append('\t\t\tbuildPhases = (')
    lines.append(f'\t\t\t\t{SOURCES_BUILD_PHASE} /* Sources */,')
    lines.append(f'\t\t\t\t{FRAMEWORKS_BUILD_PHASE} /* Frameworks */,')
    lines.append(f'\t\t\t\t{RESOURCES_BUILD_PHASE} /* Resources */,')
    lines.append('\t\t\t);')
    lines.append('\t\t\tbuildRules = (')
    lines.append('\t\t\t);')
    lines.append('\t\t\tdependencies = (')
    lines.append('\t\t\t);')
    lines.append(f'\t\t\tname = {PRODUCT_NAME};')
    lines.append(f'\t\t\tproductName = {PRODUCT_NAME};')
    lines.append(f'\t\t\tproductReference = {PRODUCT_REF} /* {PRODUCT_NAME}.app */;')
    lines.append('\t\t\tproductType = "com.apple.product-type.application";')
    lines.append('\t\t};')
    lines.append("/* End PBXNativeTarget section */")
    lines.append("")

    # PBXProject
    lines.append("/* Begin PBXProject section */")
    lines.append(f'\t\t{PROJECT_UUID} /* Project object */ = {{')
    lines.append('\t\t\tisa = PBXProject;')
    lines.append('\t\t\tattributes = {')
    lines.append('\t\t\t\tBuildIndependentTargetsInParallel = 1;')
    lines.append('\t\t\t\tLastSwiftUpdateCheck = 1500;')
    lines.append('\t\t\t\tLastUpgradeCheck = 1500;')
    lines.append('\t\t\t\tTargetAttributes = {')
    lines.append(f'\t\t\t\t\t{TARGET_UUID} = {{')
    lines.append('\t\t\t\t\t\tCreatedOnToolsVersion = 15.0;')
    lines.append('\t\t\t\t\t};')
    lines.append('\t\t\t\t};')
    lines.append('\t\t\t};')
    lines.append(f'\t\t\tbuildConfigurationList = {PROJECT_CONFIG_LIST} /* Build configuration list for PBXProject "{PRODUCT_NAME}" */;')
    lines.append('\t\t\tcompatibilityVersion = "Xcode 14.0";')
    lines.append('\t\t\tdevelopmentRegion = es;')
    lines.append('\t\t\thasScannedForEncodings = 0;')
    lines.append('\t\t\tknownRegions = (')
    lines.append('\t\t\t\tes,')
    lines.append('\t\t\t\tBase,')
    lines.append('\t\t\t);')
    lines.append(f'\t\t\tmainGroup = {MAIN_GROUP_UUID};')
    lines.append(f'\t\t\tproductRefGroup = {PRODUCTS_GROUP_UUID} /* Products */;')
    lines.append('\t\t\tprojectDirPath = "";')
    lines.append('\t\t\tprojectRoot = "";')
    lines.append('\t\t\ttargets = (')
    lines.append(f'\t\t\t\t{TARGET_UUID} /* {PRODUCT_NAME} */,')
    lines.append('\t\t\t);')
    lines.append('\t\t};')
    lines.append("/* End PBXProject section */")
    lines.append("")

    # PBXResourcesBuildPhase
    lines.append("/* Begin PBXResourcesBuildPhase section */")
    lines.append(f'\t\t{RESOURCES_BUILD_PHASE} /* Resources */ = {{')
    lines.append('\t\t\tisa = PBXResourcesBuildPhase;')
    lines.append('\t\t\tbuildActionMask = 2147483647;')
    lines.append('\t\t\tfiles = (')
    for name, rel, path in resource_files:
        if name == 'GoogleService-Info.plist':
            lines.append(f'\t\t\t\t{build_files[rel]} /* {name} in Resources */,')
    lines.append('\t\t\t);')
    lines.append('\t\t\trunOnlyForDeploymentPostprocessing = 0;')
    lines.append('\t\t};')
    lines.append("/* End PBXResourcesBuildPhase section */")
    lines.append("")

    # PBXSourcesBuildPhase
    lines.append("/* Begin PBXSourcesBuildPhase section */")
    lines.append(f'\t\t{SOURCES_BUILD_PHASE} /* Sources */ = {{')
    lines.append('\t\t\tisa = PBXSourcesBuildPhase;')
    lines.append('\t\t\tbuildActionMask = 2147483647;')
    lines.append('\t\t\tfiles = (')
    for name, rel, path in swift_files:
        lines.append(f'\t\t\t\t{build_files[rel]} /* {name} in Sources */,')
    lines.append('\t\t\t);')
    lines.append('\t\t\trunOnlyForDeploymentPostprocessing = 0;')
    lines.append('\t\t};')
    lines.append("/* End PBXSourcesBuildPhase section */")
    lines.append("")

    # PBXFrameworksBuildPhase
    lines.append("/* Begin PBXFrameworksBuildPhase section */")
    lines.append(f'\t\t{FRAMEWORKS_BUILD_PHASE} /* Frameworks */ = {{')
    lines.append('\t\t\tisa = PBXFrameworksBuildPhase;')
    lines.append('\t\t\tbuildActionMask = 2147483647;')
    lines.append('\t\t\tfiles = (')
    lines.append('\t\t\t);')
    lines.append('\t\t\trunOnlyForDeploymentPostprocessing = 0;')
    lines.append('\t\t};')
    lines.append("/* End PBXFrameworksBuildPhase section */")
    lines.append("")

    # XCBuildConfiguration
    base_settings = f"""ALWAYS_SEARCH_USER_PATHS = NO;
\t\t\t\tCLANG_ANALYZER_NONNULL = YES;
\t\t\t\tCLANG_ANALYZER_NUMBER_OBJECT_CONVERSION = YES_AGGRESSIVE;
\t\t\t\tCLANG_CXX_LANGUAGE_STANDARD = "gnu++20";
\t\t\t\tCLANG_ENABLE_MODULES = YES;
\t\t\t\tCLANG_ENABLE_OBJC_ARC = YES;
\t\t\t\tCLANG_ENABLE_OBJC_WEAK = YES;
\t\t\t\tCLANG_WARN_BLOCK_CAPTURE_AUTORELEASING = YES;
\t\t\t\tCLANG_WARN_BOOL_CONVERSION = YES;
\t\t\t\tCLANG_WARN_COMMA = YES;
\t\t\t\tCLANG_WARN_CONSTANT_CONVERSION = YES;
\t\t\t\tCLANG_WARN_DEPRECATED_OBJC_IMPLEMENTATIONS = YES;
\t\t\t\tCLANG_WARN_DIRECT_OBJC_ISA_USAGE = YES_ERROR;
\t\t\t\tCLANG_WARN_DOCUMENTATION_COMMENTS = YES;
\t\t\t\tCLANG_WARN_EMPTY_BODY = YES;
\t\t\t\tCLANG_WARN_ENUM_CONVERSION = YES;
\t\t\t\tCLANG_WARN_INFINITE_RECURSION = YES;
\t\t\t\tCLANG_WARN_INT_CONVERSION = YES;
\t\t\t\tCLANG_WARN_NON_LITERAL_NULL_CONVERSION = YES;
\t\t\t\tCLANG_WARN_OBJC_IMPLICIT_RETAIN_SELF = YES;
\t\t\t\tCLANG_WARN_OBJC_LITERAL_CONVERSION = YES;
\t\t\t\tCLANG_WARN_OBJC_ROOT_CLASS = YES_ERROR;
\t\t\t\tCLANG_WARN_QUOTED_INCLUDE_IN_FRAMEWORK_HEADER = YES;
\t\t\t\tCLANG_WARN_RANGE_LOOP_ANALYSIS = YES;
\t\t\t\tCLANG_WARN_STRICT_PROTOTYPES = YES;
\t\t\t\tCLANG_WARN_SUSPICIOUS_MOVE = YES;
\t\t\t\tCLANG_WARN_UNGUARDED_AVAILABILITY = YES_AGGRESSIVE;
\t\t\t\tCLANG_WARN_UNREACHABLE_CODE = YES;
\t\t\t\tCLANG_WARN__DUPLICATE_METHOD_MATCH = YES;
\t\t\t\tCOPY_PHASE_STRIP = NO;
\t\t\t\tDEBUG_INFORMATION_FORMAT = dwarf;
\t\t\t\tENABLE_STRICT_OBJC_MSGSEND = YES;
\t\t\t\tENABLE_TESTABILITY = YES;
\t\t\t\tGCC_C_LANGUAGE_STANDARD = gnu17;
\t\t\t\tGCC_DYNAMIC_NO_PIC = NO;
\t\t\t\tGCC_NO_COMMON_BLOCKS = YES;
\t\t\t\tGCC_OPTIMIZATION_LEVEL = 0;
\t\t\t\tGCC_PREPROCESSOR_DEFINITIONS = ("DEBUG=1", "$(inherited)",);
\t\t\t\tGCC_WARN_64_TO_32_BIT_CONVERSION = YES;
\t\t\t\tGCC_WARN_ABOUT_RETURN_TYPE = YES_ERROR;
\t\t\t\tGCC_WARN_UNDECLARED_SELECTOR = YES;
\t\t\t\tGCC_WARN_UNINITIALIZED_AUTOS = YES_AGGRESSIVE;
\t\t\t\tGCC_WARN_UNUSED_FUNCTION = YES;
\t\t\t\tGCC_WARN_UNUSED_VARIABLE = YES;
\t\t\t\tIPHONEOS_DEPLOYMENT_TARGET = {MIN_IOS};
\t\t\t\tMTL_ENABLE_DEBUG_INFO = INCLUDE_SOURCE;
\t\t\t\tMTL_FAST_MATH = YES;
\t\t\t\tONLY_ACTIVE_ARCH = YES;
\t\t\t\tSDKROOT = iphoneos;
\t\t\t\tSWIFT_ACTIVE_COMPILATION_CONDITIONS = DEBUG;
\t\t\t\tSWIFT_OPTIMIZATION_LEVEL = "-Onone";"""

    release_settings = f"""ALWAYS_SEARCH_USER_PATHS = NO;
\t\t\t\tCLANG_ANALYZER_NONNULL = YES;
\t\t\t\tCLANG_ANALYZER_NUMBER_OBJECT_CONVERSION = YES_AGGRESSIVE;
\t\t\t\tCLANG_CXX_LANGUAGE_STANDARD = "gnu++20";
\t\t\t\tCLANG_ENABLE_MODULES = YES;
\t\t\t\tCLANG_ENABLE_OBJC_ARC = YES;
\t\t\t\tCLANG_ENABLE_OBJC_WEAK = YES;
\t\t\t\tCLANG_WARN_BLOCK_CAPTURE_AUTORELEASING = YES;
\t\t\t\tCLANG_WARN_BOOL_CONVERSION = YES;
\t\t\t\tCLANG_WARN_COMMA = YES;
\t\t\t\tCLANG_WARN_CONSTANT_CONVERSION = YES;
\t\t\t\tCLANG_WARN_DEPRECATED_OBJC_IMPLEMENTATIONS = YES;
\t\t\t\tCLANG_WARN_DIRECT_OBJC_ISA_USAGE = YES_ERROR;
\t\t\t\tCLANG_WARN_DOCUMENTATION_COMMENTS = YES;
\t\t\t\tCLANG_WARN_EMPTY_BODY = YES;
\t\t\t\tCLANG_WARN_ENUM_CONVERSION = YES;
\t\t\t\tCLANG_WARN_INFINITE_RECURSION = YES;
\t\t\t\tCLANG_WARN_INT_CONVERSION = YES;
\t\t\t\tCLANG_WARN_NON_LITERAL_NULL_CONVERSION = YES;
\t\t\t\tCLANG_WARN_OBJC_IMPLICIT_RETAIN_SELF = YES;
\t\t\t\tCLANG_WARN_OBJC_LITERAL_CONVERSION = YES;
\t\t\t\tCLANG_WARN_OBJC_ROOT_CLASS = YES_ERROR;
\t\t\t\tCLANG_WARN_QUOTED_INCLUDE_IN_FRAMEWORK_HEADER = YES;
\t\t\t\tCLANG_WARN_RANGE_LOOP_ANALYSIS = YES;
\t\t\t\tCLANG_WARN_STRICT_PROTOTYPES = YES;
\t\t\t\tCLANG_WARN_SUSPICIOUS_MOVE = YES;
\t\t\t\tCLANG_WARN_UNGUARDED_AVAILABILITY = YES_AGGRESSIVE;
\t\t\t\tCLANG_WARN_UNREACHABLE_CODE = YES;
\t\t\t\tCLANG_WARN__DUPLICATE_METHOD_MATCH = YES;
\t\t\t\tCOPY_PHASE_STRIP = NO;
\t\t\t\tDEBUG_INFORMATION_FORMAT = "dwarf-with-dsym";
\t\t\t\tENABLE_NS_ASSERTIONS = NO;
\t\t\t\tENABLE_STRICT_OBJC_MSGSEND = YES;
\t\t\t\tGCC_C_LANGUAGE_STANDARD = gnu17;
\t\t\t\tGCC_NO_COMMON_BLOCKS = YES;
\t\t\t\tGCC_WARN_64_TO_32_BIT_CONVERSION = YES;
\t\t\t\tGCC_WARN_ABOUT_RETURN_TYPE = YES_ERROR;
\t\t\t\tGCC_WARN_UNDECLARED_SELECTOR = YES;
\t\t\t\tGCC_WARN_UNINITIALIZED_AUTOS = YES_AGGRESSIVE;
\t\t\t\tGCC_WARN_UNUSED_FUNCTION = YES;
\t\t\t\tGCC_WARN_UNUSED_VARIABLE = YES;
\t\t\t\tIPHONEOS_DEPLOYMENT_TARGET = {MIN_IOS};
\t\t\t\tMTL_FAST_MATH = YES;
\t\t\t\tSDKROOT = iphoneos;
\t\t\t\tSWIFT_COMPILATION_MODE = wholemodule;
\t\t\t\tSWIFT_OPTIMIZATION_LEVEL = "-O";
\t\t\t\tVALIDATE_PRODUCT = YES;"""

    target_debug = f"""ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon;
\t\t\t\tASS​ETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME = AccentColor;
\t\t\t\tCODE_SIGN_STYLE = Automatic;
\t\t\t\tCURRENT_PROJECT_VERSION = 1;
\t\t\t\tGENERATE_INFOPLIST_FILE = NO;
\t\t\t\tINFOPLIST_FILE = TuProfeIOS/Supporting/Info.plist;
\t\t\t\tIPHONEOS_DEPLOYMENT_TARGET = {MIN_IOS};
\t\t\t\tLE_SWIFT_VERSION = {SWIFT_VERSION};
\t\t\t\tMARKETING_VERSION = 1.0;
\t\t\t\tPRODUCT_BUNDLE_IDENTIFIER = {BUNDLE_ID};
\t\t\t\tPRODUCT_NAME = "$(TARGET_NAME)";
\t\t\t\tSWIFT_EMIT_LOC_STRINGS = YES;
\t\t\t\tSWIFT_VERSION = {SWIFT_VERSION};
\t\t\t\tTARGETED_DEVICE_FAMILY = "1,2";"""

    lines.append("/* Begin XCBuildConfiguration section */")

    # Project Debug
    lines.append(f'\t\t{DEBUG_PROJECT_CONFIG} /* Debug */ = {{')
    lines.append('\t\t\tisa = XCBuildConfiguration;')
    lines.append('\t\t\tbuildSettings = {')
    lines.append(f'\t\t\t\t{base_settings}')
    lines.append('\t\t\t};')
    lines.append('\t\t\tname = Debug;')
    lines.append('\t\t};')

    # Project Release
    lines.append(f'\t\t{RELEASE_PROJECT_CONFIG} /* Release */ = {{')
    lines.append('\t\t\tisa = XCBuildConfiguration;')
    lines.append('\t\t\tbuildSettings = {')
    lines.append(f'\t\t\t\t{release_settings}')
    lines.append('\t\t\t};')
    lines.append('\t\t\tname = Release;')
    lines.append('\t\t};')

    # Target Debug
    lines.append(f'\t\t{DEBUG_CONFIG_UUID} /* Debug */ = {{')
    lines.append('\t\t\tisa = XCBuildConfiguration;')
    lines.append('\t\t\tbuildSettings = {')
    lines.append(f'\t\t\t\t{target_debug}')
    lines.append('\t\t\t};')
    lines.append('\t\t\tname = Debug;')
    lines.append('\t\t};')

    # Target Release
    lines.append(f'\t\t{RELEASE_CONFIG_UUID} /* Release */ = {{')
    lines.append('\t\t\tisa = XCBuildConfiguration;')
    lines.append('\t\t\tbuildSettings = {')
    lines.append(f'\t\t\t\t{target_debug}')
    lines.append('\t\t\t};')
    lines.append('\t\t\tname = Release;')
    lines.append('\t\t};')

    lines.append("/* End XCBuildConfiguration section */")
    lines.append("")

    # XCConfigurationList
    lines.append("/* Begin XCConfigurationList section */")
    lines.append(f'\t\t{PROJECT_CONFIG_LIST} /* Build configuration list for PBXProject "{PRODUCT_NAME}" */ = {{')
    lines.append('\t\t\tisa = XCConfigurationList;')
    lines.append('\t\t\tbuildConfigurations = (')
    lines.append(f'\t\t\t\t{DEBUG_PROJECT_CONFIG} /* Debug */,')
    lines.append(f'\t\t\t\t{RELEASE_PROJECT_CONFIG} /* Release */,')
    lines.append('\t\t\t);')
    lines.append('\t\t\tdefaultConfigurationIsVisible = 0;')
    lines.append('\t\t\tdefaultConfigurationName = Release;')
    lines.append('\t\t};')

    lines.append(f'\t\t{TARGET_CONFIG_LIST} /* Build configuration list for PBXNativeTarget "{PRODUCT_NAME}" */ = {{')
    lines.append('\t\t\tisa = XCConfigurationList;')
    lines.append('\t\t\tbuildConfigurations = (')
    lines.append(f'\t\t\t\t{DEBUG_CONFIG_UUID} /* Debug */,')
    lines.append(f'\t\t\t\t{RELEASE_CONFIG_UUID} /* Release */,')
    lines.append('\t\t\t);')
    lines.append('\t\t\tdefaultConfigurationIsVisible = 0;')
    lines.append('\t\t\tdefaultConfigurationName = Release;')
    lines.append('\t\t};')
    lines.append("/* End XCConfigurationList section */")
    lines.append("")

    lines.append("\t};")
    lines.append(f'\trootObject = {PROJECT_UUID} /* Project object */;')
    lines.append("}")

    content = "\n".join(lines)
    with open(OUTPUT_FILE, 'w') as f:
        f.write(content)

    print(f"✅ Generated: {OUTPUT_FILE}")
    print(f"   Swift files: {len(swift_files)}")
    print(f"   Resource files: {len(resource_files)}")
    print(f"")
    print(f"Next steps:")
    print(f"1. Add Firebase via Swift Package Manager in Xcode")
    print(f"2. Add SDWebImageSwiftUI via Swift Package Manager")
    print(f"3. Replace GoogleService-Info.plist with your real one")
    print(f"4. open {OUTPUT_DIR}")

if __name__ == "__main__":
    generate()