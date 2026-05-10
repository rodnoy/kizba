Command line invocation:
    /Applications/Xcode.app/Contents/Developer/usr/bin/xcodebuild test -scheme Kizba -project Kizba.xcodeproj -destination platform=macOS "-only-testing:KizbaTests/EntryDetailModelBiometricRevealTests"

Partial xcodebuild output (first ~200 lines):

2026-05-10 22:24:38.676 xcodebuild[98940:29406127]  DVTDeviceOperation: Encountered a build number "" that is incompatible with DVTBuildVersion.
2026-05-10 22:24:38.678 xcodebuild[98940:29406079] [MT] DVTDeviceOperation: Encountered a build number "" that is incompatible with DVTBuildVersion.
--- xcodebuild: WARNING: Using the first of multiple matching destinations:
{ platform:macOS, arch:arm64, id:00006001-000868D21A42401E, name:My Mac }
{ platform:macOS, arch:x86_64, id:00006001-000868D21A42401E, name:My Mac }
ComputePackagePrebuildTargetDependencyGraph

Prepare packages

CreateBuildRequest

SendProjectDescription

CreateBuildOperation

ComputeTargetDependencyGraph
note: Building targets in dependency order
note: Target dependency graph (2 targets)
    Target 'KizbaTests' in project 'Kizba'
        ➜ Explicit dependency on target 'Kizba' in project 'Kizba'
    Target 'Kizba' in project 'Kizba' (no dependencies)

GatherProvisioningInputs

CreateBuildDescription

ExecuteExternalTool /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/clang -v -E -dM -isysroot /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX26.4.sdk -x c -c /dev/null

ExecuteExternalTool /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc --version

ExecuteExternalTool /Applications/Xcode.app/Contents/Developer/usr/bin/actool --version --output-format xml1

ExecuteExternalTool /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/ld -version_details

Build description signature: c38b1dd69fd77f613d44c69aafdc19b9
Build description path: /Users/kirillsimagin/Library/Developer/Xcode/DerivedData/Kizba-efejvmfzdmoqdoewsmanttogshar/Build/Intermediates.noindex/XCBuildData/c38b1dd69fd77f613d44c69aafdc19b9.xcbuilddata
ClangStatCache /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/clang-stat-cache /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX26.4.sdk /Users/kirillsimagin/Library/Developer/Xcode/DerivedData/SDKStatCaches.noindex/macosx26.4-25E251-30f9ca8789b706f8bd3fc906a70d770f.sdkstatcache
    cd /Users/kirillsimagin/dev/my/worldproject/kizba/Kizba.xcodeproj
    /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/clang-stat-cache /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX26.4.sdk -o /Users/kirillsimagin/Library/Developer/Xcode/DerivedData/SDKStatCaches.noindex/macosx26.4-25E251-30f9ca8789b706f8bd3fc906a70d770f.sdkstatcache

SwiftDriver Kizba normal arm64 com.apple.xcode.tools.swift.compiler (in target 'Kizba' from project 'Kizba')
    cd /Users/kirillsimagin/dev/my/worldproject/kizba
    builtin-SwiftDriver -- /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc -module-name Kizba -Onone @/Users/kirillsimagin/Library/Developer/Xcode/DerivedData/Kizba-efejvmfzdmoqdoewsmanttogshar/Build/Intermediates.noindex/Kizba.build/Debug/Kizba.build/Objects-normal/arm64/Kizba.SwiftFileList -DDEBUG -enable-upcoming-feature StrictConcurrency -default-isolation\=MainActor -enable-bare-slash-regex -enable-upcoming-feature DisableOutwardActorInference -enable-upcoming-feature InferSendableFromCaptures -enable-upcoming-feature GlobalActorIsolatedTypesUsability -enable-upcoming-feature MemberImportVisibility -enable-upcoming-feature InferIsolatedConformances -enable-upcoming-feature NonisolatedNonsendingByDefault -enable-experimental-feature DebugDescriptionMacro -sdk /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX26.4.sdk -target arm64-apple-macos14.0 -g -module-cache-path /Users/kirillsimagin/Library/Developer/Xcode/DerivedData/ModuleCache.noindex -Xfrontend -serialize-debugging-options -enable-testing -warnings-as-errors -index-store-path /Users/kirillsimagin/Library/Developer/Xcode/DerivedData/Kizba-efejvmfzdmoqdoewsmanttogshar/Index.noindex/DataStore -Xcc -D_LIBCPP_HARDENING_MODE\=_LIBCPP_HARDENING_MODE_DEBUG -swift-version 5 -I /Users/kirillsimagin/Library/Developer/Xcode/DerivedData/Kizba-efejvmfzdmoqdoewsmanttogshar/Build/Products/Debug -F /Users/kirillsimagin/Library/Developer/Xcode/DerivedData/Kizba-efejvmfzdmoqdoewsmanttogshar/Build/Products/Debug -emit-localized-strings -emit-localized-strings-path /Users/kirillsimagin/Library/Developer/Xcode/DerivedData/Kizba-efejvmfzdmoqdoewsmanttogshar/Build/Intermediates.noindex/Kizba.build/Debug/Kizba.build/Objects-normal/arm64 -c -j10 -enable-batch-mode -incremental -Xcc -ivfsstatcache -Xcc /Users/kirillsimagin/Library/Developer/Xcode/DerivedData/SDKStatCaches.noindex/macosx26.4-25E251-30f9ca8789b706f8bd3fc906a70d770f.sdkstatcache -... (truncated)

Error summary:
- Multiple swift compile warnings treated as errors in Swift 6 language mode.
- The immediate build failure: "'MutableSettingsStore' is inaccessible due to 'private' protection level" originating from KizbaTests/EntryDetailModelBiometricRevealTests.swift when attempting to instantiate MutableSettingsStore declared as private in EntryDetailModelCopyTests.swift.

Grep checks performed and included below:
- rg -n '\\bas!\\b' Kizba: no matches
- rg -n 'Logger.*stdin|print\\(.*stdin' Kizba: no matches
