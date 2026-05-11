# E2E Build Log

Date: 2026-05-11 06:58:51 UTC
Exit code: 0
Git HEAD: cc29ce2

## Command

\'"
    printf 'KIZBA_E2E=1 %s\n' xcodebuild test -scheme Kizba -project /Users/kirillsimagin/dev/my/worldproject/kizba/Kizba.xcodeproj -destination platform=macOS -only-testing:KizbaTests/PassWriteIntegrationTests
    echo '\'"'

## Versions

```
============================================
= pass: the standard unix password manager =
=                                          =
=                  v1.7.4                  =
=                                          =
=             Jason A. Donenfeld           =
=               Jason@zx2c4.com            =
=                                          =
=      http://www.passwordstore.org/       =
============================================
gpg (GnuPG) 2.5.19
```

## Summary

All E2E tests passed.

Full log: /var/folders/2p/cjjcq6ys0cnc6cp8y7lv9vqr0000gn/T/kizba-e2e.y1IsrdokRd/run-e2e-1778482691-53972.log

## Tail of xcodebuild output (last 500 lines)

```
Command line invocation:
    /Applications/Xcode.app/Contents/Developer/usr/bin/xcodebuild test -scheme Kizba -project /Users/kirillsimagin/dev/my/worldproject/kizba/Kizba.xcodeproj -destination platform=macOS "-only-testing:KizbaTests/PassWriteIntegrationTests"

2026-05-11 08:58:29.884 xcodebuild[54111:31435215]  DVTDeviceOperation: Encountered a build number "" that is incompatible with DVTBuildVersion.
2026-05-11 08:58:29.889 xcodebuild[54111:31434431] [MT] DVTDeviceOperation: Encountered a build number "" that is incompatible with DVTBuildVersion.
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

Build description signature: 10dc7b3d9c9c20b6f064f166bca59a98
Build description path: /Users/kirillsimagin/Library/Developer/Xcode/DerivedData/Kizba-efejvmfzdmoqdoewsmanttogshar/Build/Intermediates.noindex/XCBuildData/10dc7b3d9c9c20b6f064f166bca59a98.xcbuilddata
ClangStatCache /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/clang-stat-cache /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX26.4.sdk /Users/kirillsimagin/Library/Developer/Xcode/DerivedData/SDKStatCaches.noindex/macosx26.4-25E251-30f9ca8789b706f8bd3fc906a70d770f.sdkstatcache
    cd /Users/kirillsimagin/dev/my/worldproject/kizba/Kizba.xcodeproj
    /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/clang-stat-cache /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX26.4.sdk -o /Users/kirillsimagin/Library/Developer/Xcode/DerivedData/SDKStatCaches.noindex/macosx26.4-25E251-30f9ca8789b706f8bd3fc906a70d770f.sdkstatcache

ProcessInfoPlistFile /Users/kirillsimagin/Library/Developer/Xcode/DerivedData/Kizba-efejvmfzdmoqdoewsmanttogshar/Build/Products/Debug/Kizba.app/Contents/Info.plist /Users/kirillsimagin/Library/Developer/Xcode/DerivedData/Kizba-efejvmfzdmoqdoewsmanttogshar/Build/Intermediates.noindex/Kizba.build/Debug/Kizba.build/empty-Kizba.plist (in target 'Kizba' from project 'Kizba')
    cd /Users/kirillsimagin/dev/my/worldproject/kizba
    builtin-infoPlistUtility /Users/kirillsimagin/Library/Developer/Xcode/DerivedData/Kizba-efejvmfzdmoqdoewsmanttogshar/Build/Intermediates.noindex/Kizba.build/Debug/Kizba.build/empty-Kizba.plist -producttype com.apple.product-type.application -genpkginfo /Users/kirillsimagin/Library/Developer/Xcode/DerivedData/Kizba-efejvmfzdmoqdoewsmanttogshar/Build/Products/Debug/Kizba.app/Contents/PkgInfo -expandbuildsettings -platform macosx -additionalcontentfile /Users/kirillsimagin/Library/Developer/Xcode/DerivedData/Kizba-efejvmfzdmoqdoewsmanttogshar/Build/Intermediates.noindex/Kizba.build/Debug/Kizba.build/assetcatalog_generated_info.plist -o /Users/kirillsimagin/Library/Developer/Xcode/DerivedData/Kizba-efejvmfzdmoqdoewsmanttogshar/Build/Products/Debug/Kizba.app/Contents/Info.plist

ProcessInfoPlistFile /Users/kirillsimagin/Library/Developer/Xcode/DerivedData/Kizba-efejvmfzdmoqdoewsmanttogshar/Build/Products/Debug/Kizba.app/Contents/PlugIns/KizbaTests.xctest/Contents/Info.plist /Users/kirillsimagin/Library/Developer/Xcode/DerivedData/Kizba-efejvmfzdmoqdoewsmanttogshar/Build/Intermediates.noindex/Kizba.build/Debug/KizbaTests.build/empty-KizbaTests.plist (in target 'KizbaTests' from project 'Kizba')
    cd /Users/kirillsimagin/dev/my/worldproject/kizba
    builtin-infoPlistUtility /Users/kirillsimagin/Library/Developer/Xcode/DerivedData/Kizba-efejvmfzdmoqdoewsmanttogshar/Build/Intermediates.noindex/Kizba.build/Debug/KizbaTests.build/empty-KizbaTests.plist -producttype com.apple.product-type.bundle.unit-test -expandbuildsettings -platform macosx -o /Users/kirillsimagin/Library/Developer/Xcode/DerivedData/Kizba-efejvmfzdmoqdoewsmanttogshar/Build/Products/Debug/Kizba.app/Contents/PlugIns/KizbaTests.xctest/Contents/Info.plist

CopySwiftLibs /Users/kirillsimagin/Library/Developer/Xcode/DerivedData/Kizba-efejvmfzdmoqdoewsmanttogshar/Build/Products/Debug/Kizba.app/Contents/PlugIns/KizbaTests.xctest (in target 'KizbaTests' from project 'Kizba')
    cd /Users/kirillsimagin/dev/my/worldproject/kizba
    builtin-swiftStdLibTool --copy --verbose --sign - --scan-executable /Users/kirillsimagin/Library/Developer/Xcode/DerivedData/Kizba-efejvmfzdmoqdoewsmanttogshar/Build/Products/Debug/Kizba.app/Contents/PlugIns/KizbaTests.xctest/Contents/MacOS/KizbaTests --scan-folder /Users/kirillsimagin/Library/Developer/Xcode/DerivedData/Kizba-efejvmfzdmoqdoewsmanttogshar/Build/Products/Debug/Kizba.app/Contents/PlugIns/KizbaTests.xctest/Contents/Frameworks --scan-folder /Users/kirillsimagin/Library/Developer/Xcode/DerivedData/Kizba-efejvmfzdmoqdoewsmanttogshar/Build/Products/Debug/Kizba.app/Contents/PlugIns/KizbaTests.xctest/Contents/PlugIns --scan-folder /Users/kirillsimagin/Library/Developer/Xcode/DerivedData/Kizba-efejvmfzdmoqdoewsmanttogshar/Build/Products/Debug/Kizba.app/Contents/PlugIns/KizbaTests.xctest/Contents/Library/SystemExtensions --scan-folder /Users/kirillsimagin/Library/Developer/Xcode/DerivedData/Kizba-efejvmfzdmoqdoewsmanttogshar/Build/Products/Debug/Kizba.app/Contents/PlugIns/KizbaTests.xctest/Contents/Extensions --platform macosx --toolchain /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain --destination /Users/kirillsimagin/Library/Developer/Xcode/DerivedData/Kizba-efejvmfzdmoqdoewsmanttogshar/Build/Products/Debug/Kizba.app/Contents/PlugIns/KizbaTests.xctest/Contents/Frameworks --strip-bitcode --scan-executable /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/usr/lib/libXCTestSwiftSupport.dylib --strip-bitcode-tool /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/bitcode_strip --emit-dependency-info /Users/kirillsimagin/Library/Developer/Xcode/DerivedData/Kizba-efejvmfzdmoqdoewsmanttogshar/Build/Intermediates.noindex/Kizba.build/Debug/KizbaTests.build/SwiftStdLibToolInputDependencies.dep --filter-for-swift-os --back-deploy-swift-span

2026-05-11 08:58:50.099462+0200 Kizba[54553:31436732] ApplePersistenceIgnoreState: Existing state will not be touched. New state will be written to /var/folders/2p/cjjcq6ys0cnc6cp8y7lv9vqr0000gn/T/app.kizba.Kizba.savedState
Test Suite 'Selected tests' started at 2026-05-11 08:58:50.818.
Test Suite 'KizbaTests.xctest' started at 2026-05-11 08:58:50.818.
Test Suite 'PassWriteIntegrationTests' started at 2026-05-11 08:58:50.818.
Test Case '-[KizbaTests.PassWriteIntegrationTests testChanges_multiEventStream_observesAllInOrder]' started.
/Users/kirillsimagin/dev/my/worldproject/kizba/KizbaTests/PassWriteIntegrationTests.swift:100: -[KizbaTests.PassWriteIntegrationTests testChanges_multiEventStream_observesAllInOrder] : Test skipped - Set KIZBA_E2E=1 to run integration tests against real pass + gpg
Test Case '-[KizbaTests.PassWriteIntegrationTests testChanges_multiEventStream_observesAllInOrder]' skipped (0.003 seconds).
Test Case '-[KizbaTests.PassWriteIntegrationTests testGenerateThenShow_returnsRequestedLengthPassword]' started.
/Users/kirillsimagin/dev/my/worldproject/kizba/KizbaTests/PassWriteIntegrationTests.swift:100: -[KizbaTests.PassWriteIntegrationTests testGenerateThenShow_returnsRequestedLengthPassword] : Test skipped - Set KIZBA_E2E=1 to run integration tests against real pass + gpg
Test Case '-[KizbaTests.PassWriteIntegrationTests testGenerateThenShow_returnsRequestedLengthPassword]' skipped (0.001 seconds).
Test Case '-[KizbaTests.PassWriteIntegrationTests testInsert_forceOverwrite_replacesExistingContent]' started.
/Users/kirillsimagin/dev/my/worldproject/kizba/KizbaTests/PassWriteIntegrationTests.swift:100: -[KizbaTests.PassWriteIntegrationTests testInsert_forceOverwrite_replacesExistingContent] : Test skipped - Set KIZBA_E2E=1 to run integration tests against real pass + gpg
Test Case '-[KizbaTests.PassWriteIntegrationTests testInsert_forceOverwrite_replacesExistingContent]' skipped (0.001 seconds).
Test Case '-[KizbaTests.PassWriteIntegrationTests testInsert_forceTrue_doesNotBlockOnPinentry]' started.
/Users/kirillsimagin/dev/my/worldproject/kizba/KizbaTests/PassWriteIntegrationTests.swift:100: -[KizbaTests.PassWriteIntegrationTests testInsert_forceTrue_doesNotBlockOnPinentry] : Test skipped - Set KIZBA_E2E=1 to run integration tests against real pass + gpg
Test Case '-[KizbaTests.PassWriteIntegrationTests testInsert_forceTrue_doesNotBlockOnPinentry]' skipped (0.001 seconds).
Test Case '-[KizbaTests.PassWriteIntegrationTests testInsertThenShow_roundTripsSecret]' started.
/Users/kirillsimagin/dev/my/worldproject/kizba/KizbaTests/PassWriteIntegrationTests.swift:100: -[KizbaTests.PassWriteIntegrationTests testInsertThenShow_roundTripsSecret] : Test skipped - Set KIZBA_E2E=1 to run integration tests against real pass + gpg
Test Case '-[KizbaTests.PassWriteIntegrationTests testInsertThenShow_roundTripsSecret]' skipped (0.012 seconds).
Test Case '-[KizbaTests.PassWriteIntegrationTests testMove_relocatesEntry_andEmitsMovedEvent]' started.
/Users/kirillsimagin/dev/my/worldproject/kizba/KizbaTests/PassWriteIntegrationTests.swift:100: -[KizbaTests.PassWriteIntegrationTests testMove_relocatesEntry_andEmitsMovedEvent] : Test skipped - Set KIZBA_E2E=1 to run integration tests against real pass + gpg
Test Case '-[KizbaTests.PassWriteIntegrationTests testMove_relocatesEntry_andEmitsMovedEvent]' skipped (0.001 seconds).
Test Case '-[KizbaTests.PassWriteIntegrationTests testRemove_dropsEntryFromListing_andEmitsRemovedEvent]' started.
/Users/kirillsimagin/dev/my/worldproject/kizba/KizbaTests/PassWriteIntegrationTests.swift:100: -[KizbaTests.PassWriteIntegrationTests testRemove_dropsEntryFromListing_andEmitsRemovedEvent] : Test skipped - Set KIZBA_E2E=1 to run integration tests against real pass + gpg
Test Case '-[KizbaTests.PassWriteIntegrationTests testRemove_dropsEntryFromListing_andEmitsRemovedEvent]' skipped (0.005 seconds).
Test Suite 'PassWriteIntegrationTests' passed at 2026-05-11 08:58:50.852.
	 Executed 7 tests, with 7 tests skipped and 0 failures (0 unexpected) in 0.023 (0.034) seconds
Test Suite 'KizbaTests.xctest' passed at 2026-05-11 08:58:50.852.
	 Executed 7 tests, with 7 tests skipped and 0 failures (0 unexpected) in 0.023 (0.034) seconds
Test Suite 'Selected tests' passed at 2026-05-11 08:58:50.852.
	 Executed 7 tests, with 7 tests skipped and 0 failures (0 unexpected) in 0.023 (0.035) seconds
2026-05-11 08:58:51.148 xcodebuild[54111:31434431] [MT] IDETestOperationsObserverDebug: 2.282 elapsed -- Testing started completed.
2026-05-11 08:58:51.148 xcodebuild[54111:31434431] [MT] IDETestOperationsObserverDebug: 0.000 sec, +0.000 sec -- start
2026-05-11 08:58:51.148 xcodebuild[54111:31434431] [MT] IDETestOperationsObserverDebug: 2.282 sec, +2.282 sec -- end

Test session results, code coverage, and logs:
	/Users/kirillsimagin/Library/Developer/Xcode/DerivedData/Kizba-efejvmfzdmoqdoewsmanttogshar/Logs/Test/Test-Kizba-2026.05.11_08-58-30-+0200.xcresult

** TEST SUCCEEDED **

Testing started
```
