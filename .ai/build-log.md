Command line invocation:
    /Applications/Xcode.app/Contents/Developer/usr/bin/xcodebuild -scheme Kizba -project Kizba.xcodeproj -destination platform=macOS test

2026-05-08 15:35:45.871 xcodebuild[8509:16820527]  DVTDeviceOperation: Encountered a build number "" that is incompatible with DVTBuildVersion.
2026-05-08 15:35:45.875 xcodebuild[8509:16819683] [MT] DVTDeviceOperation: Encountered a build number "" that is incompatible with DVTBuildVersion.
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

ExecuteExternalTool /Applications/Xcode.app/Contents/Developer/usr/bin/actool --version --output-format xml1

ExecuteExternalTool /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc --version

ExecuteExternalTool /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/clang -v -E -dM -isysroot /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX26.4.sdk -x c -c /dev/null

ExecuteExternalTool /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/ld -version_details

Build description signature: cefc794304594a93a097507733343be9
Build description path: /Users/kirillsimagin/Library/Developer/Xcode/DerivedData/Kizba-efejvmfzdmoqdoewsmanttogshar/Build/Intermediates.noindex/XCBuildData/cefc794304594a93a097507733343be9.xcbuilddata
ClangStatCache /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/clang-stat-cache /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX26.4.sdk /Users/kirillsimagin/Library/Developer/Xcode/DerivedData/SDKStatCaches.noindex/macosx26.4-25E251-30f9ca8789b706f8bd3fc906a70d770f.sdkstatcache
    cd /Users/kirillsimagin/dev/my/worldproject/kizba/Kizba.xcodeproj
    /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/clang-stat-cache /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX26.4.sdk -o /Users/kirillsimagin/Library/Developer/Xcode/DerivedData/SDKStatCaches.noindex/macosx26.4-25E251-30f9ca8789b706f8bd3fc906a70d770f.sdkstatcache

ProcessInfoPlistFile /Users/kirillsimagin/Library/Developer/Xcode/DerivedData/Kizba-efejvmfzdmoqdoewsmanttogshar/Build/Products/Debug/Kizba.app/Contents/Info.plist /Users/kirillsimagin/Library/Developer/Xcode/DerivedData/Kizba-efejvmfzdmoqdoewsmanttogshar/Build/Intermediates.noindex/Kizba.build/Debug/Kizba.build/empty-Kizba.plist (in target 'Kizba' from project 'Kizba')
    cd /Users/kirillsimagin/dev/my/worldproject/kizba
    builtin-infoPlistUtility /Users/kirillsimagin/Library/Developer/Xcode/DerivedData/Kizba-efejvmfzdmoqdoewsmanttogshar/Build/Intermediates.noindex/Kizba.build/Debug/Kizba.build/empty-Kizba.plist -producttype com.apple.product-type.application -genpkginfo /Users/kirillsimagin/Library/Developer/Xcode/DerivedData/Kizba-efejvmfzdmoqdoewsmanttogshar/Build/Products/Debug/Kizba.app/Contents/PkgInfo -expandbuildsettings -platform macosx -additionalcontentfile /Users/kirillsimagin/Library/Developer/Xcode/DerivedData/Kizba-efejvmfzdmoqdoewsmanttogshar/Build/Intermediates.noindex/Kizba.build/Debug/Kizba.build/assetcatalog_generated_info.plist -o /Users/kirillsimagin/Library/Developer/Xcode/DerivedData/Kizba-efejvmfzdmoqdoewsmanttogshar/Build/Products/Debug/Kizba.app/Contents/Info.plist

ConstructStubExecutorLinkFileList /Users/kirillsimagin/Library/Developer/Xcode/DerivedData/Kizba-efejvmfzdmoqdoewsmanttogshar/Build/Intermediates.noindex/Kizba.build/Debug/Kizba.build/Kizba-ExecutorLinkFileList-normal-arm64.txt (in target 'Kizba' from project 'Kizba')
    cd /Users/kirillsimagin/dev/my/worldproject/kizba
    construct-stub-executor-link-file-list /Users/kirillsimagin/Library/Developer/Xcode/DerivedData/Kizba-efejvmfzdmoqdoewsmanttogshar/Build/Products/Debug/Kizba.app/Contents/MacOS/Kizba.debug.dylib /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/usr/lib/libPreviewsJITStubExecutor_no_swift_entry_point.a /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/usr/lib/libPreviewsJITStubExecutor.a --output /Users/kirillsimagin/Library/Developer/Xcode/DerivedData/Kizba-efejvmfzdmoqdoewsmanttogshar/Build/Intermediates.noindex/Kizba.build/Debug/Kizba.build/Kizba-ExecutorLinkFileList-normal-arm64.txt
note: Using stub executor library with Swift entry point. (in target 'Kizba' from project 'Kizba')

SwiftDriver KizbaTests normal arm64 com.apple.xcode.tools.swift.compiler (in target 'KizbaTests' from project 'Kizba')
    cd /Users/kirillsimagin/dev/my/worldproject/kizba
    builtin-SwiftDriver -- /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc -module-name KizbaTests -Onone @/Users/kirillsimagin/Library/Developer/Xcode/DerivedData/Kizba-efejvmfzdmoqdoewsmanttogshar/Build/Intermediates.noindex/Kizba.build/Debug/KizbaTests.build/Objects-normal/arm64/KizbaTests.SwiftFileList -DDEBUG -plugin-path /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/lib/swift/host/plugins/testing -enable-bare-slash-regex -enable-upcoming-feature DisableOutwardActorInference -enable-upcoming-feature InferSendableFromCaptures -enable-upcoming-feature GlobalActorIsolatedTypesUsability -enable-upcoming-feature MemberImportVisibility -enable-upcoming-feature InferIsolatedConformances -enable-upcoming-feature NonisolatedNonsendingByDefault -enable-experimental-feature DebugDescriptionMacro -sdk /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX26.4.sdk -target arm64-apple-macos14.0 -g -module-cache-path /Users/kirillsimagin/Library/Developer/Xcode/DerivedData/ModuleCache.noindex -Xfrontend -serialize-debugging-options -enable-testing -index-store-path /Users/kirillsimagin/Library/Developer/Xcode/DerivedData/Kizba-efejvmfzdmoqdoewsmanttogshar/Index.noindex/DataStore -Xcc -D_LIBCPP_HARDENING_MODE\=_LIBCPP_HARDENING_MODE_DEBUG -swift-version 5 -I /Users/kirillsimagin/Library/Developer/Xcode/DerivedData/Kizba-efejvmfzdmoqdoewsmanttogshar/Build/Products/Debug -Isystem /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/usr/lib -F /Users/kirillsimagin/Library/Developer/Xcode/DerivedData/Kizba-efejvmfzdmoqdoewsmanttogshar/Build/Products/Debug -F /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/Library/Frameworks -c -j10 -enable-batch-mode -incremental -Xcc -ivfsstatcache -Xcc /Users/kirillsimagin/Library/Developer/Xcode/DerivedData/SDKStatCaches.noindex/macosx26.4-25E251-30f9ca8789b706f8bd3fc906a70d770f.sdkstatcache -output-file-map /Users/kirillsimagin/Library/Developer/Xcode/DerivedData/Kizba-efejvmfzdmoqdoewsmanttogshar/Build/Intermediates.noindex/Kizba.build/Debug/KizbaTests.build/Objects-normal/arm64/KizbaTests-OutputFileMap.json -use-frontend-parseable-output -save-temps -no-color-diagnostics -explicit-module-build -module-cache-path /Users/kirillsimagin/Library/Developer/Xcode/DerivedData/Kizba-efejvmfzdmoqdoewsmanttogshar/Build/Intermediates.noindex/SwiftExplicitPrecompiledModules -clang-scanner-module-cache-path /Users/kirillsimagin/Library/Developer/Xcode/DerivedData/ModuleCache.noindex -sdk-module-cache-path /Users/kirillsimagin/Library/Developer/Xcode/DerivedData/ModuleCache.noindex -serialize-diagnostics -emit-dependencies -emit-module -emit-module-path /Users/kirillsimagin/Library/Developer/Xcode/DerivedData/Kizba-efejvmfzdmoqdoewsmanttogshar/Build/Intermediates.noindex/Kizba.build/Debug/KizbaTests.build/Objects-normal/arm64/KizbaTests.swiftmodule -validate-clang-modules-once -clang-build-session-file /Users/kirillsimagin/Library/Developer/Xcode/DerivedData/ModuleCache.noindex/Session.modulevalidation -Xcc -I/Users/kirillsimagin/Library/Developer/Xcode/DerivedData/Kizba-efejvmfzdmoqdoewsmanttogshar/Build/Intermediates.noindex/Kizba.build/Debug/KizbaTests.build/swift-overrides.hmap -emit-const-values -Xfrontend -const-gather-protocols-file -Xfrontend /Users/kirillsimagin/Library/Developer/Xcode/DerivedData/Kizba-efejvmfzdmoqdoewsmanttogshar/Build/Intermediates.noindex/Kizba.build/Debug/KizbaTests.build/Objects-normal/arm64/KizbaTests_const_extract_protocols.json -Xcc -iquote -Xcc /Users/kirillsimagin/Library/Developer/Xcode/DerivedData/Kizba-efejvmfzdmoqdoewsmanttogshar/Build/Intermediates.noindex/Kizba.build/Debug/KizbaTests.build/KizbaTests-generated-files.hmap -Xcc -I/Users/kirillsimagin/Library/Developer/Xcode/DerivedData/Kizba-efejvmfzdmoqdoewsmanttogshar/Build/Intermediates.noindex/Kizba.build/Debug/KizbaTests.build/KizbaTests-own-target-headers.hmap -Xcc -I/Users/kirillsimagin/Library/Developer/Xcode/DerivedData/Kizba-efejvmfzdmoqdoewsmanttogshar/Build/Intermediates.noindex/Kizba.build/Debug/KizbaTests.build/KizbaTests-all-target-headers.hmap -Xcc -iquote -Xcc /Users/kirillsimagin/Library/Developer/Xcode/DerivedData/Kizba-efejvmfzdmoqdoewsmanttogshar/Build/Intermediates.noindex/Kizba.build/Debug/KizbaTests.build/KizbaTests-project-headers.hmap -Xcc -I/Users/kirillsimagin/Library/Developer/Xcode/DerivedData/Kizba-efejvmfzdmoqdoewsmanttogshar/Build/Products/Debug/include -Xcc -I/Users/kirillsimagin/Library/Developer/Xcode/DerivedData/Kizba-efejvmfzdmoqdoewsmanttogshar/Build/Intermediates.noindex/Kizba.build/Debug/KizbaTests.build/DerivedSources-normal/arm64 -Xcc -I/Users/kirillsimagin/Library/Developer/Xcode/DerivedData/Kizba-efejvmfzdmoqdoewsmanttogshar/Build/Intermediates.noindex/Kizba.build/Debug/KizbaTests.build/DerivedSources/arm64 -Xcc -I/Users/kirillsimagin/Library/Developer/Xcode/DerivedData/Kizba-efejvmfzdmoqdoewsmanttogshar/Build/Intermediates.noindex/Kizba.build/Debug/KizbaTests.build/DerivedSources -Xcc -DDEBUG\=1 -emit-objc-header -emit-objc-header-path /Users/kirillsimagin/Library/Developer/Xcode/DerivedData/Kizba-efejvmfzdmoqdoewsmanttogshar/Build/Intermediates.noindex/Kizba.build/Debug/KizbaTests.build/Objects-normal/arm64/KizbaTests-Swift.h -working-directory /Users/kirillsimagin/dev/my/worldproject/kizba -experimental-emit-module-separately -disable-cmo

Ld /Users/kirillsimagin/Library/Developer/Xcode/DerivedData/Kizba-efejvmfzdmoqdoewsmanttogshar/Build/Products/Debug/Kizba.app/Contents/MacOS/Kizba normal (in target 'Kizba' from project 'Kizba')
    cd /Users/kirillsimagin/dev/my/worldproject/kizba
    /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/clang -Xlinker -reproducible -target arm64-apple-macos14.0 -isysroot /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX26.4.sdk -O0 -L/Users/kirillsimagin/Library/Developer/Xcode/DerivedData/Kizba-efejvmfzdmoqdoewsmanttogshar/Build/Products/Debug -F/Users/kirillsimagin/Library/Developer/Xcode/DerivedData/Kizba-efejvmfzdmoqdoewsmanttogshar/Build/Products/Debug -Xlinker -rpath -Xlinker @executable_path -Xlinker -rpath -Xlinker @executable_path/../Frameworks -rdynamic -Xlinker -no_deduplicate -e ___debug_blank_executor_main -Xlinker -sectcreate -Xlinker __TEXT -Xlinker __debug_dylib -Xlinker /Users/kirillsimagin/Library/Developer/Xcode/DerivedData/Kizba-efejvmfzdmoqdoewsmanttogshar/Build/Intermediates.noindex/Kizba.build/Debug/Kizba.build/Kizba-DebugDylibPath-normal-arm64.txt -Xlinker -sectcreate -Xlinker __TEXT -Xlinker __debug_instlnm -Xlinker /Users/kirillsimagin/Library/Developer/Xcode/DerivedData/Kizba-efejvmfzdmoqdoewsmanttogshar/Build/Intermediates.noindex/Kizba.build/Debug/Kizba.build/Kizba-DebugDylibInstallName-normal-arm64.txt -Xlinker -filelist -Xlinker /Users/kirillsimagin/Library/Developer/Xcode/DerivedData/Kizba-efejvmfzdmoqdoewsmanttogshar/Build/Intermediates.noindex/Kizba.build/Debug/Kizba.build/Kizba-ExecutorLinkFileList-normal-arm64.txt /Users/kirillsimagin/Library/Developer/Xcode/DerivedData/Kizba-efejvmfzdmoqdoewsmanttogshar/Build/Products/Debug/Kizba.app/Contents/MacOS/Kizba.debug.dylib -Xlinker -no_adhoc_codesign -o /Users/kirillsimagin/Library/Developer/Xcode/DerivedData/Kizba-efejvmfzdmoqdoewsmanttogshar/Build/Products/Debug/Kizba.app/Contents/MacOS/Kizba

CopySwiftLibs /Users/kirillsimagin/Library/Developer/Xcode/DerivedData/Kizba-efejvmfzdmoqdoewsmanttogshar/Build/Products/Debug/Kizba.app (in target 'Kizba' from project 'Kizba')
    cd /Users/kirillsimagin/dev/my/worldproject/kizba
    builtin-swiftStdLibTool --copy --verbose --sign - --scan-executable /Users/kirillsimagin/Library/Developer/Xcode/DerivedData/Kizba-efejvmfzdmoqdoewsmanttogshar/Build/Products/Debug/Kizba.app/Contents/MacOS/Kizba.debug.dylib --scan-folder /Users/kirillsimagin/Library/Developer/Xcode/DerivedData/Kizba-efejvmfzdmoqdoewsmanttogshar/Build/Products/Debug/Kizba.app/Contents/Frameworks --scan-folder /Users/kirillsimagin/Library/Developer/Xcode/DerivedData/Kizba-efejvmfzdmoqdoewsmanttogshar/Build/Products/Debug/Kizba.app/Contents/PlugIns --scan-folder /Users/kirillsimagin/Library/Developer/Xcode/DerivedData/Kizba-efejvmfzdmoqdoewsmanttogshar/Build/Products/Debug/Kizba.app/Contents/Library/SystemExtensions --scan-folder /Users/kirillsimagin/Library/Developer/Xcode/DerivedData/Kizba-efejvmfzdmoqdoewsmanttogshar/Build/Products/Debug/Kizba.app/Contents/Extensions --platform macosx --toolchain /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain --destination /Users/kirillsimagin/Library/Developer/Xcode/DerivedData/Kizba-efejvmfzdmoqdoewsmanttogshar/Build/Products/Debug/Kizba.app/Contents/Frameworks --strip-bitcode --strip-bitcode-tool /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/bitcode_strip --emit-dependency-info /Users/kirillsimagin/Library/Developer/Xcode/DerivedData/Kizba-efejvmfzdmoqdoewsmanttogshar/Build/Intermediates.noindex/Kizba.build/Debug/Kizba.build/SwiftStdLibToolInputDependencies.dep --filter-for-swift-os --back-deploy-swift-span

ExtractAppIntentsMetadata (in target 'Kizba' from project 'Kizba')
    cd /Users/kirillsimagin/dev/my/worldproject/kizba
    /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/appintentsmetadataprocessor --toolchain-dir /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain --module-name Kizba --sdk-root /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX26.4.sdk --xcode-version 17E202 --platform-family macOS --deployment-target 14.0 --bundle-identifier app.kizba.Kizba --output /Users/kirillsimagin/Library/Developer/Xcode/DerivedData/Kizba-efejvmfzdmoqdoewsmanttogshar/Build/Products/Debug/Kizba.app/Contents/Resources --target-triple arm64-apple-macos14.0 --binary-file /Users/kirillsimagin/Library/Developer/Xcode/DerivedData/Kizba-efejvmfzdmoqdoewsmanttogshar/Build/Products/Debug/Kizba.app/Contents/MacOS/Kizba --dependency-file /Users/kirillsimagin/Library/Developer/Xcode/DerivedData/Kizba-efejvmfzdmoqdoewsmanttogshar/Build/Intermediates.noindex/Kizba.build/Debug/Kizba.build/Objects-normal/arm64/Kizba_dependency_info.dat --stringsdata-file /Users/kirillsimagin/Library/Developer/Xcode/DerivedData/Kizba-efejvmfzdmoqdoewsmanttogshar/Build/Intermediates.noindex/Kizba.build/Debug/Kizba.build/Objects-normal/arm64/ExtractedAppShortcutsMetadata.stringsdata --source-file-list /Users/kirillsimagin/Library/Developer/Xcode/DerivedData/Kizba-efejvmfzdmoqdoewsmanttogshar/Build/Intermediates.noindex/Kizba.build/Debug/Kizba.build/Objects-normal/arm64/Kizba.SwiftFileList --metadata-file-list /Users/kirillsimagin/Library/Developer/Xcode/DerivedData/Kizba-efejvmfzdmoqdoewsmanttogshar/Build/Intermediates.noindex/Kizba.build/Debug/Kizba.build/Kizba.DependencyMetadataFileList --static-metadata-file-list /Users/kirillsimagin/Library/Developer/Xcode/DerivedData/Kizba-efejvmfzdmoqdoewsmanttogshar/Build/Intermediates.noindex/Kizba.build/Debug/Kizba.build/Kizba.DependencyStaticMetadataFileList --swift-const-vals-list /Users/kirillsimagin/Library/Developer/Xcode/DerivedData/Kizba-efejvmfzdmoqdoewsmanttogshar/Build/Intermediates.noindex/Kizba.build/Debug/Kizba.build/Objects-normal/arm64/Kizba.SwiftConstValuesFileList --compile-time-extraction --deployment-aware-processing --validate-assistant-intents --no-app-shortcuts-localization
2026-05-08 15:35:59.097 appintentsmetadataprocessor[8850:16821449] Starting appintentsmetadataprocessor export
2026-05-08 15:35:59.100 appintentsmetadataprocessor[8850:16821449] warning: Metadata extraction skipped. No AppIntents.framework dependency found.

ProcessInfoPlistFile /Users/kirillsimagin/Library/Developer/Xcode/DerivedData/Kizba-efejvmfzdmoqdoewsmanttogshar/Build/Products/Debug/Kizba.app/Contents/PlugIns/KizbaTests.xctest/Contents/Info.plist /Users/kirillsimagin/Library/Developer/Xcode/DerivedData/Kizba-efejvmfzdmoqdoewsmanttogshar/Build/Intermediates.noindex/Kizba.build/Debug/KizbaTests.build/empty-KizbaTests.plist (in target 'KizbaTests' from project 'Kizba')
    cd /Users/kirillsimagin/dev/my/worldproject/kizba
    builtin-infoPlistUtility /Users/kirillsimagin/Library/Developer/Xcode/DerivedData/Kizba-efejvmfzdmoqdoewsmanttogshar/Build/Intermediates.noindex/Kizba.build/Debug/KizbaTests.build/empty-KizbaTests.plist -producttype com.apple.product-type.bundle.unit-test -expandbuildsettings -platform macosx -o /Users/kirillsimagin/Library/Developer/Xcode/DerivedData/Kizba-efejvmfzdmoqdoewsmanttogshar/Build/Products/Debug/Kizba.app/Contents/PlugIns/KizbaTests.xctest/Contents/Info.plist

SwiftCompile normal arm64 Compiling\ DomainModelsRefinementTests.swift,\ DomainModelsTests.swift,\ DomainProtocolsTests.swift /Users/kirillsimagin/dev/my/worldproject/kizba/KizbaTests/DomainModelsRefinementTests.swift /Users/kirillsimagin/dev/my/worldproject/kizba/KizbaTests/DomainModelsTests.swift /Users/kirillsimagin/dev/my/worldproject/kizba/KizbaTests/DomainProtocolsTests.swift (in target 'KizbaTests' from project 'Kizba')

SwiftCompile normal arm64 /Users/kirillsimagin/dev/my/worldproject/kizba/KizbaTests/DomainModelsRefinementTests.swift (in target 'KizbaTests' from project 'Kizba')
    cd /Users/kirillsimagin/dev/my/worldproject/kizba
    
/Users/kirillsimagin/dev/my/worldproject/kizba/KizbaTests/DomainModelsRefinementTests.swift:51:35: warning: main actor-isolated conformance of 'PassEntry' to 'Hashable' cannot be used in nonisolated context; this is an error in the Swift 6 language mode
        let set: Set<PassEntry> = [a, b, c]
                                  ^
/Users/kirillsimagin/dev/my/worldproject/kizba/KizbaTests/DomainModelsRefinementTests.swift:52:28: warning: main actor-isolated conformance of 'PassEntry' to 'Hashable' cannot be used in nonisolated context; this is an error in the Swift 6 language mode
        XCTAssertEqual(set.count, 2)
                           ^
/Users/kirillsimagin/dev/my/worldproject/kizba/KizbaTests/DomainModelsRefinementTests.swift:53:27: warning: main actor-isolated conformance of 'PassEntry' to 'Hashable' cannot be used in nonisolated context; this is an error in the Swift 6 language mode
        XCTAssertTrue(set.contains(PassEntry(path: "a/b")))
                          ^
/Users/kirillsimagin/dev/my/worldproject/kizba/KizbaTests/DomainModelsRefinementTests.swift:65:38: warning: main actor-isolated conformance of 'PassEntry' to 'Encodable' cannot be used in nonisolated context; this is an error in the Swift 6 language mode
        let data = try JSONEncoder().encode(entry)
                                     ^
/Users/kirillsimagin/dev/my/worldproject/kizba/KizbaTests/DomainModelsRefinementTests.swift:94:38: warning: main actor-isolated conformance of 'PassMetadata' to 'Encodable' cannot be used in nonisolated context; this is an error in the Swift 6 language mode
        let data = try JSONEncoder().encode(original)
                                     ^
/Users/kirillsimagin/dev/my/worldproject/kizba/KizbaTests/DomainModelsRefinementTests.swift:95:41: warning: main actor-isolated conformance of 'PassMetadata' to 'Decodable' cannot be used in nonisolated context; this is an error in the Swift 6 language mode
        let decoded = try JSONDecoder().decode(PassMetadata.self, from: data)
                                        ^
/Users/kirillsimagin/dev/my/worldproject/kizba/KizbaTests/DomainModelsRefinementTests.swift:96:9: warning: main actor-isolated conformance of 'PassMetadata' to 'Equatable' cannot be used in nonisolated context; this is an error in the Swift 6 language mode
        XCTAssertEqual(decoded, original)
        ^
/Users/kirillsimagin/dev/my/worldproject/kizba/KizbaTests/DomainModelsRefinementTests.swift:107:9: warning: main actor-isolated conformance of 'PassMetadata' to 'Equatable' cannot be used in nonisolated context; this is an error in the Swift 6 language mode
        XCTAssertNotEqual(withNil, withEmpty)
        ^
/Users/kirillsimagin/dev/my/worldproject/kizba/KizbaTests/DomainModelsRefinementTests.swift:109:41: warning: main actor-isolated conformance of 'PassMetadata' to 'Encodable' cannot be used in nonisolated context; this is an error in the Swift 6 language mode
        let nilData = try JSONEncoder().encode(withNil)
                                        ^
/Users/kirillsimagin/dev/my/worldproject/kizba/KizbaTests/DomainModelsRefinementTests.swift:110:43: warning: main actor-isolated conformance of 'PassMetadata' to 'Encodable' cannot be used in nonisolated context; this is an error in the Swift 6 language mode
        let emptyData = try JSONEncoder().encode(withEmpty)
                                          ^
/Users/kirillsimagin/dev/my/worldproject/kizba/KizbaTests/DomainModelsRefinementTests.swift:111:44: warning: main actor-isolated conformance of 'PassMetadata' to 'Decodable' cannot be used in nonisolated context; this is an error in the Swift 6 language mode
        let decodedNil = try JSONDecoder().decode(PassMetadata.self, from: nilData)
                                           ^
/Users/kirillsimagin/dev/my/worldproject/kizba/KizbaTests/DomainModelsRefinementTests.swift:112:46: warning: main actor-isolated conformance of 'PassMetadata' to 'Decodable' cannot be used in nonisolated context; this is an error in the Swift 6 language mode
        let decodedEmpty = try JSONDecoder().decode(PassMetadata.self, from: emptyData)
                                             ^
/Users/kirillsimagin/dev/my/worldproject/kizba/KizbaTests/DomainModelsRefinementTests.swift:121:44: warning: main actor-isolated conformance of 'PassMetadata.Field' to 'Hashable' cannot be used in nonisolated context; this is an error in the Swift 6 language mode
        let set: Set<PassMetadata.Field> = [f1, f2, f3]
                                           ^
