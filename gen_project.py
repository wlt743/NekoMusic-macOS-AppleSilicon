import pathlib

root = pathlib.Path("NekoMusicMac")
swift_files = sorted([p.relative_to(root) for p in root.rglob("*.swift")])
print("文件数:", len(swift_files))

def gen(prefix, n):
    return f"{prefix}{n:04X}"

build_ids = {str(f): gen("A10000", i) for i, f in enumerate(swift_files)}
ref_ids = {str(f): gen("A20000", i) for i, f in enumerate(swift_files)}

def group_for(p):
    parts = str(p).split("/")
    return parts[0] if len(parts) > 1 else "root"

build_entries = "".join(
    f'\t\t{build_ids[k]} /* {k.split("/")[-1]} in Sources */ = {{isa = PBXBuildFile; fileRef = {ref_ids[k]} /* {k.split("/")[-1]} */; }};\n'
    for k in build_ids)
ref_entries = "".join(
    f'\t\t{ref_ids[k]} /* {k.split("/")[-1]} */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = {k.split("/")[-1]}; sourceTree = "<group>"; }};\n'
    for k in ref_ids)

groups = {}
for k in ref_ids:
    groups.setdefault(group_for(k), []).append(k)

group_entries = ""
group_refs_top = ""
for idx, (g, files) in enumerate(groups.items()):
    gid = gen("A30000", idx)
    children = "".join(f'\t\t\t\t{ref_ids[f]} /* {f.split("/")[-1]} */,\n' for f in files)
    if g == "root":
        group_entries += f'''\t\t{gid} /* Sources */ = {{
\t\t\tisa = PBXGroup;
\t\t\tchildren = (
{children}\t\t\t);
\t\t\tsourceTree = "<group>";
\t\t}};
'''
    else:
        group_entries += f'''\t\t{gid} /* {g} */ = {{
\t\t\tisa = PBXGroup;
\t\t\tchildren = (
{children}\t\t\t);
\t\t\tpath = {g};
\t\t\tsourceTree = "<group>";
\t\t}};
'''
    group_refs_top += f'\t\t\t\t{gid} /* {g} */,\n'

source_entries = "".join(f'\t\t\t\t{build_ids[k]} /* {k.split("/")[-1]} in Sources */,\n' for k in build_ids)

