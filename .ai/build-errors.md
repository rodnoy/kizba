Command line invocation:
    /Applications/Xcode.app/Contents/Developer/usr/bin/xcodebuild test -scheme Kizba -destination platform=macOS

2026-05-24 08:24:42.854 xcodebuild[11537:1069390]  DVTDeviceOperation: Encountered a build number "" that is incompatible with DVTBuildVersion.
2026-05-24 08:24:42.859 xcodebuild[11537:1068507] [MT] DVTDeviceOperation: Encountered a build number "" that is incompatible with DVTBuildVersion.
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

ExecuteExternalTool /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/clang -v -E -dM -isysroot /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX26.5.sdk -x c -c /dev/null

ExecuteExternalTool /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc --version

ExecuteExternalTool /Applications/Xcode.app/Contents/Developer/usr/bin/actool --version --output-format xml1

ExecuteExternalTool /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/ld -version_details

Build description signature: 9c84521f42a4c821f256f9690601db37
Build description path: /Users/kirillsimagin/Library/Developer/Xcode/DerivedData/Kizba-efejvmfzdmoqdoewsmanttogshar/Build/Intermediates.noindex/XCBuildData/9c84521f42a4c821f256f9690601db37.xcbuilddata
ClangStatCache /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/clang-stat-cache /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX26.5.sdk /Users/kirillsimagin/Library/Developer/Xcode/DerivedData/SDKStatCaches.noindex/macosx26.5-25F70-e082c4a02f00227109f4ed75e425c832.sdkstatcache
    cd /Users/kirillsimagin/dev/my/worldproject/kizba/Kizba.xcodeproj
    /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/clang-stat-cache /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX26.5.sdk -o /Users/kirillsimagin/Library/Developer/Xcode/DerivedData/SDKStatCaches.noindex/macosx26.5-25F70-e082c4a02f00227109f4ed75e425c832.sdkstatcache

SwiftDriver KizbaTests normal arm64 com.apple.xcode.tools.swift.compiler (in target 'KizbaTests' from project 'Kizba')
    cd /Users/kirillsimagin/dev/my/worldproject/kizba
    builtin-SwiftDriver -- /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc -module-name KizbaTests -Onone @/Users/kirillsimagin/Library/Developer/Xcode/DerivedData/Kizba-efejvmfzdmoqdoewsmanttogshar/Build/Intermediates.noindex/Kizba.build/Debug/KizbaTests.build/Objects-normal/arm64/KizbaTests.SwiftFileList -DDEBUG -plugin-path /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/lib/swift/host/plugins/testing -enable-bare-slash-regex -enable-upcoming-feature DisableOutwardActorInference -enable-upcoming-feature InferSendableFromCaptures -enable-upcoming-feature GlobalActorIsolatedTypesUsability -enable-upcoming-feature MemberImportVisibility -enable-upcoming-feature InferIsolatedConformances -enable-upcoming-feature NonisolatedNonsendingByDefault -enable-experimental-feature DebugDescriptionMacro -sdk /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX26.5.sdk -target arm64-apple-macos14.0 -g -module-cache-path /Users/kirillsimagin/Library/Developer/Xcode/DerivedData/ModuleCache.noindex -Xfrontend -serialize-debugging-options -enable-testing -index-store-path /Users/kirillsimagin/Library/Developer/Xcode/DerivedData/Kizba-efejvmfzdmoqdoewsmanttogshar/Index.noindex/DataStore -Xcc -D_LIBCPP_HARDENING_MODE\=_LIBCPP_HARDENING_MODE_DEBUG -swift-version 5 -I /Users/kirillsimagin/Library/Developer/Xcode/DerivedData/Kizba-efejvmfzdmoqdoewsmanttogshar/Build/Products/Debug -Isystem /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/usr/lib -F /Users/kirillsimagin/Library/Developer/Xcode/DerivedData/Kizba-efejvmfzdmoqdoewsmanttogshar/Build/Products/Debug -F /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/Library/Frameworks -c -j10 -enable-batch-mode -incremental -Xcc -ivfsstatcache -Xcc /Users/kirillsimagin/Library/Developer/Xcode/DerivedData/SDKStatCaches.noindex/macosx26.5-25F70-e082c4a02f00227109f4ed75e425c832.sdkstatcache -output-file-map /Users/kirillsimagin/Library/Developer/Xcode/DerivedData/Kizba-efejvmfzdmoqdoewsmanttogshar/Build/Intermediates.noindex/Kizba.build/Debug/KizbaTests.build/Objects-normal/arm64/KizbaTests-OutputFileMap.json -use-frontend-parseable-output -save-temps -no-color-diagnostics -explicit-module-build -module-cache-path /Users/kirillsimagin/Library/Developer/Xcode/DerivedData/Kizba-efejvmfzdmoqdoewsmanttogshar/Build/Intermediates.noindex/SwiftExplicitPrecompiledModules -clang-scanner-module-cache-path /Users/kirillsimagin/Library/Developer/Xcode/DerivedData/ModuleCache.noindex -sdk-module-cache-path /Users/kirillsimagin/Library/Developer/Xcode/DerivedData/ModuleCache.noindex -serialize-diagnostics -emit-dependencies -emit-module -emit-module-path /Users/kirillsimagin/Library/Developer/Xcode/DerivedData/Kizba-efejvmfzdmoqdoewsmanttogshar/Build/Intermediates.noindex/Kizba.build/Debug/KizbaTests.build/Objects-normal/arm64/KizbaTests.swiftmodule -validate-clang-modules-once -clang-build-session-file /Users/kirillsimagin/Library/Developer/Xcode/DerivedData/ModuleCache.noindex/Session.modulevalidation -Xcc -I/Users/kirillsimagin/Library/Developer/Xcode/DerivedData/Kizba-efejvmfzdmoqdoewsmanttogshar/Build/Intermediates.noindex/Kizba.build/Debug/KizbaTests.build/swift-overrides.hmap -emit-const-values -Xfrontend -const-gather-protocols-file -Xfrontend /Users/kirillsimagin/Library/Developer/Xcode/DerivedData/Kizba-efejvmfzdmoqdoewsmanttogshar/Build/Intermediates.noindex/Kizba.build/Debug/KizbaTests.build/Objects-normal/arm64/KizbaTests_const_extract_protocols.json -Xcc -iquote -Xcc /Users/kirillsimagin/Library/Developer/Xcode/DerivedData/Kizba-efejvmfzdmoqdoewsmanttogshar/Build/Intermediates.noindex/Kizba.build/Debug/KizbaTests.build/KizbaTests-generated-files.hmap -Xcc -I/Users/kirillsimagin/Library/Developer/Xcode/DerivedData/Kizba-efejvmfzdmoqdoewsmanttogshar/Build/Intermediates.noindex/Kizba.build/Debug/KizbaTests.build/KizbaTests-own-target-headers.hmap -Xcc -I/Users/kirillsimagin/Library/Developer/Xcode/DerivedData/Kizba-efejvmfzdmoqdoewsmanttogshar/Build/Intermediates.noindex/Kizba.build/Debug/KizbaTests.build/KizbaTests-all-target-headers.hmap -Xcc -iquote -Xcc /Users/kirillsimagin/Library/Developer/Xcode/DerivedData/Kizba-efejvmfzdmoqdoewsmanttogshar/Build/Intermediates.noindex/Kizba.build/Debug/KizbaTests.build/KizbaTests-project-headers.hmap -Xcc -I/Users/kirillsimagin/Library/Developer/Xcode/DerivedData/Kizba-efejvmfzdmoqdoewsmanttogshar/Build/Products/Debug/include -Xcc -I/Users/kirillsimagin/Library/Developer/Xcode/DerivedData/Kizba-efejvmfzdmoqdoewsmanttogshar/Build/Intermediates.noindex/Kizba.build/Debug/KizbaTests.build/DerivedSources-normal/arm64 -Xcc -I/Users/kirillsimagin/Library/Developer/Xcode/DerivedData/Kizba-efejvmfzdmoqdoewsmanttogshar/Build/Intermediates.noindex/Kizba.build/Debug/KizbaTests.build/DerivedSources/arm64 -Xcc -I/Users/kirillsimagin/Library/Developer/Xcode/DerivedData/Kizba-efejvmfzdmoqdoewsmanttogshar/Build/Intermediates.noindex/Kizba.build/Debug/KizbaTests.build/DerivedSources -Xcc -DDEBUG\=1 -emit-objc-header -emit-objc-header-path /Users/kirillsimagin/Library/Developer/Xcode/DerivedData/Kizba-efejvmfzdmoqdoewsmanttogshar/Build/Intermediates.noindex/Kizba.build/Debug/KizbaTests.build/Objects-normal/arm64/KizbaTests-Swift.h -working-directory /Users/kirillsimagin/dev/my/worldproject/kizba -experimental-emit-module-separately -disable-cmo

CopySwiftLibs /Users/kirillsimagin/Library/Developer/Xcode/DerivedData/Kizba-efejvmfzdmoqdoewsmanttogshar/Build/Products/Debug/Kizba.app (in target 'Kizba' from project 'Kizba')
    cd /Users/kirillsimagin/dev/my/worldproject/kizba
    builtin-swiftStdLibTool --copy --verbose --sign - --scan-executable /Users/kirillsimagin/Library/Developer/Xcode/DerivedData/Kizba-efejvmfzdmoqdoewsmanttogshar/Build/Products/Debug/Kizba.app/Contents/MacOS/Kizba.debug.dylib --scan-folder /Users/kirillsimagin/Library/Developer/Xcode/DerivedData/Kizba-efejvmfzdmoqdoewsmanttogshar/Build/Products/Debug/Kizba.app/Contents/Frameworks --scan-folder /Users/kirillsimagin/Library/Developer/Xcode/DerivedData/Kizba-efejvmfzdmoqdoewsmanttogshar/Build/Products/Debug/Kizba.app/Contents/PlugIns --scan-folder /Users/kirillsimagin/Library/Developer/Xcode/DerivedData/Kizba-efejvmfzdmoqdoewsmanttogshar/Build/Products/Debug/Kizba.app/Contents/Library/SystemExtensions --scan-folder /Users/kirillsimagin/Library/Developer/Xcode/DerivedData/Kizba-efejvmfzdmoqdoewsmanttogshar/Build/Products/Debug/Kizba.app/Contents/Extensions --platform macosx --toolchain /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain --destination /Users/kirillsimagin/Library/Developer/Xcode/DerivedData/Kizba-efejvmfzdmoqdoewsmanttogshar/Build/Products/Debug/Kizba.app/Contents/Frameworks --strip-bitcode --strip-bitcode-tool /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/bitcode_strip --emit-dependency-info /Users/kirillsimagin/Library/Developer/Xcode/DerivedData/Kizba-efejvmfzdmoqdoewsmanttogshar/Build/Intermediates.noindex/Kizba.build/Debug/Kizba.build/SwiftStdLibToolInputDependencies.dep --filter-for-swift-os --back-deploy-swift-span

ProcessInfoPlistFile /Users/kirillsimagin/Library/Developer/Xcode/DerivedData/Kizba-efejvmfzdmoqdoewsmanttogshar/Build/Products/Debug/Kizba.app/Contents/Info.plist /Users/kirillsimagin/Library/Developer/Xcode/DerivedData/Kizba-efejvmfzdmoqdoewsmanttogshar/Build/Intermediates.noindex/Kizba.build/Debug/Kizba.build/empty-Kizba.plist (in target 'Kizba' from project 'Kizba')
    cd /Users/kirillsimagin/dev/my/worldproject/kizba
    builtin-infoPlistUtility /Users/kirillsimagin/Library/Developer/Xcode/DerivedData/Kizba-efejvmfzdmoqdoewsmanttogshar/Build/Intermediates.noindex/Kizba.build/Debug/Kizba.build/empty-Kizba.plist -producttype com.apple.product-type.application -genpkginfo /Users/kirillsimagin/Library/Developer/Xcode/DerivedData/Kizba-efejvmfzdmoqdoewsmanttogshar/Build/Products/Debug/Kizba.app/Contents/PkgInfo -expandbuildsettings -platform macosx -additionalcontentfile /Users/kirillsimagin/Library/Developer/Xcode/DerivedData/Kizba-efejvmfzdmoqdoewsmanttogshar/Build/Intermediates.noindex/Kizba.build/Debug/Kizba.build/assetcatalog_generated_info.plist -o /Users/kirillsimagin/Library/Developer/Xcode/DerivedData/Kizba-efejvmfzdmoqdoewsmanttogshar/Build/Products/Debug/Kizba.app/Contents/Info.plist

ProcessInfoPlistFile /Users/kirillsimagin/Library/Developer/Xcode/DerivedData/Kizba-efejvmfzdmoqdoewsmanttogshar/Build/Products/Debug/Kizba.app/Contents/PlugIns/KizbaTests.xctest/Contents/Info.plist /Users/kirillsimagin/Library/Developer/Xcode/DerivedData/Kizba-efejvmfzdmoqdoewsmanttogshar/Build/Intermediates.noindex/Kizba.build/Debug/KizbaTests.build/empty-KizbaTests.plist (in target 'KizbaTests' from project 'Kizba')
    cd /Users/kirillsimagin/dev/my/worldproject/kizba
    builtin-infoPlistUtility /Users/kirillsimagin/Library/Developer/Xcode/DerivedData/Kizba-efejvmfzdmoqdoewsmanttogshar/Build/Intermediates.noindex/Kizba.build/Debug/KizbaTests.build/empty-KizbaTests.plist -producttype com.apple.product-type.bundle.unit-test -expandbuildsettings -platform macosx -o /Users/kirillsimagin/Library/Developer/Xcode/DerivedData/Kizba-efejvmfzdmoqdoewsmanttogshar/Build/Products/Debug/Kizba.app/Contents/PlugIns/KizbaTests.xctest/Contents/Info.plist

SwiftCompile normal arm64 Compiling\ KizbaNightContrastTests.swift /Users/kirillsimagin/dev/my/worldproject/kizba/KizbaTests/KizbaNightContrastTests.swift (in target 'KizbaTests' from project 'Kizba')

SwiftCompile normal arm64 /Users/kirillsimagin/dev/my/worldproject/kizba/KizbaTests/KizbaNightContrastTests.swift (in target 'KizbaTests' from project 'Kizba')
    cd /Users/kirillsimagin/dev/my/worldproject/kizba
    

SwiftEmitModule normal arm64 Emitting\ module\ for\ KizbaTests (in target 'KizbaTests' from project 'Kizba')
EmitSwiftModule normal arm64 (in target 'KizbaTests' from project 'Kizba')
    cd /Users/kirillsimagin/dev/my/worldproject/kizba
    
/Users/kirillsimagin/dev/my/worldproject/kizba/KizbaTests/Fixtures/FakePassGitManager.swift:6:58: warning: main actor-isolated static property 'notARepository' can not be referenced on a nonisolated actor instance
    var nextStatus: Result<GitStatus, Error> = .success(.notARepository)
                                                         ^
Kizba.GitStatus.notARepository:2:30: note: static property declared here
@MainActor public static let notARepository: Kizba.GitStatus}
                             ^
/Users/kirillsimagin/dev/my/worldproject/kizba/KizbaTests/Presentation/Features/MenuBar/MenuBarModelTests.swift:233:24: warning: conformance of 'FakePassManager' to protocol 'PassManaging' involves isolation mismatches and can cause data races; this is an error in the Swift 6 language mode
actor FakePassManager: PassManaging {
                       ^
/Users/kirillsimagin/dev/my/worldproject/kizba/KizbaTests/Presentation/Features/MenuBar/MenuBarModelTests.swift:233:7: note: mark all declarations used in the conformance 'nonisolated'
actor FakePassManager: PassManaging {
      ^
/Users/kirillsimagin/dev/my/worldproject/kizba/KizbaTests/Presentation/Features/MenuBar/MenuBarModelTests.swift:233:24: note: turn data races into runtime errors with '@preconcurrency'
actor FakePassManager: PassManaging {
                       ^
                       @preconcurrency 
/Users/kirillsimagin/dev/my/worldproject/kizba/KizbaTests/Presentation/Features/MenuBar/MenuBarModelTests.swift:242:10: note: actor-isolated instance method 'storeLocation()' cannot satisfy main actor-isolated requirement
    func storeLocation() -> URL {
         ^
/Users/kirillsimagin/dev/my/worldproject/kizba/KizbaTests/Presentation/Features/MenuBar/MenuBarModelTests.swift:275:9: note: actor-isolated property 'changes' cannot satisfy main actor-isolated requirement
    var changes: AsyncStream<StoreChange> {
        ^
/Users/kirillsimagin/dev/my/worldproject/kizba/KizbaTests/ActionHistoryTests.swift:229:41: warning: call to main actor-isolated initializer 'init(entries:secrets:storeLocation:)' in a synchronous nonisolated context
        passManager: any PassManaging = MockPassManager(entries: [], secrets: [:])
                                        ^
Kizba.MockPassManager.init:2:19: note: calls to initializer 'init(entries:secrets:storeLocation:)' from outside of its actor context are implicitly asynchronous
@MainActor public init(entries: [Kizba.PassEntry], secrets: [String : Kizba.PassSecret], storeLocation: URL = URL(fileURLWithPath: "/tmp/kizba-mock-store"))}
                  ^
/Users/kirillsimagin/dev/my/worldproject/kizba/KizbaTests/BinaryDiscoveryServiceTests.swift:175:23: warning: main actor-isolated initializer 'init(overrideProvider:pathOverride:environmentReader:fileChecker:)' cannot be called from outside of the actor; this is an error in the Swift 6 language mode
        let service = BinaryDiscoveryService(
                      ^~~~~~~~~~~~~~~~~~~~~~~
                      await 
/Users/kirillsimagin/dev/my/worldproject/kizba/KizbaTests/BiometricAuthenticatingTests.swift:39:30: warning: call to main actor-isolated instance method 'isAvailable()' in a synchronous nonisolated context
        XCTAssertEqual(fake1.isAvailable(), .available)
                             ^
/Users/kirillsimagin/dev/my/worldproject/kizba/KizbaTests/BiometricAuthenticatingTests.swift:30:18: note: calls to instance method 'isAvailable()' from outside of its actor context are implicitly asynchronous
            func isAvailable() -> BiometricAvailability { avail }
                 ^
/Users/kirillsimagin/dev/my/worldproject/kizba/KizbaTests/BiometricAuthenticatingTests.swift:30:18: note: main actor isolation inferred from conformance to protocol 'BiometricAuthenticating'
            func isAvailable() -> BiometricAvailability { avail }
                 ^
/Users/kirillsimagin/dev/my/worldproject/kizba/KizbaTests/BiometricAuthenticatingTests.swift:44:30: warning: call to main actor-isolated instance method 'isAvailable()' in a synchronous nonisolated context
        XCTAssertEqual(fake2.isAvailable(), .unavailable(.notEnrolled))
                             ^
/Users/kirillsimagin/dev/my/worldproject/kizba/KizbaTests/BiometricAuthenticatingTests.swift:30:18: note: calls to instance method 'isAvailable()' from outside of its actor context are implicitly asynchronous
            func isAvailable() -> BiometricAvailability { avail }
                 ^
/Users/kirillsimagin/dev/my/worldproject/kizba/KizbaTests/BiometricAuthenticatingTests.swift:30:18: note: main actor isolation inferred from conformance to protocol 'BiometricAuthenticating'
            func isAvailable() -> BiometricAvailability { avail }
                 ^
/Users/kirillsimagin/dev/my/worldproject/kizba/KizbaTests/EntryFormModelCreateTests.swift:380:41: warning: call to main actor-isolated initializer 'init(entries:secrets:storeLocation:)' in a synchronous nonisolated context
        passManager: any PassManaging = MockPassManager(entries: [], secrets: [:]),
                                        ^
Kizba.MockPassManager.init:2:19: note: calls to initializer 'init(entries:secrets:storeLocation:)' from outside of its actor context are implicitly asynchronous
@MainActor public init(entries: [Kizba.PassEntry], secrets: [String : Kizba.PassSecret], storeLocation: URL = URL(fileURLWithPath: "/tmp/kizba-mock-store"))}
                  ^
/Users/kirillsimagin/dev/my/worldproject/kizba/KizbaTests/GitMenuCommandsTests.swift:107:30: warning: main actor-isolated static property 'notARepository' can not be referenced from a nonisolated context
        status: GitStatus = .notARepository,
                             ^
Kizba.GitStatus.notARepository:2:30: note: static property declared here
@MainActor public static let notARepository: Kizba.GitStatus}
                             ^
/Users/kirillsimagin/dev/my/worldproject/kizba/KizbaTests/GitStatusModelTests.swift:603:41: warning: call to main actor-isolated initializer 'init(entries:secrets:storeLocation:)' in a synchronous nonisolated context
        passManager: any PassManaging = MockPassManager(entries: [], secrets: [:]),
                                        ^
Kizba.MockPassManager.init:2:19: note: calls to initializer 'init(entries:secrets:storeLocation:)' from outside of its actor context are implicitly asynchronous
@MainActor public init(entries: [Kizba.PassEntry], secrets: [String : Kizba.PassSecret], storeLocation: URL = URL(fileURLWithPath: "/tmp/kizba-mock-store"))}
                  ^
/Users/kirillsimagin/dev/my/worldproject/kizba/KizbaTests/SemanticIconographyTests.swift:51:71: warning: main actor-isolated conformance of 'BannerView.Severity' to 'Hashable' cannot be used in nonisolated context; this is an error in the Swift 6 language mode
    private static let expectedIcons: [BannerView.Severity: String] = [
                                                                      ^

SwiftDriverJobDiscovery normal arm64 Compiling KizbaNightContrastTests.swift (in target 'KizbaTests' from project 'Kizba')

SwiftDriverJobDiscovery normal arm64 Emitting module for KizbaTests (in target 'KizbaTests' from project 'Kizba')

SwiftDriver\ Compilation\ Requirements KizbaTests normal arm64 com.apple.xcode.tools.swift.compiler (in target 'KizbaTests' from project 'Kizba')
    cd /Users/kirillsimagin/dev/my/worldproject/kizba
    builtin-Swift-Compilation-Requirements -- /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc -module-name KizbaTests -Onone @/Users/kirillsimagin/Library/Developer/Xcode/DerivedData/Kizba-efejvmfzdmoqdoewsmanttogshar/Build/Intermediates.noindex/Kizba.build/Debug/KizbaTests.build/Objects-normal/arm64/KizbaTests.SwiftFileList -DDEBUG -plugin-path /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/lib/swift/host/plugins/testing -enable-bare-slash-regex -enable-upcoming-feature DisableOutwardActorInference -enable-upcoming-feature InferSendableFromCaptures -enable-upcoming-feature GlobalActorIsolatedTypesUsability -enable-upcoming-feature MemberImportVisibility -enable-upcoming-feature InferIsolatedConformances -enable-upcoming-feature NonisolatedNonsendingByDefault -enable-experimental-feature DebugDescriptionMacro -sdk /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX26.5.sdk -target arm64-apple-macos14.0 -g -module-cache-path /Users/kirillsimagin/Library/Developer/Xcode/DerivedData/ModuleCache.noindex -Xfrontend -serialize-debugging-options -enable-testing -index-store-path /Users/kirillsimagin/Library/Developer/Xcode/DerivedData/Kizba-efejvmfzdmoqdoewsmanttogshar/Index.noindex/DataStore -Xcc -D_LIBCPP_HARDENING_MODE\=_LIBCPP_HARDENING_MODE_DEBUG -swift-version 5 -I /Users/kirillsimagin/Library/Developer/Xcode/DerivedData/Kizba-efejvmfzdmoqdoewsmanttogshar/Build/Products/Debug -Isystem /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/usr/lib -F /Users/kirillsimagin/Library/Developer/Xcode/DerivedData/Kizba-efejvmfzdmoqdoewsmanttogshar/Build/Products/Debug -F /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/Library/Frameworks -c -j10 -enable-batch-mode -incremental -Xcc -ivfsstatcache -Xcc /Users/kirillsimagin/Library/Developer/Xcode/DerivedData/SDKStatCaches.noindex/macosx26.5-25F70-e082c4a02f00227109f4ed75e425c832.sdkstatcache -output-file-map /Users/kirillsimagin/Library/Developer/Xcode/DerivedData/Kizba-efejvmfzdmoqdoewsmanttogshar/Build/Intermediates.noindex/Kizba.build/Debug/KizbaTests.build/Objects-normal/arm64/KizbaTests-OutputFileMap.json -use-frontend-parseable-output -save-temps -no-color-diagnostics -explicit-module-build -module-cache-path /Users/kirillsimagin/Library/Developer/Xcode/DerivedData/Kizba-efejvmfzdmoqdoewsmanttogshar/Build/Intermediates.noindex/SwiftExplicitPrecompiledModules -clang-scanner-module-cache-path /Users/kirillsimagin/Library/Developer/Xcode/DerivedData/ModuleCache.noindex -sdk-module-cache-path /Users/kirillsimagin/Library/Developer/Xcode/DerivedData/ModuleCache.noindex -serialize-diagnostics -emit-dependencies -emit-module -emit-module-path /Users/kirillsimagin/Library/Developer/Xcode/DerivedData/Kizba-efejvmfzdmoqdoewsmanttogshar/Build/Intermediates.noindex/Kizba.build/Debug/KizbaTests.build/Objects-normal/arm64/KizbaTests.swiftmodule -validate-clang-modules-once -clang-build-session-file /Users/kirillsimagin/Library/Developer/Xcode/DerivedData/ModuleCache.noindex/Session.modulevalidation -Xcc -I/Users/kirillsimagin/Library/Developer/Xcode/DerivedData/Kizba-efejvmfzdmoqdoewsmanttogshar/Build/Intermediates.noindex/Kizba.build/Debug/KizbaTests.build/swift-overrides.hmap -emit-const-values -Xfrontend -const-gather-protocols-file -Xfrontend /Users/kirillsimagin/Library/Developer/Xcode/DerivedData/Kizba-efejvmfzdmoqdoewsmanttogshar/Build/Intermediates.noindex/Kizba.build/Debug/KizbaTests.build/Objects-normal/arm64/KizbaTests_const_extract_protocols.json -Xcc -iquote -Xcc /Users/kirillsimagin/Library/Developer/Xcode/DerivedData/Kizba-efejvmfzdmoqdoewsmanttogshar/Build/Intermediates.noindex/Kizba.build/Debug/KizbaTests.build/KizbaTests-generated-files.hmap -Xcc -I/Users/kirillsimagin/Library/Developer/Xcode/DerivedData/Kizba-efejvmfzdmoqdoewsmanttogshar/Build/Intermediates.noindex/Kizba.build/Debug/KizbaTests.build/KizbaTests-own-target-headers.hmap -Xcc -I/Users/kirillsimagin/Library/Developer/Xcode/DerivedData/Kizba-efejvmfzdmoqdoewsmanttogshar/Build/Intermediates.noindex/Kizba.build/Debug/KizbaTests.build/KizbaTests-all-target-headers.hmap -Xcc -iquote -Xcc /Users/kirillsimagin/Library/Developer/Xcode/DerivedData/Kizba-efejvmfzdmoqdoewsmanttogshar/Build/Intermediates.noindex/Kizba.build/Debug/KizbaTests.build/KizbaTests-project-headers.hmap -Xcc -I/Users/kirillsimagin/Library/Developer/Xcode/DerivedData/Kizba-efejvmfzdmoqdoewsmanttogshar/Build/Products/Debug/include -Xcc -I/Users/kirillsimagin/Library/Developer/Xcode/DerivedData/Kizba-efejvmfzdmoqdoewsmanttogshar/Build/Intermediates.noindex/Kizba.build/Debug/KizbaTests.build/DerivedSources-normal/arm64 -Xcc -I/Users/kirillsimagin/Library/Developer/Xcode/DerivedData/Kizba-efejvmfzdmoqdoewsmanttogshar/Build/Intermediates.noindex/Kizba.build/Debug/KizbaTests.build/DerivedSources/arm64 -Xcc -I/Users/kirillsimagin/Library/Developer/Xcode/DerivedData/Kizba-efejvmfzdmoqdoewsmanttogshar/Build/Intermediates.noindex/Kizba.build/Debug/KizbaTests.build/DerivedSources -Xcc -DDEBUG\=1 -emit-objc-header -emit-objc-header-path /Users/kirillsimagin/Library/Developer/Xcode/DerivedData/Kizba-efejvmfzdmoqdoewsmanttogshar/Build/Intermediates.noindex/Kizba.build/Debug/KizbaTests.build/Objects-normal/arm64/KizbaTests-Swift.h -working-directory /Users/kirillsimagin/dev/my/worldproject/kizba -experimental-emit-module-separately -disable-cmo

SwiftDriver\ Compilation KizbaTests normal arm64 com.apple.xcode.tools.swift.compiler (in target 'KizbaTests' from project 'Kizba')
    cd /Users/kirillsimagin/dev/my/worldproject/kizba
    builtin-Swift-Compilation -- /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc -module-name KizbaTests -Onone @/Users/kirillsimagin/Library/Developer/Xcode/DerivedData/Kizba-efejvmfzdmoqdoewsmanttogshar/Build/Intermediates.noindex/Kizba.build/Debug/KizbaTests.build/Objects-normal/arm64/KizbaTests.SwiftFileList -DDEBUG -plugin-path /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/lib/swift/host/plugins/testing -enable-bare-slash-regex -enable-upcoming-feature DisableOutwardActorInference -enable-upcoming-feature InferSendableFromCaptures -enable-upcoming-feature GlobalActorIsolatedTypesUsability -enable-upcoming-feature MemberImportVisibility -enable-upcoming-feature InferIsolatedConformances -enable-upcoming-feature NonisolatedNonsendingByDefault -enable-experimental-feature DebugDescriptionMacro -sdk /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX26.5.sdk -target arm64-apple-macos14.0 -g -module-cache-path /Users/kirillsimagin/Library/Developer/Xcode/DerivedData/ModuleCache.noindex -Xfrontend -serialize-debugging-options -enable-testing -index-store-path /Users/kirillsimagin/Library/Developer/Xcode/DerivedData/Kizba-efejvmfzdmoqdoewsmanttogshar/Index.noindex/DataStore -Xcc -D_LIBCPP_HARDENING_MODE\=_LIBCPP_HARDENING_MODE_DEBUG -swift-version 5 -I /Users/kirillsimagin/Library/Developer/Xcode/DerivedData/Kizba-efejvmfzdmoqdoewsmanttogshar/Build/Products/Debug -Isystem /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/usr/lib -F /Users/kirillsimagin/Library/Developer/Xcode/DerivedData/Kizba-efejvmfzdmoqdoewsmanttogshar/Build/Products/Debug -F /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/Library/Frameworks -c -j10 -enable-batch-mode -incremental -Xcc -ivfsstatcache -Xcc /Users/kirillsimagin/Library/Developer/Xcode/DerivedData/SDKStatCaches.noindex/macosx26.5-25F70-e082c4a02f00227109f4ed75e425c832.sdkstatcache -output-file-map /Users/kirillsimagin/Library/Developer/Xcode/DerivedData/Kizba-efejvmfzdmoqdoewsmanttogshar/Build/Intermediates.noindex/Kizba.build/Debug/KizbaTests.build/Objects-normal/arm64/KizbaTests-OutputFileMap.json -use-frontend-parseable-output -save-temps -no-color-diagnostics -explicit-module-build -module-cache-path /Users/kirillsimagin/Library/Developer/Xcode/DerivedData/Kizba-efejvmfzdmoqdoewsmanttogshar/Build/Intermediates.noindex/SwiftExplicitPrecompiledModules -clang-scanner-module-cache-path /Users/kirillsimagin/Library/Developer/Xcode/DerivedData/ModuleCache.noindex -sdk-module-cache-path /Users/kirillsimagin/Library/Developer/Xcode/DerivedData/ModuleCache.noindex -serialize-diagnostics -emit-dependencies -emit-module -emit-module-path /Users/kirillsimagin/Library/Developer/Xcode/DerivedData/Kizba-efejvmfzdmoqdoewsmanttogshar/Build/Intermediates.noindex/Kizba.build/Debug/KizbaTests.build/Objects-normal/arm64/KizbaTests.swiftmodule -validate-clang-modules-once -clang-build-session-file /Users/kirillsimagin/Library/Developer/Xcode/DerivedData/ModuleCache.noindex/Session.modulevalidation -Xcc -I/Users/kirillsimagin/Library/Developer/Xcode/DerivedData/Kizba-efejvmfzdmoqdoewsmanttogshar/Build/Intermediates.noindex/Kizba.build/Debug/KizbaTests.build/swift-overrides.hmap -emit-const-values -Xfrontend -const-gather-protocols-file -Xfrontend /Users/kirillsimagin/Library/Developer/Xcode/DerivedData/Kizba-efejvmfzdmoqdoewsmanttogshar/Build/Intermediates.noindex/Kizba.build/Debug/KizbaTests.build/Objects-normal/arm64/KizbaTests_const_extract_protocols.json -Xcc -iquote -Xcc /Users/kirillsimagin/Library/Developer/Xcode/DerivedData/Kizba-efejvmfzdmoqdoewsmanttogshar/Build/Intermediates.noindex/Kizba.build/Debug/KizbaTests.build/KizbaTests-generated-files.hmap -Xcc -I/Users/kirillsimagin/Library/Developer/Xcode/DerivedData/Kizba-efejvmfzdmoqdoewsmanttogshar/Build/Intermediates.noindex/Kizba.build/Debug/KizbaTests.build/KizbaTests-own-target-headers.hmap -Xcc -I/Users/kirillsimagin/Library/Developer/Xcode/DerivedData/Kizba-efejvmfzdmoqdoewsmanttogshar/Build/Intermediates.noindex/Kizba.build/Debug/KizbaTests.build/KizbaTests-all-target-headers.hmap -Xcc -iquote -Xcc /Users/kirillsimagin/Library/Developer/Xcode/DerivedData/Kizba-efejvmfzdmoqdoewsmanttogshar/Build/Intermediates.noindex/Kizba.build/Debug/KizbaTests.build/KizbaTests-project-headers.hmap -Xcc -I/Users/kirillsimagin/Library/Developer/Xcode/DerivedData/Kizba-efejvmfzdmoqdoewsmanttogshar/Build/Products/Debug/include -Xcc -I/Users/kirillsimagin/Library/Developer/Xcode/DerivedData/Kizba-efejvmfzdmoqdoewsmanttogshar/Build/Intermediates.noindex/Kizba.build/Debug/KizbaTests.build/DerivedSources-normal/arm64 -Xcc -I/Users/kirillsimagin/Library/Developer/Xcode/DerivedData/Kizba-efejvmfzdmoqdoewsmanttogshar/Build/Intermediates.noindex/Kizba.build/Debug/KizbaTests.build/DerivedSources/arm64 -Xcc -I/Users/kirillsimagin/Library/Developer/Xcode/DerivedData/Kizba-efejvmfzdmoqdoewsmanttogshar/Build/Intermediates.noindex/Kizba.build/Debug/KizbaTests.build/DerivedSources -Xcc -DDEBUG\=1 -emit-objc-header -emit-objc-header-path /Users/kirillsimagin/Library/Developer/Xcode/DerivedData/Kizba-efejvmfzdmoqdoewsmanttogshar/Build/Intermediates.noindex/Kizba.build/Debug/KizbaTests.build/Objects-normal/arm64/KizbaTests-Swift.h -working-directory /Users/kirillsimagin/dev/my/worldproject/kizba -experimental-emit-module-separately -disable-cmo

Copy /Users/kirillsimagin/Library/Developer/Xcode/DerivedData/Kizba-efejvmfzdmoqdoewsmanttogshar/Build/Products/Debug/KizbaTests.swiftmodule/Project/arm64-apple-macos.swiftsourceinfo /Users/kirillsimagin/Library/Developer/Xcode/DerivedData/Kizba-efejvmfzdmoqdoewsmanttogshar/Build/Intermediates.noindex/Kizba.build/Debug/KizbaTests.build/Objects-normal/arm64/KizbaTests.swiftsourceinfo (in target 'KizbaTests' from project 'Kizba')
    cd /Users/kirillsimagin/dev/my/worldproject/kizba
    builtin-copy -exclude .DS_Store -exclude CVS -exclude .svn -exclude .git -exclude .hg -resolve-src-symlinks -rename /Users/kirillsimagin/Library/Developer/Xcode/DerivedData/Kizba-efejvmfzdmoqdoewsmanttogshar/Build/Intermediates.noindex/Kizba.build/Debug/KizbaTests.build/Objects-normal/arm64/KizbaTests.swiftsourceinfo /Users/kirillsimagin/Library/Developer/Xcode/DerivedData/Kizba-efejvmfzdmoqdoewsmanttogshar/Build/Products/Debug/KizbaTests.swiftmodule/Project/arm64-apple-macos.swiftsourceinfo

Copy /Users/kirillsimagin/Library/Developer/Xcode/DerivedData/Kizba-efejvmfzdmoqdoewsmanttogshar/Build/Products/Debug/KizbaTests.swiftmodule/arm64-apple-macos.abi.json /Users/kirillsimagin/Library/Developer/Xcode/DerivedData/Kizba-efejvmfzdmoqdoewsmanttogshar/Build/Intermediates.noindex/Kizba.build/Debug/KizbaTests.build/Objects-normal/arm64/KizbaTests.abi.json (in target 'KizbaTests' from project 'Kizba')
    cd /Users/kirillsimagin/dev/my/worldproject/kizba
    builtin-copy -exclude .DS_Store -exclude CVS -exclude .svn -exclude .git -exclude .hg -resolve-src-symlinks -rename /Users/kirillsimagin/Library/Developer/Xcode/DerivedData/Kizba-efejvmfzdmoqdoewsmanttogshar/Build/Intermediates.noindex/Kizba.build/Debug/KizbaTests.build/Objects-normal/arm64/KizbaTests.abi.json /Users/kirillsimagin/Library/Developer/Xcode/DerivedData/Kizba-efejvmfzdmoqdoewsmanttogshar/Build/Products/Debug/KizbaTests.swiftmodule/arm64-apple-macos.abi.json

Copy /Users/kirillsimagin/Library/Developer/Xcode/DerivedData/Kizba-efejvmfzdmoqdoewsmanttogshar/Build/Products/Debug/KizbaTests.swiftmodule/arm64-apple-macos.swiftmodule /Users/kirillsimagin/Library/Developer/Xcode/DerivedData/Kizba-efejvmfzdmoqdoewsmanttogshar/Build/Intermediates.noindex/Kizba.build/Debug/KizbaTests.build/Objects-normal/arm64/KizbaTests.swiftmodule (in target 'KizbaTests' from project 'Kizba')
    cd /Users/kirillsimagin/dev/my/worldproject/kizba
    builtin-copy -exclude .DS_Store -exclude CVS -exclude .svn -exclude .git -exclude .hg -resolve-src-symlinks -rename /Users/kirillsimagin/Library/Developer/Xcode/DerivedData/Kizba-efejvmfzdmoqdoewsmanttogshar/Build/Intermediates.noindex/Kizba.build/Debug/KizbaTests.build/Objects-normal/arm64/KizbaTests.swiftmodule /Users/kirillsimagin/Library/Developer/Xcode/DerivedData/Kizba-efejvmfzdmoqdoewsmanttogshar/Build/Products/Debug/KizbaTests.swiftmodule/arm64-apple-macos.swiftmodule

Ld /Users/kirillsimagin/Library/Developer/Xcode/DerivedData/Kizba-efejvmfzdmoqdoewsmanttogshar/Build/Products/Debug/Kizba.app/Contents/PlugIns/KizbaTests.xctest/Contents/MacOS/KizbaTests normal (in target 'KizbaTests' from project 'Kizba')
    cd /Users/kirillsimagin/dev/my/worldproject/kizba
    /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/clang -Xlinker -reproducible -target arm64-apple-macos14.0 -bundle -isysroot /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX26.5.sdk -O0 -L/Users/kirillsimagin/Library/Developer/Xcode/DerivedData/Kizba-efejvmfzdmoqdoewsmanttogshar/Build/Intermediates.noindex/EagerLinkingTBDs/Debug -L/Users/kirillsimagin/Library/Developer/Xcode/DerivedData/Kizba-efejvmfzdmoqdoewsmanttogshar/Build/Products/Debug -L/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/usr/lib -F/Users/kirillsimagin/Library/Developer/Xcode/DerivedData/Kizba-efejvmfzdmoqdoewsmanttogshar/Build/Intermediates.noindex/EagerLinkingTBDs/Debug -F/Users/kirillsimagin/Library/Developer/Xcode/DerivedData/Kizba-efejvmfzdmoqdoewsmanttogshar/Build/Products/Debug -iframework /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/Library/Frameworks -filelist /Users/kirillsimagin/Library/Developer/Xcode/DerivedData/Kizba-efejvmfzdmoqdoewsmanttogshar/Build/Intermediates.noindex/Kizba.build/Debug/KizbaTests.build/Objects-normal/arm64/KizbaTests.LinkFileList -Xlinker -rpath -Xlinker /usr/lib/swift -Xlinker -rpath -Xlinker @loader_path/../Frameworks -Xlinker -rpath -Xlinker @executable_path/../Frameworks -Xlinker -dead_strip -bundle_loader /Users/kirillsimagin/Library/Developer/Xcode/DerivedData/Kizba-efejvmfzdmoqdoewsmanttogshar/Build/Products/Debug/Kizba.app/Contents/MacOS/Kizba -Xlinker -object_path_lto -Xlinker /Users/kirillsimagin/Library/Developer/Xcode/DerivedData/Kizba-efejvmfzdmoqdoewsmanttogshar/Build/Intermediates.noindex/Kizba.build/Debug/KizbaTests.build/Objects-normal/arm64/KizbaTests_lto.o -rdynamic -Xlinker -no_deduplicate -Xlinker -dependency_info -Xlinker /Users/kirillsimagin/Library/Developer/Xcode/DerivedData/Kizba-efejvmfzdmoqdoewsmanttogshar/Build/Intermediates.noindex/Kizba.build/Debug/KizbaTests.build/Objects-normal/arm64/KizbaTests_dependency_info.dat -fobjc-link-runtime -L/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/lib/swift/macosx -L/usr/lib/swift -Xlinker -add_ast_path -Xlinker /Users/kirillsimagin/Library/Developer/Xcode/DerivedData/Kizba-efejvmfzdmoqdoewsmanttogshar/Build/Intermediates.noindex/Kizba.build/Debug/KizbaTests.build/Objects-normal/arm64/KizbaTests.swiftmodule @/Users/kirillsimagin/Library/Developer/Xcode/DerivedData/Kizba-efejvmfzdmoqdoewsmanttogshar/Build/Intermediates.noindex/Kizba.build/Debug/KizbaTests.build/Objects-normal/arm64/KizbaTests-linker-args.resp -Xlinker -needed_framework -Xlinker XCTest -framework XCTest -Xlinker -needed-lXCTestSwiftSupport -lXCTestSwiftSupport /Users/kirillsimagin/Library/Developer/Xcode/DerivedData/Kizba-efejvmfzdmoqdoewsmanttogshar/Build/Products/Debug/Kizba.app/Contents/MacOS/Kizba.debug.dylib -Xlinker -no_adhoc_codesign -o /Users/kirillsimagin/Library/Developer/Xcode/DerivedData/Kizba-efejvmfzdmoqdoewsmanttogshar/Build/Products/Debug/Kizba.app/Contents/PlugIns/KizbaTests.xctest/Contents/MacOS/KizbaTests

CopySwiftLibs /Users/kirillsimagin/Library/Developer/Xcode/DerivedData/Kizba-efejvmfzdmoqdoewsmanttogshar/Build/Products/Debug/Kizba.app/Contents/PlugIns/KizbaTests.xctest (in target 'KizbaTests' from project 'Kizba')
    cd /Users/kirillsimagin/dev/my/worldproject/kizba
    builtin-swiftStdLibTool --copy --verbose --sign - --scan-executable /Users/kirillsimagin/Library/Developer/Xcode/DerivedData/Kizba-efejvmfzdmoqdoewsmanttogshar/Build/Products/Debug/Kizba.app/Contents/PlugIns/KizbaTests.xctest/Contents/MacOS/KizbaTests --scan-folder /Users/kirillsimagin/Library/Developer/Xcode/DerivedData/Kizba-efejvmfzdmoqdoewsmanttogshar/Build/Products/Debug/Kizba.app/Contents/PlugIns/KizbaTests.xctest/Contents/Frameworks --scan-folder /Users/kirillsimagin/Library/Developer/Xcode/DerivedData/Kizba-efejvmfzdmoqdoewsmanttogshar/Build/Products/Debug/Kizba.app/Contents/PlugIns/KizbaTests.xctest/Contents/PlugIns --scan-folder /Users/kirillsimagin/Library/Developer/Xcode/DerivedData/Kizba-efejvmfzdmoqdoewsmanttogshar/Build/Products/Debug/Kizba.app/Contents/PlugIns/KizbaTests.xctest/Contents/Library/SystemExtensions --scan-folder /Users/kirillsimagin/Library/Developer/Xcode/DerivedData/Kizba-efejvmfzdmoqdoewsmanttogshar/Build/Products/Debug/Kizba.app/Contents/PlugIns/KizbaTests.xctest/Contents/Extensions --platform macosx --toolchain /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain --destination /Users/kirillsimagin/Library/Developer/Xcode/DerivedData/Kizba-efejvmfzdmoqdoewsmanttogshar/Build/Products/Debug/Kizba.app/Contents/PlugIns/KizbaTests.xctest/Contents/Frameworks --strip-bitcode --scan-executable /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/usr/lib/libXCTestSwiftSupport.dylib --strip-bitcode-tool /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/bitcode_strip --emit-dependency-info /Users/kirillsimagin/Library/Developer/Xcode/DerivedData/Kizba-efejvmfzdmoqdoewsmanttogshar/Build/Intermediates.noindex/Kizba.build/Debug/KizbaTests.build/SwiftStdLibToolInputDependencies.dep --filter-for-swift-os --back-deploy-swift-span

ExtractAppIntentsMetadata (in target 'KizbaTests' from project 'Kizba')
    cd /Users/kirillsimagin/dev/my/worldproject/kizba
    /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/appintentsmetadataprocessor --toolchain-dir /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain --module-name KizbaTests --sdk-root /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX26.5.sdk --xcode-version 17F42 --platform-family macOS --deployment-target 14.0 --bundle-identifier app.kizba.KizbaTests --output /Users/kirillsimagin/Library/Developer/Xcode/DerivedData/Kizba-efejvmfzdmoqdoewsmanttogshar/Build/Products/Debug/Kizba.app/Contents/PlugIns/KizbaTests.xctest/Contents/Resources --target-triple arm64-apple-macos14.0 --binary-file /Users/kirillsimagin/Library/Developer/Xcode/DerivedData/Kizba-efejvmfzdmoqdoewsmanttogshar/Build/Products/Debug/Kizba.app/Contents/PlugIns/KizbaTests.xctest/Contents/MacOS/KizbaTests --dependency-file /Users/kirillsimagin/Library/Developer/Xcode/DerivedData/Kizba-efejvmfzdmoqdoewsmanttogshar/Build/Intermediates.noindex/Kizba.build/Debug/KizbaTests.build/Objects-normal/arm64/KizbaTests_dependency_info.dat --stringsdata-file /Users/kirillsimagin/Library/Developer/Xcode/DerivedData/Kizba-efejvmfzdmoqdoewsmanttogshar/Build/Intermediates.noindex/Kizba.build/Debug/KizbaTests.build/Objects-normal/arm64/ExtractedAppShortcutsMetadata.stringsdata --source-file-list /Users/kirillsimagin/Library/Developer/Xcode/DerivedData/Kizba-efejvmfzdmoqdoewsmanttogshar/Build/Intermediates.noindex/Kizba.build/Debug/KizbaTests.build/Objects-normal/arm64/KizbaTests.SwiftFileList --metadata-file-list /Users/kirillsimagin/Library/Developer/Xcode/DerivedData/Kizba-efejvmfzdmoqdoewsmanttogshar/Build/Intermediates.noindex/Kizba.build/Debug/KizbaTests.build/KizbaTests.DependencyMetadataFileList --static-metadata-file-list /Users/kirillsimagin/Library/Developer/Xcode/DerivedData/Kizba-efejvmfzdmoqdoewsmanttogshar/Build/Intermediates.noindex/Kizba.build/Debug/KizbaTests.build/KizbaTests.DependencyStaticMetadataFileList --swift-const-vals-list /Users/kirillsimagin/Library/Developer/Xcode/DerivedData/Kizba-efejvmfzdmoqdoewsmanttogshar/Build/Intermediates.noindex/Kizba.build/Debug/KizbaTests.build/Objects-normal/arm64/KizbaTests.SwiftConstValuesFileList --compile-time-extraction --deployment-aware-processing --validate-assistant-intents --no-app-shortcuts-localization
2026-05-24 08:25:04.230 appintentsmetadataprocessor[11874:1070402] Starting appintentsmetadataprocessor export
2026-05-24 08:25:04.232 appintentsmetadataprocessor[11874:1070402] warning: Metadata extraction skipped. No AppIntents.framework dependency found.

CodeSign /Users/kirillsimagin/Library/Developer/Xcode/DerivedData/Kizba-efejvmfzdmoqdoewsmanttogshar/Build/Products/Debug/Kizba.app/Contents/PlugIns/KizbaTests.xctest (in target 'KizbaTests' from project 'Kizba')
    cd /Users/kirillsimagin/dev/my/worldproject/kizba
    
    Signing Identity:     "Sign to Run Locally"
    
    /usr/bin/codesign --force --sign - --timestamp\=none --generate-entitlement-der /Users/kirillsimagin/Library/Developer/Xcode/DerivedData/Kizba-efejvmfzdmoqdoewsmanttogshar/Build/Products/Debug/Kizba.app/Contents/PlugIns/KizbaTests.xctest

CodeSign /Users/kirillsimagin/Library/Developer/Xcode/DerivedData/Kizba-efejvmfzdmoqdoewsmanttogshar/Build/Products/Debug/Kizba.app/Contents/MacOS/Kizba.debug.dylib (in target 'Kizba' from project 'Kizba')
    cd /Users/kirillsimagin/dev/my/worldproject/kizba
    
    Signing Identity:     "Sign to Run Locally"
    
    /usr/bin/codesign --force --sign - --timestamp\=none --generate-entitlement-der /Users/kirillsimagin/Library/Developer/Xcode/DerivedData/Kizba-efejvmfzdmoqdoewsmanttogshar/Build/Products/Debug/Kizba.app/Contents/MacOS/Kizba.debug.dylib
/Users/kirillsimagin/Library/Developer/Xcode/DerivedData/Kizba-efejvmfzdmoqdoewsmanttogshar/Build/Products/Debug/Kizba.app/Contents/MacOS/Kizba.debug.dylib: replacing existing signature

CodeSign /Users/kirillsimagin/Library/Developer/Xcode/DerivedData/Kizba-efejvmfzdmoqdoewsmanttogshar/Build/Products/Debug/Kizba.app/Contents/MacOS/__preview.dylib (in target 'Kizba' from project 'Kizba')
    cd /Users/kirillsimagin/dev/my/worldproject/kizba
    
    Signing Identity:     "Sign to Run Locally"
    
    /usr/bin/codesign --force --sign - --timestamp\=none --generate-entitlement-der /Users/kirillsimagin/Library/Developer/Xcode/DerivedData/Kizba-efejvmfzdmoqdoewsmanttogshar/Build/Products/Debug/Kizba.app/Contents/MacOS/__preview.dylib
/Users/kirillsimagin/Library/Developer/Xcode/DerivedData/Kizba-efejvmfzdmoqdoewsmanttogshar/Build/Products/Debug/Kizba.app/Contents/MacOS/__preview.dylib: replacing existing signature

CodeSign /Users/kirillsimagin/Library/Developer/Xcode/DerivedData/Kizba-efejvmfzdmoqdoewsmanttogshar/Build/Products/Debug/Kizba.app (in target 'Kizba' from project 'Kizba')
    cd /Users/kirillsimagin/dev/my/worldproject/kizba
    
    Signing Identity:     "Sign to Run Locally"
    
    /usr/bin/codesign --force --sign - --entitlements /Users/kirillsimagin/Library/Developer/Xcode/DerivedData/Kizba-efejvmfzdmoqdoewsmanttogshar/Build/Intermediates.noindex/Kizba.build/Debug/Kizba.build/Kizba.app.xcent --timestamp\=none --generate-entitlement-der /Users/kirillsimagin/Library/Developer/Xcode/DerivedData/Kizba-efejvmfzdmoqdoewsmanttogshar/Build/Products/Debug/Kizba.app
/Users/kirillsimagin/Library/Developer/Xcode/DerivedData/Kizba-efejvmfzdmoqdoewsmanttogshar/Build/Products/Debug/Kizba.app: replacing existing signature

Validate /Users/kirillsimagin/Library/Developer/Xcode/DerivedData/Kizba-efejvmfzdmoqdoewsmanttogshar/Build/Products/Debug/Kizba.app (in target 'Kizba' from project 'Kizba')
    cd /Users/kirillsimagin/dev/my/worldproject/kizba
    builtin-validationUtility /Users/kirillsimagin/Library/Developer/Xcode/DerivedData/Kizba-efejvmfzdmoqdoewsmanttogshar/Build/Products/Debug/Kizba.app -no-validate-extension -infoplist-subpath Contents/Info.plist

RegisterWithLaunchServices /Users/kirillsimagin/Library/Developer/Xcode/DerivedData/Kizba-efejvmfzdmoqdoewsmanttogshar/Build/Products/Debug/Kizba.app (in target 'Kizba' from project 'Kizba')
    cd /Users/kirillsimagin/dev/my/worldproject/kizba
    /System/Library/Frameworks/CoreServices.framework/Versions/Current/Frameworks/LaunchServices.framework/Versions/Current/Support/lsregister -f -R -trusted /Users/kirillsimagin/Library/Developer/Xcode/DerivedData/Kizba-efejvmfzdmoqdoewsmanttogshar/Build/Products/Debug/Kizba.app

2026-05-24 08:25:06.128746+0200 Kizba[11882:1070610] [Connection] Unable to get synchronousRemoteObjectProxy, error: Error Domain=NSCocoaErrorDomain Code=4097 "connection to service named com.apple.linkd.autoShortcut" UserInfo={NSDebugDescription=connection to service named com.apple.linkd.autoShortcut}
2026-05-24 08:25:06.129382+0200 Kizba[11882:1070611] [Connection] Unable to get synchronousRemoteObjectProxy, error: Error Domain=NSCocoaErrorDomain Code=4097 "connection to service named com.apple.linkd.autoShortcut" UserInfo={NSDebugDescription=connection to service named com.apple.linkd.autoShortcut}
2026-05-24 08:25:06.130210+0200 Kizba[11882:1070614] [Connection] Unable to get synchronousRemoteObjectProxy, error: Error Domain=NSCocoaErrorDomain Code=4097 "connection to service named com.apple.linkd.autoShortcut" UserInfo={NSDebugDescription=connection to service named com.apple.linkd.autoShortcut}
2026-05-24 08:25:06.130636+0200 Kizba[11882:1070616] [Connection] Unable to get synchronousRemoteObjectProxy, error: Error Domain=NSCocoaErrorDomain Code=4097 "connection to service named com.apple.linkd.autoShortcut" UserInfo={NSDebugDescription=connection to service named com.apple.linkd.autoShortcut}
2026-05-24 08:25:06.131343+0200 Kizba[11882:1070616] [Connection] Unable to re-register with Process Instance Registry, error: Error Domain=NSCocoaErrorDomain Code=4097 "connection to service named com.apple.linkd.autoShortcut" UserInfo={NSDebugDescription=connection to service named com.apple.linkd.autoShortcut}
2026-05-24 08:25:06.131158+0200 Kizba[11882:1070611] [Connection] Unable to re-register with Process Instance Registry, error: Error Domain=NSCocoaErrorDomain Code=4097 "connection to service named com.apple.linkd.autoShortcut" UserInfo={NSDebugDescription=connection to service named com.apple.linkd.autoShortcut}
2026-05-24 08:25:06.131166+0200 Kizba[11882:1070610] [Application] Error registering app with intents framework: Error Domain=NSCocoaErrorDomain Code=4097 "connection to service named com.apple.linkd.autoShortcut" UserInfo={NSDebugDescription=connection to service named com.apple.linkd.autoShortcut}
2026-05-24 08:25:06.131152+0200 Kizba[11882:1070617] [Connection] Unable to get synchronousRemoteObjectProxy, error: Error Domain=NSCocoaErrorDomain Code=4097 "connection to service named com.apple.linkd.autoShortcut" UserInfo={NSDebugDescription=connection to service named com.apple.linkd.autoShortcut}
2026-05-24 08:25:06.131163+0200 Kizba[11882:1070614] [Connection] Unable to re-register with Process Instance Registry, error: Error Domain=NSCocoaErrorDomain Code=4097 "connection to service named com.apple.linkd.autoShortcut" UserInfo={NSDebugDescription=connection to service named com.apple.linkd.autoShortcut}
2026-05-24 08:25:06.133061+0200 Kizba[11882:1070616] [Connection] Will NOT re-try to establish the connection
2026-05-24 08:25:06.133698+0200 Kizba[11882:1070617] [Connection] Unable to re-register with Process Instance Registry, error: Error Domain=NSCocoaErrorDomain Code=4097 "connection to service named com.apple.linkd.autoShortcut" UserInfo={NSDebugDescription=connection to service named com.apple.linkd.autoShortcut}
2026-05-24 08:25:06.133707+0200 Kizba[11882:1070618] [Connection] Unable to get synchronousRemoteObjectProxy, error: Error Domain=NSCocoaErrorDomain Code=4097 "connection to service named com.apple.linkd.autoShortcut" UserInfo={NSDebugDescription=connection to service named com.apple.linkd.autoShortcut}
2026-05-24 08:25:06.134991+0200 Kizba[11882:1070618] [Connection] Unable to re-register with Process Instance Registry, error: Error Domain=NSCocoaErrorDomain Code=4097 "connection to service named com.apple.linkd.autoShortcut" UserInfo={NSDebugDescription=connection to service named com.apple.linkd.autoShortcut}
2026-05-24 08:25:06.214075+0200 Kizba[11882:1070534] ApplePersistenceIgnoreState: Existing state will not be touched. New state will be written to /var/folders/2p/cjjcq6ys0cnc6cp8y7lv9vqr0000gn/T/app.kizba.Kizba.savedState
2026-05-24 08:25:06.653882+0200 Kizba[11882:1070616] [discovery] locate resolved name=git path=/opt/homebrew/bin/git
2026-05-24 08:25:06.688504+0200 Kizba[11882:1070534] [WarnOnce] It's not legal to call -layoutSubtreeIfNeeded on a view which is already being laid out.  If you are implementing the view's -layout method, you can call -[super layout] instead.  Break on void _NSDetectedLayoutRecursion(void) to debug.  This will be logged only once.  This may break in the future.
2026-05-24 08:25:06.735338+0200 Kizba[11882:1070614] [discovery] locate resolved name=pass path=/opt/homebrew/bin/pass
Test Suite 'All tests' started at 2026-05-24 08:25:06.916.
Test Suite 'KizbaTests.xctest' started at 2026-05-24 08:25:06.917.
Test Suite 'ActionHistoryTests' started at 2026-05-24 08:25:06.917.
Test Case '-[KizbaTests.ActionHistoryTests testClear_resetsPendingAndCancelsExpiry]' started.
Test Case '-[KizbaTests.ActionHistoryTests testClear_resetsPendingAndCancelsExpiry]' passed (0.016 seconds).
Test Case '-[KizbaTests.ActionHistoryTests testExpiry_clearsPendingAfterWindow]' started.
Test Case '-[KizbaTests.ActionHistoryTests testExpiry_clearsPendingAfterWindow]' passed (0.061 seconds).
Test Case '-[KizbaTests.ActionHistoryTests testExpiry_longWindow_keepsPending]' started.
2026-05-24 08:25:07.014065+0200 Kizba[11882:1070614] [shell] shell exit: exe=/opt/homebrew/bin/git argc=5 status=0 stderrBytes=0 bytesIn=0
2026-05-24 08:25:07.031553+0200 Kizba[11882:1070614] [shell] shell exit: exe=/opt/homebrew/bin/git argc=3 status=0 stderrBytes=0 bytesIn=0
Test Case '-[KizbaTests.ActionHistoryTests testExpiry_longWindow_keepsPending]' passed (0.103 seconds).
Test Case '-[KizbaTests.ActionHistoryTests testInitialState_pendingIsNil]' started.
Test Case '-[KizbaTests.ActionHistoryTests testInitialState_pendingIsNil]' passed (0.001 seconds).
Test Case '-[KizbaTests.ActionHistoryTests testRecord_replacesPreviousAction_andCancelsPriorExpiry]' started.
Test Case '-[KizbaTests.ActionHistoryTests testRecord_replacesPreviousAction_andCancelsPriorExpiry]' passed (0.113 seconds).
Test Case '-[KizbaTests.ActionHistoryTests testRecord_setsPending]' started.
Test Case '-[KizbaTests.ActionHistoryTests testRecord_setsPending]' passed (0.001 seconds).
Test Case '-[KizbaTests.ActionHistoryTests testUndoLast_afterExpiry_isNoOp_andClearsPending]' started.
Test Case '-[KizbaTests.ActionHistoryTests testUndoLast_afterExpiry_isNoOp_andClearsPending]' passed (0.127 seconds).
Test Case '-[KizbaTests.ActionHistoryTests testUndoLast_delete_reInsertsSecret]' started.
Test Case '-[KizbaTests.ActionHistoryTests testUndoLast_delete_reInsertsSecret]' passed (0.002 seconds).
Test Case '-[KizbaTests.ActionHistoryTests testUndoLast_inPlaceGenerate_restoresPriorSecret]' started.
Test Case '-[KizbaTests.ActionHistoryTests testUndoLast_inPlaceGenerate_restoresPriorSecret]' passed (0.002 seconds).
Test Case '-[KizbaTests.ActionHistoryTests testUndoLast_inverseFails_propagatesAndClearsPending]' started.
Test Case '-[KizbaTests.ActionHistoryTests testUndoLast_inverseFails_propagatesAndClearsPending]' passed (0.003 seconds).
Test Case '-[KizbaTests.ActionHistoryTests testUndoLast_move_movesEntryBack]' started.
Test Case '-[KizbaTests.ActionHistoryTests testUndoLast_move_movesEntryBack]' passed (0.002 seconds).
Test Case '-[KizbaTests.ActionHistoryTests testUndoLast_noPending_isNoOp]' started.
Test Case '-[KizbaTests.ActionHistoryTests testUndoLast_noPending_isNoOp]' passed (0.002 seconds).
Test Suite 'ActionHistoryTests' passed at 2026-05-24 08:25:07.355.
	 Executed 12 tests, with 0 failures (0 unexpected) in 0.433 (0.439) seconds
Test Suite 'AddTOTPSheetBuildSecretTests' started at 2026-05-24 08:25:07.356.
Test Case '-[KizbaTests.AddTOTPSheetBuildSecretTests testErrorMessages_areUserFacing]' started.
Test Case '-[KizbaTests.AddTOTPSheetBuildSecretTests testErrorMessages_areUserFacing]' passed (0.002 seconds).
Test Case '-[KizbaTests.AddTOTPSheetBuildSecretTests testGenerateRandom_ignoresOtherFields]' started.
Test Case '-[KizbaTests.AddTOTPSheetBuildSecretTests testGenerateRandom_ignoresOtherFields]' passed (0.002 seconds).
Test Case '-[KizbaTests.AddTOTPSheetBuildSecretTests testGenerateRandom_returnsValidSecret_withIssuerAndLabel]' started.
Test Case '-[KizbaTests.AddTOTPSheetBuildSecretTests testGenerateRandom_returnsValidSecret_withIssuerAndLabel]' passed (0.018 seconds).
Test Case '-[KizbaTests.AddTOTPSheetBuildSecretTests testPassphrase_emptyInput_returnsEmptyPassphraseError]' started.
Test Case '-[KizbaTests.AddTOTPSheetBuildSecretTests testPassphrase_emptyInput_returnsEmptyPassphraseError]' passed (0.002 seconds).
Test Case '-[KizbaTests.AddTOTPSheetBuildSecretTests testPassphrase_nonEmpty_isDeterministic]' started.
Test Case '-[KizbaTests.AddTOTPSheetBuildSecretTests testPassphrase_nonEmpty_isDeterministic]' passed (0.002 seconds).
Test Case '-[KizbaTests.AddTOTPSheetBuildSecretTests testPasteURI_invalidScheme_returnsInvalidURIError]' started.
Test Case '-[KizbaTests.AddTOTPSheetBuildSecretTests testPasteURI_invalidScheme_returnsInvalidURIError]' passed (0.002 seconds).
Test Case '-[KizbaTests.AddTOTPSheetBuildSecretTests testPasteURI_issuerOverride_winsOverEmbeddedIssuer]' started.
Test Case '-[KizbaTests.AddTOTPSheetBuildSecretTests testPasteURI_issuerOverride_winsOverEmbeddedIssuer]' passed (0.001 seconds).
Test Case '-[KizbaTests.AddTOTPSheetBuildSecretTests testPasteURI_validURI_parses]' started.
Test Case '-[KizbaTests.AddTOTPSheetBuildSecretTests testPasteURI_validURI_parses]' passed (0.002 seconds).
Test Case '-[KizbaTests.AddTOTPSheetBuildSecretTests testTypeSecret_empty_returnsInvalidBase32Error]' started.
Test Case '-[KizbaTests.AddTOTPSheetBuildSecretTests testTypeSecret_empty_returnsInvalidBase32Error]' passed (0.001 seconds).
Test Case '-[KizbaTests.AddTOTPSheetBuildSecretTests testTypeSecret_invalidCharacters_returnsInvalidBase32Error]' started.
Test Case '-[KizbaTests.AddTOTPSheetBuildSecretTests testTypeSecret_invalidCharacters_returnsInvalidBase32Error]' passed (0.002 seconds).
Test Case '-[KizbaTests.AddTOTPSheetBuildSecretTests testTypeSecret_validBase32_succeeds]' started.
Test Case '-[KizbaTests.AddTOTPSheetBuildSecretTests testTypeSecret_validBase32_succeeds]' passed (0.001 seconds).
Test Suite 'AddTOTPSheetBuildSecretTests' passed at 2026-05-24 08:25:07.408.
	 Executed 11 tests, with 0 failures (0 unexpected) in 0.036 (0.053) seconds
Test Suite 'AppEnvironmentClipboardTests' started at 2026-05-24 08:25:07.414.
Test Case '-[KizbaTests.AppEnvironmentClipboardTests testLive_andPreview_clipboardsAreDistinctTypes]' started.
Test Case '-[KizbaTests.AppEnvironmentClipboardTests testLive_andPreview_clipboardsAreDistinctTypes]' passed (0.002 seconds).
Test Case '-[KizbaTests.AppEnvironmentClipboardTests testLive_clipboardIsProductionClipboardService]' started.
Test Case '-[KizbaTests.AppEnvironmentClipboardTests testLive_clipboardIsProductionClipboardService]' passed (0.001 seconds).
Test Case '-[KizbaTests.AppEnvironmentClipboardTests testPreview_clipboardIsNotProductionService]' started.
Test Case '-[KizbaTests.AppEnvironmentClipboardTests testPreview_clipboardIsNotProductionService]' passed (0.001 seconds).
Test Suite 'AppEnvironmentClipboardTests' passed at 2026-05-24 08:25:07.418.
	 Executed 3 tests, with 0 failures (0 unexpected) in 0.003 (0.004) seconds
Test Suite 'AppEnvironmentGitWiringTests' started at 2026-05-24 08:25:07.418.
Test Case '-[KizbaTests.AppEnvironmentGitWiringTests testWireGitModel_createsModel_whenRepo]' started.
Test Case '-[KizbaTests.AppEnvironmentGitWiringTests testWireGitModel_createsModel_whenRepo]' passed (0.031 seconds).
Test Case '-[KizbaTests.AppEnvironmentGitWiringTests testWireGitModel_gitNotFound_doesNotCreateModel]' started.
Test Case '-[KizbaTests.AppEnvironmentGitWiringTests testWireGitModel_gitNotFound_doesNotCreateModel]' passed (0.005 seconds).
Test Case '-[KizbaTests.AppEnvironmentGitWiringTests testWireGitModel_noDiscovery_doesNotCreateModel]' started.
Test Case '-[KizbaTests.AppEnvironmentGitWiringTests testWireGitModel_noDiscovery_doesNotCreateModel]' passed (0.005 seconds).
Test Suite 'AppEnvironmentGitWiringTests' passed at 2026-05-24 08:25:07.460.
	 Executed 3 tests, with 0 failures (0 unexpected) in 0.041 (0.042) seconds
Test Suite 'AppEnvironmentPassCLITests' started at 2026-05-24 08:25:07.461.
Test Case '-[KizbaTests.AppEnvironmentPassCLITests testLive_includesPassCLI]' started.
Test Case '-[KizbaTests.AppEnvironmentPassCLITests testLive_includesPassCLI]' passed (0.001 seconds).
Test Case '-[KizbaTests.AppEnvironmentPassCLITests testLive_passCLIWiresBinaryDiscoveryService]' started.
Test Case '-[KizbaTests.AppEnvironmentPassCLITests testLive_passCLIWiresBinaryDiscoveryService]' passed (0.007 seconds).
Test Case '-[KizbaTests.AppEnvironmentPassCLITests testLivePassCLI_throwsBinaryNotFoundWhenDiscoveryReturnsNil]' started.
Test Case '-[KizbaTests.AppEnvironmentPassCLITests testLivePassCLI_throwsBinaryNotFoundWhenDiscoveryReturnsNil]' passed (0.003 seconds).
Test Case '-[KizbaTests.AppEnvironmentPassCLITests testPreview_doesNotIncludePassCLI]' started.
Test Case '-[KizbaTests.AppEnvironmentPassCLITests testPreview_doesNotIncludePassCLI]' passed (0.001 seconds).
Test Suite 'AppEnvironmentPassCLITests' passed at 2026-05-24 08:25:07.473.
	 Executed 4 tests, with 0 failures (0 unexpected) in 0.012 (0.013) seconds
Test Suite 'AppEnvironmentTests' started at 2026-05-24 08:25:07.474.
Test Case '-[KizbaTests.AppEnvironmentTests testPreview_passManagerExposesFixtureCorpus]' started.
Test Case '-[KizbaTests.AppEnvironmentTests testPreview_passManagerExposesFixtureCorpus]' passed (0.001 seconds).
Test Case '-[KizbaTests.AppEnvironmentTests testPreview_passManagerShowReturnsKnownFixture]' started.
Test Case '-[KizbaTests.AppEnvironmentTests testPreview_passManagerShowReturnsKnownFixture]' passed (0.001 seconds).
Test Case '-[KizbaTests.AppEnvironmentTests testPreview_passManagerStoreLocationIsStable]' started.
Test Case '-[KizbaTests.AppEnvironmentTests testPreview_passManagerStoreLocationIsStable]' passed (0.001 seconds).
Test Suite 'AppEnvironmentTests' passed at 2026-05-24 08:25:07.478.
	 Executed 3 tests, with 0 failures (0 unexpected) in 0.003 (0.004) seconds
Test Suite 'AppInfoTests' started at 2026-05-24 08:25:07.478.
Test Case '-[KizbaTests.AppInfoTests testBuildIsNotEmpty]' started.
Test Case '-[KizbaTests.AppInfoTests testBuildIsNotEmpty]' passed (0.001 seconds).
Test Case '-[KizbaTests.AppInfoTests testVersionIsNotEmpty]' started.
Test Case '-[KizbaTests.AppInfoTests testVersionIsNotEmpty]' passed (0.001 seconds).
Test Suite 'AppInfoTests' passed at 2026-05-24 08:25:07.480.
	 Executed 2 tests, with 0 failures (0 unexpected) in 0.001 (0.002) seconds
Test Suite 'AppRouterTests' started at 2026-05-24 08:25:07.485.
Test Case '-[KizbaTests.AppRouterTests testDismissAllClearsPresentationFlags]' started.
Test Case '-[KizbaTests.AppRouterTests testDismissAllClearsPresentationFlags]' passed (0.001 seconds).
Test Case '-[KizbaTests.AppRouterTests testPresentMethodsSetFlags]' started.
Test Case '-[KizbaTests.AppRouterTests testPresentMethodsSetFlags]' passed (0.001 seconds).
Test Case '-[KizbaTests.AppRouterTests testSelectedEntryID_canBeSetIndependentlyOfSelectedFolder]' started.
Test Case '-[KizbaTests.AppRouterTests testSelectedEntryID_canBeSetIndependentlyOfSelectedFolder]' passed (0.001 seconds).
Test Case '-[KizbaTests.AppRouterTests testSelectFolderAndEntry]' started.
Test Case '-[KizbaTests.AppRouterTests testSelectFolderAndEntry]' passed (0.001 seconds).
Test Suite 'AppRouterTests' passed at 2026-05-24 08:25:07.489.
	 Executed 4 tests, with 0 failures (0 unexpected) in 0.003 (0.004) seconds
Test Suite 'AppStateTests' started at 2026-05-24 08:25:07.489.
Test Case '-[KizbaTests.AppStateTests testCurrentEntries_isMutable]' started.
Test Case '-[KizbaTests.AppStateTests testCurrentEntries_isMutable]' passed (0.001 seconds).
Test Case '-[KizbaTests.AppStateTests testGitStatusModel_defaultNil]' started.
Test Case '-[KizbaTests.AppStateTests testGitStatusModel_defaultNil]' passed (0.001 seconds).
Test Case '-[KizbaTests.AppStateTests testInit_acceptsExplicitValues]' started.
Test Case '-[KizbaTests.AppStateTests testInit_acceptsExplicitValues]' passed (0.001 seconds).
Test Case '-[KizbaTests.AppStateTests testInit_defaultsAreEmpty]' started.
Test Case '-[KizbaTests.AppStateTests testInit_defaultsAreEmpty]' passed (0.001 seconds).
Test Case '-[KizbaTests.AppStateTests testSearchQuery_isMutable]' started.
Test Case '-[KizbaTests.AppStateTests testSearchQuery_isMutable]' passed (0.001 seconds).
Test Case '-[KizbaTests.AppStateTests testSelectedEntryID_isMutable]' started.
Test Case '-[KizbaTests.AppStateTests testSelectedEntryID_isMutable]' passed (0.001 seconds).
Test Suite 'AppStateTests' passed at 2026-05-24 08:25:07.521.
	 Executed 6 tests, with 0 failures (0 unexpected) in 0.005 (0.032) seconds
Test Suite 'AsyncTestHelpersTests' started at 2026-05-24 08:25:07.521.
Test Case '-[KizbaTests.AsyncTestHelpersTests testStartObservation_andWaitUntil_workTogether]' started.
Test Case '-[KizbaTests.AsyncTestHelpersTests testStartObservation_andWaitUntil_workTogether]' passed (0.022 seconds).
Test Case '-[KizbaTests.AsyncTestHelpersTests testWaitUntil_succeeds_whenPredicateBecomesTrue]' started.
Test Case '-[KizbaTests.AsyncTestHelpersTests testWaitUntil_succeeds_whenPredicateBecomesTrue]' passed (0.023 seconds).
Test Suite 'AsyncTestHelpersTests' passed at 2026-05-24 08:25:07.568.
	 Executed 2 tests, with 0 failures (0 unexpected) in 0.046 (0.047) seconds
Test Suite 'BannerViewTests' started at 2026-05-24 08:25:07.568.
Test Case '-[KizbaTests.BannerViewTests testBannerView_backgroundColor_isUniqueAcrossSeveritiesInEveryTheme]' started.
Test Case '-[KizbaTests.BannerViewTests testBannerView_backgroundColor_isUniqueAcrossSeveritiesInEveryTheme]' passed (0.002 seconds).
Test Case '-[KizbaTests.BannerViewTests testBannerView_backgroundColor_resolvesExpectedTokenPerSeverity]' started.
Test Case '-[KizbaTests.BannerViewTests testBannerView_backgroundColor_resolvesExpectedTokenPerSeverity]' passed (0.002 seconds).
Test Case '-[KizbaTests.BannerViewTests testBannerView_bodyTextMeetsWCAGContrast_inAllThemes]' started.
Test Case '-[KizbaTests.BannerViewTests testBannerView_bodyTextMeetsWCAGContrast_inAllThemes]' passed (0.001 seconds).
Test Case '-[KizbaTests.BannerViewTests testBannerView_iconColor_isUniqueAcrossSeveritiesInEveryTheme]' started.
Test Case '-[KizbaTests.BannerViewTests testBannerView_iconColor_isUniqueAcrossSeveritiesInEveryTheme]' passed (0.001 seconds).
Test Case '-[KizbaTests.BannerViewTests testBannerView_iconColor_resolvesExpectedTokenPerSeverity]' started.
Test Case '-[KizbaTests.BannerViewTests testBannerView_iconColor_resolvesExpectedTokenPerSeverity]' passed (0.002 seconds).
Test Case '-[KizbaTests.BannerViewTests testBannerView_iconMeetsWCAGNonTextContrast_inAllThemes]' started.
Test Case '-[KizbaTests.BannerViewTests testBannerView_iconMeetsWCAGNonTextContrast_inAllThemes]' passed (0.001 seconds).
Test Case '-[KizbaTests.BannerViewTests testBannerView_iconName_isCorrectPerSeverity]' started.
Test Case '-[KizbaTests.BannerViewTests testBannerView_iconName_isCorrectPerSeverity]' passed (0.001 seconds).
Test Case '-[KizbaTests.BannerViewTests testBannerView_iconName_isNonEmptyForEverySeverity]' started.
Test Case '-[KizbaTests.BannerViewTests testBannerView_iconName_isNonEmptyForEverySeverity]' passed (0.001 seconds).
Test Case '-[KizbaTests.BannerViewTests testBannerView_iconName_isUniquePerSeverity]' started.
Test Case '-[KizbaTests.BannerViewTests testBannerView_iconName_isUniquePerSeverity]' passed (0.001 seconds).
Test Case '-[KizbaTests.BannerViewTests testBannerView_severity_allCasesContainsExactlyFour]' started.
Test Case '-[KizbaTests.BannerViewTests testBannerView_severity_allCasesContainsExactlyFour]' passed (0.013 seconds).
Test Suite 'BannerViewTests' passed at 2026-05-24 08:25:07.596.
	 Executed 10 tests, with 0 failures (0 unexpected) in 0.024 (0.028) seconds
Test Suite 'Base32EncoderTests' started at 2026-05-24 08:25:07.597.
Test Case '-[KizbaTests.Base32EncoderTests testEncode_emitsNoPadding]' started.
Test Case '-[KizbaTests.Base32EncoderTests testEncode_emitsNoPadding]' passed (0.002 seconds).
Test Case '-[KizbaTests.Base32EncoderTests testEncode_empty_returnsEmptyString]' started.
Test Case '-[KizbaTests.Base32EncoderTests testEncode_empty_returnsEmptyString]' passed (0.002 seconds).
Test Case '-[KizbaTests.Base32EncoderTests testEncode_fiveBytes_fooba]' started.
Test Case '-[KizbaTests.Base32EncoderTests testEncode_fiveBytes_fooba]' passed (0.001 seconds).
Test Case '-[KizbaTests.Base32EncoderTests testEncode_fourBytes_foob]' started.
Test Case '-[KizbaTests.Base32EncoderTests testEncode_fourBytes_foob]' passed (0.001 seconds).
Test Case '-[KizbaTests.Base32EncoderTests testEncode_singleByteFoo_f]' started.
Test Case '-[KizbaTests.Base32EncoderTests testEncode_singleByteFoo_f]' passed (0.001 seconds).
Test Case '-[KizbaTests.Base32EncoderTests testEncode_sixBytes_foobar]' started.
Test Case '-[KizbaTests.Base32EncoderTests testEncode_sixBytes_foobar]' passed (0.001 seconds).
Test Case '-[KizbaTests.Base32EncoderTests testEncode_threeBytes_foo]' started.
Test Case '-[KizbaTests.Base32EncoderTests testEncode_threeBytes_foo]' passed (0.001 seconds).
Test Case '-[KizbaTests.Base32EncoderTests testEncode_twoBytes_fo]' started.
Test Case '-[KizbaTests.Base32EncoderTests testEncode_twoBytes_fo]' passed (0.002 seconds).
Test Case '-[KizbaTests.Base32EncoderTests testRoundtrip_fixedAllOnes_thirtyBytes]' started.
Test Case '-[KizbaTests.Base32EncoderTests testRoundtrip_fixedAllOnes_thirtyBytes]' passed (0.002 seconds).
Test Case '-[KizbaTests.Base32EncoderTests testRoundtrip_zeroToOneFiftyByteInputs]' started.
Test Case '-[KizbaTests.Base32EncoderTests testRoundtrip_zeroToOneFiftyByteInputs]' passed (0.009 seconds).
Test Suite 'Base32EncoderTests' passed at 2026-05-24 08:25:07.628.
	 Executed 10 tests, with 0 failures (0 unexpected) in 0.020 (0.031) seconds
Test Suite 'Base32Tests' started at 2026-05-24 08:25:07.628.
Test Case '-[KizbaTests.Base32Tests testEmpty]' started.
Test Case '-[KizbaTests.Base32Tests testEmpty]' passed (0.001 seconds).
Test Case '-[KizbaTests.Base32Tests testInvalidChar]' started.
Test Case '-[KizbaTests.Base32Tests testInvalidChar]' passed (0.001 seconds).
Test Case '-[KizbaTests.Base32Tests testLowercaseAccepted]' started.
Test Case '-[KizbaTests.Base32Tests testLowercaseAccepted]' passed (0.001 seconds).
Test Case '-[KizbaTests.Base32Tests testNoPaddingAccepted]' started.
Test Case '-[KizbaTests.Base32Tests testNoPaddingAccepted]' passed (0.001 seconds).
Test Case '-[KizbaTests.Base32Tests testSingleByte_MY_equals]' started.
Test Case '-[KizbaTests.Base32Tests testSingleByte_MY_equals]' passed (0.010 seconds).
Test Case '-[KizbaTests.Base32Tests testWhitespaceStripped]' started.
Test Case '-[KizbaTests.Base32Tests testWhitespaceStripped]' passed (0.001 seconds).
Test Suite 'Base32Tests' passed at 2026-05-24 08:25:07.645.
	 Executed 6 tests, with 0 failures (0 unexpected) in 0.015 (0.017) seconds
Test Suite 'BinaryDiscoveryServiceTests' started at 2026-05-24 08:25:07.645.
Test Case '-[KizbaTests.BinaryDiscoveryServiceTests testCachingAndReDetect]' started.
2026-05-24 08:25:07.646175+0200 Kizba[11882:1070610] [discovery] locate resolved name=pass path=/opt/homebrew/bin/pass
2026-05-24 08:25:07.646260+0200 Kizba[11882:1070610] [discovery] reDetect cache cleared
2026-05-24 08:25:07.646278+0200 Kizba[11882:1070610] [discovery] locate resolved name=pass path=/usr/local/bin/pass
Test Case '-[KizbaTests.BinaryDiscoveryServiceTests testCachingAndReDetect]' passed (0.001 seconds).
Test Case '-[KizbaTests.BinaryDiscoveryServiceTests testHomebrewPreferredOverUsrLocal]' started.
2026-05-24 08:25:07.661140+0200 Kizba[11882:1070614] [discovery] locate resolved name=pass path=/opt/homebrew/bin/pass
Test Case '-[KizbaTests.BinaryDiscoveryServiceTests testHomebrewPreferredOverUsrLocal]' passed (0.015 seconds).
Test Case '-[KizbaTests.BinaryDiscoveryServiceTests testNoFalsePositives]' started.
2026-05-24 08:25:07.664024+0200 Kizba[11882:1070610] [discovery] locate miss name=pass
Test Case '-[KizbaTests.BinaryDiscoveryServiceTests testNoFalsePositives]' passed (0.002 seconds).
Test Case '-[KizbaTests.BinaryDiscoveryServiceTests testOverrideMisconfigurationDoesNotFallBack]' started.
2026-05-24 08:25:07.667006+0200 Kizba[11882:1070614] [discovery] locate miss name=pass
Test Case '-[KizbaTests.BinaryDiscoveryServiceTests testOverrideMisconfigurationDoesNotFallBack]' passed (0.002 seconds).
Test Case '-[KizbaTests.BinaryDiscoveryServiceTests testOverrideProviderIsLive_changesAfterReDetect]' started.
2026-05-24 08:25:07.669544+0200 Kizba[11882:1070616] [discovery] locate resolved name=pass path=/opt/kizba/bin/passA
2026-05-24 08:25:07.672473+0200 Kizba[11882:1070616] [discovery] reDetect cache cleared
2026-05-24 08:25:07.672497+0200 Kizba[11882:1070616] [discovery] locate resolved name=pass path=/opt/kizba/bin/passB
Test Case '-[KizbaTests.BinaryDiscoveryServiceTests testOverrideProviderIsLive_changesAfterReDetect]' passed (0.005 seconds).
Test Case '-[KizbaTests.BinaryDiscoveryServiceTests testOverrideWins]' started.
2026-05-24 08:25:07.673762+0200 Kizba[11882:1070614] [discovery] locate resolved name=pass path=/opt/kizba/bin/pass
Test Case '-[KizbaTests.BinaryDiscoveryServiceTests testOverrideWins]' passed (0.001 seconds).
Test Case '-[KizbaTests.BinaryDiscoveryServiceTests testPathFallbackUsesSanitizedPathOrder]' started.
2026-05-24 08:25:07.675180+0200 Kizba[11882:1070614] [discovery] locate resolved name=pass path=/some/dir/pass
Test Case '-[KizbaTests.BinaryDiscoveryServiceTests testPathFallbackUsesSanitizedPathOrder]' passed (0.001 seconds).
Test Suite 'BinaryDiscoveryServiceTests' passed at 2026-05-24 08:25:07.676.
	 Executed 7 tests, with 0 failures (0 unexpected) in 0.027 (0.031) seconds
Test Suite 'BinaryLocatingTests' started at 2026-05-24 08:25:07.676.
Test Case '-[KizbaTests.BinaryLocatingTests testBinaryNameRawValues]' started.
Test Case '-[KizbaTests.BinaryLocatingTests testBinaryNameRawValues]' passed (0.005 seconds).
Test Case '-[KizbaTests.BinaryLocatingTests testLocateReturnsConfiguredURL]' started.
Test Case '-[KizbaTests.BinaryLocatingTests testLocateReturnsConfiguredURL]' passed (0.001 seconds).
Test Case '-[KizbaTests.BinaryLocatingTests testLocateReturnsNilWhenMissing]' started.
Test Case '-[KizbaTests.BinaryLocatingTests testLocateReturnsNilWhenMissing]' passed (0.001 seconds).
Test Case '-[KizbaTests.BinaryLocatingTests testReDetectClearsCache]' started.
Test Case '-[KizbaTests.BinaryLocatingTests testReDetectClearsCache]' passed (0.001 seconds).
Test Suite 'BinaryLocatingTests' passed at 2026-05-24 08:25:07.685.
	 Executed 4 tests, with 0 failures (0 unexpected) in 0.008 (0.009) seconds
Test Suite 'BiometricAuthenticatingTests' started at 2026-05-24 08:25:07.685.
Test Case '-[KizbaTests.BiometricAuthenticatingTests testBiometricResultEquatable]' started.
Test Case '-[KizbaTests.BiometricAuthenticatingTests testBiometricResultEquatable]' passed (0.004 seconds).
Test Case '-[KizbaTests.BiometricAuthenticatingTests testEnumsAreEquatable]' started.
Test Case '-[KizbaTests.BiometricAuthenticatingTests testEnumsAreEquatable]' passed (0.001 seconds).
Test Case '-[KizbaTests.BiometricAuthenticatingTests testFakeAuthenticator_conformsAndReturnsConfigured]' started.
Test Case '-[KizbaTests.BiometricAuthenticatingTests testFakeAuthenticator_conformsAndReturnsConfigured]' passed (0.001 seconds).
Test Suite 'BiometricAuthenticatingTests' passed at 2026-05-24 08:25:07.692.
	 Executed 3 tests, with 0 failures (0 unexpected) in 0.006 (0.006) seconds
Test Suite 'BiometricGateTests' started at 2026-05-24 08:25:07.692.
Test Case '-[KizbaTests.BiometricGateTests testIsSensitiveMetadataKey_whitelistAndControls_caseInsensitive]' started.
Test Case '-[KizbaTests.BiometricGateTests testIsSensitiveMetadataKey_whitelistAndControls_caseInsensitive]' passed (0.001 seconds).
Test Case '-[KizbaTests.BiometricGateTests testRun_policyOff_returnsTrue_andDoesNotAuthenticate]' started.
Test Case '-[KizbaTests.BiometricGateTests testRun_policyOff_returnsTrue_andDoesNotAuthenticate]' passed (0.103 seconds).
Test Case '-[KizbaTests.BiometricGateTests testRun_policyOn_available_cancelled_returnsFalse]' started.
Test Case '-[KizbaTests.BiometricGateTests testRun_policyOn_available_cancelled_returnsFalse]' passed (0.104 seconds).
Test Case '-[KizbaTests.BiometricGateTests testRun_policyOn_available_failed_returnsFalse]' started.
Test Case '-[KizbaTests.BiometricGateTests testRun_policyOn_available_failed_returnsFalse]' passed (0.104 seconds).
Test Case '-[KizbaTests.BiometricGateTests testRun_policyOn_available_success_returnsTrue]' started.
Test Case '-[KizbaTests.BiometricGateTests testRun_policyOn_available_success_returnsTrue]' passed (0.003 seconds).
Test Case '-[KizbaTests.BiometricGateTests testRun_policyOn_nilAuthenticator_returnsTrue]' started.
Test Case '-[KizbaTests.BiometricGateTests testRun_policyOn_nilAuthenticator_returnsTrue]' passed (0.104 seconds).
Test Case '-[KizbaTests.BiometricGateTests testRun_policyOn_unavailable_returnsTrue_andDoesNotAuthenticate]' started.
Test Case '-[KizbaTests.BiometricGateTests testRun_policyOn_unavailable_returnsTrue_andDoesNotAuthenticate]' passed (0.002 seconds).
Test Suite 'BiometricGateTests' passed at 2026-05-24 08:25:08.125.
	 Executed 7 tests, with 0 failures (0 unexpected) in 0.420 (0.433) seconds
Test Suite 'BitwardenJSONExporterTests' started at 2026-05-24 08:25:08.125.
Test Case '-[KizbaTests.BitwardenJSONExporterTests testExport_multipleItemsInSameFolder_deduplicateFolder]' started.
Test Case '-[KizbaTests.BitwardenJSONExporterTests testExport_multipleItemsInSameFolder_deduplicateFolder]' passed (0.002 seconds).
Test Case '-[KizbaTests.BitwardenJSONExporterTests testExport_recordWithFolder_extractsFolderName]' started.
Test Case '-[KizbaTests.BitwardenJSONExporterTests testExport_recordWithFolder_extractsFolderName]' passed (0.002 seconds).
Test Case '-[KizbaTests.BitwardenJSONExporterTests testExport_recordWithTOTP_passesThrough]' started.
Test Case '-[KizbaTests.BitwardenJSONExporterTests testExport_recordWithTOTP_passesThrough]' passed (0.002 seconds).
Test Case '-[KizbaTests.BitwardenJSONExporterTests testExport_recordWithURL_isWrappedInURIsArray]' started.
Test Case '-[KizbaTests.BitwardenJSONExporterTests testExport_recordWithURL_isWrappedInURIsArray]' passed (0.003 seconds).
Test Case '-[KizbaTests.BitwardenJSONExporterTests testExport_singleTopLevelRecord]' started.
Test Case '-[KizbaTests.BitwardenJSONExporterTests testExport_singleTopLevelRecord]' passed (0.002 seconds).
Test Suite 'BitwardenJSONExporterTests' passed at 2026-05-24 08:25:08.147.
	 Executed 5 tests, with 0 failures (0 unexpected) in 0.012 (0.022) seconds
Test Suite 'BitwardenJSONImporterTests' started at 2026-05-24 08:25:08.148.
Test Case '-[KizbaTests.BitwardenJSONImporterTests testParse_conflictsDetected]' started.
Test Case '-[KizbaTests.BitwardenJSONImporterTests testParse_conflictsDetected]' passed (0.003 seconds).
Test Case '-[KizbaTests.BitwardenJSONImporterTests testParse_itemWithFolder_buildsPath]' started.
Test Case '-[KizbaTests.BitwardenJSONImporterTests testParse_itemWithFolder_buildsPath]' passed (0.002 seconds).
Test Case '-[KizbaTests.BitwardenJSONImporterTests testParse_itemWithoutPassword_isSkippedAsWarning]' started.
Test Case '-[KizbaTests.BitwardenJSONImporterTests testParse_itemWithoutPassword_isSkippedAsWarning]' passed (0.002 seconds).
Test Case '-[KizbaTests.BitwardenJSONImporterTests testParse_itemWithTOTP_passesThrough]' started.
Test Case '-[KizbaTests.BitwardenJSONImporterTests testParse_itemWithTOTP_passesThrough]' passed (0.002 seconds).
Test Case '-[KizbaTests.BitwardenJSONImporterTests testParse_minimalLoginItem]' started.
Test Case '-[KizbaTests.BitwardenJSONImporterTests testParse_minimalLoginItem]' passed (0.001 seconds).
Test Case '-[KizbaTests.BitwardenJSONImporterTests testParse_missingFoldersArray_doesNotThrow]' started.
Test Case '-[KizbaTests.BitwardenJSONImporterTests testParse_missingFoldersArray_doesNotThrow]' passed (0.001 seconds).
Test Case '-[KizbaTests.BitwardenJSONImporterTests testParse_nonLoginItems_areIgnored]' started.
Test Case '-[KizbaTests.BitwardenJSONImporterTests testParse_nonLoginItems_areIgnored]' passed (0.002 seconds).
Test Case '-[KizbaTests.BitwardenJSONImporterTests testParse_sanitisesColonAndBackslashInName]' started.
Test Case '-[KizbaTests.BitwardenJSONImporterTests testParse_sanitisesColonAndBackslashInName]' passed (0.002 seconds).
Test Suite 'BitwardenJSONImporterTests' passed at 2026-05-24 08:25:08.170.
	 Executed 8 tests, with 0 failures (0 unexpected) in 0.014 (0.022) seconds
Test Suite 'CSVRowTests' started at 2026-05-24 08:25:08.179.
Test Case '-[KizbaTests.CSVRowTests testParse_emptyFields]' started.
Test Case '-[KizbaTests.CSVRowTests testParse_emptyFields]' passed (0.001 seconds).
Test Case '-[KizbaTests.CSVRowTests testParse_plainFields]' started.
Test Case '-[KizbaTests.CSVRowTests testParse_plainFields]' passed (0.001 seconds).
Test Case '-[KizbaTests.CSVRowTests testParse_quotedFieldWithComma]' started.
Test Case '-[KizbaTests.CSVRowTests testParse_quotedFieldWithComma]' passed (0.002 seconds).
Test Case '-[KizbaTests.CSVRowTests testParse_quotedFieldWithEscapedQuote]' started.
Test Case '-[KizbaTests.CSVRowTests testParse_quotedFieldWithEscapedQuote]' passed (0.002 seconds).
Test Case '-[KizbaTests.CSVRowTests testParse_trailingEmptyField]' started.
Test Case '-[KizbaTests.CSVRowTests testParse_trailingEmptyField]' passed (0.001 seconds).
Test Case '-[KizbaTests.CSVRowTests testParseAll_crlfLineEndings]' started.
Test Case '-[KizbaTests.CSVRowTests testParseAll_crlfLineEndings]' passed (0.001 seconds).
Test Case '-[KizbaTests.CSVRowTests testParseAll_emptyInput_returnsEmpty]' started.
Test Case '-[KizbaTests.CSVRowTests testParseAll_emptyInput_returnsEmpty]' passed (0.002 seconds).
Test Case '-[KizbaTests.CSVRowTests testParseAll_handlesEscapedQuoteAcrossRows]' started.
Test Case '-[KizbaTests.CSVRowTests testParseAll_handlesEscapedQuoteAcrossRows]' passed (0.001 seconds).
Test Case '-[KizbaTests.CSVRowTests testParseAll_multilineQuotedValue]' started.
Test Case '-[KizbaTests.CSVRowTests testParseAll_multilineQuotedValue]' passed (0.001 seconds).
Test Case '-[KizbaTests.CSVRowTests testParseAll_noTrailingNewline]' started.
Test Case '-[KizbaTests.CSVRowTests testParseAll_noTrailingNewline]' passed (0.001 seconds).
Test Case '-[KizbaTests.CSVRowTests testParseAll_simpleTwoRows]' started.
Test Case '-[KizbaTests.CSVRowTests testParseAll_simpleTwoRows]' passed (0.001 seconds).
Test Case '-[KizbaTests.CSVRowTests testRoundTrip_preservesAllSpecialChars]' started.
Test Case '-[KizbaTests.CSVRowTests testRoundTrip_preservesAllSpecialChars]' passed (0.010 seconds).
Test Case '-[KizbaTests.CSVRowTests testSerialize_fieldWithComma_isQuoted]' started.
Test Case '-[KizbaTests.CSVRowTests testSerialize_fieldWithComma_isQuoted]' passed (0.001 seconds).
Test Case '-[KizbaTests.CSVRowTests testSerialize_fieldWithNewline_isQuoted]' started.
Test Case '-[KizbaTests.CSVRowTests testSerialize_fieldWithNewline_isQuoted]' passed (0.001 seconds).
Test Case '-[KizbaTests.CSVRowTests testSerialize_fieldWithQuote_isEscapedAndQuoted]' started.
Test Case '-[KizbaTests.CSVRowTests testSerialize_fieldWithQuote_isEscapedAndQuoted]' passed (0.001 seconds).
Test Case '-[KizbaTests.CSVRowTests testSerialize_plain]' started.
Test Case '-[KizbaTests.CSVRowTests testSerialize_plain]' passed (0.001 seconds).
Test Suite 'CSVRowTests' passed at 2026-05-24 08:25:08.219.
	 Executed 16 tests, with 0 failures (0 unexpected) in 0.025 (0.040) seconds
Test Suite 'ClipboardServiceTests' started at 2026-05-24 08:25:08.237.
Test Case '-[KizbaTests.ClipboardServiceTests testAutoClear_whenUnchanged]' started.
2026-05-24 08:25:08.240959+0200 Kizba[11882:1070614] [clipboard] clipboard copy occurred (auto-clear scheduled)
2026-05-24 08:25:08.322959+0200 Kizba[11882:1070616] [clipboard] clipboard auto-clear performed
Test Case '-[KizbaTests.ClipboardServiceTests testAutoClear_whenUnchanged]' passed (0.323 seconds).
Test Case '-[KizbaTests.ClipboardServiceTests testCancellation_ofClearTask_onNewCopy]' started.
2026-05-24 08:25:08.562877+0200 Kizba[11882:1070611] [clipboard] clipboard copy occurred (auto-clear scheduled)
2026-05-24 08:25:08.595429+0200 Kizba[11882:1070611] [clipboard] clipboard copy occurred (auto-clear scheduled)
Test Case '-[KizbaTests.ClipboardServiceTests testCancellation_ofClearTask_onNewCopy]' passed (0.338 seconds).
Test Case '-[KizbaTests.ClipboardServiceTests testCopyWritesVerbatim]' started.
2026-05-24 08:25:08.903660+0200 Kizba[11882:1070618] [clipboard] clipboard copy occurred (auto-clear scheduled)
Test Case '-[KizbaTests.ClipboardServiceTests testCopyWritesVerbatim]' passed (0.004 seconds).
Test Case '-[KizbaTests.ClipboardServiceTests testMultipleCopies_onlyLatestClears]' started.
2026-05-24 08:25:08.908227+0200 Kizba[11882:1070610] [clipboard] clipboard copy occurred (auto-clear scheduled)
2026-05-24 08:25:08.941180+0200 Kizba[11882:1070618] [clipboard] clipboard copy occurred (auto-clear scheduled)
2026-05-24 08:25:09.024367+0200 Kizba[11882:1070618] [clipboard] clipboard auto-clear performed
Test Case '-[KizbaTests.ClipboardServiceTests testMultipleCopies_onlyLatestClears]' passed (0.461 seconds).
Test Case '-[KizbaTests.ClipboardServiceTests testNoClear_whenChangeCountDiffers]' started.
2026-05-24 08:25:09.369121+0200 Kizba[11882:1070618] [clipboard] clipboard copy occurred (auto-clear scheduled)
2026-05-24 08:25:09.452818+0200 Kizba[11882:1070618] [clipboard] clipboard auto-clear skipped: changeCount diverged
Test Case '-[KizbaTests.ClipboardServiceTests testNoClear_whenChangeCountDiffers]' passed (0.321 seconds).
Test Suite 'ClipboardServiceTests' passed at 2026-05-24 08:25:09.689.
	 Executed 5 tests, with 0 failures (0 unexpected) in 1.447 (1.452) seconds
Test Suite 'ClipboardServicingTests' started at 2026-05-24 08:25:09.689.
Test Case '-[KizbaTests.ClipboardServicingTests testCopyRecordsValueVerbatim]' started.
Test Case '-[KizbaTests.ClipboardServicingTests testCopyRecordsValueVerbatim]' passed (0.002 seconds).
Test Case '-[KizbaTests.ClipboardServicingTests testRepeatedCopiesAreOrdered]' started.
Test Case '-[KizbaTests.ClipboardServicingTests testRepeatedCopiesAreOrdered]' passed (0.002 seconds).
Test Suite 'ClipboardServicingTests' passed at 2026-05-24 08:25:09.695.
	 Executed 2 tests, with 0 failures (0 unexpected) in 0.005 (0.006) seconds
Test Suite 'CodeReviewChecklistExistsTests' started at 2026-05-24 08:25:09.696.
Test Case '-[KizbaTests.CodeReviewChecklistExistsTests testCodeReviewChecklistExists]' started.
Test Case '-[KizbaTests.CodeReviewChecklistExistsTests testCodeReviewChecklistExists]' passed (0.002 seconds).
Test Suite 'CodeReviewChecklistExistsTests' passed at 2026-05-24 08:25:09.698.
	 Executed 1 test, with 0 failures (0 unexpected) in 0.002 (0.003) seconds
Test Suite 'CodeReviewChecklistTests' started at 2026-05-24 08:25:09.699.
Test Case '-[KizbaTests.CodeReviewChecklistTests testChecklistExists]' started.
Test Case '-[KizbaTests.CodeReviewChecklistTests testChecklistExists]' passed (0.001 seconds).
Test Suite 'CodeReviewChecklistTests' passed at 2026-05-24 08:25:09.701.
	 Executed 1 test, with 0 failures (0 unexpected) in 0.001 (0.002) seconds
Test Suite 'ConcurrentWriteLockoutTests' started at 2026-05-24 08:25:09.701.
Test Case '-[KizbaTests.ConcurrentWriteLockoutTests testAppState_initialState_anyWriteInFlightIsFalse_andSetIsEmpty]' started.
Test Case '-[KizbaTests.ConcurrentWriteLockoutTests testAppState_initialState_anyWriteInFlightIsFalse_andSetIsEmpty]' passed (0.002 seconds).
Test Case '-[KizbaTests.ConcurrentWriteLockoutTests testBeginWrite_isIdempotent_setHoldsOneElement]' started.
Test Case '-[KizbaTests.ConcurrentWriteLockoutTests testBeginWrite_isIdempotent_setHoldsOneElement]' passed (0.002 seconds).
Test Case '-[KizbaTests.ConcurrentWriteLockoutTests testDeleteEntry_marksDeleteInFlight_thenReleasesOnSuccess]' started.
Test Case '-[KizbaTests.ConcurrentWriteLockoutTests testDeleteEntry_marksDeleteInFlight_thenReleasesOnSuccess]' passed (0.240 seconds).
Test Case '-[KizbaTests.ConcurrentWriteLockoutTests testEndWrite_isIdempotent_setRemainsEmpty]' started.
Test Case '-[KizbaTests.ConcurrentWriteLockoutTests testEndWrite_isIdempotent_setRemainsEmpty]' passed (0.002 seconds).
Test Case '-[KizbaTests.ConcurrentWriteLockoutTests testEntryFormCreate_cancel_releasesLockoutSynchronously]' started.
Test Case '-[KizbaTests.ConcurrentWriteLockoutTests testEntryFormCreate_cancel_releasesLockoutSynchronously]' passed (0.544 seconds).
Test Case '-[KizbaTests.ConcurrentWriteLockoutTests testEntryFormCreate_canSave_unaffectedByExternalOpInFlight]' started.
Test Case '-[KizbaTests.ConcurrentWriteLockoutTests testEntryFormCreate_canSave_unaffectedByExternalOpInFlight]' passed (0.003 seconds).
Test Case '-[KizbaTests.ConcurrentWriteLockoutTests testEntryFormCreate_handleDismissal_releasesLockoutSynchronously]' started.
Test Case '-[KizbaTests.ConcurrentWriteLockoutTests testEntryFormCreate_handleDismissal_releasesLockoutSynchronously]' passed (0.035 seconds).
Test Case '-[KizbaTests.ConcurrentWriteLockoutTests testEntryFormCreate_save_marksInsertNewInFlight_thenReleasesOnSuccess]' started.
Test Case '-[KizbaTests.ConcurrentWriteLockoutTests testEntryFormCreate_save_marksInsertNewInFlight_thenReleasesOnSuccess]' passed (0.133 seconds).
Test Case '-[KizbaTests.ConcurrentWriteLockoutTests testEntryFormCreate_save_releasesOpOnFailure]' started.
Test Case '-[KizbaTests.ConcurrentWriteLockoutTests testEntryFormCreate_save_releasesOpOnFailure]' passed (0.094 seconds).
Test Case '-[KizbaTests.ConcurrentWriteLockoutTests testEntryFormEdit_save_marksEditInFlight]' started.
Test Case '-[KizbaTests.ConcurrentWriteLockoutTests testEntryFormEdit_save_marksEditInFlight]' passed (0.149 seconds).
Test Case '-[KizbaTests.ConcurrentWriteLockoutTests testGitPull_beginEnd_trackedCorrectly]' started.
Test Case '-[KizbaTests.ConcurrentWriteLockoutTests testGitPull_beginEnd_trackedCorrectly]' passed (0.002 seconds).
Test Case '-[KizbaTests.ConcurrentWriteLockoutTests testGitPull_blocksOtherWriteOps]' started.
Test Case '-[KizbaTests.ConcurrentWriteLockoutTests testGitPull_blocksOtherWriteOps]' passed (0.002 seconds).
Test Case '-[KizbaTests.ConcurrentWriteLockoutTests testGitPush_beginEnd_trackedCorrectly]' started.
Test Case '-[KizbaTests.ConcurrentWriteLockoutTests testGitPush_beginEnd_trackedCorrectly]' passed (0.003 seconds).
Test Case '-[KizbaTests.ConcurrentWriteLockoutTests testMoveEntry_cancel_releasesLockoutSynchronously]' started.
Test Case '-[KizbaTests.ConcurrentWriteLockoutTests testMoveEntry_cancel_releasesLockoutSynchronously]' passed (0.438 seconds).
Test Case '-[KizbaTests.ConcurrentWriteLockoutTests testMoveEntry_save_marksMoveInFlight_thenReleasesOnSuccess]' started.
Test Case '-[KizbaTests.ConcurrentWriteLockoutTests testMoveEntry_save_marksMoveInFlight_thenReleasesOnSuccess]' passed (0.135 seconds).
Test Case '-[KizbaTests.ConcurrentWriteLockoutTests testMultipleConcurrentOps_areTrackedIndependently]' started.
Test Case '-[KizbaTests.ConcurrentWriteLockoutTests testMultipleConcurrentOps_areTrackedIndependently]' passed (0.002 seconds).
Test Case '-[KizbaTests.ConcurrentWriteLockoutTests testRegenerateInPlace_marksRegenerateInFlight_thenReleasesOnSuccess]' started.
Test Case '-[KizbaTests.ConcurrentWriteLockoutTests testRegenerateInPlace_marksRegenerateInFlight_thenReleasesOnSuccess]' passed (0.128 seconds).
Test Case '-[KizbaTests.ConcurrentWriteLockoutTests testRegenerateInPlace_releasesOpOnShowFailure]' started.
Test Case '-[KizbaTests.ConcurrentWriteLockoutTests testRegenerateInPlace_releasesOpOnShowFailure]' passed (0.002 seconds).
Test Suite 'ConcurrentWriteLockoutTests' passed at 2026-05-24 08:25:11.645.
	 Executed 18 tests, with 0 failures (0 unexpected) in 1.916 (1.944) seconds
Test Suite 'DestructiveConfirmationTests' started at 2026-05-24 08:25:11.645.
Test Case '-[KizbaTests.DestructiveConfirmationTests testDestructiveConfirmation_acceptsCustomConfirmLabel]' started.
Test Case '-[KizbaTests.DestructiveConfirmationTests testDestructiveConfirmation_acceptsCustomConfirmLabel]' passed (0.002 seconds).
Test Case '-[KizbaTests.DestructiveConfirmationTests testDestructiveConfirmation_isCallableWithDocumentedSignature]' started.
Test Case '-[KizbaTests.DestructiveConfirmationTests testDestructiveConfirmation_isCallableWithDocumentedSignature]' passed (0.002 seconds).
Test Case '-[KizbaTests.DestructiveConfirmationTests testDestructiveConfirmation_isCallableWithoutMessage]' started.
Test Case '-[KizbaTests.DestructiveConfirmationTests testDestructiveConfirmation_isCallableWithoutMessage]' passed (0.002 seconds).
Test Case '-[KizbaTests.DestructiveConfirmationTests testOverwriteConfirmation_acceptsCustomConfirmLabel]' started.
Test Case '-[KizbaTests.DestructiveConfirmationTests testOverwriteConfirmation_acceptsCustomConfirmLabel]' passed (0.002 seconds).
Test Case '-[KizbaTests.DestructiveConfirmationTests testOverwriteConfirmation_isCallableWithDocumentedSignature]' started.
Test Case '-[KizbaTests.DestructiveConfirmationTests testOverwriteConfirmation_isCallableWithDocumentedSignature]' passed (0.001 seconds).
Test Suite 'DestructiveConfirmationTests' passed at 2026-05-24 08:25:11.659.
	 Executed 5 tests, with 0 failures (0 unexpected) in 0.010 (0.014) seconds
Test Suite 'DiagnosticsModelTests' started at 2026-05-24 08:25:11.660.
Test Case '-[KizbaTests.DiagnosticsModelTests testClearEmptiesModelAndLog]' started.
Test Case '-[KizbaTests.DiagnosticsModelTests testClearEmptiesModelAndLog]' passed (0.002 seconds).
Test Case '-[KizbaTests.DiagnosticsModelTests testRefreshLoadsRecent]' started.
Test Case '-[KizbaTests.DiagnosticsModelTests testRefreshLoadsRecent]' passed (0.001 seconds).
Test Suite 'DiagnosticsModelTests' passed at 2026-05-24 08:25:11.664.
	 Executed 2 tests, with 0 failures (0 unexpected) in 0.003 (0.004) seconds
Test Suite 'DomainConcurrencyTests' started at 2026-05-24 08:25:11.665.
Test Case '-[KizbaTests.DomainConcurrencyTests testConcurrentAddsAreNotLost]' started.
Test Case '-[KizbaTests.DomainConcurrencyTests testConcurrentAddsAreNotLost]' passed (0.003 seconds).
Test Case '-[KizbaTests.DomainConcurrencyTests testConcurrentShowReturnsExactSecretPerEntry]' started.
Test Case '-[KizbaTests.DomainConcurrencyTests testConcurrentShowReturnsExactSecretPerEntry]' passed (0.002 seconds).
Test Case '-[KizbaTests.DomainConcurrencyTests testConcurrentShowSurfacesDecryptionFailure]' started.
Test Case '-[KizbaTests.DomainConcurrencyTests testConcurrentShowSurfacesDecryptionFailure]' passed (0.008 seconds).
Test Suite 'DomainConcurrencyTests' passed at 2026-05-24 08:25:11.679.
	 Executed 3 tests, with 0 failures (0 unexpected) in 0.013 (0.014) seconds
Test Suite 'EmptyStateViewTests' started at 2026-05-24 08:25:11.679.
Test Case '-[KizbaTests.EmptyStateViewTests testEmptyStateView_initWithActions_isCallable]' started.
Test Case '-[KizbaTests.EmptyStateViewTests testEmptyStateView_initWithActions_isCallable]' passed (0.001 seconds).
Test Case '-[KizbaTests.EmptyStateViewTests testEmptyStateView_initWithActions_messageIsOptional]' started.
Test Case '-[KizbaTests.EmptyStateViewTests testEmptyStateView_initWithActions_messageIsOptional]' passed (0.001 seconds).
Test Case '-[KizbaTests.EmptyStateViewTests testEmptyStateView_initWithoutActions_acceptsOptionalMessage]' started.
Test Case '-[KizbaTests.EmptyStateViewTests testEmptyStateView_initWithoutActions_acceptsOptionalMessage]' passed (0.001 seconds).
Test Case '-[KizbaTests.EmptyStateViewTests testEmptyStateView_initWithoutActions_isCallable]' started.
Test Case '-[KizbaTests.EmptyStateViewTests testEmptyStateView_initWithoutActions_isCallable]' passed (0.002 seconds).
Test Suite 'EmptyStateViewTests' passed at 2026-05-24 08:25:11.694.
	 Executed 4 tests, with 0 failures (0 unexpected) in 0.004 (0.015) seconds
Test Suite 'EntryDetailModelBiometricRevealTests' started at 2026-05-24 08:25:11.695.
Test Case '-[KizbaTests.EntryDetailModelBiometricRevealTests testRequestReveal_settingDisabled_revealsWithoutAuth]' started.
Test Case '-[KizbaTests.EntryDetailModelBiometricRevealTests testRequestReveal_settingDisabled_revealsWithoutAuth]' passed (0.005 seconds).
Test Case '-[KizbaTests.EntryDetailModelBiometricRevealTests testRequestReveal_settingEnabled_authCancelled_noReveal]' started.
Test Case '-[KizbaTests.EntryDetailModelBiometricRevealTests testRequestReveal_settingEnabled_authCancelled_noReveal]' passed (0.005 seconds).
Test Case '-[KizbaTests.EntryDetailModelBiometricRevealTests testRequestReveal_settingEnabled_authSuccess_reveals]' started.
Test Case '-[KizbaTests.EntryDetailModelBiometricRevealTests testRequestReveal_settingEnabled_authSuccess_reveals]' passed (0.004 seconds).
Test Case '-[KizbaTests.EntryDetailModelBiometricRevealTests testRequestReveal_settingEnabled_authUnavailable_fallsBackToReveal]' started.
Test Case '-[KizbaTests.EntryDetailModelBiometricRevealTests testRequestReveal_settingEnabled_authUnavailable_fallsBackToReveal]' passed (0.004 seconds).
Test Suite 'EntryDetailModelBiometricRevealTests' passed at 2026-05-24 08:25:11.714.
	 Executed 4 tests, with 0 failures (0 unexpected) in 0.018 (0.019) seconds
Test Suite 'EntryDetailModelCopyTests' started at 2026-05-24 08:25:11.714.
Test Case '-[KizbaTests.EntryDetailModelCopyTests test_requestCopyMetadata_nonSensitiveKey_policyOn_writesWithoutPrompt]' started.
Test Case '-[KizbaTests.EntryDetailModelCopyTests test_requestCopyMetadata_nonSensitiveKey_policyOn_writesWithoutPrompt]' passed (0.016 seconds).
Test Case '-[KizbaTests.EntryDetailModelCopyTests test_requestCopyMetadata_sensitiveKey_policyOn_cancelled_doesNotWrite]' started.
Test Case '-[KizbaTests.EntryDetailModelCopyTests test_requestCopyMetadata_sensitiveKey_policyOn_cancelled_doesNotWrite]' passed (0.013 seconds).
Test Case '-[KizbaTests.EntryDetailModelCopyTests test_requestCopyPassword_policyOn_cancelled_doesNotWriteToClipboard]' started.
Test Case '-[KizbaTests.EntryDetailModelCopyTests test_requestCopyPassword_policyOn_cancelled_doesNotWriteToClipboard]' passed (0.012 seconds).
Test Case '-[KizbaTests.EntryDetailModelCopyTests test_requestCopyPassword_policyOn_success_writesToClipboard]' started.
Test Case '-[KizbaTests.EntryDetailModelCopyTests test_requestCopyPassword_policyOn_success_writesToClipboard]' passed (0.012 seconds).
Test Case '-[KizbaTests.EntryDetailModelCopyTests testCopy_clampsOutOfRangeSettingsValue]' started.
Test Case '-[KizbaTests.EntryDetailModelCopyTests testCopy_clampsOutOfRangeSettingsValue]' passed (0.005 seconds).
Test Case '-[KizbaTests.EntryDetailModelCopyTests testCopy_readsClipboardDelayFromSettingsLive]' started.
Test Case '-[KizbaTests.EntryDetailModelCopyTests testCopy_readsClipboardDelayFromSettingsLive]' passed (0.003 seconds).
Test Case '-[KizbaTests.EntryDetailModelCopyTests testCopyMetadata_postsInfoToastWithKeyLabel]' started.
Test Case '-[KizbaTests.EntryDetailModelCopyTests testCopyMetadata_postsInfoToastWithKeyLabel]' passed (0.014 seconds).
Test Case '-[KizbaTests.EntryDetailModelCopyTests testCopyNotes_postsInfoToastWithLabel]' started.
Test Case '-[KizbaTests.EntryDetailModelCopyTests testCopyNotes_postsInfoToastWithLabel]' passed (0.013 seconds).
Test Case '-[KizbaTests.EntryDetailModelCopyTests testCopyPassword_postsInfoToastWithLabelAndDelay]' started.
Test Case '-[KizbaTests.EntryDetailModelCopyTests testCopyPassword_postsInfoToastWithLabelAndDelay]' passed (0.013 seconds).
Test Case '-[KizbaTests.EntryDetailModelCopyTests testModelCopy_invokesClipboardWithVerbatimValueAndDefaultDelay]' started.
Test Case '-[KizbaTests.EntryDetailModelCopyTests testModelCopy_invokesClipboardWithVerbatimValueAndDefaultDelay]' passed (0.005 seconds).
Test Case '-[KizbaTests.EntryDetailModelCopyTests testModelCopyPassword_forwardsLoadedPasswordVerbatim]' started.
Test Case '-[KizbaTests.EntryDetailModelCopyTests testModelCopyPassword_forwardsLoadedPasswordVerbatim]' passed (0.012 seconds).
Test Suite 'EntryDetailModelCopyTests' passed at 2026-05-24 08:25:11.834.
	 Executed 11 tests, with 0 failures (0 unexpected) in 0.117 (0.120) seconds
Test Suite 'EntryDetailModelRefinementTests' started at 2026-05-24 08:25:11.834.
Test Case '-[KizbaTests.EntryDetailModelRefinementTests testCopy_invokesClipboardWithDuration]' started.
Test Case '-[KizbaTests.EntryDetailModelRefinementTests testCopy_invokesClipboardWithDuration]' passed (0.013 seconds).
Test Case '-[KizbaTests.EntryDetailModelRefinementTests testErrorMapping_pinentryNotConfigured]' started.
Test Case '-[KizbaTests.EntryDetailModelRefinementTests testErrorMapping_pinentryNotConfigured]' passed (0.012 seconds).
Test Case '-[KizbaTests.EntryDetailModelRefinementTests testErrorMapping_setsFailedState]' started.
Test Case '-[KizbaTests.EntryDetailModelRefinementTests testErrorMapping_setsFailedState]' passed (0.012 seconds).
Test Case '-[KizbaTests.EntryDetailModelRefinementTests testReveal_doesNotPersistSecret]' started.
Test Case '-[KizbaTests.EntryDetailModelRefinementTests testReveal_doesNotPersistSecret]' passed (0.012 seconds).
Test Case '-[KizbaTests.EntryDetailModelRefinementTests testSelectionCancellation_races]' started.
Test Case '-[KizbaTests.EntryDetailModelRefinementTests testSelectionCancellation_races]' passed (0.630 seconds).
Test Suite 'EntryDetailModelRefinementTests' passed at 2026-05-24 08:25:12.515.
	 Executed 5 tests, with 0 failures (0 unexpected) in 0.680 (0.681) seconds
Test Suite 'EntryDetailModelTests' started at 2026-05-24 08:25:12.516.
Test Case '-[KizbaTests.EntryDetailModelTests testCopy_callsClipboardWithVerbatimValueAndSettingsDelay]' started.
Test Case '-[KizbaTests.EntryDetailModelTests testCopy_callsClipboardWithVerbatimValueAndSettingsDelay]' passed (0.014 seconds).
Test Case '-[KizbaTests.EntryDetailModelTests testLoadSelection_succeeds]' started.
Test Case '-[KizbaTests.EntryDetailModelTests testLoadSelection_succeeds]' passed (0.019 seconds).
Test Case '-[KizbaTests.EntryDetailModelTests testSelectionCancellation_dropsStaleResult]' started.
Test Case '-[KizbaTests.EntryDetailModelTests testSelectionCancellation_dropsStaleResult]' passed (0.217 seconds).
Test Case '-[KizbaTests.EntryDetailModelTests testSelectionCleared_returnsToIdle]' started.
Test Case '-[KizbaTests.EntryDetailModelTests testSelectionCleared_returnsToIdle]' passed (0.269 seconds).
Test Suite 'EntryDetailModelTests' passed at 2026-05-24 08:25:13.036.
	 Executed 4 tests, with 0 failures (0 unexpected) in 0.518 (0.521) seconds
Test Suite 'EntryDetailReconciliationTests' started at 2026-05-24 08:25:13.037.
Test Case '-[KizbaTests.EntryDetailReconciliationTests testBulk_isNoopForDetail]' started.
Test Case '-[KizbaTests.EntryDetailReconciliationTests testBulk_isNoopForDetail]' passed (0.144 seconds).
Test Case '-[KizbaTests.EntryDetailReconciliationTests testInserted_isNoopForDetail]' started.
Test Case '-[KizbaTests.EntryDetailReconciliationTests testInserted_isNoopForDetail]' passed (0.139 seconds).
Test Case '-[KizbaTests.EntryDetailReconciliationTests testMoved_currentPath_refetchesUnderNewPath]' started.
Test Case '-[KizbaTests.EntryDetailReconciliationTests testMoved_currentPath_refetchesUnderNewPath]' passed (0.038 seconds).
Test Case '-[KizbaTests.EntryDetailReconciliationTests testObserveChanges_calledTwice_doesNotDoubleSubscribe]' started.
Test Case '-[KizbaTests.EntryDetailReconciliationTests testObserveChanges_calledTwice_doesNotDoubleSubscribe]' passed (0.056 seconds).
Test Case '-[KizbaTests.EntryDetailReconciliationTests testRemoved_currentPath_clearsDetailState]' started.
Test Case '-[KizbaTests.EntryDetailReconciliationTests testRemoved_currentPath_clearsDetailState]' passed (0.049 seconds).
Test Case '-[KizbaTests.EntryDetailReconciliationTests testRemoved_otherPath_isNoop]' started.
Test Case '-[KizbaTests.EntryDetailReconciliationTests testRemoved_otherPath_isNoop]' passed (0.140 seconds).
Test Case '-[KizbaTests.EntryDetailReconciliationTests testStop_haltsSubscription_furtherEventsDoNotMutateDetail]' started.
Test Case '-[KizbaTests.EntryDetailReconciliationTests testStop_haltsSubscription_furtherEventsDoNotMutateDetail]' passed (0.196 seconds).
Test Case '-[KizbaTests.EntryDetailReconciliationTests testUpdated_currentPath_triggersRefetch]' started.
Test Case '-[KizbaTests.EntryDetailReconciliationTests testUpdated_currentPath_triggersRefetch]' passed (0.049 seconds).
Test Case '-[KizbaTests.EntryDetailReconciliationTests testUpdated_otherPath_doesNotRefetch]' started.
Test Case '-[KizbaTests.EntryDetailReconciliationTests testUpdated_otherPath_doesNotRefetch]' passed (0.138 seconds).
Test Suite 'EntryDetailReconciliationTests' passed at 2026-05-24 08:25:13.992.
	 Executed 9 tests, with 0 failures (0 unexpected) in 0.949 (0.955) seconds
Test Suite 'EntryFormBodyTests' started at 2026-05-24 08:25:13.993.
Test Case '-[KizbaTests.EntryFormBodyTests testDerivedIssuer_deepPath_takesSecondToLast]' started.
Test Case '-[KizbaTests.EntryFormBodyTests testDerivedIssuer_deepPath_takesSecondToLast]' passed (0.002 seconds).
Test Case '-[KizbaTests.EntryFormBodyTests testDerivedIssuer_singleComponent_returnsNil]' started.
Test Case '-[KizbaTests.EntryFormBodyTests testDerivedIssuer_singleComponent_returnsNil]' passed (0.002 seconds).
Test Case '-[KizbaTests.EntryFormBodyTests testDerivedIssuer_twoComponents_takesFirst]' started.
Test Case '-[KizbaTests.EntryFormBodyTests testDerivedIssuer_twoComponents_takesFirst]' passed (0.001 seconds).
Test Case '-[KizbaTests.EntryFormBodyTests testHeaderAndFooterSlotsAreRendered]' started.
Test Case '-[KizbaTests.EntryFormBodyTests testHeaderAndFooterSlotsAreRendered]' passed (0.002 seconds).
Test Case '-[KizbaTests.EntryFormBodyTests testPasswordRevealAccessibilityValueDefaultsToHidden]' started.
Test Case '-[KizbaTests.EntryFormBodyTests testPasswordRevealAccessibilityValueDefaultsToHidden]' passed (0.002 seconds).
Test Case '-[KizbaTests.EntryFormBodyTests testPasswordRevealAccessibilityValueWhenRevealed]' started.
Test Case '-[KizbaTests.EntryFormBodyTests testPasswordRevealAccessibilityValueWhenRevealed]' passed (0.002 seconds).
Test Case '-[KizbaTests.EntryFormBodyTests testPathFieldEnabledToggles]' started.
Test Case '-[KizbaTests.EntryFormBodyTests testPathFieldEnabledToggles]' passed (0.002 seconds).
Test Suite 'EntryFormBodyTests' passed at 2026-05-24 08:25:14.010.
	 Executed 7 tests, with 0 failures (0 unexpected) in 0.011 (0.017) seconds
Test Suite 'EntryFormModelCreateTests' started at 2026-05-24 08:25:14.011.
Test Case '-[KizbaTests.EntryFormModelCreateTests testCancel_midSave_returnsToEditing_andDropsLateCompletion]' started.
Test Case '-[KizbaTests.EntryFormModelCreateTests testCancel_midSave_returnsToEditing_andDropsLateCompletion]' passed (0.450 seconds).
Test Case '-[KizbaTests.EntryFormModelCreateTests testCanSave_emptyForm_isFalse]' started.
Test Case '-[KizbaTests.EntryFormModelCreateTests testCanSave_emptyForm_isFalse]' passed (0.002 seconds).
Test Case '-[KizbaTests.EntryFormModelCreateTests testCanSave_metadataWithDuplicateKeys_isFalse]' started.
Test Case '-[KizbaTests.EntryFormModelCreateTests testCanSave_metadataWithDuplicateKeys_isFalse]' passed (0.002 seconds).
Test Case '-[KizbaTests.EntryFormModelCreateTests testCanSave_pathAndPasswordSet_metadataEmpty_isTrue]' started.
Test Case '-[KizbaTests.EntryFormModelCreateTests testCanSave_pathAndPasswordSet_metadataEmpty_isTrue]' passed (0.001 seconds).
Test Case '-[KizbaTests.EntryFormModelCreateTests testCanSave_pathValid_passwordEmpty_isFalse]' started.
Test Case '-[KizbaTests.EntryFormModelCreateTests testCanSave_pathValid_passwordEmpty_isFalse]' passed (0.002 seconds).
Test Case '-[KizbaTests.EntryFormModelCreateTests testCanSave_pathWithGpgSuffix_isFalse]' started.
Test Case '-[KizbaTests.EntryFormModelCreateTests testCanSave_pathWithGpgSuffix_isFalse]' passed (0.002 seconds).
Test Case '-[KizbaTests.EntryFormModelCreateTests testGenerationCounter_secondSavePreemptsFirst]' started.
Test Case '-[KizbaTests.EntryFormModelCreateTests testGenerationCounter_secondSavePreemptsFirst]' passed (0.379 seconds).
Test Case '-[KizbaTests.EntryFormModelCreateTests testHandleDismissal_resetsFormAndCancelsSave]' started.
Test Case '-[KizbaTests.EntryFormModelCreateTests testHandleDismissal_resetsFormAndCancelsSave]' passed (0.450 seconds).
Test Case '-[KizbaTests.EntryFormModelCreateTests testInitialState_createMode_isEditingWithEmptyDraft]' started.
Test Case '-[KizbaTests.EntryFormModelCreateTests testInitialState_createMode_isEditingWithEmptyDraft]' passed (0.003 seconds).
Test Case '-[KizbaTests.EntryFormModelCreateTests testSave_collisionWithoutForce_failsInline_noToast]' started.
Test Case '-[KizbaTests.EntryFormModelCreateTests testSave_collisionWithoutForce_failsInline_noToast]' passed (0.014 seconds).
Test Case '-[KizbaTests.EntryFormModelCreateTests testSave_forceOverwrite_replacesExistingAndPostsToast]' started.
Test Case '-[KizbaTests.EntryFormModelCreateTests testSave_forceOverwrite_replacesExistingAndPostsToast]' passed (0.024 seconds).
Test Case '-[KizbaTests.EntryFormModelCreateTests testSave_newPath_succeeds_postsToast_andSelectsEntry]' started.
Test Case '-[KizbaTests.EntryFormModelCreateTests testSave_newPath_succeeds_postsToast_andSelectsEntry]' passed (0.115 seconds).
Test Case '-[KizbaTests.EntryFormModelCreateTests testSave_nonRecoverableError_setsFailed_postsErrorToast]' started.
Test Case '-[KizbaTests.EntryFormModelCreateTests testSave_nonRecoverableError_setsFailed_postsErrorToast]' passed (0.013 seconds).
Test Case '-[KizbaTests.EntryFormModelCreateTests testSave_withInvalidPath_doesNotInvokeManager_andStaysEditing]' started.
Test Case '-[KizbaTests.EntryFormModelCreateTests testSave_withInvalidPath_doesNotInvokeManager_andStaysEditing]' passed (0.056 seconds).
Test Suite 'EntryFormModelCreateTests' passed at 2026-05-24 08:25:15.535.
	 Executed 14 tests, with 0 failures (0 unexpected) in 1.514 (1.525) seconds
Test Suite 'EntryFormModelEditTests' started at 2026-05-24 08:25:15.536.
Test Case '-[KizbaTests.EntryFormModelEditTests testCancel_duringLoad_returnsToEditing_andDropsLateLoadCompletion]' started.
Test Case '-[KizbaTests.EntryFormModelEditTests testCancel_duringLoad_returnsToEditing_andDropsLateLoadCompletion]' passed (0.406 seconds).
Test Case '-[KizbaTests.EntryFormModelEditTests testCanEditPath_createMode_isTrue]' started.
Test Case '-[KizbaTests.EntryFormModelEditTests testCanEditPath_createMode_isTrue]' passed (0.002 seconds).
Test Case '-[KizbaTests.EntryFormModelEditTests testCanEditPath_editMode_isFalse]' started.
Test Case '-[KizbaTests.EntryFormModelEditTests testCanEditPath_editMode_isFalse]' passed (0.002 seconds).
Test Case '-[KizbaTests.EntryFormModelEditTests testCanSave_whileLoadingExisting_isFalse]' started.
Test Case '-[KizbaTests.EntryFormModelEditTests testCanSave_whileLoadingExisting_isFalse]' passed (0.158 seconds).
Test Case '-[KizbaTests.EntryFormModelEditTests testGenerationCounter_secondSavePreemptsFirst]' started.
Test Case '-[KizbaTests.EntryFormModelEditTests testGenerationCounter_secondSavePreemptsFirst]' passed (0.402 seconds).
Test Case '-[KizbaTests.EntryFormModelEditTests testInit_editMode_loadFailure_setsFailedAndPostsToast]' started.
Test Case '-[KizbaTests.EntryFormModelEditTests testInit_editMode_loadFailure_setsFailedAndPostsToast]' passed (0.012 seconds).
Test Case '-[KizbaTests.EntryFormModelEditTests testInit_editMode_loadsExistingDraftAndTransitionsToEditing]' started.
Test Case '-[KizbaTests.EntryFormModelEditTests testInit_editMode_loadsExistingDraftAndTransitionsToEditing]' passed (0.013 seconds).
Test Case '-[KizbaTests.EntryFormModelEditTests testSave_editMode_clearsForceOverwriteFlag]' started.
Test Case '-[KizbaTests.EntryFormModelEditTests testSave_editMode_clearsForceOverwriteFlag]' passed (0.024 seconds).
Test Case '-[KizbaTests.EntryFormModelEditTests testSave_editMode_doesNotMutateSelectedEntryID]' started.
Test Case '-[KizbaTests.EntryFormModelEditTests testSave_editMode_doesNotMutateSelectedEntryID]' passed (0.027 seconds).
Test Case '-[KizbaTests.EntryFormModelEditTests testSave_editMode_insertFailure_setsFailedAndPostsErrorToast]' started.
Test Case '-[KizbaTests.EntryFormModelEditTests testSave_editMode_insertFailure_setsFailedAndPostsErrorToast]' passed (0.025 seconds).
Test Case '-[KizbaTests.EntryFormModelEditTests testSave_editMode_usesInsertWithForceTrue_postsChangesSavedToast]' started.
Test Case '-[KizbaTests.EntryFormModelEditTests testSave_editMode_usesInsertWithForceTrue_postsChangesSavedToast]' passed (0.125 seconds).
Test Suite 'EntryFormModelEditTests' passed at 2026-05-24 08:25:16.740.
	 Executed 11 tests, with 0 failures (0 unexpected) in 1.196 (1.204) seconds
Test Suite 'EntryListDeleteTests' started at 2026-05-24 08:25:16.740.
Test Case '-[KizbaTests.EntryListDeleteTests testCanDelete_isTrue_whenSelectionPresentAndIdle]' started.
Test Case '-[KizbaTests.EntryListDeleteTests testCanDelete_isTrue_whenSelectionPresentAndIdle]' passed (0.002 seconds).
Test Case '-[KizbaTests.EntryListDeleteTests testDelete_thenUndo_restoresEntry_andClearsPending]' started.
Test Case '-[KizbaTests.EntryListDeleteTests testDelete_thenUndo_restoresEntry_andClearsPending]' passed (0.013 seconds).
Test Case '-[KizbaTests.EntryListDeleteTests testDeleteEntry_calledTwiceInQuickSuccession_runsOnlyOnce]' started.
Test Case '-[KizbaTests.EntryListDeleteTests testDeleteEntry_calledTwiceInQuickSuccession_runsOnlyOnce]' passed (0.097 seconds).
Test Case '-[KizbaTests.EntryListDeleteTests testDeleteEntry_happyPath_removesFromStore_clearsSelection_recordsUndo_postsToast_andReturnsIdle]' started.
Test Case '-[KizbaTests.EntryListDeleteTests testDeleteEntry_happyPath_removesFromStore_clearsSelection_recordsUndo_postsToast_andReturnsIdle]' passed (0.013 seconds).
Test Case '-[KizbaTests.EntryListDeleteTests testDeleteEntry_whenRemoveFails_abortsWithoutMutating_andPostsDangerToast]' started.
Test Case '-[KizbaTests.EntryListDeleteTests testDeleteEntry_whenRemoveFails_abortsWithoutMutating_andPostsDangerToast]' passed (0.011 seconds).
Test Case '-[KizbaTests.EntryListDeleteTests testDeleteEntry_whenSelectionDiffers_doesNotClearSelection]' started.
Test Case '-[KizbaTests.EntryListDeleteTests testDeleteEntry_whenSelectionDiffers_doesNotClearSelection]' passed (0.010 seconds).
Test Case '-[KizbaTests.EntryListDeleteTests testDeleteEntry_whenShowFails_abortsWithoutMutating_andPostsDangerToast]' started.
Test Case '-[KizbaTests.EntryListDeleteTests testDeleteEntry_whenShowFails_abortsWithoutMutating_andPostsDangerToast]' passed (0.005 seconds).
Test Case '-[KizbaTests.EntryListDeleteTests testDeletionState_isDeletingMidFlight_andIdleAfterCompletion]' started.
Test Case '-[KizbaTests.EntryListDeleteTests testDeletionState_isDeletingMidFlight_andIdleAfterCompletion]' passed (0.113 seconds).
Test Case '-[KizbaTests.EntryListDeleteTests testInitialState_isIdle_andCannotDeleteWithoutSelection]' started.
Test Case '-[KizbaTests.EntryListDeleteTests testInitialState_isIdle_andCannotDeleteWithoutSelection]' passed (0.002 seconds).
Test Case '-[KizbaTests.EntryListDeleteTests testUndo_afterExpiry_doesNotRestoreEntry]' started.
Test Case '-[KizbaTests.EntryListDeleteTests testUndo_afterExpiry_doesNotRestoreEntry]' passed (0.176 seconds).
Test Suite 'EntryListDeleteTests' passed at 2026-05-24 08:25:17.188.
	 Executed 10 tests, with 0 failures (0 unexpected) in 0.442 (0.448) seconds
Test Suite 'EntryListModelRefreshTests' started at 2026-05-24 08:25:17.188.
Test Case '-[KizbaTests.EntryListModelRefreshTests testRefresh_cancellable]' started.
Test Case '-[KizbaTests.EntryListModelRefreshTests testRefresh_cancellable]' passed (0.139 seconds).
Test Case '-[KizbaTests.EntryListModelRefreshTests testRefresh_invokesScannerAndUpdatesEntries]' started.
Test Case '-[KizbaTests.EntryListModelRefreshTests testRefresh_invokesScannerAndUpdatesEntries]' passed (0.012 seconds).
Test Suite 'EntryListModelRefreshTests' passed at 2026-05-24 08:25:17.342.
	 Executed 2 tests, with 0 failures (0 unexpected) in 0.152 (0.153) seconds
Test Suite 'EntryListModelTests' started at 2026-05-24 08:25:17.342.
Test Case '-[KizbaTests.EntryListModelTests test_entries_withoutQuery_respectsFolderSelection]' started.
Test Case '-[KizbaTests.EntryListModelTests test_entries_withoutQuery_respectsFolderSelection]' passed (0.002 seconds).
Test Case '-[KizbaTests.EntryListModelTests test_entries_withQuery_ignoresSelectedFolder_andReturnsGlobalMatches]' started.
Test Case '-[KizbaTests.EntryListModelTests test_entries_withQuery_ignoresSelectedFolder_andReturnsGlobalMatches]' passed (0.162 seconds).
Test Case '-[KizbaTests.EntryListModelTests testEntries_folderFilter_excludesGrandchildren]' started.
Test Case '-[KizbaTests.EntryListModelTests testEntries_folderFilter_excludesGrandchildren]' passed (0.002 seconds).
Test Case '-[KizbaTests.EntryListModelTests testEntries_folderFilter_limitsToSelectedFolder]' started.
Test Case '-[KizbaTests.EntryListModelTests testEntries_folderFilter_limitsToSelectedFolder]' passed (0.103 seconds).
Test Case '-[KizbaTests.EntryListModelTests testEntries_folderFilter_matchesEntryWithExactPath]' started.
Test Case '-[KizbaTests.EntryListModelTests testEntries_folderFilter_matchesEntryWithExactPath]' passed (0.001 seconds).
Test Case '-[KizbaTests.EntryListModelTests testEntries_folderFilter_nestedSelection_narrowsToImmediateChildren]' started.
Test Case '-[KizbaTests.EntryListModelTests testEntries_folderFilter_nestedSelection_narrowsToImmediateChildren]' passed (0.000 seconds).
Test Case '-[KizbaTests.EntryListModelTests testEntries_folderFilter_nestedSelectionExcludesDeeperNesting]' started.
Test Case '-[KizbaTests.EntryListModelTests testEntries_folderFilter_nestedSelectionExcludesDeeperNesting]' passed (0.000 seconds).
Test Case '-[KizbaTests.EntryListModelTests testEntries_folderFilter_topLevelExcludesNestedSubfolders]' started.
Test Case '-[KizbaTests.EntryListModelTests testEntries_folderFilter_topLevelExcludesNestedSubfolders]' passed (0.008 seconds).
Test Case '-[KizbaTests.EntryListModelTests testEntries_initialCount_unfiltered]' started.
Test Case '-[KizbaTests.EntryListModelTests testEntries_initialCount_unfiltered]' passed (0.002 seconds).
Test Case '-[KizbaTests.EntryListModelTests testEntries_searchFilter_isCaseInsensitiveSubstringOverPath]' started.
Test Case '-[KizbaTests.EntryListModelTests testEntries_searchFilter_isCaseInsensitiveSubstringOverPath]' passed (0.729 seconds).
Test Case '-[KizbaTests.EntryListModelTests testSelect_updatesAppStateSelectedEntryID]' started.
Test Case '-[KizbaTests.EntryListModelTests testSelect_updatesAppStateSelectedEntryID]' passed (0.003 seconds).
Test Suite 'EntryListModelTests' passed at 2026-05-24 08:25:18.360.
	 Executed 11 tests, with 0 failures (0 unexpected) in 1.012 (1.017) seconds
Test Suite 'EntryListNewEntryPathPrefillTests' started at 2026-05-24 08:25:18.360.
Test Case '-[KizbaTests.EntryListNewEntryPathPrefillTests test_makeNewEntryFormModel_withEmptyFolder_pathIsEmpty]' started.
Test Case '-[KizbaTests.EntryListNewEntryPathPrefillTests test_makeNewEntryFormModel_withEmptyFolder_pathIsEmpty]' passed (0.002 seconds).
Test Case '-[KizbaTests.EntryListNewEntryPathPrefillTests test_makeNewEntryFormModel_withNilFolder_pathIsEmpty]' started.
Test Case '-[KizbaTests.EntryListNewEntryPathPrefillTests test_makeNewEntryFormModel_withNilFolder_pathIsEmpty]' passed (0.002 seconds).
Test Case '-[KizbaTests.EntryListNewEntryPathPrefillTests test_makeNewEntryFormModel_withSelectedFolder_prefillsPath]' started.
Test Case '-[KizbaTests.EntryListNewEntryPathPrefillTests test_makeNewEntryFormModel_withSelectedFolder_prefillsPath]' passed (0.003 seconds).
Test Suite 'EntryListNewEntryPathPrefillTests' passed at 2026-05-24 08:25:18.369.
	 Executed 3 tests, with 0 failures (0 unexpected) in 0.007 (0.009) seconds
Test Suite 'EntryListReconciliationTests' started at 2026-05-24 08:25:18.369.
Test Case '-[KizbaTests.EntryListReconciliationTests testBulk_clearsNonSurvivingSelection]' started.
Test Case '-[KizbaTests.EntryListReconciliationTests testBulk_clearsNonSurvivingSelection]' passed (0.045 seconds).
Test Case '-[KizbaTests.EntryListReconciliationTests testBulk_preservesSurvivingSelection]' started.
Test Case '-[KizbaTests.EntryListReconciliationTests testBulk_preservesSurvivingSelection]' passed (0.085 seconds).
Test Case '-[KizbaTests.EntryListReconciliationTests testEndToEnd_formModelInsert_listAutoRefreshes_andSelectionFollows]' started.
Test Case '-[KizbaTests.EntryListReconciliationTests testEndToEnd_formModelInsert_listAutoRefreshes_andSelectionFollows]' passed (0.047 seconds).
Test Case '-[KizbaTests.EntryListReconciliationTests testInserted_doesNotMutateSelection_fromCentralisedHandler]' started.
Test Case '-[KizbaTests.EntryListReconciliationTests testInserted_doesNotMutateSelection_fromCentralisedHandler]' passed (0.044 seconds).
Test Case '-[KizbaTests.EntryListReconciliationTests testMoved_ofOtherEntry_leavesSelectionAlone]' started.
Test Case '-[KizbaTests.EntryListReconciliationTests testMoved_ofOtherEntry_leavesSelectionAlone]' passed (0.050 seconds).
Test Case '-[KizbaTests.EntryListReconciliationTests testMoved_ofSelectedEntry_selectionFollows]' started.
Test Case '-[KizbaTests.EntryListReconciliationTests testMoved_ofSelectedEntry_selectionFollows]' passed (0.045 seconds).
Test Case '-[KizbaTests.EntryListReconciliationTests testMoved_updatesFavoritePath]' started.
Test Case '-[KizbaTests.EntryListReconciliationTests testMoved_updatesFavoritePath]' passed (0.045 seconds).
Test Case '-[KizbaTests.EntryListReconciliationTests testObserveChanges_calledTwice_doesNotDoubleSubscribe]' started.
Test Case '-[KizbaTests.EntryListReconciliationTests testObserveChanges_calledTwice_doesNotDoubleSubscribe]' passed (0.057 seconds).
Test Case '-[KizbaTests.EntryListReconciliationTests testRemoved_cleansFavorite]' started.
Test Case '-[KizbaTests.EntryListReconciliationTests testRemoved_cleansFavorite]' passed (0.046 seconds).
Test Case '-[KizbaTests.EntryListReconciliationTests testRemoved_ofOtherEntry_leavesSelectionAlone]' started.
Test Case '-[KizbaTests.EntryListReconciliationTests testRemoved_ofOtherEntry_leavesSelectionAlone]' passed (0.047 seconds).
Test Case '-[KizbaTests.EntryListReconciliationTests testRemoved_ofSelectedEntry_clearsSelection]' started.
Test Case '-[KizbaTests.EntryListReconciliationTests testRemoved_ofSelectedEntry_clearsSelection]' passed (0.044 seconds).
Test Case '-[KizbaTests.EntryListReconciliationTests testStop_haltsSubscription_furtherEventsDoNotRefresh]' started.
Test Case '-[KizbaTests.EntryListReconciliationTests testStop_haltsSubscription_furtherEventsDoNotRefresh]' passed (0.201 seconds).
Test Case '-[KizbaTests.EntryListReconciliationTests testSubscription_handlesMultipleEvents_inOrder]' started.
Test Case '-[KizbaTests.EntryListReconciliationTests testSubscription_handlesMultipleEvents_inOrder]' passed (0.043 seconds).
Test Case '-[KizbaTests.EntryListReconciliationTests testSubscription_receivesInsertedEvent_andRefreshesEntries]' started.
Test Case '-[KizbaTests.EntryListReconciliationTests testSubscription_receivesInsertedEvent_andRefreshesEntries]' passed (0.041 seconds).
Test Case '-[KizbaTests.EntryListReconciliationTests testSubscription_receivesMovedEvent_andRefreshesEntries]' started.
Test Case '-[KizbaTests.EntryListReconciliationTests testSubscription_receivesMovedEvent_andRefreshesEntries]' passed (0.047 seconds).
Test Case '-[KizbaTests.EntryListReconciliationTests testSubscription_receivesRemovedEvent_andRefreshesEntries]' started.
Test Case '-[KizbaTests.EntryListReconciliationTests testSubscription_receivesRemovedEvent_andRefreshesEntries]' passed (0.046 seconds).
Test Suite 'EntryListReconciliationTests' passed at 2026-05-24 08:25:19.312.
	 Executed 16 tests, with 0 failures (0 unexpected) in 0.931 (0.943) seconds
Test Suite 'EntryPathConverterTests' started at 2026-05-24 08:25:19.313.
Test Case '-[KizbaTests.EntryPathConverterTests testDotsInBasenamePreserved]' started.
Test Case '-[KizbaTests.EntryPathConverterTests testDotsInBasenamePreserved]' passed (0.005 seconds).
Test Case '-[KizbaTests.EntryPathConverterTests testEmptyBasenameReturnsNil]' started.
Test Case '-[KizbaTests.EntryPathConverterTests testEmptyBasenameReturnsNil]' passed (0.001 seconds).
Test Case '-[KizbaTests.EntryPathConverterTests testNestedPath]' started.
Test Case '-[KizbaTests.EntryPathConverterTests testNestedPath]' passed (0.001 seconds).
Test Case '-[KizbaTests.EntryPathConverterTests testNonGpgReturnsNil]' started.
Test Case '-[KizbaTests.EntryPathConverterTests testNonGpgReturnsNil]' passed (0.001 seconds).
Test Case '-[KizbaTests.EntryPathConverterTests testOutsideRootReturnsNil]' started.
Test Case '-[KizbaTests.EntryPathConverterTests testOutsideRootReturnsNil]' passed (0.001 seconds).
Test Case '-[KizbaTests.EntryPathConverterTests testStoreRootItselfReturnsNil]' started.
Test Case '-[KizbaTests.EntryPathConverterTests testStoreRootItselfReturnsNil]' passed (0.001 seconds).
Test Case '-[KizbaTests.EntryPathConverterTests testTopLevel]' started.
Test Case '-[KizbaTests.EntryPathConverterTests testTopLevel]' passed (0.001 seconds).
Test Case '-[KizbaTests.EntryPathConverterTests testUnicodeAndSpacesPreserved]' started.
Test Case '-[KizbaTests.EntryPathConverterTests testUnicodeAndSpacesPreserved]' passed (0.001 seconds).
Test Suite 'EntryPathConverterTests' passed at 2026-05-24 08:25:19.327.
	 Executed 8 tests, with 0 failures (0 unexpected) in 0.011 (0.015) seconds
Test Suite 'EntryPathValidatorTests' started at 2026-05-24 08:25:19.335.
Test Case '-[KizbaTests.EntryPathValidatorTests testDeeplyNestedPathAccepted]' started.
Test Case '-[KizbaTests.EntryPathValidatorTests testDeeplyNestedPathAccepted]' passed (0.001 seconds).
Test Case '-[KizbaTests.EntryPathValidatorTests testDotComponentRejected]' started.
Test Case '-[KizbaTests.EntryPathValidatorTests testDotComponentRejected]' passed (0.001 seconds).
Test Case '-[KizbaTests.EntryPathValidatorTests testDotDotComponentRejected]' started.
Test Case '-[KizbaTests.EntryPathValidatorTests testDotDotComponentRejected]' passed (0.001 seconds).
Test Case '-[KizbaTests.EntryPathValidatorTests testEmptyMiddleComponentRejected]' started.
Test Case '-[KizbaTests.EntryPathValidatorTests testEmptyMiddleComponentRejected]' passed (0.001 seconds).
Test Case '-[KizbaTests.EntryPathValidatorTests testEmptyStringRejected]' started.
Test Case '-[KizbaTests.EntryPathValidatorTests testEmptyStringRejected]' passed (0.001 seconds).
Test Case '-[KizbaTests.EntryPathValidatorTests testGpgSuffixRejected]' started.
Test Case '-[KizbaTests.EntryPathValidatorTests testGpgSuffixRejected]' passed (0.002 seconds).
Test Case '-[KizbaTests.EntryPathValidatorTests testInternalWhitespaceInComponentAccepted]' started.
Test Case '-[KizbaTests.EntryPathValidatorTests testInternalWhitespaceInComponentAccepted]' passed (0.002 seconds).
Test Case '-[KizbaTests.EntryPathValidatorTests testInternalWhitespaceInNestedComponentAccepted]' started.
Test Case '-[KizbaTests.EntryPathValidatorTests testInternalWhitespaceInNestedComponentAccepted]' passed (0.001 seconds).
Test Case '-[KizbaTests.EntryPathValidatorTests testLeadingSlashRejected]' started.
Test Case '-[KizbaTests.EntryPathValidatorTests testLeadingSlashRejected]' passed (0.001 seconds).
Test Case '-[KizbaTests.EntryPathValidatorTests testLeadingWhitespaceRejected]' started.
Test Case '-[KizbaTests.EntryPathValidatorTests testLeadingWhitespaceRejected]' passed (0.001 seconds).
Test Case '-[KizbaTests.EntryPathValidatorTests testSimpleNestedPathAccepted]' started.
Test Case '-[KizbaTests.EntryPathValidatorTests testSimpleNestedPathAccepted]' passed (0.002 seconds).
Test Case '-[KizbaTests.EntryPathValidatorTests testSingleSlashRejected]' started.
Test Case '-[KizbaTests.EntryPathValidatorTests testSingleSlashRejected]' passed (0.003 seconds).
Test Case '-[KizbaTests.EntryPathValidatorTests testSuccessReturnsOriginalPathUnchanged]' started.
Test Case '-[KizbaTests.EntryPathValidatorTests testSuccessReturnsOriginalPathUnchanged]' passed (0.002 seconds).
Test Case '-[KizbaTests.EntryPathValidatorTests testTopLevelEntryAccepted]' started.
Test Case '-[KizbaTests.EntryPathValidatorTests testTopLevelEntryAccepted]' passed (0.001 seconds).
Test Case '-[KizbaTests.EntryPathValidatorTests testTrailingSlashRejected]' started.
Test Case '-[KizbaTests.EntryPathValidatorTests testTrailingSlashRejected]' passed (0.001 seconds).
Test Case '-[KizbaTests.EntryPathValidatorTests testTrailingWhitespaceRejected]' started.
Test Case '-[KizbaTests.EntryPathValidatorTests testTrailingWhitespaceRejected]' passed (0.001 seconds).
Test Case '-[KizbaTests.EntryPathValidatorTests testUnicodePathAccepted]' started.
Test Case '-[KizbaTests.EntryPathValidatorTests testUnicodePathAccepted]' passed (0.001 seconds).
Test Case '-[KizbaTests.EntryPathValidatorTests testWhitespaceOnlyMiddleComponentRejected]' started.
Test Case '-[KizbaTests.EntryPathValidatorTests testWhitespaceOnlyMiddleComponentRejected]' passed (0.001 seconds).
Test Case '-[KizbaTests.EntryPathValidatorTests testWhitespaceOnlyRejected]' started.
Test Case '-[KizbaTests.EntryPathValidatorTests testWhitespaceOnlyRejected]' passed (0.001 seconds).
Test Suite 'EntryPathValidatorTests' passed at 2026-05-24 08:25:19.417.
	 Executed 19 tests, with 0 failures (0 unexpected) in 0.024 (0.082) seconds
Test Suite 'EntryRowViewTests' started at 2026-05-24 08:25:19.417.
Test Case '-[KizbaTests.EntryRowViewTests testEntryRowView_backgroundColor_hoveredNotSelectedIsSurfaceHover]' started.
Test Case '-[KizbaTests.EntryRowViewTests testEntryRowView_backgroundColor_hoveredNotSelectedIsSurfaceHover]' passed (0.002 seconds).
Test Case '-[KizbaTests.EntryRowViewTests testEntryRowView_backgroundColor_idleIsClear]' started.
Test Case '-[KizbaTests.EntryRowViewTests testEntryRowView_backgroundColor_idleIsClear]' passed (0.002 seconds).
Test Case '-[KizbaTests.EntryRowViewTests testEntryRowView_backgroundColor_isUnaffectedByLeadingIcon]' started.
Test Case '-[KizbaTests.EntryRowViewTests testEntryRowView_backgroundColor_isUnaffectedByLeadingIcon]' passed (0.002 seconds).
Test Case '-[KizbaTests.EntryRowViewTests testEntryRowView_backgroundColor_selectedAndHoveredIsSurfaceSelected]' started.
Test Case '-[KizbaTests.EntryRowViewTests testEntryRowView_backgroundColor_selectedAndHoveredIsSurfaceSelected]' passed (0.001 seconds).
Test Case '-[KizbaTests.EntryRowViewTests testEntryRowView_backgroundColor_selectedNotHoveredIsSurfaceSelected]' started.
Test Case '-[KizbaTests.EntryRowViewTests testEntryRowView_backgroundColor_selectedNotHoveredIsSurfaceSelected]' passed (0.013 seconds).
Test Case '-[KizbaTests.EntryRowViewTests testEntryRowView_backgroundColor_selectionWinsOverHover]' started.
Test Case '-[KizbaTests.EntryRowViewTests testEntryRowView_backgroundColor_selectionWinsOverHover]' passed (0.001 seconds).
Test Case '-[KizbaTests.EntryRowViewTests testEntryRowView_backgroundColor_threeNonClearStatesAreDistinctPerTheme]' started.
Test Case '-[KizbaTests.EntryRowViewTests testEntryRowView_backgroundColor_threeNonClearStatesAreDistinctPerTheme]' passed (0.001 seconds).
Test Case '-[KizbaTests.EntryRowViewTests testEntryRowView_initWithLeadingIconName_compilesAndConstructs]' started.
Test Case '-[KizbaTests.EntryRowViewTests testEntryRowView_initWithLeadingIconName_compilesAndConstructs]' passed (0.001 seconds).
Test Suite 'EntryRowViewTests' passed at 2026-05-24 08:25:19.462.
	 Executed 8 tests, with 0 failures (0 unexpected) in 0.022 (0.044) seconds
Test Suite 'ErrorPresentationIntegrationTests' started at 2026-05-24 08:25:19.462.
Test Case '-[KizbaTests.ErrorPresentationIntegrationTests testDiagnosticsModel_recordsInvocationWithDecryptionFailure]' started.
Test Case '-[KizbaTests.ErrorPresentationIntegrationTests testDiagnosticsModel_recordsInvocationWithDecryptionFailure]' passed (0.103 seconds).
Test Case '-[KizbaTests.ErrorPresentationIntegrationTests testEntryDetailModel_decryptionFailed_setsFailed_and_ErrorPresentationInline]' started.
Test Case '-[KizbaTests.ErrorPresentationIntegrationTests testEntryDetailModel_decryptionFailed_setsFailed_and_ErrorPresentationInline]' passed (0.013 seconds).
Test Suite 'ErrorPresentationIntegrationTests' passed at 2026-05-24 08:25:19.590.
	 Executed 2 tests, with 0 failures (0 unexpected) in 0.116 (0.128) seconds
Test Suite 'ErrorPresentationTests' started at 2026-05-24 08:25:19.591.
Test Case '-[KizbaTests.ErrorPresentationTests testBinaryNotFoundPassMapsToEmptyStateWithPassKey]' started.
Test Case '-[KizbaTests.ErrorPresentationTests testBinaryNotFoundPassMapsToEmptyStateWithPassKey]' passed (0.002 seconds).
Test Case '-[KizbaTests.ErrorPresentationTests testDecryptionFailedMapsToInlineWithDiagnosticsContainingExcerpt]' started.
Test Case '-[KizbaTests.ErrorPresentationTests testDecryptionFailedMapsToInlineWithDiagnosticsContainingExcerpt]' passed (0.002 seconds).
Test Case '-[KizbaTests.ErrorPresentationTests testEntryAlreadyExistsMapsToSilent]' started.
Test Case '-[KizbaTests.ErrorPresentationTests testEntryAlreadyExistsMapsToSilent]' passed (0.002 seconds).
Test Case '-[KizbaTests.ErrorPresentationTests testGitAuthFailed_mapsToToastWithDiagnostics]' started.
Test Case '-[KizbaTests.ErrorPresentationTests testGitAuthFailed_mapsToToastWithDiagnostics]' passed (0.001 seconds).
Test Case '-[KizbaTests.ErrorPresentationTests testGitConflict_mapsToSilent]' started.
Test Case '-[KizbaTests.ErrorPresentationTests testGitConflict_mapsToSilent]' passed (0.001 seconds).
Test Case '-[KizbaTests.ErrorPresentationTests testGitNetworkUnavailable_mapsToToastWithDiagnostics]' started.
Test Case '-[KizbaTests.ErrorPresentationTests testGitNetworkUnavailable_mapsToToastWithDiagnostics]' passed (0.001 seconds).
Test Case '-[KizbaTests.ErrorPresentationTests testGitNoRemote_mapsToOnboarding]' started.
Test Case '-[KizbaTests.ErrorPresentationTests testGitNoRemote_mapsToOnboarding]' passed (0.001 seconds).
Test Case '-[KizbaTests.ErrorPresentationTests testGitNotInitialized_mapsToOnboarding]' started.
Test Case '-[KizbaTests.ErrorPresentationTests testGitNotInitialized_mapsToOnboarding]' passed (0.001 seconds).
Test Case '-[KizbaTests.ErrorPresentationTests testGitRejected_mapsToToastWithDiagnostics]' started.
Test Case '-[KizbaTests.ErrorPresentationTests testGitRejected_mapsToToastWithDiagnostics]' passed (0.001 seconds).
Test Case '-[KizbaTests.ErrorPresentationTests testInvalidGpgIdMapsToOnboarding]' started.
Test Case '-[KizbaTests.ErrorPresentationTests testInvalidGpgIdMapsToOnboarding]' passed (0.001 seconds).
Test Case '-[KizbaTests.ErrorPresentationTests testInvalidLengthMapsToSilent]' started.
Test Case '-[KizbaTests.ErrorPresentationTests testInvalidLengthMapsToSilent]' passed (0.001 seconds).
Test Case '-[KizbaTests.ErrorPresentationTests testPinentryNotConfiguredMapsToBannerWithHelpURL]' started.
Test Case '-[KizbaTests.ErrorPresentationTests testPinentryNotConfiguredMapsToBannerWithHelpURL]' passed (0.001 seconds).
Test Case '-[KizbaTests.ErrorPresentationTests testRecipientKeyNotTrusted_mapsToBannerWithFixInstructions]' started.
Test Case '-[KizbaTests.ErrorPresentationTests testRecipientKeyNotTrusted_mapsToBannerWithFixInstructions]' passed (0.001 seconds).
Test Case '-[KizbaTests.ErrorPresentationTests testRecipientKeyNotTrusted_nilHint_usesPlaceholder]' started.
Test Case '-[KizbaTests.ErrorPresentationTests testRecipientKeyNotTrusted_nilHint_usesPlaceholder]' passed (0.026 seconds).
Test Case '-[KizbaTests.ErrorPresentationTests testRecipientNotFoundMapsToBannerCarryingIdentifier]' started.
Test Case '-[KizbaTests.ErrorPresentationTests testRecipientNotFoundMapsToBannerCarryingIdentifier]' passed (0.002 seconds).
Test Case '-[KizbaTests.ErrorPresentationTests testSourceNotFoundMapsToToastWithDiagnostics]' started.
Test Case '-[KizbaTests.ErrorPresentationTests testSourceNotFoundMapsToToastWithDiagnostics]' passed (0.002 seconds).
Test Case '-[KizbaTests.ErrorPresentationTests testTimedOutMapsToToastWithDiagnostics]' started.
Test Case '-[KizbaTests.ErrorPresentationTests testTimedOutMapsToToastWithDiagnostics]' passed (0.002 seconds).
Test Case '-[KizbaTests.ErrorPresentationTests testWriteFailedWithoutReasonStillProducesToast]' started.
Test Case '-[KizbaTests.ErrorPresentationTests testWriteFailedWithoutReasonStillProducesToast]' passed (0.001 seconds).
Test Case '-[KizbaTests.ErrorPresentationTests testWriteFailedWithReasonMapsToToastWithDiagnosticsCarryingReason]' started.
Test Case '-[KizbaTests.ErrorPresentationTests testWriteFailedWithReasonMapsToToastWithDiagnosticsCarryingReason]' passed (0.001 seconds).
Test Suite 'ErrorPresentationTests' passed at 2026-05-24 08:25:19.658.
	 Executed 19 tests, with 0 failures (0 unexpected) in 0.046 (0.067) seconds
Test Suite 'FSEventsStoreWatcherTests' started at 2026-05-24 08:25:19.658.
Test Case '-[KizbaTests.FSEventsStoreWatcherTests testFSEventsEmitsOnRealFSChange]' started.
/Users/kirillsimagin/dev/my/worldproject/kizba/KizbaTests/FSEventsStoreWatcherTests.swift:8: -[KizbaTests.FSEventsStoreWatcherTests testFSEventsEmitsOnRealFSChange] : Test skipped - Opt-in
Test Case '-[KizbaTests.FSEventsStoreWatcherTests testFSEventsEmitsOnRealFSChange]' skipped (0.002 seconds).
Test Suite 'FSEventsStoreWatcherTests' passed at 2026-05-24 08:25:19.660.
	 Executed 1 test, with 1 test skipped and 0 failures (0 unexpected) in 0.002 (0.002) seconds
Test Suite 'FakePassGitManagerTests' started at 2026-05-24 08:25:19.669.
Test Case '-[KizbaTests.FakePassGitManagerTests testDefaultPushReturns_pushed]' started.
Test Case '-[KizbaTests.FakePassGitManagerTests testDefaultPushReturns_pushed]' passed (0.001 seconds).
Test Case '-[KizbaTests.FakePassGitManagerTests testPullConsumesScriptedResults]' started.
Test Case '-[KizbaTests.FakePassGitManagerTests testPullConsumesScriptedResults]' passed (0.103 seconds).
Test Case '-[KizbaTests.FakePassGitManagerTests testPushConsumesScriptedResults]' started.
Test Case '-[KizbaTests.FakePassGitManagerTests testPushConsumesScriptedResults]' passed (0.003 seconds).
Test Case '-[KizbaTests.FakePassGitManagerTests testStatusCallCount_incrementsOnEachCall]' started.
Test Case '-[KizbaTests.FakePassGitManagerTests testStatusCallCount_incrementsOnEachCall]' passed (0.002 seconds).
Test Case '-[KizbaTests.FakePassGitManagerTests testStatusReturnsConfiguredResult]' started.
Test Case '-[KizbaTests.FakePassGitManagerTests testStatusReturnsConfiguredResult]' passed (0.002 seconds).
Test Suite 'FakePassGitManagerTests' passed at 2026-05-24 08:25:19.783.
	 Executed 5 tests, with 0 failures (0 unexpected) in 0.112 (0.114) seconds
Test Suite 'FakeStoreWatcherTests' started at 2026-05-24 08:25:19.784.
Test Case '-[KizbaTests.FakeStoreWatcherTests testMultipleSubscribersReceiveEvents]' started.
Test Case '-[KizbaTests.FakeStoreWatcherTests testMultipleSubscribersReceiveEvents]' passed (0.004 seconds).
Test Case '-[KizbaTests.FakeStoreWatcherTests testSimulateChangeEmitsEvent]' started.
Test Case '-[KizbaTests.FakeStoreWatcherTests testSimulateChangeEmitsEvent]' passed (0.005 seconds).
Test Case '-[KizbaTests.FakeStoreWatcherTests testStartStopCounts]' started.
Test Case '-[KizbaTests.FakeStoreWatcherTests testStartStopCounts]' passed (0.104 seconds).
Test Suite 'FakeStoreWatcherTests' passed at 2026-05-24 08:25:19.898.
	 Executed 3 tests, with 0 failures (0 unexpected) in 0.112 (0.114) seconds
Test Suite 'FavoritesModelTests' started at 2026-05-24 08:25:19.898.
Test Case '-[KizbaTests.FavoritesModelTests testFavorites_areSorted]' started.
Test Case '-[KizbaTests.FavoritesModelTests testFavorites_areSorted]' passed (0.003 seconds).
Test Case '-[KizbaTests.FavoritesModelTests testIsFavorite_returnsCorrectValue]' started.
Test Case '-[KizbaTests.FavoritesModelTests testIsFavorite_returnsCorrectValue]' passed (0.104 seconds).
Test Case '-[KizbaTests.FavoritesModelTests testLoad_populatesFavoritesFromStore]' started.
Test Case '-[KizbaTests.FavoritesModelTests testLoad_populatesFavoritesFromStore]' passed (0.003 seconds).
Test Case '-[KizbaTests.FavoritesModelTests testObservesStoreChanges]' started.
Test Case '-[KizbaTests.FavoritesModelTests testObservesStoreChanges]' passed (0.108 seconds).
Test Case '-[KizbaTests.FavoritesModelTests testStop_cancelsObservation]' started.
Test Case '-[KizbaTests.FavoritesModelTests testStop_cancelsObservation]' passed (0.056 seconds).
Test Case '-[KizbaTests.FavoritesModelTests testToggle_addsFavorite]' started.
Test Case '-[KizbaTests.FavoritesModelTests testToggle_addsFavorite]' passed (0.004 seconds).
Test Case '-[KizbaTests.FavoritesModelTests testToggle_removesFavorite]' started.
Test Case '-[KizbaTests.FavoritesModelTests testToggle_removesFavorite]' passed (0.003 seconds).
Test Suite 'FavoritesModelTests' passed at 2026-05-24 08:25:20.183.
	 Executed 7 tests, with 0 failures (0 unexpected) in 0.280 (0.285) seconds
Test Suite 'FolderTreeBuilderTests' started at 2026-05-24 08:25:20.183.
Test Case '-[KizbaTests.FolderTreeBuilderTests testBuild_alphabeticalSort_isCaseInsensitive]' started.
Test Case '-[KizbaTests.FolderTreeBuilderTests testBuild_alphabeticalSort_isCaseInsensitive]' passed (0.001 seconds).
Test Case '-[KizbaTests.FolderTreeBuilderTests testBuild_deepNesting_materialisesEveryIntermediate]' started.
Test Case '-[KizbaTests.FolderTreeBuilderTests testBuild_deepNesting_materialisesEveryIntermediate]' passed (0.001 seconds).
Test Case '-[KizbaTests.FolderTreeBuilderTests testBuild_empty_returnsEmptyArray]' started.
Test Case '-[KizbaTests.FolderTreeBuilderTests testBuild_empty_returnsEmptyArray]' passed (0.002 seconds).
Test Case '-[KizbaTests.FolderTreeBuilderTests testBuild_emptyPathComponent_isSkipped]' started.
Test Case '-[KizbaTests.FolderTreeBuilderTests testBuild_emptyPathComponent_isSkipped]' passed (0.001 seconds).
Test Case '-[KizbaTests.FolderTreeBuilderTests testBuild_isDeterministic_acrossInputOrder]' started.
Test Case '-[KizbaTests.FolderTreeBuilderTests testBuild_isDeterministic_acrossInputOrder]' passed (0.001 seconds).
Test Case '-[KizbaTests.FolderTreeBuilderTests testBuild_mixedNesting_topLevelOrdering_andSubfolder]' started.
Test Case '-[KizbaTests.FolderTreeBuilderTests testBuild_mixedNesting_topLevelOrdering_andSubfolder]' passed (0.001 seconds).
Test Case '-[KizbaTests.FolderTreeBuilderTests testBuild_multipleSiblingEntries_singleFolderWithoutSubfolders]' started.
Test Case '-[KizbaTests.FolderTreeBuilderTests testBuild_multipleSiblingEntries_singleFolderWithoutSubfolders]' passed (0.001 seconds).
Test Case '-[KizbaTests.FolderTreeBuilderTests testBuild_singleNestedEntry_producesOneLeafFolder]' started.
Test Case '-[KizbaTests.FolderTreeBuilderTests testBuild_singleNestedEntry_producesOneLeafFolder]' passed (0.001 seconds).
Test Case '-[KizbaTests.FolderTreeBuilderTests testBuild_singleTopLevelEntry_producesNoFolder]' started.
Test Case '-[KizbaTests.FolderTreeBuilderTests testBuild_singleTopLevelEntry_producesNoFolder]' passed (0.002 seconds).
Test Suite 'FolderTreeBuilderTests' passed at 2026-05-24 08:25:20.218.
	 Executed 9 tests, with 0 failures (0 unexpected) in 0.011 (0.034) seconds
Test Suite 'FormFieldRowAccessibilityTests' started at 2026-05-24 08:25:20.218.
Test Case '-[KizbaTests.FormFieldRowAccessibilityTests testShouldUseVerticalLayout_returnsFalseForDefaultSize]' started.
Test Case '-[KizbaTests.FormFieldRowAccessibilityTests testShouldUseVerticalLayout_returnsFalseForDefaultSize]' passed (0.002 seconds).
Test Case '-[KizbaTests.FormFieldRowAccessibilityTests testShouldUseVerticalLayout_returnsTrueForAccessibilitySize]' started.
Test Case '-[KizbaTests.FormFieldRowAccessibilityTests testShouldUseVerticalLayout_returnsTrueForAccessibilitySize]' passed (0.001 seconds).
Test Suite 'FormFieldRowAccessibilityTests' passed at 2026-05-24 08:25:20.223.
	 Executed 2 tests, with 0 failures (0 unexpected) in 0.003 (0.004) seconds
Test Suite 'GeneratePasswordModelTests' started at 2026-05-24 08:25:20.240.
Test Case '-[KizbaTests.GeneratePasswordModelTests testApplyFlow_populatingDraftPassword_unblocksFormCanSave]' started.
Test Case '-[KizbaTests.GeneratePasswordModelTests testApplyFlow_populatingDraftPassword_unblocksFormCanSave]' passed (0.001 seconds).
Test Case '-[KizbaTests.GeneratePasswordModelTests testIncludeSymbolsMutation_alone_doesNotCallGenerator]' started.
Test Case '-[KizbaTests.GeneratePasswordModelTests testIncludeSymbolsMutation_alone_doesNotCallGenerator]' passed (0.001 seconds).
Test Case '-[KizbaTests.GeneratePasswordModelTests testInit_runsInitialPreview_andSurfacesReadyState]' started.
Test Case '-[KizbaTests.GeneratePasswordModelTests testInit_runsInitialPreview_andSurfacesReadyState]' passed (0.001 seconds).
Test Case '-[KizbaTests.GeneratePasswordModelTests testLengthBounds_matchesProjectSpec]' started.
Test Case '-[KizbaTests.GeneratePasswordModelTests testLengthBounds_matchesProjectSpec]' passed (0.002 seconds).
Test Case '-[KizbaTests.GeneratePasswordModelTests testLengthMutation_alone_doesNotCallGenerator]' started.
Test Case '-[KizbaTests.GeneratePasswordModelTests testLengthMutation_alone_doesNotCallGenerator]' passed (0.012 seconds).
Test Case '-[KizbaTests.GeneratePasswordModelTests testRegenerate_afterError_recoversToReadyOnValidLength]' started.
Test Case '-[KizbaTests.GeneratePasswordModelTests testRegenerate_afterError_recoversToReadyOnValidLength]' passed (0.002 seconds).
Test Case '-[KizbaTests.GeneratePasswordModelTests testRegenerate_consumesNextScriptedValue_andUpdatesState]' started.
Test Case '-[KizbaTests.GeneratePasswordModelTests testRegenerate_consumesNextScriptedValue_andUpdatesState]' passed (0.002 seconds).
Test Case '-[KizbaTests.GeneratePasswordModelTests testRegenerate_propagatesCurrentLengthAndSymbolsFlag]' started.
Test Case '-[KizbaTests.GeneratePasswordModelTests testRegenerate_propagatesCurrentLengthAndSymbolsFlag]' passed (0.001 seconds).
Test Case '-[KizbaTests.GeneratePasswordModelTests testRegenerate_withInvalidLengthZero_landsInErrorState]' started.
Test Case '-[KizbaTests.GeneratePasswordModelTests testRegenerate_withInvalidLengthZero_landsInErrorState]' passed (0.001 seconds).
Test Case '-[KizbaTests.GeneratePasswordModelTests testRegenerate_withNegativeLength_landsInErrorState]' started.
Test Case '-[KizbaTests.GeneratePasswordModelTests testRegenerate_withNegativeLength_landsInErrorState]' passed (0.002 seconds).
Test Suite 'GeneratePasswordModelTests' passed at 2026-05-24 08:25:20.279.
	 Executed 10 tests, with 0 failures (0 unexpected) in 0.024 (0.039) seconds
Test Suite 'GenericCSVExporterTests' started at 2026-05-24 08:25:20.279.
Test Case '-[KizbaTests.GenericCSVExporterTests testExport_endsWithTrailingNewline]' started.
Test Case '-[KizbaTests.GenericCSVExporterTests testExport_endsWithTrailingNewline]' passed (0.002 seconds).
Test Case '-[KizbaTests.GenericCSVExporterTests testExport_fieldWithComma_isQuoted]' started.
Test Case '-[KizbaTests.GenericCSVExporterTests testExport_fieldWithComma_isQuoted]' passed (0.001 seconds).
Test Case '-[KizbaTests.GenericCSVExporterTests testExport_fieldWithQuote_isEscaped]' started.
Test Case '-[KizbaTests.GenericCSVExporterTests testExport_fieldWithQuote_isEscaped]' passed (0.001 seconds).
Test Case '-[KizbaTests.GenericCSVExporterTests testExport_headerRowFirst]' started.
Test Case '-[KizbaTests.GenericCSVExporterTests testExport_headerRowFirst]' passed (0.001 seconds).
Test Case '-[KizbaTests.GenericCSVExporterTests testExport_nilFields_areEmpty]' started.
Test Case '-[KizbaTests.GenericCSVExporterTests testExport_nilFields_areEmpty]' passed (0.001 seconds).
Test Case '-[KizbaTests.GenericCSVExporterTests testExport_singleRecord]' started.
Test Case '-[KizbaTests.GenericCSVExporterTests testExport_singleRecord]' passed (0.001 seconds).
Test Suite 'GenericCSVExporterTests' passed at 2026-05-24 08:25:20.298.
	 Executed 6 tests, with 0 failures (0 unexpected) in 0.008 (0.019) seconds
Test Suite 'GenericCSVImporterTests' started at 2026-05-24 08:25:20.298.
Test Case '-[KizbaTests.GenericCSVImporterTests testParse_caseInsensitiveHeaders]' started.
Test Case '-[KizbaTests.GenericCSVImporterTests testParse_caseInsensitiveHeaders]' passed (0.001 seconds).
Test Case '-[KizbaTests.GenericCSVImporterTests testParse_conflictsDetected]' started.
Test Case '-[KizbaTests.GenericCSVImporterTests testParse_conflictsDetected]' passed (0.001 seconds).
Test Case '-[KizbaTests.GenericCSVImporterTests testParse_emptyInput_throws]' started.
Test Case '-[KizbaTests.GenericCSVImporterTests testParse_emptyInput_throws]' passed (0.001 seconds).
Test Case '-[KizbaTests.GenericCSVImporterTests testParse_missingNameColumn_throws]' started.
Test Case '-[KizbaTests.GenericCSVImporterTests testParse_missingNameColumn_throws]' passed (0.001 seconds).
Test Case '-[KizbaTests.GenericCSVImporterTests testParse_missingPasswordColumn_throws]' started.
Test Case '-[KizbaTests.GenericCSVImporterTests testParse_missingPasswordColumn_throws]' passed (0.001 seconds).
Test Case '-[KizbaTests.GenericCSVImporterTests testParse_otpauthAlias_recognised]' started.
Test Case '-[KizbaTests.GenericCSVImporterTests testParse_otpauthAlias_recognised]' passed (0.001 seconds).
Test Case '-[KizbaTests.GenericCSVImporterTests testParse_rowWithEmptyPassword_isWarning]' started.
Test Case '-[KizbaTests.GenericCSVImporterTests testParse_rowWithEmptyPassword_isWarning]' passed (0.001 seconds).
Test Case '-[KizbaTests.GenericCSVImporterTests testParse_standardHeader]' started.
Test Case '-[KizbaTests.GenericCSVImporterTests testParse_standardHeader]' passed (0.001 seconds).
Test Case '-[KizbaTests.GenericCSVImporterTests testParse_titleAndWebsiteAliases]' started.
Test Case '-[KizbaTests.GenericCSVImporterTests testParse_titleAndWebsiteAliases]' passed (0.001 seconds).
Test Case '-[KizbaTests.GenericCSVImporterTests testParse_totpColumn_isPassedThrough]' started.
Test Case '-[KizbaTests.GenericCSVImporterTests testParse_totpColumn_isPassedThrough]' passed (0.001 seconds).
Test Suite 'GenericCSVImporterTests' passed at 2026-05-24 08:25:20.324.
	 Executed 10 tests, with 0 failures (0 unexpected) in 0.007 (0.026) seconds
Test Suite 'GitActionsPopoverTests' started at 2026-05-24 08:25:20.324.
Test Case '-[KizbaTests.GitActionsPopoverTests testInFlightAccessibility_progressLabelAndCancelHint]' started.
Test Case '-[KizbaTests.GitActionsPopoverTests testInFlightAccessibility_progressLabelAndCancelHint]' passed (0.002 seconds).
Test Case '-[KizbaTests.GitActionsPopoverTests testPullButtonDisabledWhenModelCannotPull]' started.
Test Case '-[KizbaTests.GitActionsPopoverTests testPullButtonDisabledWhenModelCannotPull]' passed (0.002 seconds).
Test Case '-[KizbaTests.GitActionsPopoverTests testPullButtonEnabledWhenModelCanPull]' started.
Test Case '-[KizbaTests.GitActionsPopoverTests testPullButtonEnabledWhenModelCanPull]' passed (0.002 seconds).
Test Case '-[KizbaTests.GitActionsPopoverTests testPushButtonDisabledWhenModelCannotPush]' started.
Test Case '-[KizbaTests.GitActionsPopoverTests testPushButtonDisabledWhenModelCannotPush]' passed (0.002 seconds).
Test Case '-[KizbaTests.GitActionsPopoverTests testPushButtonEnabledWhenModelCanPush]' started.
Test Case '-[KizbaTests.GitActionsPopoverTests testPushButtonEnabledWhenModelCanPush]' passed (0.001 seconds).
Test Case '-[KizbaTests.GitActionsPopoverTests testRefreshButtonDisabledWhenLoadOrOperationInProgress]' started.
Test Case '-[KizbaTests.GitActionsPopoverTests testRefreshButtonDisabledWhenLoadOrOperationInProgress]' passed (0.001 seconds).
Test Case '-[KizbaTests.GitActionsPopoverTests testRefreshButtonEnabledWhenIdle]' started.
Test Case '-[KizbaTests.GitActionsPopoverTests testRefreshButtonEnabledWhenIdle]' passed (0.001 seconds).
Test Case '-[KizbaTests.GitActionsPopoverTests testSpinnerAndCancelHiddenWhenIdle]' started.
Test Case '-[KizbaTests.GitActionsPopoverTests testSpinnerAndCancelHiddenWhenIdle]' passed (0.001 seconds).
Test Case '-[KizbaTests.GitActionsPopoverTests testSpinnerAndCancelVisibleWhenPullingOrPushing]' started.
Test Case '-[KizbaTests.GitActionsPopoverTests testSpinnerAndCancelVisibleWhenPullingOrPushing]' passed (0.001 seconds).
Test Suite 'GitActionsPopoverTests' passed at 2026-05-24 08:25:20.363.
	 Executed 9 tests, with 0 failures (0 unexpected) in 0.011 (0.038) seconds
Test Suite 'GitConflictBannerMountTests' started at 2026-05-24 08:25:20.363.
Test Case '-[KizbaTests.GitConflictBannerMountTests testGitConflictBannerSheetBinding_andContentBuilder_workWithModel]' started.
Test Case '-[KizbaTests.GitConflictBannerMountTests testGitConflictBannerSheetBinding_andContentBuilder_workWithModel]' passed (0.024 seconds).
Test Case '-[KizbaTests.GitConflictBannerMountTests testPresentGitConflictBanner_setsFlagTrue_whenModelExists]' started.
Test Case '-[KizbaTests.GitConflictBannerMountTests testPresentGitConflictBanner_setsFlagTrue_whenModelExists]' passed (0.001 seconds).
Test Suite 'GitConflictBannerMountTests' passed at 2026-05-24 08:25:20.388.
	 Executed 2 tests, with 0 failures (0 unexpected) in 0.025 (0.025) seconds
Test Suite 'GitConflictBannerTests' started at 2026-05-24 08:25:20.388.
Test Case '-[KizbaTests.GitConflictBannerTests testBanner_accessibility_storePathAndButtons]' started.
Test Case '-[KizbaTests.GitConflictBannerTests testBanner_accessibility_storePathAndButtons]' passed (0.001 seconds).
Test Case '-[KizbaTests.GitConflictBannerTests testDismissButton_dismissesBanner]' started.
Test Case '-[KizbaTests.GitConflictBannerTests testDismissButton_dismissesBanner]' passed (0.003 seconds).
Test Case '-[KizbaTests.GitConflictBannerTests testOpenTerminalButton_callsActionAndDismisses]' started.
Test Case '-[KizbaTests.GitConflictBannerTests testOpenTerminalButton_callsActionAndDismisses]' passed (0.001 seconds).
Test Case '-[KizbaTests.GitConflictBannerTests testStorePath_rendered_copyable]' started.
Test Case '-[KizbaTests.GitConflictBannerTests testStorePath_rendered_copyable]' passed (0.001 seconds).
Test Suite 'GitConflictBannerTests' passed at 2026-05-24 08:25:20.413.
	 Executed 4 tests, with 0 failures (0 unexpected) in 0.005 (0.025) seconds
Test Suite 'GitMenuCommandsTests' started at 2026-05-24 08:25:20.413.
Test Case '-[KizbaTests.GitMenuCommandsTests testCanPull_gitPushInFlight_false]' started.
Test Case '-[KizbaTests.GitMenuCommandsTests testCanPull_gitPushInFlight_false]' passed (0.002 seconds).
Test Case '-[KizbaTests.GitMenuCommandsTests testCanPullDisabledWhenAnyWriteInFlight]' started.
Test Case '-[KizbaTests.GitMenuCommandsTests testCanPullDisabledWhenAnyWriteInFlight]' passed (0.002 seconds).
Test Case '-[KizbaTests.GitMenuCommandsTests testCanPullDisabledWhenNoRemote]' started.
Test Case '-[KizbaTests.GitMenuCommandsTests testCanPullDisabledWhenNoRemote]' passed (0.002 seconds).
Test Case '-[KizbaTests.GitMenuCommandsTests testCanPushEnabledWhenAheadAndNoWriteInFlight]' started.
Test Case '-[KizbaTests.GitMenuCommandsTests testCanPushEnabledWhenAheadAndNoWriteInFlight]' passed (0.001 seconds).
Test Case '-[KizbaTests.GitMenuCommandsTests testCanRefreshReflectsModel]' started.
Test Case '-[KizbaTests.GitMenuCommandsTests testCanRefreshReflectsModel]' passed (0.001 seconds).
Test Case '-[KizbaTests.GitMenuCommandsTests testMenuHiddenWhenNoModel]' started.
Test Case '-[KizbaTests.GitMenuCommandsTests testMenuHiddenWhenNoModel]' passed (0.001 seconds).
Test Case '-[KizbaTests.GitMenuCommandsTests testMenuVisibleWhenModelPresent]' started.
Test Case '-[KizbaTests.GitMenuCommandsTests testMenuVisibleWhenModelPresent]' passed (0.001 seconds).
Test Suite 'GitMenuCommandsTests' passed at 2026-05-24 08:25:20.431.
	 Executed 7 tests, with 0 failures (0 unexpected) in 0.008 (0.018) seconds
Test Suite 'GitStatusBadgeTests' started at 2026-05-24 08:25:20.431.
Test Case '-[KizbaTests.GitStatusBadgeTests testAccessibilityLabel_aheadAndBehind]' started.
Test Case '-[KizbaTests.GitStatusBadgeTests testAccessibilityLabel_aheadAndBehind]' passed (0.001 seconds).
Test Case '-[KizbaTests.GitStatusBadgeTests testAccessibilityLabel_conflict]' started.
Test Case '-[KizbaTests.GitStatusBadgeTests testAccessibilityLabel_conflict]' passed (0.001 seconds).
Test Case '-[KizbaTests.GitStatusBadgeTests testAccessibilityLabel_notARepository]' started.
Test Case '-[KizbaTests.GitStatusBadgeTests testAccessibilityLabel_notARepository]' passed (0.001 seconds).
Test Case '-[KizbaTests.GitStatusBadgeTests testBadge_accessibilityValue_and_label]' started.
Test Case '-[KizbaTests.GitStatusBadgeTests testBadge_accessibilityValue_and_label]' passed (0.001 seconds).
Test Case '-[KizbaTests.GitStatusBadgeTests testBadgeText_aheadAndBehind]' started.
Test Case '-[KizbaTests.GitStatusBadgeTests testBadgeText_aheadAndBehind]' passed (0.001 seconds).
Test Case '-[KizbaTests.GitStatusBadgeTests testBadgeText_aheadOnly]' started.
Test Case '-[KizbaTests.GitStatusBadgeTests testBadgeText_aheadOnly]' passed (0.001 seconds).
Test Case '-[KizbaTests.GitStatusBadgeTests testBadgeText_behindOnly]' started.
Test Case '-[KizbaTests.GitStatusBadgeTests testBadgeText_behindOnly]' passed (0.001 seconds).
Test Case '-[KizbaTests.GitStatusBadgeTests testBadgeText_clean]' started.
Test Case '-[KizbaTests.GitStatusBadgeTests testBadgeText_clean]' passed (0.001 seconds).
Test Case '-[KizbaTests.GitStatusBadgeTests testBadgeText_conflict]' started.
Test Case '-[KizbaTests.GitStatusBadgeTests testBadgeText_conflict]' passed (0.001 seconds).
Test Case '-[KizbaTests.GitStatusBadgeTests testBadgeText_localChanges]' started.
Test Case '-[KizbaTests.GitStatusBadgeTests testBadgeText_localChanges]' passed (0.001 seconds).
Test Case '-[KizbaTests.GitStatusBadgeTests testBadgeText_notARepository]' started.
Test Case '-[KizbaTests.GitStatusBadgeTests testBadgeText_notARepository]' passed (0.006 seconds).
Test Suite 'GitStatusBadgeTests' passed at 2026-05-24 08:25:20.459.
	 Executed 11 tests, with 0 failures (0 unexpected) in 0.012 (0.028) seconds
Test Suite 'GitStatusModelObserveTests' started at 2026-05-24 08:25:20.459.
Test Case '-[KizbaTests.GitStatusModelObserveTests testObserveChanges_handlesCancellationDuringLoad]' started.
Test Case '-[KizbaTests.GitStatusModelObserveTests testObserveChanges_handlesCancellationDuringLoad]' passed (0.250 seconds).
Test Case '-[KizbaTests.GitStatusModelObserveTests testObserveChanges_noDoubleSubscribe]' started.
Test Case '-[KizbaTests.GitStatusModelObserveTests testObserveChanges_noDoubleSubscribe]' passed (0.038 seconds).
Test Case '-[KizbaTests.GitStatusModelObserveTests testObserveChanges_triggersLoadOnEvent]' started.
Test Case '-[KizbaTests.GitStatusModelObserveTests testObserveChanges_triggersLoadOnEvent]' passed (0.037 seconds).
Test Case '-[KizbaTests.GitStatusModelObserveTests testStop_cancelsSubscription]' started.
Test Case '-[KizbaTests.GitStatusModelObserveTests testStop_cancelsSubscription]' passed (0.198 seconds).
Test Suite 'GitStatusModelObserveTests' passed at 2026-05-24 08:25:20.986.
	 Executed 4 tests, with 0 failures (0 unexpected) in 0.522 (0.526) seconds
Test Suite 'GitStatusModelTests' started at 2026-05-24 08:25:20.986.
Test Case '-[KizbaTests.GitStatusModelTests testBadgeAccessibilityLabel_nonEmpty]' started.
Test Case '-[KizbaTests.GitStatusModelTests testBadgeAccessibilityLabel_nonEmpty]' passed (0.002 seconds).
Test Case '-[KizbaTests.GitStatusModelTests testBadgeText_variousStates]' started.
Test Case '-[KizbaTests.GitStatusModelTests testBadgeText_variousStates]' passed (0.002 seconds).
Test Case '-[KizbaTests.GitStatusModelTests testCancelLoad_cancelsTask_and_leavesLoadStateIdleOrFailedConsistent]' started.
Test Case '-[KizbaTests.GitStatusModelTests testCancelLoad_cancelsTask_and_leavesLoadStateIdleOrFailedConsistent]' passed (0.035 seconds).
Test Case '-[KizbaTests.GitStatusModelTests testCancelOperation_abortsInFlightPull]' started.
Test Case '-[KizbaTests.GitStatusModelTests testCancelOperation_abortsInFlightPull]' passed (0.057 seconds).
Test Case '-[KizbaTests.GitStatusModelTests testCancelOperation_abortsInFlightPush]' started.
Test Case '-[KizbaTests.GitStatusModelTests testCancelOperation_abortsInFlightPush]' passed (0.058 seconds).
Test Case '-[KizbaTests.GitStatusModelTests testCancelOperation_idempotent_whenIdle]' started.
Test Case '-[KizbaTests.GitStatusModelTests testCancelOperation_idempotent_whenIdle]' passed (0.002 seconds).
Test Case '-[KizbaTests.GitStatusModelTests testCanPull_respectsAnyWriteInFlight]' started.
Test Case '-[KizbaTests.GitStatusModelTests testCanPull_respectsAnyWriteInFlight]' passed (0.002 seconds).
Test Case '-[KizbaTests.GitStatusModelTests testCanPush_aheadCount_enablesPush]' started.
Test Case '-[KizbaTests.GitStatusModelTests testCanPush_aheadCount_enablesPush]' passed (0.001 seconds).
Test Case '-[KizbaTests.GitStatusModelTests testCanRefresh_falseWhileLoading_trueWhenIdle]' started.
Test Case '-[KizbaTests.GitStatusModelTests testCanRefresh_falseWhileLoading_trueWhenIdle]' passed (0.125 seconds).
Test Case '-[KizbaTests.GitStatusModelTests testFetchAndReloadStatus_callsGitFetch_thenLoadStatus]' started.
Test Case '-[KizbaTests.GitStatusModelTests testFetchAndReloadStatus_callsGitFetch_thenLoadStatus]' passed (0.104 seconds).
Test Case '-[KizbaTests.GitStatusModelTests testFetchFailure_fallsBackToLocalStatus]' started.
Test Case '-[KizbaTests.GitStatusModelTests testFetchFailure_fallsBackToLocalStatus]' passed (0.106 seconds).
Test Case '-[KizbaTests.GitStatusModelTests testIsFullyClean_trueForCleanStatus]' started.
Test Case '-[KizbaTests.GitStatusModelTests testIsFullyClean_trueForCleanStatus]' passed (0.003 seconds).
Test Case '-[KizbaTests.GitStatusModelTests testLoad_sets_lastError_nil_onSuccess]' started.
Test Case '-[KizbaTests.GitStatusModelTests testLoad_sets_lastError_nil_onSuccess]' passed (0.002 seconds).
Test Case '-[KizbaTests.GitStatusModelTests testLoadStatus_failure_setsLastError_and_loadStateFailed_and_postsToastWhenAppropriate]' started.
Test Case '-[KizbaTests.GitStatusModelTests testLoadStatus_failure_setsLastError_and_loadStateFailed_and_postsToastWhenAppropriate]' passed (0.098 seconds).
Test Case '-[KizbaTests.GitStatusModelTests testLoadStatus_failure_silentPresentation_doesNotPostToast]' started.
Test Case '-[KizbaTests.GitStatusModelTests testLoadStatus_failure_silentPresentation_doesNotPostToast]' passed (0.105 seconds).
Test Case '-[KizbaTests.GitStatusModelTests testLoadStatus_happyPath_updatesStatusAndLoadState]' started.
Test Case '-[KizbaTests.GitStatusModelTests testLoadStatus_happyPath_updatesStatusAndLoadState]' passed (0.002 seconds).
Test Case '-[KizbaTests.GitStatusModelTests testLoadStatus_staleResult_ignoredByGeneration]' started.
Test Case '-[KizbaTests.GitStatusModelTests testLoadStatus_staleResult_ignoredByGeneration]' passed (0.126 seconds).
Test Case '-[KizbaTests.GitStatusModelTests testLoadUsesSettingsTimeout]' started.
/Users/kirillsimagin/dev/my/worldproject/kizba/KizbaTests/GitStatusModelTests.swift:186: -[KizbaTests.GitStatusModelTests testLoadUsesSettingsTimeout] : Test skipped - C.1 scaffold does not consume git timeout setting yet.
Test Case '-[KizbaTests.GitStatusModelTests testLoadUsesSettingsTimeout]' skipped (0.004 seconds).
Test Case '-[KizbaTests.GitStatusModelTests testOpenTerminalAtStore_doesNotCrash]' started.
Test Case '-[KizbaTests.GitStatusModelTests testOpenTerminalAtStore_doesNotCrash]' passed (0.005 seconds).
Test Case '-[KizbaTests.GitStatusModelTests testOperationState_transitions_onPullPushCalls]' started.
Test Case '-[KizbaTests.GitStatusModelTests testOperationState_transitions_onPullPushCalls]' passed (0.002 seconds).
Test Case '-[KizbaTests.GitStatusModelTests testPull_conflictError_presentsBanner]' started.
Test Case '-[KizbaTests.GitStatusModelTests testPull_conflictError_presentsBanner]' passed (0.003 seconds).
Test Case '-[KizbaTests.GitStatusModelTests testPull_failure_postsDangerToast_and_setsLastError]' started.
Test Case '-[KizbaTests.GitStatusModelTests testPull_failure_postsDangerToast_and_setsLastError]' passed (0.003 seconds).
Test Case '-[KizbaTests.GitStatusModelTests testPull_guardsCanPull_doesNothingWhenFalse]' started.
Test Case '-[KizbaTests.GitStatusModelTests testPull_guardsCanPull_doesNothingWhenFalse]' passed (0.003 seconds).
Test Case '-[KizbaTests.GitStatusModelTests testPull_happyPath_postsSuccessToast_and_reloadsStatus]' started.
Test Case '-[KizbaTests.GitStatusModelTests testPull_happyPath_postsSuccessToast_and_reloadsStatus]' passed (0.003 seconds).
Test Case '-[KizbaTests.GitStatusModelTests testPull_setsWriteLockout_duringOperation]' started.
The file /tmp/kizba-mock-store does not exist.
Test Case '-[KizbaTests.GitStatusModelTests testPull_setsWriteLockout_duringOperation]' passed (0.320 seconds).
Test Case '-[KizbaTests.GitStatusModelTests testPush_failure_postsDangerToast_and_setsLastError]' started.
Test Case '-[KizbaTests.GitStatusModelTests testPush_failure_postsDangerToast_and_setsLastError]' passed (0.003 seconds).
Test Case '-[KizbaTests.GitStatusModelTests testPush_guardsCanPush_doesNothingWhenFalse]' started.
Test Case '-[KizbaTests.GitStatusModelTests testPush_guardsCanPush_doesNothingWhenFalse]' passed (0.002 seconds).
Test Case '-[KizbaTests.GitStatusModelTests testPush_happyPath_postsSuccessToast]' started.
Test Case '-[KizbaTests.GitStatusModelTests testPush_happyPath_postsSuccessToast]' passed (0.003 seconds).
Test Case '-[KizbaTests.GitStatusModelTests testPush_setsWriteLockout_duringOperation]' started.
Test Case '-[KizbaTests.GitStatusModelTests testPush_setsWriteLockout_duringOperation]' passed (0.313 seconds).
Test Case '-[KizbaTests.GitStatusModelTests testRefresh_autoDismissesBannerWhenConflictsResolved]' started.
Test Case '-[KizbaTests.GitStatusModelTests testRefresh_autoDismissesBannerWhenConflictsResolved]' passed (0.106 seconds).
Test Case '-[KizbaTests.GitStatusModelTests testRefresh_autoPresentsBannerWhenStatusHasConflicts]' started.
Test Case '-[KizbaTests.GitStatusModelTests testRefresh_autoPresentsBannerWhenStatusHasConflicts]' passed (0.002 seconds).
Test Suite 'GitStatusModelTests' passed at 2026-05-24 08:25:22.610.
	 Executed 31 tests, with 1 test skipped and 0 failures (0 unexpected) in 1.600 (1.624) seconds
Test Suite 'GitStatusParserTests' started at 2026-05-24 08:25:22.610.
Test Case '-[KizbaTests.GitStatusParserTests testAheadAndBehind_parsesBothCounts]' started.
Test Case '-[KizbaTests.GitStatusParserTests testAheadAndBehind_parsesBothCounts]' passed (0.016 seconds).
Test Case '-[KizbaTests.GitStatusParserTests testAheadOnly_parsesAheadCount]' started.
Test Case '-[KizbaTests.GitStatusParserTests testAheadOnly_parsesAheadCount]' passed (0.013 seconds).
Test Case '-[KizbaTests.GitStatusParserTests testBehindOnly_parsesBehindCount]' started.
Test Case '-[KizbaTests.GitStatusParserTests testBehindOnly_parsesBehindCount]' passed (0.009 seconds).
Test Case '-[KizbaTests.GitStatusParserTests testBranchWithSlashes_parsedCorrectly]' started.
Test Case '-[KizbaTests.GitStatusParserTests testBranchWithSlashes_parsedCorrectly]' passed (0.002 seconds).
Test Case '-[KizbaTests.GitStatusParserTests testCleanRepoNoRemote_hasUpstreamFalse]' started.
Test Case '-[KizbaTests.GitStatusParserTests testCleanRepoNoRemote_hasUpstreamFalse]' passed (0.005 seconds).
Test Case '-[KizbaTests.GitStatusParserTests testCleanRepoWithUpstream_parsesAllHeaders]' started.
Test Case '-[KizbaTests.GitStatusParserTests testCleanRepoWithUpstream_parsesAllHeaders]' passed (0.002 seconds).
Test Case '-[KizbaTests.GitStatusParserTests testConflictLine_hasConflictsTrue]' started.
Test Case '-[KizbaTests.GitStatusParserTests testConflictLine_hasConflictsTrue]' passed (0.005 seconds).
Test Case '-[KizbaTests.GitStatusParserTests testDetachedHead_branchIsNil]' started.
Test Case '-[KizbaTests.GitStatusParserTests testDetachedHead_branchIsNil]' passed (0.010 seconds).
Test Case '-[KizbaTests.GitStatusParserTests testEmptyInput_returnsGitRepoWithDefaults]' started.
Test Case '-[KizbaTests.GitStatusParserTests testEmptyInput_returnsGitRepoWithDefaults]' passed (0.001 seconds).
Test Case '-[KizbaTests.GitStatusParserTests testIsGitRepository_alwaysTrue]' started.
Test Case '-[KizbaTests.GitStatusParserTests testIsGitRepository_alwaysTrue]' passed (0.002 seconds).
Test Case '-[KizbaTests.GitStatusParserTests testLastFetchAt_alwaysNil]' started.
Test Case '-[KizbaTests.GitStatusParserTests testLastFetchAt_alwaysNil]' passed (0.004 seconds).
Test Case '-[KizbaTests.GitStatusParserTests testModifiedFile_hasLocalChangesTrue]' started.
Test Case '-[KizbaTests.GitStatusParserTests testModifiedFile_hasLocalChangesTrue]' passed (0.004 seconds).
Test Case '-[KizbaTests.GitStatusParserTests testMultiSection_allFieldsCombined]' started.
Test Case '-[KizbaTests.GitStatusParserTests testMultiSection_allFieldsCombined]' passed (0.002 seconds).
Test Case '-[KizbaTests.GitStatusParserTests testRenamedFile_hasLocalChangesTrue]' started.
Test Case '-[KizbaTests.GitStatusParserTests testRenamedFile_hasLocalChangesTrue]' passed (0.008 seconds).
Test Case '-[KizbaTests.GitStatusParserTests testStagedFile_hasLocalChangesTrue]' started.
Test Case '-[KizbaTests.GitStatusParserTests testStagedFile_hasLocalChangesTrue]' passed (0.004 seconds).
Test Case '-[KizbaTests.GitStatusParserTests testUnknownLines_silentlyIgnored]' started.
Test Case '-[KizbaTests.GitStatusParserTests testUnknownLines_silentlyIgnored]' passed (0.004 seconds).
Test Case '-[KizbaTests.GitStatusParserTests testUntrackedFile_hasLocalChangesTrue]' started.
Test Case '-[KizbaTests.GitStatusParserTests testUntrackedFile_hasLocalChangesTrue]' passed (0.008 seconds).
Test Case '-[KizbaTests.GitStatusParserTests testWhitespaceOnlyInput_returnsDefaults]' started.
Test Case '-[KizbaTests.GitStatusParserTests testWhitespaceOnlyInput_returnsDefaults]' passed (0.002 seconds).
Test Suite 'GitStatusParserTests' passed at 2026-05-24 08:25:22.723.
	 Executed 18 tests, with 0 failures (0 unexpected) in 0.101 (0.113) seconds
Test Suite 'GitStatusTests' started at 2026-05-24 08:25:22.724.
Test Case '-[KizbaTests.GitStatusTests testCustomInit_allFieldsSet]' started.
Test Case '-[KizbaTests.GitStatusTests testCustomInit_allFieldsSet]' passed (0.001 seconds).
Test Case '-[KizbaTests.GitStatusTests testEquality_differentBranch]' started.
Test Case '-[KizbaTests.GitStatusTests testEquality_differentBranch]' passed (0.002 seconds).
Test Case '-[KizbaTests.GitStatusTests testEquality_identicalInstances]' started.
Test Case '-[KizbaTests.GitStatusTests testEquality_identicalInstances]' passed (0.001 seconds).
Test Case '-[KizbaTests.GitStatusTests testHashing_identicalInstancesShareHash]' started.
Test Case '-[KizbaTests.GitStatusTests testHashing_identicalInstancesShareHash]' passed (0.001 seconds).
Test Case '-[KizbaTests.GitStatusTests testIsNotCodable]' started.
Test Case '-[KizbaTests.GitStatusTests testIsNotCodable]' passed (0.001 seconds).
Test Case '-[KizbaTests.GitStatusTests testIsNotCustomStringConvertible]' started.
Test Case '-[KizbaTests.GitStatusTests testIsNotCustomStringConvertible]' passed (0.001 seconds).
Test Case '-[KizbaTests.GitStatusTests testNotARepository_hasExpectedDefaults]' started.
Test Case '-[KizbaTests.GitStatusTests testNotARepository_hasExpectedDefaults]' passed (0.001 seconds).
Test Suite 'GitStatusTests' passed at 2026-05-24 08:25:22.744.
	 Executed 7 tests, with 0 failures (0 unexpected) in 0.007 (0.021) seconds
Test Suite 'HelpCatalogTests' started at 2026-05-24 08:25:22.745.
Test Case '-[KizbaTests.HelpCatalogTests testCatalog_aeadTopic_blockIDsAreUniqueWithinTopic]' started.
Test Case '-[KizbaTests.HelpCatalogTests testCatalog_aeadTopic_blockIDsAreUniqueWithinTopic]' passed (0.001 seconds).
Test Case '-[KizbaTests.HelpCatalogTests testCatalog_aeadTopic_everyCommandIsNonEmpty]' started.
Test Case '-[KizbaTests.HelpCatalogTests testCatalog_aeadTopic_everyCommandIsNonEmpty]' passed (0.002 seconds).
Test Case '-[KizbaTests.HelpCatalogTests testCatalog_aeadTopic_everyCommandSequenceHasAtLeastOneCommand]' started.
Test Case '-[KizbaTests.HelpCatalogTests testCatalog_aeadTopic_everyCommandSequenceHasAtLeastOneCommand]' passed (0.002 seconds).
Test Case '-[KizbaTests.HelpCatalogTests testCatalog_aeadTopic_hasExpectedSectionCount]' started.
Test Case '-[KizbaTests.HelpCatalogTests testCatalog_aeadTopic_hasExpectedSectionCount]' passed (0.002 seconds).
Test Case '-[KizbaTests.HelpCatalogTests testCatalog_aeadTopic_paragraphsAreNonEmpty]' started.
Test Case '-[KizbaTests.HelpCatalogTests testCatalog_aeadTopic_paragraphsAreNonEmpty]' passed (0.002 seconds).
Test Case '-[KizbaTests.HelpCatalogTests testCatalog_aeadTopic_section6_findScriptUsesFind]' started.
Test Case '-[KizbaTests.HelpCatalogTests testCatalog_aeadTopic_section6_findScriptUsesFind]' passed (0.013 seconds).
Test Case '-[KizbaTests.HelpCatalogTests testCatalog_aeadTopic_sectionHeadingsMatchSpec]' started.
Test Case '-[KizbaTests.HelpCatalogTests testCatalog_aeadTopic_sectionHeadingsMatchSpec]' passed (0.003 seconds).
Test Case '-[KizbaTests.HelpCatalogTests testCatalog_aeadTopic_warningsAreNonEmpty]' started.
Test Case '-[KizbaTests.HelpCatalogTests testCatalog_aeadTopic_warningsAreNonEmpty]' passed (0.002 seconds).
Test Case '-[KizbaTests.HelpCatalogTests testCatalog_aeadTopicExistsByID]' started.
Test Case '-[KizbaTests.HelpCatalogTests testCatalog_aeadTopicExistsByID]' passed (0.002 seconds).
Test Case '-[KizbaTests.HelpCatalogTests testCatalog_containsConfigurePinentryTopic]' started.
Test Case '-[KizbaTests.HelpCatalogTests testCatalog_containsConfigurePinentryTopic]' passed (0.001 seconds).
Test Case '-[KizbaTests.HelpCatalogTests testCatalog_containsGPGKeyTrustTopic]' started.
Test Case '-[KizbaTests.HelpCatalogTests testCatalog_containsGPGKeyTrustTopic]' passed (0.014 seconds).
Test Case '-[KizbaTests.HelpCatalogTests testCatalog_containsOneTimePasswordsTopic]' started.
Test Case '-[KizbaTests.HelpCatalogTests testCatalog_containsOneTimePasswordsTopic]' passed (0.001 seconds).
Test Case '-[KizbaTests.HelpCatalogTests testCatalog_containsSetupGitRemoteTopic]' started.
Test Case '-[KizbaTests.HelpCatalogTests testCatalog_containsSetupGitRemoteTopic]' passed (0.002 seconds).
Test Case '-[KizbaTests.HelpCatalogTests testCatalog_containsSetupPassAndGPGTopic]' started.
Test Case '-[KizbaTests.HelpCatalogTests testCatalog_containsSetupPassAndGPGTopic]' passed (0.003 seconds).
Test Case '-[KizbaTests.HelpCatalogTests testCatalog_hasAtLeastOneTopic]' started.
Test Case '-[KizbaTests.HelpCatalogTests testCatalog_hasAtLeastOneTopic]' passed (0.002 seconds).
Test Case '-[KizbaTests.HelpCatalogTests testCatalog_oneTimePasswordsAccessorExists]' started.
Test Case '-[KizbaTests.HelpCatalogTests testCatalog_oneTimePasswordsAccessorExists]' passed (0.011 seconds).
Test Case '-[KizbaTests.HelpCatalogTests testCatalog_topicIDsAreUnique]' started.
Test Case '-[KizbaTests.HelpCatalogTests testCatalog_topicIDsAreUnique]' passed (0.002 seconds).
Test Case '-[KizbaTests.HelpCatalogTests testGPGKeyTrust_accessorExists]' started.
Test Case '-[KizbaTests.HelpCatalogTests testGPGKeyTrust_accessorExists]' passed (0.002 seconds).
Test Case '-[KizbaTests.HelpCatalogTests testGPGKeyTrust_containsCommandAndWarningBlocks]' started.
Test Case '-[KizbaTests.HelpCatalogTests testGPGKeyTrust_containsCommandAndWarningBlocks]' passed (0.002 seconds).
Test Case '-[KizbaTests.HelpCatalogTests testGPGKeyTrust_hasExpectedSectionCount]' started.
Test Case '-[KizbaTests.HelpCatalogTests testGPGKeyTrust_hasExpectedSectionCount]' passed (0.001 seconds).
Test Case '-[KizbaTests.HelpCatalogTests testSetupTopics_blockIDsAreUniqueWithinTopic]' started.
Test Case '-[KizbaTests.HelpCatalogTests testSetupTopics_blockIDsAreUniqueWithinTopic]' passed (0.011 seconds).
Test Case '-[KizbaTests.HelpCatalogTests testSetupTopics_containCommandAndWarningBlocks]' started.
Test Case '-[KizbaTests.HelpCatalogTests testSetupTopics_containCommandAndWarningBlocks]' passed (0.002 seconds).
Test Case '-[KizbaTests.HelpCatalogTests testSetupTopics_everyCommandIsNonEmpty]' started.
Test Case '-[KizbaTests.HelpCatalogTests testSetupTopics_everyCommandIsNonEmpty]' passed (0.002 seconds).
Test Case '-[KizbaTests.HelpCatalogTests testSetupTopics_haveAccessors]' started.
Test Case '-[KizbaTests.HelpCatalogTests testSetupTopics_haveAccessors]' passed (0.002 seconds).
Test Case '-[KizbaTests.HelpCatalogTests testSetupTopics_haveExpectedSectionCount]' started.
Test Case '-[KizbaTests.HelpCatalogTests testSetupTopics_haveExpectedSectionCount]' passed (0.001 seconds).
Test Suite 'HelpCatalogTests' passed at 2026-05-24 08:25:22.851.
	 Executed 25 tests, with 0 failures (0 unexpected) in 0.086 (0.106) seconds
Test Suite 'HelpCommandCardTests' started at 2026-05-24 08:25:22.860.
Test Case '-[KizbaTests.HelpCommandCardTests testAccessibilityLabel_emptyArray_returnsSafeFallback]' started.
Test Case '-[KizbaTests.HelpCommandCardTests testAccessibilityLabel_emptyArray_returnsSafeFallback]' passed (0.001 seconds).
Test Case '-[KizbaTests.HelpCommandCardTests testAccessibilityLabel_multipleCommands_isCopyCommandsCount]' started.
Test Case '-[KizbaTests.HelpCommandCardTests testAccessibilityLabel_multipleCommands_isCopyCommandsCount]' passed (0.002 seconds).
Test Case '-[KizbaTests.HelpCommandCardTests testAccessibilityLabel_singleCommand_isCopyCommandColon]' started.
Test Case '-[KizbaTests.HelpCommandCardTests testAccessibilityLabel_singleCommand_isCopyCommandColon]' passed (0.002 seconds).
Test Case '-[KizbaTests.HelpCommandCardTests testCopyButtonLabel_copied_anyCount_isCopiedCheck]' started.
Test Case '-[KizbaTests.HelpCommandCardTests testCopyButtonLabel_copied_anyCount_isCopiedCheck]' passed (0.001 seconds).
Test Case '-[KizbaTests.HelpCommandCardTests testCopyButtonLabel_idle_multipleCommands_isCopyAll]' started.
Test Case '-[KizbaTests.HelpCommandCardTests testCopyButtonLabel_idle_multipleCommands_isCopyAll]' passed (0.002 seconds).
Test Case '-[KizbaTests.HelpCommandCardTests testCopyButtonLabel_idle_singleCommand_isCopy]' started.
Test Case '-[KizbaTests.HelpCommandCardTests testCopyButtonLabel_idle_singleCommand_isCopy]' passed (0.002 seconds).
Test Case '-[KizbaTests.HelpCommandCardTests testHelpWindowID_isStableHelp]' started.
Test Case '-[KizbaTests.HelpCommandCardTests testHelpWindowID_isStableHelp]' passed (0.001 seconds).
Test Suite 'HelpCommandCardTests' passed at 2026-05-24 08:25:22.885.
	 Executed 7 tests, with 0 failures (0 unexpected) in 0.011 (0.026) seconds
Test Suite 'HelpModelTests' started at 2026-05-24 08:25:22.885.
Test Case '-[KizbaTests.HelpModelTests testCopy_clearsCopiedBlockIDAfterFlashDuration]' started.
Test Case '-[KizbaTests.HelpModelTests testCopy_clearsCopiedBlockIDAfterFlashDuration]' passed (0.083 seconds).
Test Case '-[KizbaTests.HelpModelTests testCopy_invokesClipboardWithSingleCommand]' started.
Test Case '-[KizbaTests.HelpModelTests testCopy_invokesClipboardWithSingleCommand]' passed (0.003 seconds).
Test Case '-[KizbaTests.HelpModelTests testCopy_joinsMultipleCommandsWithNewlines]' started.
Test Case '-[KizbaTests.HelpModelTests testCopy_joinsMultipleCommandsWithNewlines]' passed (0.002 seconds).
Test Case '-[KizbaTests.HelpModelTests testCopy_onDifferentBlock_movesCopiedBlockIDImmediately]' started.
Test Case '-[KizbaTests.HelpModelTests testCopy_onDifferentBlock_movesCopiedBlockIDImmediately]' passed (0.003 seconds).
Test Case '-[KizbaTests.HelpModelTests testCopy_passesHelpRetentionDuration]' started.
Test Case '-[KizbaTests.HelpModelTests testCopy_passesHelpRetentionDuration]' passed (0.002 seconds).
Test Case '-[KizbaTests.HelpModelTests testCopy_repeatedOnSameBlock_keepsCopiedBlockIDStable]' started.
Test Case '-[KizbaTests.HelpModelTests testCopy_repeatedOnSameBlock_keepsCopiedBlockIDStable]' passed (0.002 seconds).
Test Case '-[KizbaTests.HelpModelTests testCopy_setsCopiedBlockID]' started.
Test Case '-[KizbaTests.HelpModelTests testCopy_setsCopiedBlockID]' passed (0.002 seconds).
Test Case '-[KizbaTests.HelpModelTests testCopy_singleElementArray_isNotMutated]' started.
Test Case '-[KizbaTests.HelpModelTests testCopy_singleElementArray_isNotMutated]' passed (0.002 seconds).
Test Case '-[KizbaTests.HelpModelTests testInit_selectedTopic_resolvesByID]' started.
Test Case '-[KizbaTests.HelpModelTests testInit_selectedTopic_resolvesByID]' passed (0.001 seconds).
Test Case '-[KizbaTests.HelpModelTests testInit_selectsFirstTopicByDefault]' started.
Test Case '-[KizbaTests.HelpModelTests testInit_selectsFirstTopicByDefault]' passed (0.001 seconds).
Test Case '-[KizbaTests.HelpModelTests testIsCopied_isFalseForOtherBlocks]' started.
Test Case '-[KizbaTests.HelpModelTests testIsCopied_isFalseForOtherBlocks]' passed (0.001 seconds).
Test Case '-[KizbaTests.HelpModelTests testIsCopied_isTrueForActiveBlock]' started.
Test Case '-[KizbaTests.HelpModelTests testIsCopied_isTrueForActiveBlock]' passed (0.001 seconds).
Test Case '-[KizbaTests.HelpModelTests testSelectedTopic_fallsBackToFirstWhenIDMissing]' started.
Test Case '-[KizbaTests.HelpModelTests testSelectedTopic_fallsBackToFirstWhenIDMissing]' passed (0.001 seconds).
Test Case '-[KizbaTests.HelpModelTests testSetSelectedTopicID_changesSelectedTopic]' started.
Test Case '-[KizbaTests.HelpModelTests testSetSelectedTopicID_changesSelectedTopic]' passed (0.001 seconds).
Test Suite 'HelpModelTests' passed at 2026-05-24 08:25:23.001.
	 Executed 14 tests, with 0 failures (0 unexpected) in 0.105 (0.116) seconds
Test Suite 'ImportConflictResolverTests' started at 2026-05-24 08:25:23.001.
Test Case '-[KizbaTests.ImportConflictResolverTests testResolve_conflictOverwrite_returnsOverwrite]' started.
Test Case '-[KizbaTests.ImportConflictResolverTests testResolve_conflictOverwrite_returnsOverwrite]' passed (0.001 seconds).
Test Case '-[KizbaTests.ImportConflictResolverTests testResolve_conflictRename_preservesAllFields]' started.
Test Case '-[KizbaTests.ImportConflictResolverTests testResolve_conflictRename_preservesAllFields]' passed (0.002 seconds).
Test Case '-[KizbaTests.ImportConflictResolverTests testResolve_conflictRename_returnsCreateWithSuffix2]' started.
Test Case '-[KizbaTests.ImportConflictResolverTests testResolve_conflictRename_returnsCreateWithSuffix2]' passed (0.002 seconds).
Test Case '-[KizbaTests.ImportConflictResolverTests testResolve_conflictRename_skipsExistingSuffix2]' started.
Test Case '-[KizbaTests.ImportConflictResolverTests testResolve_conflictRename_skipsExistingSuffix2]' passed (0.001 seconds).
Test Case '-[KizbaTests.ImportConflictResolverTests testResolve_conflictSkip_returnsNil]' started.
Test Case '-[KizbaTests.ImportConflictResolverTests testResolve_conflictSkip_returnsNil]' passed (0.001 seconds).
Test Case '-[KizbaTests.ImportConflictResolverTests testResolve_noConflict_returnsCreate]' started.
Test Case '-[KizbaTests.ImportConflictResolverTests testResolve_noConflict_returnsCreate]' passed (0.029 seconds).
Test Suite 'ImportConflictResolverTests' passed at 2026-05-24 08:25:23.058.
	 Executed 6 tests, with 0 failures (0 unexpected) in 0.036 (0.057) seconds
Test Suite 'InfoTooltipTests' started at 2026-05-24 08:25:23.059.
Test Case '-[KizbaTests.InfoTooltipTests testDefaultInfoAccessibilityLabel_includesFieldLabel]' started.
Test Case '-[KizbaTests.InfoTooltipTests testDefaultInfoAccessibilityLabel_includesFieldLabel]' passed (0.002 seconds).
Test Case '-[KizbaTests.InfoTooltipTests testFormFieldRow_existingCallSitesRemainCompatible]' started.
Test Case '-[KizbaTests.InfoTooltipTests testFormFieldRow_existingCallSitesRemainCompatible]' passed (0.002 seconds).
Test Case '-[KizbaTests.InfoTooltipTests testFormFieldRow_initWithInfoText_isCallable]' started.
Test Case '-[KizbaTests.InfoTooltipTests testFormFieldRow_initWithInfoText_isCallable]' passed (0.001 seconds).
Test Case '-[KizbaTests.InfoTooltipTests testFormFieldRow_initWithInfoTextAndAccessibilityLabel_isCallable]' started.
Test Case '-[KizbaTests.InfoTooltipTests testFormFieldRow_initWithInfoTextAndAccessibilityLabel_isCallable]' passed (0.002 seconds).
Test Case '-[KizbaTests.InfoTooltipTests testInfoTooltip_initializesWithEmptyStrings]' started.
Test Case '-[KizbaTests.InfoTooltipTests testInfoTooltip_initializesWithEmptyStrings]' passed (0.001 seconds).
Test Case '-[KizbaTests.InfoTooltipTests testInfoTooltip_initializesWithoutTitle]' started.
Test Case '-[KizbaTests.InfoTooltipTests testInfoTooltip_initializesWithoutTitle]' passed (0.001 seconds).
Test Case '-[KizbaTests.InfoTooltipTests testInfoTooltip_initializesWithTitle]' started.
Test Case '-[KizbaTests.InfoTooltipTests testInfoTooltip_initializesWithTitle]' passed (0.001 seconds).
Test Case '-[KizbaTests.InfoTooltipTests testResolvedHelperText_errorWinsOverInfoAndHelp]' started.
Test Case '-[KizbaTests.InfoTooltipTests testResolvedHelperText_errorWinsOverInfoAndHelp]' passed (0.001 seconds).
Test Case '-[KizbaTests.InfoTooltipTests testResolvedHelperText_returnsErrorText_whenErrorIsSet]' started.
Test Case '-[KizbaTests.InfoTooltipTests testResolvedHelperText_returnsErrorText_whenErrorIsSet]' passed (0.002 seconds).
Test Case '-[KizbaTests.InfoTooltipTests testResolvedHelperText_returnsHelpText_whenOnlyHelpIsSet]' started.
Test Case '-[KizbaTests.InfoTooltipTests testResolvedHelperText_returnsHelpText_whenOnlyHelpIsSet]' passed (0.002 seconds).
Test Case '-[KizbaTests.InfoTooltipTests testResolvedHelperText_returnsNil_whenAllInputsAreNil]' started.
Test Case '-[KizbaTests.InfoTooltipTests testResolvedHelperText_returnsNil_whenAllInputsAreNil]' passed (0.001 seconds).
Test Case '-[KizbaTests.InfoTooltipTests testResolvedHelperText_suppressesHelpText_whenInfoTextIsSet]' started.
Test Case '-[KizbaTests.InfoTooltipTests testResolvedHelperText_suppressesHelpText_whenInfoTextIsSet]' passed (0.001 seconds).
Test Suite 'InfoTooltipTests' passed at 2026-05-24 08:25:23.099.
	 Executed 12 tests, with 0 failures (0 unexpected) in 0.017 (0.040) seconds
Test Suite 'InvocationLogTests' started at 2026-05-24 08:25:23.106.
Test Case '-[KizbaTests.InvocationLogTests testClear]' started.
Test Case '-[KizbaTests.InvocationLogTests testClear]' passed (0.003 seconds).
Test Case '-[KizbaTests.InvocationLogTests testInit_clampsZeroOrNegativeMaxEntries]' started.
Test Case '-[KizbaTests.InvocationLogTests testInit_clampsZeroOrNegativeMaxEntries]' passed (0.002 seconds).
Test Case '-[KizbaTests.InvocationLogTests testRecent_isEmptyInitially]' started.
Test Case '-[KizbaTests.InvocationLogTests testRecent_isEmptyInitially]' passed (0.001 seconds).
Test Case '-[KizbaTests.InvocationLogTests testRecent_newestFirst_underCap]' started.
Test Case '-[KizbaTests.InvocationLogTests testRecent_newestFirst_underCap]' passed (0.001 seconds).
Test Case '-[KizbaTests.InvocationLogTests testRecordAndRecent_limit]' started.
Test Case '-[KizbaTests.InvocationLogTests testRecordAndRecent_limit]' passed (0.014 seconds).
Test Suite 'InvocationLogTests' passed at 2026-05-24 08:25:23.130.
	 Executed 5 tests, with 0 failures (0 unexpected) in 0.021 (0.024) seconds
Test Suite 'KeyValueEditorAccessibilityTests' started at 2026-05-24 08:25:23.130.
Test Case '-[KizbaTests.KeyValueEditorAccessibilityTests testRowAccessibilityLabel_returnsOneIndexedString]' started.
Test Case '-[KizbaTests.KeyValueEditorAccessibilityTests testRowAccessibilityLabel_returnsOneIndexedString]' passed (0.002 seconds).
Test Suite 'KeyValueEditorAccessibilityTests' passed at 2026-05-24 08:25:23.133.
	 Executed 1 test, with 0 failures (0 unexpected) in 0.002 (0.003) seconds
Test Suite 'KizbaButtonStyleTests' started at 2026-05-24 08:25:23.133.
Test Case '-[KizbaTests.KizbaButtonStyleTests testBackgroundColor_destructive_isDangerInEveryThemeRegardlessOfPress]' started.
Test Case '-[KizbaTests.KizbaButtonStyleTests testBackgroundColor_destructive_isDangerInEveryThemeRegardlessOfPress]' passed (0.001 seconds).
Test Case '-[KizbaTests.KizbaButtonStyleTests testBackgroundColor_ghost_idleIsClearAndPressedIsLuminanceAwaySurface]' started.
Test Case '-[KizbaTests.KizbaButtonStyleTests testBackgroundColor_ghost_idleIsClearAndPressedIsLuminanceAwaySurface]' passed (0.002 seconds).
Test Case '-[KizbaTests.KizbaButtonStyleTests testBackgroundColor_ghost_pressStateChangesFill]' started.
Test Case '-[KizbaTests.KizbaButtonStyleTests testBackgroundColor_ghost_pressStateChangesFill]' passed (0.001 seconds).
Test Case '-[KizbaTests.KizbaButtonStyleTests testBackgroundColor_primary_isAccentInEveryThemeRegardlessOfPress]' started.
Test Case '-[KizbaTests.KizbaButtonStyleTests testBackgroundColor_primary_isAccentInEveryThemeRegardlessOfPress]' passed (0.002 seconds).
Test Case '-[KizbaTests.KizbaButtonStyleTests testBackgroundColor_secondary_isSurfaceElevatedInEveryThemeRegardlessOfPress]' started.
Test Case '-[KizbaTests.KizbaButtonStyleTests testBackgroundColor_secondary_isSurfaceElevatedInEveryThemeRegardlessOfPress]' passed (0.001 seconds).
Test Case '-[KizbaTests.KizbaButtonStyleTests testContrast_destructive_meetsAAInEveryTheme]' started.
Test Case '-[KizbaTests.KizbaButtonStyleTests testContrast_destructive_meetsAAInEveryTheme]' passed (0.001 seconds).
Test Case '-[KizbaTests.KizbaButtonStyleTests testContrast_ghost_idle_meetsAAAgainstSurface]' started.
Test Case '-[KizbaTests.KizbaButtonStyleTests testContrast_ghost_idle_meetsAAAgainstSurface]' passed (0.001 seconds).
Test Case '-[KizbaTests.KizbaButtonStyleTests testContrast_ghost_pressed_meetsAAAgainstLuminanceAwaySurface]' started.
Test Case '-[KizbaTests.KizbaButtonStyleTests testContrast_ghost_pressed_meetsAAAgainstLuminanceAwaySurface]' passed (0.001 seconds).
Test Case '-[KizbaTests.KizbaButtonStyleTests testContrast_primary_meetsAAInEveryTheme]' started.
Test Case '-[KizbaTests.KizbaButtonStyleTests testContrast_primary_meetsAAInEveryTheme]' passed (0.001 seconds).
Test Case '-[KizbaTests.KizbaButtonStyleTests testContrast_secondary_meetsAAOnSurfaceElevated]' started.
Test Case '-[KizbaTests.KizbaButtonStyleTests testContrast_secondary_meetsAAOnSurfaceElevated]' passed (0.010 seconds).
Test Case '-[KizbaTests.KizbaButtonStyleTests testCornerRadius_regular_isRadiusMd_compactIsRadiusSm]' started.
Test Case '-[KizbaTests.KizbaButtonStyleTests testCornerRadius_regular_isRadiusMd_compactIsRadiusSm]' passed (0.001 seconds).
Test Case '-[KizbaTests.KizbaButtonStyleTests testDisabledOpacity_isAtMost60Percent]' started.
Test Case '-[KizbaTests.KizbaButtonStyleTests testDisabledOpacity_isAtMost60Percent]' passed (0.001 seconds).
Test Case '-[KizbaTests.KizbaButtonStyleTests testFont_filledVariants_useBodyEmphasized]' started.
Test Case '-[KizbaTests.KizbaButtonStyleTests testFont_filledVariants_useBodyEmphasized]' passed (0.001 seconds).
Test Case '-[KizbaTests.KizbaButtonStyleTests testFont_lightVariants_useBody]' started.
Test Case '-[KizbaTests.KizbaButtonStyleTests testFont_lightVariants_useBody]' passed (0.001 seconds).
Test Case '-[KizbaTests.KizbaButtonStyleTests testForegroundColor_destructive_isOnDangerInEveryTheme]' started.
Test Case '-[KizbaTests.KizbaButtonStyleTests testForegroundColor_destructive_isOnDangerInEveryTheme]' passed (0.015 seconds).
Test Case '-[KizbaTests.KizbaButtonStyleTests testForegroundColor_ghost_isAccentInEveryTheme]' started.
Test Case '-[KizbaTests.KizbaButtonStyleTests testForegroundColor_ghost_isAccentInEveryTheme]' passed (0.001 seconds).
Test Case '-[KizbaTests.KizbaButtonStyleTests testForegroundColor_primary_isOnAccentInEveryTheme]' started.
Test Case '-[KizbaTests.KizbaButtonStyleTests testForegroundColor_primary_isOnAccentInEveryTheme]' passed (0.002 seconds).
Test Case '-[KizbaTests.KizbaButtonStyleTests testForegroundColor_secondary_isAccentInEveryTheme]' started.
Test Case '-[KizbaTests.KizbaButtonStyleTests testForegroundColor_secondary_isAccentInEveryTheme]' passed (0.001 seconds).
Test Case '-[KizbaTests.KizbaButtonStyleTests testHasAccentBorder_onlySecondaryDrawsBorder]' started.
Test Case '-[KizbaTests.KizbaButtonStyleTests testHasAccentBorder_onlySecondaryDrawsBorder]' passed (0.001 seconds).
Test Case '-[KizbaTests.KizbaButtonStyleTests testPadding_compact_mapsToSpacingXsAndMd]' started.
Test Case '-[KizbaTests.KizbaButtonStyleTests testPadding_compact_mapsToSpacingXsAndMd]' passed (0.002 seconds).
Test Case '-[KizbaTests.KizbaButtonStyleTests testPadding_regular_mapsToSpacingSmAndLg]' started.
Test Case '-[KizbaTests.KizbaButtonStyleTests testPadding_regular_mapsToSpacingSmAndLg]' passed (0.002 seconds).
Test Case '-[KizbaTests.KizbaButtonStyleTests testSize_allCases_containsExactlyTwoSizes]' started.
Test Case '-[KizbaTests.KizbaButtonStyleTests testSize_allCases_containsExactlyTwoSizes]' passed (0.001 seconds).
Test Case '-[KizbaTests.KizbaButtonStyleTests testVariant_allCases_containsExactlyFourVariants]' started.
Test Case '-[KizbaTests.KizbaButtonStyleTests testVariant_allCases_containsExactlyFourVariants]' passed (0.001 seconds).
Test Suite 'KizbaButtonStyleTests' passed at 2026-05-24 08:25:23.210.
	 Executed 23 tests, with 0 failures (0 unexpected) in 0.047 (0.076) seconds
Test Suite 'KizbaCardTests' started at 2026-05-24 08:25:23.221.
Test Case '-[KizbaTests.KizbaCardTests testBackgroundColor_isSurfaceElevatedInEveryTheme]' started.
Test Case '-[KizbaTests.KizbaCardTests testBackgroundColor_isSurfaceElevatedInEveryTheme]' passed (0.002 seconds).
Test Case '-[KizbaTests.KizbaCardTests testBorderColor_isDividerInEveryTheme]' started.
Test Case '-[KizbaTests.KizbaCardTests testBorderColor_isDividerInEveryTheme]' passed (0.002 seconds).
Test Case '-[KizbaTests.KizbaCardTests testContrast_onSurfaceVsCardBackground_meetsAAInEveryTheme]' started.
Test Case '-[KizbaTests.KizbaCardTests testContrast_onSurfaceVsCardBackground_meetsAAInEveryTheme]' passed (0.001 seconds).
Test Case '-[KizbaTests.KizbaCardTests testCornerRadius_isRadiusLgInEveryTheme]' started.
Test Case '-[KizbaTests.KizbaCardTests testCornerRadius_isRadiusLgInEveryTheme]' passed (0.001 seconds).
Test Case '-[KizbaTests.KizbaCardTests testPadding_isSpacingLgInEveryTheme]' started.
Test Case '-[KizbaTests.KizbaCardTests testPadding_isSpacingLgInEveryTheme]' passed (0.008 seconds).
Test Suite 'KizbaCardTests' passed at 2026-05-24 08:25:23.237.
	 Executed 5 tests, with 0 failures (0 unexpected) in 0.013 (0.016) seconds
Test Suite 'KizbaFocusRingTests' started at 2026-05-24 08:25:23.238.
Test Case '-[KizbaTests.KizbaFocusRingTests testInnerColor_isFocusRingInnerInEveryTheme]' started.
Test Case '-[KizbaTests.KizbaFocusRingTests testInnerColor_isFocusRingInnerInEveryTheme]' passed (0.002 seconds).
Test Case '-[KizbaTests.KizbaFocusRingTests testInnerCornerRadius_clampsAtZero_whenOuterRadiusIsTooSmall]' started.
Test Case '-[KizbaTests.KizbaFocusRingTests testInnerCornerRadius_clampsAtZero_whenOuterRadiusIsTooSmall]' passed (0.001 seconds).
Test Case '-[KizbaTests.KizbaFocusRingTests testInnerCornerRadius_normalGeometry_subtractsOuterWidth]' started.
Test Case '-[KizbaTests.KizbaFocusRingTests testInnerCornerRadius_normalGeometry_subtractsOuterWidth]' passed (0.001 seconds).
Test Case '-[KizbaTests.KizbaFocusRingTests testInnerCornerRadius_zeroOuterWidth_returnsOuterRadius]' started.
Test Case '-[KizbaTests.KizbaFocusRingTests testInnerCornerRadius_zeroOuterWidth_returnsOuterRadius]' passed (0.001 seconds).
Test Case '-[KizbaTests.KizbaFocusRingTests testOuterColor_isFocusRingOuterInEveryTheme]' started.
Test Case '-[KizbaTests.KizbaFocusRingTests testOuterColor_isFocusRingOuterInEveryTheme]' passed (0.001 seconds).
Test Suite 'KizbaFocusRingTests' passed at 2026-05-24 08:25:23.249.
	 Executed 5 tests, with 0 failures (0 unexpected) in 0.005 (0.011) seconds
Test Suite 'KizbaNightContrastTests' started at 2026-05-24 08:25:23.249.
Test Case '-[KizbaTests.KizbaNightContrastTests testKizbaNight_onAccent_against_accent_and_accentSecondary_meet_AA]' started.
Test Case '-[KizbaTests.KizbaNightContrastTests testKizbaNight_onAccent_against_accent_and_accentSecondary_meet_AA]' passed (0.001 seconds).
Test Case '-[KizbaTests.KizbaNightContrastTests testKizbaNight_onAccent_against_accentMuted_meet_AA]' started.
/Users/kirillsimagin/dev/my/worldproject/kizba/KizbaTests/KizbaNightContrastTests.swift:85: error: -[KizbaTests.KizbaNightContrastTests testKizbaNight_onAccent_against_accentMuted_meet_AA] : XCTAssertGreaterThanOrEqual failed: ("1.8838768382268365") is less than ("4.5") - onAccent/accentMuted for light below AA: 1.8838768382268365
/Users/kirillsimagin/dev/my/worldproject/kizba/KizbaTests/KizbaNightContrastTests.swift:85: error: -[KizbaTests.KizbaNightContrastTests testKizbaNight_onAccent_against_accentMuted_meet_AA] : XCTAssertGreaterThanOrEqual failed: ("1.8838768382268365") is less than ("4.5") - onAccent/accentMuted for lightHighContrast below AA: 1.8838768382268365
Test Case '-[KizbaTests.KizbaNightContrastTests testKizbaNight_onAccent_against_accentMuted_meet_AA]' failed (4.908 seconds).
Test Case '-[KizbaTests.KizbaNightContrastTests testKizbaNight_onSurface_and_onSurface_over_surface_and_surfaceCard_meet_contrast_requirements]' started.
Test Case '-[KizbaTests.KizbaNightContrastTests testKizbaNight_onSurface_and_onSurface_over_surface_and_surfaceCard_meet_contrast_requirements]' passed (0.001 seconds).
Test Case '-[KizbaTests.KizbaNightContrastTests testKizbaNight_onSurfaceMuted_over_surface_and_surfaceCard_meet_AA]' started.
Test Case '-[KizbaTests.KizbaNightContrastTests testKizbaNight_onSurfaceMuted_over_surface_and_surfaceCard_meet_AA]' passed (0.000 seconds).
Test Case '-[KizbaTests.KizbaNightContrastTests testSmoke_referencesStep1Tokens]' started.
Test Case '-[KizbaTests.KizbaNightContrastTests testSmoke_referencesStep1Tokens]' passed (0.000 seconds).
Test Suite 'KizbaNightContrastTests' failed at 2026-05-24 08:25:28.161.
	 Executed 5 tests, with 2 failures (0 unexpected) in 4.910 (4.911) seconds
Test Suite 'KizbaTests' started at 2026-05-24 08:25:28.161.
Test Case '-[KizbaTests.KizbaTests testExample]' started.
Test Case '-[KizbaTests.KizbaTests testExample]' passed (0.009 seconds).
Test Case '-[KizbaTests.KizbaTests testPerformanceExample]' started.
/Users/kirillsimagin/dev/my/worldproject/kizba/KizbaTests/KizbaTests.swift:33: Test Case '-[KizbaTests.KizbaTests testPerformanceExample]' measured [Time, seconds] average: 0.000, relative standard deviation: 85.195%, values: [0.000060, 0.000028, 0.000017, 0.000009, 0.000008, 0.000011, 0.000008, 0.000008, 0.000045, 0.000009], performanceMetricID:com.apple.XCTPerformanceMetric_WallClockTime, baselineName: "", baselineAverage: , polarity: prefers smaller, maxPercentRegression: 10.000%, maxPercentRelativeStandardDeviation: 10.000%, maxRegression: 0.100, maxStandardDeviation: 0.100
Test Case '-[KizbaTests.KizbaTests testPerformanceExample]' passed (0.255 seconds).
Test Suite 'KizbaTests' passed at 2026-05-24 08:25:28.426.
	 Executed 2 tests, with 0 failures (0 unexpected) in 0.264 (0.265) seconds
Test Suite 'LiveOTPGeneratorTests' started at 2026-05-24 08:25:28.426.
Test Case '-[KizbaTests.LiveOTPGeneratorTests testHOTP_rfc4226Counters0to9]' started.
Test Case '-[KizbaTests.LiveOTPGeneratorTests testHOTP_rfc4226Counters0to9]' passed (0.002 seconds).
Test Case '-[KizbaTests.LiveOTPGeneratorTests testInvalidBase32_returnsZeros]' started.
Test Case '-[KizbaTests.LiveOTPGeneratorTests testInvalidBase32_returnsZeros]' passed (0.001 seconds).
Test Case '-[KizbaTests.LiveOTPGeneratorTests testTOTP_SHA1_rfc6238Vectors]' started.
Test Case '-[KizbaTests.LiveOTPGeneratorTests testTOTP_SHA1_rfc6238Vectors]' passed (0.001 seconds).
Test Case '-[KizbaTests.LiveOTPGeneratorTests testTOTP_SHA256_rfc6238Vectors]' started.
Test Case '-[KizbaTests.LiveOTPGeneratorTests testTOTP_SHA256_rfc6238Vectors]' passed (0.001 seconds).
Test Case '-[KizbaTests.LiveOTPGeneratorTests testTOTP_SHA512_rfc6238Vectors]' started.
Test Case '-[KizbaTests.LiveOTPGeneratorTests testTOTP_SHA512_rfc6238Vectors]' passed (0.001 seconds).
Test Suite 'LiveOTPGeneratorTests' passed at 2026-05-24 08:25:28.434.
	 Executed 5 tests, with 0 failures (0 unexpected) in 0.005 (0.008) seconds
Test Suite 'LivePassGitManagerTests' started at 2026-05-24 08:25:28.434.
Test Case '-[KizbaTests.LivePassGitManagerTests testPull_authFailed_throwsGitAuthFailed]' started.
Test Case '-[KizbaTests.LivePassGitManagerTests testPull_authFailed_throwsGitAuthFailed]' passed (0.004 seconds).
Test Case '-[KizbaTests.LivePassGitManagerTests testPull_cancellation_propagates]' started.
Test Case '-[KizbaTests.LivePassGitManagerTests testPull_cancellation_propagates]' passed (0.001 seconds).
Test Case '-[KizbaTests.LivePassGitManagerTests testPull_conflict_throwsGitConflict]' started.
Test Case '-[KizbaTests.LivePassGitManagerTests testPull_conflict_throwsGitConflict]' passed (0.005 seconds).
Test Case '-[KizbaTests.LivePassGitManagerTests testPull_happyPath_succeeds]' started.
Test Case '-[KizbaTests.LivePassGitManagerTests testPull_happyPath_succeeds]' passed (0.004 seconds).
Test Case '-[KizbaTests.LivePassGitManagerTests testPull_networkUnavailable_throwsGitNetworkUnavailable]' started.
Test Case '-[KizbaTests.LivePassGitManagerTests testPull_networkUnavailable_throwsGitNetworkUnavailable]' passed (0.004 seconds).
Test Case '-[KizbaTests.LivePassGitManagerTests testPush_alreadyUpToDate_returnsAlreadyUpToDate]' started.
Test Case '-[KizbaTests.LivePassGitManagerTests testPush_alreadyUpToDate_returnsAlreadyUpToDate]' passed (0.003 seconds).
Test Case '-[KizbaTests.LivePassGitManagerTests testPush_authFailed_throwsGitAuthFailed]' started.
Test Case '-[KizbaTests.LivePassGitManagerTests testPush_authFailed_throwsGitAuthFailed]' passed (0.003 seconds).
Test Case '-[KizbaTests.LivePassGitManagerTests testPush_cancellation_propagates]' started.
Test Case '-[KizbaTests.LivePassGitManagerTests testPush_cancellation_propagates]' passed (0.003 seconds).
Test Case '-[KizbaTests.LivePassGitManagerTests testPush_happyPath_returnsPushed]' started.
Test Case '-[KizbaTests.LivePassGitManagerTests testPush_happyPath_returnsPushed]' passed (0.001 seconds).
Test Case '-[KizbaTests.LivePassGitManagerTests testPush_rejected_throwsGitRejected]' started.
Test Case '-[KizbaTests.LivePassGitManagerTests testPush_rejected_throwsGitRejected]' passed (0.106 seconds).
Test Case '-[KizbaTests.LivePassGitManagerTests testStatus_arbitraryError_throwsMappedPassError]' started.
Test Case '-[KizbaTests.LivePassGitManagerTests testStatus_arbitraryError_throwsMappedPassError]' passed (0.004 seconds).
Test Case '-[KizbaTests.LivePassGitManagerTests testStatus_happyPath_returnsParsedGitStatus]' started.
Test Case '-[KizbaTests.LivePassGitManagerTests testStatus_happyPath_returnsParsedGitStatus]' passed (0.003 seconds).
Test Case '-[KizbaTests.LivePassGitManagerTests testStatus_networkError_throwsMappedPassError]' started.
Test Case '-[KizbaTests.LivePassGitManagerTests testStatus_networkError_throwsMappedPassError]' passed (0.003 seconds).
Test Case '-[KizbaTests.LivePassGitManagerTests testStatus_noRemote_hasRemoteFalse_hasUpstreamFalse]' started.
Test Case '-[KizbaTests.LivePassGitManagerTests testStatus_noRemote_hasRemoteFalse_hasUpstreamFalse]' passed (0.004 seconds).
Test Case '-[KizbaTests.LivePassGitManagerTests testStatus_notARepo_returnsNotARepository]' started.
Test Case '-[KizbaTests.LivePassGitManagerTests testStatus_notARepo_returnsNotARepository]' passed (0.004 seconds).
Test Case '-[KizbaTests.LivePassGitManagerTests testStatus_remoteWithoutUpstream_hasRemoteTrue_hasUpstreamFalse]' started.
Test Case '-[KizbaTests.LivePassGitManagerTests testStatus_remoteWithoutUpstream_hasRemoteTrue_hasUpstreamFalse]' passed (0.104 seconds).
Test Suite 'LivePassGitManagerTests' passed at 2026-05-24 08:25:28.699.
	 Executed 16 tests, with 0 failures (0 unexpected) in 0.255 (0.265) seconds
Test Suite 'LivePassManagerFSEventsTests' started at 2026-05-24 08:25:28.700.
Test Case '-[KizbaTests.LivePassManagerFSEventsTests testWatcher_doesNotStartTwiceOnSecondSubscriber]' started.
Test Case '-[KizbaTests.LivePassManagerFSEventsTests testWatcher_doesNotStartTwiceOnSecondSubscriber]' passed (0.034 seconds).
Test Case '-[KizbaTests.LivePassManagerFSEventsTests testWatcher_emitsBulkOnSimulateChange]' started.
Test Case '-[KizbaTests.LivePassManagerFSEventsTests testWatcher_emitsBulkOnSimulateChange]' passed (1.087 seconds).
Test Case '-[KizbaTests.LivePassManagerFSEventsTests testWatcher_lazyStartsOnFirstSubscriber]' started.
Test Case '-[KizbaTests.LivePassManagerFSEventsTests testWatcher_lazyStartsOnFirstSubscriber]' passed (0.024 seconds).
Test Case '-[KizbaTests.LivePassManagerFSEventsTests testWatcher_multipleEmitsDeliveredToAllSubscribers]' started.
Test Case '-[KizbaTests.LivePassManagerFSEventsTests testWatcher_multipleEmitsDeliveredToAllSubscribers]' passed (2.122 seconds).
Test Case '-[KizbaTests.LivePassManagerFSEventsTests testWatcher_stopDoesNotCrashIfNoSubscribers]' started.
Test Case '-[KizbaTests.LivePassManagerFSEventsTests testWatcher_stopDoesNotCrashIfNoSubscribers]' passed (0.002 seconds).
Test Case '-[KizbaTests.LivePassManagerFSEventsTests testWatcher_stopsOnLastUnsubscribe]' started.
Test Case '-[KizbaTests.LivePassManagerFSEventsTests testWatcher_stopsOnLastUnsubscribe]' passed (0.096 seconds).
Test Suite 'LivePassManagerFSEventsTests' passed at 2026-05-24 08:25:32.068.
	 Executed 6 tests, with 0 failures (0 unexpected) in 3.364 (3.368) seconds
Test Suite 'LivePassManagerStoreOverrideTests' started at 2026-05-24 08:25:32.069.
Test Case '-[KizbaTests.LivePassManagerStoreOverrideTests testNoStoreOverride_passwordStoreDirIsDefaultRoot]' started.
2026-05-24 08:25:32.072515+0200 Kizba[11882:1070620] [pass] pass show ok: exe=/opt/homebrew/bin/pass argc=2 status=0 stderrBytes=0
Test Case '-[KizbaTests.LivePassManagerStoreOverrideTests testNoStoreOverride_passwordStoreDirIsDefaultRoot]' passed (0.004 seconds).
Test Case '-[KizbaTests.LivePassManagerStoreOverrideTests testStoreLocation_readsLiveProvider]' started.
Test Case '-[KizbaTests.LivePassManagerStoreOverrideTests testStoreLocation_readsLiveProvider]' passed (0.002 seconds).
Test Case '-[KizbaTests.LivePassManagerStoreOverrideTests testStoreOverride_isReadLivePerCall]' started.
2026-05-24 08:25:32.078447+0200 Kizba[11882:1070611] [pass] pass show ok: exe=/opt/homebrew/bin/pass argc=2 status=0 stderrBytes=0
2026-05-24 08:25:32.078879+0200 Kizba[11882:1070619] [pass] pass show ok: exe=/opt/homebrew/bin/pass argc=2 status=0 stderrBytes=0
Test Case '-[KizbaTests.LivePassManagerStoreOverrideTests testStoreOverride_isReadLivePerCall]' passed (0.003 seconds).
Test Case '-[KizbaTests.LivePassManagerStoreOverrideTests testStoreOverride_propagatesToPasswordStoreDirEnv]' started.
2026-05-24 08:25:32.082219+0200 Kizba[11882:1071152] [pass] pass show ok: exe=/opt/homebrew/bin/pass argc=2 status=0 stderrBytes=0
Test Case '-[KizbaTests.LivePassManagerStoreOverrideTests testStoreOverride_propagatesToPasswordStoreDirEnv]' passed (0.003 seconds).
Test Suite 'LivePassManagerStoreOverrideTests' passed at 2026-05-24 08:25:32.084.
	 Executed 4 tests, with 0 failures (0 unexpected) in 0.012 (0.015) seconds
Test Suite 'LivePassManagerTests' started at 2026-05-24 08:25:32.084.
Test Case '-[KizbaTests.LivePassManagerTests testListEntries_delegatesToScannerAndMapsToPassEntries]' started.
Test Case '-[KizbaTests.LivePassManagerTests testListEntries_delegatesToScannerAndMapsToPassEntries]' passed (0.002 seconds).
Test Case '-[KizbaTests.LivePassManagerTests testListEntries_emptyStoreReturnsEmpty]' started.
Test Case '-[KizbaTests.LivePassManagerTests testListEntries_emptyStoreReturnsEmpty]' passed (0.002 seconds).
Test Case '-[KizbaTests.LivePassManagerTests testShow_delegatesToPassCLIWithEntryPath]' started.
2026-05-24 08:25:32.091324+0200 Kizba[11882:1070614] [pass] pass show ok: exe=/opt/homebrew/bin/pass argc=2 status=0 stderrBytes=0
Test Case '-[KizbaTests.LivePassManagerTests testShow_delegatesToPassCLIWithEntryPath]' passed (0.001 seconds).
Test Case '-[KizbaTests.LivePassManagerTests testStoreLocation_defaultRootMatchesHomePasswordStore]' started.
Test Case '-[KizbaTests.LivePassManagerTests testStoreLocation_defaultRootMatchesHomePasswordStore]' passed (0.007 seconds).
Test Case '-[KizbaTests.LivePassManagerTests testStoreLocation_returnsInjectedRoot]' started.
Test Case '-[KizbaTests.LivePassManagerTests testStoreLocation_returnsInjectedRoot]' passed (0.001 seconds).
Test Suite 'LivePassManagerTests' passed at 2026-05-24 08:25:32.100.
	 Executed 5 tests, with 0 failures (0 unexpected) in 0.013 (0.016) seconds
Test Suite 'LivePassManagerWriteTests' started at 2026-05-24 08:25:32.100.
Test Case '-[KizbaTests.LivePassManagerWriteTests testChanges_droppedSubscriber_doesNotBlockOthers]' started.
2026-05-24 08:25:32.133623+0200 Kizba[11882:1070534] [pass] pass insert ok: exe=/opt/homebrew/bin/pass argc=3 status=0 bytesIn=2 stderrBytes=0
2026-05-24 08:25:32.515261+0200 Kizba[11882:1070534] [pass] pass insert ok: exe=/opt/homebrew/bin/pass argc=3 status=0 bytesIn=2 stderrBytes=0
Test Case '-[KizbaTests.LivePassManagerWriteTests testChanges_droppedSubscriber_doesNotBlockOthers]' passed (0.660 seconds).
Test Case '-[KizbaTests.LivePassManagerWriteTests testChanges_multipleSubscribers_eachReceivesEveryEvent]' started.
2026-05-24 08:25:32.793171+0200 Kizba[11882:1070534] [pass] pass insert ok: exe=/opt/homebrew/bin/pass argc=3 status=0 bytesIn=2 stderrBytes=0
Test Case '-[KizbaTests.LivePassManagerWriteTests testChanges_multipleSubscribers_eachReceivesEveryEvent]' passed (0.349 seconds).
Test Case '-[KizbaTests.LivePassManagerWriteTests testGenerate_existingPathWithForce_emitsUpdated]' started.
2026-05-24 08:25:33.133079+0200 Kizba[11882:1070534] [pass] pass generate ok: exe=/opt/homebrew/bin/pass argc=5 status=0 stdoutBytes=53 stderrBytes=0
Test Case '-[KizbaTests.LivePassManagerWriteTests testGenerate_existingPathWithForce_emitsUpdated]' passed (0.125 seconds).
Test Case '-[KizbaTests.LivePassManagerWriteTests testGenerate_failure_throwsAndEmitsNothing]' started.
2026-05-24 08:25:33.259120+0200 Kizba[11882:1070534] [pass] pass generate failed: exe=/opt/homebrew/bin/pass argc=3 status=1 bytesIn=0 stderrBytes=53 excerpt=Error: pass-length "abc" must be a positive integer.
Test Case '-[KizbaTests.LivePassManagerWriteTests testGenerate_failure_throwsAndEmitsNothing]' passed (0.109 seconds).
Test Case '-[KizbaTests.LivePassManagerWriteTests testGenerate_newPath_returnsSecretAndEmitsInserted]' started.
2026-05-24 08:25:33.368003+0200 Kizba[11882:1070534] [pass] pass generate ok: exe=/opt/homebrew/bin/pass argc=3 status=0 stdoutBytes=53 stderrBytes=0
Test Case '-[KizbaTests.LivePassManagerWriteTests testGenerate_newPath_returnsSecretAndEmitsInserted]' passed (0.124 seconds).
Test Case '-[KizbaTests.LivePassManagerWriteTests testInsert_existingPath_emitsUpdated]' started.
2026-05-24 08:25:33.492272+0200 Kizba[11882:1070534] [pass] pass insert ok: exe=/opt/homebrew/bin/pass argc=4 status=0 bytesIn=8 stderrBytes=0
Test Case '-[KizbaTests.LivePassManagerWriteTests testInsert_existingPath_emitsUpdated]' passed (0.124 seconds).
Test Case '-[KizbaTests.LivePassManagerWriteTests testInsert_failure_throwsAndEmitsNothing]' started.
2026-05-24 08:25:33.618493+0200 Kizba[11882:1070534] [pass] pass insert failed: exe=/opt/homebrew/bin/pass argc=3 status=1 bytesIn=2 stderrBytes=31 excerpt=Error: new/foo already exists.
Test Case '-[KizbaTests.LivePassManagerWriteTests testInsert_failure_throwsAndEmitsNothing]' passed (0.105 seconds).
Test Case '-[KizbaTests.LivePassManagerWriteTests testInsert_newPath_emitsInsertedAndInvalidatesScanner]' started.
2026-05-24 08:25:33.724210+0200 Kizba[11882:1070534] [pass] pass insert ok: exe=/opt/homebrew/bin/pass argc=3 status=0 bytesIn=8 stderrBytes=0
Test Case '-[KizbaTests.LivePassManagerWriteTests testInsert_newPath_emitsInsertedAndInvalidatesScanner]' passed (0.126 seconds).
Test Case '-[KizbaTests.LivePassManagerWriteTests testInsert_stdinCarriesSerialisedBody]' started.
2026-05-24 08:25:33.829487+0200 Kizba[11882:1070534] [pass] pass insert ok: exe=/opt/homebrew/bin/pass argc=3 status=0 bytesIn=40 stderrBytes=0
Test Case '-[KizbaTests.LivePassManagerWriteTests testInsert_stdinCarriesSerialisedBody]' passed (0.003 seconds).
Test Case '-[KizbaTests.LivePassManagerWriteTests testMove_emitsMovedAndReturnsNewEntry]' started.
2026-05-24 08:25:33.854563+0200 Kizba[11882:1070534] [pass] pass mv ok: exe=/opt/homebrew/bin/pass argc=3 status=0 stderrBytes=0
Test Case '-[KizbaTests.LivePassManagerWriteTests testMove_emitsMovedAndReturnsNewEntry]' passed (0.126 seconds).
Test Case '-[KizbaTests.LivePassManagerWriteTests testMove_targetCollision_throwsAndEmitsNothing]' started.
2026-05-24 08:25:33.981968+0200 Kizba[11882:1070534] [pass] pass mv failed: exe=/opt/homebrew/bin/pass argc=3 status=1 bytesIn=0 stderrBytes=59 excerpt=mv: refusing to overwrite '/store/.password-store/c/d.gpg'
Test Case '-[KizbaTests.LivePassManagerWriteTests testMove_targetCollision_throwsAndEmitsNothing]' passed (0.108 seconds).
Test Case '-[KizbaTests.LivePassManagerWriteTests testRemove_emitsRemovedAndInvalidates]' started.
2026-05-24 08:25:34.089709+0200 Kizba[11882:1070534] [pass] pass rm ok: exe=/opt/homebrew/bin/pass argc=3 status=0 stderrBytes=0
Test Case '-[KizbaTests.LivePassManagerWriteTests testRemove_emitsRemovedAndInvalidates]' passed (0.126 seconds).
Test Case '-[KizbaTests.LivePassManagerWriteTests testRemove_failure_throwsAndEmitsNothing]' started.
2026-05-24 08:25:34.216994+0200 Kizba[11882:1070534] [pass] pass rm failed: exe=/opt/homebrew/bin/pass argc=3 status=1 bytesIn=0 stderrBytes=46 excerpt=Error: gone/foo is not in the password store.
Test Case '-[KizbaTests.LivePassManagerWriteTests testRemove_failure_throwsAndEmitsNothing]' passed (0.108 seconds).
Test Suite 'LivePassManagerWriteTests' passed at 2026-05-24 08:25:34.301.
	 Executed 13 tests, with 0 failures (0 unexpected) in 2.192 (2.201) seconds
Test Suite 'LivePasswordGeneratorTests' started at 2026-05-24 08:25:34.302.
Test Case '-[KizbaTests.LivePasswordGeneratorTests testGenerate_anyMode_neverContainsWhitespaceOrControlOrNonASCII]' started.
Test Case '-[KizbaTests.LivePasswordGeneratorTests testGenerate_anyMode_neverContainsWhitespaceOrControlOrNonASCII]' passed (0.013 seconds).
Test Case '-[KizbaTests.LivePasswordGeneratorTests testGenerate_length128_returns128Characters]' started.
Test Case '-[KizbaTests.LivePasswordGeneratorTests testGenerate_length128_returns128Characters]' passed (0.001 seconds).
Test Case '-[KizbaTests.LivePasswordGeneratorTests testGenerate_length16_returns16Characters]' started.
Test Case '-[KizbaTests.LivePasswordGeneratorTests testGenerate_length16_returns16Characters]' passed (0.001 seconds).
Test Case '-[KizbaTests.LivePasswordGeneratorTests testGenerate_lengthOne_returnsSingleCharacter]' started.
Test Case '-[KizbaTests.LivePasswordGeneratorTests testGenerate_lengthOne_returnsSingleCharacter]' passed (0.001 seconds).
Test Case '-[KizbaTests.LivePasswordGeneratorTests testGenerate_lengthZero_throwsInvalidLength]' started.
Test Case '-[KizbaTests.LivePasswordGeneratorTests testGenerate_lengthZero_throwsInvalidLength]' passed (0.001 seconds).
Test Case '-[KizbaTests.LivePasswordGeneratorTests testGenerate_negativeLength_throwsInvalidLengthCarryingValue]' started.
Test Case '-[KizbaTests.LivePasswordGeneratorTests testGenerate_negativeLength_throwsInvalidLengthCarryingValue]' passed (0.001 seconds).
Test Case '-[KizbaTests.LivePasswordGeneratorTests testGenerate_repeatedCalls_produceDistinctPasswords]' started.
Test Case '-[KizbaTests.LivePasswordGeneratorTests testGenerate_repeatedCalls_produceDistinctPasswords]' passed (0.001 seconds).
Test Case '-[KizbaTests.LivePasswordGeneratorTests testGenerate_withoutSymbols_onlyContainsAlphanumeric]' started.
Test Case '-[KizbaTests.LivePasswordGeneratorTests testGenerate_withoutSymbols_onlyContainsAlphanumeric]' passed (0.007 seconds).
Test Case '-[KizbaTests.LivePasswordGeneratorTests testGenerate_withSymbols_canActuallyEmitSymbols]' started.
Test Case '-[KizbaTests.LivePasswordGeneratorTests testGenerate_withSymbols_canActuallyEmitSymbols]' passed (0.011 seconds).
Test Case '-[KizbaTests.LivePasswordGeneratorTests testGenerate_withSymbols_onlyContainsAlphanumericOrSymbols]' started.
Test Case '-[KizbaTests.LivePasswordGeneratorTests testGenerate_withSymbols_onlyContainsAlphanumericOrSymbols]' passed (0.006 seconds).
Test Case '-[KizbaTests.LivePasswordGeneratorTests testStatisticalBias_alphanumeric_isWithinReasonableBounds_smoke]' started.
Test Case '-[KizbaTests.LivePasswordGeneratorTests testStatisticalBias_alphanumeric_isWithinReasonableBounds_smoke]' passed (0.062 seconds).
Test Case '-[KizbaTests.LivePasswordGeneratorTests testStatisticalBias_alphanumericPlusSymbols_isWithinReasonableBounds_smoke]' started.
Test Case '-[KizbaTests.LivePasswordGeneratorTests testStatisticalBias_alphanumericPlusSymbols_isWithinReasonableBounds_smoke]' passed (0.052 seconds).
Test Suite 'LivePasswordGeneratorTests' passed at 2026-05-24 08:25:34.462.
	 Executed 12 tests, with 0 failures (0 unexpected) in 0.156 (0.161) seconds
Test Suite 'LiveSearchEngineTests' started at 2026-05-24 08:25:34.463.
Test Case '-[KizbaTests.LiveSearchEngineTests testSearch_boostDoesNotExceedOne]' started.
Test Case '-[KizbaTests.LiveSearchEngineTests testSearch_boostDoesNotExceedOne]' passed (0.001 seconds).
Test Case '-[KizbaTests.LiveSearchEngineTests testSearch_emptyQueryReturnsEmpty]' started.
Test Case '-[KizbaTests.LiveSearchEngineTests testSearch_emptyQueryReturnsEmpty]' passed (0.001 seconds).
Test Case '-[KizbaTests.LiveSearchEngineTests testSearch_exactMatchScoresHighest]' started.
Test Case '-[KizbaTests.LiveSearchEngineTests testSearch_exactMatchScoresHighest]' passed (0.001 seconds).
Test Case '-[KizbaTests.LiveSearchEngineTests testSearch_favoriteAndRecentBoostStack]' started.
Test Case '-[KizbaTests.LiveSearchEngineTests testSearch_favoriteAndRecentBoostStack]' passed (0.001 seconds).
Test Case '-[KizbaTests.LiveSearchEngineTests testSearch_favoriteGetsBoost]' started.
Test Case '-[KizbaTests.LiveSearchEngineTests testSearch_favoriteGetsBoost]' passed (0.001 seconds).
Test Case '-[KizbaTests.LiveSearchEngineTests testSearch_noContextSameAsBefore]' started.
Test Case '-[KizbaTests.LiveSearchEngineTests testSearch_noContextSameAsBefore]' passed (0.102 seconds).
Test Case '-[KizbaTests.LiveSearchEngineTests testSearch_recentGetsBoost]' started.
Test Case '-[KizbaTests.LiveSearchEngineTests testSearch_recentGetsBoost]' passed (0.001 seconds).
Test Case '-[KizbaTests.LiveSearchEngineTests testSearch_returnsResultsForMatchingQuery]' started.
Test Case '-[KizbaTests.LiveSearchEngineTests testSearch_returnsResultsForMatchingQuery]' passed (0.001 seconds).
Test Suite 'LiveSearchEngineTests' passed at 2026-05-24 08:25:34.575.
	 Executed 8 tests, with 0 failures (0 unexpected) in 0.110 (0.112) seconds
Test Suite 'LocalAuthBiometricAuthenticatorTests' started at 2026-05-24 08:25:34.575.
Test Case '-[KizbaTests.LocalAuthBiometricAuthenticatorTests testIsAvailable_and_authenticate_useContextPerCall_smokeConformance]' started.
Test Case '-[KizbaTests.LocalAuthBiometricAuthenticatorTests testIsAvailable_and_authenticate_useContextPerCall_smokeConformance]' passed (3.035 seconds).
Test Case '-[KizbaTests.LocalAuthBiometricAuthenticatorTests testMapFailureReason_mapsKnownLAErrorCodesCorrectly]' started.
Test Case '-[KizbaTests.LocalAuthBiometricAuthenticatorTests testMapFailureReason_mapsKnownLAErrorCodesCorrectly]' passed (0.002 seconds).
Test Case '-[KizbaTests.LocalAuthBiometricAuthenticatorTests testMapUnavailableReason_mapsKnownLAErrorCodesCorrectly]' started.
Test Case '-[KizbaTests.LocalAuthBiometricAuthenticatorTests testMapUnavailableReason_mapsKnownLAErrorCodesCorrectly]' passed (0.002 seconds).
Test Suite 'LocalAuthBiometricAuthenticatorTests' passed at 2026-05-24 08:25:37.616.
	 Executed 3 tests, with 0 failures (0 unexpected) in 3.039 (3.041) seconds
Test Suite 'LogWrapperTests' started at 2026-05-24 08:25:37.616.
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
Test Suite 'LogWrapperTests' passed at 2026-05-24 08:25:37.623.
	 Executed 5 tests, with 0 failures (0 unexpected) in 0.004 (0.007) seconds
Test Suite 'MenuBarModelTests' started at 2026-05-24 08:25:37.623.
Test Case '-[KizbaTests.MenuBarModelTests testCopyEntry_copiesToClipboard]' started.
Test Case '-[KizbaTests.MenuBarModelTests testCopyEntry_copiesToClipboard]' passed (0.103 seconds).
Test Case '-[KizbaTests.MenuBarModelTests testCopyEntry_policyOff_writesToClipboardWithoutPrompt]' started.
Test Case '-[KizbaTests.MenuBarModelTests testCopyEntry_policyOff_writesToClipboardWithoutPrompt]' passed (0.002 seconds).
Test Case '-[KizbaTests.MenuBarModelTests testCopyEntry_policyOn_cancelled_doesNotWriteToClipboard]' started.
Test Case '-[KizbaTests.MenuBarModelTests testCopyEntry_policyOn_cancelled_doesNotWriteToClipboard]' passed (0.002 seconds).
Test Case '-[KizbaTests.MenuBarModelTests testCopyEntry_policyOn_success_writesToClipboard]' started.
Test Case '-[KizbaTests.MenuBarModelTests testCopyEntry_policyOn_success_writesToClipboard]' passed (0.002 seconds).
Test Case '-[KizbaTests.MenuBarModelTests testLoadRecentsAndFavorites_populatesBoth]' started.
Test Case '-[KizbaTests.MenuBarModelTests testLoadRecentsAndFavorites_populatesBoth]' passed (0.002 seconds).
Test Case '-[KizbaTests.MenuBarModelTests testSearch_emptyQueryClearsResults]' started.
Test Case '-[KizbaTests.MenuBarModelTests testSearch_emptyQueryClearsResults]' passed (0.211 seconds).
Test Case '-[KizbaTests.MenuBarModelTests testSearch_populatesResults]' started.
Test Case '-[KizbaTests.MenuBarModelTests testSearch_populatesResults]' passed (0.366 seconds).
Test Case '-[KizbaTests.MenuBarModelTests testSelection_and_copy]' started.
Test Case '-[KizbaTests.MenuBarModelTests testSelection_and_copy]' passed (0.004 seconds).
Test Suite 'MenuBarModelTests' passed at 2026-05-24 08:25:38.321.
	 Executed 8 tests, with 0 failures (0 unexpected) in 0.692 (0.698) seconds
Test Suite 'MetadataPairTests' started at 2026-05-24 08:25:38.322.
Test Case '-[KizbaTests.MetadataPairTests testEqualityRequiresAllThreeFields]' started.
Test Case '-[KizbaTests.MetadataPairTests testEqualityRequiresAllThreeFields]' passed (0.002 seconds).
Test Case '-[KizbaTests.MetadataPairTests testHashableUsableInSet]' started.
Test Case '-[KizbaTests.MetadataPairTests testHashableUsableInSet]' passed (0.002 seconds).
Test Case '-[KizbaTests.MetadataPairTests testInitWithAutoIDProducesUniqueIdentifiers]' started.
Test Case '-[KizbaTests.MetadataPairTests testInitWithAutoIDProducesUniqueIdentifiers]' passed (0.001 seconds).
Test Case '-[KizbaTests.MetadataPairTests testInitWithExplicitID]' started.
Test Case '-[KizbaTests.MetadataPairTests testInitWithExplicitID]' passed (0.008 seconds).
Test Case '-[KizbaTests.MetadataPairTests testIsNotCodable]' started.
Test Case '-[KizbaTests.MetadataPairTests testIsNotCodable]' passed (0.002 seconds).
Test Case '-[KizbaTests.MetadataPairTests testIsNotCustomStringConvertible]' started.
Test Case '-[KizbaTests.MetadataPairTests testIsNotCustomStringConvertible]' passed (0.002 seconds).
Test Case '-[KizbaTests.MetadataPairTests testRuntimeIsNotEncodable]' started.
Test Case '-[KizbaTests.MetadataPairTests testRuntimeIsNotEncodable]' passed (0.001 seconds).
Test Case '-[KizbaTests.MetadataPairTests testValueSemanticsForKeyMutation]' started.
Test Case '-[KizbaTests.MetadataPairTests testValueSemanticsForKeyMutation]' passed (0.002 seconds).
Test Case '-[KizbaTests.MetadataPairTests testValueSemanticsForValueMutation]' started.
Test Case '-[KizbaTests.MetadataPairTests testValueSemanticsForValueMutation]' passed (0.001 seconds).
Test Suite 'MetadataPairTests' passed at 2026-05-24 08:25:38.349.
	 Executed 9 tests, with 0 failures (0 unexpected) in 0.021 (0.027) seconds
Test Suite 'MetadataValidatorTests' started at 2026-05-24 08:25:38.370.
Test Case '-[KizbaTests.MetadataValidatorTests testCaseSensitiveKeysAccepted]' started.
Test Case '-[KizbaTests.MetadataValidatorTests testCaseSensitiveKeysAccepted]' passed (0.002 seconds).
Test Case '-[KizbaTests.MetadataValidatorTests testDuplicateAdjacentKeys]' started.
Test Case '-[KizbaTests.MetadataValidatorTests testDuplicateAdjacentKeys]' passed (0.002 seconds).
Test Case '-[KizbaTests.MetadataValidatorTests testDuplicateKeyReportsBothIndices]' started.
Test Case '-[KizbaTests.MetadataValidatorTests testDuplicateKeyReportsBothIndices]' passed (0.002 seconds).
Test Case '-[KizbaTests.MetadataValidatorTests testEmptyKeyRejected]' started.
Test Case '-[KizbaTests.MetadataValidatorTests testEmptyKeyRejected]' passed (0.001 seconds).
Test Case '-[KizbaTests.MetadataValidatorTests testEmptyListAccepted]' started.
Test Case '-[KizbaTests.MetadataValidatorTests testEmptyListAccepted]' passed (0.001 seconds).
Test Case '-[KizbaTests.MetadataValidatorTests testFirstViolationByIndexWins]' started.
Test Case '-[KizbaTests.MetadataValidatorTests testFirstViolationByIndexWins]' passed (0.001 seconds).
Test Case '-[KizbaTests.MetadataValidatorTests testKeyWithColonRejected]' started.
Test Case '-[KizbaTests.MetadataValidatorTests testKeyWithColonRejected]' passed (0.001 seconds).
Test Case '-[KizbaTests.MetadataValidatorTests testKeyWithNewlineRejected]' started.
Test Case '-[KizbaTests.MetadataValidatorTests testKeyWithNewlineRejected]' passed (0.001 seconds).
Test Case '-[KizbaTests.MetadataValidatorTests testSinglePairAccepted]' started.
Test Case '-[KizbaTests.MetadataValidatorTests testSinglePairAccepted]' passed (0.001 seconds).
Test Case '-[KizbaTests.MetadataValidatorTests testSuccessReturnsOriginalListUnchanged]' started.
Test Case '-[KizbaTests.MetadataValidatorTests testSuccessReturnsOriginalListUnchanged]' passed (0.001 seconds).
Test Case '-[KizbaTests.MetadataValidatorTests testTwoDistinctPairsAccepted]' started.
Test Case '-[KizbaTests.MetadataValidatorTests testTwoDistinctPairsAccepted]' passed (0.001 seconds).
Test Case '-[KizbaTests.MetadataValidatorTests testValueWithColonAccepted]' started.
Test Case '-[KizbaTests.MetadataValidatorTests testValueWithColonAccepted]' passed (0.001 seconds).
Test Case '-[KizbaTests.MetadataValidatorTests testValueWithNewlineAccepted]' started.
Test Case '-[KizbaTests.MetadataValidatorTests testValueWithNewlineAccepted]' passed (0.002 seconds).
Test Suite 'MetadataValidatorTests' passed at 2026-05-24 08:25:38.427.
	 Executed 13 tests, with 0 failures (0 unexpected) in 0.014 (0.057) seconds
Test Suite 'MockPassManagerTests' started at 2026-05-24 08:25:38.427.
Test Case '-[KizbaTests.MockPassManagerTests testChanges_streamEmitsInsertedEvent]' started.
Test Case '-[KizbaTests.MockPassManagerTests testChanges_streamEmitsInsertedEvent]' passed (0.023 seconds).
Test Case '-[KizbaTests.MockPassManagerTests testConcurrency_readers_consistentResults]' started.
Test Case '-[KizbaTests.MockPassManagerTests testConcurrency_readers_consistentResults]' passed (0.003 seconds).
Test Case '-[KizbaTests.MockPassManagerTests testFixtures_areDeterministicAcrossInstances]' started.
Test Case '-[KizbaTests.MockPassManagerTests testFixtures_areDeterministicAcrossInstances]' passed (0.102 seconds).
Test Case '-[KizbaTests.MockPassManagerTests testFixtures_coverThreeFolders]' started.
Test Case '-[KizbaTests.MockPassManagerTests testFixtures_coverThreeFolders]' passed (0.002 seconds).
Test Case '-[KizbaTests.MockPassManagerTests testFixtures_includeEdgeCases]' started.
Test Case '-[KizbaTests.MockPassManagerTests testFixtures_includeEdgeCases]' passed (0.002 seconds).
Test Case '-[KizbaTests.MockPassManagerTests testInsert_existingEntryWithForce_overwritesAndEmitsUpdated]' started.
Test Case '-[KizbaTests.MockPassManagerTests testInsert_existingEntryWithForce_overwritesAndEmitsUpdated]' passed (0.024 seconds).
Test Case '-[KizbaTests.MockPassManagerTests testInsert_existingEntryWithoutForce_throwsAlreadyExists]' started.
Test Case '-[KizbaTests.MockPassManagerTests testInsert_existingEntryWithoutForce_throwsAlreadyExists]' passed (0.004 seconds).
Test Case '-[KizbaTests.MockPassManagerTests testInsert_newEntry_appendsAndReturnsEntry]' started.
Test Case '-[KizbaTests.MockPassManagerTests testInsert_newEntry_appendsAndReturnsEntry]' passed (0.002 seconds).
Test Case '-[KizbaTests.MockPassManagerTests testMock_has20Fixtures]' started.
Test Case '-[KizbaTests.MockPassManagerTests testMock_has20Fixtures]' passed (0.001 seconds).
Test Case '-[KizbaTests.MockPassManagerTests testMove_targetCollisionWithoutForce_throwsAlreadyExists]' started.
Test Case '-[KizbaTests.MockPassManagerTests testMove_targetCollisionWithoutForce_throwsAlreadyExists]' passed (0.001 seconds).
Test Case '-[KizbaTests.MockPassManagerTests testRemove_missingEntry_throwsSourceNotFound]' started.
Test Case '-[KizbaTests.MockPassManagerTests testRemove_missingEntry_throwsSourceNotFound]' passed (0.001 seconds).
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
Test Suite 'MockPassManagerTests' passed at 2026-05-24 08:25:38.620.
	 Executed 16 tests, with 0 failures (0 unexpected) in 0.170 (0.192) seconds
Test Suite 'MoveEntryModelTests' started at 2026-05-24 08:25:38.620.
Test Case '-[KizbaTests.MoveEntryModelTests testCancel_midSave_landsInIdle_withoutCompletionSideEffects]' started.
Test Case '-[KizbaTests.MoveEntryModelTests testCancel_midSave_landsInIdle_withoutCompletionSideEffects]' passed (0.305 seconds).
Test Case '-[KizbaTests.MoveEntryModelTests testCanSave_isFalse_whenNewPathContainsDotDot]' started.
Test Case '-[KizbaTests.MoveEntryModelTests testCanSave_isFalse_whenNewPathContainsDotDot]' passed (0.002 seconds).
Test Case '-[KizbaTests.MoveEntryModelTests testCanSave_isFalse_whenNewPathEqualsOriginal_andSurfacesSamePathError]' started.
Test Case '-[KizbaTests.MoveEntryModelTests testCanSave_isFalse_whenNewPathEqualsOriginal_andSurfacesSamePathError]' passed (0.001 seconds).
Test Case '-[KizbaTests.MoveEntryModelTests testCanSave_isFalse_whenNewPathHasGpgSuffix]' started.
Test Case '-[KizbaTests.MoveEntryModelTests testCanSave_isFalse_whenNewPathHasGpgSuffix]' passed (0.001 seconds).
Test Case '-[KizbaTests.MoveEntryModelTests testCanSave_isFalse_whenNewPathIsEmpty]' started.
Test Case '-[KizbaTests.MoveEntryModelTests testCanSave_isFalse_whenNewPathIsEmpty]' passed (0.001 seconds).
Test Case '-[KizbaTests.MoveEntryModelTests testCanSave_isTrue_forValidNewPath]' started.
Test Case '-[KizbaTests.MoveEntryModelTests testCanSave_isTrue_forValidNewPath]' passed (0.001 seconds).
Test Case '-[KizbaTests.MoveEntryModelTests testGenerationCounter_dropsStaleCompletionFromCancelledSave]' started.
Test Case '-[KizbaTests.MoveEntryModelTests testGenerationCounter_dropsStaleCompletionFromCancelledSave]' passed (0.090 seconds).
Test Case '-[KizbaTests.MoveEntryModelTests testHandleDismissal_cancelsInFlightSave_andDropsCompletion]' started.
Test Case '-[KizbaTests.MoveEntryModelTests testHandleDismissal_cancelsInFlightSave_andDropsCompletion]' passed (0.307 seconds).
Test Case '-[KizbaTests.MoveEntryModelTests testInitialState_isIdle_andNewPathIsPreFilledWithOriginal_andForceIsFalse]' started.
Test Case '-[KizbaTests.MoveEntryModelTests testInitialState_isIdle_andNewPathIsPreFilledWithOriginal_andForceIsFalse]' passed (0.002 seconds).
Test Case '-[KizbaTests.MoveEntryModelTests testSave_collisionWithoutForce_landsInFailed_inlineRecoverable_andDoesNotRecordOrSelectOrToast]' started.
Test Case '-[KizbaTests.MoveEntryModelTests testSave_collisionWithoutForce_landsInFailed_inlineRecoverable_andDoesNotRecordOrSelectOrToast]' passed (0.109 seconds).
Test Case '-[KizbaTests.MoveEntryModelTests testSave_forceReplaceAfterCollision_succeeds]' started.
Test Case '-[KizbaTests.MoveEntryModelTests testSave_forceReplaceAfterCollision_succeeds]' passed (0.016 seconds).
Test Case '-[KizbaTests.MoveEntryModelTests testSave_happyPath_landsInSaved_andUpdatesManager_andSelectsNewEntry_andRecordsUndo_andPostsToast]' started.
Test Case '-[KizbaTests.MoveEntryModelTests testSave_happyPath_landsInSaved_andUpdatesManager_andSelectsNewEntry_andRecordsUndo_andPostsToast]' passed (0.009 seconds).
Test Case '-[KizbaTests.MoveEntryModelTests testSave_withNonRecoverableError_landsInFailed_andPostsErrorToast]' started.
Test Case '-[KizbaTests.MoveEntryModelTests testSave_withNonRecoverableError_landsInFailed_andPostsErrorToast]' passed (0.011 seconds).
Test Case '-[KizbaTests.MoveEntryModelTests testUndo_fromPendingAction_movesEntryBackToOriginalPath]' started.
Test Case '-[KizbaTests.MoveEntryModelTests testUndo_fromPendingAction_movesEntryBackToOriginalPath]' passed (0.009 seconds).
Test Suite 'MoveEntryModelTests' passed at 2026-05-24 08:25:39.492.
	 Executed 14 tests, with 0 failures (0 unexpected) in 0.864 (0.873) seconds
Test Suite 'OTPAuthURIBuilderTests' started at 2026-05-24 08:25:39.493.
Test Case '-[KizbaTests.OTPAuthURIBuilderTests testBuild_hotpAlwaysEmitsCounter_evenWhenZero]' started.
Test Case '-[KizbaTests.OTPAuthURIBuilderTests testBuild_hotpAlwaysEmitsCounter_evenWhenZero]' passed (0.002 seconds).
Test Case '-[KizbaTests.OTPAuthURIBuilderTests testBuild_hotpHighCounter]' started.
Test Case '-[KizbaTests.OTPAuthURIBuilderTests testBuild_hotpHighCounter]' passed (0.001 seconds).
Test Case '-[KizbaTests.OTPAuthURIBuilderTests testBuild_includesNonDefaultAlgorithm]' started.
Test Case '-[KizbaTests.OTPAuthURIBuilderTests testBuild_includesNonDefaultAlgorithm]' passed (0.001 seconds).
Test Case '-[KizbaTests.OTPAuthURIBuilderTests testBuild_includesNonDefaultDigits]' started.
Test Case '-[KizbaTests.OTPAuthURIBuilderTests testBuild_includesNonDefaultDigits]' passed (0.001 seconds).
Test Case '-[KizbaTests.OTPAuthURIBuilderTests testBuild_includesNonDefaultPeriod]' started.
Test Case '-[KizbaTests.OTPAuthURIBuilderTests testBuild_includesNonDefaultPeriod]' passed (0.001 seconds).
Test Case '-[KizbaTests.OTPAuthURIBuilderTests testBuild_minimalDefaults_omitsAlgorithmDigitsPeriod]' started.
Test Case '-[KizbaTests.OTPAuthURIBuilderTests testBuild_minimalDefaults_omitsAlgorithmDigitsPeriod]' passed (0.002 seconds).
Test Case '-[KizbaTests.OTPAuthURIBuilderTests testBuild_noIssuer_noAccount_usesPlaceholderLabel]' started.
Test Case '-[KizbaTests.OTPAuthURIBuilderTests testBuild_noIssuer_noAccount_usesPlaceholderLabel]' passed (0.002 seconds).
Test Case '-[KizbaTests.OTPAuthURIBuilderTests testRoundtrip_accountOnly_noIssuer]' started.
Test Case '-[KizbaTests.OTPAuthURIBuilderTests testRoundtrip_accountOnly_noIssuer]' passed (0.003 seconds).
Test Case '-[KizbaTests.OTPAuthURIBuilderTests testRoundtrip_hotp]' started.
Test Case '-[KizbaTests.OTPAuthURIBuilderTests testRoundtrip_hotp]' passed (0.001 seconds).
Test Case '-[KizbaTests.OTPAuthURIBuilderTests testRoundtrip_minimalTOTP]' started.
Test Case '-[KizbaTests.OTPAuthURIBuilderTests testRoundtrip_minimalTOTP]' passed (0.001 seconds).
Test Case '-[KizbaTests.OTPAuthURIBuilderTests testRoundtrip_nonDefaultsTOTP]' started.
Test Case '-[KizbaTests.OTPAuthURIBuilderTests testRoundtrip_nonDefaultsTOTP]' passed (0.001 seconds).
Test Case '-[KizbaTests.OTPAuthURIBuilderTests testRoundtrip_sha512]' started.
Test Case '-[KizbaTests.OTPAuthURIBuilderTests testRoundtrip_sha512]' passed (0.001 seconds).
Test Suite 'OTPAuthURIBuilderTests' passed at 2026-05-24 08:25:39.524.
	 Executed 12 tests, with 0 failures (0 unexpected) in 0.014 (0.031) seconds
Test Suite 'OTPAuthURIParserTests' started at 2026-05-24 08:25:39.524.
Test Case '-[KizbaTests.OTPAuthURIParserTests testParse_algorithmCaseInsensitive]' started.
Test Case '-[KizbaTests.OTPAuthURIParserTests testParse_algorithmCaseInsensitive]' passed (0.001 seconds).
Test Case '-[KizbaTests.OTPAuthURIParserTests testParse_customPeriod60_sha512_digits8]' started.
Test Case '-[KizbaTests.OTPAuthURIParserTests testParse_customPeriod60_sha512_digits8]' passed (0.002 seconds).
Test Case '-[KizbaTests.OTPAuthURIParserTests testParse_digits5_throws]' started.
Test Case '-[KizbaTests.OTPAuthURIParserTests testParse_digits5_throws]' passed (0.002 seconds).
Test Case '-[KizbaTests.OTPAuthURIParserTests testParse_hotp_missingCounter_throws]' started.
Test Case '-[KizbaTests.OTPAuthURIParserTests testParse_hotp_missingCounter_throws]' passed (0.001 seconds).
Test Case '-[KizbaTests.OTPAuthURIParserTests testParse_hotp_withCounter]' started.
Test Case '-[KizbaTests.OTPAuthURIParserTests testParse_hotp_withCounter]' passed (0.001 seconds).
Test Case '-[KizbaTests.OTPAuthURIParserTests testParse_invalidBase32_throws]' started.
Test Case '-[KizbaTests.OTPAuthURIParserTests testParse_invalidBase32_throws]' passed (0.001 seconds).
Test Case '-[KizbaTests.OTPAuthURIParserTests testParse_invalidPeriod_throws]' started.
Test Case '-[KizbaTests.OTPAuthURIParserTests testParse_invalidPeriod_throws]' passed (0.002 seconds).
Test Case '-[KizbaTests.OTPAuthURIParserTests testParse_invalidScheme_throws]' started.
Test Case '-[KizbaTests.OTPAuthURIParserTests testParse_invalidScheme_throws]' passed (0.001 seconds).
Test Case '-[KizbaTests.OTPAuthURIParserTests testParse_issuerQueryOverridesLabelPrefix]' started.
Test Case '-[KizbaTests.OTPAuthURIParserTests testParse_issuerQueryOverridesLabelPrefix]' passed (0.001 seconds).
Test Case '-[KizbaTests.OTPAuthURIParserTests testParse_lowercaseBase32_accepted]' started.
Test Case '-[KizbaTests.OTPAuthURIParserTests testParse_lowercaseBase32_accepted]' passed (0.001 seconds).
Test Case '-[KizbaTests.OTPAuthURIParserTests testParse_malformedURI_throws]' started.
Test Case '-[KizbaTests.OTPAuthURIParserTests testParse_malformedURI_throws]' passed (0.001 seconds).
Test Case '-[KizbaTests.OTPAuthURIParserTests testParse_missingSecret_throws]' started.
Test Case '-[KizbaTests.OTPAuthURIParserTests testParse_missingSecret_throws]' passed (0.002 seconds).
Test Case '-[KizbaTests.OTPAuthURIParserTests testParse_paddedBase32_acceptedAndStripped]' started.
Test Case '-[KizbaTests.OTPAuthURIParserTests testParse_paddedBase32_acceptedAndStripped]' passed (0.002 seconds).
Test Case '-[KizbaTests.OTPAuthURIParserTests testParse_rfcSample_totp]' started.
Test Case '-[KizbaTests.OTPAuthURIParserTests testParse_rfcSample_totp]' passed (0.001 seconds).
Test Case '-[KizbaTests.OTPAuthURIParserTests testParse_unsupportedHost_throws]' started.
Test Case '-[KizbaTests.OTPAuthURIParserTests testParse_unsupportedHost_throws]' passed (0.001 seconds).
Test Case '-[KizbaTests.OTPAuthURIParserTests testParse_urlEncodedLabel_parsed]' started.
Test Case '-[KizbaTests.OTPAuthURIParserTests testParse_urlEncodedLabel_parsed]' passed (0.001 seconds).
Test Suite 'OTPAuthURIParserTests' passed at 2026-05-24 08:25:39.602.
	 Executed 16 tests, with 0 failures (0 unexpected) in 0.018 (0.078) seconds
Test Suite 'OTPDiscoveryTests' started at 2026-05-24 08:25:39.602.
Test Case '-[KizbaTests.OTPDiscoveryTests testOtpSecret_bareUriInMetadataValue_schemeRecovered]' started.
Test Case '-[KizbaTests.OTPDiscoveryTests testOtpSecret_bareUriInMetadataValue_schemeRecovered]' passed (0.002 seconds).
Test Case '-[KizbaTests.OTPDiscoveryTests testOtpSecret_extraLineMatch_returnsParsedSecret]' started.
Test Case '-[KizbaTests.OTPDiscoveryTests testOtpSecret_extraLineMatch_returnsParsedSecret]' passed (0.003 seconds).
Test Case '-[KizbaTests.OTPDiscoveryTests testOtpSecret_fullSchemeInMetadataValue_stillWorks]' started.
Test Case '-[KizbaTests.OTPDiscoveryTests testOtpSecret_fullSchemeInMetadataValue_stillWorks]' passed (0.003 seconds).
Test Case '-[KizbaTests.OTPDiscoveryTests testOtpSecret_fullUriUnderCustomMetadataKey_isDiscovered]' started.
Test Case '-[KizbaTests.OTPDiscoveryTests testOtpSecret_fullUriUnderCustomMetadataKey_isDiscovered]' passed (0.002 seconds).
Test Case '-[KizbaTests.OTPDiscoveryTests testOtpSecret_invalidURIInMetadata_returnsNilSilently]' started.
Test Case '-[KizbaTests.OTPDiscoveryTests testOtpSecret_invalidURIInMetadata_returnsNilSilently]' passed (0.002 seconds).
Test Case '-[KizbaTests.OTPDiscoveryTests testOtpSecret_metadataKeyMatch_returnsParsedSecret]' started.
Test Case '-[KizbaTests.OTPDiscoveryTests testOtpSecret_metadataKeyMatch_returnsParsedSecret]' passed (0.003 seconds).
Test Case '-[KizbaTests.OTPDiscoveryTests testOtpSecret_metadataWinsWhenBothPresent]' started.
Test Case '-[KizbaTests.OTPDiscoveryTests testOtpSecret_metadataWinsWhenBothPresent]' passed (0.002 seconds).
Test Case '-[KizbaTests.OTPDiscoveryTests testOtpSecret_mixedCaseKey_matchesCaseInsensitively]' started.
Test Case '-[KizbaTests.OTPDiscoveryTests testOtpSecret_mixedCaseKey_matchesCaseInsensitively]' passed (0.001 seconds).
Test Case '-[KizbaTests.OTPDiscoveryTests testOtpSecret_noOTP_returnsNil]' started.
Test Case '-[KizbaTests.OTPDiscoveryTests testOtpSecret_noOTP_returnsNil]' passed (0.001 seconds).
Test Suite 'OTPDiscoveryTests' passed at 2026-05-24 08:25:39.650.
	 Executed 9 tests, with 0 failures (0 unexpected) in 0.018 (0.048) seconds
Test Suite 'OTPModelTests' started at 2026-05-24 08:25:39.651.
Test Case '-[KizbaTests.OTPModelTests test_hotp_showsCodeOnce_noProgressDrain]' started.
Test Case '-[KizbaTests.OTPModelTests test_hotp_showsCodeOnce_noProgressDrain]' passed (1.337 seconds).
Test Case '-[KizbaTests.OTPModelTests test_progressFraction_drainsLinearly]' started.
Test Case '-[KizbaTests.OTPModelTests test_progressFraction_drainsLinearly]' passed (0.343 seconds).
Test Case '-[KizbaTests.OTPModelTests test_recomputesCodeOnPeriodBoundary]' started.
Test Case '-[KizbaTests.OTPModelTests test_recomputesCodeOnPeriodBoundary]' passed (1.151 seconds).
Test Case '-[KizbaTests.OTPModelTests test_requestCopy_policyOnCancelled_doesNotWrite]' started.
Test Case '-[KizbaTests.OTPModelTests test_requestCopy_policyOnCancelled_doesNotWrite]' passed (0.014 seconds).
Test Case '-[KizbaTests.OTPModelTests test_requestCopy_policyOnSuccess_writesToClipboard]' started.
Test Case '-[KizbaTests.OTPModelTests test_requestCopy_policyOnSuccess_writesToClipboard]' passed (0.013 seconds).
Test Case '-[KizbaTests.OTPModelTests test_start_emitsInitialCode]' started.
Test Case '-[KizbaTests.OTPModelTests test_start_emitsInitialCode]' passed (0.013 seconds).
Test Case '-[KizbaTests.OTPModelTests test_stop_cancelsRefreshTask]' started.
Test Case '-[KizbaTests.OTPModelTests test_stop_cancelsRefreshTask]' passed (1.235 seconds).
Test Suite 'OTPModelTests' passed at 2026-05-24 08:25:43.764.
	 Executed 7 tests, with 0 failures (0 unexpected) in 4.107 (4.113) seconds
Test Suite 'OTPSecretGeneratorTests' started at 2026-05-24 08:25:43.765.
Test Case '-[KizbaTests.OTPSecretGeneratorTests testFromBase32_acceptsValidUppercase]' started.
Test Case '-[KizbaTests.OTPSecretGeneratorTests testFromBase32_acceptsValidUppercase]' passed (0.005 seconds).
Test Case '-[KizbaTests.OTPSecretGeneratorTests testFromBase32_normalisesLowercaseToUppercase]' started.
Test Case '-[KizbaTests.OTPSecretGeneratorTests testFromBase32_normalisesLowercaseToUppercase]' passed (0.001 seconds).
Test Case '-[KizbaTests.OTPSecretGeneratorTests testFromBase32_rejectsEmpty]' started.
Test Case '-[KizbaTests.OTPSecretGeneratorTests testFromBase32_rejectsEmpty]' passed (0.001 seconds).
Test Case '-[KizbaTests.OTPSecretGeneratorTests testFromBase32_rejectsInvalidCharacters]' started.
Test Case '-[KizbaTests.OTPSecretGeneratorTests testFromBase32_rejectsInvalidCharacters]' passed (0.001 seconds).
Test Case '-[KizbaTests.OTPSecretGeneratorTests testFromBase32_stripsInternalWhitespace]' started.
Test Case '-[KizbaTests.OTPSecretGeneratorTests testFromBase32_stripsInternalWhitespace]' passed (0.001 seconds).
Test Case '-[KizbaTests.OTPSecretGeneratorTests testFromBase32_stripsPadding]' started.
Test Case '-[KizbaTests.OTPSecretGeneratorTests testFromBase32_stripsPadding]' passed (0.001 seconds).
Test Case '-[KizbaTests.OTPSecretGeneratorTests testFromPassphrase_differentInputs_differentSecrets]' started.
Test Case '-[KizbaTests.OTPSecretGeneratorTests testFromPassphrase_differentInputs_differentSecrets]' passed (0.001 seconds).
Test Case '-[KizbaTests.OTPSecretGeneratorTests testFromPassphrase_emptyPassphrase_stillProducesSecret]' started.
Test Case '-[KizbaTests.OTPSecretGeneratorTests testFromPassphrase_emptyPassphrase_stillProducesSecret]' passed (0.001 seconds).
Test Case '-[KizbaTests.OTPSecretGeneratorTests testFromPassphrase_isAlso160Bits]' started.
Test Case '-[KizbaTests.OTPSecretGeneratorTests testFromPassphrase_isAlso160Bits]' passed (0.001 seconds).
Test Case '-[KizbaTests.OTPSecretGeneratorTests testFromPassphrase_isDeterministic]' started.
Test Case '-[KizbaTests.OTPSecretGeneratorTests testFromPassphrase_isDeterministic]' passed (0.033 seconds).
Test Case '-[KizbaTests.OTPSecretGeneratorTests testRandom_defaultsToTOTP_sha1_6digits_30s]' started.
Test Case '-[KizbaTests.OTPSecretGeneratorTests testRandom_defaultsToTOTP_sha1_6digits_30s]' passed (0.003 seconds).
Test Case '-[KizbaTests.OTPSecretGeneratorTests testRandom_isDifferentEachCall]' started.
Test Case '-[KizbaTests.OTPSecretGeneratorTests testRandom_isDifferentEachCall]' passed (0.002 seconds).
Test Case '-[KizbaTests.OTPSecretGeneratorTests testRandom_producesValidBase32]' started.
Test Case '-[KizbaTests.OTPSecretGeneratorTests testRandom_producesValidBase32]' passed (0.001 seconds).
Test Case '-[KizbaTests.OTPSecretGeneratorTests testRandom_propagatesLabelAndIssuer]' started.
Test Case '-[KizbaTests.OTPSecretGeneratorTests testRandom_propagatesLabelAndIssuer]' passed (0.001 seconds).
Test Case '-[KizbaTests.OTPSecretGeneratorTests testRandom_secretIs160Bits]' started.
Test Case '-[KizbaTests.OTPSecretGeneratorTests testRandom_secretIs160Bits]' passed (0.001 seconds).
Test Suite 'OTPSecretGeneratorTests' passed at 2026-05-24 08:25:43.844.
	 Executed 15 tests, with 0 failures (0 unexpected) in 0.052 (0.079) seconds
Test Suite 'OnePasswordCSVImporterTests' started at 2026-05-24 08:25:43.844.
Test Case '-[KizbaTests.OnePasswordCSVImporterTests testParse_commonFieldsExport]' started.
Test Case '-[KizbaTests.OnePasswordCSVImporterTests testParse_commonFieldsExport]' passed (0.002 seconds).
Test Case '-[KizbaTests.OnePasswordCSVImporterTests testParse_conflictsDetected]' started.
Test Case '-[KizbaTests.OnePasswordCSVImporterTests testParse_conflictsDetected]' passed (0.002 seconds).
Test Case '-[KizbaTests.OnePasswordCSVImporterTests testParse_emptyTitle_isWarning]' started.
Test Case '-[KizbaTests.OnePasswordCSVImporterTests testParse_emptyTitle_isWarning]' passed (0.002 seconds).
Test Case '-[KizbaTests.OnePasswordCSVImporterTests testParse_missingTitle_throws]' started.
Test Case '-[KizbaTests.OnePasswordCSVImporterTests testParse_missingTitle_throws]' passed (0.001 seconds).
Test Case '-[KizbaTests.OnePasswordCSVImporterTests testParse_quotedNotesWithComma]' started.
Test Case '-[KizbaTests.OnePasswordCSVImporterTests testParse_quotedNotesWithComma]' passed (0.013 seconds).
Test Suite 'OnePasswordCSVImporterTests' passed at 2026-05-24 08:25:43.869.
	 Executed 5 tests, with 0 failures (0 unexpected) in 0.021 (0.024) seconds
Test Suite 'PassCLIGitEnvTests' started at 2026-05-24 08:25:43.869.
Test Case '-[KizbaTests.PassCLIGitEnvTests testGitEnv_containsGitTerminalPromptZero]' started.
Test Case '-[KizbaTests.PassCLIGitEnvTests testGitEnv_containsGitTerminalPromptZero]' passed (0.002 seconds).
Test Case '-[KizbaTests.PassCLIGitEnvTests testGitEnv_containsSshAskpassFalse]' started.
Test Case '-[KizbaTests.PassCLIGitEnvTests testGitEnv_containsSshAskpassFalse]' passed (0.002 seconds).
Test Case '-[KizbaTests.PassCLIGitEnvTests testGitEnv_inheritsBaseComposedEnv]' started.
Test Case '-[KizbaTests.PassCLIGitEnvTests testGitEnv_inheritsBaseComposedEnv]' passed (0.002 seconds).
Test Case '-[KizbaTests.PassCLIGitEnvTests testGitEnv_omitsSshAuthSock_whenAbsent]' started.
Test Case '-[KizbaTests.PassCLIGitEnvTests testGitEnv_omitsSshAuthSock_whenAbsent]' passed (0.010 seconds).
Test Case '-[KizbaTests.PassCLIGitEnvTests testGitEnv_pathIncludesSbinAndUsrSbin]' started.
Test Case '-[KizbaTests.PassCLIGitEnvTests testGitEnv_pathIncludesSbinAndUsrSbin]' passed (0.002 seconds).
Test Case '-[KizbaTests.PassCLIGitEnvTests testGitEnv_propagatesSshAuthSock_whenPresent]' started.
Test Case '-[KizbaTests.PassCLIGitEnvTests testGitEnv_propagatesSshAuthSock_whenPresent]' passed (0.002 seconds).
Test Suite 'PassCLIGitEnvTests' passed at 2026-05-24 08:25:43.893.
	 Executed 6 tests, with 0 failures (0 unexpected) in 0.020 (0.024) seconds
Test Suite 'PassCLIGitTests' started at 2026-05-24 08:25:43.893.
Test Case '-[KizbaTests.PassCLIGitTests testGitPull_invocationShape]' started.
Test Case '-[KizbaTests.PassCLIGitTests testGitPull_invocationShape]' passed (0.002 seconds).
Test Case '-[KizbaTests.PassCLIGitTests testGitPush_invocationShape]' started.
Test Case '-[KizbaTests.PassCLIGitTests testGitPush_invocationShape]' passed (0.013 seconds).
Test Case '-[KizbaTests.PassCLIGitTests testGitPush_pushed_returnsPushed]' started.
Test Case '-[KizbaTests.PassCLIGitTests testGitPush_pushed_returnsPushed]' passed (0.002 seconds).
Test Case '-[KizbaTests.PassCLIGitTests testGitPush_upToDate_returnsAlreadyUpToDate]' started.
Test Case '-[KizbaTests.PassCLIGitTests testGitPush_upToDate_returnsAlreadyUpToDate]' passed (0.003 seconds).
Test Case '-[KizbaTests.PassCLIGitTests testGitStatus_followsUpWithGitRemoteCall]' started.
Test Case '-[KizbaTests.PassCLIGitTests testGitStatus_followsUpWithGitRemoteCall]' passed (0.003 seconds).
Test Case '-[KizbaTests.PassCLIGitTests testGitStatus_invocationShape]' started.
Test Case '-[KizbaTests.PassCLIGitTests testGitStatus_invocationShape]' passed (0.002 seconds).
Test Case '-[KizbaTests.PassCLIGitTests testGitStatus_mergesFetchHeadMtime]' started.
Test Case '-[KizbaTests.PassCLIGitTests testGitStatus_mergesFetchHeadMtime]' passed (0.005 seconds).
Test Case '-[KizbaTests.PassCLIGitTests testGitStatus_noFetchHead_lastFetchAtNil]' started.
Test Case '-[KizbaTests.PassCLIGitTests testGitStatus_noFetchHead_lastFetchAtNil]' passed (0.005 seconds).
Test Case '-[KizbaTests.PassCLIGitTests testGitStatus_parsesStdout]' started.
Test Case '-[KizbaTests.PassCLIGitTests testGitStatus_parsesStdout]' passed (0.104 seconds).
Test Suite 'PassCLIGitTests' passed at 2026-05-24 08:25:44.039.
	 Executed 9 tests, with 0 failures (0 unexpected) in 0.139 (0.145) seconds
Test Suite 'PassCLITests' started at 2026-05-24 08:25:44.039.
Test Case '-[KizbaTests.PassCLITests testCancellation_propagatesCancellation]' started.
2026-05-24 08:25:44.093199+0200 Kizba[11882:1070614] [pass] pass show cancelled: exe=/opt/homebrew/bin/pass argc=2
Test Case '-[KizbaTests.PassCLITests testCancellation_propagatesCancellation]' passed (0.054 seconds).
Test Case '-[KizbaTests.PassCLITests testDecryptionFailure_mapsToPassError]' started.
2026-05-24 08:25:44.096528+0200 Kizba[11882:1070614] [pass] pass show failed: exe=/opt/homebrew/bin/pass argc=2 status=2 stderrBytes=114 excerpt=gpg: decryption failed: No secret key gpg: encrypted with RSA key, ID <redacted-id> gpg: <redacted-email>
Test Case '-[KizbaTests.PassCLITests testDecryptionFailure_mapsToPassError]' passed (0.003 seconds).
Test Case '-[KizbaTests.PassCLITests testDefaultPATHIsExportedWhenNoOverridesSupplied]' started.
2026-05-24 08:25:44.099627+0200 Kizba[11882:1070614] [pass] pass show ok: exe=/opt/homebrew/bin/pass argc=2 status=0 stderrBytes=0
Test Case '-[KizbaTests.PassCLITests testDefaultPATHIsExportedWhenNoOverridesSupplied]' passed (0.002 seconds).
Test Case '-[KizbaTests.PassCLITests testEnvAndBinaryOverride_composition]' started.
2026-05-24 08:25:44.102717+0200 Kizba[11882:1070611] [pass] pass show ok: exe=/private/tmp/custom-pass-bin argc=2 status=0 stderrBytes=0
Test Case '-[KizbaTests.PassCLITests testEnvAndBinaryOverride_composition]' passed (0.003 seconds).
Test Case '-[KizbaTests.PassCLITests testShowSuccess_parsesPasswordAndMetadata]' started.
2026-05-24 08:25:44.106219+0200 Kizba[11882:1071152] [pass] pass show ok: exe=/opt/homebrew/bin/pass argc=2 status=0 stderrBytes=0
Test Case '-[KizbaTests.PassCLITests testShowSuccess_parsesPasswordAndMetadata]' passed (0.003 seconds).
Test Case '-[KizbaTests.PassCLITests testTimeout_throwsTimedOut]' started.
2026-05-24 08:25:44.120586+0200 Kizba[11882:1070617] [pass] pass show timed out: exe=/opt/homebrew/bin/pass argc=2
Test Case '-[KizbaTests.PassCLITests testTimeout_throwsTimedOut]' passed (0.014 seconds).
Test Suite 'PassCLITests' passed at 2026-05-24 08:25:44.122.
	 Executed 6 tests, with 0 failures (0 unexpected) in 0.079 (0.083) seconds
Test Suite 'PassCLIWriteTests' started at 2026-05-24 08:25:44.123.
Test Case '-[KizbaTests.PassCLIWriteTests testGenerate_basic_argvIsGeneratePathLength]' started.
2026-05-24 08:25:44.125054+0200 Kizba[11882:1070534] [pass] pass generate ok: exe=/opt/homebrew/bin/pass argc=3 status=0 stdoutBytes=52 stderrBytes=0
Test Case '-[KizbaTests.PassCLIWriteTests testGenerate_basic_argvIsGeneratePathLength]' passed (0.003 seconds).
Test Case '-[KizbaTests.PassCLIWriteTests testGenerate_environmentDefaultsPATHWhenNoOverridesSupplied]' started.
2026-05-24 08:25:44.128082+0200 Kizba[11882:1070534] [pass] pass generate ok: exe=/opt/homebrew/bin/pass argc=3 status=0 stdoutBytes=52 stderrBytes=0
Test Case '-[KizbaTests.PassCLIWriteTests testGenerate_environmentDefaultsPATHWhenNoOverridesSupplied]' passed (0.003 seconds).
Test Case '-[KizbaTests.PassCLIWriteTests testGenerate_force_addsDashF]' started.
2026-05-24 08:25:44.132192+0200 Kizba[11882:1070534] [pass] pass generate ok: exe=/opt/homebrew/bin/pass argc=4 status=0 stdoutBytes=52 stderrBytes=0
Test Case '-[KizbaTests.PassCLIWriteTests testGenerate_force_addsDashF]' passed (0.003 seconds).
Test Case '-[KizbaTests.PassCLIWriteTests testGenerate_forceAndNoSymbols_orderIsForceThenNoSymbols]' started.
2026-05-24 08:25:44.135130+0200 Kizba[11882:1070534] [pass] pass generate ok: exe=/opt/homebrew/bin/pass argc=5 status=0 stdoutBytes=52 stderrBytes=0
Test Case '-[KizbaTests.PassCLIWriteTests testGenerate_forceAndNoSymbols_orderIsForceThenNoSymbols]' passed (0.002 seconds).
Test Case '-[KizbaTests.PassCLIWriteTests testGenerate_happyPath_returnsParsedPassword]' started.
2026-05-24 08:25:44.137472+0200 Kizba[11882:1070534] [pass] pass generate ok: exe=/opt/homebrew/bin/pass argc=3 status=0 stdoutBytes=52 stderrBytes=0
Test Case '-[KizbaTests.PassCLIWriteTests testGenerate_happyPath_returnsParsedPassword]' passed (0.005 seconds).
Test Case '-[KizbaTests.PassCLIWriteTests testGenerate_invalidLengthStderr_throwsInvalidLength]' started.
2026-05-24 08:25:44.142403+0200 Kizba[11882:1070534] [pass] pass generate failed: exe=/opt/homebrew/bin/pass argc=3 status=1 bytesIn=0 stderrBytes=53 excerpt=Error: pass-length "abc" must be a positive integer.
Test Case '-[KizbaTests.PassCLIWriteTests testGenerate_invalidLengthStderr_throwsInvalidLength]' passed (0.002 seconds).
Test Case '-[KizbaTests.PassCLIWriteTests testGenerate_noSymbols_addsDashN]' started.
2026-05-24 08:25:44.144050+0200 Kizba[11882:1070534] [pass] pass generate ok: exe=/opt/homebrew/bin/pass argc=4 status=0 stdoutBytes=52 stderrBytes=0
Test Case '-[KizbaTests.PassCLIWriteTests testGenerate_noSymbols_addsDashN]' passed (0.001 seconds).
Test Case '-[KizbaTests.PassCLIWriteTests testGenerateInPlace_basic_argvIncludesInPlaceFlag]' started.
2026-05-24 08:25:44.145464+0200 Kizba[11882:1070534] [pass] pass generate-in-place ok: exe=/opt/homebrew/bin/pass argc=4 status=0 stdoutBytes=52 stderrBytes=0
Test Case '-[KizbaTests.PassCLIWriteTests testGenerateInPlace_basic_argvIncludesInPlaceFlag]' passed (0.001 seconds).
Test Case '-[KizbaTests.PassCLIWriteTests testGenerateInPlace_happyPath_returnsParsedPassword]' started.
2026-05-24 08:25:44.151861+0200 Kizba[11882:1070534] [pass] pass generate-in-place ok: exe=/opt/homebrew/bin/pass argc=4 status=0 stdoutBytes=55 stderrBytes=0
Test Case '-[KizbaTests.PassCLIWriteTests testGenerateInPlace_happyPath_returnsParsedPassword]' passed (0.001 seconds).
Test Case '-[KizbaTests.PassCLIWriteTests testGenerateInPlace_noSymbols_addsDashNBeforeInPlace]' started.
2026-05-24 08:25:44.153284+0200 Kizba[11882:1070534] [pass] pass generate-in-place ok: exe=/opt/homebrew/bin/pass argc=5 status=0 stdoutBytes=52 stderrBytes=0
Test Case '-[KizbaTests.PassCLIWriteTests testGenerateInPlace_noSymbols_addsDashNBeforeInPlace]' passed (0.001 seconds).
Test Case '-[KizbaTests.PassCLIWriteTests testInsert_alreadyExistsStderr_throwsEntryAlreadyExists]' started.
2026-05-24 08:25:44.154691+0200 Kizba[11882:1070534] [pass] pass insert failed: exe=/opt/homebrew/bin/pass argc=3 status=1 bytesIn=1 stderrBytes=31 excerpt=Error: foo/bar already exists.
Test Case '-[KizbaTests.PassCLIWriteTests testInsert_alreadyExistsStderr_throwsEntryAlreadyExists]' passed (0.107 seconds).
Test Case '-[KizbaTests.PassCLIWriteTests testInsert_cancellation_propagatesPassErrorCancelled]' started.
2026-05-24 08:25:44.317185+0200 Kizba[11882:1070534] [pass] pass insert cancelled: exe=/opt/homebrew/bin/pass argc=3 bytesIn=1
Test Case '-[KizbaTests.PassCLIWriteTests testInsert_cancellation_propagatesPassErrorCancelled]' passed (0.057 seconds).
Test Case '-[KizbaTests.PassCLIWriteTests testInsert_emptyBody_stillFedAsData]' started.
2026-05-24 08:25:44.321011+0200 Kizba[11882:1070534] [pass] pass insert ok: exe=/opt/homebrew/bin/pass argc=3 status=0 bytesIn=0 stderrBytes=0
Test Case '-[KizbaTests.PassCLIWriteTests testInsert_emptyBody_stillFedAsData]' passed (0.002 seconds).
Test Case '-[KizbaTests.PassCLIWriteTests testInsert_environmentIncludesAllConfiguredOverrides]' started.
2026-05-24 08:25:44.323482+0200 Kizba[11882:1070534] [pass] pass insert ok: exe=/opt/homebrew/bin/pass argc=3 status=0 bytesIn=1 stderrBytes=0
Test Case '-[KizbaTests.PassCLIWriteTests testInsert_environmentIncludesAllConfiguredOverrides]' passed (0.001 seconds).
Test Case '-[KizbaTests.PassCLIWriteTests testInsert_force_addsForceFlagBeforePath]' started.
2026-05-24 08:25:44.325042+0200 Kizba[11882:1070534] [pass] pass insert ok: exe=/opt/homebrew/bin/pass argc=4 status=0 bytesIn=7 stderrBytes=0
Test Case '-[KizbaTests.PassCLIWriteTests testInsert_force_addsForceFlagBeforePath]' passed (0.001 seconds).
Test Case '-[KizbaTests.PassCLIWriteTests testInsert_noForce_argvIsInsertDashMPath]' started.
2026-05-24 08:25:44.326784+0200 Kizba[11882:1070534] [pass] pass insert ok: exe=/opt/homebrew/bin/pass argc=3 status=0 bytesIn=7 stderrBytes=0
Test Case '-[KizbaTests.PassCLIWriteTests testInsert_noForce_argvIsInsertDashMPath]' passed (0.001 seconds).
Test Case '-[KizbaTests.PassCLIWriteTests testInsert_recipientNotFoundStderr_throwsRecipientNotFound]' started.
2026-05-24 08:25:44.328696+0200 Kizba[11882:1070534] [pass] pass insert failed: exe=/opt/homebrew/bin/pass argc=3 status=2 bytesIn=1 stderrBytes=47 excerpt=gpg: <redacted-email> skipped: No public key
Test Case '-[KizbaTests.PassCLIWriteTests testInsert_recipientNotFoundStderr_throwsRecipientNotFound]' passed (0.001 seconds).
Test Case '-[KizbaTests.PassCLIWriteTests testInsert_stdinPayloadIsCapturedExactly]' started.
2026-05-24 08:25:44.330203+0200 Kizba[11882:1070534] [pass] pass insert ok: exe=/opt/homebrew/bin/pass argc=3 status=0 bytesIn=18 stderrBytes=0
Test Case '-[KizbaTests.PassCLIWriteTests testInsert_stdinPayloadIsCapturedExactly]' passed (0.001 seconds).
Test Case '-[KizbaTests.PassCLIWriteTests testMove_environmentIncludesGnupgHomeOverride]' started.
2026-05-24 08:25:44.336974+0200 Kizba[11882:1070534] [pass] pass mv ok: exe=/opt/homebrew/bin/pass argc=3 status=0 stderrBytes=0
Test Case '-[KizbaTests.PassCLIWriteTests testMove_environmentIncludesGnupgHomeOverride]' passed (0.003 seconds).
Test Case '-[KizbaTests.PassCLIWriteTests testMove_force_addsDashFBeforeFrom]' started.
2026-05-24 08:25:44.338990+0200 Kizba[11882:1070534] [pass] pass mv ok: exe=/opt/homebrew/bin/pass argc=4 status=0 stderrBytes=0
Test Case '-[KizbaTests.PassCLIWriteTests testMove_force_addsDashFBeforeFrom]' passed (0.001 seconds).
Test Case '-[KizbaTests.PassCLIWriteTests testMove_noForce_argvIsMvFromTo]' started.
2026-05-24 08:25:44.340352+0200 Kizba[11882:1070534] [pass] pass mv ok: exe=/opt/homebrew/bin/pass argc=3 status=0 stderrBytes=0
Test Case '-[KizbaTests.PassCLIWriteTests testMove_noForce_argvIsMvFromTo]' passed (0.001 seconds).
Test Case '-[KizbaTests.PassCLIWriteTests testMove_sourceMissingStderr_throwsSourceNotFound]' started.
2026-05-24 08:25:44.351618+0200 Kizba[11882:1070534] [pass] pass mv failed: exe=/opt/homebrew/bin/pass argc=3 status=1 bytesIn=0 stderrBytes=41 excerpt=Error: a/b is not in the password store.
Test Case '-[KizbaTests.PassCLIWriteTests testMove_sourceMissingStderr_throwsSourceNotFound]' passed (0.011 seconds).
Test Case '-[KizbaTests.PassCLIWriteTests testMove_targetCollisionStderr_throwsEntryAlreadyExists]' started.
2026-05-24 08:25:44.353138+0200 Kizba[11882:1070534] [pass] pass mv failed: exe=/opt/homebrew/bin/pass argc=3 status=1 bytesIn=0 stderrBytes=59 excerpt=mv: refusing to overwrite '/store/.password-store/c/d.gpg'
Test Case '-[KizbaTests.PassCLIWriteTests testMove_targetCollisionStderr_throwsEntryAlreadyExists]' passed (0.001 seconds).
Test Case '-[KizbaTests.PassCLIWriteTests testRemove_argvIsRmDashFPath]' started.
2026-05-24 08:25:44.354457+0200 Kizba[11882:1070534] [pass] pass rm ok: exe=/opt/homebrew/bin/pass argc=3 status=0 stderrBytes=0
Test Case '-[KizbaTests.PassCLIWriteTests testRemove_argvIsRmDashFPath]' passed (0.001 seconds).
Test Case '-[KizbaTests.PassCLIWriteTests testRemove_environmentIncludesPasswordStoreDirOverride]' started.
2026-05-24 08:25:44.368813+0200 Kizba[11882:1070534] [pass] pass rm ok: exe=/opt/homebrew/bin/pass argc=3 status=0 stderrBytes=0
Test Case '-[KizbaTests.PassCLIWriteTests testRemove_environmentIncludesPasswordStoreDirOverride]' passed (0.015 seconds).
Test Case '-[KizbaTests.PassCLIWriteTests testRemove_missingEntryStderr_throwsSourceNotFound]' started.
2026-05-24 08:25:44.372357+0200 Kizba[11882:1070534] [pass] pass rm failed: exe=/opt/homebrew/bin/pass argc=3 status=1 bytesIn=0 stderrBytes=45 excerpt=Error: foo/bar is not in the password store.
Test Case '-[KizbaTests.PassCLIWriteTests testRemove_missingEntryStderr_throwsSourceNotFound]' passed (0.003 seconds).
Test Case '-[KizbaTests.PassCLIWriteTests testWriteOperations_envForcesClassicOpenPGPFormat]' started.
2026-05-24 08:25:44.375594+0200 Kizba[11882:1070534] [pass] pass insert ok: exe=/opt/homebrew/bin/pass argc=3 status=0 bytesIn=1 stderrBytes=0
2026-05-24 08:25:44.375721+0200 Kizba[11882:1070534] [pass] pass generate ok: exe=/opt/homebrew/bin/pass argc=3 status=0 stdoutBytes=52 stderrBytes=0
2026-05-24 08:25:44.375818+0200 Kizba[11882:1070534] [pass] pass generate-in-place ok: exe=/opt/homebrew/bin/pass argc=4 status=0 stdoutBytes=52 stderrBytes=0
2026-05-24 08:25:44.383581+0200 Kizba[11882:1070534] [pass] pass rm ok: exe=/opt/homebrew/bin/pass argc=3 status=0 stderrBytes=0
2026-05-24 08:25:44.383812+0200 Kizba[11882:1070534] [pass] pass mv ok: exe=/opt/homebrew/bin/pass argc=3 status=0 stderrBytes=0
Test Case '-[KizbaTests.PassCLIWriteTests testWriteOperations_envForcesClassicOpenPGPFormat]' passed (0.011 seconds).
Test Suite 'PassCLIWriteTests' passed at 2026-05-24 08:25:44.386.
	 Executed 27 tests, with 0 failures (0 unexpected) in 0.242 (0.263) seconds
Test Suite 'PassEntryRefinementTests' started at 2026-05-24 08:25:44.386.
Test Case '-[KizbaTests.PassEntryRefinementTests testCodableJSONShapeIsStable]' started.
Test Case '-[KizbaTests.PassEntryRefinementTests testCodableJSONShapeIsStable]' passed (0.003 seconds).
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
Test Suite 'PassEntryRefinementTests' passed at 2026-05-24 08:25:44.397.
	 Executed 6 tests, with 0 failures (0 unexpected) in 0.008 (0.011) seconds
Test Suite 'PassEntryTests' started at 2026-05-24 08:25:44.397.
Test Case '-[KizbaTests.PassEntryTests testCodableRoundTrip]' started.
Test Case '-[KizbaTests.PassEntryTests testCodableRoundTrip]' passed (0.001 seconds).
Test Case '-[KizbaTests.PassEntryTests testEquality]' started.
Test Case '-[KizbaTests.PassEntryTests testEquality]' passed (0.001 seconds).
Test Case '-[KizbaTests.PassEntryTests testNameAndFolderForNestedPath]' started.
Test Case '-[KizbaTests.PassEntryTests testNameAndFolderForNestedPath]' passed (0.001 seconds).
Test Case '-[KizbaTests.PassEntryTests testNameAndFolderForTopLevelPath]' started.
Test Case '-[KizbaTests.PassEntryTests testNameAndFolderForTopLevelPath]' passed (0.001 seconds).
Test Suite 'PassEntryTests' passed at 2026-05-24 08:25:44.402.
	 Executed 4 tests, with 0 failures (0 unexpected) in 0.003 (0.005) seconds
Test Suite 'PassErrorGitCasesTests' started at 2026-05-24 08:25:44.402.
Test Case '-[KizbaTests.PassErrorGitCasesTests testAutoRefreshes_gitCases_allFalse]' started.
Test Case '-[KizbaTests.PassErrorGitCasesTests testAutoRefreshes_gitCases_allFalse]' passed (0.001 seconds).
Test Case '-[KizbaTests.PassErrorGitCasesTests testEquality_gitCases]' started.
Test Case '-[KizbaTests.PassErrorGitCasesTests testEquality_gitCases]' passed (0.001 seconds).
Test Case '-[KizbaTests.PassErrorGitCasesTests testHashing_gitConflictWithPaths]' started.
Test Case '-[KizbaTests.PassErrorGitCasesTests testHashing_gitConflictWithPaths]' passed (0.001 seconds).
Test Case '-[KizbaTests.PassErrorGitCasesTests testInlineRecoverable_gitCases_allFalse]' started.
Test Case '-[KizbaTests.PassErrorGitCasesTests testInlineRecoverable_gitCases_allFalse]' passed (0.001 seconds).
Test Case '-[KizbaTests.PassErrorGitCasesTests testOnboardingHint_gitNoRemote_configureGitRemote]' started.
Test Case '-[KizbaTests.PassErrorGitCasesTests testOnboardingHint_gitNoRemote_configureGitRemote]' passed (0.001 seconds).
Test Case '-[KizbaTests.PassErrorGitCasesTests testOnboardingHint_gitNotInitialized_configureGitRemote]' started.
Test Case '-[KizbaTests.PassErrorGitCasesTests testOnboardingHint_gitNotInitialized_configureGitRemote]' passed (0.001 seconds).
Test Case '-[KizbaTests.PassErrorGitCasesTests testOnboardingHint_others_nil]' started.
Test Case '-[KizbaTests.PassErrorGitCasesTests testOnboardingHint_others_nil]' passed (0.001 seconds).
Test Suite 'PassErrorGitCasesTests' passed at 2026-05-24 08:25:44.432.
	 Executed 7 tests, with 0 failures (0 unexpected) in 0.005 (0.029) seconds
Test Suite 'PassErrorMapperTests' started at 2026-05-24 08:25:44.432.
Test Case '-[KizbaTests.PassErrorMapperTests testBinaryNotFoundMapsToBinaryNotFound_commandNotFoundShape]' started.
Test Case '-[KizbaTests.PassErrorMapperTests testBinaryNotFoundMapsToBinaryNotFound_commandNotFoundShape]' passed (0.001 seconds).
Test Case '-[KizbaTests.PassErrorMapperTests testBinaryNotFoundMapsToBinaryNotFound_pathShape]' started.
Test Case '-[KizbaTests.PassErrorMapperTests testBinaryNotFoundMapsToBinaryNotFound_pathShape]' passed (0.002 seconds).
Test Case '-[KizbaTests.PassErrorMapperTests testDecryptionFailureMapsToDecryptionFailed]' started.
Test Case '-[KizbaTests.PassErrorMapperTests testDecryptionFailureMapsToDecryptionFailed]' passed (0.002 seconds).
Test Case '-[KizbaTests.PassErrorMapperTests testEntryAlreadyExists_alreadyExistsBareForm]' started.
Test Case '-[KizbaTests.PassErrorMapperTests testEntryAlreadyExists_alreadyExistsBareForm]' passed (0.003 seconds).
Test Case '-[KizbaTests.PassErrorMapperTests testEntryAlreadyExists_cowardlyRefusing]' started.
Test Case '-[KizbaTests.PassErrorMapperTests testEntryAlreadyExists_cowardlyRefusing]' passed (0.012 seconds).
Test Case '-[KizbaTests.PassErrorMapperTests testEntryAlreadyExists_mvRefusingToOverwrite]' started.
Test Case '-[KizbaTests.PassErrorMapperTests testEntryAlreadyExists_mvRefusingToOverwrite]' passed (0.003 seconds).
Test Case '-[KizbaTests.PassErrorMapperTests testEntryAlreadyExists_withoutQuotedPath_returnsEmptyString]' started.
Test Case '-[KizbaTests.PassErrorMapperTests testEntryAlreadyExists_withoutQuotedPath_returnsEmptyString]' passed (0.002 seconds).
Test Case '-[KizbaTests.PassErrorMapperTests testInappropriateIoctlMapsToPinentryNotConfigured]' started.
Test Case '-[KizbaTests.PassErrorMapperTests testInappropriateIoctlMapsToPinentryNotConfigured]' passed (0.002 seconds).
Test Case '-[KizbaTests.PassErrorMapperTests testInvalidGpgId_passwordStoreEmpty]' started.
Test Case '-[KizbaTests.PassErrorMapperTests testInvalidGpgId_passwordStoreEmpty]' passed (0.001 seconds).
Test Case '-[KizbaTests.PassErrorMapperTests testInvalidGpgId_youMustRunPassInit]' started.
Test Case '-[KizbaTests.PassErrorMapperTests testInvalidGpgId_youMustRunPassInit]' passed (0.002 seconds).
Test Case '-[KizbaTests.PassErrorMapperTests testInvalidLength_bareForm]' started.
Test Case '-[KizbaTests.PassErrorMapperTests testInvalidLength_bareForm]' passed (0.002 seconds).
Test Case '-[KizbaTests.PassErrorMapperTests testInvalidLength_quotedToken]' started.
Test Case '-[KizbaTests.PassErrorMapperTests testInvalidLength_quotedToken]' passed (0.001 seconds).
Test Case '-[KizbaTests.PassErrorMapperTests testIsNotInPasswordStore_moveContext_mapsToSourceNotFound]' started.
Test Case '-[KizbaTests.PassErrorMapperTests testIsNotInPasswordStore_moveContext_mapsToSourceNotFound]' passed (0.001 seconds).
Test Case '-[KizbaTests.PassErrorMapperTests testIsNotInPasswordStore_nilContext_mapsToInvalidGpgId]' started.
Test Case '-[KizbaTests.PassErrorMapperTests testIsNotInPasswordStore_nilContext_mapsToInvalidGpgId]' passed (0.001 seconds).
Test Case '-[KizbaTests.PassErrorMapperTests testIsNotInPasswordStore_removeContext_mapsToSourceNotFound]' started.
Test Case '-[KizbaTests.PassErrorMapperTests testIsNotInPasswordStore_removeContext_mapsToSourceNotFound]' passed (0.001 seconds).
Test Case '-[KizbaTests.PassErrorMapperTests testIsNotInPasswordStore_showContext_mapsToInvalidGpgId]' started.
Test Case '-[KizbaTests.PassErrorMapperTests testIsNotInPasswordStore_showContext_mapsToInvalidGpgId]' passed (0.001 seconds).
Test Case '-[KizbaTests.PassErrorMapperTests testMapperExcerptIsAlwaysSanitised]' started.
Test Case '-[KizbaTests.PassErrorMapperTests testMapperExcerptIsAlwaysSanitised]' passed (0.001 seconds).
Test Case '-[KizbaTests.PassErrorMapperTests testPinentryMapsToPinentryNotConfigured]' started.
Test Case '-[KizbaTests.PassErrorMapperTests testPinentryMapsToPinentryNotConfigured]' passed (0.001 seconds).
Test Case '-[KizbaTests.PassErrorMapperTests testRecipientKeyNotTrusted_english_mapsToCase]' started.
Test Case '-[KizbaTests.PassErrorMapperTests testRecipientKeyNotTrusted_english_mapsToCase]' passed (0.011 seconds).
Test Case '-[KizbaTests.PassErrorMapperTests testRecipientKeyNotTrusted_french_mapsToCase]' started.
Test Case '-[KizbaTests.PassErrorMapperTests testRecipientKeyNotTrusted_french_mapsToCase]' passed (0.001 seconds).
Test Case '-[KizbaTests.PassErrorMapperTests testRecipientKeyNotTrusted_german_mapsToCase]' started.
Test Case '-[KizbaTests.PassErrorMapperTests testRecipientKeyNotTrusted_german_mapsToCase]' passed (0.001 seconds).
Test Case '-[KizbaTests.PassErrorMapperTests testRecipientKeyNotTrusted_sanitisedInput_keyHintIsNil]' started.
Test Case '-[KizbaTests.PassErrorMapperTests testRecipientKeyNotTrusted_sanitisedInput_keyHintIsNil]' passed (0.001 seconds).
Test Case '-[KizbaTests.PassErrorMapperTests testRecipientKeyNotTrusted_trustOnlyWithoutTTY_doesNotMatch]' started.
Test Case '-[KizbaTests.PassErrorMapperTests testRecipientKeyNotTrusted_trustOnlyWithoutTTY_doesNotMatch]' passed (0.002 seconds).
Test Case '-[KizbaTests.PassErrorMapperTests testRecipientKeyNotTrusted_ttyOnlyWithoutTrust_doesNotMatch]' started.
Test Case '-[KizbaTests.PassErrorMapperTests testRecipientKeyNotTrusted_ttyOnlyWithoutTrust_doesNotMatch]' passed (0.002 seconds).
Test Case '-[KizbaTests.PassErrorMapperTests testRecipientNotFound_email]' started.
Test Case '-[KizbaTests.PassErrorMapperTests testRecipientNotFound_email]' passed (0.002 seconds).
Test Case '-[KizbaTests.PassErrorMapperTests testRecipientNotFound_excerptRedactsEmail_payloadKeepsIt]' started.
Test Case '-[KizbaTests.PassErrorMapperTests testRecipientNotFound_excerptRedactsEmail_payloadKeepsIt]' passed (0.002 seconds).
Test Case '-[KizbaTests.PassErrorMapperTests testRecipientNotFound_excerptRedactsHexId_payloadKeepsIt]' started.
Test Case '-[KizbaTests.PassErrorMapperTests testRecipientNotFound_excerptRedactsHexId_payloadKeepsIt]' passed (0.001 seconds).
Test Case '-[KizbaTests.PassErrorMapperTests testRecipientNotFound_hexKeyId]' started.
Test Case '-[KizbaTests.PassErrorMapperTests testRecipientNotFound_hexKeyId]' passed (0.001 seconds).
Test Case '-[KizbaTests.PassErrorMapperTests testRecipientNotFound_stdinShape_fallsBackToEmpty]' started.
Test Case '-[KizbaTests.PassErrorMapperTests testRecipientNotFound_stdinShape_fallsBackToEmpty]' passed (0.001 seconds).
Test Case '-[KizbaTests.PassErrorMapperTests testSanitizeEnforcesLengthLimit]' started.
Test Case '-[KizbaTests.PassErrorMapperTests testSanitizeEnforcesLengthLimit]' passed (0.043 seconds).
Test Case '-[KizbaTests.PassErrorMapperTests testSanitizeIdempotent]' started.
Test Case '-[KizbaTests.PassErrorMapperTests testSanitizeIdempotent]' passed (0.021 seconds).
Test Case '-[KizbaTests.PassErrorMapperTests testSanitizeIdempotent_atExactCap]' started.
Test Case '-[KizbaTests.PassErrorMapperTests testSanitizeIdempotent_atExactCap]' passed (0.013 seconds).
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
Test Case '-[KizbaTests.PassErrorMapperTests testWriteSideMapping_isIdempotent]' started.
Test Case '-[KizbaTests.PassErrorMapperTests testWriteSideMapping_isIdempotent]' passed (0.001 seconds).
Test Suite 'PassErrorMapperTests' passed at 2026-05-24 08:25:44.628.
	 Executed 38 tests, with 0 failures (0 unexpected) in 0.140 (0.196) seconds
Test Suite 'PassErrorRefinementTests' started at 2026-05-24 08:25:44.628.
Test Case '-[KizbaTests.PassErrorRefinementTests testAutoRefreshesOnlyForSourceNotFound]' started.
Test Case '-[KizbaTests.PassErrorRefinementTests testAutoRefreshesOnlyForSourceNotFound]' passed (0.001 seconds).
Test Case '-[KizbaTests.PassErrorRefinementTests testHashableInSet]' started.
Test Case '-[KizbaTests.PassErrorRefinementTests testHashableInSet]' passed (0.001 seconds).
Test Case '-[KizbaTests.PassErrorRefinementTests testInlineRecoverableOnlyForEntryAlreadyExists]' started.
Test Case '-[KizbaTests.PassErrorRefinementTests testInlineRecoverableOnlyForEntryAlreadyExists]' passed (0.008 seconds).
Test Case '-[KizbaTests.PassErrorRefinementTests testOnboardingHintEqualityAndDistinctness]' started.
Test Case '-[KizbaTests.PassErrorRefinementTests testOnboardingHintEqualityAndDistinctness]' passed (0.001 seconds).
Test Case '-[KizbaTests.PassErrorRefinementTests testOnboardingHintMappings]' started.
Test Case '-[KizbaTests.PassErrorRefinementTests testOnboardingHintMappings]' passed (0.001 seconds).
Test Case '-[KizbaTests.PassErrorRefinementTests testParameterlessCasesAreDistinct]' started.
Test Case '-[KizbaTests.PassErrorRefinementTests testParameterlessCasesAreDistinct]' passed (0.001 seconds).
Test Case '-[KizbaTests.PassErrorRefinementTests testStderrExcerptIsPartOfIdentity]' started.
Test Case '-[KizbaTests.PassErrorRefinementTests testStderrExcerptIsPartOfIdentity]' passed (0.001 seconds).
Test Case '-[KizbaTests.PassErrorRefinementTests testStoreNotFoundCarriesPath]' started.
Test Case '-[KizbaTests.PassErrorRefinementTests testStoreNotFoundCarriesPath]' passed (0.008 seconds).
Test Case '-[KizbaTests.PassErrorRefinementTests testWriteSideCasesAreDistinctFromReadSide]' started.
Test Case '-[KizbaTests.PassErrorRefinementTests testWriteSideCasesAreDistinctFromReadSide]' passed (0.001 seconds).
Test Case '-[KizbaTests.PassErrorRefinementTests testWriteSideCasesEqualityAndPayload]' started.
Test Case '-[KizbaTests.PassErrorRefinementTests testWriteSideCasesEqualityAndPayload]' passed (0.001 seconds).
Test Case '-[KizbaTests.PassErrorRefinementTests testWriteSideCasesHashableInSet]' started.
Test Case '-[KizbaTests.PassErrorRefinementTests testWriteSideCasesHashableInSet]' passed (0.001 seconds).
Test Suite 'PassErrorRefinementTests' passed at 2026-05-24 08:25:44.652.
	 Executed 11 tests, with 0 failures (0 unexpected) in 0.022 (0.025) seconds
Test Suite 'PassErrorTests' started at 2026-05-24 08:25:44.653.
Test Case '-[KizbaTests.PassErrorTests testEqualityAcrossCases]' started.
Test Case '-[KizbaTests.PassErrorTests testEqualityAcrossCases]' passed (0.001 seconds).
Test Case '-[KizbaTests.PassErrorTests testIsErrorType]' started.
Test Case '-[KizbaTests.PassErrorTests testIsErrorType]' passed (0.001 seconds).
Test Suite 'PassErrorTests' passed at 2026-05-24 08:25:44.665.
	 Executed 2 tests, with 0 failures (0 unexpected) in 0.001 (0.013) seconds
Test Suite 'PassGenerateParserTests' started at 2026-05-24 08:25:44.665.
Test Case '-[KizbaTests.PassGenerateParserTests testParseAcceptsBareSinglePasswordLine]' started.
Test Case '-[KizbaTests.PassGenerateParserTests testParseAcceptsBareSinglePasswordLine]' passed (0.001 seconds).
Test Case '-[KizbaTests.PassGenerateParserTests testParseAcceptsBareSinglePasswordLineWithTrailingNewline]' started.
Test Case '-[KizbaTests.PassGenerateParserTests testParseAcceptsBareSinglePasswordLineWithTrailingNewline]' passed (0.001 seconds).
Test Case '-[KizbaTests.PassGenerateParserTests testParseAnsiOnlyInputThrows]' started.
Test Case '-[KizbaTests.PassGenerateParserTests testParseAnsiOnlyInputThrows]' passed (0.001 seconds).
Test Case '-[KizbaTests.PassGenerateParserTests testParseDefensiveAgainstGitStyleStdoutNoise]' started.
Test Case '-[KizbaTests.PassGenerateParserTests testParseDefensiveAgainstGitStyleStdoutNoise]' passed (0.024 seconds).
Test Case '-[KizbaTests.PassGenerateParserTests testParseEmptyStringThrows]' started.
Test Case '-[KizbaTests.PassGenerateParserTests testParseEmptyStringThrows]' passed (0.001 seconds).
Test Case '-[KizbaTests.PassGenerateParserTests testParseInPlaceColoredOutput]' started.
Test Case '-[KizbaTests.PassGenerateParserTests testParseInPlaceColoredOutput]' passed (0.001 seconds).
Test Case '-[KizbaTests.PassGenerateParserTests testParseInPlacePlainOutput]' started.
Test Case '-[KizbaTests.PassGenerateParserTests testParseInPlacePlainOutput]' passed (0.001 seconds).
Test Case '-[KizbaTests.PassGenerateParserTests testParsePass173ColoredOutput]' started.
Test Case '-[KizbaTests.PassGenerateParserTests testParsePass173ColoredOutput]' passed (0.001 seconds).
Test Case '-[KizbaTests.PassGenerateParserTests testParsePass173PlainOutput]' started.
Test Case '-[KizbaTests.PassGenerateParserTests testParsePass173PlainOutput]' passed (0.001 seconds).
Test Case '-[KizbaTests.PassGenerateParserTests testParsePass174ColoredOutput]' started.
Test Case '-[KizbaTests.PassGenerateParserTests testParsePass174ColoredOutput]' passed (0.001 seconds).
Test Case '-[KizbaTests.PassGenerateParserTests testParsePass174PlainOutput]' started.
Test Case '-[KizbaTests.PassGenerateParserTests testParsePass174PlainOutput]' passed (0.001 seconds).
Test Case '-[KizbaTests.PassGenerateParserTests testParseSingleNewlineThrows]' started.
Test Case '-[KizbaTests.PassGenerateParserTests testParseSingleNewlineThrows]' passed (0.001 seconds).
Test Case '-[KizbaTests.PassGenerateParserTests testParseStripsAnsiBeforeLastLineSelection]' started.
Test Case '-[KizbaTests.PassGenerateParserTests testParseStripsAnsiBeforeLastLineSelection]' passed (0.001 seconds).
Test Case '-[KizbaTests.PassGenerateParserTests testParseTolerantToMultipleTrailingNewlines]' started.
Test Case '-[KizbaTests.PassGenerateParserTests testParseTolerantToMultipleTrailingNewlines]' passed (0.001 seconds).
Test Case '-[KizbaTests.PassGenerateParserTests testParseTolerantToSingleTrailingNewline]' started.
Test Case '-[KizbaTests.PassGenerateParserTests testParseTolerantToSingleTrailingNewline]' passed (0.011 seconds).
Test Case '-[KizbaTests.PassGenerateParserTests testParseTrimsLeadingWhitespaceOnPasswordLine]' started.
Test Case '-[KizbaTests.PassGenerateParserTests testParseTrimsLeadingWhitespaceOnPasswordLine]' passed (0.001 seconds).
Test Case '-[KizbaTests.PassGenerateParserTests testParseWhitespaceOnlyStringThrows]' started.
Test Case '-[KizbaTests.PassGenerateParserTests testParseWhitespaceOnlyStringThrows]' passed (0.001 seconds).
Test Case '-[KizbaTests.PassGenerateParserTests testStripAnsiIsIdempotent]' started.
Test Case '-[KizbaTests.PassGenerateParserTests testStripAnsiIsIdempotent]' passed (0.001 seconds).
Test Case '-[KizbaTests.PassGenerateParserTests testStripAnsiOnEmptyStringReturnsEmpty]' started.
Test Case '-[KizbaTests.PassGenerateParserTests testStripAnsiOnEmptyStringReturnsEmpty]' passed (0.001 seconds).
Test Case '-[KizbaTests.PassGenerateParserTests testStripAnsiOnPlainTextIsIdentity]' started.
Test Case '-[KizbaTests.PassGenerateParserTests testStripAnsiOnPlainTextIsIdentity]' passed (0.013 seconds).
Test Case '-[KizbaTests.PassGenerateParserTests testStripAnsiPreservesBareBracketCharacters]' started.
Test Case '-[KizbaTests.PassGenerateParserTests testStripAnsiPreservesBareBracketCharacters]' passed (0.001 seconds).
Test Case '-[KizbaTests.PassGenerateParserTests testStripAnsiPreservesContentBetweenSequences]' started.
Test Case '-[KizbaTests.PassGenerateParserTests testStripAnsiPreservesContentBetweenSequences]' passed (0.001 seconds).
Test Case '-[KizbaTests.PassGenerateParserTests testStripAnsiRemovesMultipleAdjacentSequences]' started.
Test Case '-[KizbaTests.PassGenerateParserTests testStripAnsiRemovesMultipleAdjacentSequences]' passed (0.001 seconds).
Test Case '-[KizbaTests.PassGenerateParserTests testStripAnsiRemovesParameterizedSequences]' started.
Test Case '-[KizbaTests.PassGenerateParserTests testStripAnsiRemovesParameterizedSequences]' passed (0.001 seconds).
Test Case '-[KizbaTests.PassGenerateParserTests testStripAnsiRemovesSingleSequence]' started.
Test Case '-[KizbaTests.PassGenerateParserTests testStripAnsiRemovesSingleSequence]' passed (0.001 seconds).
Test Suite 'PassGenerateParserTests' passed at 2026-05-24 08:25:44.754.
	 Executed 25 tests, with 0 failures (0 unexpected) in 0.062 (0.089) seconds
Test Suite 'PassGitErrorMapperTests' started at 2026-05-24 08:25:44.755.
Test Case '-[KizbaTests.PassGitErrorMapperTests testAuthenticationFailed_mapsToGitAuthFailed]' started.
Test Case '-[KizbaTests.PassGitErrorMapperTests testAuthenticationFailed_mapsToGitAuthFailed]' passed (0.004 seconds).
Test Case '-[KizbaTests.PassGitErrorMapperTests testAutomaticMergeFailed_mapsToGitConflict]' started.
Test Case '-[KizbaTests.PassGitErrorMapperTests testAutomaticMergeFailed_mapsToGitConflict]' passed (0.003 seconds).
Test Case '-[KizbaTests.PassGitErrorMapperTests testConflictMulti_mapsToGitConflictWithMultiplePaths]' started.
Test Case '-[KizbaTests.PassGitErrorMapperTests testConflictMulti_mapsToGitConflictWithMultiplePaths]' passed (0.008 seconds).
Test Case '-[KizbaTests.PassGitErrorMapperTests testConflictPathExtraction_capsAt20]' started.
Test Case '-[KizbaTests.PassGitErrorMapperTests testConflictPathExtraction_capsAt20]' passed (0.001 seconds).
Test Case '-[KizbaTests.PassGitErrorMapperTests testConflictSingle_mapsToGitConflictWithPath]' started.
Test Case '-[KizbaTests.PassGitErrorMapperTests testConflictSingle_mapsToGitConflictWithPath]' passed (0.001 seconds).
Test Case '-[KizbaTests.PassGitErrorMapperTests testCouldNotReadUsername_mapsToGitAuthFailed]' started.
Test Case '-[KizbaTests.PassGitErrorMapperTests testCouldNotReadUsername_mapsToGitAuthFailed]' passed (0.001 seconds).
Test Case '-[KizbaTests.PassGitErrorMapperTests testCouldNotResolveHost_mapsToGitNetworkUnavailable]' started.
Test Case '-[KizbaTests.PassGitErrorMapperTests testCouldNotResolveHost_mapsToGitNetworkUnavailable]' passed (0.003 seconds).
Test Case '-[KizbaTests.PassGitErrorMapperTests testDoesNotAppearToBeGitRepo_mapsToGitNoRemote]' started.
Test Case '-[KizbaTests.PassGitErrorMapperTests testDoesNotAppearToBeGitRepo_mapsToGitNoRemote]' passed (0.001 seconds).
Test Case '-[KizbaTests.PassGitErrorMapperTests testExcerptIsSanitised]' started.
Test Case '-[KizbaTests.PassGitErrorMapperTests testExcerptIsSanitised]' passed (0.001 seconds).
Test Case '-[KizbaTests.PassGitErrorMapperTests testFetchFirst_mapsToGitRejected]' started.
Test Case '-[KizbaTests.PassGitErrorMapperTests testFetchFirst_mapsToGitRejected]' passed (0.001 seconds).
Test Case '-[KizbaTests.PassGitErrorMapperTests testNetworkIsUnreachable_mapsToGitNetworkUnavailable]' started.
Test Case '-[KizbaTests.PassGitErrorMapperTests testNetworkIsUnreachable_mapsToGitNetworkUnavailable]' passed (0.001 seconds).
Test Case '-[KizbaTests.PassGitErrorMapperTests testNoConfiguredPushDestination_mapsToGitNoRemote]' started.
Test Case '-[KizbaTests.PassGitErrorMapperTests testNoConfiguredPushDestination_mapsToGitNoRemote]' passed (0.003 seconds).
Test Case '-[KizbaTests.PassGitErrorMapperTests testNonFastForward_mapsToGitRejected]' started.
Test Case '-[KizbaTests.PassGitErrorMapperTests testNonFastForward_mapsToGitRejected]' passed (0.003 seconds).
Test Case '-[KizbaTests.PassGitErrorMapperTests testNotAGitRepository_mapsToGitNotInitialized]' started.
Test Case '-[KizbaTests.PassGitErrorMapperTests testNotAGitRepository_mapsToGitNotInitialized]' passed (0.003 seconds).
Test Case '-[KizbaTests.PassGitErrorMapperTests testOperationTimedOut_mapsToGitNetworkUnavailable]' started.
Test Case '-[KizbaTests.PassGitErrorMapperTests testOperationTimedOut_mapsToGitNetworkUnavailable]' passed (0.001 seconds).
Test Case '-[KizbaTests.PassGitErrorMapperTests testPermissionDenied_mapsToGitAuthFailed]' started.
Test Case '-[KizbaTests.PassGitErrorMapperTests testPermissionDenied_mapsToGitAuthFailed]' passed (0.001 seconds).
Test Case '-[KizbaTests.PassGitErrorMapperTests testSanitisationIsIdempotent]' started.
Test Case '-[KizbaTests.PassGitErrorMapperTests testSanitisationIsIdempotent]' passed (0.001 seconds).
Test Case '-[KizbaTests.PassGitErrorMapperTests testUnknownStderr_fallsBackToWriteFailed]' started.
Test Case '-[KizbaTests.PassGitErrorMapperTests testUnknownStderr_fallsBackToWriteFailed]' passed (0.003 seconds).
Test Case '-[KizbaTests.PassGitErrorMapperTests testUpdatesWereRejected_mapsToGitRejected]' started.
Test Case '-[KizbaTests.PassGitErrorMapperTests testUpdatesWereRejected_mapsToGitRejected]' passed (0.015 seconds).
Test Suite 'PassGitErrorMapperTests' passed at 2026-05-24 08:25:44.821.
	 Executed 19 tests, with 0 failures (0 unexpected) in 0.054 (0.066) seconds
Test Suite 'PassGitIntegrationTests' started at 2026-05-24 08:25:44.821.
Test Case '-[KizbaTests.PassGitIntegrationTests testPull_conflict]' started.
/Users/kirillsimagin/dev/my/worldproject/kizba/KizbaTests/PassGitIntegrationTests.swift:14: -[KizbaTests.PassGitIntegrationTests testPull_conflict] : Test skipped - E2E tests require KIZBA_E2E=1 and KIZBA_GIT_E2E=1
Test Case '-[KizbaTests.PassGitIntegrationTests testPull_conflict]' skipped (0.103 seconds).
Test Case '-[KizbaTests.PassGitIntegrationTests testPull_happy]' started.
/Users/kirillsimagin/dev/my/worldproject/kizba/KizbaTests/PassGitIntegrationTests.swift:14: -[KizbaTests.PassGitIntegrationTests testPull_happy] : Test skipped - E2E tests require KIZBA_E2E=1 and KIZBA_GIT_E2E=1
Test Case '-[KizbaTests.PassGitIntegrationTests testPull_happy]' skipped (0.003 seconds).
Test Case '-[KizbaTests.PassGitIntegrationTests testPush_alreadyUpToDate]' started.
/Users/kirillsimagin/dev/my/worldproject/kizba/KizbaTests/PassGitIntegrationTests.swift:14: -[KizbaTests.PassGitIntegrationTests testPush_alreadyUpToDate] : Test skipped - E2E tests require KIZBA_E2E=1 and KIZBA_GIT_E2E=1
Test Case '-[KizbaTests.PassGitIntegrationTests testPush_alreadyUpToDate]' skipped (0.104 seconds).
Test Case '-[KizbaTests.PassGitIntegrationTests testPush_happy]' started.
/Users/kirillsimagin/dev/my/worldproject/kizba/KizbaTests/PassGitIntegrationTests.swift:14: -[KizbaTests.PassGitIntegrationTests testPush_happy] : Test skipped - E2E tests require KIZBA_E2E=1 and KIZBA_GIT_E2E=1
Test Case '-[KizbaTests.PassGitIntegrationTests testPush_happy]' skipped (0.003 seconds).
Test Case '-[KizbaTests.PassGitIntegrationTests testStatus_clean]' started.
/Users/kirillsimagin/dev/my/worldproject/kizba/KizbaTests/PassGitIntegrationTests.swift:14: -[KizbaTests.PassGitIntegrationTests testStatus_clean] : Test skipped - E2E tests require KIZBA_E2E=1 and KIZBA_GIT_E2E=1
Test Case '-[KizbaTests.PassGitIntegrationTests testStatus_clean]' skipped (0.104 seconds).
Test Case '-[KizbaTests.PassGitIntegrationTests testStatus_dirty]' started.
/Users/kirillsimagin/dev/my/worldproject/kizba/KizbaTests/PassGitIntegrationTests.swift:14: -[KizbaTests.PassGitIntegrationTests testStatus_dirty] : Test skipped - E2E tests require KIZBA_E2E=1 and KIZBA_GIT_E2E=1
Test Case '-[KizbaTests.PassGitIntegrationTests testStatus_dirty]' skipped (0.103 seconds).
Test Case '-[KizbaTests.PassGitIntegrationTests testStatus_noRemote]' started.
/Users/kirillsimagin/dev/my/worldproject/kizba/KizbaTests/PassGitIntegrationTests.swift:14: -[KizbaTests.PassGitIntegrationTests testStatus_noRemote] : Test skipped - E2E tests require KIZBA_E2E=1 and KIZBA_GIT_E2E=1
Test Case '-[KizbaTests.PassGitIntegrationTests testStatus_noRemote]' skipped (0.206 seconds).
Test Suite 'PassGitIntegrationTests' passed at 2026-05-24 08:25:45.452.
	 Executed 7 tests, with 7 tests skipped and 0 failures (0 unexpected) in 0.627 (0.631) seconds
Test Suite 'PassManagingTests' started at 2026-05-24 08:25:45.453.
Test Case '-[KizbaTests.PassManagingTests testListEntriesReturnsFixture]' started.
Test Case '-[KizbaTests.PassManagingTests testListEntriesReturnsFixture]' passed (0.002 seconds).
Test Case '-[KizbaTests.PassManagingTests testShowRoundTrip]' started.
Test Case '-[KizbaTests.PassManagingTests testShowRoundTrip]' passed (0.002 seconds).
Test Case '-[KizbaTests.PassManagingTests testShowSurfacesDecryptionFailureForUnknownEntry]' started.
Test Case '-[KizbaTests.PassManagingTests testShowSurfacesDecryptionFailureForUnknownEntry]' passed (0.001 seconds).
Test Case '-[KizbaTests.PassManagingTests testStoreLocationIsExposed]' started.
Test Case '-[KizbaTests.PassManagingTests testStoreLocationIsExposed]' passed (0.001 seconds).
Test Suite 'PassManagingTests' passed at 2026-05-24 08:25:45.461.
	 Executed 4 tests, with 0 failures (0 unexpected) in 0.007 (0.009) seconds
Test Suite 'PassMetadataRefinementTests' started at 2026-05-24 08:25:45.461.
Test Case '-[KizbaTests.PassMetadataRefinementTests testCodableRoundTripPreservesDuplicateKeysAndOrder]' started.
Test Case '-[KizbaTests.PassMetadataRefinementTests testCodableRoundTripPreservesDuplicateKeysAndOrder]' passed (0.002 seconds).
Test Case '-[KizbaTests.PassMetadataRefinementTests testEmptyStringNotesIsDistinctFromNil]' started.
Test Case '-[KizbaTests.PassMetadataRefinementTests testEmptyStringNotesIsDistinctFromNil]' passed (0.002 seconds).
Test Case '-[KizbaTests.PassMetadataRefinementTests testFieldHashableDistinguishesKeyAndValue]' started.
Test Case '-[KizbaTests.PassMetadataRefinementTests testFieldHashableDistinguishesKeyAndValue]' passed (0.001 seconds).
Test Case '-[KizbaTests.PassMetadataRefinementTests testFirstValueIsCaseSensitive]' started.
Test Case '-[KizbaTests.PassMetadataRefinementTests testFirstValueIsCaseSensitive]' passed (0.002 seconds).
Test Suite 'PassMetadataRefinementTests' passed at 2026-05-24 08:25:45.482.
	 Executed 4 tests, with 0 failures (0 unexpected) in 0.007 (0.021) seconds
Test Suite 'PassMetadataTests' started at 2026-05-24 08:25:45.483.
Test Case '-[KizbaTests.PassMetadataTests testCodableRoundTripPreservesFieldOrder]' started.
Test Case '-[KizbaTests.PassMetadataTests testCodableRoundTripPreservesFieldOrder]' passed (0.002 seconds).
Test Case '-[KizbaTests.PassMetadataTests testEmptyDefaults]' started.
Test Case '-[KizbaTests.PassMetadataTests testEmptyDefaults]' passed (0.002 seconds).
Test Case '-[KizbaTests.PassMetadataTests testFirstValueRespectsOrderAndDuplicates]' started.
Test Case '-[KizbaTests.PassMetadataTests testFirstValueRespectsOrderAndDuplicates]' passed (0.001 seconds).
Test Suite 'PassMetadataTests' passed at 2026-05-24 08:25:45.496.
	 Executed 3 tests, with 0 failures (0 unexpected) in 0.004 (0.013) seconds
Test Suite 'PassSecretRefinementTests' started at 2026-05-24 08:25:45.496.
Test Case '-[KizbaTests.PassSecretRefinementTests testEqualityIgnoresMetadataIdentityButRespectsContents]' started.
Test Case '-[KizbaTests.PassSecretRefinementTests testEqualityIgnoresMetadataIdentityButRespectsContents]' passed (0.002 seconds).
Test Case '-[KizbaTests.PassSecretRefinementTests testIsSendable]' started.
Test Case '-[KizbaTests.PassSecretRefinementTests testIsSendable]' passed (0.002 seconds).
Test Case '-[KizbaTests.PassSecretRefinementTests testLargePasswordRoundTripsThroughEquality]' started.
Test Case '-[KizbaTests.PassSecretRefinementTests testLargePasswordRoundTripsThroughEquality]' passed (0.002 seconds).
Test Case '-[KizbaTests.PassSecretRefinementTests testPasswordPreservesWhitespaceAndNewlinesVerbatim]' started.
Test Case '-[KizbaTests.PassSecretRefinementTests testPasswordPreservesWhitespaceAndNewlinesVerbatim]' passed (0.002 seconds).
Test Suite 'PassSecretRefinementTests' passed at 2026-05-24 08:25:45.518.
	 Executed 4 tests, with 0 failures (0 unexpected) in 0.008 (0.021) seconds
Test Suite 'PassSecretSecurityTests' started at 2026-05-24 08:25:45.518.
Test Case '-[KizbaTests.PassSecretSecurityTests testInitAndEquality]' started.
Test Case '-[KizbaTests.PassSecretSecurityTests testInitAndEquality]' passed (0.002 seconds).
Test Case '-[KizbaTests.PassSecretSecurityTests testIsNotCodable]' started.
Test Case '-[KizbaTests.PassSecretSecurityTests testIsNotCodable]' passed (0.002 seconds).
Test Case '-[KizbaTests.PassSecretSecurityTests testIsNotCustomStringConvertible]' started.
Test Case '-[KizbaTests.PassSecretSecurityTests testIsNotCustomStringConvertible]' passed (0.002 seconds).
Test Suite 'PassSecretSecurityTests' passed at 2026-05-24 08:25:45.526.
	 Executed 3 tests, with 0 failures (0 unexpected) in 0.005 (0.008) seconds
Test Suite 'PassSecretSerializerTests' started at 2026-05-24 08:25:45.526.
Test Case '-[KizbaTests.PassSecretSerializerTests test_roundTrip_notesStartingWithKeyColonValue_isKnownLimitation]' started.
/Users/kirillsimagin/dev/my/worldproject/kizba/KizbaTests/PassSecretSerializerTests.swift:350: -[KizbaTests.PassSecretSerializerTests test_roundTrip_notesStartingWithKeyColonValue_isKnownLimitation] : Test skipped - Inherent limitation of the `pass` informal body format: notes whose first line matches /^[A-Za-z0-9_.-]+: / are indistinguishable from metadata on re-parse. Documented in PassSecretSerializer.swift. MetadataValidator may surface this as a form-time warning in Phase F.
Test Case '-[KizbaTests.PassSecretSerializerTests test_roundTrip_notesStartingWithKeyColonValue_isKnownLimitation]' skipped (0.010 seconds).
Test Case '-[KizbaTests.PassSecretSerializerTests testDraftOverload_emptyNotes_treatedSameAsNil]' started.
Test Case '-[KizbaTests.PassSecretSerializerTests testDraftOverload_emptyNotes_treatedSameAsNil]' passed (0.002 seconds).
Test Case '-[KizbaTests.PassSecretSerializerTests testDraftOverload_matchesSnapshotSerialisation]' started.
Test Case '-[KizbaTests.PassSecretSerializerTests testDraftOverload_matchesSnapshotSerialisation]' passed (0.002 seconds).
Test Case '-[KizbaTests.PassSecretSerializerTests testDuplicateMetadataKeys_preservedInOrder]' started.
Test Case '-[KizbaTests.PassSecretSerializerTests testDuplicateMetadataKeys_preservedInOrder]' passed (0.001 seconds).
Test Case '-[KizbaTests.PassSecretSerializerTests testEmptyNotesString_treatedAsNoNotes]' started.
Test Case '-[KizbaTests.PassSecretSerializerTests testEmptyNotesString_treatedAsNoNotes]' passed (0.002 seconds).
Test Case '-[KizbaTests.PassSecretSerializerTests testEmptyPassword_emitsLoneNewline]' started.
Test Case '-[KizbaTests.PassSecretSerializerTests testEmptyPassword_emitsLoneNewline]' passed (0.011 seconds).
Test Case '-[KizbaTests.PassSecretSerializerTests testMetadataValueContainingColon_preservedVerbatim]' started.
Test Case '-[KizbaTests.PassSecretSerializerTests testMetadataValueContainingColon_preservedVerbatim]' passed (0.002 seconds).
Test Case '-[KizbaTests.PassSecretSerializerTests testMetadataValueWithLeadingTrailingSpaces_notTrimmed]' started.
Test Case '-[KizbaTests.PassSecretSerializerTests testMetadataValueWithLeadingTrailingSpaces_notTrimmed]' passed (0.001 seconds).
Test Case '-[KizbaTests.PassSecretSerializerTests testNotesWithEmbeddedBlankLine_preservedVerbatim]' started.
Test Case '-[KizbaTests.PassSecretSerializerTests testNotesWithEmbeddedBlankLine_preservedVerbatim]' passed (0.001 seconds).
Test Case '-[KizbaTests.PassSecretSerializerTests testNotesWithTrailingNewline_preservedVerbatim]' started.
Test Case '-[KizbaTests.PassSecretSerializerTests testNotesWithTrailingNewline_preservedVerbatim]' passed (0.001 seconds).
Test Case '-[KizbaTests.PassSecretSerializerTests testPasswordOnly_emitsPasswordPlusSingleNewline]' started.
Test Case '-[KizbaTests.PassSecretSerializerTests testPasswordOnly_emitsPasswordPlusSingleNewline]' passed (0.002 seconds).
Test Case '-[KizbaTests.PassSecretSerializerTests testPasswordPlusMetadataPlusMultiLineNotes]' started.
Test Case '-[KizbaTests.PassSecretSerializerTests testPasswordPlusMetadataPlusMultiLineNotes]' passed (0.002 seconds).
Test Case '-[KizbaTests.PassSecretSerializerTests testPasswordPlusMetadataPlusNotes]' started.
Test Case '-[KizbaTests.PassSecretSerializerTests testPasswordPlusMetadataPlusNotes]' passed (0.002 seconds).
Test Case '-[KizbaTests.PassSecretSerializerTests testPasswordPlusNotes_noMetadata_noLeadingSeparator]' started.
Test Case '-[KizbaTests.PassSecretSerializerTests testPasswordPlusNotes_noMetadata_noLeadingSeparator]' passed (0.001 seconds).
Test Case '-[KizbaTests.PassSecretSerializerTests testPasswordPlusOneMetadataPair_noNotes]' started.
Test Case '-[KizbaTests.PassSecretSerializerTests testPasswordPlusOneMetadataPair_noNotes]' passed (0.012 seconds).
Test Case '-[KizbaTests.PassSecretSerializerTests testPasswordPlusTwoMetadataPairs_orderPreserved]' started.
Test Case '-[KizbaTests.PassSecretSerializerTests testPasswordPlusTwoMetadataPairs_orderPreserved]' passed (0.001 seconds).
Test Case '-[KizbaTests.PassSecretSerializerTests testRoundTrip_parseOfSerialiseEqualsOriginal_overCorpus]' started.
Test Case '-[KizbaTests.PassSecretSerializerTests testRoundTrip_parseOfSerialiseEqualsOriginal_overCorpus]' passed (0.001 seconds).
Test Suite 'PassSecretSerializerTests' passed at 2026-05-24 08:25:45.602.
	 Executed 17 tests, with 1 test skipped and 0 failures (0 unexpected) in 0.053 (0.076) seconds
Test Suite 'PassShowParserTests' started at 2026-05-24 08:25:45.602.
Test Case '-[KizbaTests.PassShowParserTests testColonInValue]' started.
Test Case '-[KizbaTests.PassShowParserTests testColonInValue]' passed (0.001 seconds).
Test Case '-[KizbaTests.PassShowParserTests testDuplicateKeys]' started.
Test Case '-[KizbaTests.PassShowParserTests testDuplicateKeys]' passed (0.002 seconds).
Test Case '-[KizbaTests.PassShowParserTests testEmptyInput_throws]' started.
Test Case '-[KizbaTests.PassShowParserTests testEmptyInput_throws]' passed (0.002 seconds).
Test Case '-[KizbaTests.PassShowParserTests testNotesContainingKeyLikeLines]' started.
Test Case '-[KizbaTests.PassShowParserTests testNotesContainingKeyLikeLines]' passed (0.001 seconds).
Test Case '-[KizbaTests.PassShowParserTests testNotesStartingImmediatelyAfterPassword]' started.
Test Case '-[KizbaTests.PassShowParserTests testNotesStartingImmediatelyAfterPassword]' passed (0.001 seconds).
Test Case '-[KizbaTests.PassShowParserTests testPasswordOnly_noTrailingNewline]' started.
Test Case '-[KizbaTests.PassShowParserTests testPasswordOnly_noTrailingNewline]' passed (0.001 seconds).
Test Case '-[KizbaTests.PassShowParserTests testPasswordOnly]' started.
Test Case '-[KizbaTests.PassShowParserTests testPasswordOnly]' passed (0.004 seconds).
Test Case '-[KizbaTests.PassShowParserTests testWithMetadata]' started.
Test Case '-[KizbaTests.PassShowParserTests testWithMetadata]' passed (0.001 seconds).
Test Case '-[KizbaTests.PassShowParserTests testWithNotes_multiLine_preservesNewlines]' started.
Test Case '-[KizbaTests.PassShowParserTests testWithNotes_multiLine_preservesNewlines]' passed (0.001 seconds).
Test Case '-[KizbaTests.PassShowParserTests testWithNotes_singleLine]' started.
Test Case '-[KizbaTests.PassShowParserTests testWithNotes_singleLine]' passed (0.001 seconds).
Test Suite 'PassShowParserTests' passed at 2026-05-24 08:25:45.630.
	 Executed 10 tests, with 0 failures (0 unexpected) in 0.012 (0.028) seconds
Test Suite 'PassWriteIntegrationTests' started at 2026-05-24 08:25:45.630.
Test Case '-[KizbaTests.PassWriteIntegrationTests testChanges_multiEventStream_observesAllInOrder]' started.
/Users/kirillsimagin/dev/my/worldproject/kizba/KizbaTests/PassWriteIntegrationTests.swift:100: -[KizbaTests.PassWriteIntegrationTests testChanges_multiEventStream_observesAllInOrder] : Test skipped - Set KIZBA_E2E=1 to run integration tests against real pass + gpg
Test Case '-[KizbaTests.PassWriteIntegrationTests testChanges_multiEventStream_observesAllInOrder]' skipped (0.022 seconds).
Test Case '-[KizbaTests.PassWriteIntegrationTests testGenerateThenShow_returnsRequestedLengthPassword]' started.
/Users/kirillsimagin/dev/my/worldproject/kizba/KizbaTests/PassWriteIntegrationTests.swift:100: -[KizbaTests.PassWriteIntegrationTests testGenerateThenShow_returnsRequestedLengthPassword] : Test skipped - Set KIZBA_E2E=1 to run integration tests against real pass + gpg
Test Case '-[KizbaTests.PassWriteIntegrationTests testGenerateThenShow_returnsRequestedLengthPassword]' skipped (0.003 seconds).
Test Case '-[KizbaTests.PassWriteIntegrationTests testInsert_forceOverwrite_replacesExistingContent]' started.
/Users/kirillsimagin/dev/my/worldproject/kizba/KizbaTests/PassWriteIntegrationTests.swift:100: -[KizbaTests.PassWriteIntegrationTests testInsert_forceOverwrite_replacesExistingContent] : Test skipped - Set KIZBA_E2E=1 to run integration tests against real pass + gpg
Test Case '-[KizbaTests.PassWriteIntegrationTests testInsert_forceOverwrite_replacesExistingContent]' skipped (0.002 seconds).
Test Case '-[KizbaTests.PassWriteIntegrationTests testInsert_forceTrue_doesNotBlockOnPinentry]' started.
/Users/kirillsimagin/dev/my/worldproject/kizba/KizbaTests/PassWriteIntegrationTests.swift:100: -[KizbaTests.PassWriteIntegrationTests testInsert_forceTrue_doesNotBlockOnPinentry] : Test skipped - Set KIZBA_E2E=1 to run integration tests against real pass + gpg
Test Case '-[KizbaTests.PassWriteIntegrationTests testInsert_forceTrue_doesNotBlockOnPinentry]' skipped (0.003 seconds).
Test Case '-[KizbaTests.PassWriteIntegrationTests testInsertThenShow_roundTripsSecret]' started.
/Users/kirillsimagin/dev/my/worldproject/kizba/KizbaTests/PassWriteIntegrationTests.swift:100: -[KizbaTests.PassWriteIntegrationTests testInsertThenShow_roundTripsSecret] : Test skipped - Set KIZBA_E2E=1 to run integration tests against real pass + gpg
Test Case '-[KizbaTests.PassWriteIntegrationTests testInsertThenShow_roundTripsSecret]' skipped (0.001 seconds).
Test Case '-[KizbaTests.PassWriteIntegrationTests testMove_relocatesEntry_andEmitsMovedEvent]' started.
/Users/kirillsimagin/dev/my/worldproject/kizba/KizbaTests/PassWriteIntegrationTests.swift:100: -[KizbaTests.PassWriteIntegrationTests testMove_relocatesEntry_andEmitsMovedEvent] : Test skipped - Set KIZBA_E2E=1 to run integration tests against real pass + gpg
Test Case '-[KizbaTests.PassWriteIntegrationTests testMove_relocatesEntry_andEmitsMovedEvent]' skipped (0.105 seconds).
Test Case '-[KizbaTests.PassWriteIntegrationTests testRemove_dropsEntryFromListing_andEmitsRemovedEvent]' started.
/Users/kirillsimagin/dev/my/worldproject/kizba/KizbaTests/PassWriteIntegrationTests.swift:100: -[KizbaTests.PassWriteIntegrationTests testRemove_dropsEntryFromListing_andEmitsRemovedEvent] : Test skipped - Set KIZBA_E2E=1 to run integration tests against real pass + gpg
Test Case '-[KizbaTests.PassWriteIntegrationTests testRemove_dropsEntryFromListing_andEmitsRemovedEvent]' skipped (0.003 seconds).
Test Suite 'PassWriteIntegrationTests' passed at 2026-05-24 08:25:45.783.
	 Executed 7 tests, with 7 tests skipped and 0 failures (0 unexpected) in 0.140 (0.152) seconds
Test Suite 'PasswordStoreScannerTests' started at 2026-05-24 08:25:45.783.
Test Case '-[KizbaTests.PasswordStoreScannerTests testCachingAndInvalidate]' started.
Test Case '-[KizbaTests.PasswordStoreScannerTests testCachingAndInvalidate]' passed (0.012 seconds).
Test Case '-[KizbaTests.PasswordStoreScannerTests testCaseInsensitiveGpgExtension]' started.
Test Case '-[KizbaTests.PasswordStoreScannerTests testCaseInsensitiveGpgExtension]' passed (0.010 seconds).
Test Case '-[KizbaTests.PasswordStoreScannerTests testEmptyStore_returnsEmpty]' started.
Test Case '-[KizbaTests.PasswordStoreScannerTests testEmptyStore_returnsEmpty]' passed (0.005 seconds).
Test Case '-[KizbaTests.PasswordStoreScannerTests testGpgIdAndGitIgnored]' started.
Test Case '-[KizbaTests.PasswordStoreScannerTests testGpgIdAndGitIgnored]' passed (0.031 seconds).
Test Case '-[KizbaTests.PasswordStoreScannerTests testMissingRoot_throws]' started.
2026-05-24 08:25:45.846468+0200 Kizba[11882:1071152] [discovery] PasswordStoreScanner: store root missing at /var/folders/2p/cjjcq6ys0cnc6cp8y7lv9vqr0000gn/T/kizba-tempstore-9D8D5939-C4E7-4F56-963F-2964105AEF66/does-not-exist
Test Case '-[KizbaTests.PasswordStoreScannerTests testMissingRoot_throws]' passed (0.005 seconds).
Test Case '-[KizbaTests.PasswordStoreScannerTests testStandardLayout_returnsExpectedSortedEntries]' started.
Test Case '-[KizbaTests.PasswordStoreScannerTests testStandardLayout_returnsExpectedSortedEntries]' passed (0.020 seconds).
Test Case '-[KizbaTests.PasswordStoreScannerTests testUnicodeAndSpacesPreserved]' started.
Test Case '-[KizbaTests.PasswordStoreScannerTests testUnicodeAndSpacesPreserved]' passed (0.019 seconds).
Test Case '-[KizbaTests.PasswordStoreScannerTests testValidateStoreRoot]' started.
Test Case '-[KizbaTests.PasswordStoreScannerTests testValidateStoreRoot]' passed (0.005 seconds).
Test Suite 'PasswordStoreScannerTests' passed at 2026-05-24 08:25:45.895.
	 Executed 8 tests, with 0 failures (0 unexpected) in 0.107 (0.112) seconds
Test Suite 'ProcessShellRunnerInvocationTests' started at 2026-05-24 08:25:45.896.
Test Case '-[KizbaTests.ProcessShellRunnerInvocationTests testCancelPublishesInvocation]' started.
2026-05-24 08:25:45.984806+0200 Kizba[11882:1070619] [shell] shell cancelled: exe=/bin/sleep argc=1
Test Case '-[KizbaTests.ProcessShellRunnerInvocationTests testCancelPublishesInvocation]' passed (0.090 seconds).
Test Case '-[KizbaTests.ProcessShellRunnerInvocationTests testSuccessfulRunPublishesInvocation]' started.
2026-05-24 08:25:45.997884+0200 Kizba[11882:1071365] [shell] shell exit: exe=/bin/echo argc=1 status=0 stderrBytes=0 bytesIn=0
Test Case '-[KizbaTests.ProcessShellRunnerInvocationTests testSuccessfulRunPublishesInvocation]' passed (0.011 seconds).
Test Case '-[KizbaTests.ProcessShellRunnerInvocationTests testTimeoutPublishesInvocation]' started.
2026-05-24 08:25:46.101812+0200 Kizba[11882:1070617] [shell] shell timeout: exe=/bin/sleep argc=1
Test Case '-[KizbaTests.ProcessShellRunnerInvocationTests testTimeoutPublishesInvocation]' passed (0.104 seconds).
Test Suite 'ProcessShellRunnerInvocationTests' passed at 2026-05-24 08:25:46.104.
	 Executed 3 tests, with 0 failures (0 unexpected) in 0.206 (0.208) seconds
Test Suite 'ProcessShellRunnerStdinTests' started at 2026-05-24 08:25:46.104.
Test Case '-[KizbaTests.ProcessShellRunnerStdinTests testCancellationMidWrite]' started.
2026-05-24 08:25:46.310117+0200 Kizba[11882:1071950] [shell] shell cancelled: exe=/bin/sh argc=2
Test Case '-[KizbaTests.ProcessShellRunnerStdinTests testCancellationMidWrite]' passed (0.207 seconds).
Test Case '-[KizbaTests.ProcessShellRunnerStdinTests testCloseImmediatelyProducesEmptyEcho]' started.
2026-05-24 08:25:46.337584+0200 Kizba[11882:1071152] [shell] shell exit: exe=/bin/cat argc=0 status=0 stderrBytes=0 bytesIn=0
Test Case '-[KizbaTests.ProcessShellRunnerStdinTests testCloseImmediatelyProducesEmptyEcho]' passed (0.026 seconds).
Test Case '-[KizbaTests.ProcessShellRunnerStdinTests testInvocationRecordContainsByteCountButNotPayload]' started.
2026-05-24 08:25:46.350414+0200 Kizba[11882:1071152] [shell] shell exit: exe=/bin/cat argc=0 status=0 stderrBytes=0 bytesIn=21
Test Case '-[KizbaTests.ProcessShellRunnerStdinTests testInvocationRecordContainsByteCountButNotPayload]' passed (0.012 seconds).
Test Case '-[KizbaTests.ProcessShellRunnerStdinTests testLargeStdinViaCat_noDeadlock]' started.
2026-05-24 08:25:47.672649+0200 Kizba[11882:1070617] [shell] shell exit: exe=/bin/cat argc=0 status=0 stderrBytes=0 bytesIn=10485760
Test Case '-[KizbaTests.ProcessShellRunnerStdinTests testLargeStdinViaCat_noDeadlock]' passed (1.321 seconds).
Test Case '-[KizbaTests.ProcessShellRunnerStdinTests testRunFromDetachedTask]' started.
2026-05-24 08:25:47.695932+0200 Kizba[11882:1070614] [shell] shell exit: exe=/bin/cat argc=0 status=0 stderrBytes=0 bytesIn=14
Test Case '-[KizbaTests.ProcessShellRunnerStdinTests testRunFromDetachedTask]' passed (0.122 seconds).
Test Case '-[KizbaTests.ProcessShellRunnerStdinTests testStdinEchoViaCat]' started.
2026-05-24 08:25:47.822291+0200 Kizba[11882:1070619] [shell] shell exit: exe=/bin/cat argc=0 status=0 stderrBytes=0 bytesIn=12
Test Case '-[KizbaTests.ProcessShellRunnerStdinTests testStdinEchoViaCat]' passed (0.128 seconds).
Test Suite 'ProcessShellRunnerStdinTests' passed at 2026-05-24 08:25:47.925.
	 Executed 6 tests, with 0 failures (0 unexpected) in 1.817 (1.821) seconds
Test Suite 'ProcessShellRunnerTests' started at 2026-05-24 08:25:47.926.
Test Case '-[KizbaTests.ProcessShellRunnerTests testArgumentsAreForwardedAsDiscreteArgvEntries]' started.
2026-05-24 08:25:47.941429+0200 Kizba[11882:1070614] [shell] shell exit: exe=/bin/echo argc=2 status=0 stderrBytes=0 bytesIn=0
Test Case '-[KizbaTests.ProcessShellRunnerTests testArgumentsAreForwardedAsDiscreteArgvEntries]' passed (0.118 seconds).
Test Case '-[KizbaTests.ProcessShellRunnerTests testArgumentWithEmbeddedDoubleSpacesIsPreservedAsSingleArgv]' started.
2026-05-24 08:25:48.087541+0200 Kizba[11882:1070619] [shell] shell exit: exe=/bin/sh argc=4 status=0 stderrBytes=0 bytesIn=0
Test Case '-[KizbaTests.ProcessShellRunnerTests testArgumentWithEmbeddedDoubleSpacesIsPreservedAsSingleArgv]' passed (0.044 seconds).
Test Case '-[KizbaTests.ProcessShellRunnerTests testCancellationPropagates]' started.
2026-05-24 08:25:48.191973+0200 Kizba[11882:1071152] [shell] shell cancelled: exe=/bin/sleep argc=1
Test Case '-[KizbaTests.ProcessShellRunnerTests testCancellationPropagates]' passed (0.105 seconds).
Test Case '-[KizbaTests.ProcessShellRunnerTests testEchoSuccess]' started.
2026-05-24 08:25:48.216685+0200 Kizba[11882:1070619] [shell] shell exit: exe=/bin/echo argc=1 status=0 stderrBytes=0 bytesIn=0
Test Case '-[KizbaTests.ProcessShellRunnerTests testEchoSuccess]' passed (0.125 seconds).
Test Case '-[KizbaTests.ProcessShellRunnerTests testEmptyEnvironmentIsNotInheritedFromParent]' started.
2026-05-24 08:25:48.350739+0200 Kizba[11882:1070617] [shell] shell exit: exe=/bin/sh argc=2 status=0 stderrBytes=0 bytesIn=0
Test Case '-[KizbaTests.ProcessShellRunnerTests testEmptyEnvironmentIsNotInheritedFromParent]' passed (0.032 seconds).
Test Case '-[KizbaTests.ProcessShellRunnerTests testEnvironmentVariablesAreForwardedToChild]' started.
2026-05-24 08:25:48.373595+0200 Kizba[11882:1070617] [shell] shell exit: exe=/bin/sh argc=2 status=0 stderrBytes=0 bytesIn=0
Test Case '-[KizbaTests.ProcessShellRunnerTests testEnvironmentVariablesAreForwardedToChild]' passed (0.022 seconds).
Test Case '-[KizbaTests.ProcessShellRunnerTests testLargeStdoutDrain]' started.
2026-05-24 08:25:48.411363+0200 Kizba[11882:1070614] [shell] shell exit: exe=/bin/sh argc=2 status=0 stderrBytes=0 bytesIn=0
Test Case '-[KizbaTests.ProcessShellRunnerTests testLargeStdoutDrain]' passed (0.037 seconds).
Test Case '-[KizbaTests.ProcessShellRunnerTests testNonZeroExit]' started.
2026-05-24 08:25:48.433158+0200 Kizba[11882:1070617] [shell] shell exit: exe=/usr/bin/false argc=0 status=1 stderrBytes=0 bytesIn=0
Test Case '-[KizbaTests.ProcessShellRunnerTests testNonZeroExit]' passed (0.022 seconds).
Test Case '-[KizbaTests.ProcessShellRunnerTests testRelativeExecutableNotResolvedViaPATH]' started.
2026-05-24 08:25:48.437985+0200 Kizba[11882:1070614] [shell] process spawn failed for /kizba-not-a-real-binary-3DD33849-BB70-4695-A5E5-BAB40F2AD438: Error Domain=NSCocoaErrorDomain Code=4 "The file “kizba-not-a-real-binary-3DD33849-BB70-4695-A5E5-BAB40F2AD438” doesn’t exist." UserInfo={NSFilePath=/kizba-not-a-real-binary-3DD33849-BB70-4695-A5E5-BAB40F2AD438}
Test Case '-[KizbaTests.ProcessShellRunnerTests testRelativeExecutableNotResolvedViaPATH]' passed (0.004 seconds).
Test Case '-[KizbaTests.ProcessShellRunnerTests testSpawnFailureForMissingExecutable]' started.
2026-05-24 08:25:48.439964+0200 Kizba[11882:1070614] [shell] process spawn failed for /nonexistent/kizba-definitely-not-here-99A31ECC-9495-423C-8301-9DD1EDD5FF96: Error Domain=NSCocoaErrorDomain Code=4 "The file “kizba-definitely-not-here-99A31ECC-9495-423C-8301-9DD1EDD5FF96” doesn’t exist." UserInfo={NSFilePath=/nonexistent/kizba-definitely-not-here-99A31ECC-9495-423C-8301-9DD1EDD5FF96}
Test Case '-[KizbaTests.ProcessShellRunnerTests testSpawnFailureForMissingExecutable]' passed (0.002 seconds).
Test Case '-[KizbaTests.ProcessShellRunnerTests testTimeoutTerminatesProcess]' started.
2026-05-24 08:25:48.644077+0200 Kizba[11882:1071950] [shell] shell timeout: exe=/bin/sleep argc=1
Test Case '-[KizbaTests.ProcessShellRunnerTests testTimeoutTerminatesProcess]' passed (0.205 seconds).
Test Suite 'ProcessShellRunnerTests' passed at 2026-05-24 08:25:48.646.
	 Executed 11 tests, with 0 failures (0 unexpected) in 0.715 (0.720) seconds
Test Suite 'QRCodeImageTests' started at 2026-05-24 08:25:48.647.
Test Case '-[KizbaTests.QRCodeImageTests testGenerate_emptyPayload_stillReturnsImage]' started.
Test Case '-[KizbaTests.QRCodeImageTests testGenerate_emptyPayload_stillReturnsImage]' passed (0.197 seconds).
Test Case '-[KizbaTests.QRCodeImageTests testGenerate_typicalOTPAuthURI_returnsImage]' started.
Test Case '-[KizbaTests.QRCodeImageTests testGenerate_typicalOTPAuthURI_returnsImage]' passed (0.015 seconds).
Test Suite 'QRCodeImageTests' passed at 2026-05-24 08:25:48.861.
	 Executed 2 tests, with 0 failures (0 unexpected) in 0.212 (0.214) seconds
Test Suite 'RecentsModelTests' started at 2026-05-24 08:25:48.861.
Test Case '-[KizbaTests.RecentsModelTests testCappedListReflectsSetMaxCount]' started.
Test Case '-[KizbaTests.RecentsModelTests testCappedListReflectsSetMaxCount]' passed (0.045 seconds).
Test Case '-[KizbaTests.RecentsModelTests testLoad_filtersOutInvalidPaths]' started.
Test Case '-[KizbaTests.RecentsModelTests testLoad_filtersOutInvalidPaths]' passed (0.104 seconds).
Test Case '-[KizbaTests.RecentsModelTests testLoad_observesChanges]' started.
Test Case '-[KizbaTests.RecentsModelTests testLoad_observesChanges]' passed (0.036 seconds).
Test Case '-[KizbaTests.RecentsModelTests testLoad_populatesRecents]' started.
Test Case '-[KizbaTests.RecentsModelTests testLoad_populatesRecents]' passed (0.002 seconds).
Test Case '-[KizbaTests.RecentsModelTests testLoad_returnsAllPathsWhenAllValid]' started.
Test Case '-[KizbaTests.RecentsModelTests testLoad_returnsAllPathsWhenAllValid]' passed (0.002 seconds).
Test Case '-[KizbaTests.RecentsModelTests testLoad_returnsEmptyWhenNothingValid]' started.
Test Case '-[KizbaTests.RecentsModelTests testLoad_returnsEmptyWhenNothingValid]' passed (0.003 seconds).
Test Case '-[KizbaTests.RecentsModelTests testLoad_withoutValidator_passesPathsThrough]' started.
Test Case '-[KizbaTests.RecentsModelTests testLoad_withoutValidator_passesPathsThrough]' passed (0.003 seconds).
Test Case '-[KizbaTests.RecentsModelTests testStop_cancelsObservation]' started.
Test Case '-[KizbaTests.RecentsModelTests testStop_cancelsObservation]' passed (0.079 seconds).
Test Suite 'RecentsModelTests' passed at 2026-05-24 08:25:49.141.
	 Executed 8 tests, with 0 failures (0 unexpected) in 0.275 (0.280) seconds
Test Suite 'RegenerateInPlaceModelTests' started at 2026-05-24 08:25:49.142.
Test Case '-[KizbaTests.RegenerateInPlaceModelTests testInitialState_isIdle_withDefaultLengthAndSymbols]' started.
Test Case '-[KizbaTests.RegenerateInPlaceModelTests testInitialState_isIdle_withDefaultLengthAndSymbols]' passed (0.002 seconds).
Test Case '-[KizbaTests.RegenerateInPlaceModelTests testLengthBounds_pinnedAt8To128]' started.
Test Case '-[KizbaTests.RegenerateInPlaceModelTests testLengthBounds_pinnedAt8To128]' passed (0.001 seconds).
Test Case '-[KizbaTests.RegenerateInPlaceModelTests testRegenerate_afterCall_isNotInRunning_orIdle]' started.
Test Case '-[KizbaTests.RegenerateInPlaceModelTests testRegenerate_afterCall_isNotInRunning_orIdle]' passed (0.003 seconds).
Test Case '-[KizbaTests.RegenerateInPlaceModelTests testRegenerate_generateFailureAfterSuccessfulShow_landsInFailed_andDoesNotRecordAction_andPostsDangerToast]' started.
Test Case '-[KizbaTests.RegenerateInPlaceModelTests testRegenerate_generateFailureAfterSuccessfulShow_landsInFailed_andDoesNotRecordAction_andPostsDangerToast]' passed (0.104 seconds).
Test Case '-[KizbaTests.RegenerateInPlaceModelTests testRegenerate_happyPath_landsInSucceeded_andRecordsAction_andPostsToast]' started.
Test Case '-[KizbaTests.RegenerateInPlaceModelTests testRegenerate_happyPath_landsInSucceeded_andRecordsAction_andPostsToast]' passed (0.105 seconds).
Test Case '-[KizbaTests.RegenerateInPlaceModelTests testRegenerate_lengthAndSymbols_passedThroughToManager]' started.
Test Case '-[KizbaTests.RegenerateInPlaceModelTests testRegenerate_lengthAndSymbols_passedThroughToManager]' passed (0.002 seconds).
Test Case '-[KizbaTests.RegenerateInPlaceModelTests testRegenerate_preShowFailure_landsInFailed_andDoesNotRecordAction_andPostsDangerToast]' started.
Test Case '-[KizbaTests.RegenerateInPlaceModelTests testRegenerate_preShowFailure_landsInFailed_andDoesNotRecordAction_andPostsDangerToast]' passed (0.004 seconds).
Test Case '-[KizbaTests.RegenerateInPlaceModelTests testToast_message_neverContainsTheNewPassword]' started.
Test Case '-[KizbaTests.RegenerateInPlaceModelTests testToast_message_neverContainsTheNewPassword]' passed (0.002 seconds).
Test Case '-[KizbaTests.RegenerateInPlaceModelTests testUndo_fromPendingAction_restoresPriorSecret]' started.
Test Case '-[KizbaTests.RegenerateInPlaceModelTests testUndo_fromPendingAction_restoresPriorSecret]' passed (0.005 seconds).
Test Suite 'RegenerateInPlaceModelTests' passed at 2026-05-24 08:25:49.376.
	 Executed 9 tests, with 0 failures (0 unexpected) in 0.228 (0.234) seconds
Test Suite 'ReleaseBinaryTests' started at 2026-05-24 08:25:49.376.
Test Case '-[KizbaTests.ReleaseBinaryTests testDebugFixturesAbsentFromReleaseDescription]' started.
Test Case '-[KizbaTests.ReleaseBinaryTests testDebugFixturesAbsentFromReleaseDescription]' passed (0.028 seconds).
Test Suite 'ReleaseBinaryTests' passed at 2026-05-24 08:25:49.405.
	 Executed 1 test, with 0 failures (0 unexpected) in 0.028 (0.029) seconds
Test Suite 'RoundTripTests' started at 2026-05-24 08:25:49.405.
Test Case '-[KizbaTests.RoundTripTests testBitwardenJSON_roundTrip_preservesAllRecords]' started.
Test Case '-[KizbaTests.RoundTripTests testBitwardenJSON_roundTrip_preservesAllRecords]' passed (0.003 seconds).
Test Case '-[KizbaTests.RoundTripTests testGenericCSV_roundTrip_preservesAllRecords]' started.
Test Case '-[KizbaTests.RoundTripTests testGenericCSV_roundTrip_preservesAllRecords]' passed (0.002 seconds).
Test Case '-[KizbaTests.RoundTripTests testPassSecretExporter_caseInsensitiveAliasResolution]' started.
Test Case '-[KizbaTests.RoundTripTests testPassSecretExporter_caseInsensitiveAliasResolution]' passed (0.001 seconds).
Test Case '-[KizbaTests.RoundTripTests testPassSecretExporter_mapsStandardMetadata]' started.
Test Case '-[KizbaTests.RoundTripTests testPassSecretExporter_mapsStandardMetadata]' passed (0.001 seconds).
Test Case '-[KizbaTests.RoundTripTests testPassSecretExporter_username_aliasFallback]' started.
Test Case '-[KizbaTests.RoundTripTests testPassSecretExporter_username_aliasFallback]' passed (0.001 seconds).
Test Suite 'RoundTripTests' passed at 2026-05-24 08:25:49.417.
	 Executed 5 tests, with 0 failures (0 unexpected) in 0.007 (0.012) seconds
Test Suite 'SearchModelSelectionTests' started at 2026-05-24 08:25:49.417.
Test Case '-[KizbaTests.SearchModelSelectionTests testMoveSelection_downAndUp_clampsCorrectly]' started.
Test Case '-[KizbaTests.SearchModelSelectionTests testMoveSelection_downAndUp_clampsCorrectly]' passed (0.001 seconds).
Test Case '-[KizbaTests.SearchModelSelectionTests testSelection_defaultsToFirstResult_afterSearch]' started.
Test Case '-[KizbaTests.SearchModelSelectionTests testSelection_defaultsToFirstResult_afterSearch]' passed (0.369 seconds).
Test Case '-[KizbaTests.SearchModelSelectionTests testSelection_resetsOnEmptyQuery]' started.
Test Case '-[KizbaTests.SearchModelSelectionTests testSelection_resetsOnEmptyQuery]' passed (0.672 seconds).
Test Suite 'SearchModelSelectionTests' passed at 2026-05-24 08:25:50.461.
	 Executed 3 tests, with 0 failures (0 unexpected) in 1.042 (1.044) seconds
Test Suite 'SearchModelTests' started at 2026-05-24 08:25:50.462.
Test Case '-[KizbaTests.SearchModelTests testSearchModel_updatesResultsOnQuery]' started.
Test Case '-[KizbaTests.SearchModelTests testSearchModel_updatesResultsOnQuery]' passed (0.609 seconds).
Test Suite 'SearchModelTests' passed at 2026-05-24 08:25:51.072.
	 Executed 1 test, with 0 failures (0 unexpected) in 0.609 (0.610) seconds
Test Suite 'SearchModelUITests' started at 2026-05-24 08:25:51.072.
Test Case '-[KizbaTests.SearchModelUITests testSearchView_selectCallsOnSelect]' started.
Test Case '-[KizbaTests.SearchModelUITests testSearchView_selectCallsOnSelect]' passed (0.002 seconds).
Test Suite 'SearchModelUITests' passed at 2026-05-24 08:25:51.075.
	 Executed 1 test, with 0 failures (0 unexpected) in 0.002 (0.003) seconds
Test Suite 'SearchTests' started at 2026-05-24 08:25:51.076.
Test Case '-[KizbaTests.SearchTests testSearch_cancellation]' started.
Test Case '-[KizbaTests.SearchTests testSearch_cancellation]' passed (0.103 seconds).
Test Case '-[KizbaTests.SearchTests testSearch_caseInsensitive]' started.
Test Case '-[KizbaTests.SearchTests testSearch_caseInsensitive]' passed (0.003 seconds).
Test Case '-[KizbaTests.SearchTests testSearch_emptyQuery_returnsEmpty]' started.
Test Case '-[KizbaTests.SearchTests testSearch_emptyQuery_returnsEmpty]' passed (0.002 seconds).
Test Case '-[KizbaTests.SearchTests testSearch_returnsResults_forSimpleQuery]' started.
Test Case '-[KizbaTests.SearchTests testSearch_returnsResults_forSimpleQuery]' passed (0.002 seconds).
Test Suite 'SearchTests' passed at 2026-05-24 08:25:51.188.
	 Executed 4 tests, with 0 failures (0 unexpected) in 0.110 (0.113) seconds
Test Suite 'SecretDraftTests' started at 2026-05-24 08:25:51.188.
Test Case '-[KizbaTests.SecretDraftTests test_secretDraft_mutationOfMetadata_triggersObservation]' started.
Test Case '-[KizbaTests.SecretDraftTests test_secretDraft_mutationOfMetadata_triggersObservation]' passed (0.001 seconds).
Test Case '-[KizbaTests.SecretDraftTests test_secretDraft_mutationOfNotes_triggersObservation]' started.
Test Case '-[KizbaTests.SecretDraftTests test_secretDraft_mutationOfNotes_triggersObservation]' passed (0.001 seconds).
Test Case '-[KizbaTests.SecretDraftTests test_secretDraft_mutationOfPassword_triggersObservation]' started.
Test Case '-[KizbaTests.SecretDraftTests test_secretDraft_mutationOfPassword_triggersObservation]' passed (0.001 seconds).
Test Case '-[KizbaTests.SecretDraftTests testDefaultStringDescriptionDoesNotLeakPassword]' started.
Test Case '-[KizbaTests.SecretDraftTests testDefaultStringDescriptionDoesNotLeakPassword]' passed (0.001 seconds).
Test Case '-[KizbaTests.SecretDraftTests testEmptyInitDefaults]' started.
Test Case '-[KizbaTests.SecretDraftTests testEmptyInitDefaults]' passed (0.001 seconds).
Test Case '-[KizbaTests.SecretDraftTests testInitFromSecretCopiesAllFields]' started.
Test Case '-[KizbaTests.SecretDraftTests testInitFromSecretCopiesAllFields]' passed (0.001 seconds).
Test Case '-[KizbaTests.SecretDraftTests testInitFromSecretMapsNilNotesToEmptyString]' started.
Test Case '-[KizbaTests.SecretDraftTests testInitFromSecretMapsNilNotesToEmptyString]' passed (0.024 seconds).
Test Case '-[KizbaTests.SecretDraftTests testIsNotCodable]' started.
Test Case '-[KizbaTests.SecretDraftTests testIsNotCodable]' passed (0.002 seconds).
Test Case '-[KizbaTests.SecretDraftTests testIsNotCustomStringConvertible]' started.
Test Case '-[KizbaTests.SecretDraftTests testIsNotCustomStringConvertible]' passed (0.002 seconds).
Test Case '-[KizbaTests.SecretDraftTests testMutatingMetadataAfterSnapshotDoesNotAffectSnapshot]' started.
Test Case '-[KizbaTests.SecretDraftTests testMutatingMetadataAfterSnapshotDoesNotAffectSnapshot]' passed (0.002 seconds).
Test Case '-[KizbaTests.SecretDraftTests testMutatingNotesAfterSnapshotDoesNotAffectSnapshot]' started.
Test Case '-[KizbaTests.SecretDraftTests testMutatingNotesAfterSnapshotDoesNotAffectSnapshot]' passed (0.002 seconds).
Test Case '-[KizbaTests.SecretDraftTests testMutatingPasswordAfterSnapshotDoesNotAffectSnapshot]' started.
Test Case '-[KizbaTests.SecretDraftTests testMutatingPasswordAfterSnapshotDoesNotAffectSnapshot]' passed (0.002 seconds).
Test Case '-[KizbaTests.SecretDraftTests testReferenceSemanticsMutationsAreShared]' started.
Test Case '-[KizbaTests.SecretDraftTests testReferenceSemanticsMutationsAreShared]' passed (0.002 seconds).
Test Case '-[KizbaTests.SecretDraftTests testSnapshotEmptyNotesBecomesNil]' started.
Test Case '-[KizbaTests.SecretDraftTests testSnapshotEmptyNotesBecomesNil]' passed (0.001 seconds).
Test Case '-[KizbaTests.SecretDraftTests testSnapshotNonEmptyNotesPreserved]' started.
Test Case '-[KizbaTests.SecretDraftTests testSnapshotNonEmptyNotesPreserved]' passed (0.002 seconds).
Test Case '-[KizbaTests.SecretDraftTests testSnapshotPreservesMetadataOrder]' started.
Test Case '-[KizbaTests.SecretDraftTests testSnapshotPreservesMetadataOrder]' passed (0.002 seconds).
Test Case '-[KizbaTests.SecretDraftTests testSnapshotRoundTripPreservesFields]' started.
Test Case '-[KizbaTests.SecretDraftTests testSnapshotRoundTripPreservesFields]' passed (0.001 seconds).
Test Suite 'SecretDraftTests' passed at 2026-05-24 08:25:51.288.
	 Executed 17 tests, with 0 failures (0 unexpected) in 0.048 (0.099) seconds
Test Suite 'SecretRevealFieldAccessibilityTests' started at 2026-05-24 08:25:51.288.
Test Case '-[KizbaTests.SecretRevealFieldAccessibilityTests testSecretRevealField_accessibilityValue_reflectsRevealState]' started.
Test Case '-[KizbaTests.SecretRevealFieldAccessibilityTests testSecretRevealField_accessibilityValue_reflectsRevealState]' passed (0.002 seconds).
Test Suite 'SecretRevealFieldAccessibilityTests' passed at 2026-05-24 08:25:51.291.
	 Executed 1 test, with 0 failures (0 unexpected) in 0.002 (0.003) seconds
Test Suite 'SecretRevealFieldTests' started at 2026-05-24 08:25:51.291.
Test Case '-[KizbaTests.SecretRevealFieldTests testSecretRevealField_displayText_doesNotContainValueWhenHidden]' started.
Test Case '-[KizbaTests.SecretRevealFieldTests testSecretRevealField_displayText_doesNotContainValueWhenHidden]' passed (0.002 seconds).
Test Case '-[KizbaTests.SecretRevealFieldTests testSecretRevealField_displayText_maskedAndRevealedDifferForNonEmptyValue]' started.
Test Case '-[KizbaTests.SecretRevealFieldTests testSecretRevealField_displayText_maskedAndRevealedDifferForNonEmptyValue]' passed (0.001 seconds).
Test Case '-[KizbaTests.SecretRevealFieldTests testSecretRevealField_displayText_whenHiddenForEmptyValueIs8Bullets]' started.
Test Case '-[KizbaTests.SecretRevealFieldTests testSecretRevealField_displayText_whenHiddenForEmptyValueIs8Bullets]' passed (0.018 seconds).
Test Case '-[KizbaTests.SecretRevealFieldTests testSecretRevealField_displayText_whenHiddenForLongValueIs32Bullets]' started.
Test Case '-[KizbaTests.SecretRevealFieldTests testSecretRevealField_displayText_whenHiddenForLongValueIs32Bullets]' passed (0.002 seconds).
Test Case '-[KizbaTests.SecretRevealFieldTests testSecretRevealField_displayText_whenHiddenForShortValueIs8Bullets]' started.
Test Case '-[KizbaTests.SecretRevealFieldTests testSecretRevealField_displayText_whenHiddenForShortValueIs8Bullets]' passed (0.002 seconds).
Test Case '-[KizbaTests.SecretRevealFieldTests testSecretRevealField_displayText_whenHiddenIsBulletOfMaskedLength]' started.
Test Case '-[KizbaTests.SecretRevealFieldTests testSecretRevealField_displayText_whenHiddenIsBulletOfMaskedLength]' passed (0.001 seconds).
Test Case '-[KizbaTests.SecretRevealFieldTests testSecretRevealField_displayText_whenRevealedReturnsValueExactly]' started.
Test Case '-[KizbaTests.SecretRevealFieldTests testSecretRevealField_displayText_whenRevealedReturnsValueExactly]' passed (0.008 seconds).
Test Case '-[KizbaTests.SecretRevealFieldTests testSecretRevealField_maskedLength_atCeilingBoundaryIsExactly32]' started.
Test Case '-[KizbaTests.SecretRevealFieldTests testSecretRevealField_maskedLength_atCeilingBoundaryIsExactly32]' passed (0.001 seconds).
Test Case '-[KizbaTests.SecretRevealFieldTests testSecretRevealField_maskedLength_atFloorBoundaryIsExactly8]' started.
Test Case '-[KizbaTests.SecretRevealFieldTests testSecretRevealField_maskedLength_atFloorBoundaryIsExactly8]' passed (0.001 seconds).
Test Case '-[KizbaTests.SecretRevealFieldTests testSecretRevealField_maskedLength_emptyValueIsClampedToFloorOf8]' started.
Test Case '-[KizbaTests.SecretRevealFieldTests testSecretRevealField_maskedLength_emptyValueIsClampedToFloorOf8]' passed (0.001 seconds).
Test Case '-[KizbaTests.SecretRevealFieldTests testSecretRevealField_maskedLength_inRangePassesThrough]' started.
Test Case '-[KizbaTests.SecretRevealFieldTests testSecretRevealField_maskedLength_inRangePassesThrough]' passed (0.001 seconds).
Test Case '-[KizbaTests.SecretRevealFieldTests testSecretRevealField_maskedLength_longValueIsClampedToCeilingOf32]' started.
Test Case '-[KizbaTests.SecretRevealFieldTests testSecretRevealField_maskedLength_longValueIsClampedToCeilingOf32]' passed (0.001 seconds).
Test Case '-[KizbaTests.SecretRevealFieldTests testSecretRevealField_maskedLength_shortValueIsClampedToFloorOf8]' started.
Test Case '-[KizbaTests.SecretRevealFieldTests testSecretRevealField_maskedLength_shortValueIsClampedToFloorOf8]' passed (0.001 seconds).
Test Suite 'SecretRevealFieldTests' passed at 2026-05-24 08:25:51.350.
	 Executed 13 tests, with 0 failures (0 unexpected) in 0.038 (0.059) seconds
Test Suite 'SecretRevealFieldTouchIDTests' started at 2026-05-24 08:25:51.351.
Test Case '-[KizbaTests.SecretRevealFieldTouchIDTests testAttemptReveal_gateDisabled_revealsImmediately]' started.
Test Case '-[KizbaTests.SecretRevealFieldTouchIDTests testAttemptReveal_gateDisabled_revealsImmediately]' passed (0.001 seconds).
Test Case '-[KizbaTests.SecretRevealFieldTouchIDTests testAttemptReveal_gateEnabled_authCancelled_noReveal]' started.
Test Case '-[KizbaTests.SecretRevealFieldTouchIDTests testAttemptReveal_gateEnabled_authCancelled_noReveal]' passed (0.010 seconds).
Test Case '-[KizbaTests.SecretRevealFieldTouchIDTests testAttemptReveal_gateEnabled_authFailed_noReveal]' started.
Test Case '-[KizbaTests.SecretRevealFieldTouchIDTests testAttemptReveal_gateEnabled_authFailed_noReveal]' passed (0.004 seconds).
Test Case '-[KizbaTests.SecretRevealFieldTouchIDTests testAttemptReveal_gateEnabled_authSuccess_reveals]' started.
Test Case '-[KizbaTests.SecretRevealFieldTouchIDTests testAttemptReveal_gateEnabled_authSuccess_reveals]' passed (0.002 seconds).
Test Case '-[KizbaTests.SecretRevealFieldTouchIDTests testRemask_alwaysImmediate]' started.
Test Case '-[KizbaTests.SecretRevealFieldTouchIDTests testRemask_alwaysImmediate]' passed (0.001 seconds).
Test Suite 'SecretRevealFieldTouchIDTests' passed at 2026-05-24 08:25:51.371.
	 Executed 5 tests, with 0 failures (0 unexpected) in 0.018 (0.020) seconds
Test Suite 'SemanticIconographyTests' started at 2026-05-24 08:25:51.371.
Test Case '-[KizbaTests.SemanticIconographyTests testSemanticIconography_bannerIconName_isDistinctAcrossSeverities]' started.
Test Case '-[KizbaTests.SemanticIconographyTests testSemanticIconography_bannerIconName_isDistinctAcrossSeverities]' passed (0.001 seconds).
Test Case '-[KizbaTests.SemanticIconographyTests testSemanticIconography_bannerIconName_isNonEmptyForEverySeverity]' started.
Test Case '-[KizbaTests.SemanticIconographyTests testSemanticIconography_bannerIconName_isNonEmptyForEverySeverity]' passed (0.001 seconds).
Test Case '-[KizbaTests.SemanticIconographyTests testSemanticIconography_bannerIconName_matchesExpectedConstants]' started.
Test Case '-[KizbaTests.SemanticIconographyTests testSemanticIconography_bannerIconName_matchesExpectedConstants]' passed (0.001 seconds).
Test Case '-[KizbaTests.SemanticIconographyTests testSemanticIconography_iconColor_differsFromBackground_inAllThemes]' started.
Test Case '-[KizbaTests.SemanticIconographyTests testSemanticIconography_iconColor_differsFromBackground_inAllThemes]' passed (0.001 seconds).
Test Case '-[KizbaTests.SemanticIconographyTests testSemanticIconography_toastView_reusesBannerIconSourceOfTruth]' started.
Test Case '-[KizbaTests.SemanticIconographyTests testSemanticIconography_toastView_reusesBannerIconSourceOfTruth]' passed (0.002 seconds).
Test Suite 'SemanticIconographyTests' passed at 2026-05-24 08:25:51.396.
	 Executed 5 tests, with 0 failures (0 unexpected) in 0.005 (0.025) seconds
Test Suite 'SettingsKeyMigrationTests' started at 2026-05-24 08:25:51.397.
Test Case '-[KizbaTests.SettingsKeyMigrationTests testExistingNewKeyIsNotOverwrittenByLegacyValue]' started.
Test Case '-[KizbaTests.SettingsKeyMigrationTests testExistingNewKeyIsNotOverwrittenByLegacyValue]' passed (0.017 seconds).
Test Case '-[KizbaTests.SettingsKeyMigrationTests testLegacyFalseMigratesToNewKeyAndRemovesLegacy]' started.
Test Case '-[KizbaTests.SettingsKeyMigrationTests testLegacyFalseMigratesToNewKeyAndRemovesLegacy]' passed (0.013 seconds).
Test Case '-[KizbaTests.SettingsKeyMigrationTests testLegacyTrueMigratesToNewKeyAndRemovesLegacy]' started.
Test Case '-[KizbaTests.SettingsKeyMigrationTests testLegacyTrueMigratesToNewKeyAndRemovesLegacy]' passed (0.005 seconds).
Test Case '-[KizbaTests.SettingsKeyMigrationTests testMissingLegacyRegistersNewKeyDefaultFalse]' started.
Test Case '-[KizbaTests.SettingsKeyMigrationTests testMissingLegacyRegistersNewKeyDefaultFalse]' passed (0.002 seconds).
Test Suite 'SettingsKeyMigrationTests' passed at 2026-05-24 08:25:51.435.
	 Executed 4 tests, with 0 failures (0 unexpected) in 0.036 (0.038) seconds
Test Suite 'SettingsModelTests' started at 2026-05-24 08:25:51.435.
Test Case '-[KizbaTests.SettingsModelTests testBiometricAvailability_propagatesFromAuth]' started.
Test Case '-[KizbaTests.SettingsModelTests testBiometricAvailability_propagatesFromAuth]' passed (0.001 seconds).
Test Case '-[KizbaTests.SettingsModelTests testDefaultsClipboardDelay]' started.
Test Case '-[KizbaTests.SettingsModelTests testDefaultsClipboardDelay]' passed (0.001 seconds).
Test Case '-[KizbaTests.SettingsModelTests testDefaultsGitOperationTimeout]' started.
Test Case '-[KizbaTests.SettingsModelTests testDefaultsGitOperationTimeout]' passed (0.001 seconds).
Test Case '-[KizbaTests.SettingsModelTests testGitOperationTimeoutBoundsAreSane]' started.
Test Case '-[KizbaTests.SettingsModelTests testGitOperationTimeoutBoundsAreSane]' passed (0.001 seconds).
Test Case '-[KizbaTests.SettingsModelTests testGitOperationTimeoutPersistsOnSave]' started.
Test Case '-[KizbaTests.SettingsModelTests testGitOperationTimeoutPersistsOnSave]' passed (0.014 seconds).
Test Case '-[KizbaTests.SettingsModelTests testGitOperationTimeoutResetsToDefault]' started.
Test Case '-[KizbaTests.SettingsModelTests testGitOperationTimeoutResetsToDefault]' passed (0.013 seconds).
Test Case '-[KizbaTests.SettingsModelTests testGitTimeout_accessibilityValue_likeString]' started.
Test Case '-[KizbaTests.SettingsModelTests testGitTimeout_accessibilityValue_likeString]' passed (0.002 seconds).
Test Case '-[KizbaTests.SettingsModelTests testHasChanges_becomesTrueAfterMutation]' started.
Test Case '-[KizbaTests.SettingsModelTests testHasChanges_becomesTrueAfterMutation]' passed (0.002 seconds).
Test Case '-[KizbaTests.SettingsModelTests testHasChanges_falseAfterSave]' started.
Test Case '-[KizbaTests.SettingsModelTests testHasChanges_falseAfterSave]' passed (0.015 seconds).
Test Case '-[KizbaTests.SettingsModelTests testHasChanges_flipsWhenShowFavoritesMutated]' started.
Test Case '-[KizbaTests.SettingsModelTests testHasChanges_flipsWhenShowFavoritesMutated]' passed (0.001 seconds).
Test Case '-[KizbaTests.SettingsModelTests testHasChanges_flipsWhenShowOTPMutated]' started.
Test Case '-[KizbaTests.SettingsModelTests testHasChanges_flipsWhenShowOTPMutated]' passed (0.003 seconds).
Test Case '-[KizbaTests.SettingsModelTests testHasChanges_isFalseAfterLoad]' started.
Test Case '-[KizbaTests.SettingsModelTests testHasChanges_isFalseAfterLoad]' passed (0.001 seconds).
Test Case '-[KizbaTests.SettingsModelTests testRecentsLimit_defaultIsSeven]' started.
Test Case '-[KizbaTests.SettingsModelTests testRecentsLimit_defaultIsSeven]' passed (0.001 seconds).
Test Case '-[KizbaTests.SettingsModelTests testRecentsLimit_persistsAndClampsHigh]' started.
Test Case '-[KizbaTests.SettingsModelTests testRecentsLimit_persistsAndClampsHigh]' passed (0.014 seconds).
Test Case '-[KizbaTests.SettingsModelTests testRecentsLimit_persistsAndClampsLow]' started.
Test Case '-[KizbaTests.SettingsModelTests testRecentsLimit_persistsAndClampsLow]' passed (0.013 seconds).
Test Case '-[KizbaTests.SettingsModelTests testReDetectTriggersDiscovery]' started.
Test Case '-[KizbaTests.SettingsModelTests testReDetectTriggersDiscovery]' passed (0.002 seconds).
Test Case '-[KizbaTests.SettingsModelTests testReset_clearsHasChanges]' started.
Test Case '-[KizbaTests.SettingsModelTests testReset_clearsHasChanges]' passed (0.001 seconds).
Test Case '-[KizbaTests.SettingsModelTests testReset_restoresShowInMenuBarDefault]' started.
Test Case '-[KizbaTests.SettingsModelTests testReset_restoresShowInMenuBarDefault]' passed (0.014 seconds).
Test Case '-[KizbaTests.SettingsModelTests testReset_restoresShowOTPDefault]' started.
Test Case '-[KizbaTests.SettingsModelTests testReset_restoresShowOTPDefault]' passed (0.014 seconds).
Test Case '-[KizbaTests.SettingsModelTests testResetToDefaults]' started.
Test Case '-[KizbaTests.SettingsModelTests testResetToDefaults]' passed (0.014 seconds).
Test Case '-[KizbaTests.SettingsModelTests testSave_callsSetMaxCountOnRecentStore]' started.
Test Case '-[KizbaTests.SettingsModelTests testSave_callsSetMaxCountOnRecentStore]' passed (0.115 seconds).
Test Case '-[KizbaTests.SettingsModelTests testSave_isNoopWhenNoChanges]' started.
Test Case '-[KizbaTests.SettingsModelTests testSave_isNoopWhenNoChanges]' passed (0.003 seconds).
Test Case '-[KizbaTests.SettingsModelTests testSave_propagatesClampedValueToRecentStore]' started.
Test Case '-[KizbaTests.SettingsModelTests testSave_propagatesClampedValueToRecentStore]' passed (0.115 seconds).
Test Case '-[KizbaTests.SettingsModelTests testSaveState_transitions_idle_saving_saved_idle]' started.
Test Case '-[KizbaTests.SettingsModelTests testSaveState_transitions_idle_saving_saved_idle]' passed (0.014 seconds).
Test Case '-[KizbaTests.SettingsModelTests testSetAndGetOverrides]' started.
Test Case '-[KizbaTests.SettingsModelTests testSetAndGetOverrides]' passed (0.014 seconds).
Test Case '-[KizbaTests.SettingsModelTests testShowFavorites_defaultIsTrue]' started.
Test Case '-[KizbaTests.SettingsModelTests testShowFavorites_defaultIsTrue]' passed (0.002 seconds).
Test Case '-[KizbaTests.SettingsModelTests testShowFavorites_persists]' started.
Test Case '-[KizbaTests.SettingsModelTests testShowFavorites_persists]' passed (0.014 seconds).
Test Case '-[KizbaTests.SettingsModelTests testShowInMenuBar_defaultsToTrue]' started.
Test Case '-[KizbaTests.SettingsModelTests testShowInMenuBar_defaultsToTrue]' passed (0.002 seconds).
Test Case '-[KizbaTests.SettingsModelTests testShowInMenuBar_persistsChange]' started.
Test Case '-[KizbaTests.SettingsModelTests testShowInMenuBar_persistsChange]' passed (0.014 seconds).
Test Case '-[KizbaTests.SettingsModelTests testShowOTP_defaultIsTrue]' started.
Test Case '-[KizbaTests.SettingsModelTests testShowOTP_defaultIsTrue]' passed (0.002 seconds).
Test Case '-[KizbaTests.SettingsModelTests testShowOTP_persists]' started.
Test Case '-[KizbaTests.SettingsModelTests testShowOTP_persists]' passed (0.013 seconds).
Test Case '-[KizbaTests.SettingsModelTests testShowRecents_defaultIsTrue]' started.
Test Case '-[KizbaTests.SettingsModelTests testShowRecents_defaultIsTrue]' passed (0.002 seconds).
Test Case '-[KizbaTests.SettingsModelTests testShowRecents_persists]' started.
Test Case '-[KizbaTests.SettingsModelTests testShowRecents_persists]' passed (0.013 seconds).
Test Case '-[KizbaTests.SettingsModelTests testSnapshot_treatsNilAndEmptyOverrideAsDifferent]' started.
Test Case '-[KizbaTests.SettingsModelTests testSnapshot_treatsNilAndEmptyOverrideAsDifferent]' passed (0.002 seconds).
Test Case '-[KizbaTests.SettingsModelTests testToggleBiometricOff_authCancelled_leavesEnabled]' started.
Test Case '-[KizbaTests.SettingsModelTests testToggleBiometricOff_authCancelled_leavesEnabled]' passed (0.103 seconds).
Test Case '-[KizbaTests.SettingsModelTests testToggleBiometricOff_failedAuth_leavesEnabled_andReturnsFailure]' started.
Test Case '-[KizbaTests.SettingsModelTests testToggleBiometricOff_failedAuth_leavesEnabled_andReturnsFailure]' passed (0.104 seconds).
Test Case '-[KizbaTests.SettingsModelTests testToggleBiometricOff_requiresAuth_successPersists]' started.
Test Case '-[KizbaTests.SettingsModelTests testToggleBiometricOff_requiresAuth_successPersists]' passed (0.103 seconds).
Test Case '-[KizbaTests.SettingsModelTests testToggleBiometricOn_persistsWithoutAuth]' started.
Test Case '-[KizbaTests.SettingsModelTests testToggleBiometricOn_persistsWithoutAuth]' passed (0.103 seconds).
Test Suite 'SettingsModelTests' passed at 2026-05-24 08:25:52.323.
	 Executed 38 tests, with 0 failures (0 unexpected) in 0.865 (0.888) seconds
Test Suite 'SettingsStoringTests' started at 2026-05-24 08:25:52.324.
Test Case '-[KizbaTests.SettingsStoringTests testKeysAreIsolated]' started.
Test Case '-[KizbaTests.SettingsStoringTests testKeysAreIsolated]' passed (0.002 seconds).
Test Case '-[KizbaTests.SettingsStoringTests testNilRemovesEntry]' started.
Test Case '-[KizbaTests.SettingsStoringTests testNilRemovesEntry]' passed (0.002 seconds).
Test Case '-[KizbaTests.SettingsStoringTests testRoundTripStringAndInt]' started.
Test Case '-[KizbaTests.SettingsStoringTests testRoundTripStringAndInt]' passed (0.002 seconds).
Test Suite 'SettingsStoringTests' passed at 2026-05-24 08:25:52.330.
	 Executed 3 tests, with 0 failures (0 unexpected) in 0.005 (0.007) seconds
Test Suite 'SettingsViewTouchIDTests' started at 2026-05-24 08:25:52.331.
Test Case '-[KizbaTests.SettingsViewTouchIDTests testToggleDisabledWhenBiometricUnavailable]' started.
Test Case '-[KizbaTests.SettingsViewTouchIDTests testToggleDisabledWhenBiometricUnavailable]' passed (0.002 seconds).
Test Case '-[KizbaTests.SettingsViewTouchIDTests testToggleEnabledWhenBiometricAvailable]' started.
Test Case '-[KizbaTests.SettingsViewTouchIDTests testToggleEnabledWhenBiometricAvailable]' passed (0.002 seconds).
Test Suite 'SettingsViewTouchIDTests' passed at 2026-05-24 08:25:52.337.
	 Executed 2 tests, with 0 failures (0 unexpected) in 0.004 (0.005) seconds
Test Suite 'ShellCommandRunningTests' started at 2026-05-24 08:25:52.337.
Test Case '-[KizbaTests.ShellCommandRunningTests testRunForwardsArgumentsAndReturnsResult]' started.
Test Case '-[KizbaTests.ShellCommandRunningTests testRunForwardsArgumentsAndReturnsResult]' passed (0.003 seconds).
Test Suite 'ShellCommandRunningTests' passed at 2026-05-24 08:25:52.342.
	 Executed 1 test, with 0 failures (0 unexpected) in 0.003 (0.004) seconds
Test Suite 'SidebarModelTests' started at 2026-05-24 08:25:52.342.
Test Case '-[KizbaTests.SidebarModelTests testInit_foldersStartEmpty]' started.
Test Case '-[KizbaTests.SidebarModelTests testInit_foldersStartEmpty]' passed (0.001 seconds).
Test Case '-[KizbaTests.SidebarModelTests testLoad_producesSortedTopLevelFolders_fromPreviewEnvironment]' started.
Test Case '-[KizbaTests.SidebarModelTests testLoad_producesSortedTopLevelFolders_fromPreviewEnvironment]' passed (0.001 seconds).
Test Case '-[KizbaTests.SidebarModelTests testObserveChanges_refreshesFolderTree_whenNestedEntryIsInserted]' started.
Test Case '-[KizbaTests.SidebarModelTests testObserveChanges_refreshesFolderTree_whenNestedEntryIsInserted]' passed (0.036 seconds).
Test Case '-[KizbaTests.SidebarModelTests testTopLevelFolders_dedupesRepeatedHeads]' started.
Test Case '-[KizbaTests.SidebarModelTests testTopLevelFolders_dedupesRepeatedHeads]' passed (0.002 seconds).
Test Case '-[KizbaTests.SidebarModelTests testTopLevelFolders_isPureAndDeterministic]' started.
Test Case '-[KizbaTests.SidebarModelTests testTopLevelFolders_isPureAndDeterministic]' passed (0.002 seconds).
Test Case '-[KizbaTests.SidebarModelTests testTopLevelFolders_skipsTopLevelEntriesWithoutSlash]' started.
Test Case '-[KizbaTests.SidebarModelTests testTopLevelFolders_skipsTopLevelEntriesWithoutSlash]' passed (0.002 seconds).
Test Suite 'SidebarModelTests' passed at 2026-05-24 08:25:52.392.
	 Executed 6 tests, with 0 failures (0 unexpected) in 0.045 (0.050) seconds
Test Suite 'SourceGrepTests' started at 2026-05-24 08:25:52.392.
Test Case '-[KizbaTests.SourceGrepTests testGitDomainTypesNonConformances]' started.
Test Case '-[KizbaTests.SourceGrepTests testGitDomainTypesNonConformances]' passed (0.969 seconds).
Test Case '-[KizbaTests.SourceGrepTests testIconOnlyButtonsHaveHelp_inAuditedFeatures]' started.
Test Case '-[KizbaTests.SourceGrepTests testIconOnlyButtonsHaveHelp_inAuditedFeatures]' passed (0.022 seconds).
Test Case '-[KizbaTests.SourceGrepTests testMockPassManagerIsDebugOnly]' started.
Test Case '-[KizbaTests.SourceGrepTests testMockPassManagerIsDebugOnly]' passed (0.001 seconds).
Test Case '-[KizbaTests.SourceGrepTests testNoCodableOrCustomStringConvertible_onSearchResult]' started.
Test Case '-[KizbaTests.SourceGrepTests testNoCodableOrCustomStringConvertible_onSearchResult]' passed (0.034 seconds).
Test Case '-[KizbaTests.SourceGrepTests testNoDirectLoggerInstantiationOutsideWrapper]' started.
Test Case '-[KizbaTests.SourceGrepTests testNoDirectLoggerInstantiationOutsideWrapper]' passed (0.024 seconds).
Test Case '-[KizbaTests.SourceGrepTests testNoForceCast_inKizbaSource]' started.
Test Case '-[KizbaTests.SourceGrepTests testNoForceCast_inKizbaSource]' passed (0.069 seconds).
Test Case '-[KizbaTests.SourceGrepTests testNoInlineNumericPadding_inPresentationOutsideDS]' started.
Test Case '-[KizbaTests.SourceGrepTests testNoInlineNumericPadding_inPresentationOutsideDS]' passed (0.031 seconds).
Test Case '-[KizbaTests.SourceGrepTests testNoLiteralAnimation_inPresentationOutsideDS]' started.
Test Case '-[KizbaTests.SourceGrepTests testNoLiteralAnimation_inPresentationOutsideDS]' passed (0.030 seconds).
Test Case '-[KizbaTests.SourceGrepTests testNoLiteralFont_inPresentationOutsideDS]' started.
Test Case '-[KizbaTests.SourceGrepTests testNoLiteralFont_inPresentationOutsideDS]' passed (0.030 seconds).
Test Case '-[KizbaTests.SourceGrepTests testNoLiteralForegroundShortcut_inPresentationOutsideDS]' started.
Test Case '-[KizbaTests.SourceGrepTests testNoLiteralForegroundShortcut_inPresentationOutsideDS]' passed (0.037 seconds).
Test Case '-[KizbaTests.SourceGrepTests testNoLiteralSwiftUIColor_inPresentationOutsideDS]' started.
Test Case '-[KizbaTests.SourceGrepTests testNoLiteralSwiftUIColor_inPresentationOutsideDS]' passed (0.031 seconds).
Test Case '-[KizbaTests.SourceGrepTests testNoModelConstructorInSheetBody]' started.
Test Case '-[KizbaTests.SourceGrepTests testNoModelConstructorInSheetBody]' passed (0.024 seconds).
Test Case '-[KizbaTests.SourceGrepTests testNoNumericCornerRadius_inPresentationOutsideDS]' started.
Test Case '-[KizbaTests.SourceGrepTests testNoNumericCornerRadius_inPresentationOutsideDS]' passed (0.035 seconds).
Test Case '-[KizbaTests.SourceGrepTests testNoNumericOpacity_inPresentationOutsideDS]' started.
Test Case '-[KizbaTests.SourceGrepTests testNoNumericOpacity_inPresentationOutsideDS]' passed (0.029 seconds).
Test Case '-[KizbaTests.SourceGrepTests testNoRawPrintInInfrastructure]' started.
Test Case '-[KizbaTests.SourceGrepTests testNoRawPrintInInfrastructure]' passed (0.021 seconds).
Test Case '-[KizbaTests.SourceGrepTests testNoRawPrintInKizbaSource]' started.
Test Case '-[KizbaTests.SourceGrepTests testNoRawPrintInKizbaSource]' passed (0.081 seconds).
Test Case '-[KizbaTests.SourceGrepTests testNoStdinLogging_inKizbaSource]' started.
Test Case '-[KizbaTests.SourceGrepTests testNoStdinLogging_inKizbaSource]' passed (0.079 seconds).
Test Case '-[KizbaTests.SourceGrepTests testNoStdoutReferencesInInfrastructure]' started.
Test Case '-[KizbaTests.SourceGrepTests testNoStdoutReferencesInInfrastructure]' passed (0.047 seconds).
Test Case '-[KizbaTests.SourceGrepTests testOTPSecretIsNotCodable]' started.
Test Case '-[KizbaTests.SourceGrepTests testOTPSecretIsNotCodable]' passed (0.032 seconds).
Test Case '-[KizbaTests.SourceGrepTests testOTPSecretIsNotStringConvertible]' started.
Test Case '-[KizbaTests.SourceGrepTests testOTPSecretIsNotStringConvertible]' passed (0.001 seconds).
Test Case '-[KizbaTests.SourceGrepTests testPassSecretIsNotCodable]' started.
Test Case '-[KizbaTests.SourceGrepTests testPassSecretIsNotCodable]' passed (0.031 seconds).
Test Case '-[KizbaTests.SourceGrepTests testPassSecretIsNotStringConvertible]' started.
Test Case '-[KizbaTests.SourceGrepTests testPassSecretIsNotStringConvertible]' passed (0.001 seconds).
Test Case '-[KizbaTests.SourceGrepTests testPresentationModelsRequireObservable]' started.
Test Case '-[KizbaTests.SourceGrepTests testPresentationModelsRequireObservable]' passed (0.011 seconds).
Test Case '-[KizbaTests.SourceGrepTests testSourceGrepFixtures_expectRuleBehavior]' started.
Test Case '-[KizbaTests.SourceGrepTests testSourceGrepFixtures_expectRuleBehavior]' passed (0.001 seconds).
Test Suite 'SourceGrepTests' passed at 2026-05-24 08:25:54.070.
	 Executed 24 tests, with 0 failures (0 unexpected) in 1.670 (1.677) seconds
Test Suite 'StatusItemControllerTests' started at 2026-05-24 08:25:54.070.
Test Case '-[KizbaTests.StatusItemControllerTests testHide_idempotent]' started.
Test Case '-[KizbaTests.StatusItemControllerTests testHide_idempotent]' passed (0.005 seconds).
Test Case '-[KizbaTests.StatusItemControllerTests testShow_idempotent]' started.
Test Case '-[KizbaTests.StatusItemControllerTests testShow_idempotent]' passed (0.004 seconds).
Test Case '-[KizbaTests.StatusItemControllerTests testToggle_showsAndHides]' started.
2026-05-24 08:25:54.082415+0200 Kizba[11882:1070614] [SceneClient] No scene exists for identity: com.apple.controlcenter:A43ABB51-6564-45AC-9BBC-911A5BBC80B2-Aux[1]-NSStatusItemView
2026-05-24 08:25:54.086964+0200 Kizba[11882:1070614] [SceneClient] No scene exists for identity: com.apple.controlcenter:EFAEC2C6-300F-4165-8E07-DEB61E68BFD3-Aux[1]-NSStatusItemView
Test Case '-[KizbaTests.StatusItemControllerTests testToggle_showsAndHides]' passed (0.011 seconds).
Test Suite 'StatusItemControllerTests' passed at 2026-05-24 08:25:54.091.
	 Executed 3 tests, with 0 failures (0 unexpected) in 0.020 (0.021) seconds
Test Suite 'StoreChangeTests' started at 2026-05-24 08:25:54.091.
Test Case '-[KizbaTests.StoreChangeTests testAllCasesConstruct]' started.
Test Case '-[KizbaTests.StoreChangeTests testAllCasesConstruct]' passed (0.001 seconds).
2026-05-24 08:25:54.092246+0200 Kizba[11882:1071152] [SceneClient] No scene exists for identity: com.apple.controlcenter:DF75C4ED-6AA5-43E2-9A38-D0DD955CA45F-Aux[1]-NSStatusItemView
Test Case '-[KizbaTests.StoreChangeTests testBulkSelfEquality]' started.
Test Case '-[KizbaTests.StoreChangeTests testBulkSelfEquality]' passed (0.001 seconds).
Test Case '-[KizbaTests.StoreChangeTests testDifferentCasesWithSamePathAreNotEqual]' started.
Test Case '-[KizbaTests.StoreChangeTests testDifferentCasesWithSamePathAreNotEqual]' passed (0.013 seconds).
Test Case '-[KizbaTests.StoreChangeTests testHashableInSetDeduplicates]' started.
Test Case '-[KizbaTests.StoreChangeTests testHashableInSetDeduplicates]' passed (0.001 seconds).
Test Case '-[KizbaTests.StoreChangeTests testInsertedEqualityRespectsPath]' started.
Test Case '-[KizbaTests.StoreChangeTests testInsertedEqualityRespectsPath]' passed (0.001 seconds).
Test Case '-[KizbaTests.StoreChangeTests testIsSendable]' started.
Test Case '-[KizbaTests.StoreChangeTests testIsSendable]' passed (0.001 seconds).
Test Case '-[KizbaTests.StoreChangeTests testMovedEqualityIsDirectional]' started.
Test Case '-[KizbaTests.StoreChangeTests testMovedEqualityIsDirectional]' passed (0.001 seconds).
Test Suite 'StoreChangeTests' passed at 2026-05-24 08:25:54.109.
	 Executed 7 tests, with 0 failures (0 unexpected) in 0.017 (0.018) seconds
Test Suite 'ThemeTokenTests' started at 2026-05-24 08:25:54.109.
Test Case '-[KizbaTests.ThemeTokenTests testContrastChecker_blackOnWhiteIsApproximately21]' started.
Test Case '-[KizbaTests.ThemeTokenTests testContrastChecker_blackOnWhiteIsApproximately21]' passed (0.001 seconds).
Test Case '-[KizbaTests.ThemeTokenTests testContrastChecker_compositingFullyOpaqueOverIsIdentity]' started.
Test Case '-[KizbaTests.ThemeTokenTests testContrastChecker_compositingFullyOpaqueOverIsIdentity]' passed (0.010 seconds).
Test Case '-[KizbaTests.ThemeTokenTests testContrastChecker_isSymmetric]' started.
Test Case '-[KizbaTests.ThemeTokenTests testContrastChecker_isSymmetric]' passed (0.001 seconds).
Test Case '-[KizbaTests.ThemeTokenTests testContrastChecker_whiteOnWhiteIsExactly1]' started.
Test Case '-[KizbaTests.ThemeTokenTests testContrastChecker_whiteOnWhiteIsExactly1]' passed (0.001 seconds).
Test Case '-[KizbaTests.ThemeTokenTests testTheme_allVariants_focusRingInnerIsVisibleOnAccent]' started.
Test Case '-[KizbaTests.ThemeTokenTests testTheme_allVariants_focusRingInnerIsVisibleOnAccent]' passed (0.001 seconds).
Test Case '-[KizbaTests.ThemeTokenTests testTheme_allVariants_focusRingInnerIsVisibleOnRing]' started.
Test Case '-[KizbaTests.ThemeTokenTests testTheme_allVariants_focusRingInnerIsVisibleOnRing]' passed (0.001 seconds).
Test Case '-[KizbaTests.ThemeTokenTests testTheme_allVariants_focusRingOuterIsVisibleOnSurface]' started.
Test Case '-[KizbaTests.ThemeTokenTests testTheme_allVariants_focusRingOuterIsVisibleOnSurface]' passed (0.001 seconds).
Test Case '-[KizbaTests.ThemeTokenTests testTheme_allVariants_haveCorrectIDWiring]' started.
Test Case '-[KizbaTests.ThemeTokenTests testTheme_allVariants_haveCorrectIDWiring]' passed (0.001 seconds).
Test Case '-[KizbaTests.ThemeTokenTests testTheme_allVariants_onAccentMeetsAA]' started.
Test Case '-[KizbaTests.ThemeTokenTests testTheme_allVariants_onAccentMeetsAA]' passed (0.001 seconds).
Test Case '-[KizbaTests.ThemeTokenTests testTheme_allVariants_onDangerMeetsAA]' started.
Test Case '-[KizbaTests.ThemeTokenTests testTheme_allVariants_onDangerMeetsAA]' passed (0.001 seconds).
Test Case '-[KizbaTests.ThemeTokenTests testTheme_allVariants_onSuccessMeetsAA]' started.
Test Case '-[KizbaTests.ThemeTokenTests testTheme_allVariants_onSuccessMeetsAA]' passed (0.001 seconds).
Test Case '-[KizbaTests.ThemeTokenTests testTheme_allVariants_onSurfaceMeetsAAA_7to1]' started.
Test Case '-[KizbaTests.ThemeTokenTests testTheme_allVariants_onSurfaceMeetsAAA_7to1]' passed (0.001 seconds).
Test Case '-[KizbaTests.ThemeTokenTests testTheme_allVariants_onSurfaceMutedMeetsAA_4_5to1]' started.
Test Case '-[KizbaTests.ThemeTokenTests testTheme_allVariants_onSurfaceMutedMeetsAA_4_5to1]' passed (0.001 seconds).
Test Case '-[KizbaTests.ThemeTokenTests testTheme_allVariants_onWarningMeetsAA]' started.
Test Case '-[KizbaTests.ThemeTokenTests testTheme_allVariants_onWarningMeetsAA]' passed (0.022 seconds).
Test Case '-[KizbaTests.ThemeTokenTests testTheme_allVariants_passwordRevealMeetsAAA_7to1]' started.
Test Case '-[KizbaTests.ThemeTokenTests testTheme_allVariants_passwordRevealMeetsAAA_7to1]' passed (0.001 seconds).
Test Case '-[KizbaTests.ThemeTokenTests testTheme_dark_roleColorsAreDistinct]' started.
Test Case '-[KizbaTests.ThemeTokenTests testTheme_dark_roleColorsAreDistinct]' passed (0.001 seconds).
Test Case '-[KizbaTests.ThemeTokenTests testTheme_equality_freshlyConstructedMatchesStaticConstant]' started.
Test Case '-[KizbaTests.ThemeTokenTests testTheme_equality_freshlyConstructedMatchesStaticConstant]' passed (0.001 seconds).
Test Case '-[KizbaTests.ThemeTokenTests testTheme_equality_sameVariantIsEqual_differentVariantsAreNot]' started.
Test Case '-[KizbaTests.ThemeTokenTests testTheme_equality_sameVariantIsEqual_differentVariantsAreNot]' passed (0.001 seconds).
Test Case '-[KizbaTests.ThemeTokenTests testTheme_highContrast_doesNotRegressAnyBodyContrast]' started.
Test Case '-[KizbaTests.ThemeTokenTests testTheme_highContrast_doesNotRegressAnyBodyContrast]' passed (0.001 seconds).
Test Case '-[KizbaTests.ThemeTokenTests testTheme_highContrast_mutedTextIsDeliberatelyEqualToOnSurface]' started.
Test Case '-[KizbaTests.ThemeTokenTests testTheme_highContrast_mutedTextIsDeliberatelyEqualToOnSurface]' passed (0.001 seconds).
Test Case '-[KizbaTests.ThemeTokenTests testTheme_highContrast_onSurfaceMutedMeetsAAA_7to1]' started.
Test Case '-[KizbaTests.ThemeTokenTests testTheme_highContrast_onSurfaceMutedMeetsAAA_7to1]' passed (0.001 seconds).
Test Case '-[KizbaTests.ThemeTokenTests testTheme_ID_hasExactlyFourCases]' started.
Test Case '-[KizbaTests.ThemeTokenTests testTheme_ID_hasExactlyFourCases]' passed (0.001 seconds).
Test Case '-[KizbaTests.ThemeTokenTests testTheme_light_roleColorsAreDistinct]' started.
Test Case '-[KizbaTests.ThemeTokenTests testTheme_light_roleColorsAreDistinct]' passed (0.001 seconds).
Test Case '-[KizbaTests.ThemeTokenTests testTheme_motion_instantOrReduceMotionSuppressesAnimation]' started.
Test Case '-[KizbaTests.ThemeTokenTests testTheme_motion_instantOrReduceMotionSuppressesAnimation]' passed (0.001 seconds).
Test Case '-[KizbaTests.ThemeTokenTests testTheme_motion_nonInstantTokensProduceAnimationWhenReduceMotionOff]' started.
Test Case '-[KizbaTests.ThemeTokenTests testTheme_motion_nonInstantTokensProduceAnimationWhenReduceMotionOff]' passed (0.001 seconds).
Test Case '-[KizbaTests.ThemeTokenTests testTheme_radius_matchesPlanValues]' started.
Test Case '-[KizbaTests.ThemeTokenTests testTheme_radius_matchesPlanValues]' passed (0.001 seconds).
Test Case '-[KizbaTests.ThemeTokenTests testTheme_spacing_matchesPlanValues]' started.
Test Case '-[KizbaTests.ThemeTokenTests testTheme_spacing_matchesPlanValues]' passed (0.001 seconds).
Test Suite 'ThemeTokenTests' passed at 2026-05-24 08:25:54.214.
	 Executed 27 tests, with 0 failures (0 unexpected) in 0.051 (0.105) seconds
Test Suite 'ToastCenterTests' started at 2026-05-24 08:25:54.214.
Test Case '-[KizbaTests.ToastCenterTests testAutoDismiss_clearsVisibleAfterDuration]' started.
2026-05-24 08:25:54.234384+0200 Kizba[11882:1070534] [StatusBar] Unhandled disconnected auxiliary scene <NSHostedViewScene: 0xb8d4e9ab0>
2026-05-24 08:25:54.234571+0200 Kizba[11882:1070534] [Common] [BSBlockSentinel:FBSWorkspaceScenesClient] failed!
2026-05-24 08:25:54.238009+0200 Kizba[11882:1070534] [StatusBar] Unhandled disconnected auxiliary scene <NSHostedViewScene: 0xb8d4e98f0>
2026-05-24 08:25:54.238174+0200 Kizba[11882:1070534] [Common] [BSBlockSentinel:FBSWorkspaceScenesClient] failed!
2026-05-24 08:25:54.238325+0200 Kizba[11882:1070534] [StatusBar] Unhandled disconnected scene <NSStatusItemScene: 0xb901dc4b0>
2026-05-24 08:25:54.238350+0200 Kizba[11882:1070534] [Common] [BSBlockSentinel:FBSWorkspaceScenesClient] failed!
2026-05-24 08:25:54.238379+0200 Kizba[11882:1070534] [StatusBar] Unhandled disconnected scene <NSStatusItemScene: 0xb901df160>
2026-05-24 08:25:54.238396+0200 Kizba[11882:1070534] [Common] [BSBlockSentinel:FBSWorkspaceScenesClient] failed!
2026-05-24 08:25:54.238579+0200 Kizba[11882:1070534] [StatusBar] Unhandled disconnected auxiliary scene <NSHostedViewScene: 0xb8d4e9260>
2026-05-24 08:25:54.238691+0200 Kizba[11882:1070534] [Common] [BSBlockSentinel:FBSWorkspaceScenesClient] failed!
2026-05-24 08:25:54.238712+0200 Kizba[11882:1070534] [StatusBar] Unhandled disconnected scene <NSStatusItemScene: 0xb9035cc80>
2026-05-24 08:25:54.238724+0200 Kizba[11882:1070534] [Common] [BSBlockSentinel:FBSWorkspaceScenesClient] failed!
Test Case '-[KizbaTests.ToastCenterTests testAutoDismiss_clearsVisibleAfterDuration]' passed (0.380 seconds).
Test Case '-[KizbaTests.ToastCenterTests testDedup_distinguishesByMessage]' started.
Test Case '-[KizbaTests.ToastCenterTests testDedup_distinguishesByMessage]' passed (0.002 seconds).
Test Case '-[KizbaTests.ToastCenterTests testDedup_distinguishesBySeverity]' started.
Test Case '-[KizbaTests.ToastCenterTests testDedup_distinguishesBySeverity]' passed (0.002 seconds).
Test Case '-[KizbaTests.ToastCenterTests testDedup_expiresAfterOneSecond]' started.
Test Case '-[KizbaTests.ToastCenterTests testDedup_expiresAfterOneSecond]' passed (1.213 seconds).
Test Case '-[KizbaTests.ToastCenterTests testDedup_identicalPostWithinWindow_isDropped]' started.
Test Case '-[KizbaTests.ToastCenterTests testDedup_identicalPostWithinWindow_isDropped]' passed (0.002 seconds).
Test Case '-[KizbaTests.ToastCenterTests testDefaultDuration_actionable_isTenSeconds]' started.
Test Case '-[KizbaTests.ToastCenterTests testDefaultDuration_actionable_isTenSeconds]' passed (0.002 seconds).
Test Case '-[KizbaTests.ToastCenterTests testDefaultDuration_nonActionable_isFourSeconds]' started.
Test Case '-[KizbaTests.ToastCenterTests testDefaultDuration_nonActionable_isFourSeconds]' passed (0.001 seconds).
Test Case '-[KizbaTests.ToastCenterTests testDismiss_matchingID_clearsVisible]' started.
Test Case '-[KizbaTests.ToastCenterTests testDismiss_matchingID_clearsVisible]' passed (0.001 seconds).
Test Case '-[KizbaTests.ToastCenterTests testDismiss_nonMatchingID_isNoOp]' started.
Test Case '-[KizbaTests.ToastCenterTests testDismiss_nonMatchingID_isNoOp]' passed (0.001 seconds).
Test Case '-[KizbaTests.ToastCenterTests testExplicitDuration_overridesDefault]' started.
Test Case '-[KizbaTests.ToastCenterTests testExplicitDuration_overridesDefault]' passed (0.001 seconds).
Test Case '-[KizbaTests.ToastCenterTests testNewPost_cancelsPriorAutoDismissTask]' started.
Test Case '-[KizbaTests.ToastCenterTests testNewPost_cancelsPriorAutoDismissTask]' passed (0.268 seconds).
Test Case '-[KizbaTests.ToastCenterTests testNewPost_preemptsCurrentlyVisible]' started.
Test Case '-[KizbaTests.ToastCenterTests testNewPost_preemptsCurrentlyVisible]' passed (0.002 seconds).
Test Case '-[KizbaTests.ToastCenterTests testPost_setsVisibleToPostedToast]' started.
Test Case '-[KizbaTests.ToastCenterTests testPost_setsVisibleToPostedToast]' passed (0.002 seconds).
Test Case '-[KizbaTests.ToastCenterTests testToast_freshIDPerInstance]' started.
Test Case '-[KizbaTests.ToastCenterTests testToast_freshIDPerInstance]' passed (0.002 seconds).
Test Suite 'ToastCenterTests' passed at 2026-05-24 08:25:56.102.
	 Executed 14 tests, with 0 failures (0 unexpected) in 1.879 (1.888) seconds
Test Suite 'ToastViewTests' started at 2026-05-24 08:25:56.103.
Test Case '-[KizbaTests.ToastViewTests testToastView_accessibilityLabel_includesSeverityAndTitleWhenMessageIsNil]' started.
Test Case '-[KizbaTests.ToastViewTests testToastView_accessibilityLabel_includesSeverityAndTitleWhenMessageIsNil]' passed (0.002 seconds).
Test Case '-[KizbaTests.ToastViewTests testToastView_accessibilityLabel_includesSeverityTitleAndMessageWhenAllPresent]' started.
Test Case '-[KizbaTests.ToastViewTests testToastView_accessibilityLabel_includesSeverityTitleAndMessageWhenAllPresent]' passed (0.002 seconds).
Test Case '-[KizbaTests.ToastViewTests testToastView_accessibilityLabel_isStableAcrossSeverities]' started.
Test Case '-[KizbaTests.ToastViewTests testToastView_accessibilityLabel_isStableAcrossSeverities]' passed (0.001 seconds).
Test Case '-[KizbaTests.ToastViewTests testToastView_accessibilityLabel_skipsEmptyMessage]' started.
Test Case '-[KizbaTests.ToastViewTests testToastView_accessibilityLabel_skipsEmptyMessage]' passed (0.001 seconds).
Test Case '-[KizbaTests.ToastViewTests testToastView_severityLabel_isCorrectPerSeverity]' started.
Test Case '-[KizbaTests.ToastViewTests testToastView_severityLabel_isCorrectPerSeverity]' passed (0.001 seconds).
Test Case '-[KizbaTests.ToastViewTests testToastView_severityLabel_isNonEmptyForEverySeverity]' started.
Test Case '-[KizbaTests.ToastViewTests testToastView_severityLabel_isNonEmptyForEverySeverity]' passed (0.001 seconds).
Test Case '-[KizbaTests.ToastViewTests testToastView_severityLabel_isUniquePerSeverity]' started.
Test Case '-[KizbaTests.ToastViewTests testToastView_severityLabel_isUniquePerSeverity]' passed (0.001 seconds).
Test Suite 'ToastViewTests' passed at 2026-05-24 08:25:56.112.
	 Executed 7 tests, with 0 failures (0 unexpected) in 0.007 (0.009) seconds
Test Suite 'TouchIDProtectionHelpTests' started at 2026-05-24 08:25:56.127.
Test Case '-[KizbaTests.TouchIDProtectionHelpTests testHelpCatalog_containsTouchIDProtectionTopic]' started.
Test Case '-[KizbaTests.TouchIDProtectionHelpTests testHelpCatalog_containsTouchIDProtectionTopic]' passed (0.001 seconds).
Test Suite 'TouchIDProtectionHelpTests' passed at 2026-05-24 08:25:56.129.
	 Executed 1 test, with 0 failures (0 unexpected) in 0.001 (0.002) seconds
Test Suite 'UndoableActionTests' started at 2026-05-24 08:25:56.129.
Test Case '-[KizbaTests.UndoableActionTests testDeleteCase_constructsWithPathAndSecret]' started.
Test Case '-[KizbaTests.UndoableActionTests testDeleteCase_constructsWithPathAndSecret]' passed (0.001 seconds).
Test Case '-[KizbaTests.UndoableActionTests testInPlaceGenerateCase_constructsWithPathAndPreviousSecret]' started.
Test Case '-[KizbaTests.UndoableActionTests testInPlaceGenerateCase_constructsWithPathAndPreviousSecret]' passed (0.001 seconds).
Test Case '-[KizbaTests.UndoableActionTests testIsNotCodable]' started.
Test Case '-[KizbaTests.UndoableActionTests testIsNotCodable]' passed (0.001 seconds).
Test Case '-[KizbaTests.UndoableActionTests testIsNotCustomStringConvertible]' started.
Test Case '-[KizbaTests.UndoableActionTests testIsNotCustomStringConvertible]' passed (0.001 seconds).
Test Case '-[KizbaTests.UndoableActionTests testIsSendable]' started.
Test Case '-[KizbaTests.UndoableActionTests testIsSendable]' passed (0.024 seconds).
Test Case '-[KizbaTests.UndoableActionTests testMoveCase_constructsWithFromAndTo]' started.
Test Case '-[KizbaTests.UndoableActionTests testMoveCase_constructsWithFromAndTo]' passed (0.002 seconds).
Test Suite 'UndoableActionTests' passed at 2026-05-24 08:25:56.161.
	 Executed 6 tests, with 0 failures (0 unexpected) in 0.029 (0.032) seconds
Test Suite 'UserDefaultsFavoritesStoreTests' started at 2026-05-24 08:25:56.162.
Test Case '-[KizbaTests.UserDefaultsFavoritesStoreTests testAddRemoveTogglePersistence]' started.
Test Case '-[KizbaTests.UserDefaultsFavoritesStoreTests testAddRemoveTogglePersistence]' passed (0.017 seconds).
Test Case '-[KizbaTests.UserDefaultsFavoritesStoreTests testDuplicateAddIdempotent]' started.
Test Case '-[KizbaTests.UserDefaultsFavoritesStoreTests testDuplicateAddIdempotent]' passed (0.009 seconds).
Test Case '-[KizbaTests.UserDefaultsFavoritesStoreTests testEmptyInitialState]' started.
Test Case '-[KizbaTests.UserDefaultsFavoritesStoreTests testEmptyInitialState]' passed (0.008 seconds).
Test Case '-[KizbaTests.UserDefaultsFavoritesStoreTests testInit_doesNotOverwriteNewKey_whenBothPresent]' started.
Test Case '-[KizbaTests.UserDefaultsFavoritesStoreTests testInit_doesNotOverwriteNewKey_whenBothPresent]' passed (0.008 seconds).
Test Case '-[KizbaTests.UserDefaultsFavoritesStoreTests testInit_idempotent_secondConstructionIsNoOp]' started.
Test Case '-[KizbaTests.UserDefaultsFavoritesStoreTests testInit_idempotent_secondConstructionIsNoOp]' passed (0.008 seconds).
Test Case '-[KizbaTests.UserDefaultsFavoritesStoreTests testInit_migratesLegacyFavorites_onceWhenNewKeyAbsent]' started.
Test Case '-[KizbaTests.UserDefaultsFavoritesStoreTests testInit_migratesLegacyFavorites_onceWhenNewKeyAbsent]' passed (0.006 seconds).
Test Suite 'UserDefaultsFavoritesStoreTests' passed at 2026-05-24 08:25:56.220.
	 Executed 6 tests, with 0 failures (0 unexpected) in 0.055 (0.058) seconds
Test Suite 'UserDefaultsFolderExpansionStoreTests' started at 2026-05-24 08:25:56.220.
Test Case '-[KizbaTests.UserDefaultsFolderExpansionStoreTests testEmptyInitialState]' started.
Test Case '-[KizbaTests.UserDefaultsFolderExpansionStoreTests testEmptyInitialState]' passed (0.002 seconds).
Test Case '-[KizbaTests.UserDefaultsFolderExpansionStoreTests testSetExpanded_isIdempotent_andDoesNotDuplicatePersisted]' started.
Test Case '-[KizbaTests.UserDefaultsFolderExpansionStoreTests testSetExpanded_isIdempotent_andDoesNotDuplicatePersisted]' passed (0.005 seconds).
Test Case '-[KizbaTests.UserDefaultsFolderExpansionStoreTests testSetExpanded_persistsAcrossInstances]' started.
Test Case '-[KizbaTests.UserDefaultsFolderExpansionStoreTests testSetExpanded_persistsAcrossInstances]' passed (0.007 seconds).
Test Case '-[KizbaTests.UserDefaultsFolderExpansionStoreTests testSetExpanded_storesSetAsArray_withMultipleEntries]' started.
Test Case '-[KizbaTests.UserDefaultsFolderExpansionStoreTests testSetExpanded_storesSetAsArray_withMultipleEntries]' passed (0.004 seconds).
Test Case '-[KizbaTests.UserDefaultsFolderExpansionStoreTests testSetExpanded_toggleRoundTrip]' started.
Test Case '-[KizbaTests.UserDefaultsFolderExpansionStoreTests testSetExpanded_toggleRoundTrip]' passed (0.004 seconds).
Test Suite 'UserDefaultsFolderExpansionStoreTests' passed at 2026-05-24 08:25:56.244.
	 Executed 5 tests, with 0 failures (0 unexpected) in 0.023 (0.024) seconds
Test Suite 'UserDefaultsRecentEntriesStoreTests' started at 2026-05-24 08:25:56.245.
Test Case '-[KizbaTests.UserDefaultsRecentEntriesStoreTests testClear_emptiesList]' started.
Test Case '-[KizbaTests.UserDefaultsRecentEntriesStoreTests testClear_emptiesList]' passed (0.006 seconds).
Test Case '-[KizbaTests.UserDefaultsRecentEntriesStoreTests testInit_ignoresBothLegacyKeys]' started.
Test Case '-[KizbaTests.UserDefaultsRecentEntriesStoreTests testInit_ignoresBothLegacyKeys]' passed (0.010 seconds).
Test Case '-[KizbaTests.UserDefaultsRecentEntriesStoreTests testInit_ignoresLegacyKey_andRemovesIt]' started.
Test Case '-[KizbaTests.UserDefaultsRecentEntriesStoreTests testInit_ignoresLegacyKey_andRemovesIt]' passed (0.005 seconds).
Test Case '-[KizbaTests.UserDefaultsRecentEntriesStoreTests testInit_ignoresLegacyV1Key_andRemovesIt]' started.
Test Case '-[KizbaTests.UserDefaultsRecentEntriesStoreTests testInit_ignoresLegacyV1Key_andRemovesIt]' passed (0.004 seconds).
Test Case '-[KizbaTests.UserDefaultsRecentEntriesStoreTests testInit_readsFromNewNamespacedKey]' started.
Test Case '-[KizbaTests.UserDefaultsRecentEntriesStoreTests testInit_readsFromNewNamespacedKey]' passed (0.005 seconds).
Test Case '-[KizbaTests.UserDefaultsRecentEntriesStoreTests testInit_usesDefaultFromSettingsKey]' started.
Test Case '-[KizbaTests.UserDefaultsRecentEntriesStoreTests testInit_usesDefaultFromSettingsKey]' passed (0.007 seconds).
Test Case '-[KizbaTests.UserDefaultsRecentEntriesStoreTests testRecentPaths_returnsOrderedList]' started.
Test Case '-[KizbaTests.UserDefaultsRecentEntriesStoreTests testRecentPaths_returnsOrderedList]' passed (0.005 seconds).
Test Case '-[KizbaTests.UserDefaultsRecentEntriesStoreTests testRecentsChanged_emitsOnClear]' started.
Test Case '-[KizbaTests.UserDefaultsRecentEntriesStoreTests testRecentsChanged_emitsOnClear]' passed (0.087 seconds).
Test Case '-[KizbaTests.UserDefaultsRecentEntriesStoreTests testRecentsChanged_emitsOnRecord]' started.
Test Case '-[KizbaTests.UserDefaultsRecentEntriesStoreTests testRecentsChanged_emitsOnRecord]' passed (0.074 seconds).
Test Case '-[KizbaTests.UserDefaultsRecentEntriesStoreTests testRecord_addsPath]' started.
Test Case '-[KizbaTests.UserDefaultsRecentEntriesStoreTests testRecord_addsPath]' passed (0.012 seconds).
Test Case '-[KizbaTests.UserDefaultsRecentEntriesStoreTests testRecord_evictsOldestBeyondMax]' started.
Test Case '-[KizbaTests.UserDefaultsRecentEntriesStoreTests testRecord_evictsOldestBeyondMax]' passed (0.016 seconds).
Test Case '-[KizbaTests.UserDefaultsRecentEntriesStoreTests testRecord_movesExistingToFront]' started.
Test Case '-[KizbaTests.UserDefaultsRecentEntriesStoreTests testRecord_movesExistingToFront]' passed (0.012 seconds).
Test Case '-[KizbaTests.UserDefaultsRecentEntriesStoreTests testRecord_persistsToNewKey_only]' started.
Test Case '-[KizbaTests.UserDefaultsRecentEntriesStoreTests testRecord_persistsToNewKey_only]' passed (0.007 seconds).
Test Case '-[KizbaTests.UserDefaultsRecentEntriesStoreTests testSetMaxCount_clampsHigh]' started.
Test Case '-[KizbaTests.UserDefaultsRecentEntriesStoreTests testSetMaxCount_clampsHigh]' passed (0.008 seconds).
Test Case '-[KizbaTests.UserDefaultsRecentEntriesStoreTests testSetMaxCount_clampsLow]' started.
Test Case '-[KizbaTests.UserDefaultsRecentEntriesStoreTests testSetMaxCount_clampsLow]' passed (0.010 seconds).
Test Case '-[KizbaTests.UserDefaultsRecentEntriesStoreTests testSetMaxCount_noopWhenUnchanged]' started.
Test Case '-[KizbaTests.UserDefaultsRecentEntriesStoreTests testSetMaxCount_noopWhenUnchanged]' passed (0.163 seconds).
Test Case '-[KizbaTests.UserDefaultsRecentEntriesStoreTests testSetMaxCount_truncatesAndEmitsOnce]' started.
Test Case '-[KizbaTests.UserDefaultsRecentEntriesStoreTests testSetMaxCount_truncatesAndEmitsOnce]' passed (0.172 seconds).
Test Suite 'UserDefaultsRecentEntriesStoreTests' passed at 2026-05-24 08:25:56.855.
	 Executed 17 tests, with 0 failures (0 unexpected) in 0.603 (0.610) seconds
Test Suite 'UserDefaultsSettingsStoreTests' started at 2026-05-24 08:25:56.855.
Test Case '-[KizbaTests.UserDefaultsSettingsStoreTests testClear]' started.
Test Case '-[KizbaTests.UserDefaultsSettingsStoreTests testClear]' passed (0.012 seconds).
Test Case '-[KizbaTests.UserDefaultsSettingsStoreTests testDefaults_clipboardClearDelaySeconds]' started.
Test Case '-[KizbaTests.UserDefaultsSettingsStoreTests testDefaults_clipboardClearDelaySeconds]' passed (0.002 seconds).
Test Case '-[KizbaTests.UserDefaultsSettingsStoreTests testNamespacingIsolation]' started.
Test Case '-[KizbaTests.UserDefaultsSettingsStoreTests testNamespacingIsolation]' passed (0.003 seconds).
Test Case '-[KizbaTests.UserDefaultsSettingsStoreTests testRecentsLimit_clampsHigh]' started.
Test Case '-[KizbaTests.UserDefaultsSettingsStoreTests testRecentsLimit_clampsHigh]' passed (0.003 seconds).
Test Case '-[KizbaTests.UserDefaultsSettingsStoreTests testRecentsLimit_clampsLow]' started.
Test Case '-[KizbaTests.UserDefaultsSettingsStoreTests testRecentsLimit_clampsLow]' passed (0.003 seconds).
Test Case '-[KizbaTests.UserDefaultsSettingsStoreTests testRecentsLimit_defaultsToSeven]' started.
Test Case '-[KizbaTests.UserDefaultsSettingsStoreTests testRecentsLimit_defaultsToSeven]' passed (0.002 seconds).
Test Case '-[KizbaTests.UserDefaultsSettingsStoreTests testRecentsLimit_roundTrip]' started.
Test Case '-[KizbaTests.UserDefaultsSettingsStoreTests testRecentsLimit_roundTrip]' passed (0.003 seconds).
Test Case '-[KizbaTests.UserDefaultsSettingsStoreTests testResetClearsAll]' started.
Test Case '-[KizbaTests.UserDefaultsSettingsStoreTests testResetClearsAll]' passed (0.003 seconds).
Test Case '-[KizbaTests.UserDefaultsSettingsStoreTests testRoundTripPerType]' started.
Test Case '-[KizbaTests.UserDefaultsSettingsStoreTests testRoundTripPerType]' passed (0.003 seconds).
Test Case '-[KizbaTests.UserDefaultsSettingsStoreTests testShowFavorites_defaultsTrue]' started.
Test Case '-[KizbaTests.UserDefaultsSettingsStoreTests testShowFavorites_defaultsTrue]' passed (0.001 seconds).
Test Case '-[KizbaTests.UserDefaultsSettingsStoreTests testShowFavorites_roundTrip]' started.
Test Case '-[KizbaTests.UserDefaultsSettingsStoreTests testShowFavorites_roundTrip]' passed (0.002 seconds).
Test Case '-[KizbaTests.UserDefaultsSettingsStoreTests testShowRecents_defaultsTrue]' started.
Test Case '-[KizbaTests.UserDefaultsSettingsStoreTests testShowRecents_defaultsTrue]' passed (0.001 seconds).
Test Case '-[KizbaTests.UserDefaultsSettingsStoreTests testShowRecents_roundTrip]' started.
Test Case '-[KizbaTests.UserDefaultsSettingsStoreTests testShowRecents_roundTrip]' passed (0.002 seconds).
Test Suite 'UserDefaultsSettingsStoreTests' passed at 2026-05-24 08:25:56.902.
	 Executed 13 tests, with 0 failures (0 unexpected) in 0.040 (0.047) seconds
Test Suite 'KizbaTests.xctest' failed at 2026-05-24 08:25:56.902.
	 Executed 1293 tests, with 17 tests skipped and 2 failures (0 unexpected) in 48.281 (49.986) seconds
Test Suite 'All tests' failed at 2026-05-24 08:25:56.917.
	 Executed 1293 tests, with 17 tests skipped and 2 failures (0 unexpected) in 48.281 (50.001) seconds
2026-05-24 08:26:15.205 xcodebuild[11537:1068507] [MT] IDETestOperationsObserverDebug: 70.723 elapsed -- Testing started completed.
2026-05-24 08:26:15.205 xcodebuild[11537:1068507] [MT] IDETestOperationsObserverDebug: 0.000 sec, +0.000 sec -- start
2026-05-24 08:26:15.205 xcodebuild[11537:1068507] [MT] IDETestOperationsObserverDebug: 70.723 sec, +70.723 sec -- end

Test session results, code coverage, and logs:
	/Users/kirillsimagin/Library/Developer/Xcode/DerivedData/Kizba-efejvmfzdmoqdoewsmanttogshar/Logs/Test/Test-Kizba-2026.05.24_08-24-43-+0200.xcresult

Failing tests:
	KizbaNightContrastTests.testKizbaNight_onAccent_against_accentMuted_meet_AA()
	KizbaNightContrastTests.testKizbaNight_onAccent_against_accentMuted_meet_AA()

** TEST FAILED **

Testing started


---
Captured by smart-worker at 2026-05-24T06:26:00Z
Command: xcodebuild test -scheme "Kizba" -destination 'platform=macOS'