/Users/kirillsimagin/dev/my/worldproject/kizba/KizbaTests/DomainModelsRefinementTests.swift:122:28: warning: main actor-isolated conformance of 'PassMetadata.Field' to 'Hashable' cannot be used in nonisolated context; this is an error in the Swift 6 language mode
        XCTAssertEqual(set.count, 2)
                           ^
/Users/kirillsimagin/dev/my/worldproject/kizba/KizbaTests/DomainModelsRefinementTests.swift:141:9: warning: main actor-isolated conformance of 'PassSecret' to 'Equatable' cannot be used in nonisolated context; this is an error in the Swift 6 language mode
        XCTAssertEqual(
        ^
/Users/kirillsimagin/dev/my/worldproject/kizba/KizbaTests/DomainModelsRefinementTests.swift:145:9: warning: main actor-isolated conformance of 'PassSecret' to 'Equatable' cannot be used in nonisolated context; this is an error in the Swift 6 language mode
        XCTAssertNotEqual(
        ^
/Users/kirillsimagin/dev/my/worldproject/kizba/KizbaTests/DomainModelsRefinementTests.swift:157:9: warning: main actor-isolated conformance of 'PassSecret' to 'Equatable' cannot be used in nonisolated context; this is an error in the Swift 6 language mode
        XCTAssertEqual(s1, s2)
        ^
/Users/kirillsimagin/dev/my/worldproject/kizba/KizbaTests/DomainModelsRefinementTests.swift:231:23: warning: main actor-isolated property 'path' can not be referenced on a nonisolated actor instance
        secrets[entry.path] = secret
                      ^
Kizba.PassEntry.path:2:23: note: property declared here
@MainActor public let path: String}
                      ^
/Users/kirillsimagin/dev/my/worldproject/kizba/KizbaTests/DomainModelsRefinementTests.swift:237:42: warning: main actor-isolated property 'path' cannot be accessed from outside of the actor; this is an error in the Swift 6 language mode
        guard let secret = secrets[entry.path] else {
                           ~~~~~~~~~~~~~~^~~~~
                           await 
/Users/kirillsimagin/dev/my/worldproject/kizba/KizbaTests/DomainModelsRefinementTests.swift:267:41: warning: cannot form key path to main actor-isolated property 'path'; this is an error in the Swift 6 language mode
        XCTAssertEqual(Set(listed.map(\.path)).count, count)
                                        ^
/Users/kirillsimagin/dev/my/worldproject/kizba/KizbaTests/DomainModelsRefinementTests.swift:258:33: warning: main actor-isolated initializer 'init(path:)' cannot be called from outside of the actor; this is an error in the Swift 6 language mode
                    let entry = PassEntry(path: "folder/item-\(index)")
                                ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
                                await 
/Users/kirillsimagin/dev/my/worldproject/kizba/KizbaTests/DomainModelsRefinementTests.swift:259:34: warning: main actor-isolated initializer 'init(password:metadata:)' cannot be called from outside of the actor; this is an error in the Swift 6 language mode
                    let secret = PassSecret(password: "pwd-\(index)")
                                 ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
                                 await 
/Users/kirillsimagin/dev/my/worldproject/kizba/KizbaTests/DomainModelsRefinementTests.swift:276:25: warning: main actor-isolated initializer 'init(path:)' cannot be called from outside of the actor; this is an error in the Swift 6 language mode
            let entry = PassEntry(path: "f/\(index)")
                        ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~
                        await 
/Users/kirillsimagin/dev/my/worldproject/kizba/KizbaTests/DomainModelsRefinementTests.swift:277:26: warning: main actor-isolated initializer 'init(password:metadata:)' cannot be called from outside of the actor; this is an error in the Swift 6 language mode
            let secret = PassSecret(password: "pwd-\(index)")
                         ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
                         await 
/Users/kirillsimagin/dev/my/worldproject/kizba/KizbaTests/DomainModelsRefinementTests.swift:287:33: warning: main actor-isolated initializer 'init(path:)' cannot be called from outside of the actor; this is an error in the Swift 6 language mode
                    let entry = PassEntry(path: "f/\(index)")
                                ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~
                                await 
/Users/kirillsimagin/dev/my/worldproject/kizba/KizbaTests/DomainModelsRefinementTests.swift:289:44: warning: main actor-isolated property 'password' cannot be accessed from outside of the actor; this is an error in the Swift 6 language mode
                    return (index, secret?.password)
                           ~~~~~~~~~~~~~~~~^~~~~~~~~
                           await 

SwiftCompile normal arm64 /Users/kirillsimagin/dev/my/worldproject/kizba/KizbaTests/DomainModelsTests.swift (in target 'KizbaTests' from project 'Kizba')
    cd /Users/kirillsimagin/dev/my/worldproject/kizba
    
/Users/kirillsimagin/dev/my/worldproject/kizba/KizbaTests/DomainModelsTests.swift:28:9: warning: main actor-isolated conformance of 'PassEntry' to 'Equatable' cannot be used in nonisolated context; this is an error in the Swift 6 language mode
        XCTAssertEqual(PassEntry(path: "a/b"), PassEntry(path: "a/b"))
        ^
/Users/kirillsimagin/dev/my/worldproject/kizba/KizbaTests/DomainModelsTests.swift:29:9: warning: main actor-isolated conformance of 'PassEntry' to 'Equatable' cannot be used in nonisolated context; this is an error in the Swift 6 language mode
        XCTAssertNotEqual(PassEntry(path: "a/b"), PassEntry(path: "a/c"))
        ^
/Users/kirillsimagin/dev/my/worldproject/kizba/KizbaTests/DomainModelsTests.swift:34:38: warning: main actor-isolated conformance of 'PassEntry' to 'Encodable' cannot be used in nonisolated context; this is an error in the Swift 6 language mode
        let data = try JSONEncoder().encode(original)
                                     ^
/Users/kirillsimagin/dev/my/worldproject/kizba/KizbaTests/DomainModelsTests.swift:35:41: warning: main actor-isolated conformance of 'PassEntry' to 'Decodable' cannot be used in nonisolated context; this is an error in the Swift 6 language mode
        let decoded = try JSONDecoder().decode(PassEntry.self, from: data)
                                        ^
/Users/kirillsimagin/dev/my/worldproject/kizba/KizbaTests/DomainModelsTests.swift:36:9: warning: main actor-isolated conformance of 'PassEntry' to 'Equatable' cannot be used in nonisolated context; this is an error in the Swift 6 language mode
        XCTAssertEqual(decoded, original)
        ^
/Users/kirillsimagin/dev/my/worldproject/kizba/KizbaTests/DomainModelsTests.swift:61:38: warning: main actor-isolated conformance of 'PassMetadata' to 'Encodable' cannot be used in nonisolated context; this is an error in the Swift 6 language mode
        let data = try JSONEncoder().encode(original)
                                     ^
/Users/kirillsimagin/dev/my/worldproject/kizba/KizbaTests/DomainModelsTests.swift:62:41: warning: main actor-isolated conformance of 'PassMetadata' to 'Decodable' cannot be used in nonisolated context; this is an error in the Swift 6 language mode
        let decoded = try JSONDecoder().decode(PassMetadata.self, from: data)
                                        ^
/Users/kirillsimagin/dev/my/worldproject/kizba/KizbaTests/DomainModelsTests.swift:63:9: warning: main actor-isolated conformance of 'PassMetadata' to 'Equatable' cannot be used in nonisolated context; this is an error in the Swift 6 language mode
        XCTAssertEqual(decoded, original)
        ^
/Users/kirillsimagin/dev/my/worldproject/kizba/KizbaTests/DomainModelsTests.swift:83:9: warning: main actor-isolated conformance of 'PassSecret' to 'Equatable' cannot be used in nonisolated context; this is an error in the Swift 6 language mode
        XCTAssertEqual(secret, PassSecret(
        ^

SwiftCompile normal arm64 /Users/kirillsimagin/dev/my/worldproject/kizba/KizbaTests/DomainProtocolsTests.swift (in target 'KizbaTests' from project 'Kizba')
    cd /Users/kirillsimagin/dev/my/worldproject/kizba
    
/Users/kirillsimagin/dev/my/worldproject/kizba/KizbaTests/DomainProtocolsTests.swift:37:42: warning: main actor-isolated property 'path' cannot be accessed from outside of the actor; this is an error in the Swift 6 language mode
        guard let secret = secrets[entry.path] else {
                           ~~~~~~~~~~~~~~^~~~~
                           await 
/Users/kirillsimagin/dev/my/worldproject/kizba/KizbaTests/DomainProtocolsTests.swift:49:21: warning: main actor-isolated initializer 'init(path:)' cannot be called from outside of the actor; this is an error in the Swift 6 language mode
        let entry = PassEntry(path: "work/aws/root")
                    ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
                    await 
/Users/kirillsimagin/dev/my/worldproject/kizba/KizbaTests/DomainProtocolsTests.swift:66:9: warning: main actor-isolated conformance of 'PassSecret' to 'Equatable' cannot be used in caller isolation inheriting-isolated context; this is an error in the Swift 6 language mode
        XCTAssertEqual(decrypted, secret)
        ^
/Users/kirillsimagin/dev/my/worldproject/kizba/KizbaTests/DomainProtocolsTests.swift:56:21: warning: main actor-isolated initializer 'init(path:)' cannot be called from outside of the actor; this is an error in the Swift 6 language mode
        let entry = PassEntry(path: "work/aws/root")
                    ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
                    await 
/Users/kirillsimagin/dev/my/worldproject/kizba/KizbaTests/DomainProtocolsTests.swift:57:22: warning: expression is 'async' but is not marked with 'await'; this is an error in the Swift 6 language mode
        let secret = PassSecret(
                     ^~~~~~~~~~~
                     await 
/Users/kirillsimagin/dev/my/worldproject/kizba/KizbaTests/DomainProtocolsTests.swift:57:22: note: calls to initializer 'init(password:metadata:)' from outside of its actor context are implicitly asynchronous
        let secret = PassSecret(
                     ^
/Users/kirillsimagin/dev/my/worldproject/kizba/KizbaTests/DomainProtocolsTests.swift:59:23: note: calls to initializer 'init(fields:notes:)' from outside of its actor context are implicitly asynchronous
            metadata: PassMetadata(fields: [.init(key: "url", value: "https://aws")])
                      ^
/Users/kirillsimagin/dev/my/worldproject/kizba/KizbaTests/DomainProtocolsTests.swift:59:45: note: calls to initializer 'init(key:value:)' from outside of its actor context are implicitly asynchronous
            metadata: PassMetadata(fields: [.init(key: "url", value: "https://aws")])
                                            ^
/Users/kirillsimagin/dev/my/worldproject/kizba/KizbaTests/DomainProtocolsTests.swift:63:29: warning: main actor-isolated property 'path' cannot be accessed from outside of the actor; this is an error in the Swift 6 language mode
            secrets: [entry.path: secret]
~~~~~~~~~~~~~~~~~~~~~~~~~~~~^~~~~~~~~~~~~
/Users/kirillsimagin/dev/my/worldproject/kizba/KizbaTests/DomainProtocolsTests.swift:118:14: warning: instance method 'lock' is unavailable from asynchronous contexts; Use async-safe scoped locking instead; this is an error in the Swift 6 language mode
        lock.lock()
             ^
Foundation.NSLock.lock:2:11: note: 'lock()' declared here
open func lock()}
          ^
/Users/kirillsimagin/dev/my/worldproject/kizba/KizbaTests/DomainProtocolsTests.swift:125:14: warning: instance method 'unlock' is unavailable from asynchronous contexts; Use async-safe scoped locking instead; this is an error in the Swift 6 language mode
        lock.unlock()
             ^
Foundation.NSLock.unlock:2:11: note: 'unlock()' declared here
open func unlock()}
          ^
/Users/kirillsimagin/dev/my/worldproject/kizba/KizbaTests/DomainProtocolsTests.swift:145:9: warning: main actor-isolated conformance of 'ShellResult' to 'Equatable' cannot be used in caller isolation inheriting-isolated context; this is an error in the Swift 6 language mode
        XCTAssertEqual(result, expected)
        ^
/Users/kirillsimagin/dev/my/worldproject/kizba/KizbaTests/DomainProtocolsTests.swift:171:14: warning: instance method 'lock' is unavailable from asynchronous contexts; Use async-safe scoped locking instead; this is an error in the Swift 6 language mode
        lock.lock()
             ^
Foundation.NSLock.lock:2:11: note: 'lock()' declared here
open func lock()}
          ^
/Users/kirillsimagin/dev/my/worldproject/kizba/KizbaTests/DomainProtocolsTests.swift:173:14: warning: instance method 'unlock' is unavailable from asynchronous contexts; Use async-safe scoped locking instead; this is an error in the Swift 6 language mode
        lock.unlock()
             ^
Foundation.NSLock.unlock:2:11: note: 'unlock()' declared here
open func unlock()}
          ^

SwiftCompile normal arm64 Compiling\ AppStateTests.swift,\ BinaryDiscoveryServiceTests.swift,\ ClipboardServiceTests.swift,\ DiagnosticsModelTests.swift /Users/kirillsimagin/dev/my/worldproject/kizba/KizbaTests/AppStateTests.swift /Users/kirillsimagin/dev/my/worldproject/kizba/KizbaTests/BinaryDiscoveryServiceTests.swift /Users/kirillsimagin/dev/my/worldproject/kizba/KizbaTests/ClipboardServiceTests.swift /Users/kirillsimagin/dev/my/worldproject/kizba/KizbaTests/DiagnosticsModelTests.swift (in target 'KizbaTests' from project 'Kizba')

SwiftCompile normal arm64 /Users/kirillsimagin/dev/my/worldproject/kizba/KizbaTests/AppStateTests.swift (in target 'KizbaTests' from project 'Kizba')
    cd /Users/kirillsimagin/dev/my/worldproject/kizba
    

SwiftCompile normal arm64 /Users/kirillsimagin/dev/my/worldproject/kizba/KizbaTests/BinaryDiscoveryServiceTests.swift (in target 'KizbaTests' from project 'Kizba')
    cd /Users/kirillsimagin/dev/my/worldproject/kizba
    
/Users/kirillsimagin/dev/my/worldproject/kizba/KizbaTests/BinaryDiscoveryServiceTests.swift:63:23: warning: main actor-isolated initializer 'init(overridePaths:pathOverride:environmentReader:fileChecker:)' cannot be called from outside of the actor; this is an error in the Swift 6 language mode
        let service = BinaryDiscoveryService(
                      ^~~~~~~~~~~~~~~~~~~~~~~
                      await 
/Users/kirillsimagin/dev/my/worldproject/kizba/KizbaTests/BinaryDiscoveryServiceTests.swift:81:23: warning: main actor-isolated initializer 'init(overridePaths:pathOverride:environmentReader:fileChecker:)' cannot be called from outside of the actor; this is an error in the Swift 6 language mode
        let service = BinaryDiscoveryService(
                      ^~~~~~~~~~~~~~~~~~~~~~~
                      await 
/Users/kirillsimagin/dev/my/worldproject/kizba/KizbaTests/BinaryDiscoveryServiceTests.swift:103:23: warning: main actor-isolated initializer 'init(overridePaths:pathOverride:environmentReader:fileChecker:)' cannot be called from outside of the actor; this is an error in the Swift 6 language mode
        let service = BinaryDiscoveryService(
                      ^~~~~~~~~~~~~~~~~~~~~~~
                      await 
/Users/kirillsimagin/dev/my/worldproject/kizba/KizbaTests/BinaryDiscoveryServiceTests.swift:124:23: warning: main actor-isolated initializer 'init(overridePaths:pathOverride:environmentReader:fileChecker:)' cannot be called from outside of the actor; this is an error in the Swift 6 language mode
        let service = BinaryDiscoveryService(
                      ^~~~~~~~~~~~~~~~~~~~~~~
                      await 
/Users/kirillsimagin/dev/my/worldproject/kizba/KizbaTests/BinaryDiscoveryServiceTests.swift:157:23: warning: main actor-isolated initializer 'init(overridePaths:pathOverride:environmentReader:fileChecker:)' cannot be called from outside of the actor; this is an error in the Swift 6 language mode
        let service = BinaryDiscoveryService(
                      ^~~~~~~~~~~~~~~~~~~~~~~
                      await 
/Users/kirillsimagin/dev/my/worldproject/kizba/KizbaTests/BinaryDiscoveryServiceTests.swift:175:23: warning: main actor-isolated initializer 'init(overridePaths:pathOverride:environmentReader:fileChecker:)' cannot be called from outside of the actor; this is an error in the Swift 6 language mode
        let service = BinaryDiscoveryService(
                      ^~~~~~~~~~~~~~~~~~~~~~~
                      await 

SwiftCompile normal arm64 /Users/kirillsimagin/dev/my/worldproject/kizba/KizbaTests/ClipboardServiceTests.swift (in target 'KizbaTests' from project 'Kizba')
    cd /Users/kirillsimagin/dev/my/worldproject/kizba
    
/Users/kirillsimagin/dev/my/worldproject/kizba/KizbaTests/ClipboardServiceTests.swift:30:23: warning: main actor-isolated initializer 'init(adapter:)' cannot be called from outside of the actor; this is an error in the Swift 6 language mode
        let service = ClipboardService(adapter: fake)
                      ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
                      await 
/Users/kirillsimagin/dev/my/worldproject/kizba/KizbaTests/ClipboardServiceTests.swift:46:23: warning: main actor-isolated initializer 'init(adapter:)' cannot be called from outside of the actor; this is an error in the Swift 6 language mode
        let service = ClipboardService(adapter: fake)
                      ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
                      await 
/Users/kirillsimagin/dev/my/worldproject/kizba/KizbaTests/ClipboardServiceTests.swift:69:23: warning: main actor-isolated initializer 'init(adapter:)' cannot be called from outside of the actor; this is an error in the Swift 6 language mode
        let service = ClipboardService(adapter: fake)
                      ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
                      await 
/Users/kirillsimagin/dev/my/worldproject/kizba/KizbaTests/ClipboardServiceTests.swift:96:23: warning: main actor-isolated initializer 'init(adapter:)' cannot be called from outside of the actor; this is an error in the Swift 6 language mode
        let service = ClipboardService(adapter: fake)
                      ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
                      await 
/Users/kirillsimagin/dev/my/worldproject/kizba/KizbaTests/ClipboardServiceTests.swift:128:23: warning: main actor-isolated initializer 'init(adapter:)' cannot be called from outside of the actor; this is an error in the Swift 6 language mode
        let service = ClipboardService(adapter: fake)
                      ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
                      await 
/Users/kirillsimagin/dev/my/worldproject/kizba/KizbaTests/ClipboardServiceTests.swift:183:18: warning: instance method 'lock' is unavailable from asynchronous contexts; Use async-safe scoped locking instead; this is an error in the Swift 6 language mode
            lock.lock(); defer { lock.unlock() }
                 ^
Foundation.NSLock.lock:2:11: note: 'lock()' declared here
open func lock()}
          ^
/Users/kirillsimagin/dev/my/worldproject/kizba/KizbaTests/ClipboardServiceTests.swift:183:39: warning: instance method 'unlock' is unavailable from asynchronous contexts; Use async-safe scoped locking instead; this is an error in the Swift 6 language mode
            lock.lock(); defer { lock.unlock() }
                                      ^
Foundation.NSLock.unlock:2:11: note: 'unlock()' declared here
open func unlock()}
          ^
/Users/kirillsimagin/dev/my/worldproject/kizba/KizbaTests/ClipboardServiceTests.swift:189:14: warning: instance method 'lock' is unavailable from asynchronous contexts; Use async-safe scoped locking instead; this is an error in the Swift 6 language mode
        lock.lock(); defer { lock.unlock() }
             ^
Foundation.NSLock.lock:2:11: note: 'lock()' declared here
open func lock()}
          ^
/Users/kirillsimagin/dev/my/worldproject/kizba/KizbaTests/ClipboardServiceTests.swift:189:35: warning: instance method 'unlock' is unavailable from asynchronous contexts; Use async-safe scoped locking instead; this is an error in the Swift 6 language mode
        lock.lock(); defer { lock.unlock() }
                                  ^
Foundation.NSLock.unlock:2:11: note: 'unlock()' declared here
open func unlock()}
          ^
/Users/kirillsimagin/dev/my/worldproject/kizba/KizbaTests/ClipboardServiceTests.swift:195:14: warning: instance method 'lock' is unavailable from asynchronous contexts; Use async-safe scoped locking instead; this is an error in the Swift 6 language mode
        lock.lock(); defer { lock.unlock() }
             ^
Foundation.NSLock.lock:2:11: note: 'lock()' declared here
open func lock()}
          ^
/Users/kirillsimagin/dev/my/worldproject/kizba/KizbaTests/ClipboardServiceTests.swift:195:35: warning: instance method 'unlock' is unavailable from asynchronous contexts; Use async-safe scoped locking instead; this is an error in the Swift 6 language mode
        lock.lock(); defer { lock.unlock() }
                                  ^
Foundation.NSLock.unlock:2:11: note: 'unlock()' declared here
open func unlock()}
          ^

SwiftCompile normal arm64 /Users/kirillsimagin/dev/my/worldproject/kizba/KizbaTests/DiagnosticsModelTests.swift (in target 'KizbaTests' from project 'Kizba')
    cd /Users/kirillsimagin/dev/my/worldproject/kizba
    

SwiftCompile normal arm64 Compiling\ TempStoreFixture.swift,\ AppEnvironmentClipboardTests.swift,\ AppEnvironmentPassCLITests.swift,\ AppEnvironmentTests.swift /Users/kirillsimagin/dev/my/worldproject/kizba/KizbaTests/Fixtures/TempStoreFixture.swift /Users/kirillsimagin/dev/my/worldproject/kizba/KizbaTests/AppEnvironmentClipboardTests.swift /Users/kirillsimagin/dev/my/worldproject/kizba/KizbaTests/AppEnvironmentPassCLITests.swift /Users/kirillsimagin/dev/my/worldproject/kizba/KizbaTests/AppEnvironmentTests.swift (in target 'KizbaTests' from project 'Kizba')

SwiftCompile normal arm64 /Users/kirillsimagin/dev/my/worldproject/kizba/KizbaTests/Fixtures/TempStoreFixture.swift (in target 'KizbaTests' from project 'Kizba')
    cd /Users/kirillsimagin/dev/my/worldproject/kizba
    

SwiftCompile normal arm64 /Users/kirillsimagin/dev/my/worldproject/kizba/KizbaTests/AppEnvironmentClipboardTests.swift (in target 'KizbaTests' from project 'Kizba')
    cd /Users/kirillsimagin/dev/my/worldproject/kizba
    

SwiftCompile normal arm64 /Users/kirillsimagin/dev/my/worldproject/kizba/KizbaTests/AppEnvironmentPassCLITests.swift (in target 'KizbaTests' from project 'Kizba')
    cd /Users/kirillsimagin/dev/my/worldproject/kizba
    
/Users/kirillsimagin/dev/my/worldproject/kizba/KizbaTests/AppEnvironmentPassCLITests.swift:30:38: warning: main actor-isolated property 'passCLI' can not be referenced from a nonisolated autoclosure
        let cli = try? XCTUnwrap(env.passCLI)
                                     ^
Kizba.AppEnvironment.passCLI:2:25: note: property declared here
@MainActor internal let passCLI: Kizba.LivePassCLI?}
                        ^
/Users/kirillsimagin/dev/my/worldproject/kizba/KizbaTests/AppEnvironmentPassCLITests.swift:29:34: warning: main actor-isolated static method 'live()' cannot be called from outside of the actor; this is an error in the Swift 6 language mode
        let env = AppEnvironment.live()
                  ~~~~~~~~~~~~~~~^~~~~~
                  await 

SwiftCompile normal arm64 /Users/kirillsimagin/dev/my/worldproject/kizba/KizbaTests/AppEnvironmentTests.swift (in target 'KizbaTests' from project 'Kizba')
    cd /Users/kirillsimagin/dev/my/worldproject/kizba
    
/Users/kirillsimagin/dev/my/worldproject/kizba/KizbaTests/AppEnvironmentTests.swift:22:39: warning: main actor-isolated property 'path' can not be referenced from a nonisolated autoclosure
        XCTAssertEqual(entries.first?.path, "personal/email/gmail")
                                      ^
Kizba.PassEntry.path:2:23: note: property declared here
@MainActor public let path: String}
                      ^
/Users/kirillsimagin/dev/my/worldproject/kizba/KizbaTests/AppEnvironmentTests.swift:23:38: warning: main actor-isolated property 'path' can not be referenced from a nonisolated autoclosure
        XCTAssertEqual(entries.last?.path,  "archive/services/ftp")
                                     ^
Kizba.PassEntry.path:2:23: note: property declared here
@MainActor public let path: String}
                      ^
/Users/kirillsimagin/dev/my/worldproject/kizba/KizbaTests/AppEnvironmentTests.swift:18:34: warning: main actor-isolated static method 'preview()' cannot be called from outside of the actor; this is an error in the Swift 6 language mode
        let env = AppEnvironment.preview()
                  ~~~~~~~~~~~~~~~^~~~~~~~~
                  await 
/Users/kirillsimagin/dev/my/worldproject/kizba/KizbaTests/AppEnvironmentTests.swift:32:31: warning: main actor-isolated property 'password' can not be referenced from a nonisolated autoclosure
        XCTAssertEqual(secret.password, "aws-root-MFA-required")
                              ^
Kizba.PassSecret.password:2:23: note: property declared here
@MainActor public let password: String}
                      ^
/Users/kirillsimagin/dev/my/worldproject/kizba/KizbaTests/AppEnvironmentTests.swift:34:64: warning: main actor-isolated property 'value' can not be referenced from a nonisolated autoclosure
            secret.metadata.fields.first { $0.key == "user" }?.value,
                                                               ^
Kizba.PassMetadata.Field.value:3:23: note: property declared here
@MainActor public let value: String  }
                      ^
/Users/kirillsimagin/dev/my/worldproject/kizba/KizbaTests/AppEnvironmentTests.swift:34:29: warning: main actor-isolated property 'fields' can not be referenced from a nonisolated autoclosure
            secret.metadata.fields.first { $0.key == "user" }?.value,
                            ^