pbx = f'''// !$*UTF8*$!
{{
	archiveVersion = 1;
	classes = {{
	}};
	objectVersion = 56;
	objects = {{

/* Begin PBXBuildFile section */
{build_entries}/* End PBXBuildFile section */

/* Begin PBXFileReference section */
{ref_entries}\t\tA2000099 /* NekoMusicMac.app */ = {{isa = PBXFileReference; explicitFileType = wrapper.application; includeInIndex = 0; path = NekoMusicMac.app; sourceTree = BUILT_PRODUCTS_DIR; }};
/* End PBXFileReference section */

/* Begin PBXFrameworksBuildPhase section */
\t\tA5000002 /* Frameworks */ = {{
\t\t\tisa = PBXFrameworksBuildPhase;
\t\t\tbuildActionMask = 2147483647;
\t\t\tfiles = (
\t\t\t);
\t\t\trunOnlyForDeploymentPostprocessing = 0;
\t\t}};
/* End PBXFrameworksBuildPhase section */

/* Begin PBXGroup section */
\t\tA3000001 = {{
\t\t\tisa = PBXGroup;
\t\t\tchildren = (
\t\t\t\tA3000002 /* NekoMusicMac */,
\t\t\t\tA3000010 /* Products */,
\t\t\t);
\t\t\tsourceTree = "<group>";
\t\t}};
\t\tA3000002 /* NekoMusicMac */ = {{
\t\t\tisa = PBXGroup;
\t\t\tchildren = (
{group_refs_top}\t\t\t);
\t\t\tpath = NekoMusicMac;
\t\t\tsourceTree = "<group>";
\t\t}};
{group_entries}\t\tA3000010 /* Products */ = {{
\t\t\tisa = PBXGroup;
\t\t\tchildren = (
\t\t\t\tA2000099 /* NekoMusicMac.app */,
\t\t\t);
\t\t\tname = Products;
\t\t\tsourceTree = "<group>";
\t\t}};
/* End PBXGroup section */

/* Begin PBXNativeTarget section */
\t\tA4000001 /* NekoMusicMac */ = {{
\t\t\tisa = PBXNativeTarget;
\t\t\tbuildConfigurationList = A6000001 /* Build configuration list for PBXNativeTarget "NekoMusicMac" */;
\t\t\tbuildPhases = (
\t\t\t\tA5000001 /* Sources */,
\t\t\t\tA5000002 /* Frameworks */,
\t\t\t\tA5000003 /* Resources */,
\t\t\t);
\t\t\tbuildRules = (
\t\t\t);
\t\t\tdependencies = (
\t\t\t);
\t\t\tname = NekoMusicMac;
\t\t\tproductName = NekoMusicMac;
\t\t\tproductReference = A2000099 /* NekoMusicMac.app */;
\t\t\tproductType = "com.apple.product-type.application";
\t\t}};
/* End PBXNativeTarget section */

/* Begin PBXProject section */
\t\tA7000001 /* Project object */ = {{
\t\t\tisa = PBXProject;
\t\t\tattributes = {{
\t\t\t\tBuildIndependentTargetsInParallel = 1;
\t\t\t\tLastSwiftUpdateCheck = 1500;
\t\t\t\tLastUpgradeCheck = 1500;
\t\t\t}};
\t\t\tbuildConfigurationList = A6000002 /* Build configuration list for PBXProject "NekoMusicMac" */;
\t\t\tcompatibilityVersion = "Xcode 14.0";
\t\t\tdevelopmentRegion = "zh-Hans";
\t\t\thasScannedForEncodings = 0;
\t\t\tknownRegions = (
\t\t\t\ten,
\t\t\t\tBase,
\t\t\t\t"zh-Hans",
\t\t\t);
\t\t\tmainGroup = A3000001;
\t\t\tproductRefGroup = A3000010 /* Products */;
\t\t\tprojectDirPath = "";
\t\t\tprojectRoot = "";
\t\t\ttargets = (
\t\t\t\tA4000001 /* NekoMusicMac */,
\t\t\t);
\t\t}};
/* End PBXProject section */

/* Begin PBXResourcesBuildPhase section */
\t\tA5000003 /* Resources */ = {{
\t\t\tisa = PBXResourcesBuildPhase;
\t\t\tbuildActionMask = 2147483647;
\t\t\tfiles = (
\t\t\t);
\t\t\trunOnlyForDeploymentPostprocessing = 0;
\t\t}};
/* End PBXResourcesBuildPhase section */

/* Begin PBXSourcesBuildPhase section */
\t\tA5000001 /* Sources */ = {{
\t\t\tisa = PBXSourcesBuildPhase;
\t\t\tbuildActionMask = 2147483647;
\t\t\tfiles = (
{source_entries}\t\t\t);
\t\t\trunOnlyForDeploymentPostprocessing = 0;
\t\t}};
/* End PBXSourcesBuildPhase section */

/* Begin XCBuildConfiguration section */
\t\tA8000001 /* Debug */ = {{
\t\t\tisa = XCBuildConfiguration;
\t\t\tbuildSettings = {{
\t\t\t\tALWAYS_SEARCH_USER_PATHS = NO;
\t\t\t\tCLANG_ENABLE_MODULES = YES;
\t\t\t\tCLANG_ENABLE_OBJC_ARC = YES;
\t\t\t\tCOPY_PHASE_STRIP = NO;
\t\t\t\tDEBUG_INFORMATION_FORMAT = dwarf;
\t\t\t\tENABLE_TESTABILITY = YES;
\t\t\t\tGCC_OPTIMIZATION_LEVEL = 0;
\t\t\t\tMACOSX_DEPLOYMENT_TARGET = 14.0;
\t\t\t\tONLY_ACTIVE_ARCH = YES;
\t\t\t\tSDKROOT = macosx;
\t\t\t\tSWIFT_ACTIVE_COMPILATION_CONDITIONS = DEBUG;
\t\t\t\tSWIFT_OPTIMIZATION_LEVEL = "-Onone";
\t\t\t}};
\t\t\tname = Debug;
\t\t}};
\t\tA8000002 /* Release */ = {{
\t\t\tisa = XCBuildConfiguration;
\t\t\tbuildSettings = {{
\t\t\t\tALWAYS_SEARCH_USER_PATHS = NO;
\t\t\t\tCLANG_ENABLE_MODULES = YES;
\t\t\t\tCLANG_ENABLE_OBJC_ARC = YES;
\t\t\t\tCOPY_PHASE_STRIP = NO;
\t\t\t\tDEBUG_INFORMATION_FORMAT = "dwarf-with-dsym";
\t\t\t\tENABLE_NS_ASSERTIONS = NO;
\t\t\t\tMACOSX_DEPLOYMENT_TARGET = 14.0;
\t\t\t\tSDKROOT = macosx;
\t\t\t\tSWIFT_COMPILATION_MODE = wholemodule;
\t\t\t\tSWIFT_OPTIMIZATION_LEVEL = "-O";
\t\t\t}};
\t\t\tname = Release;
\t\t}};
\t\tA8000003 /* Debug */ = {{
\t\t\tisa = XCBuildConfiguration;
\t\t\tbuildSettings = {{
\t\t\t\tCODE_SIGN_STYLE = Automatic;
\t\t\t\tCOMBINE_HIDPI_IMAGES = YES;
\t\t\t\tCURRENT_PROJECT_VERSION = 1;
\t\t\t\tDEVELOPMENT_TEAM = B9N6W9S7D8;
\t\t\t\tENABLE_HARDENED_RUNTIME = YES;
\t\t\t\tGENERATE_INFOPLIST_FILE = YES;
\t\t\t\tINFOPLIST_KEY_CFBundleDisplayName = NekoMusic;
\t\t\t\tINFOPLIST_KEY_LSApplicationCategoryType = "public.app-category.music";
\t\t\t\tLD_RUNPATH_SEARCH_PATHS = (
\t\t\t\t\t"$(inherited)",
\t\t\t\t\t"@executable_path/../Frameworks",
\t\t\t\t);
\t\t\t\tMARKETING_VERSION = 1.0.0;
\t\t\t\tPRODUCT_BUNDLE_IDENTIFIER = com.wlt743.nekomusic.mac;
\t\t\t\tPRODUCT_NAME = "$(TARGET_NAME)";
\t\t\t\tSWIFT_EMIT_LOC_STRINGS = YES;
\t\t\t\tSWIFT_VERSION = 5.0;
\t\t\t}};
\t\t\tname = Debug;
\t\t}};
\t\tA8000004 /* Release */ = {{
\t\t\tisa = XCBuildConfiguration;
\t\t\tbuildSettings = {{
\t\t\t\tCODE_SIGN_STYLE = Automatic;
\t\t\t\tCOMBINE_HIDPI_IMAGES = YES;
\t\t\t\tCURRENT_PROJECT_VERSION = 1;
\t\t\t\tDEVELOPMENT_TEAM = B9N6W9S7D8;
\t\t\t\tENABLE_HARDENED_RUNTIME = YES;
\t\t\t\tGENERATE_INFOPLIST_FILE = YES;
\t\t\t\tINFOPLIST_KEY_CFBundleDisplayName = NekoMusic;
\t\t\t\tINFOPLIST_KEY_LSApplicationCategoryType = "public.app-category.music";
\t\t\t\tLD_RUNPATH_SEARCH_PATHS = (
\t\t\t\t\t"$(inherited)",
\t\t\t\t\t"@executable_path/../Frameworks",
\t\t\t\t);
\t\t\t\tMARKETING_VERSION = 1.0.0;
\t\t\t\tPRODUCT_BUNDLE_IDENTIFIER = com.wlt743.nekomusic.mac;
\t\t\t\tPRODUCT_NAME = "$(TARGET_NAME)";
\t\t\t\tSWIFT_EMIT_LOC_STRINGS = YES;
\t\t\t\tSWIFT_VERSION = 5.0;
\t\t\t}};
\t\t\tname = Release;
\t\t}};
/* End XCBuildConfiguration section */

/* Begin XCConfigurationList section */
\t\tA6000001 /* Build configuration list for PBXNativeTarget "NekoMusicMac" */ = {{
\t\t\tisa = XCConfigurationList;
\t\t\tbuildConfigurations = (
\t\t\t\tA8000003 /* Debug */,
\t\t\t\tA8000004 /* Release */,
\t\t\t);
\t\t\tdefaultConfigurationIsVisible = 0;
\t\t\tdefaultConfigurationName = Release;
\t\t}};
\t\tA6000002 /* Build configuration list for PBXProject "NekoMusicMac" */ = {{
\t\t\tisa = XCConfigurationList;
\t\t\tbuildConfigurations = (
\t\t\t\tA8000001 /* Debug */,
\t\t\t\tA8000002 /* Release */,
\t\t\t);
\t\t\tdefaultConfigurationIsVisible = 0;
\t\t\tdefaultConfigurationName = Release;
\t\t}};
/* End XCConfigurationList section */
\t}};
\trootObject = A7000001 /* Project object */;
}}
'''
pathlib.Path("NekoMusicMac.xcodeproj/project.pbxproj").write_text(pbx)
print("pbxproj 已生成")