Kizba.PassMetadata.fields:2:23: note: property declared here
@MainActor public var fields: [Kizba.PassMetadata.Field]}
                      ^
/Users/kirillsimagin/dev/my/worldproject/kizba/KizbaTests/AppEnvironmentTests.swift:34:20: warning: main actor-isolated property 'metadata' can not be referenced from a nonisolated autoclosure
            secret.metadata.fields.first { $0.key == "user" }?.value,
                   ^
Kizba.PassSecret.metadata:2:23: note: property declared here
@MainActor public let metadata: Kizba.PassMetadata}
                      ^
/Users/kirillsimagin/dev/my/worldproject/kizba/KizbaTests/AppEnvironmentTests.swift:34:47: warning: main actor-isolated property 'key' can not be referenced from a nonisolated context
            secret.metadata.fields.first { $0.key == "user" }?.value,
                                              ^
Kizba.PassMetadata.Field.key:3:23: note: property declared here
@MainActor public let key: String  }
                      ^
/Users/kirillsimagin/dev/my/worldproject/kizba/KizbaTests/AppEnvironmentTests.swift:27:34: warning: main actor-isolated static method 'preview()' cannot be called from outside of the actor; this is an error in the Swift 6 language mode
        let env = AppEnvironment.preview()
                  ~~~~~~~~~~~~~~~^~~~~~~~~
                  await 
/Users/kirillsimagin/dev/my/worldproject/kizba/KizbaTests/AppEnvironmentTests.swift:28:21: warning: main actor-isolated initializer 'init(path:)' cannot be called from outside of the actor; this is an error in the Swift 6 language mode
        let entry = PassEntry(path: "work/aws/root")
                    ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
                    await 
/Users/kirillsimagin/dev/my/worldproject/kizba/KizbaTests/AppEnvironmentTests.swift:42:17: warning: main actor-isolated property 'passManager' can not be referenced from a nonisolated autoclosure
            env.passManager.storeLocation(),
                ^
Kizba.AppEnvironment.passManager:2:25: note: property declared here
@MainActor internal let passManager: any Kizba.PassManaging}
                        ^
/Users/kirillsimagin/dev/my/worldproject/kizba/KizbaTests/AppEnvironmentTests.swift:42:29: warning: call to main actor-isolated instance method 'storeLocation()' in a synchronous nonisolated context
            env.passManager.storeLocation(),
                            ^
Kizba.PassManaging.storeLocation:2:17: note: calls to instance method 'storeLocation()' from outside of its actor context are implicitly asynchronous
@MainActor func storeLocation() -> URL}
                ^
/Users/kirillsimagin/dev/my/worldproject/kizba/KizbaTests/AppEnvironmentTests.swift:40:34: warning: main actor-isolated static method 'preview()' cannot be called from outside of the actor; this is an error in the Swift 6 language mode
        let env = AppEnvironment.preview()
                  ~~~~~~~~~~~~~~~^~~~~~~~~
                  await 

SwiftEmitModule normal arm64 Emitting\ module\ for\ KizbaTests (in target 'KizbaTests' from project 'Kizba')

EmitSwiftModule normal arm64 (in target 'KizbaTests' from project 'Kizba')
    cd /Users/kirillsimagin/dev/my/worldproject/kizba
    

SwiftCompile normal arm64 Compiling\ ProcessShellRunnerInvocationTests.swift,\ ProcessShellRunnerTests.swift,\ SettingsModelTests.swift /Users/kirillsimagin/dev/my/worldproject/kizba/KizbaTests/ProcessShellRunnerInvocationTests.swift /Users/kirillsimagin/dev/my/worldproject/kizba/KizbaTests/ProcessShellRunnerTests.swift /Users/kirillsimagin/dev/my/worldproject/kizba/KizbaTests/SettingsModelTests.swift (in target 'KizbaTests' from project 'Kizba')

SwiftCompile normal arm64 /Users/kirillsimagin/dev/my/worldproject/kizba/KizbaTests/ProcessShellRunnerInvocationTests.swift (in target 'KizbaTests' from project 'Kizba')
    cd /Users/kirillsimagin/dev/my/worldproject/kizba
    
/Users/kirillsimagin/dev/my/worldproject/kizba/KizbaTests/ProcessShellRunnerInvocationTests.swift:42:31: warning: main actor-isolated property 'exitCode' can not be referenced from a nonisolated autoclosure
        XCTAssertEqual(result.exitCode, 0)
                              ^
Kizba.ShellResult.exitCode:2:23: note: property declared here
@MainActor public let exitCode: Int32}
                      ^
/Users/kirillsimagin/dev/my/worldproject/kizba/KizbaTests/ProcessShellRunnerInvocationTests.swift:48:36: warning: main actor-isolated property 'executable' can not be referenced from a nonisolated autoclosure
        XCTAssertEqual((invocation.executable as NSString).lastPathComponent, "echo")
                                   ^
Kizba.Invocation.executable:2:23: note: property declared here
@MainActor public let executable: String}
                      ^
/Users/kirillsimagin/dev/my/worldproject/kizba/KizbaTests/ProcessShellRunnerInvocationTests.swift:49:35: warning: main actor-isolated property 'args' can not be referenced from a nonisolated autoclosure
        XCTAssertEqual(invocation.args, ["hello"])
                                  ^
Kizba.Invocation.args:2:23: note: property declared here
@MainActor public let args: [String]}
                      ^
/Users/kirillsimagin/dev/my/worldproject/kizba/KizbaTests/ProcessShellRunnerInvocationTests.swift:50:35: warning: main actor-isolated property 'exitCode' can not be referenced from a nonisolated autoclosure
        XCTAssertEqual(invocation.exitCode, 0)
                                  ^
Kizba.Invocation.exitCode:2:23: note: property declared here
@MainActor public let exitCode: Int32}
                      ^
/Users/kirillsimagin/dev/my/worldproject/kizba/KizbaTests/ProcessShellRunnerInvocationTests.swift:51:35: warning: main actor-isolated property 'stderrExcerpt' can not be referenced from a nonisolated autoclosure
        XCTAssertEqual(invocation.stderrExcerpt, "")
                                  ^
Kizba.Invocation.stderrExcerpt:2:23: note: property declared here
@MainActor public let stderrExcerpt: String}
                      ^
/Users/kirillsimagin/dev/my/worldproject/kizba/KizbaTests/ProcessShellRunnerInvocationTests.swift:52:48: warning: main actor-isolated property 'duration' can not be referenced from a nonisolated autoclosure
        XCTAssertGreaterThanOrEqual(invocation.duration, 0)
                                               ^
Kizba.Invocation.duration:2:23: note: property declared here
@MainActor public let duration: TimeInterval}
                      ^
/Users/kirillsimagin/dev/my/worldproject/kizba/KizbaTests/ProcessShellRunnerInvocationTests.swift:33:19: warning: main actor-isolated initializer 'init(maxEntries:)' cannot be called from outside of the actor; this is an error in the Swift 6 language mode
        let log = InvocationLog()
                  ^~~~~~~~~~~~~~~
                  await 
/Users/kirillsimagin/dev/my/worldproject/kizba/KizbaTests/ProcessShellRunnerInvocationTests.swift:77:36: warning: main actor-isolated property 'exitCode' can not be referenced from a nonisolated autoclosure
        XCTAssertEqual(invocation?.exitCode, -3)
                                   ^
Kizba.Invocation.exitCode:2:23: note: property declared here
@MainActor public let exitCode: Int32}
                      ^
/Users/kirillsimagin/dev/my/worldproject/kizba/KizbaTests/ProcessShellRunnerInvocationTests.swift:78:36: warning: main actor-isolated property 'stderrExcerpt' can not be referenced from a nonisolated autoclosure
        XCTAssertEqual(invocation?.stderrExcerpt, "timed out")
                                   ^
Kizba.Invocation.stderrExcerpt:2:23: note: property declared here
@MainActor public let stderrExcerpt: String}
                      ^
/Users/kirillsimagin/dev/my/worldproject/kizba/KizbaTests/ProcessShellRunnerInvocationTests.swift:56:19: warning: main actor-isolated initializer 'init(maxEntries:)' cannot be called from outside of the actor; this is an error in the Swift 6 language mode
        let log = InvocationLog()
                  ^~~~~~~~~~~~~~~
                  await 
/Users/kirillsimagin/dev/my/worldproject/kizba/KizbaTests/ProcessShellRunnerInvocationTests.swift:102:36: warning: main actor-isolated property 'exitCode' can not be referenced from a nonisolated autoclosure
        XCTAssertEqual(invocation?.exitCode, -2)
                                   ^
Kizba.Invocation.exitCode:2:23: note: property declared here
@MainActor public let exitCode: Int32}
                      ^
/Users/kirillsimagin/dev/my/worldproject/kizba/KizbaTests/ProcessShellRunnerInvocationTests.swift:103:36: warning: main actor-isolated property 'stderrExcerpt' can not be referenced from a nonisolated autoclosure
        XCTAssertEqual(invocation?.stderrExcerpt, "cancelled")
                                   ^
Kizba.Invocation.stderrExcerpt:2:23: note: property declared here
@MainActor public let stderrExcerpt: String}
                      ^
/Users/kirillsimagin/dev/my/worldproject/kizba/KizbaTests/ProcessShellRunnerInvocationTests.swift:82:19: warning: main actor-isolated initializer 'init(maxEntries:)' cannot be called from outside of the actor; this is an error in the Swift 6 language mode
        let log = InvocationLog()
                  ^~~~~~~~~~~~~~~
                  await 

SwiftCompile normal arm64 /Users/kirillsimagin/dev/my/worldproject/kizba/KizbaTests/ProcessShellRunnerTests.swift (in target 'KizbaTests' from project 'Kizba')
    cd /Users/kirillsimagin/dev/my/worldproject/kizba
    
/Users/kirillsimagin/dev/my/worldproject/kizba/KizbaTests/ProcessShellRunnerTests.swift:32:31: warning: main actor-isolated property 'exitCode' can not be referenced from a nonisolated autoclosure
        XCTAssertEqual(result.exitCode, 0)
                              ^
Kizba.ShellResult.exitCode:2:23: note: property declared here
@MainActor public let exitCode: Int32}
                      ^
/Users/kirillsimagin/dev/my/worldproject/kizba/KizbaTests/ProcessShellRunnerTests.swift:34:44: warning: main actor-isolated property 'standardOutput' can not be referenced from a nonisolated autoclosure
        XCTAssertEqual(String(data: result.standardOutput, encoding: .utf8), "hello\n")
                                           ^
Kizba.ShellResult.standardOutput:2:23: note: property declared here
@MainActor public let standardOutput: Data}
                      ^
/Users/kirillsimagin/dev/my/worldproject/kizba/KizbaTests/ProcessShellRunnerTests.swift:35:30: warning: main actor-isolated property 'standardError' can not be referenced from a nonisolated autoclosure
        XCTAssertTrue(result.standardError.isEmpty)
                             ^
Kizba.ShellResult.standardError:2:23: note: property declared here
@MainActor public let standardError: Data}
                      ^
/Users/kirillsimagin/dev/my/worldproject/kizba/KizbaTests/ProcessShellRunnerTests.swift:51:34: warning: main actor-isolated property 'exitCode' can not be referenced from a nonisolated autoclosure
        XCTAssertNotEqual(result.exitCode, 0)
                                 ^
Kizba.ShellResult.exitCode:2:23: note: property declared here
@MainActor public let exitCode: Int32}
                      ^
/Users/kirillsimagin/dev/my/worldproject/kizba/KizbaTests/ProcessShellRunnerTests.swift:52:30: warning: main actor-isolated property 'standardOutput' can not be referenced from a nonisolated autoclosure
        XCTAssertTrue(result.standardOutput.isEmpty)
                             ^
Kizba.ShellResult.standardOutput:2:23: note: property declared here
@MainActor public let standardOutput: Data}
                      ^
/Users/kirillsimagin/dev/my/worldproject/kizba/KizbaTests/ProcessShellRunnerTests.swift:125:31: warning: main actor-isolated property 'exitCode' can not be referenced from a nonisolated autoclosure
        XCTAssertEqual(result.exitCode, 0)
                              ^
Kizba.ShellResult.exitCode:2:23: note: property declared here
@MainActor public let exitCode: Int32}
                      ^
/Users/kirillsimagin/dev/my/worldproject/kizba/KizbaTests/ProcessShellRunnerTests.swift:126:31: warning: main actor-isolated property 'standardOutput' can not be referenced from a nonisolated autoclosure
        XCTAssertEqual(result.standardOutput.count, 200_000,
                              ^
Kizba.ShellResult.standardOutput:2:23: note: property declared here
@MainActor public let standardOutput: Data}
                      ^
/Users/kirillsimagin/dev/my/worldproject/kizba/KizbaTests/ProcessShellRunnerTests.swift:144:31: warning: main actor-isolated property 'exitCode' can not be referenced from a nonisolated autoclosure
        XCTAssertEqual(result.exitCode, 0)
                              ^
Kizba.ShellResult.exitCode:2:23: note: property declared here
@MainActor public let exitCode: Int32}
                      ^
/Users/kirillsimagin/dev/my/worldproject/kizba/KizbaTests/ProcessShellRunnerTests.swift:146:33: warning: main actor-isolated property 'standardOutput' can not be referenced from a nonisolated autoclosure
            String(data: result.standardOutput, encoding: .utf8),
                                ^
Kizba.ShellResult.standardOutput:2:23: note: property declared here
@MainActor public let standardOutput: Data}
                      ^
/Users/kirillsimagin/dev/my/worldproject/kizba/KizbaTests/ProcessShellRunnerTests.swift:169:31: warning: main actor-isolated property 'exitCode' can not be referenced from a nonisolated autoclosure
        XCTAssertEqual(result.exitCode, 0)
                              ^
Kizba.ShellResult.exitCode:2:23: note: property declared here
@MainActor public let exitCode: Int32}
                      ^
/Users/kirillsimagin/dev/my/worldproject/kizba/KizbaTests/ProcessShellRunnerTests.swift:171:33: warning: main actor-isolated property 'standardOutput' can not be referenced from a nonisolated autoclosure
            String(data: result.standardOutput, encoding: .utf8),
                                ^
Kizba.ShellResult.standardOutput:2:23: note: property declared here
@MainActor public let standardOutput: Data}
                      ^
/Users/kirillsimagin/dev/my/worldproject/kizba/KizbaTests/ProcessShellRunnerTests.swift:191:31: warning: main actor-isolated property 'exitCode' can not be referenced from a nonisolated autoclosure
        XCTAssertEqual(result.exitCode, 0)
                              ^
Kizba.ShellResult.exitCode:2:23: note: property declared here
@MainActor public let exitCode: Int32}
                      ^
/Users/kirillsimagin/dev/my/worldproject/kizba/KizbaTests/ProcessShellRunnerTests.swift:197:33: warning: main actor-isolated property 'standardOutput' can not be referenced from a nonisolated autoclosure
            String(data: result.standardOutput, encoding: .utf8),
                                ^
Kizba.ShellResult.standardOutput:2:23: note: property declared here
@MainActor public let standardOutput: Data}
                      ^
/Users/kirillsimagin/dev/my/worldproject/kizba/KizbaTests/ProcessShellRunnerTests.swift:213:31: warning: main actor-isolated property 'exitCode' can not be referenced from a nonisolated autoclosure
        XCTAssertEqual(result.exitCode, 0)
                              ^
Kizba.ShellResult.exitCode:2:23: note: property declared here
@MainActor public let exitCode: Int32}
                      ^
/Users/kirillsimagin/dev/my/worldproject/kizba/KizbaTests/ProcessShellRunnerTests.swift:215:33: warning: main actor-isolated property 'standardOutput' can not be referenced from a nonisolated autoclosure
            String(data: result.standardOutput, encoding: .utf8),
                                ^
Kizba.ShellResult.standardOutput:2:23: note: property declared here
@MainActor public let standardOutput: Data}
                      ^

SwiftCompile normal arm64 /Users/kirillsimagin/dev/my/worldproject/kizba/KizbaTests/SettingsModelTests.swift (in target 'KizbaTests' from project 'Kizba')
    cd /Users/kirillsimagin/dev/my/worldproject/kizba
    
/Users/kirillsimagin/dev/my/worldproject/kizba/KizbaTests/SettingsModelTests.swift:44:13: warning: variable 'model' was never mutated; consider changing to 'let' constant
        var model = SettingsModel(settings: store, discovery: discovery)
        ~~~ ^
        let
/Users/kirillsimagin/dev/my/worldproject/kizba/KizbaTests/SettingsModelTests.swift:66:13: warning: variable 'model' was never mutated; consider changing to 'let' constant
        var model = SettingsModel(settings: store, discovery: discovery)
        ~~~ ^
        let

SwiftCompile normal arm64 Compiling\ EntryListModelRefreshTests.swift,\ EntryListModelTests.swift,\ EntryPathConverterTests.swift /Users/kirillsimagin/dev/my/worldproject/kizba/KizbaTests/EntryListModelRefreshTests.swift /Users/kirillsimagin/dev/my/worldproject/kizba/KizbaTests/EntryListModelTests.swift /Users/kirillsimagin/dev/my/worldproject/kizba/KizbaTests/EntryPathConverterTests.swift (in target 'KizbaTests' from project 'Kizba')

SwiftCompile normal arm64 /Users/kirillsimagin/dev/my/worldproject/kizba/KizbaTests/EntryListModelRefreshTests.swift (in target 'KizbaTests' from project 'Kizba')
    cd /Users/kirillsimagin/dev/my/worldproject/kizba
    

SwiftCompile normal arm64 /Users/kirillsimagin/dev/my/worldproject/kizba/KizbaTests/EntryListModelTests.swift (in target 'KizbaTests' from project 'Kizba')
    cd /Users/kirillsimagin/dev/my/worldproject/kizba
    

SwiftCompile normal arm64 /Users/kirillsimagin/dev/my/worldproject/kizba/KizbaTests/EntryPathConverterTests.swift (in target 'KizbaTests' from project 'Kizba')
    cd /Users/kirillsimagin/dev/my/worldproject/kizba
    

SwiftCompile normal arm64 Compiling\ SidebarModelTests.swift,\ SourceGrepTests.swift,\ UserDefaultsSettingsStoreTests.swift /Users/kirillsimagin/dev/my/worldproject/kizba/KizbaTests/SidebarModelTests.swift /Users/kirillsimagin/dev/my/worldproject/kizba/KizbaTests/SourceGrepTests.swift /Users/kirillsimagin/dev/my/worldproject/kizba/KizbaTests/UserDefaultsSettingsStoreTests.swift (in target 'KizbaTests' from project 'Kizba')

SwiftCompile normal arm64 /Users/kirillsimagin/dev/my/worldproject/kizba/KizbaTests/SidebarModelTests.swift (in target 'KizbaTests' from project 'Kizba')
    cd /Users/kirillsimagin/dev/my/worldproject/kizba
    

SwiftCompile normal arm64 /Users/kirillsimagin/dev/my/worldproject/kizba/KizbaTests/SourceGrepTests.swift (in target 'KizbaTests' from project 'Kizba')
    cd /Users/kirillsimagin/dev/my/worldproject/kizba
    

SwiftCompile normal arm64 /Users/kirillsimagin/dev/my/worldproject/kizba/KizbaTests/UserDefaultsSettingsStoreTests.swift (in target 'KizbaTests' from project 'Kizba')
    cd /Users/kirillsimagin/dev/my/worldproject/kizba
    

SwiftCompile normal arm64 Compiling\ PassErrorMapperTests.swift,\ PassShowParserTests.swift,\ PasswordStoreScannerTests.swift /Users/kirillsimagin/dev/my/worldproject/kizba/KizbaTests/PassErrorMapperTests.swift /Users/kirillsimagin/dev/my/worldproject/kizba/KizbaTests/PassShowParserTests.swift /Users/kirillsimagin/dev/my/worldproject/kizba/KizbaTests/PasswordStoreScannerTests.swift (in target 'KizbaTests' from project 'Kizba')

SwiftCompile normal arm64 /Users/kirillsimagin/dev/my/worldproject/kizba/KizbaTests/PassErrorMapperTests.swift (in target 'KizbaTests' from project 'Kizba')
    cd /Users/kirillsimagin/dev/my/worldproject/kizba
    

SwiftCompile normal arm64 /Users/kirillsimagin/dev/my/worldproject/kizba/KizbaTests/PassShowParserTests.swift (in target 'KizbaTests' from project 'Kizba')
    cd /Users/kirillsimagin/dev/my/worldproject/kizba
    

SwiftCompile normal arm64 /Users/kirillsimagin/dev/my/worldproject/kizba/KizbaTests/PasswordStoreScannerTests.swift (in target 'KizbaTests' from project 'Kizba')
    cd /Users/kirillsimagin/dev/my/worldproject/kizba
    
/Users/kirillsimagin/dev/my/worldproject/kizba/KizbaTests/PasswordStoreScannerTests.swift:22:23: warning: main actor-isolated initializer 'init(ignoreList:)' cannot be called from outside of the actor; this is an error in the Swift 6 language mode
        let scanner = PasswordStoreScanner()
                      ^~~~~~~~~~~~~~~~~~~~~~
                      await 
/Users/kirillsimagin/dev/my/worldproject/kizba/KizbaTests/PasswordStoreScannerTests.swift:53:23: warning: main actor-isolated initializer 'init(ignoreList:)' cannot be called from outside of the actor; this is an error in the Swift 6 language mode
        let scanner = PasswordStoreScanner()
                      ^~~~~~~~~~~~~~~~~~~~~~
                      await 
/Users/kirillsimagin/dev/my/worldproject/kizba/KizbaTests/PasswordStoreScannerTests.swift:66:23: warning: main actor-isolated initializer 'init(ignoreList:)' cannot be called from outside of the actor; this is an error in the Swift 6 language mode
        let scanner = PasswordStoreScanner()
                      ^~~~~~~~~~~~~~~~~~~~~~
                      await 
/Users/kirillsimagin/dev/my/worldproject/kizba/KizbaTests/PasswordStoreScannerTests.swift:88:23: warning: main actor-isolated initializer 'init(ignoreList:)' cannot be called from outside of the actor; this is an error in the Swift 6 language mode
        let scanner = PasswordStoreScanner()
                      ^~~~~~~~~~~~~~~~~~~~~~
                      await 
/Users/kirillsimagin/dev/my/worldproject/kizba/KizbaTests/PasswordStoreScannerTests.swift:104:23: warning: main actor-isolated initializer 'init(ignoreList:)' cannot be called from outside of the actor; this is an error in the Swift 6 language mode
        let scanner = PasswordStoreScanner()
                      ^~~~~~~~~~~~~~~~~~~~~~
                      await 
/Users/kirillsimagin/dev/my/worldproject/kizba/KizbaTests/PasswordStoreScannerTests.swift:123:23: warning: main actor-isolated initializer 'init(ignoreList:)' cannot be called from outside of the actor; this is an error in the Swift 6 language mode
        let scanner = PasswordStoreScanner()
                      ^~~~~~~~~~~~~~~~~~~~~~
                      await 
/Users/kirillsimagin/dev/my/worldproject/kizba/KizbaTests/PasswordStoreScannerTests.swift:153:23: warning: main actor-isolated initializer 'init(ignoreList:)' cannot be called from outside of the actor; this is an error in the Swift 6 language mode
        let scanner = PasswordStoreScanner()
                      ^~~~~~~~~~~~~~~~~~~~~~
                      await 
/Users/kirillsimagin/dev/my/worldproject/kizba/KizbaTests/PasswordStoreScannerTests.swift:167:23: warning: main actor-isolated initializer 'init(ignoreList:)' cannot be called from outside of the actor; this is an error in the Swift 6 language mode
        let scanner = PasswordStoreScanner()
                      ^~~~~~~~~~~~~~~~~~~~~~
                      await 

SwiftCompile normal arm64 Compiling\ InvocationLogTests.swift,\ KizbaTests.swift,\ LivePassManagerTests.swift /Users/kirillsimagin/dev/my/worldproject/kizba/KizbaTests/InvocationLogTests.swift /Users/kirillsimagin/dev/my/worldproject/kizba/KizbaTests/KizbaTests.swift /Users/kirillsimagin/dev/my/worldproject/kizba/KizbaTests/LivePassManagerTests.swift (in target 'KizbaTests' from project 'Kizba')

SwiftCompile normal arm64 /Users/kirillsimagin/dev/my/worldproject/kizba/KizbaTests/InvocationLogTests.swift (in target 'KizbaTests' from project 'Kizba')
    cd /Users/kirillsimagin/dev/my/worldproject/kizba
    
/Users/kirillsimagin/dev/my/worldproject/kizba/KizbaTests/InvocationLogTests.swift:41:40: warning: main actor-isolated property 'args' can not be referenced from a nonisolated context
        XCTAssertEqual(recent.map { $0.args.first }, ["4", "3", "2"])
                                       ^
Kizba.Invocation.args:2:23: note: property declared here
@MainActor public let args: [String]}
                      ^
/Users/kirillsimagin/dev/my/worldproject/kizba/KizbaTests/InvocationLogTests.swift:30:19: warning: main actor-isolated initializer 'init(maxEntries:)' cannot be called from outside of the actor; this is an error in the Swift 6 language mode
        let log = InvocationLog(maxEntries: 3)
                  ^~~~~~~~~~~~~~~~~~~~~~~~~~~~
                  await 
/Users/kirillsimagin/dev/my/worldproject/kizba/KizbaTests/InvocationLogTests.swift:45:19: warning: main actor-isolated initializer 'init(maxEntries:)' cannot be called from outside of the actor; this is an error in the Swift 6 language mode
        let log = InvocationLog()
                  ^~~~~~~~~~~~~~~
                  await 
/Users/kirillsimagin/dev/my/worldproject/kizba/KizbaTests/InvocationLogTests.swift:57:40: warning: main actor-isolated property 'args' can not be referenced from a nonisolated context
        XCTAssertEqual(recent.map { $0.args.first }, ["third", "second", "first"])
                                       ^
Kizba.Invocation.args:2:23: note: property declared here
@MainActor public let args: [String]}
                      ^
/Users/kirillsimagin/dev/my/worldproject/kizba/KizbaTests/InvocationLogTests.swift:51:19: warning: main actor-isolated initializer 'init(maxEntries:)' cannot be called from outside of the actor; this is an error in the Swift 6 language mode
        let log = InvocationLog(maxEntries: 10)
                  ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~
                  await 
/Users/kirillsimagin/dev/my/worldproject/kizba/KizbaTests/InvocationLogTests.swift:61:19: warning: main actor-isolated initializer 'init(maxEntries:)' cannot be called from outside of the actor; this is an error in the Swift 6 language mode
        let log = InvocationLog(maxEntries: 5)
                  ^~~~~~~~~~~~~~~~~~~~~~~~~~~~
                  await 
/Users/kirillsimagin/dev/my/worldproject/kizba/KizbaTests/InvocationLogTests.swift:78:38: warning: main actor-isolated property 'args' can not be referenced from a nonisolated autoclosure
        XCTAssertEqual(recent.first?.args.first, "b")
                                     ^
Kizba.Invocation.args:2:23: note: property declared here
@MainActor public let args: [String]}
                      ^
/Users/kirillsimagin/dev/my/worldproject/kizba/KizbaTests/InvocationLogTests.swift:71:19: warning: main actor-isolated initializer 'init(maxEntries:)' cannot be called from outside of the actor; this is an error in the Swift 6 language mode
        let log = InvocationLog(maxEntries: 0)
                  ^~~~~~~~~~~~~~~~~~~~~~~~~~~~
                  await 

SwiftCompile normal arm64 /Users/kirillsimagin/dev/my/worldproject/kizba/KizbaTests/KizbaTests.swift (in target 'KizbaTests' from project 'Kizba')
    cd /Users/kirillsimagin/dev/my/worldproject/kizba
    

SwiftCompile normal arm64 /Users/kirillsimagin/dev/my/worldproject/kizba/KizbaTests/LivePassManagerTests.swift (in target 'KizbaTests' from project 'Kizba')
    cd /Users/kirillsimagin/dev/my/worldproject/kizba
    
/Users/kirillsimagin/dev/my/worldproject/kizba/KizbaTests/LivePassManagerTests.swift:44:38: warning: cannot form key path to main actor-isolated property 'path'; this is an error in the Swift 6 language mode
        XCTAssertEqual(entries.map(\.path), expected)
                                     ^
/Users/kirillsimagin/dev/my/worldproject/kizba/KizbaTests/LivePassManagerTests.swift:45:38: warning: cannot form key path to main actor-isolated property 'id'; this is an error in the Swift 6 language mode
        XCTAssertEqual(entries.map(\.id), expected)
                                     ^
/Users/kirillsimagin/dev/my/worldproject/kizba/KizbaTests/LivePassManagerTests.swift:36:23: warning: main actor-isolated initializer 'init(scanner:passCLI:storeRoot:)' cannot be called from outside of the actor; this is an error in the Swift 6 language mode
        let manager = LivePassManager(
                      ^~~~~~~~~~~~~~~~
                      await 
/Users/kirillsimagin/dev/my/worldproject/kizba/KizbaTests/LivePassManagerTests.swift:54:23: warning: main actor-isolated initializer 'init(scanner:passCLI:storeRoot:)' cannot be called from outside of the actor; this is an error in the Swift 6 language mode
        let manager = LivePassManager(
                      ^~~~~~~~~~~~~~~~
                      await 
/Users/kirillsimagin/dev/my/worldproject/kizba/KizbaTests/LivePassManagerTests.swift:92:31: warning: main actor-isolated property 'password' can not be referenced from a nonisolated autoclosure
        XCTAssertEqual(secret.password, "hunter2")
                              ^
Kizba.PassSecret.password:2:23: note: property declared here
@MainActor public let password: String}
                      ^
/Users/kirillsimagin/dev/my/worldproject/kizba/KizbaTests/LivePassManagerTests.swift:93:40: warning: call to main actor-isolated instance method 'firstValue(for:)' in a synchronous nonisolated context
        XCTAssertEqual(secret.metadata.firstValue(for: "url"), "https://x.test")
                                       ^
Kizba.PassMetadata.firstValue:2:24: note: calls to instance method 'firstValue(for:)' from outside of its actor context are implicitly asynchronous
@MainActor public func firstValue(for key: String) -> String?}
                       ^
/Users/kirillsimagin/dev/my/worldproject/kizba/KizbaTests/LivePassManagerTests.swift:93:31: warning: main actor-isolated property 'metadata' can not be referenced from a nonisolated autoclosure
        XCTAssertEqual(secret.metadata.firstValue(for: "url"), "https://x.test")
                              ^
Kizba.PassSecret.metadata:2:23: note: property declared here
@MainActor public let metadata: Kizba.PassMetadata}
                      ^
/Users/kirillsimagin/dev/my/worldproject/kizba/KizbaTests/LivePassManagerTests.swift:94:40: warning: main actor-isolated property 'notes' can not be referenced from a nonisolated autoclosure
        XCTAssertEqual(secret.metadata.notes, "\nbeware of the leopard\n")
                                       ^
Kizba.PassMetadata.notes:2:23: note: property declared here
@MainActor public var notes: String?}
                      ^
/Users/kirillsimagin/dev/my/worldproject/kizba/KizbaTests/LivePassManagerTests.swift:94:31: warning: main actor-isolated property 'metadata' can not be referenced from a nonisolated autoclosure
        XCTAssertEqual(secret.metadata.notes, "\nbeware of the leopard\n")
                              ^
Kizba.PassSecret.metadata:2:23: note: property declared here
@MainActor public let metadata: Kizba.PassMetadata}
                      ^
/Users/kirillsimagin/dev/my/worldproject/kizba/KizbaTests/LivePassManagerTests.swift:76:23: warning: main actor-isolated initializer 'init(scanner:passCLI:storeRoot:)' cannot be called from outside of the actor; this is an error in the Swift 6 language mode
        let manager = LivePassManager(
                      ^~~~~~~~~~~~~~~~
                      await 
/Users/kirillsimagin/dev/my/worldproject/kizba/KizbaTests/LivePassManagerTests.swift:82:21: warning: main actor-isolated initializer 'init(path:)' cannot be called from outside of the actor; this is an error in the Swift 6 language mode
        let entry = PassEntry(path: "personal/email/gmail")
                    ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
                    await 

SwiftCompile normal arm64 Compiling\ LogWrapperTests.swift,\ MockPassManagerTests.swift,\ PassCLITests.swift /Users/kirillsimagin/dev/my/worldproject/kizba/KizbaTests/LogWrapperTests.swift /Users/kirillsimagin/dev/my/worldproject/kizba/KizbaTests/MockPassManagerTests.swift /Users/kirillsimagin/dev/my/worldproject/kizba/KizbaTests/PassCLITests.swift (in target 'KizbaTests' from project 'Kizba')

SwiftCompile normal arm64 /Users/kirillsimagin/dev/my/worldproject/kizba/KizbaTests/LogWrapperTests.swift (in target 'KizbaTests' from project 'Kizba')
    cd /Users/kirillsimagin/dev/my/worldproject/kizba
    

SwiftCompile normal arm64 /Users/kirillsimagin/dev/my/worldproject/kizba/KizbaTests/MockPassManagerTests.swift (in target 'KizbaTests' from project 'Kizba')
    cd /Users/kirillsimagin/dev/my/worldproject/kizba
    
/Users/kirillsimagin/dev/my/worldproject/kizba/KizbaTests/MockPassManagerTests.swift:26:39: warning: main actor-isolated property 'path' can not be referenced from a nonisolated autoclosure
        XCTAssertEqual(entries.first?.path, "personal/email/gmail")
                                      ^
Kizba.PassEntry.path:2:23: note: property declared here
@MainActor public let path: String}
                      ^
/Users/kirillsimagin/dev/my/worldproject/kizba/KizbaTests/MockPassManagerTests.swift:27:38: warning: main actor-isolated property 'path' can not be referenced from a nonisolated autoclosure
        XCTAssertEqual(entries.last?.path,  "archive/services/ftp")
                                     ^
Kizba.PassEntry.path:2:23: note: property declared here
@MainActor public let path: String}
                      ^
/Users/kirillsimagin/dev/my/worldproject/kizba/KizbaTests/MockPassManagerTests.swift:20:39: warning: main actor-isolated static method 'preview()' cannot be called from outside of the actor; this is an error in the Swift 6 language mode
        let manager = MockPassManager.preview()
                      ~~~~~~~~~~~~~~~~^~~~~~~~~
                      await 
/Users/kirillsimagin/dev/my/worldproject/kizba/KizbaTests/MockPassManagerTests.swift:38:45: warning: main actor-isolated property 'path' can not be referenced from a nonisolated context
        let topLevel = Set(entries.map { $0.path.split(separator: "/").first.map(String.init) ?? "" })
                                            ^
Kizba.PassEntry.path:2:23: note: property declared here
@MainActor public let path: String}
                      ^
/Users/kirillsimagin/dev/my/worldproject/kizba/KizbaTests/MockPassManagerTests.swift:44:39: warning: cannot form key path to main actor-isolated property 'path'; this is an error in the Swift 6 language mode
        let paths = Set(entries.map(\.path))
                                      ^
/Users/kirillsimagin/dev/my/worldproject/kizba/KizbaTests/MockPassManagerTests.swift:50:40: warning: main actor-isolated property 'path' can not be referenced from a nonisolated context
        let empty = entries.first { $0.path == "personal/empty-name/" }
                                       ^
Kizba.PassEntry.path:2:23: note: property declared here
@MainActor public let path: String}
                      ^
/Users/kirillsimagin/dev/my/worldproject/kizba/KizbaTests/MockPassManagerTests.swift:52:31: warning: main actor-isolated property 'name' can not be referenced from a nonisolated autoclosure
        XCTAssertEqual(empty?.name, "")
                              ^
Kizba.PassEntry.name:2:23: note: property declared here
@MainActor public var name: String { get }}
                      ^
/Users/kirillsimagin/dev/my/worldproject/kizba/KizbaTests/MockPassManagerTests.swift:63:31: warning: main actor-isolated property 'password' can not be referenced from a nonisolated autoclosure
        XCTAssertEqual(secret.password, "aws-root-MFA-required")
                              ^
Kizba.PassSecret.password:2:23: note: property declared here
@MainActor public let password: String}
                      ^
/Users/kirillsimagin/dev/my/worldproject/kizba/KizbaTests/MockPassManagerTests.swift:64:40: warning: call to main actor-isolated instance method 'firstValue(for:)' in a synchronous nonisolated context
        XCTAssertEqual(secret.metadata.firstValue(for: "user"), "root@example-org.aws")
                                       ^
Kizba.PassMetadata.firstValue:2:24: note: calls to instance method 'firstValue(for:)' from outside of its actor context are implicitly asynchronous
@MainActor public func firstValue(for key: String) -> String?}
                       ^
/Users/kirillsimagin/dev/my/worldproject/kizba/KizbaTests/MockPassManagerTests.swift:64:31: warning: main actor-isolated property 'metadata' can not be referenced from a nonisolated autoclosure
        XCTAssertEqual(secret.metadata.firstValue(for: "user"), "root@example-org.aws")
                              ^
Kizba.PassSecret.metadata:2:23: note: property declared here
@MainActor public let metadata: Kizba.PassMetadata}
                      ^
/Users/kirillsimagin/dev/my/worldproject/kizba/KizbaTests/MockPassManagerTests.swift:65:40: warning: call to main actor-isolated instance method 'firstValue(for:)' in a synchronous nonisolated context
        XCTAssertEqual(secret.metadata.firstValue(for: "mfa"),  "yubikey-5c-nfc")
                                       ^
Kizba.PassMetadata.firstValue:2:24: note: calls to instance method 'firstValue(for:)' from outside of its actor context are implicitly asynchronous
@MainActor public func firstValue(for key: String) -> String?}
                       ^
/Users/kirillsimagin/dev/my/worldproject/kizba/KizbaTests/MockPassManagerTests.swift:65:31: warning: main actor-isolated property 'metadata' can not be referenced from a nonisolated autoclosure
        XCTAssertEqual(secret.metadata.firstValue(for: "mfa"),  "yubikey-5c-nfc")
                              ^
Kizba.PassSecret.metadata:2:23: note: property declared here
@MainActor public let metadata: Kizba.PassMetadata}
                      ^
/Users/kirillsimagin/dev/my/worldproject/kizba/KizbaTests/MockPassManagerTests.swift:66:40: warning: main actor-isolated property 'notes' can not be referenced from a nonisolated autoclosure
        XCTAssertEqual(secret.metadata.notes, "Break-glass account. Use only with two-person rule.")
                                       ^
Kizba.PassMetadata.notes:2:23: note: property declared here
@MainActor public var notes: String?}
                      ^
/Users/kirillsimagin/dev/my/worldproject/kizba/KizbaTests/MockPassManagerTests.swift:66:31: warning: main actor-isolated property 'metadata' can not be referenced from a nonisolated autoclosure
        XCTAssertEqual(secret.metadata.notes, "Break-glass account. Use only with two-person rule.")
                              ^
Kizba.PassSecret.metadata:2:23: note: property declared here
@MainActor public let metadata: Kizba.PassMetadata}
                      ^
/Users/kirillsimagin/dev/my/worldproject/kizba/KizbaTests/MockPassManagerTests.swift:67:41: warning: call to main actor-isolated instance method 'firstValue(for:)' in a synchronous nonisolated context
        XCTAssertNotNil(secret.metadata.firstValue(for: "created"))
                                        ^
Kizba.PassMetadata.firstValue:2:24: note: calls to instance method 'firstValue(for:)' from outside of its actor context are implicitly asynchronous
@MainActor public func firstValue(for key: String) -> String?}
                       ^
/Users/kirillsimagin/dev/my/worldproject/kizba/KizbaTests/MockPassManagerTests.swift:67:32: warning: main actor-isolated property 'metadata' can not be referenced from a nonisolated autoclosure
        XCTAssertNotNil(secret.metadata.firstValue(for: "created"))
                               ^
Kizba.PassSecret.metadata:2:23: note: property declared here
@MainActor public let metadata: Kizba.PassMetadata}
                      ^
/Users/kirillsimagin/dev/my/worldproject/kizba/KizbaTests/MockPassManagerTests.swift:58:39: warning: main actor-isolated static method 'preview()' cannot be called from outside of the actor; this is an error in the Swift 6 language mode
        let manager = MockPassManager.preview()
                      ~~~~~~~~~~~~~~~~^~~~~~~~~
                      await 
/Users/kirillsimagin/dev/my/worldproject/kizba/KizbaTests/MockPassManagerTests.swift:59:21: warning: main actor-isolated initializer 'init(path:)' cannot be called from outside of the actor; this is an error in the Swift 6 language mode
        let entry = PassEntry(path: "work/aws/root")
                    ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
                    await 
/Users/kirillsimagin/dev/my/worldproject/kizba/KizbaTests/MockPassManagerTests.swift:74:31: warning: main actor-isolated property 'password' can not be referenced from a nonisolated autoclosure
        XCTAssertEqual(secret.password, "correct horse battery staple")
                              ^
Kizba.PassSecret.password:2:23: note: property declared here
@MainActor public let password: String}
                      ^
/Users/kirillsimagin/dev/my/worldproject/kizba/KizbaTests/MockPassManagerTests.swift:75:39: warning: main actor-isolated property 'fields' can not be referenced from a nonisolated autoclosure
        XCTAssertTrue(secret.metadata.fields.isEmpty)
                                      ^
Kizba.PassMetadata.fields:2:23: note: property declared here
@MainActor public var fields: [Kizba.PassMetadata.Field]}
                      ^
/Users/kirillsimagin/dev/my/worldproject/kizba/KizbaTests/MockPassManagerTests.swift:75:30: warning: main actor-isolated property 'metadata' can not be referenced from a nonisolated autoclosure
        XCTAssertTrue(secret.metadata.fields.isEmpty)
                             ^
Kizba.PassSecret.metadata:2:23: note: property declared here
@MainActor public let metadata: Kizba.PassMetadata}
                      ^
/Users/kirillsimagin/dev/my/worldproject/kizba/KizbaTests/MockPassManagerTests.swift:76:38: warning: main actor-isolated property 'notes' can not be referenced from a nonisolated autoclosure
        XCTAssertNil(secret.metadata.notes)
                                     ^
Kizba.PassMetadata.notes:2:23: note: property declared here
@MainActor public var notes: String?}
                      ^
/Users/kirillsimagin/dev/my/worldproject/kizba/KizbaTests/MockPassManagerTests.swift:76:29: warning: main actor-isolated property 'metadata' can not be referenced from a nonisolated autoclosure
        XCTAssertNil(secret.metadata.notes)
                            ^
Kizba.PassSecret.metadata:2:23: note: property declared here
@MainActor public let metadata: Kizba.PassMetadata}
                      ^
/Users/kirillsimagin/dev/my/worldproject/kizba/KizbaTests/MockPassManagerTests.swift:71:39: warning: main actor-isolated static method 'preview()' cannot be called from outside of the actor; this is an error in the Swift 6 language mode
        let manager = MockPassManager.preview()
                      ~~~~~~~~~~~~~~~~^~~~~~~~~
                      await 
/Users/kirillsimagin/dev/my/worldproject/kizba/KizbaTests/MockPassManagerTests.swift:80:39: warning: main actor-isolated static method 'preview()' cannot be called from outside of the actor; this is an error in the Swift 6 language mode
        let manager = MockPassManager.preview()
                      ~~~~~~~~~~~~~~~~^~~~~~~~~
                      await 
/Users/kirillsimagin/dev/my/worldproject/kizba/KizbaTests/MockPassManagerTests.swift:81:23: warning: main actor-isolated initializer 'init(path:)' cannot be called from outside of the actor; this is an error in the Swift 6 language mode
        let unknown = PassEntry(path: "nope/does-not-exist")
                      ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
                      await 
/Users/kirillsimagin/dev/my/worldproject/kizba/KizbaTests/MockPassManagerTests.swift:130:21: warning: main actor-isolated conformance of 'PassSecret' to 'Equatable' cannot be used in nonisolated context; this is an error in the Swift 6 language mode
                    XCTAssertEqual(secret, baselineSecret)
                    ^
/Users/kirillsimagin/dev/my/worldproject/kizba/KizbaTests/MockPassManagerTests.swift:117:39: warning: main actor-isolated static method 'preview()' cannot be called from outside of the actor; this is an error in the Swift 6 language mode
        let manager = MockPassManager.preview()
                      ~~~~~~~~~~~~~~~~^~~~~~~~~
                      await 
/Users/kirillsimagin/dev/my/worldproject/kizba/KizbaTests/MockPassManagerTests.swift:119:22: warning: main actor-isolated initializer 'init(path:)' cannot be called from outside of the actor; this is an error in the Swift 6 language mode
        let target = PassEntry(path: "work/github/personal-token")
                     ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
                     await 

SwiftCompile normal arm64 /Users/kirillsimagin/dev/my/worldproject/kizba/KizbaTests/PassCLITests.swift (in target 'KizbaTests' from project 'Kizba')
    cd /Users/kirillsimagin/dev/my/worldproject/kizba
    
/Users/kirillsimagin/dev/my/worldproject/kizba/KizbaTests/PassCLITests.swift:290:14: warning: instance method 'lock' is unavailable from asynchronous contexts; Use async-safe scoped locking instead; this is an error in the Swift 6 language mode
        lock.lock()
             ^
Foundation.NSLock.lock:2:11: note: 'lock()' declared here
open func lock()}
          ^
/Users/kirillsimagin/dev/my/worldproject/kizba/KizbaTests/PassCLITests.swift:292:14: warning: instance method 'unlock' is unavailable from asynchronous contexts; Use async-safe scoped locking instead; this is an error in the Swift 6 language mode
        lock.unlock()
             ^
Foundation.NSLock.unlock:2:11: note: 'unlock()' declared here
open func unlock()}
          ^

SwiftCompile normal arm64 Compiling\ EntryDetailModelCopyTests.swift,\ EntryDetailModelRefinementTests.swift,\ EntryDetailModelTests.swift /Users/kirillsimagin/dev/my/worldproject/kizba/KizbaTests/EntryDetailModelCopyTests.swift /Users/kirillsimagin/dev/my/worldproject/kizba/KizbaTests/EntryDetailModelRefinementTests.swift /Users/kirillsimagin/dev/my/worldproject/kizba/KizbaTests/EntryDetailModelTests.swift (in target 'KizbaTests' from project 'Kizba')
SwiftCompile normal arm64 /Users/kirillsimagin/dev/my/worldproject/kizba/KizbaTests/EntryDetailModelCopyTests.swift (in target 'KizbaTests' from project 'Kizba')
    cd /Users/kirillsimagin/dev/my/worldproject/kizba
    
/Users/kirillsimagin/dev/my/worldproject/kizba/KizbaTests/EntryDetailModelCopyTests.swift:104:14: warning: instance method 'lock' is unavailable from asynchronous contexts; Use async-safe scoped locking instead; this is an error in the Swift 6 language mode
        lock.lock(); defer { lock.unlock() }
             ^
Foundation.NSLock.lock:2:11: note: 'lock()' declared here
open func lock()}
          ^
/Users/kirillsimagin/dev/my/worldproject/kizba/KizbaTests/EntryDetailModelCopyTests.swift:104:35: warning: instance method 'unlock' is unavailable from asynchronous contexts; Use async-safe scoped locking instead; this is an error in the Swift 6 language mode
        lock.lock(); defer { lock.unlock() }
                                  ^
Foundation.NSLock.unlock:2:11: note: 'unlock()' declared here
open func unlock()}
          ^

SwiftCompile normal arm64 /Users/kirillsimagin/dev/my/worldproject/kizba/KizbaTests/EntryDetailModelRefinementTests.swift (in target 'KizbaTests' from project 'Kizba')
    cd /Users/kirillsimagin/dev/my/worldproject/kizba
    
/Users/kirillsimagin/dev/my/worldproject/kizba/KizbaTests/EntryDetailModelRefinementTests.swift:304:44: warning: main actor-isolated property 'path' cannot be accessed from outside of the actor; this is an error in the Swift 6 language mode
        guard let outcome = outcomes[entry.path] else {
                            ~~~~~~~~~~~~~~~^~~~~
                            await 
/Users/kirillsimagin/dev/my/worldproject/kizba/KizbaTests/EntryDetailModelRefinementTests.swift:305:85: warning: main actor-isolated property 'path' cannot be accessed from outside of the actor; this is an error in the Swift 6 language mode
            throw PassError.decryptionFailed(stderrExcerpt: "no fixture for \(entry.path)")
                                                                              ~~~~~~^~~~
                                                                              await 
/Users/kirillsimagin/dev/my/worldproject/kizba/KizbaTests/EntryDetailModelRefinementTests.swift:340:14: warning: instance method 'lock' is unavailable from asynchronous contexts; Use async-safe scoped locking instead; this is an error in the Swift 6 language mode
        lock.lock(); defer { lock.unlock() }
             ^
Foundation.NSLock.lock:2:11: note: 'lock()' declared here
open func lock()}
          ^
/Users/kirillsimagin/dev/my/worldproject/kizba/KizbaTests/EntryDetailModelRefinementTests.swift:340:35: warning: instance method 'unlock' is unavailable from asynchronous contexts; Use async-safe scoped locking instead; this is an error in the Swift 6 language mode
        lock.lock(); defer { lock.unlock() }
                                  ^
Foundation.NSLock.unlock:2:11: note: 'unlock()' declared here
open func unlock()}
          ^

SwiftCompile normal arm64 /Users/kirillsimagin/dev/my/worldproject/kizba/KizbaTests/EntryDetailModelTests.swift (in target 'KizbaTests' from project 'Kizba')
    cd /Users/kirillsimagin/dev/my/worldproject/kizba
    
/Users/kirillsimagin/dev/my/worldproject/kizba/KizbaTests/EntryDetailModelTests.swift:37:18: warning: instance method 'lock' is unavailable from asynchronous contexts; Use async-safe scoped locking instead; this is an error in the Swift 6 language mode
            lock.lock(); defer { lock.unlock() }
                 ^
Foundation.NSLock.lock:2:11: note: 'lock()' declared here
open func lock()}
          ^
/Users/kirillsimagin/dev/my/worldproject/kizba/KizbaTests/EntryDetailModelTests.swift:37:39: warning: instance method 'unlock' is unavailable from asynchronous contexts; Use async-safe scoped locking instead; this is an error in the Swift 6 language mode
            lock.lock(); defer { lock.unlock() }
                                      ^
Foundation.NSLock.unlock:2:11: note: 'unlock()' declared here
open func unlock()}
          ^
/Users/kirillsimagin/dev/my/worldproject/kizba/KizbaTests/EntryDetailModelTests.swift:64:36: warning: main actor-isolated property 'path' cannot be accessed from outside of the actor; this is an error in the Swift 6 language mode
            showCalls.append(entry.path)
            ~~~~~~~~~~~~~~~~~~~~~~~^~~~~
            await 
/Users/kirillsimagin/dev/my/worldproject/kizba/KizbaTests/EntryDetailModelTests.swift:68:46: warning: main actor-isolated property 'path' cannot be accessed from outside of the actor; this is an error in the Swift 6 language mode
            guard let secret = secrets[entry.path] else {
                               ~~~~~~~~~~~~~~^~~~~
                               await 

SwiftDriverJobDiscovery normal arm64 Compiling PassErrorMapperTests.swift, PassShowParserTests.swift, PasswordStoreScannerTests.swift (in target 'KizbaTests' from project 'Kizba')

SwiftDriverJobDiscovery normal arm64 Compiling InvocationLogTests.swift, KizbaTests.swift, LivePassManagerTests.swift (in target 'KizbaTests' from project 'Kizba')

SwiftDriverJobDiscovery normal arm64 Emitting module for KizbaTests (in target 'KizbaTests' from project 'Kizba')

SwiftDriver\ Compilation\ Requirements KizbaTests normal arm64 com.apple.xcode.tools.swift.compiler (in target 'KizbaTests' from project 'Kizba')
    cd /Users/kirillsimagin/dev/my/worldproject/kizba
    builtin-Swift-Compilation-Requirements -- /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc -module-name KizbaTests -Onone @/Users/kirillsimagin/Library/Developer/Xcode/DerivedData/Kizba-efejvmfzdmoqdoewsmanttogshar/Build/Intermediates.noindex/Kizba.build/Debug/KizbaTests.build/Objects-normal/arm64/KizbaTests.SwiftFileList -DDEBUG -plugin-path /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/lib/swift/host/plugins/testing -enable-bare-slash-regex -enable-upcoming-feature DisableOutwardActorInference -enable-upcoming-feature InferSendableFromCaptures -enable-upcoming-feature GlobalActorIsolatedTypesUsability -enable-upcoming-feature MemberImportVisibility -enable-upcoming-feature InferIsolatedConformances -enable-upcoming-feature NonisolatedNonsendingByDefault -enable-experimental-feature DebugDescriptionMacro -sdk /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX26.4.sdk -target arm64-apple-macos14.0 -g -module-cache-path /Users/kirillsimagin/Library/Developer/Xcode/DerivedData/ModuleCache.noindex -Xfrontend -serialize-debugging-options -enable-testing -index-store-path /Users/kirillsimagin/Library/Developer/Xcode/DerivedData/Kizba-efejvmfzdmoqdoewsmanttogshar/Index.noindex/DataStore -Xcc -D_LIBCPP_HARDENING_MODE\=_LIBCPP_HARDENING_MODE_DEBUG -swift-version 5 -I /Users/kirillsimagin/Library/Developer/Xcode/DerivedData/Kizba-efejvmfzdmoqdoewsmanttogshar/Build/Products/Debug -Isystem /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/usr/lib -F /Users/kirillsimagin/Library/Developer/Xcode/DerivedData/Kizba-efejvmfzdmoqdoewsmanttogshar/Build/Products/Debug -F /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/Library/Frameworks -c -j10 -enable-batch-mode -incremental -Xcc -ivfsstatcache -Xcc /Users/kirillsimagin/Library/Developer/Xcode/DerivedData/SDKStatCaches.noindex/macosx26.4-25E251-30f9ca8789b706f8bd3fc906a70d770f.sdkstatcache -output-file-map /Users/kirillsimagin/Library/Developer/Xcode/DerivedData/Kizba-efejvmfzdmoqdoewsmanttogshar/Build/Intermediates.noindex/Kizba.build/Debug/KizbaTests.build/Objects-normal/arm64/KizbaTests-OutputFileMap.json -use-frontend-parseable-output -save-temps -no-color-diagnostics -explicit-module-build -module-cache-path /Users/kirillsimagin/Library/Developer/Xcode/DerivedData/Kizba-efejvmfzdmoqdoewsmanttogshar/Build/Intermediates.noindex/SwiftExplicitPrecompiledModules -clang-scanner-module-cache-path /Users/kirillsimagin/Library/Developer/Xcode/DerivedData/ModuleCache.noindex -sdk-module-cache-path /Users/kirillsimagin/Library/Developer/Xcode/DerivedData/ModuleCache.noindex -serialize-diagnostics -emit-dependencies -emit-module -emit-module-path /Users/kirillsimagin/Library/Developer/Xcode/DerivedData/Kizba-efejvmfzdmoqdoewsmanttogshar/Build/Intermediates.noindex/Kizba.build/Debug/KizbaTests.build/Objects-normal/arm64/KizbaTests.swiftmodule -validate-clang-modules-once -clang-build-session-file /Users/kirillsimagin/Library/Developer/Xcode/DerivedData/ModuleCache.noindex/Session.modulevalidation -Xcc -I/Users/kirillsimagin/Library/Developer/Xcode/DerivedData/Kizba-efejvmfzdmoqdoewsmanttogshar/Build/Intermediates.noindex/Kizba.build/Debug/KizbaTests.build/swift-overrides.hmap -emit-const-values -Xfrontend -const-gather-protocols-file -Xfrontend /Users/kirillsimagin/Library/Developer/Xcode/DerivedData/Kizba-efejvmfzdmoqdoewsmanttogshar/Build/Intermediates.noindex/Kizba.build/Debug/KizbaTests.build/Objects-normal/arm64/KizbaTests_const_extract_protocols.json -Xcc -iquote -Xcc /Users/kirillsimagin/Library/Developer/Xcode/DerivedData/Kizba-efejvmfzdmoqdoewsmanttogshar/Build/Intermediates.noindex/Kizba.build/Debug/KizbaTests.build/KizbaTests-generated-files.hmap -Xcc -I/Users/kirillsimagin/Library/Developer/Xcode/DerivedData/Kizba-efejvmfzdmoqdoewsmanttogshar/Build/Intermediates.noindex/Kizba.build/Debug/KizbaTests.build/KizbaTests-own-target-headers.hmap -Xcc -I/Users/kirillsimagin/Library/Developer/Xcode/DerivedData/Kizba-efejvmfzdmoqdoewsmanttogshar/Build/Intermediates.noindex/Kizba.build/Debug/KizbaTests.build/KizbaTests-all-target-headers.hmap -Xcc -iquote -Xcc /Users/kirillsimagin/Library/Developer/Xcode/DerivedData/Kizba-efejvmfzdmoqdoewsmanttogshar/Build/Intermediates.noindex/Kizba.build/Debug/KizbaTests.build/KizbaTests-project-headers.hmap -Xcc -I/Users/kirillsimagin/Library/Developer/Xcode/DerivedData/Kizba-efejvmfzdmoqdoewsmanttogshar/Build/Products/Debug/include -Xcc -I/Users/kirillsimagin/Library/Developer/Xcode/DerivedData/Kizba-efejvmfzdmoqdoewsmanttogshar/Build/Intermediates.noindex/Kizba.build/Debug/KizbaTests.build/DerivedSources-normal/arm64 -Xcc -I/Users/kirillsimagin/Library/Developer/Xcode/DerivedData/Kizba-efejvmfzdmoqdoewsmanttogshar/Build/Intermediates.noindex/Kizba.build/Debug/KizbaTests.build/DerivedSources/arm64 -Xcc -I/Users/kirillsimagin/Library/Developer/Xcode/DerivedData/Kizba-efejvmfzdmoqdoewsmanttogshar/Build/Intermediates.noindex/Kizba.build/Debug/KizbaTests.build/DerivedSources -Xcc -DDEBUG\=1 -emit-objc-header -emit-objc-header-path /Users/kirillsimagin/Library/Developer/Xcode/DerivedData/Kizba-efejvmfzdmoqdoewsmanttogshar/Build/Intermediates.noindex/Kizba.build/Debug/KizbaTests.build/Objects-normal/arm64/KizbaTests-Swift.h -working-directory /Users/kirillsimagin/dev/my/worldproject/kizba -experimental-emit-module-separately -disable-cmo

Copy /Users/kirillsimagin/Library/Developer/Xcode/DerivedData/Kizba-efejvmfzdmoqdoewsmanttogshar/Build/Products/Debug/KizbaTests.swiftmodule/arm64-apple-macos.swiftmodule /Users/kirillsimagin/Library/Developer/Xcode/DerivedData/Kizba-efejvmfzdmoqdoewsmanttogshar/Build/Intermediates.noindex/Kizba.build/Debug/KizbaTests.build/Objects-normal/arm64/KizbaTests.swiftmodule (in target 'KizbaTests' from project 'Kizba')
    cd /Users/kirillsimagin/dev/my/worldproject/kizba
    builtin-copy -exclude .DS_Store -exclude CVS -exclude .svn -exclude .git -exclude .hg -resolve-src-symlinks -rename /Users/kirillsimagin/Library/Developer/Xcode/DerivedData/Kizba-efejvmfzdmoqdoewsmanttogshar/Build/Intermediates.noindex/Kizba.build/Debug/KizbaTests.build/Objects-normal/arm64/KizbaTests.swiftmodule /Users/kirillsimagin/Library/Developer/Xcode/DerivedData/Kizba-efejvmfzdmoqdoewsmanttogshar/Build/Products/Debug/KizbaTests.swiftmodule/arm64-apple-macos.swiftmodule

Copy /Users/kirillsimagin/Library/Developer/Xcode/DerivedData/Kizba-efejvmfzdmoqdoewsmanttogshar/Build/Products/Debug/KizbaTests.swiftmodule/arm64-apple-macos.abi.json /Users/kirillsimagin/Library/Developer/Xcode/DerivedData/Kizba-efejvmfzdmoqdoewsmanttogshar/Build/Intermediates.noindex/Kizba.build/Debug/KizbaTests.build/Objects-normal/arm64/KizbaTests.abi.json (in target 'KizbaTests' from project 'Kizba')
    cd /Users/kirillsimagin/dev/my/worldproject/kizba
    builtin-copy -exclude .DS_Store -exclude CVS -exclude .svn -exclude .git -exclude .hg -resolve-src-symlinks -rename /Users/kirillsimagin/Library/Developer/Xcode/DerivedData/Kizba-efejvmfzdmoqdoewsmanttogshar/Build/Intermediates.noindex/Kizba.build/Debug/KizbaTests.build/Objects-normal/arm64/KizbaTests.abi.json /Users/kirillsimagin/Library/Developer/Xcode/DerivedData/Kizba-efejvmfzdmoqdoewsmanttogshar/Build/Products/Debug/KizbaTests.swiftmodule/arm64-apple-macos.abi.json

Copy /Users/kirillsimagin/Library/Developer/Xcode/DerivedData/Kizba-efejvmfzdmoqdoewsmanttogshar/Build/Products/Debug/KizbaTests.swiftmodule/Project/arm64-apple-macos.swiftsourceinfo /Users/kirillsimagin/Library/Developer/Xcode/DerivedData/Kizba-efejvmfzdmoqdoewsmanttogshar/Build/Intermediates.noindex/Kizba.build/Debug/KizbaTests.build/Objects-normal/arm64/KizbaTests.swiftsourceinfo (in target 'KizbaTests' from project 'Kizba')
    cd /Users/kirillsimagin/dev/my/worldproject/kizba
    builtin-copy -exclude .DS_Store -exclude CVS -exclude .svn -exclude .git -exclude .hg -resolve-src-symlinks -rename /Users/kirillsimagin/Library/Developer/Xcode/DerivedData/Kizba-efejvmfzdmoqdoewsmanttogshar/Build/Intermediates.noindex/Kizba.build/Debug/KizbaTests.build/Objects-normal/arm64/KizbaTests.swiftsourceinfo /Users/kirillsimagin/Library/Developer/Xcode/DerivedData/Kizba-efejvmfzdmoqdoewsmanttogshar/Build/Products/Debug/KizbaTests.swiftmodule/Project/arm64-apple-macos.swiftsourceinfo

SwiftDriverJobDiscovery normal arm64 Compiling EntryListModelRefreshTests.swift, EntryListModelTests.swift, EntryPathConverterTests.swift (in target 'KizbaTests' from project 'Kizba')

SwiftDriverJobDiscovery normal arm64 Compiling AppStateTests.swift, BinaryDiscoveryServiceTests.swift, ClipboardServiceTests.swift, DiagnosticsModelTests.swift (in target 'KizbaTests' from project 'Kizba')

SwiftDriverJobDiscovery normal arm64 Compiling TempStoreFixture.swift, AppEnvironmentClipboardTests.swift, AppEnvironmentPassCLITests.swift, AppEnvironmentTests.swift (in target 'KizbaTests' from project 'Kizba')

SwiftDriverJobDiscovery normal arm64 Compiling ProcessShellRunnerInvocationTests.swift, ProcessShellRunnerTests.swift, SettingsModelTests.swift (in target 'KizbaTests' from project 'Kizba')

SwiftDriverJobDiscovery normal arm64 Compiling SidebarModelTests.swift, SourceGrepTests.swift, UserDefaultsSettingsStoreTests.swift (in target 'KizbaTests' from project 'Kizba')

SwiftDriverJobDiscovery normal arm64 Compiling LogWrapperTests.swift, MockPassManagerTests.swift, PassCLITests.swift (in target 'KizbaTests' from project 'Kizba')

SwiftDriverJobDiscovery normal arm64 Compiling DomainModelsRefinementTests.swift, DomainModelsTests.swift, DomainProtocolsTests.swift (in target 'KizbaTests' from project 'Kizba')

SwiftDriverJobDiscovery normal arm64 Compiling EntryDetailModelCopyTests.swift, EntryDetailModelRefinementTests.swift, EntryDetailModelTests.swift (in target 'KizbaTests' from project 'Kizba')

SwiftDriver\ Compilation KizbaTests normal arm64 com.apple.xcode.tools.swift.compiler (in target 'KizbaTests' from project 'Kizba')
    cd /Users/kirillsimagin/dev/my/worldproject/kizba
    builtin-Swift-Compilation -- /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc -module-name KizbaTests -Onone @/Users/kirillsimagin/Library/Developer/Xcode/DerivedData/Kizba-efejvmfzdmoqdoewsmanttogshar/Build/Intermediates.noindex/Kizba.build/Debug/KizbaTests.build/Objects-normal/arm64/KizbaTests.SwiftFileList -DDEBUG -plugin-path /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/lib/swift/host/plugins/testing -enable-bare-slash-regex -enable-upcoming-feature DisableOutwardActorInference -enable-upcoming-feature InferSendableFromCaptures -enable-upcoming-feature GlobalActorIsolatedTypesUsability -enable-upcoming-feature MemberImportVisibility -enable-upcoming-feature InferIsolatedConformances -enable-upcoming-feature NonisolatedNonsendingByDefault -enable-experimental-feature DebugDescriptionMacro -sdk /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX26.4.sdk -target arm64-apple-macos14.0 -g -module-cache-path /Users/kirillsimagin/Library/Developer/Xcode/DerivedData/ModuleCache.noindex -Xfrontend -serialize-debugging-options -enable-testing -index-store-path /Users/kirillsimagin/Library/Developer/Xcode/DerivedData/Kizba-efejvmfzdmoqdoewsmanttogshar/Index.noindex/DataStore -Xcc -D_LIBCPP_HARDENING_MODE\=_LIBCPP_HARDENING_MODE_DEBUG -swift-version 5 -I /Users/kirillsimagin/Library/Developer/Xcode/DerivedData/Kizba-efejvmfzdmoqdoewsmanttogshar/Build/Products/Debug -Isystem /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/usr/lib -F /Users/kirillsimagin/Library/Developer/Xcode/DerivedData/Kizba-efejvmfzdmoqdoewsmanttogshar/Build/Products/Debug -F /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/Library/Frameworks -c -j10 -enable-batch-mode -incremental -Xcc -ivfsstatcache -Xcc /Users/kirillsimagin/Library/Developer/Xcode/DerivedData/SDKStatCaches.noindex/macosx26.4-25E251-30f9ca8789b706f8bd3fc906a70d770f.sdkstatcache -output-file-map /Users/kirillsimagin/Library/Developer/Xcode/DerivedData/Kizba-efejvmfzdmoqdoewsmanttogshar/Build/Intermediates.noindex/Kizba.build/Debug/KizbaTests.build/Objects-normal/arm64/KizbaTests-OutputFileMap.json -use-frontend-parseable-output -save-temps -no-color-diagnostics -explicit-module-build -module-cache-path /Users/kirillsimagin/Library/Developer/Xcode/DerivedData/Kizba-efejvmfzdmoqdoewsmanttogshar/Build/Intermediates.noindex/SwiftExplicitPrecompiledModules -clang-scanner-module-cache-path /Users/kirillsimagin/Library/Developer/Xcode/DerivedData/ModuleCache.noindex -sdk-module-cache-path /Users/kirillsimagin/Library/Developer/Xcode/DerivedData/ModuleCache.noindex -serialize-diagnostics -emit-dependencies -emit-module -emit-module-path /Users/kirillsimagin/Library/Developer/Xcode/DerivedData/Kizba-efejvmfzdmoqdoewsmanttogshar/Build/Intermediates.noindex/Kizba.build/Debug/KizbaTests.build/Objects-normal/arm64/KizbaTests.swiftmodule -validate-clang-modules-once -clang-build-session-file /Users/kirillsimagin/Library/Developer/Xcode/DerivedData/ModuleCache.noindex/Session.modulevalidation -Xcc -I/Users/kirillsimagin/Library/Developer/Xcode/DerivedData/Kizba-efejvmfzdmoqdoewsmanttogshar/Build/Intermediates.noindex/Kizba.build/Debug/KizbaTests.build/swift-overrides.hmap -emit-const-values -Xfrontend -const-gather-protocols-file -Xfrontend /Users/kirillsimagin/Library/Developer/Xcode/DerivedData/Kizba-efejvmfzdmoqdoewsmanttogshar/Build/Intermediates.noindex/Kizba.build/Debug/KizbaTests.build/Objects-normal/arm64/KizbaTests_const_extract_protocols.json -Xcc -iquote -Xcc /Users/kirillsimagin/Library/Developer/Xcode/DerivedData/Kizba-efejvmfzdmoqdoewsmanttogshar/Build/Intermediates.noindex/Kizba.build/Debug/KizbaTests.build/KizbaTests-generated-files.hmap -Xcc -I/Users/kirillsimagin/Library/Developer/Xcode/DerivedData/Kizba-efejvmfzdmoqdoewsmanttogshar/Build/Intermediates.noindex/Kizba.build/Debug/KizbaTests.build/KizbaTests-own-target-headers.hmap -Xcc -I/Users/kirillsimagin/Library/Developer/Xcode/DerivedData/Kizba-efejvmfzdmoqdoewsmanttogshar/Build/Intermediates.noindex/Kizba.build/Debug/KizbaTests.build/KizbaTests-all-target-headers.hmap -Xcc -iquote -Xcc /Users/kirillsimagin/Library/Developer/Xcode/DerivedData/Kizba-efejvmfzdmoqdoewsmanttogshar/Build/Intermediates.noindex/Kizba.build/Debug/KizbaTests.build/KizbaTests-project-headers.hmap -Xcc -I/Users/kirillsimagin/Library/Developer/Xcode/DerivedData/Kizba-efejvmfzdmoqdoewsmanttogshar/Build/Products/Debug/include -Xcc -I/Users/kirillsimagin/Library/Developer/Xcode/DerivedData/Kizba-efejvmfzdmoqdoewsmanttogshar/Build/Intermediates.noindex/Kizba.build/Debug/KizbaTests.build/DerivedSources-normal/arm64 -Xcc -I/Users/kirillsimagin/Library/Developer/Xcode/DerivedData/Kizba-efejvmfzdmoqdoewsmanttogshar/Build/Intermediates.noindex/Kizba.build/Debug/KizbaTests.build/DerivedSources/arm64 -Xcc -I/Users/kirillsimagin/Library/Developer/Xcode/DerivedData/Kizba-efejvmfzdmoqdoewsmanttogshar/Build/Intermediates.noindex/Kizba.build/Debug/KizbaTests.build/DerivedSources -Xcc -DDEBUG\=1 -emit-objc-header -emit-objc-header-path /Users/kirillsimagin/Library/Developer/Xcode/DerivedData/Kizba-efejvmfzdmoqdoewsmanttogshar/Build/Intermediates.noindex/Kizba.build/Debug/KizbaTests.build/Objects-normal/arm64/KizbaTests-Swift.h -working-directory /Users/kirillsimagin/dev/my/worldproject/kizba -experimental-emit-module-separately -disable-cmo

Ld /Users/kirillsimagin/Library/Developer/Xcode/DerivedData/Kizba-efejvmfzdmoqdoewsmanttogshar/Build/Products/Debug/Kizba.app/Contents/PlugIns/KizbaTests.xctest/Contents/MacOS/KizbaTests normal (in target 'KizbaTests' from project 'Kizba')
    cd /Users/kirillsimagin/dev/my/worldproject/kizba
    /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/clang -Xlinker -reproducible -target arm64-apple-macos14.0 -bundle -isysroot /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX26.4.sdk -O0 -L/Users/kirillsimagin/Library/Developer/Xcode/DerivedData/Kizba-efejvmfzdmoqdoewsmanttogshar/Build/Intermediates.noindex/EagerLinkingTBDs/Debug -L/Users/kirillsimagin/Library/Developer/Xcode/DerivedData/Kizba-efejvmfzdmoqdoewsmanttogshar/Build/Products/Debug -L/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/usr/lib -F/Users/kirillsimagin/Library/Developer/Xcode/DerivedData/Kizba-efejvmfzdmoqdoewsmanttogshar/Build/Intermediates.noindex/EagerLinkingTBDs/Debug -F/Users/kirillsimagin/Library/Developer/Xcode/DerivedData/Kizba-efejvmfzdmoqdoewsmanttogshar/Build/Products/Debug -iframework /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/Library/Frameworks -filelist /Users/kirillsimagin/Library/Developer/Xcode/DerivedData/Kizba-efejvmfzdmoqdoewsmanttogshar/Build/Intermediates.noindex/Kizba.build/Debug/KizbaTests.build/Objects-normal/arm64/KizbaTests.LinkFileList -Xlinker -rpath -Xlinker /usr/lib/swift -Xlinker -rpath -Xlinker @loader_path/../Frameworks -Xlinker -rpath -Xlinker @executable_path/../Frameworks -bundle_loader /Users/kirillsimagin/Library/Developer/Xcode/DerivedData/Kizba-efejvmfzdmoqdoewsmanttogshar/Build/Products/Debug/Kizba.app/Contents/MacOS/Kizba -Xlinker -object_path_lto -Xlinker /Users/kirillsimagin/Library/Developer/Xcode/DerivedData/Kizba-efejvmfzdmoqdoewsmanttogshar/Build/Intermediates.noindex/Kizba.build/Debug/KizbaTests.build/Objects-normal/arm64/KizbaTests_lto.o -rdynamic -Xlinker -no_deduplicate -Xlinker -dependency_info -Xlinker /Users/kirillsimagin/Library/Developer/Xcode/DerivedData/Kizba-efejvmfzdmoqdoewsmanttogshar/Build/Intermediates.noindex/Kizba.build/Debug/KizbaTests.build/Objects-normal/arm64/KizbaTests_dependency_info.dat -fobjc-link-runtime -L/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/lib/swift/macosx -L/usr/lib/swift -Xlinker -add_ast_path -Xlinker /Users/kirillsimagin/Library/Developer/Xcode/DerivedData/Kizba-efejvmfzdmoqdoewsmanttogshar/Build/Intermediates.noindex/Kizba.build/Debug/KizbaTests.build/Objects-normal/arm64/KizbaTests.swiftmodule @/Users/kirillsimagin/Library/Developer/Xcode/DerivedData/Kizba-efejvmfzdmoqdoewsmanttogshar/Build/Intermediates.noindex/Kizba.build/Debug/KizbaTests.build/Objects-normal/arm64/KizbaTests-linker-args.resp -Xlinker -needed_framework -Xlinker XCTest -framework XCTest -Xlinker -needed-lXCTestSwiftSupport -lXCTestSwiftSupport /Users/kirillsimagin/Library/Developer/Xcode/DerivedData/Kizba-efejvmfzdmoqdoewsmanttogshar/Build/Products/Debug/Kizba.app/Contents/MacOS/Kizba.debug.dylib -Xlinker -no_adhoc_codesign -o /Users/kirillsimagin/Library/Developer/Xcode/DerivedData/Kizba-efejvmfzdmoqdoewsmanttogshar/Build/Products/Debug/Kizba.app/Contents/PlugIns/KizbaTests.xctest/Contents/MacOS/KizbaTests

ExtractAppIntentsMetadata (in target 'KizbaTests' from project 'Kizba')
    cd /Users/kirillsimagin/dev/my/worldproject/kizba
    /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/appintentsmetadataprocessor --toolchain-dir /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain --module-name KizbaTests --sdk-root /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX26.4.sdk --xcode-version 17E202 --platform-family macOS --deployment-target 14.0 --bundle-identifier app.kizba.KizbaTests --output /Users/kirillsimagin/Library/Developer/Xcode/DerivedData/Kizba-efejvmfzdmoqdoewsmanttogshar/Build/Products/Debug/Kizba.app/Contents/PlugIns/KizbaTests.xctest/Contents/Resources --target-triple arm64-apple-macos14.0 --binary-file /Users/kirillsimagin/Library/Developer/Xcode/DerivedData/Kizba-efejvmfzdmoqdoewsmanttogshar/Build/Products/Debug/Kizba.app/Contents/PlugIns/KizbaTests.xctest/Contents/MacOS/KizbaTests --dependency-file /Users/kirillsimagin/Library/Developer/Xcode/DerivedData/Kizba-efejvmfzdmoqdoewsmanttogshar/Build/Intermediates.noindex/Kizba.build/Debug/KizbaTests.build/Objects-normal/arm64/KizbaTests_dependency_info.dat --stringsdata-file /Users/kirillsimagin/Library/Developer/Xcode/DerivedData/Kizba-efejvmfzdmoqdoewsmanttogshar/Build/Intermediates.noindex/Kizba.build/Debug/KizbaTests.build/Objects-normal/arm64/ExtractedAppShortcutsMetadata.stringsdata --source-file-list /Users/kirillsimagin/Library/Developer/Xcode/DerivedData/Kizba-efejvmfzdmoqdoewsmanttogshar/Build/Intermediates.noindex/Kizba.build/Debug/KizbaTests.build/Objects-normal/arm64/KizbaTests.SwiftFileList --metadata-file-list /Users/kirillsimagin/Library/Developer/Xcode/DerivedData/Kizba-efejvmfzdmoqdoewsmanttogshar/Build/Intermediates.noindex/Kizba.build/Debug/KizbaTests.build/KizbaTests.DependencyMetadataFileList --static-metadata-file-list /Users/kirillsimagin/Library/Developer/Xcode/DerivedData/Kizba-efejvmfzdmoqdoewsmanttogshar/Build/Intermediates.noindex/Kizba.build/Debug/KizbaTests.build/KizbaTests.DependencyStaticMetadataFileList --swift-const-vals-list /Users/kirillsimagin/Library/Developer/Xcode/DerivedData/Kizba-efejvmfzdmoqdoewsmanttogshar/Build/Intermediates.noindex/Kizba.build/Debug/KizbaTests.build/Objects-normal/arm64/KizbaTests.SwiftConstValuesFileList --compile-time-extraction --deployment-aware-processing --validate-assistant-intents --no-app-shortcuts-localization
2026-05-08 15:36:01.259 appintentsmetadataprocessor[8916:16821845] Starting appintentsmetadataprocessor export
2026-05-08 15:36:01.261 appintentsmetadataprocessor[8916:16821845] warning: Metadata extraction skipped. No AppIntents.framework dependency found.

CopySwiftLibs /Users/kirillsimagin/Library/Developer/Xcode/DerivedData/Kizba-efejvmfzdmoqdoewsmanttogshar/Build/Products/Debug/Kizba.app/Contents/PlugIns/KizbaTests.xctest (in target 'KizbaTests' from project 'Kizba')
    cd /Users/kirillsimagin/dev/my/worldproject/kizba
    builtin-swiftStdLibTool --copy --verbose --sign - --scan-executable /Users/kirillsimagin/Library/Developer/Xcode/DerivedData/Kizba-efejvmfzdmoqdoewsmanttogshar/Build/Products/Debug/Kizba.app/Contents/PlugIns/KizbaTests.xctest/Contents/MacOS/KizbaTests --scan-folder /Users/kirillsimagin/Library/Developer/Xcode/DerivedData/Kizba-efejvmfzdmoqdoewsmanttogshar/Build/Products/Debug/Kizba.app/Contents/PlugIns/KizbaTests.xctest/Contents/Frameworks --scan-folder /Users/kirillsimagin/Library/Developer/Xcode/DerivedData/Kizba-efejvmfzdmoqdoewsmanttogshar/Build/Products/Debug/Kizba.app/Contents/PlugIns/KizbaTests.xctest/Contents/PlugIns --scan-folder /Users/kirillsimagin/Library/Developer/Xcode/DerivedData/Kizba-efejvmfzdmoqdoewsmanttogshar/Build/Products/Debug/Kizba.app/Contents/PlugIns/KizbaTests.xctest/Contents/Library/SystemExtensions --scan-folder /Users/kirillsimagin/Library/Developer/Xcode/DerivedData/Kizba-efejvmfzdmoqdoewsmanttogshar/Build/Products/Debug/Kizba.app/Contents/PlugIns/KizbaTests.xctest/Contents/Extensions --platform macosx --toolchain /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain --destination /Users/kirillsimagin/Library/Developer/Xcode/DerivedData/Kizba-efejvmfzdmoqdoewsmanttogshar/Build/Products/Debug/Kizba.app/Contents/PlugIns/KizbaTests.xctest/Contents/Frameworks --strip-bitcode --scan-executable /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/usr/lib/libXCTestSwiftSupport.dylib --strip-bitcode-tool /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/bitcode_strip --emit-dependency-info /Users/kirillsimagin/Library/Developer/Xcode/DerivedData/Kizba-efejvmfzdmoqdoewsmanttogshar/Build/Intermediates.noindex/Kizba.build/Debug/KizbaTests.build/SwiftStdLibToolInputDependencies.dep --filter-for-swift-os --back-deploy-swift-span

CodeSign /Users/kirillsimagin/Library/Developer/Xcode/DerivedData/Kizba-efejvmfzdmoqdoewsmanttogshar/Build/Products/Debug/Kizba.app/Contents/PlugIns/KizbaTests.xctest (in target 'KizbaTests' from project 'Kizba')
    cd /Users/kirillsimagin/dev/my/worldproject/kizba
    
    Signing Identity:     "Sign to Run Locally"
    
    /usr/bin/codesign --force --sign - --timestamp\=none --generate-entitlement-der /Users/kirillsimagin/Library/Developer/Xcode/DerivedData/Kizba-efejvmfzdmoqdoewsmanttogshar/Build/Products/Debug/Kizba.app/Contents/PlugIns/KizbaTests.xctest

RegisterExecutionPolicyException /Users/kirillsimagin/Library/Developer/Xcode/DerivedData/Kizba-efejvmfzdmoqdoewsmanttogshar/Build/Products/Debug/Kizba.app/Contents/PlugIns/KizbaTests.xctest (in target 'KizbaTests' from project 'Kizba')
    cd /Users/kirillsimagin/dev/my/worldproject/kizba
    builtin-RegisterExecutionPolicyException /Users/kirillsimagin/Library/Developer/Xcode/DerivedData/Kizba-efejvmfzdmoqdoewsmanttogshar/Build/Products/Debug/Kizba.app/Contents/PlugIns/KizbaTests.xctest

Touch /Users/kirillsimagin/Library/Developer/Xcode/DerivedData/Kizba-efejvmfzdmoqdoewsmanttogshar/Build/Products/Debug/Kizba.app/Contents/PlugIns/KizbaTests.xctest (in target 'KizbaTests' from project 'Kizba')
    cd /Users/kirillsimagin/dev/my/worldproject/kizba
    /usr/bin/touch -c /Users/kirillsimagin/Library/Developer/Xcode/DerivedData/Kizba-efejvmfzdmoqdoewsmanttogshar/Build/Products/Debug/Kizba.app/Contents/PlugIns/KizbaTests.xctest

CodeSign /Users/kirillsimagin/Library/Developer/Xcode/DerivedData/Kizba-efejvmfzdmoqdoewsmanttogshar/Build/Products/Debug/Kizba.app/Contents/MacOS/Kizba.debug.dylib (in target 'Kizba' from project 'Kizba')
    cd /Users/kirillsimagin/dev/my/worldproject/kizba
    
    Signing Identity:     "Sign to Run Locally"
    
    /usr/bin/codesign --force --sign - --timestamp\=none --generate-entitlement-der /Users/kirillsimagin/Library/Developer/Xcode/DerivedData/Kizba-efejvmfzdmoqdoewsmanttogshar/Build/Products/Debug/Kizba.app/Contents/MacOS/Kizba.debug.dylib

CodeSign /Users/kirillsimagin/Library/Developer/Xcode/DerivedData/Kizba-efejvmfzdmoqdoewsmanttogshar/Build/Products/Debug/Kizba.app/Contents/MacOS/__preview.dylib (in target 'Kizba' from project 'Kizba')
    cd /Users/kirillsimagin/dev/my/worldproject/kizba
    
    Signing Identity:     "Sign to Run Locally"
    
    /usr/bin/codesign --force --sign - --timestamp\=none --generate-entitlement-der /Users/kirillsimagin/Library/Developer/Xcode/DerivedData/Kizba-efejvmfzdmoqdoewsmanttogshar/Build/Products/Debug/Kizba.app/Contents/MacOS/__preview.dylib

CodeSign /Users/kirillsimagin/Library/Developer/Xcode/DerivedData/Kizba-efejvmfzdmoqdoewsmanttogshar/Build/Products/Debug/Kizba.app (in target 'Kizba' from project 'Kizba')
    cd /Users/kirillsimagin/dev/my/worldproject/kizba
    
    Signing Identity:     "Sign to Run Locally"
    
    /usr/bin/codesign --force --sign - --entitlements /Users/kirillsimagin/Library/Developer/Xcode/DerivedData/Kizba-efejvmfzdmoqdoewsmanttogshar/Build/Intermediates.noindex/Kizba.build/Debug/Kizba.build/Kizba.app.xcent --timestamp\=none --generate-entitlement-der /Users/kirillsimagin/Library/Developer/Xcode/DerivedData/Kizba-efejvmfzdmoqdoewsmanttogshar/Build/Products/Debug/Kizba.app

Validate /Users/kirillsimagin/Library/Developer/Xcode/DerivedData/Kizba-efejvmfzdmoqdoewsmanttogshar/Build/Products/Debug/Kizba.app (in target 'Kizba' from project 'Kizba')
    cd /Users/kirillsimagin/dev/my/worldproject/kizba
    builtin-validationUtility /Users/kirillsimagin/Library/Developer/Xcode/DerivedData/Kizba-efejvmfzdmoqdoewsmanttogshar/Build/Products/Debug/Kizba.app -no-validate-extension -infoplist-subpath Contents/Info.plist

RegisterWithLaunchServices /Users/kirillsimagin/Library/Developer/Xcode/DerivedData/Kizba-efejvmfzdmoqdoewsmanttogshar/Build/Products/Debug/Kizba.app (in target 'Kizba' from project 'Kizba')
    cd /Users/kirillsimagin/dev/my/worldproject/kizba
    /System/Library/Frameworks/CoreServices.framework/Versions/Current/Frameworks/LaunchServices.framework/Versions/Current/Support/lsregister -f -R -trusted /Users/kirillsimagin/Library/Developer/Xcode/DerivedData/Kizba-efejvmfzdmoqdoewsmanttogshar/Build/Products/Debug/Kizba.app

2026-05-08 15:36:04.459101+0200 Kizba[8924:16821986] ApplePersistenceIgnoreState: Existing state will not be touched. New state will be written to /var/folders/2p/cjjcq6ys0cnc6cp8y7lv9vqr0000gn/T/app.kizba.Kizba.savedState
2026-05-08 15:36:04.913935+0200 Kizba[8924:16821986] [WarnOnce] It's not legal to call -layoutSubtreeIfNeeded on a view which is already being laid out.  If you are implementing the view's -layout method, you can call -[super layout] instead.  Break on void _NSDetectedLayoutRecursion(void) to debug.  This will be logged only once.  This may break in the future.
Test Suite 'All tests' started at 2026-05-08 15:36:05.066.
Test Suite 'KizbaTests.xctest' started at 2026-05-08 15:36:05.067.
Test Suite 'AppEnvironmentClipboardTests' started at 2026-05-08 15:36:05.067.
Test Case '-[KizbaTests.AppEnvironmentClipboardTests testLive_andPreview_clipboardsAreDistinctTypes]' started.
Test Case '-[KizbaTests.AppEnvironmentClipboardTests testLive_andPreview_clipboardsAreDistinctTypes]' passed (0.002 seconds).
Test Case '-[KizbaTests.AppEnvironmentClipboardTests testLive_clipboardIsProductionClipboardService]' started.
Test Case '-[KizbaTests.AppEnvironmentClipboardTests testLive_clipboardIsProductionClipboardService]' passed (0.001 seconds).
Test Case '-[KizbaTests.AppEnvironmentClipboardTests testPreview_clipboardIsNotProductionService]' started.
Test Case '-[KizbaTests.AppEnvironmentClipboardTests testPreview_clipboardIsNotProductionService]' passed (0.001 seconds).
Test Suite 'AppEnvironmentClipboardTests' passed at 2026-05-08 15:36:05.071.
	 Executed 3 tests, with 0 failures (0 unexpected) in 0.003 (0.005) seconds
Test Suite 'AppEnvironmentPassCLITests' started at 2026-05-08 15:36:05.072.
Test Case '-[KizbaTests.AppEnvironmentPassCLITests testLive_includesPassCLI]' started.
Test Case '-[KizbaTests.AppEnvironmentPassCLITests testLive_includesPassCLI]' passed (0.001 seconds).
Test Case '-[KizbaTests.AppEnvironmentPassCLITests testLive_passCLIWiresBinaryDiscoveryService]' started.
Test Case '-[KizbaTests.AppEnvironmentPassCLITests testLive_passCLIWiresBinaryDiscoveryService]' passed (0.001 seconds).
Test Case '-[KizbaTests.AppEnvironmentPassCLITests testLivePassCLI_throwsBinaryNotFoundWhenDiscoveryReturnsNil]' started.
Test Case '-[KizbaTests.AppEnvironmentPassCLITests testLivePassCLI_throwsBinaryNotFoundWhenDiscoveryReturnsNil]' passed (0.002 seconds).
Test Case '-[KizbaTests.AppEnvironmentPassCLITests testPreview_doesNotIncludePassCLI]' started.
Test Case '-[KizbaTests.AppEnvironmentPassCLITests testPreview_doesNotIncludePassCLI]' passed (0.001 seconds).
Test Suite 'AppEnvironmentPassCLITests' passed at 2026-05-08 15:36:05.078.
	 Executed 4 tests, with 0 failures (0 unexpected) in 0.005 (0.006) seconds
Test Suite 'AppEnvironmentTests' started at 2026-05-08 15:36:05.078.
Test Case '-[KizbaTests.AppEnvironmentTests testPreview_passManagerExposesFixtureCorpus]' started.
Test Case '-[KizbaTests.AppEnvironmentTests testPreview_passManagerExposesFixtureCorpus]' passed (0.001 seconds).
Test Case '-[KizbaTests.AppEnvironmentTests testPreview_passManagerShowReturnsKnownFixture]' started.
Test Case '-[KizbaTests.AppEnvironmentTests testPreview_passManagerShowReturnsKnownFixture]' passed (0.001 seconds).
Test Case '-[KizbaTests.AppEnvironmentTests testPreview_passManagerStoreLocationIsStable]' started.
Test Case '-[KizbaTests.AppEnvironmentTests testPreview_passManagerStoreLocationIsStable]' passed (0.012 seconds).
Test Suite 'AppEnvironmentTests' passed at 2026-05-08 15:36:05.093.
	 Executed 3 tests, with 0 failures (0 unexpected) in 0.014 (0.015) seconds
Test Suite 'AppStateTests' started at 2026-05-08 15:36:05.093.
Test Case '-[KizbaTests.AppStateTests testCurrentEntries_isMutable]' started.
Test Case '-[KizbaTests.AppStateTests testCurrentEntries_isMutable]' passed (0.001 seconds).
Test Case '-[KizbaTests.AppStateTests testInit_acceptsExplicitValues]' started.
Test Case '-[KizbaTests.AppStateTests testInit_acceptsExplicitValues]' passed (0.001 seconds).
Test Case '-[KizbaTests.AppStateTests testInit_defaultsAreEmpty]' started.
Test Case '-[KizbaTests.AppStateTests testInit_defaultsAreEmpty]' passed (0.001 seconds).
Test Case '-[KizbaTests.AppStateTests testSearchQuery_isMutable]' started.
Test Case '-[KizbaTests.AppStateTests testSearchQuery_isMutable]' passed (0.005 seconds).
Test Case '-[KizbaTests.AppStateTests testSelectedEntryID_isMutable]' started.
Test Case '-[KizbaTests.AppStateTests testSelectedEntryID_isMutable]' passed (0.001 seconds).
Test Suite 'AppStateTests' passed at 2026-05-08 15:36:05.103.
	 Executed 5 tests, with 0 failures (0 unexpected) in 0.009 (0.010) seconds
Test Suite 'BinaryDiscoveryServiceTests' started at 2026-05-08 15:36:05.103.
Test Case '-[KizbaTests.BinaryDiscoveryServiceTests testCachingAndReDetect]' started.
2026-05-08 15:36:05.104261+0200 Kizba[8924:16822074] [discovery] locate resolved name=pass path=/opt/homebrew/bin/pass
2026-05-08 15:36:05.104344+0200 Kizba[8924:16822074] [discovery] reDetect cache cleared
2026-05-08 15:36:05.104365+0200 Kizba[8924:16822074] [discovery] locate resolved name=pass path=/usr/local/bin/pass
Test Case '-[KizbaTests.BinaryDiscoveryServiceTests testCachingAndReDetect]' passed (0.001 seconds).
Test Case '-[KizbaTests.BinaryDiscoveryServiceTests testHomebrewPreferredOverUsrLocal]' started.
2026-05-08 15:36:05.113392+0200 Kizba[8924:16822075] [discovery] locate resolved name=pass path=/opt/homebrew/bin/pass
Test Case '-[KizbaTests.BinaryDiscoveryServiceTests testHomebrewPreferredOverUsrLocal]' passed (0.002 seconds).
Test Case '-[KizbaTests.BinaryDiscoveryServiceTests testNoFalsePositives]' started.
2026-05-08 15:36:05.114642+0200 Kizba[8924:16822075] [discovery] locate miss name=pass
Test Case '-[KizbaTests.BinaryDiscoveryServiceTests testNoFalsePositives]' passed (0.001 seconds).
Test Case '-[KizbaTests.BinaryDiscoveryServiceTests testOverrideMisconfigurationDoesNotFallBack]' started.
2026-05-08 15:36:05.115867+0200 Kizba[8924:16822130] [discovery] locate miss name=pass
Test Case '-[KizbaTests.BinaryDiscoveryServiceTests testOverrideMisconfigurationDoesNotFallBack]' passed (0.001 seconds).
Test Case '-[KizbaTests.BinaryDiscoveryServiceTests testOverrideWins]' started.
2026-05-08 15:36:05.116846+0200 Kizba[8924:16822129] [discovery] locate resolved name=pass path=/opt/kizba/bin/pass
Test Case '-[KizbaTests.BinaryDiscoveryServiceTests testOverrideWins]' passed (0.005 seconds).
Test Case '-[KizbaTests.BinaryDiscoveryServiceTests testPathFallbackUsesSanitizedPathOrder]' started.
2026-05-08 15:36:05.122400+0200 Kizba[8924:16822130] [discovery] locate resolved name=pass path=/some/dir/pass
Test Case '-[KizbaTests.BinaryDiscoveryServiceTests testPathFallbackUsesSanitizedPathOrder]' passed (0.001 seconds).
Test Suite 'BinaryDiscoveryServiceTests' passed at 2026-05-08 15:36:05.123.
	 Executed 6 tests, with 0 failures (0 unexpected) in 0.011 (0.020) seconds
Test Suite 'BinaryLocatingTests' started at 2026-05-08 15:36:05.123.
Test Case '-[KizbaTests.BinaryLocatingTests testBinaryNameRawValues]' started.
Test Case '-[KizbaTests.BinaryLocatingTests testBinaryNameRawValues]' passed (0.001 seconds).
Test Case '-[KizbaTests.BinaryLocatingTests testLocateReturnsConfiguredURL]' started.
Test Case '-[KizbaTests.BinaryLocatingTests testLocateReturnsConfiguredURL]' passed (0.001 seconds).
Test Case '-[KizbaTests.BinaryLocatingTests testLocateReturnsNilWhenMissing]' started.
Test Case '-[KizbaTests.BinaryLocatingTests testLocateReturnsNilWhenMissing]' passed (0.007 seconds).
Test Case '-[KizbaTests.BinaryLocatingTests testReDetectClearsCache]' started.
Test Case '-[KizbaTests.BinaryLocatingTests testReDetectClearsCache]' passed (0.001 seconds).
Test Suite 'BinaryLocatingTests' passed at 2026-05-08 15:36:05.134.
	 Executed 4 tests, with 0 failures (0 unexpected) in 0.010 (0.011) seconds
Test Suite 'ClipboardServiceTests' started at 2026-05-08 15:36:05.134.
Test Case '-[KizbaTests.ClipboardServiceTests testAutoClear_whenUnchanged]' started.
2026-05-08 15:36:05.135301+0200 Kizba[8924:16822129] [clipboard] clipboard copy occurred (auto-clear scheduled)
2026-05-08 15:36:05.217970+0200 Kizba[8924:16822075] [clipboard] clipboard auto-clear performed
Test Case '-[KizbaTests.ClipboardServiceTests testAutoClear_whenUnchanged]' passed (0.307 seconds).
Test Case '-[KizbaTests.ClipboardServiceTests testCancellation_ofClearTask_onNewCopy]' started.
2026-05-08 15:36:05.443550+0200 Kizba[8924:16822074] [clipboard] clipboard copy occurred (auto-clear scheduled)
2026-05-08 15:36:05.478291+0200 Kizba[8924:16822129] [clipboard] clipboard copy occurred (auto-clear scheduled)
Test Case '-[KizbaTests.ClipboardServiceTests testCancellation_ofClearTask_onNewCopy]' passed (0.340 seconds).
Test Case '-[KizbaTests.ClipboardServiceTests testCopyWritesVerbatim]' started.
2026-05-08 15:36:05.783982+0200 Kizba[8924:16822129] [clipboard] clipboard copy occurred (auto-clear scheduled)
Test Case '-[KizbaTests.ClipboardServiceTests testCopyWritesVerbatim]' passed (0.002 seconds).
Test Case '-[KizbaTests.ClipboardServiceTests testMultipleCopies_onlyLatestClears]' started.
2026-05-08 15:36:05.787078+0200 Kizba[8924:16822129] [clipboard] clipboard copy occurred (auto-clear scheduled)
2026-05-08 15:36:05.819384+0200 Kizba[8924:16822129] [clipboard] clipboard copy occurred (auto-clear scheduled)
2026-05-08 15:36:05.900111+0200 Kizba[8924:16822129] [clipboard] clipboard auto-clear performed
Test Case '-[KizbaTests.ClipboardServiceTests testMultipleCopies_onlyLatestClears]' passed (0.460 seconds).
Test Case '-[KizbaTests.ClipboardServiceTests testNoClear_whenChangeCountDiffers]' started.
2026-05-08 15:36:06.247641+0200 Kizba[8924:16822129] [clipboard] clipboard copy occurred (auto-clear scheduled)
2026-05-08 15:36:06.328543+0200 Kizba[8924:16822130] [clipboard] clipboard auto-clear skipped: changeCount diverged
Test Case '-[KizbaTests.ClipboardServiceTests testNoClear_whenChangeCountDiffers]' passed (0.304 seconds).
Test Suite 'ClipboardServiceTests' passed at 2026-05-08 15:36:06.551.
	 Executed 5 tests, with 0 failures (0 unexpected) in 1.414 (1.417) seconds
Test Suite 'ClipboardServicingTests' started at 2026-05-08 15:36:06.552.
Test Case '-[KizbaTests.ClipboardServicingTests testCopyRecordsValueVerbatim]' started.
Test Case '-[KizbaTests.ClipboardServicingTests testCopyRecordsValueVerbatim]' passed (0.003 seconds).
Test Case '-[KizbaTests.ClipboardServicingTests testRepeatedCopiesAreOrdered]' started.
Test Case '-[KizbaTests.ClipboardServicingTests testRepeatedCopiesAreOrdered]' passed (0.002 seconds).
Test Suite 'ClipboardServicingTests' passed at 2026-05-08 15:36:06.558.
	 Executed 2 tests, with 0 failures (0 unexpected) in 0.005 (0.006) seconds
Test Suite 'DiagnosticsModelTests' started at 2026-05-08 15:36:06.559.
Test Case '-[KizbaTests.DiagnosticsModelTests testClearEmptiesModelAndLog]' started.
Test Case '-[KizbaTests.DiagnosticsModelTests testClearEmptiesModelAndLog]' passed (0.003 seconds).
Test Case '-[KizbaTests.DiagnosticsModelTests testRefreshLoadsRecent]' started.
Test Case '-[KizbaTests.DiagnosticsModelTests testRefreshLoadsRecent]' passed (0.002 seconds).
Test Suite 'DiagnosticsModelTests' passed at 2026-05-08 15:36:06.565.
	 Executed 2 tests, with 0 failures (0 unexpected) in 0.005 (0.007) seconds
Test Suite 'DomainConcurrencyTests' started at 2026-05-08 15:36:06.566.
Test Case '-[KizbaTests.DomainConcurrencyTests testConcurrentAddsAreNotLost]' started.
Test Case '-[KizbaTests.DomainConcurrencyTests testConcurrentAddsAreNotLost]' passed (0.003 seconds).
Test Case '-[KizbaTests.DomainConcurrencyTests testConcurrentShowReturnsExactSecretPerEntry]' started.
Test Case '-[KizbaTests.DomainConcurrencyTests testConcurrentShowReturnsExactSecretPerEntry]' passed (0.005 seconds).
Test Case '-[KizbaTests.DomainConcurrencyTests testConcurrentShowSurfacesDecryptionFailure]' started.
Test Case '-[KizbaTests.DomainConcurrencyTests testConcurrentShowSurfacesDecryptionFailure]' passed (0.001 seconds).
Test Suite 'DomainConcurrencyTests' passed at 2026-05-08 15:36:06.579.
	 Executed 3 tests, with 0 failures (0 unexpected) in 0.009 (0.013) seconds
Test Suite 'EntryDetailModelCopyTests' started at 2026-05-08 15:36:06.579.
Test Case '-[KizbaTests.EntryDetailModelCopyTests testModelCopy_invokesClipboardWithVerbatimValueAndDelay]' started.
Test Case '-[KizbaTests.EntryDetailModelCopyTests testModelCopy_invokesClipboardWithVerbatimValueAndDelay]' passed (0.103 seconds).
Test Case '-[KizbaTests.EntryDetailModelCopyTests testModelCopyPassword_forwardsLoadedPasswordVerbatim]' started.
Test Case '-[KizbaTests.EntryDetailModelCopyTests testModelCopyPassword_forwardsLoadedPasswordVerbatim]' passed (0.013 seconds).
Test Suite 'EntryDetailModelCopyTests' passed at 2026-05-08 15:36:06.696.
	 Executed 2 tests, with 0 failures (0 unexpected) in 0.116 (0.117) seconds
Test Suite 'EntryDetailModelRefinementTests' started at 2026-05-08 15:36:06.697.
Test Case '-[KizbaTests.EntryDetailModelRefinementTests testCopy_invokesClipboardWithDuration]' started.
Test Case '-[KizbaTests.EntryDetailModelRefinementTests testCopy_invokesClipboardWithDuration]' passed (0.014 seconds).
Test Case '-[KizbaTests.EntryDetailModelRefinementTests testErrorMapping_pinentryNotConfigured]' started.
Test Case '-[KizbaTests.EntryDetailModelRefinementTests testErrorMapping_pinentryNotConfigured]' passed (0.014 seconds).
Test Case '-[KizbaTests.EntryDetailModelRefinementTests testErrorMapping_setsFailedState]' started.
Test Case '-[KizbaTests.EntryDetailModelRefinementTests testErrorMapping_setsFailedState]' passed (0.014 seconds).
Test Case '-[KizbaTests.EntryDetailModelRefinementTests testReveal_doesNotPersistSecret]' started.
Test Case '-[KizbaTests.EntryDetailModelRefinementTests testReveal_doesNotPersistSecret]' passed (0.013 seconds).
Test Case '-[KizbaTests.EntryDetailModelRefinementTests testSelectionCancellation_races]' started.
Test Case '-[KizbaTests.EntryDetailModelRefinementTests testSelectionCancellation_races]' passed (0.615 seconds).
Test Suite 'EntryDetailModelRefinementTests' passed at 2026-05-08 15:36:07.370.
	 Executed 5 tests, with 0 failures (0 unexpected) in 0.670 (0.674) seconds
Test Suite 'EntryDetailModelTests' started at 2026-05-08 15:36:07.371.
Test Case '-[KizbaTests.EntryDetailModelTests testCopy_callsClipboardWithVerbatimValueAndDelay]' started.
Test Case '-[KizbaTests.EntryDetailModelTests testCopy_callsClipboardWithVerbatimValueAndDelay]' passed (0.013 seconds).
Test Case '-[KizbaTests.EntryDetailModelTests testLoadSelection_succeeds]' started.
Test Case '-[KizbaTests.EntryDetailModelTests testLoadSelection_succeeds]' passed (0.013 seconds).
Test Case '-[KizbaTests.EntryDetailModelTests testSelectionCancellation_dropsStaleResult]' started.
Test Case '-[KizbaTests.EntryDetailModelTests testSelectionCancellation_dropsStaleResult]' passed (0.206 seconds).
Test Case '-[KizbaTests.EntryDetailModelTests testSelectionCleared_returnsToIdle]' started.
Test Case '-[KizbaTests.EntryDetailModelTests testSelectionCleared_returnsToIdle]' passed (0.266 seconds).
Test Suite 'EntryDetailModelTests' passed at 2026-05-08 15:36:07.874.
	 Executed 4 tests, with 0 failures (0 unexpected) in 0.499 (0.503) seconds
Test Suite 'EntryListModelRefreshTests' started at 2026-05-08 15:36:07.874.
Test Case '-[KizbaTests.EntryListModelRefreshTests testRefresh_cancellable]' started.
Test Case '-[KizbaTests.EntryListModelRefreshTests testRefresh_cancellable]' passed (0.024 seconds).
Test Case '-[KizbaTests.EntryListModelRefreshTests testRefresh_invokesScannerAndUpdatesEntries]' started.
Test Case '-[KizbaTests.EntryListModelRefreshTests testRefresh_invokesScannerAndUpdatesEntries]' passed (0.002 seconds).
Test Suite 'EntryListModelRefreshTests' passed at 2026-05-08 15:36:07.902.
	 Executed 2 tests, with 0 failures (0 unexpected) in 0.026 (0.028) seconds
Test Suite 'EntryListModelTests' started at 2026-05-08 15:36:07.903.
Test Case '-[KizbaTests.EntryListModelTests testEntries_folderFilter_limitsToSelectedFolder]' started.
Test Case '-[KizbaTests.EntryListModelTests testEntries_folderFilter_limitsToSelectedFolder]' passed (0.002 seconds).
Test Case '-[KizbaTests.EntryListModelTests testEntries_initialCount_unfiltered]' started.
Test Case '-[KizbaTests.EntryListModelTests testEntries_initialCount_unfiltered]' passed (0.002 seconds).
Test Case '-[KizbaTests.EntryListModelTests testEntries_searchFilter_isCaseInsensitiveSubstringOverPath]' started.
Test Case '-[KizbaTests.EntryListModelTests testEntries_searchFilter_isCaseInsensitiveSubstringOverPath]' passed (0.003 seconds).
Test Case '-[KizbaTests.EntryListModelTests testSelect_updatesAppStateSelectedEntryID]' started.
Test Case '-[KizbaTests.EntryListModelTests testSelect_updatesAppStateSelectedEntryID]' passed (0.002 seconds).
Test Suite 'EntryListModelTests' passed at 2026-05-08 15:36:07.915.
	 Executed 4 tests, with 0 failures (0 unexpected) in 0.010 (0.013) seconds
Test Suite 'EntryPathConverterTests' started at 2026-05-08 15:36:07.916.
Test Case '-[KizbaTests.EntryPathConverterTests testDotsInBasenamePreserved]' started.
Test Case '-[KizbaTests.EntryPathConverterTests testDotsInBasenamePreserved]' passed (0.002 seconds).
Test Case '-[KizbaTests.EntryPathConverterTests testEmptyBasenameReturnsNil]' started.
Test Case '-[KizbaTests.EntryPathConverterTests testEmptyBasenameReturnsNil]' passed (0.002 seconds).
Test Case '-[KizbaTests.EntryPathConverterTests testNestedPath]' started.
Test Case '-[KizbaTests.EntryPathConverterTests testNestedPath]' passed (0.002 seconds).
Test Case '-[KizbaTests.EntryPathConverterTests testNonGpgReturnsNil]' started.
Test Case '-[KizbaTests.EntryPathConverterTests testNonGpgReturnsNil]' passed (0.001 seconds).
Test Case '-[KizbaTests.EntryPathConverterTests testOutsideRootReturnsNil]' started.
Test Case '-[KizbaTests.EntryPathConverterTests testOutsideRootReturnsNil]' passed (0.001 seconds).
Test Case '-[KizbaTests.EntryPathConverterTests testStoreRootItselfReturnsNil]' started.
Test Case '-[KizbaTests.EntryPathConverterTests testStoreRootItselfReturnsNil]' passed (0.001 seconds).
Test Case '-[KizbaTests.EntryPathConverterTests testTopLevel]' started.
Test Case '-[KizbaTests.EntryPathConverterTests testTopLevel]' passed (0.001 seconds).
Test Case '-[KizbaTests.EntryPathConverterTests testUnicodeAndSpacesPreserved]' started.
Test Case '-[KizbaTests.EntryPathConverterTests testUnicodeAndSpacesPreserved]' passed (0.005 seconds).
Test Suite 'EntryPathConverterTests' passed at 2026-05-08 15:36:07.932.
	 Executed 8 tests, with 0 failures (0 unexpected) in 0.013 (0.017) seconds
Test Suite 'InvocationLogTests' started at 2026-05-08 15:36:07.933.
Test Case '-[KizbaTests.InvocationLogTests testClear]' started.
Test Case '-[KizbaTests.InvocationLogTests testClear]' passed (0.001 seconds).
Test Case '-[KizbaTests.InvocationLogTests testInit_clampsZeroOrNegativeMaxEntries]' started.
Test Case '-[KizbaTests.InvocationLogTests testInit_clampsZeroOrNegativeMaxEntries]' passed (0.001 seconds).
Test Case '-[KizbaTests.InvocationLogTests testRecent_isEmptyInitially]' started.
Test Case '-[KizbaTests.InvocationLogTests testRecent_isEmptyInitially]' passed (0.001 seconds).
Test Case '-[KizbaTests.InvocationLogTests testRecent_newestFirst_underCap]' started.
Test Case '-[KizbaTests.InvocationLogTests testRecent_newestFirst_underCap]' passed (0.001 seconds).
Test Case '-[KizbaTests.InvocationLogTests testRecordAndRecent_limit]' started.
Test Case '-[KizbaTests.InvocationLogTests testRecordAndRecent_limit]' passed (0.001 seconds).
Test Suite 'InvocationLogTests' passed at 2026-05-08 15:36:07.951.
	 Executed 5 tests, with 0 failures (0 unexpected) in 0.005 (0.018) seconds
Test Suite 'KizbaTests' started at 2026-05-08 15:36:07.951.
Test Case '-[KizbaTests.KizbaTests testExample]' started.
Test Case '-[KizbaTests.KizbaTests testExample]' passed (0.001 seconds).
Test Case '-[KizbaTests.KizbaTests testPerformanceExample]' started.
/Users/kirillsimagin/dev/my/worldproject/kizba/KizbaTests/KizbaTests.swift:33: Test Case '-[KizbaTests.KizbaTests testPerformanceExample]' measured [Time, seconds] average: 0.000, relative standard deviation: 109.042%, values: [0.000052, 0.000012, 0.000009, 0.000008, 0.000007, 0.000007, 0.000007, 0.000007, 0.000007, 0.000007], performanceMetricID:com.apple.XCTPerformanceMetric_WallClockTime, baselineName: "", baselineAverage: , polarity: prefers smaller, maxPercentRegression: 10.000%, maxPercentRelativeStandardDeviation: 10.000%, maxRegression: 0.100, maxStandardDeviation: 0.100
Test Case '-[KizbaTests.KizbaTests testPerformanceExample]' passed (5.120 seconds).
Test Suite 'KizbaTests' passed at 2026-05-08 15:36:13.072.
	 Executed 2 tests, with 0 failures (0 unexpected) in 5.121 (5.121) seconds
Test Suite 'LivePassManagerTests' started at 2026-05-08 15:36:13.072.
Test Case '-[KizbaTests.LivePassManagerTests testListEntries_delegatesToScannerAndMapsToPassEntries]' started.
Test Case '-[KizbaTests.LivePassManagerTests testListEntries_delegatesToScannerAndMapsToPassEntries]' passed (0.003 seconds).
Test Case '-[KizbaTests.LivePassManagerTests testListEntries_emptyStoreReturnsEmpty]' started.
Test Case '-[KizbaTests.LivePassManagerTests testListEntries_emptyStoreReturnsEmpty]' passed (0.001 seconds).
Test Case '-[KizbaTests.LivePassManagerTests testShow_delegatesToPassCLIWithEntryPath]' started.
2026-05-08 15:36:13.078679+0200 Kizba[8924:16822469] [pass] pass show ok: exe=/opt/homebrew/bin/pass argc=2 status=0 stderrBytes=0
Test Case '-[KizbaTests.LivePassManagerTests testShow_delegatesToPassCLIWithEntryPath]' passed (0.002 seconds).
Test Case '-[KizbaTests.LivePassManagerTests testStoreLocation_defaultRootMatchesHomePasswordStore]' started.
Test Case '-[KizbaTests.LivePassManagerTests testStoreLocation_defaultRootMatchesHomePasswordStore]' passed (0.001 seconds).
Test Case '-[KizbaTests.LivePassManagerTests testStoreLocation_returnsInjectedRoot]' started.
Test Case '-[KizbaTests.LivePassManagerTests testStoreLocation_returnsInjectedRoot]' passed (0.001 seconds).
Test Suite 'LivePassManagerTests' passed at 2026-05-08 15:36:13.081.
	 Executed 5 tests, with 0 failures (0 unexpected) in 0.007 (0.009) seconds
Test Suite 'LogWrapperTests' started at 2026-05-08 15:36:13.081.
Test Case '-[KizbaTests.LogWrapperTests testCategoryLoggersAreDistinct]' started.
Test Case '-[KizbaTests.LogWrapperTests testCategoryLoggersAreDistinct]' passed (0.001 seconds).
Test Case '-[KizbaTests.LogWrapperTests testRedactDefaultCap]' started.
Test Case '-[KizbaTests.LogWrapperTests testRedactDefaultCap]' passed (0.001 seconds).
Test Case '-[KizbaTests.LogWrapperTests testRedactPassesShortStringThrough]' started.
Test Case '-[KizbaTests.LogWrapperTests testRedactPassesShortStringThrough]' passed (0.001 seconds).
Test Case '-[KizbaTests.LogWrapperTests testRedactTruncatesLongString]' started.
Test Case '-[KizbaTests.LogWrapperTests testRedactTruncatesLongString]' passed (0.001 seconds).
Test Case '-[KizbaTests.LogWrapperTests testSubsystemIdentifier]' started.
Test Case '-[KizbaTests.LogWrapperTests testSubsystemIdentifier]' passed (0.001 seconds).
Test Suite 'LogWrapperTests' passed at 2026-05-08 15:36:13.091.
	 Executed 5 tests, with 0 failures (0 unexpected) in 0.003 (0.010) seconds
Test Suite 'MockPassManagerTests' started at 2026-05-08 15:36:13.091.
Test Case '-[KizbaTests.MockPassManagerTests testConcurrency_readers_consistentResults]' started.
Test Case '-[KizbaTests.MockPassManagerTests testConcurrency_readers_consistentResults]' passed (0.001 seconds).
Test Case '-[KizbaTests.MockPassManagerTests testFixtures_areDeterministicAcrossInstances]' started.
Test Case '-[KizbaTests.MockPassManagerTests testFixtures_areDeterministicAcrossInstances]' passed (0.001 seconds).
Test Case '-[KizbaTests.MockPassManagerTests testFixtures_coverThreeFolders]' started.
Test Case '-[KizbaTests.MockPassManagerTests testFixtures_coverThreeFolders]' passed (0.001 seconds).
Test Case '-[KizbaTests.MockPassManagerTests testFixtures_includeEdgeCases]' started.
Test Case '-[KizbaTests.MockPassManagerTests testFixtures_includeEdgeCases]' passed (0.001 seconds).
Test Case '-[KizbaTests.MockPassManagerTests testMock_has20Fixtures]' started.
Test Case '-[KizbaTests.MockPassManagerTests testMock_has20Fixtures]' passed (0.001 seconds).
Test Case '-[KizbaTests.MockPassManagerTests testShow_passwordOnlyEntry_hasEmptyMetadata]' started.
Test Case '-[KizbaTests.MockPassManagerTests testShow_passwordOnlyEntry_hasEmptyMetadata]' passed (0.001 seconds).
Test Case '-[KizbaTests.MockPassManagerTests testShow_returnsExpectedEntry]' started.
Test Case '-[KizbaTests.MockPassManagerTests testShow_returnsExpectedEntry]' passed (0.001 seconds).
Test Case '-[KizbaTests.MockPassManagerTests testShow_unknownEntry_throwsDecryptionFailed]' started.
Test Case '-[KizbaTests.MockPassManagerTests testShow_unknownEntry_throwsDecryptionFailed]' passed (0.001 seconds).
Test Case '-[KizbaTests.MockPassManagerTests testStoreLocation_honoursCustomURL]' started.
Test Case '-[KizbaTests.MockPassManagerTests testStoreLocation_honoursCustomURL]' passed (0.001 seconds).
Test Case '-[KizbaTests.MockPassManagerTests testStoreLocation_returnsFileURL]' started.
Test Case '-[KizbaTests.MockPassManagerTests testStoreLocation_returnsFileURL]' passed (0.001 seconds).
Test Suite 'MockPassManagerTests' passed at 2026-05-08 15:36:13.127.
	 Executed 10 tests, with 0 failures (0 unexpected) in 0.010 (0.035) seconds
Test Suite 'PassCLITests' started at 2026-05-08 15:36:13.127.
Test Case '-[KizbaTests.PassCLITests testCancellation_propagatesCancellation]' started.
2026-05-08 15:36:13.193698+0200 Kizba[8924:16822074] [pass] pass show cancelled: exe=/opt/homebrew/bin/pass argc=2
Test Case '-[KizbaTests.PassCLITests testCancellation_propagatesCancellation]' passed (0.054 seconds).
Test Case '-[KizbaTests.PassCLITests testDecryptionFailure_mapsToPassError]' started.
2026-05-08 15:36:13.195573+0200 Kizba[8924:16822075] [pass] pass show failed: exe=/opt/homebrew/bin/pass argc=2 status=2 stderrBytes=114 excerpt=gpg: decryption failed: No secret key gpg: encrypted with RSA key, ID <redacted-id> gpg: <redacted-email>
Test Case '-[KizbaTests.PassCLITests testDecryptionFailure_mapsToPassError]' passed (0.001 seconds).
Test Case '-[KizbaTests.PassCLITests testDefaultPATHIsExportedWhenNoOverridesSupplied]' started.
2026-05-08 15:36:13.196741+0200 Kizba[8924:16822077] [pass] pass show ok: exe=/opt/homebrew/bin/pass argc=2 status=0 stderrBytes=0
Test Case '-[KizbaTests.PassCLITests testDefaultPATHIsExportedWhenNoOverridesSupplied]' passed (0.001 seconds).
Test Case '-[KizbaTests.PassCLITests testEnvAndBinaryOverride_composition]' started.
2026-05-08 15:36:13.198015+0200 Kizba[8924:16822131] [pass] pass show ok: exe=/private/tmp/custom-pass-bin argc=2 status=0 stderrBytes=0
Test Case '-[KizbaTests.PassCLITests testEnvAndBinaryOverride_composition]' passed (0.001 seconds).
Test Case '-[KizbaTests.PassCLITests testShowSuccess_parsesPasswordAndMetadata]' started.
2026-05-08 15:36:13.199479+0200 Kizba[8924:16822075] [pass] pass show ok: exe=/opt/homebrew/bin/pass argc=2 status=0 stderrBytes=0
Test Case '-[KizbaTests.PassCLITests testShowSuccess_parsesPasswordAndMetadata]' passed (0.001 seconds).
Test Case '-[KizbaTests.PassCLITests testTimeout_throwsTimedOut]' started.
2026-05-08 15:36:13.211944+0200 Kizba[8924:16822074] [pass] pass show timed out: exe=/opt/homebrew/bin/pass argc=2
Test Case '-[KizbaTests.PassCLITests testTimeout_throwsTimedOut]' passed (0.012 seconds).
Test Suite 'PassCLITests' passed at 2026-05-08 15:36:13.213.
	 Executed 6 tests, with 0 failures (0 unexpected) in 0.071 (0.086) seconds
Test Suite 'PassEntryRefinementTests' started at 2026-05-08 15:36:13.213.
Test Case '-[KizbaTests.PassEntryRefinementTests testCodableJSONShapeIsStable]' started.
Test Case '-[KizbaTests.PassEntryRefinementTests testCodableJSONShapeIsStable]' passed (0.001 seconds).
Test Case '-[KizbaTests.PassEntryRefinementTests testEmptyPathYieldsEmptyNameAndFolder]' started.
Test Case '-[KizbaTests.PassEntryRefinementTests testEmptyPathYieldsEmptyNameAndFolder]' passed (0.001 seconds).
Test Case '-[KizbaTests.PassEntryRefinementTests testHashableSemanticsInSet]' started.
Test Case '-[KizbaTests.PassEntryRefinementTests testHashableSemanticsInSet]' passed (0.001 seconds).
Test Case '-[KizbaTests.PassEntryRefinementTests testIdMatchesPathForIdentifiable]' started.
Test Case '-[KizbaTests.PassEntryRefinementTests testIdMatchesPathForIdentifiable]' passed (0.001 seconds).
Test Case '-[KizbaTests.PassEntryRefinementTests testTrailingSlashIsTreatedAsEmptyName]' started.
Test Case '-[KizbaTests.PassEntryRefinementTests testTrailingSlashIsTreatedAsEmptyName]' passed (0.001 seconds).
Test Case '-[KizbaTests.PassEntryRefinementTests testUnicodeAndSpacesInPath]' started.
Test Case '-[KizbaTests.PassEntryRefinementTests testUnicodeAndSpacesInPath]' passed (0.001 seconds).
Test Suite 'PassEntryRefinementTests' passed at 2026-05-08 15:36:13.219.
	 Executed 6 tests, with 0 failures (0 unexpected) in 0.004 (0.006) seconds
Test Suite 'PassEntryTests' started at 2026-05-08 15:36:13.219.
Test Case '-[KizbaTests.PassEntryTests testCodableRoundTrip]' started.
Test Case '-[KizbaTests.PassEntryTests testCodableRoundTrip]' passed (0.005 seconds).
Test Case '-[KizbaTests.PassEntryTests testEquality]' started.
Test Case '-[KizbaTests.PassEntryTests testEquality]' passed (0.001 seconds).
Test Case '-[KizbaTests.PassEntryTests testNameAndFolderForNestedPath]' started.
Test Case '-[KizbaTests.PassEntryTests testNameAndFolderForNestedPath]' passed (0.001 seconds).
Test Case '-[KizbaTests.PassEntryTests testNameAndFolderForTopLevelPath]' started.
Test Case '-[KizbaTests.PassEntryTests testNameAndFolderForTopLevelPath]' passed (0.001 seconds).
Test Suite 'PassEntryTests' passed at 2026-05-08 15:36:13.227.
	 Executed 4 tests, with 0 failures (0 unexpected) in 0.007 (0.008) seconds
Test Suite 'PassErrorMapperTests' started at 2026-05-08 15:36:13.227.
Test Case '-[KizbaTests.PassErrorMapperTests testBinaryNotFoundMapsToBinaryNotFound_commandNotFoundShape]' started.
Test Case '-[KizbaTests.PassErrorMapperTests testBinaryNotFoundMapsToBinaryNotFound_commandNotFoundShape]' passed (0.001 seconds).
Test Case '-[KizbaTests.PassErrorMapperTests testBinaryNotFoundMapsToBinaryNotFound_pathShape]' started.
Test Case '-[KizbaTests.PassErrorMapperTests testBinaryNotFoundMapsToBinaryNotFound_pathShape]' passed (0.002 seconds).
Test Case '-[KizbaTests.PassErrorMapperTests testDecryptionFailureMapsToDecryptionFailed]' started.
Test Case '-[KizbaTests.PassErrorMapperTests testDecryptionFailureMapsToDecryptionFailed]' passed (0.001 seconds).
Test Case '-[KizbaTests.PassErrorMapperTests testInappropriateIoctlMapsToPinentryNotConfigured]' started.
Test Case '-[KizbaTests.PassErrorMapperTests testInappropriateIoctlMapsToPinentryNotConfigured]' passed (0.001 seconds).
Test Case '-[KizbaTests.PassErrorMapperTests testMapperExcerptIsAlwaysSanitised]' started.
Test Case '-[KizbaTests.PassErrorMapperTests testMapperExcerptIsAlwaysSanitised]' passed (0.001 seconds).
Test Case '-[KizbaTests.PassErrorMapperTests testPinentryMapsToPinentryNotConfigured]' started.
Test Case '-[KizbaTests.PassErrorMapperTests testPinentryMapsToPinentryNotConfigured]' passed (0.001 seconds).
Test Case '-[KizbaTests.PassErrorMapperTests testSanitizeEnforcesLengthLimit]' started.
Test Case '-[KizbaTests.PassErrorMapperTests testSanitizeEnforcesLengthLimit]' passed (0.050 seconds).
Test Case '-[KizbaTests.PassErrorMapperTests testSanitizeIdempotent]' started.
Test Case '-[KizbaTests.PassErrorMapperTests testSanitizeIdempotent]' passed (0.023 seconds).
Test Case '-[KizbaTests.PassErrorMapperTests testSanitizeIdempotent_atExactCap]' started.
Test Case '-[KizbaTests.PassErrorMapperTests testSanitizeIdempotent_atExactCap]' passed (0.014 seconds).
Test Case '-[KizbaTests.PassErrorMapperTests testSanitizeRedactsEmailAndHex]' started.
Test Case '-[KizbaTests.PassErrorMapperTests testSanitizeRedactsEmailAndHex]' passed (0.001 seconds).
Test Case '-[KizbaTests.PassErrorMapperTests testSanitizeShortStringIsLeftIntact]' started.
Test Case '-[KizbaTests.PassErrorMapperTests testSanitizeShortStringIsLeftIntact]' passed (0.001 seconds).
Test Case '-[KizbaTests.PassErrorMapperTests testTimeoutByExitCode]' started.
Test Case '-[KizbaTests.PassErrorMapperTests testTimeoutByExitCode]' passed (0.001 seconds).
Test Case '-[KizbaTests.PassErrorMapperTests testTimeoutByStderrText]' started.
Test Case '-[KizbaTests.PassErrorMapperTests testTimeoutByStderrText]' passed (0.001 seconds).
Test Case '-[KizbaTests.PassErrorMapperTests testUnknownFallbackShellFailure]' started.
Test Case '-[KizbaTests.PassErrorMapperTests testUnknownFallbackShellFailure]' passed (0.001 seconds).
Test Suite 'PassErrorMapperTests' passed at 2026-05-08 15:36:13.350.
	 Executed 14 tests, with 0 failures (0 unexpected) in 0.097 (0.123) seconds
Test Suite 'PassErrorRefinementTests' started at 2026-05-08 15:36:13.352.
Test Case '-[KizbaTests.PassErrorRefinementTests testHashableInSet]' started.
Test Case '-[KizbaTests.PassErrorRefinementTests testHashableInSet]' passed (0.001 seconds).
Test Case '-[KizbaTests.PassErrorRefinementTests testParameterlessCasesAreDistinct]' started.
Test Case '-[KizbaTests.PassErrorRefinementTests testParameterlessCasesAreDistinct]' passed (0.001 seconds).
Test Case '-[KizbaTests.PassErrorRefinementTests testStderrExcerptIsPartOfIdentity]' started.
Test Case '-[KizbaTests.PassErrorRefinementTests testStderrExcerptIsPartOfIdentity]' passed (0.001 seconds).
Test Case '-[KizbaTests.PassErrorRefinementTests testStoreNotFoundCarriesPath]' started.
Test Case '-[KizbaTests.PassErrorRefinementTests testStoreNotFoundCarriesPath]' passed (0.001 seconds).
Test Suite 'PassErrorRefinementTests' passed at 2026-05-08 15:36:13.356.
	 Executed 4 tests, with 0 failures (0 unexpected) in 0.003 (0.004) seconds
Test Suite 'PassErrorTests' started at 2026-05-08 15:36:13.356.
Test Case '-[KizbaTests.PassErrorTests testEqualityAcrossCases]' started.
Test Case '-[KizbaTests.PassErrorTests testEqualityAcrossCases]' passed (0.014 seconds).
Test Case '-[KizbaTests.PassErrorTests testIsErrorType]' started.
Test Case '-[KizbaTests.PassErrorTests testIsErrorType]' passed (0.001 seconds).
Test Suite 'PassErrorTests' passed at 2026-05-08 15:36:13.371.
	 Executed 2 tests, with 0 failures (0 unexpected) in 0.015 (0.016) seconds
Test Suite 'PassManagingTests' started at 2026-05-08 15:36:13.372.
Test Case '-[KizbaTests.PassManagingTests testListEntriesReturnsFixture]' started.
Test Case '-[KizbaTests.PassManagingTests testListEntriesReturnsFixture]' passed (0.001 seconds).
Test Case '-[KizbaTests.PassManagingTests testShowRoundTrip]' started.
Test Case '-[KizbaTests.PassManagingTests testShowRoundTrip]' passed (0.001 seconds).
Test Case '-[KizbaTests.PassManagingTests testShowSurfacesDecryptionFailureForUnknownEntry]' started.
Test Case '-[KizbaTests.PassManagingTests testShowSurfacesDecryptionFailureForUnknownEntry]' passed (0.001 seconds).
Test Case '-[KizbaTests.PassManagingTests testStoreLocationIsExposed]' started.
Test Case '-[KizbaTests.PassManagingTests testStoreLocationIsExposed]' passed (0.001 seconds).
Test Suite 'PassManagingTests' passed at 2026-05-08 15:36:13.386.
	 Executed 4 tests, with 0 failures (0 unexpected) in 0.004 (0.015) seconds
Test Suite 'PassMetadataRefinementTests' started at 2026-05-08 15:36:13.386.
Test Case '-[KizbaTests.PassMetadataRefinementTests testCodableRoundTripPreservesDuplicateKeysAndOrder]' started.
Test Case '-[KizbaTests.PassMetadataRefinementTests testCodableRoundTripPreservesDuplicateKeysAndOrder]' passed (0.001 seconds).
Test Case '-[KizbaTests.PassMetadataRefinementTests testEmptyStringNotesIsDistinctFromNil]' started.
Test Case '-[KizbaTests.PassMetadataRefinementTests testEmptyStringNotesIsDistinctFromNil]' passed (0.001 seconds).
Test Case '-[KizbaTests.PassMetadataRefinementTests testFieldHashableDistinguishesKeyAndValue]' started.
Test Case '-[KizbaTests.PassMetadataRefinementTests testFieldHashableDistinguishesKeyAndValue]' passed (0.011 seconds).
Test Case '-[KizbaTests.PassMetadataRefinementTests testFirstValueIsCaseSensitive]' started.
Test Case '-[KizbaTests.PassMetadataRefinementTests testFirstValueIsCaseSensitive]' passed (0.001 seconds).
Test Suite 'PassMetadataRefinementTests' passed at 2026-05-08 15:36:13.400.
	 Executed 4 tests, with 0 failures (0 unexpected) in 0.013 (0.014) seconds
Test Suite 'PassMetadataTests' started at 2026-05-08 15:36:13.401.
Test Case '-[KizbaTests.PassMetadataTests testCodableRoundTripPreservesFieldOrder]' started.
Test Case '-[KizbaTests.PassMetadataTests testCodableRoundTripPreservesFieldOrder]' passed (0.001 seconds).
Test Case '-[KizbaTests.PassMetadataTests testEmptyDefaults]' started.
Test Case '-[KizbaTests.PassMetadataTests testEmptyDefaults]' passed (0.001 seconds).
Test Case '-[KizbaTests.PassMetadataTests testFirstValueRespectsOrderAndDuplicates]' started.
Test Case '-[KizbaTests.PassMetadataTests testFirstValueRespectsOrderAndDuplicates]' passed (0.011 seconds).
Test Suite 'PassMetadataTests' passed at 2026-05-08 15:36:13.414.
	 Executed 3 tests, with 0 failures (0 unexpected) in 0.013 (0.014) seconds
Test Suite 'PassSecretRefinementTests' started at 2026-05-08 15:36:13.414.
Test Case '-[KizbaTests.PassSecretRefinementTests testEqualityIgnoresMetadataIdentityButRespectsContents]' started.
Test Case '-[KizbaTests.PassSecretRefinementTests testEqualityIgnoresMetadataIdentityButRespectsContents]' passed (0.001 seconds).
Test Case '-[KizbaTests.PassSecretRefinementTests testIsSendable]' started.
Test Case '-[KizbaTests.PassSecretRefinementTests testIsSendable]' passed (0.001 seconds).
Test Case '-[KizbaTests.PassSecretRefinementTests testLargePasswordRoundTripsThroughEquality]' started.
Test Case '-[KizbaTests.PassSecretRefinementTests testLargePasswordRoundTripsThroughEquality]' passed (0.001 seconds).
Test Case '-[KizbaTests.PassSecretRefinementTests testPasswordPreservesWhitespaceAndNewlinesVerbatim]' started.
Test Case '-[KizbaTests.PassSecretRefinementTests testPasswordPreservesWhitespaceAndNewlinesVerbatim]' passed (0.012 seconds).
Test Suite 'PassSecretRefinementTests' passed at 2026-05-08 15:36:13.430.
	 Executed 4 tests, with 0 failures (0 unexpected) in 0.014 (0.015) seconds
Test Suite 'PassSecretSecurityTests' started at 2026-05-08 15:36:13.430.
Test Case '-[KizbaTests.PassSecretSecurityTests testInitAndEquality]' started.
Test Case '-[KizbaTests.PassSecretSecurityTests testInitAndEquality]' passed (0.001 seconds).
Test Case '-[KizbaTests.PassSecretSecurityTests testIsNotCodable]' started.
Test Case '-[KizbaTests.PassSecretSecurityTests testIsNotCodable]' passed (0.001 seconds).
Test Case '-[KizbaTests.PassSecretSecurityTests testIsNotCustomStringConvertible]' started.
Test Case '-[KizbaTests.PassSecretSecurityTests testIsNotCustomStringConvertible]' passed (0.001 seconds).
Test Suite 'PassSecretSecurityTests' passed at 2026-05-08 15:36:13.433.
	 Executed 3 tests, with 0 failures (0 unexpected) in 0.002 (0.003) seconds
Test Suite 'PassShowParserTests' started at 2026-05-08 15:36:13.443.
Test Case '-[KizbaTests.PassShowParserTests testColonInValue]' started.
Test Case '-[KizbaTests.PassShowParserTests testColonInValue]' passed (0.001 seconds).
Test Case '-[KizbaTests.PassShowParserTests testDuplicateKeys]' started.
Test Case '-[KizbaTests.PassShowParserTests testDuplicateKeys]' passed (0.001 seconds).
Test Case '-[KizbaTests.PassShowParserTests testEmptyInput_throws]' started.
Test Case '-[KizbaTests.PassShowParserTests testEmptyInput_throws]' passed (0.001 seconds).
Test Case '-[KizbaTests.PassShowParserTests testNotesContainingKeyLikeLines]' started.
Test Case '-[KizbaTests.PassShowParserTests testNotesContainingKeyLikeLines]' passed (0.001 seconds).
Test Case '-[KizbaTests.PassShowParserTests testNotesStartingImmediatelyAfterPassword]' started.
Test Case '-[KizbaTests.PassShowParserTests testNotesStartingImmediatelyAfterPassword]' passed (0.001 seconds).
Test Case '-[KizbaTests.PassShowParserTests testPasswordOnly_noTrailingNewline]' started.
Test Case '-[KizbaTests.PassShowParserTests testPasswordOnly_noTrailingNewline]' passed (0.001 seconds).
Test Case '-[KizbaTests.PassShowParserTests testPasswordOnly]' started.
Test Case '-[KizbaTests.PassShowParserTests testPasswordOnly]' passed (0.001 seconds).
Test Case '-[KizbaTests.PassShowParserTests testWithMetadata]' started.
Test Case '-[KizbaTests.PassShowParserTests testWithMetadata]' passed (0.001 seconds).
Test Case '-[KizbaTests.PassShowParserTests testWithNotes_multiLine_preservesNewlines]' started.
Test Case '-[KizbaTests.PassShowParserTests testWithNotes_multiLine_preservesNewlines]' passed (0.001 seconds).
Test Case '-[KizbaTests.PassShowParserTests testWithNotes_singleLine]' started.
Test Case '-[KizbaTests.PassShowParserTests testWithNotes_singleLine]' passed (0.000 seconds).
Test Suite 'PassShowParserTests' passed at 2026-05-08 15:36:13.464.
	 Executed 10 tests, with 0 failures (0 unexpected) in 0.007 (0.021) seconds
Test Suite 'PasswordStoreScannerTests' started at 2026-05-08 15:36:13.464.
Test Case '-[KizbaTests.PasswordStoreScannerTests testCachingAndInvalidate]' started.
Test Case '-[KizbaTests.PasswordStoreScannerTests testCachingAndInvalidate]' passed (0.012 seconds).
Test Case '-[KizbaTests.PasswordStoreScannerTests testCaseInsensitiveGpgExtension]' started.
Test Case '-[KizbaTests.PasswordStoreScannerTests testCaseInsensitiveGpgExtension]' passed (0.009 seconds).
Test Case '-[KizbaTests.PasswordStoreScannerTests testEmptyStore_returnsEmpty]' started.
Test Case '-[KizbaTests.PasswordStoreScannerTests testEmptyStore_returnsEmpty]' passed (0.006 seconds).
Test Case '-[KizbaTests.PasswordStoreScannerTests testGpgIdAndGitIgnored]' started.
Test Case '-[KizbaTests.PasswordStoreScannerTests testGpgIdAndGitIgnored]' passed (0.024 seconds).
Test Case '-[KizbaTests.PasswordStoreScannerTests testMissingRoot_throws]' started.
2026-05-08 15:36:13.538495+0200 Kizba[8924:16822131] [discovery] PasswordStoreScanner: store root missing at /var/folders/2p/cjjcq6ys0cnc6cp8y7lv9vqr0000gn/T/temp-store-fixture-BB3EA3C6-B95F-4AE1-A04F-515157FDE35E/does-not-exist
Test Case '-[KizbaTests.PasswordStoreScannerTests testMissingRoot_throws]' passed (0.002 seconds).
Test Case '-[KizbaTests.PasswordStoreScannerTests testStandardLayout_returnsExpectedSortedEntries]' started.
Test Case '-[KizbaTests.PasswordStoreScannerTests testStandardLayout_returnsExpectedSortedEntries]' passed (0.018 seconds).
Test Case '-[KizbaTests.PasswordStoreScannerTests testUnicodeAndSpacesPreserved]' started.
Test Case '-[KizbaTests.PasswordStoreScannerTests testUnicodeAndSpacesPreserved]' passed (0.020 seconds).
Test Case '-[KizbaTests.PasswordStoreScannerTests testValidateStoreRoot]' started.
Test Case '-[KizbaTests.PasswordStoreScannerTests testValidateStoreRoot]' passed (0.006 seconds).
Test Suite 'PasswordStoreScannerTests' passed at 2026-05-08 15:36:13.585.
	 Executed 8 tests, with 0 failures (0 unexpected) in 0.098 (0.121) seconds
Test Suite 'ProcessShellRunnerInvocationTests' started at 2026-05-08 15:36:13.586.
Test Case '-[KizbaTests.ProcessShellRunnerInvocationTests testCancelPublishesInvocation]' started.
2026-05-08 15:36:13.670488+0200 Kizba[8924:16822131] [shell] shell cancelled: exe=/bin/sleep argc=1
Test Case '-[KizbaTests.ProcessShellRunnerInvocationTests testCancelPublishesInvocation]' passed (0.108 seconds).
Test Case '-[KizbaTests.ProcessShellRunnerInvocationTests testSuccessfulRunPublishesInvocation]' started.
2026-05-08 15:36:13.714513+0200 Kizba[8924:16822074] [shell] shell exit: exe=/bin/echo argc=1 status=0 stderrBytes=0
Test Case '-[KizbaTests.ProcessShellRunnerInvocationTests testSuccessfulRunPublishesInvocation]' passed (0.022 seconds).
Test Case '-[KizbaTests.ProcessShellRunnerInvocationTests testTimeoutPublishesInvocation]' started.
2026-05-08 15:36:13.822028+0200 Kizba[8924:16822074] [shell] shell timeout: exe=/bin/sleep argc=1
Test Case '-[KizbaTests.ProcessShellRunnerInvocationTests testTimeoutPublishesInvocation]' passed (0.107 seconds).
Test Suite 'ProcessShellRunnerInvocationTests' passed at 2026-05-08 15:36:13.824.
	 Executed 3 tests, with 0 failures (0 unexpected) in 0.236 (0.238) seconds
Test Suite 'ProcessShellRunnerTests' started at 2026-05-08 15:36:13.824.
Test Case '-[KizbaTests.ProcessShellRunnerTests testArgumentsAreForwardedAsDiscreteArgvEntries]' started.
2026-05-08 15:36:13.833394+0200 Kizba[8924:16822075] [shell] shell exit: exe=/bin/echo argc=2 status=0 stderrBytes=0
Test Case '-[KizbaTests.ProcessShellRunnerTests testArgumentsAreForwardedAsDiscreteArgvEntries]' passed (0.010 seconds).
Test Case '-[KizbaTests.ProcessShellRunnerTests testArgumentWithEmbeddedDoubleSpacesIsPreservedAsSingleArgv]' started.
2026-05-08 15:36:13.860189+0200 Kizba[8924:16822131] [shell] shell exit: exe=/bin/sh argc=4 status=0 stderrBytes=0
Test Case '-[KizbaTests.ProcessShellRunnerTests testArgumentWithEmbeddedDoubleSpacesIsPreservedAsSingleArgv]' passed (0.025 seconds).
Test Case '-[KizbaTests.ProcessShellRunnerTests testCancellationPropagates]' started.
2026-05-08 15:36:13.962882+0200 Kizba[8924:16822077] [shell] shell cancelled: exe=/bin/sleep argc=1
Test Case '-[KizbaTests.ProcessShellRunnerTests testCancellationPropagates]' passed (0.103 seconds).
Test Case '-[KizbaTests.ProcessShellRunnerTests testEchoSuccess]' started.
2026-05-08 15:36:13.994006+0200 Kizba[8924:16822075] [shell] shell exit: exe=/bin/echo argc=1 status=0 stderrBytes=0
Test Case '-[KizbaTests.ProcessShellRunnerTests testEchoSuccess]' passed (0.030 seconds).
Test Case '-[KizbaTests.ProcessShellRunnerTests testEmptyEnvironmentIsNotInheritedFromParent]' started.
2026-05-08 15:36:14.032766+0200 Kizba[8924:16822075] [shell] shell exit: exe=/bin/sh argc=2 status=0 stderrBytes=0
Test Case '-[KizbaTests.ProcessShellRunnerTests testEmptyEnvironmentIsNotInheritedFromParent]' passed (0.141 seconds).
Test Case '-[KizbaTests.ProcessShellRunnerTests testEnvironmentVariablesAreForwardedToChild]' started.
2026-05-08 15:36:14.158002+0200 Kizba[8924:16822131] [shell] shell exit: exe=/bin/sh argc=2 status=0 stderrBytes=0
Test Case '-[KizbaTests.ProcessShellRunnerTests testEnvironmentVariablesAreForwardedToChild]' passed (0.023 seconds).
Test Case '-[KizbaTests.ProcessShellRunnerTests testLargeStdoutDrain]' started.
2026-05-08 15:36:14.227020+0200 Kizba[8924:16822131] [shell] shell exit: exe=/bin/sh argc=2 status=0 stderrBytes=0
Test Case '-[KizbaTests.ProcessShellRunnerTests testLargeStdoutDrain]' passed (0.069 seconds).
Test Case '-[KizbaTests.ProcessShellRunnerTests testNonZeroExit]' started.
2026-05-08 15:36:14.265433+0200 Kizba[8924:16822074] [shell] shell exit: exe=/usr/bin/false argc=0 status=1 stderrBytes=0
Test Case '-[KizbaTests.ProcessShellRunnerTests testNonZeroExit]' passed (0.037 seconds).
Test Case '-[KizbaTests.ProcessShellRunnerTests testRelativeExecutableNotResolvedViaPATH]' started.
2026-05-08 15:36:14.280147+0200 Kizba[8924:16822074] [shell] process spawn failed for /kizba-not-a-real-binary-FB319A47-FBDA-4C02-A5B4-C34866E46B78: Error Domain=NSCocoaErrorDomain Code=4 "The file “kizba-not-a-real-binary-FB319A47-FBDA-4C02-A5B4-C34866E46B78” doesn’t exist." UserInfo={NSFilePath=/kizba-not-a-real-binary-FB319A47-FBDA-4C02-A5B4-C34866E46B78}
Test Case '-[KizbaTests.ProcessShellRunnerTests testRelativeExecutableNotResolvedViaPATH]' passed (0.014 seconds).
Test Case '-[KizbaTests.ProcessShellRunnerTests testSpawnFailureForMissingExecutable]' started.
2026-05-08 15:36:14.283914+0200 Kizba[8924:16822074] [shell] process spawn failed for /nonexistent/kizba-definitely-not-here-404CA823-64C7-495F-821E-2399C6ECB901: Error Domain=NSCocoaErrorDomain Code=4 "The file “kizba-definitely-not-here-404CA823-64C7-495F-821E-2399C6ECB901” doesn’t exist." UserInfo={NSFilePath=/nonexistent/kizba-definitely-not-here-404CA823-64C7-495F-821E-2399C6ECB901}
Test Case '-[KizbaTests.ProcessShellRunnerTests testSpawnFailureForMissingExecutable]' passed (0.003 seconds).
Test Case '-[KizbaTests.ProcessShellRunnerTests testTimeoutTerminatesProcess]' started.
2026-05-08 15:36:14.490182+0200 Kizba[8924:16822075] [shell] shell timeout: exe=/bin/sleep argc=1
Test Case '-[KizbaTests.ProcessShellRunnerTests testTimeoutTerminatesProcess]' passed (0.206 seconds).
Test Suite 'ProcessShellRunnerTests' passed at 2026-05-08 15:36:14.492.
	 Executed 11 tests, with 0 failures (0 unexpected) in 0.661 (0.668) seconds
Test Suite 'SettingsModelTests' started at 2026-05-08 15:36:14.492.
Test Case '-[KizbaTests.SettingsModelTests testDefaultsClipboardDelay]' started.
Test Case '-[KizbaTests.SettingsModelTests testDefaultsClipboardDelay]' passed (0.002 seconds).
Test Case '-[KizbaTests.SettingsModelTests testReDetectTriggersDiscovery]' started.
Test Case '-[KizbaTests.SettingsModelTests testReDetectTriggersDiscovery]' passed (0.003 seconds).
Test Case '-[KizbaTests.SettingsModelTests testResetToDefaults]' started.
Test Case '-[KizbaTests.SettingsModelTests testResetToDefaults]' passed (0.002 seconds).
Test Case '-[KizbaTests.SettingsModelTests testSetAndGetOverrides]' started.
Test Case '-[KizbaTests.SettingsModelTests testSetAndGetOverrides]' passed (0.002 seconds).
Test Suite 'SettingsModelTests' passed at 2026-05-08 15:36:14.503.
	 Executed 4 tests, with 0 failures (0 unexpected) in 0.008 (0.011) seconds
Test Suite 'SettingsStoringTests' started at 2026-05-08 15:36:14.504.
Test Case '-[KizbaTests.SettingsStoringTests testKeysAreIsolated]' started.
Test Case '-[KizbaTests.SettingsStoringTests testKeysAreIsolated]' passed (0.002 seconds).
Test Case '-[KizbaTests.SettingsStoringTests testNilRemovesEntry]' started.
Test Case '-[KizbaTests.SettingsStoringTests testNilRemovesEntry]' passed (0.001 seconds).
Test Case '-[KizbaTests.SettingsStoringTests testRoundTripStringAndInt]' started.
Test Case '-[KizbaTests.SettingsStoringTests testRoundTripStringAndInt]' passed (0.001 seconds).
Test Suite 'SettingsStoringTests' passed at 2026-05-08 15:36:14.509.
	 Executed 3 tests, with 0 failures (0 unexpected) in 0.004 (0.005) seconds
Test Suite 'ShellCommandRunningTests' started at 2026-05-08 15:36:14.509.
Test Case '-[KizbaTests.ShellCommandRunningTests testRunForwardsArgumentsAndReturnsResult]' started.
Test Case '-[KizbaTests.ShellCommandRunningTests testRunForwardsArgumentsAndReturnsResult]' passed (0.002 seconds).
Test Suite 'ShellCommandRunningTests' passed at 2026-05-08 15:36:14.511.
	 Executed 1 test, with 0 failures (0 unexpected) in 0.002 (0.002) seconds
Test Suite 'SidebarModelTests' started at 2026-05-08 15:36:14.511.
Test Case '-[KizbaTests.SidebarModelTests testInit_foldersStartEmpty]' started.
Test Case '-[KizbaTests.SidebarModelTests testInit_foldersStartEmpty]' passed (0.001 seconds).
Test Case '-[KizbaTests.SidebarModelTests testLoad_producesSortedTopLevelFolders_fromPreviewEnvironment]' started.
Test Case '-[KizbaTests.SidebarModelTests testLoad_producesSortedTopLevelFolders_fromPreviewEnvironment]' passed (0.001 seconds).
Test Case '-[KizbaTests.SidebarModelTests testTopLevelFolders_dedupesRepeatedHeads]' started.
Test Case '-[KizbaTests.SidebarModelTests testTopLevelFolders_dedupesRepeatedHeads]' passed (0.001 seconds).
Test Case '-[KizbaTests.SidebarModelTests testTopLevelFolders_isPureAndDeterministic]' started.
Test Case '-[KizbaTests.SidebarModelTests testTopLevelFolders_isPureAndDeterministic]' passed (0.001 seconds).
Test Case '-[KizbaTests.SidebarModelTests testTopLevelFolders_skipsTopLevelEntriesWithoutSlash]' started.
Test Case '-[KizbaTests.SidebarModelTests testTopLevelFolders_skipsTopLevelEntriesWithoutSlash]' passed (0.001 seconds).
Test Suite 'SidebarModelTests' passed at 2026-05-08 15:36:14.526.
	 Executed 5 tests, with 0 failures (0 unexpected) in 0.003 (0.015) seconds
Test Suite 'SourceGrepTests' started at 2026-05-08 15:36:14.526.
Test Case '-[KizbaTests.SourceGrepTests testNoDirectLoggerInstantiationOutsideWrapper]' started.
Test Case '-[KizbaTests.SourceGrepTests testNoDirectLoggerInstantiationOutsideWrapper]' passed (0.097 seconds).
Test Case '-[KizbaTests.SourceGrepTests testNoRawPrintInInfrastructure]' started.
Test Case '-[KizbaTests.SourceGrepTests testNoRawPrintInInfrastructure]' passed (0.020 seconds).
Test Case '-[KizbaTests.SourceGrepTests testNoStdoutReferencesInInfrastructure]' started.
Test Case '-[KizbaTests.SourceGrepTests testNoStdoutReferencesInInfrastructure]' passed (0.019 seconds).
Test Case '-[KizbaTests.SourceGrepTests testPassSecretIsNotCodable]' started.
Test Case '-[KizbaTests.SourceGrepTests testPassSecretIsNotCodable]' passed (0.100 seconds).
Test Suite 'SourceGrepTests' passed at 2026-05-08 15:36:14.765.
	 Executed 4 tests, with 0 failures (0 unexpected) in 0.237 (0.239) seconds
Test Suite 'UserDefaultsSettingsStoreTests' started at 2026-05-08 15:36:14.765.
Test Case '-[KizbaTests.UserDefaultsSettingsStoreTests testClear]' started.
Test Case '-[KizbaTests.UserDefaultsSettingsStoreTests testClear]' passed (0.006 seconds).
Test Case '-[KizbaTests.UserDefaultsSettingsStoreTests testDefaults_clipboardClearDelaySeconds]' started.
Test Case '-[KizbaTests.UserDefaultsSettingsStoreTests testDefaults_clipboardClearDelaySeconds]' passed (0.002 seconds).
Test Case '-[KizbaTests.UserDefaultsSettingsStoreTests testNamespacingIsolation]' started.
Test Case '-[KizbaTests.UserDefaultsSettingsStoreTests testNamespacingIsolation]' passed (0.003 seconds).
Test Case '-[KizbaTests.UserDefaultsSettingsStoreTests testResetClearsAll]' started.
Test Case '-[KizbaTests.UserDefaultsSettingsStoreTests testResetClearsAll]' passed (0.004 seconds).
Test Case '-[KizbaTests.UserDefaultsSettingsStoreTests testRoundTripPerType]' started.
Test Case '-[KizbaTests.UserDefaultsSettingsStoreTests testRoundTripPerType]' passed (0.004 seconds).
Test Suite 'UserDefaultsSettingsStoreTests' passed at 2026-05-08 15:36:14.787.
	 Executed 5 tests, with 0 failures (0 unexpected) in 0.019 (0.022) seconds
Test Suite 'KizbaTests.xctest' passed at 2026-05-08 15:36:14.788.
	 Executed 197 tests, with 0 failures (0 unexpected) in 9.482 (9.721) seconds
Test Suite 'All tests' passed at 2026-05-08 15:36:14.788.
	 Executed 197 tests, with 0 failures (0 unexpected) in 9.482 (9.722) seconds
2026-05-08 15:36:15.074 xcodebuild[8509:16819683] [MT] IDETestOperationsObserverDebug: 12.231 elapsed -- Testing started completed.
2026-05-08 15:36:15.074 xcodebuild[8509:16819683] [MT] IDETestOperationsObserverDebug: 0.000 sec, +0.000 sec -- start
2026-05-08 15:36:15.074 xcodebuild[8509:16819683] [MT] IDETestOperationsObserverDebug: 12.231 sec, +12.231 sec -- end

Test session results, code coverage, and logs:
	/Users/kirillsimagin/Library/Developer/Xcode/DerivedData/Kizba-efejvmfzdmoqdoewsmanttogshar/Logs/Test/Test-Kizba-2026.05.08_15-35-46-+0200.xcresult

** TEST SUCCEEDED **

Testing started
