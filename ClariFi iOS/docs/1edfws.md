== DATE:

    Tuesday, October 14, 2025 at 9:57:26 PM Eastern Daylight Saving Time
    
    2025-10-15T01:57:26Z



== PREVIEW UPDATE ERROR:

    GroupRecordingError
    
    Error encountered during update group #143
    
    ==================================
    
    |  SchemeBuildError: Failed to build the scheme “ClariFi iOS”
    |  
    |  call to main actor-isolated initializer 'init(budgetRepository:budgetCategoryRepository:templateService:context:)' in a synchronous nonisolated context
    |  
    |  Compiling AppDIContainer.swift, AppDIContainer+Registration.swift, CategoryPickerView.swift, DIContainer.swift, DIContainer+Environment.swift, ColorSystem.swift, Decimal+Currency.swift, Typography.swift, View+ErrorAlert.swift, PremiumUpsellView.swift, View+ErrorAlert+Example.swift, AccountSetupData.swift:
    |  Failed frontend command:
    |  /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swift-frontend -frontend -c -filelist /Users/aero/Library/Developer/Xcode/DerivedData/ClariFi_iOS-gmrlhvqnuqrbwdaistjzehzlpfwz/Build/Intermediates.noindex/ClariFi\ iOS.build/Debug-iphonesimulator/ClariFi\ iOS.build/Objects-normal/arm64/sources-135 -primary-file /Users/mayenikhalo/Public/From\ aEroPartition/Dev/ClariFi\ iOS/ClariFi\ iOS/Core/DependencyInjection/AppDIContainer.swift -primary-file /Users/mayenikhalo/Public/From\ aEroPartition/Dev/ClariFi\ iOS/ClariFi\ iOS/Core/DependencyInjection/AppDIContainer+Registration.swift -primary-file /Users/mayenikhalo/Public/From\ aEroPartition/Dev/ClariFi\ iOS/ClariFi\ iOS/Views/Components/CategoryPickerView.swift -primary-file /Users/mayenikhalo/Public/From\ aEroPartition/Dev/ClariFi\ iOS/ClariFi\ iOS/Core/DependencyInjection/DIContainer.swift -primary-file /Users/mayenikhalo/Public/From\ aEroPartition/Dev/ClariFi\ iOS/ClariFi\ iOS/Core/DependencyInjection/DIContainer+Environment.swift -primary-file /Users/mayenikhalo/Public/From\ aEroPartition/Dev/ClariFi\ iOS/ClariFi\ iOS/Core/Extensions/ColorSystem.swift -primary-file /Users/mayenikhalo/Public/From\ aEroPartition/Dev/ClariFi\ iOS/ClariFi\ iOS/Core/Extensions/Decimal+Currency.swift -primary-file /Users/mayenikhalo/Public/From\ aEroPartition/Dev/ClariFi\ iOS/ClariFi\ iOS/Core/Extensions/Typography.swift -primary-file /Users/mayenikhalo/Public/From\ aEroPartition/Dev/ClariFi\ iOS/ClariFi\ iOS/Core/Extensions/View+ErrorAlert.swift -primary-file /Users/mayenikhalo/Public/From\ aEroPartition/Dev/ClariFi\ iOS/ClariFi\ iOS/Views/Components/PremiumUpsellView.swift -primary-file /Users/mayenikhalo/Public/From\ aEroPartition/Dev/ClariFi\ iOS/ClariFi\ iOS/Core/Extensions/View+ErrorAlert+Example.swift -primary-file /Users/mayenikhalo/Public/From\ aEroPartition/Dev/ClariFi\ iOS/ClariFi\ iOS/Models/AccountSetupData.swift -supplementary-output-file-map /Users/aero/Library/Developer/Xcode/DerivedData/ClariFi_iOS-gmrlhvqnuqrbwdaistjzehzlpfwz/Build/Intermediates.noindex/ClariFi\ iOS.build/Debug-iphonesimulator/ClariFi\ iOS.build/Objects-normal/arm64/supplementaryOutputs-1080 -emit-localized-strings -emit-localized-strings-path /Users/aero/Library/Developer/Xcode/DerivedData/ClariFi_iOS-gmrlhvqnuqrbwdaistjzehzlpfwz/Build/Intermediates.noindex/ClariFi\ iOS.build/Debug-iphonesimulator/ClariFi\ iOS.build/Objects-normal/arm64 -target arm64-apple-ios18.5-simulator -module-can-import-version DeveloperToolsSupport 23.0.4 23.0.4 -module-can-import-version SwiftUI 7.0.84.1 7.0.84 -module-can-import-version UIKit 9088.1.113 9088.1.113 -disable-cross-import-overlay-search -swift-module-cross-import AppIntents /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk/System/Library/Frameworks/AppIntents.framework/Modules/AppIntents.swiftcrossimport/SwiftUI.swiftoverlay -swift-module-cross-import AppIntents /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk/System/Library/Frameworks/AppIntents.framework/Modules/AppIntents.swiftcrossimport/UIKit.swiftoverlay -swift-module-cross-import AppIntents /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator26.0.sdk/System/Library/Frameworks/AppIntents.framework/Modules/AppIntents.swiftcrossimport/SwiftUI.swiftoverlay -swift-module-cross-import AppIntents /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator26.0.sdk/System/Library/Frameworks/AppIntents.framework/Modules/AppIntents.swiftcrossimport/UIKit.swiftoverlay -swift-module-cross-import CoreData /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk/System/Library/Frameworks/CoreData.framework/Modules/CoreData.swiftcrossimport/CloudKit.swiftoverlay -swift-module-cross-import CoreData /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator26.0.sdk/System/Library/Frameworks/CoreData.framework/Modules/CoreData.swiftcrossimport/CloudKit.swiftoverlay -swift-module-cross-import PhotosUI /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk/System/Library/Frameworks/PhotosUI.framework/Modules/PhotosUI.swiftcrossimport/SwiftUI.swiftoverlay -swift-module-cross-import PhotosUI /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk/System/Library/Frameworks/PhotosUI.framework/Modules/PhotosUI.swiftcrossimport/WidgetKit.swiftoverlay -swift-module-cross-import PhotosUI /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator26.0.sdk/System/Library/Frameworks/PhotosUI.framework/Modules/PhotosUI.swiftcrossimport/SwiftUI.swiftoverlay -swift-module-cross-import PhotosUI /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator26.0.sdk/System/Library/Frameworks/PhotosUI.framework/Modules/PhotosUI.swiftcrossimport/WidgetKit.swiftoverlay -swift-module-cross-import RelevanceKit /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk/System/Library/Frameworks/RelevanceKit.framework/Modules/RelevanceKit.swiftcrossimport/MapKit.swiftoverlay -swift-module-cross-import RelevanceKit /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator26.0.sdk/System/Library/Frameworks/RelevanceKit.framework/Modules/RelevanceKit.swiftcrossimport/MapKit.swiftoverlay -swift-module-cross-import StoreKit /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk/System/Library/Frameworks/StoreKit.framework/Modules/StoreKit.swiftcrossimport/SwiftUI.swiftoverlay -swift-module-cross-import StoreKit /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator26.0.sdk/System/Library/Frameworks/StoreKit.framework/Modules/StoreKit.swiftcrossimport/SwiftUI.swiftoverlay -load-resolved-plugin /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/usr/lib/swift/host/plugins/libAppIntentsMacros.dylib\#/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/usr/bin/swift-plugin-server\#AppIntentsMacros -load-resolved-plugin /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/usr/lib/swift/host/plugins/libFoundationMacros.dylib\#/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/usr/bin/swift-plugin-server\#FoundationMacros -load-resolved-plugin /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/usr/lib/swift/host/plugins/libObservationMacros.dylib\#/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/usr/bin/swift-plugin-server\#ObservationMacros -load-resolved-plugin /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/usr/lib/swift/host/plugins/libPreviewsMacros.dylib\#/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/usr/bin/swift-plugin-server\#PreviewsMacros -load-resolved-plugin /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/usr/lib/swift/host/plugins/libSwiftMacros.dylib\#/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/usr/bin/swift-plugin-server\#SwiftMacros -load-resolved-plugin /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/usr/lib/swift/host/plugins/libSwiftUIMacros.dylib\#/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/usr/bin/swift-plugin-server\#SwiftUIMacros -disable-implicit-swift-modules -Xcc -fno-implicit-modules -Xcc -fno-implicit-module-maps -explicit-swift-module-map-file /Users/aero/Library/Developer/Xcode/DerivedData/ClariFi_iOS-gmrlhvqnuqrbwdaistjzehzlpfwz/Build/Intermediates.noindex/ClariFi\ iOS.build/Debug-iphonesimulator/ClariFi\ iOS.build/Objects-normal/arm64/ClariFi_iOS-dependencies-134.json -Xllvm -aarch64-use-tbi -enable-objc-interop -sdk /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator26.0.sdk -I /Users/aero/Library/Developer/Xcode/DerivedData/ClariFi_iOS-gmrlhvqnuqrbwdaistjzehzlpfwz/Build/Products/Debug-iphonesimulator -F /Users/aero/Library/Developer/Xcode/DerivedData/ClariFi_iOS-gmrlhvqnuqrbwdaistjzehzlpfwz/Build/Products/Debug-iphonesimulator -no-color-diagnostics -Xcc -fno-color-diagnostics -enable-testing -g -debug-info-format\=dwarf -dwarf-version\=5 -module-cache-path /Users/aero/Library/Developer/Xcode/DerivedData/ClariFi_iOS-gmrlhvqnuqrbwdaistjzehzlpfwz/Build/Intermediates.noindex/SwiftExplicitPrecompiledModules -profile-generate -profile-coverage-mapping -swift-version 5 -enforce-exclusivity\=checked -Onone -D DEBUG -serialize-debugging-options -const-gather-protocols-file /Users/aero/Library/Developer/Xcode/DerivedData/ClariFi_iOS-gmrlhvqnuqrbwdaistjzehzlpfwz/Build/Intermediates.noindex/ClariFi\ iOS.build/Debug-iphonesimulator/ClariFi\ iOS.build/Objects-normal/arm64/ClariFi\ iOS_const_extract_protocols.json -enable-experimental-feature DebugDescriptionMacro -enable-bare-slash-regex -empty-abi-descriptor -validate-clang-modules-once -clang-build-session-file /Users/aero/Library/Developer/Xcode/DerivedData/ModuleCache.noindex/Session.modulevalidation -Xcc -working-directory -Xcc /Users/mayenikhalo/Public/From\ aEroPartition/Dev/ClariFi\ iOS -enable-anonymous-context-mangled-names -file-compilation-dir /Users/mayenikhalo/Public/From\ aEroPartition/Dev/ClariFi\ iOS -Xcc -D_LIBCPP_HARDENING_MODE\=_LIBCPP_HARDENING_MODE_DEBUG -Xcc -ivfsstatcache -Xcc /Users/aero/Library/Developer/Xcode/DerivedData/SDKStatCaches.noindex/iphonesimulator26.0-23A339-26257891a6c027eb51374368541b8346.sdkstatcache -Xcc -I/Users/aero/Library/Developer/Xcode/DerivedData/ClariFi_iOS-gmrlhvqnuqrbwdaistjzehzlpfwz/Build/Intermediates.noindex/ClariFi\ iOS.build/Debug-iphonesimulator/ClariFi\ iOS.build/swift-overrides.hmap -Xcc -iquote -Xcc /Users/aero/Library/Developer/Xcode/DerivedData/ClariFi_iOS-gmrlhvqnuqrbwdaistjzehzlpfwz/Build/Intermediates.noindex/ClariFi\ iOS.build/Debug-iphonesimulator/ClariFi\ iOS.build/ClariFi\ iOS-generated-files.hmap -Xcc -I/Users/aero/Library/Developer/Xcode/DerivedData/ClariFi_iOS-gmrlhvqnuqrbwdaistjzehzlpfwz/Build/Intermediates.noindex/ClariFi\ iOS.build/Debug-iphonesimulator/ClariFi\ iOS.build/ClariFi\ iOS-own-target-headers.hmap -Xcc -I/Users/aero/Library/Developer/Xcode/DerivedData/ClariFi_iOS-gmrlhvqnuqrbwdaistjzehzlpfwz/Build/Intermediates.noindex/ClariFi\ iOS.build/Debug-iphonesimulator/ClariFi\ iOS.build/ClariFi\ iOS-all-target-headers.hmap -Xcc -iquote -Xcc /Users/aero/Library/Developer/Xcode/DerivedData/ClariFi_iOS-gmrlhvqnuqrbwdaistjzehzlpfwz/Build/Intermediates.noindex/ClariFi\ iOS.build/Debug-iphonesimulator/ClariFi\ iOS.build/ClariFi\ iOS-project-headers.hmap -Xcc -I/Users/aero/Library/Developer/Xcode/DerivedData/ClariFi_iOS-gmrlhvqnuqrbwdaistjzehzlpfwz/Build/Products/Debug-iphonesimulator/include -Xcc -I/Users/aero/Library/Developer/Xcode/DerivedData/ClariFi_iOS-gmrlhvqnuqrbwdaistjzehzlpfwz/Build/Intermediates.noindex/ClariFi\ iOS.build/Debug-iphonesimulator/ClariFi\ iOS.build/DerivedSources-normal/arm64 -Xcc -I/Users/aero/Library/Developer/Xcode/DerivedData/ClariFi_iOS-gmrlhvqnuqrbwdaistjzehzlpfwz/Build/Intermediates.noindex/ClariFi\ iOS.build/Debug-iphonesimulator/ClariFi\ iOS.build/DerivedSources/arm64 -Xcc -I/Users/aero/Library/Developer/Xcode/DerivedData/ClariFi_iOS-gmrlhvqnuqrbwdaistjzehzlpfwz/Build/Intermediates.noindex/ClariFi\ iOS.build/Debug-iphonesimulator/ClariFi\ iOS.build/DerivedSources -Xcc -DDEBUG\=1 -no-auto-bridging-header-chaining -module-name ClariFi_iOS -frontend-parseable-output -disable-clang-spi -target-sdk-version 26.0 -target-sdk-name iphonesimulator26.0 -clang-target arm64-apple-ios26.0-simulator -in-process-plugin-server-path /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/lib/swift/host/libSwiftInProcPluginServer.dylib -o /Users/aero/Library/Developer/Xcode/DerivedData/ClariFi_iOS-gmrlhvqnuqrbwdaistjzehzlpfwz/Build/Intermediates.noindex/ClariFi\ iOS.build/Debug-iphonesimulator/ClariFi\ iOS.build/Objects-normal/arm64/AppDIContainer.o -o /Users/aero/Library/Developer/Xcode/DerivedData/ClariFi_iOS-gmrlhvqnuqrbwdaistjzehzlpfwz/Build/Intermediates.noindex/ClariFi\ iOS.build/Debug-iphonesimulator/ClariFi\ iOS.build/Objects-normal/arm64/AppDIContainer+Registration.o -o /Users/aero/Library/Developer/Xcode/DerivedData/ClariFi_iOS-gmrlhvqnuqrbwdaistjzehzlpfwz/Build/Intermediates.noindex/ClariFi\ iOS.build/Debug-iphonesimulator/ClariFi\ iOS.build/Objects-normal/arm64/CategoryPickerView.o -o /Users/aero/Library/Developer/Xcode/DerivedData/ClariFi_iOS-gmrlhvqnuqrbwdaistjzehzlpfwz/Build/Intermediates.noindex/ClariFi\ iOS.build/Debug-iphonesimulator/ClariFi\ iOS.build/Objects-normal/arm64/DIContainer.o -o /Users/aero/Library/Developer/Xcode/DerivedData/ClariFi_iOS-gmrlhvqnuqrbwdaistjzehzlpfwz/Build/Intermediates.noindex/ClariFi\ iOS.build/Debug-iphonesimulator/ClariFi\ iOS.build/Objects-normal/arm64/DIContainer+Environment.o -o /Users/aero/Library/Developer/Xcode/DerivedData/ClariFi_iOS-gmrlhvqnuqrbwdaistjzehzlpfwz/Build/Intermediates.noindex/ClariFi\ iOS.build/Debug-iphonesimulator/ClariFi\ iOS.build/Objects-normal/arm64/ColorSystem.o -o /Users/aero/Library/Developer/Xcode/DerivedData/ClariFi_iOS-gmrlhvqnuqrbwdaistjzehzlpfwz/Build/Intermediates.noindex/ClariFi\ iOS.build/Debug-iphonesimulator/ClariFi\ iOS.build/Objects-normal/arm64/Decimal+Currency.o -o /Users/aero/Library/Developer/Xcode/DerivedData/ClariFi_iOS-gmrlhvqnuqrbwdaistjzehzlpfwz/Build/Intermediates.noindex/ClariFi\ iOS.build/Debug-iphonesimulator/ClariFi\ iOS.build/Objects-normal/arm64/Typography.o -o /Users/aero/Library/Developer/Xcode/DerivedData/ClariFi_iOS-gmrlhvqnuqrbwdaistjzehzlpfwz/Build/Intermediates.noindex/ClariFi\ iOS.build/Debug-iphonesimulator/ClariFi\ iOS.build/Objects-normal/arm64/View+ErrorAlert.o -o /Users/aero/Library/Developer/Xcode/DerivedData/ClariFi_iOS-gmrlhvqnuqrbwdaistjzehzlpfwz/Build/Intermediates.noindex/ClariFi\ iOS.build/Debug-iphonesimulator/ClariFi\ iOS.build/Objects-normal/arm64/PremiumUpsellView.o -o /Users/aero/Library/Developer/Xcode/DerivedData/ClariFi_iOS-gmrlhvqnuqrbwdaistjzehzlpfwz/Build/Intermediates.noindex/ClariFi\ iOS.build/Debug-iphonesimulator/ClariFi\ iOS.build/Objects-normal/arm64/View+ErrorAlert+Example.o -o /Users/aero/Library/Developer/Xcode/DerivedData/ClariFi_iOS-gmrlhvqnuqrbwdaistjzehzlpfwz/Build/Intermediates.noindex/ClariFi\ iOS.build/Debug-iphonesimulator/ClariFi\ iOS.build/Objects-normal/arm64/AccountSetupData.o -index-unit-output-path /ClariFi\ iOS.build/Debug-iphonesimulator/ClariFi\ iOS.build/Objects-normal/arm64/AppDIContainer.o -index-unit-output-path /ClariFi\ iOS.build/Debug-iphonesimulator/ClariFi\ iOS.build/Objects-normal/arm64/AppDIContainer+Registration.o -index-unit-output-path /ClariFi\ iOS.build/Debug-iphonesimulator/ClariFi\ iOS.build/Objects-normal/arm64/CategoryPickerView.o -index-unit-output-path /ClariFi\ iOS.build/Debug-iphonesimulator/ClariFi\ iOS.build/Objects-normal/arm64/DIContainer.o -index-unit-output-path /ClariFi\ iOS.build/Debug-iphonesimulator/ClariFi\ iOS.build/Objects-normal/arm64/DIContainer+Environment.o -index-unit-output-path /ClariFi\ iOS.build/Debug-iphonesimulator/ClariFi\ iOS.build/Objects-normal/arm64/ColorSystem.o -index-unit-output-path /ClariFi\ iOS.build/Debug-iphonesimulator/ClariFi\ iOS.build/Objects-normal/arm64/Decimal+Currency.o -index-unit-output-path /ClariFi\ iOS.build/Debug-iphonesimulator/ClariFi\ iOS.build/Objects-normal/arm64/Typography.o -index-unit-output-path /ClariFi\ iOS.build/Debug-iphonesimulator/ClariFi\ iOS.build/Objects-normal/arm64/View+ErrorAlert.o -index-unit-output-path /ClariFi\ iOS.build/Debug-iphonesimulator/ClariFi\ iOS.build/Objects-normal/arm64/PremiumUpsellView.o -index-unit-output-path /ClariFi\ iOS.build/Debug-iphonesimulator/ClariFi\ iOS.build/Objects-normal/arm64/View+ErrorAlert+Example.o -index-unit-output-path /ClariFi\ iOS.build/Debug-iphonesimulator/ClariFi\ iOS.build/Objects-normal/arm64/AccountSetupData.o -index-store-path /Users/aero/Library/Developer/Xcode/DerivedData/ClariFi_iOS-gmrlhvqnuqrbwdaistjzehzlpfwz/Index.noindex/DataStore -index-system-modules
    |  
    |  
    |  Compile AppDIContainer+Registration.swift (arm64):
    |  /Users/mayenikhalo/Public/From aEroPartition/Dev/ClariFi iOS/ClariFi iOS/Core/DependencyInjection/AppDIContainer+Registration.swift:116:50: warning: use of protocol 'TransactionRepository' as a type must be written 'any TransactionRepository'; this will be an error in a future Swift language mode
    |                  transactionRepository: c.resolve(TransactionRepository.self),
    |                                                   ^~~~~~~~~~~~~~~~~~~~~
    |                                                   (any TransactionRepository)
    |  /Users/mayenikhalo/Public/From aEroPartition/Dev/ClariFi iOS/ClariFi iOS/Core/DependencyInjection/AppDIContainer+Registration.swift:130:50: warning: use of protocol 'TransactionRepository' as a type must be written 'any TransactionRepository'; this will be an error in a future Swift language mode
    |                  transactionRepository: c.resolve(TransactionRepository.self),
    |                                                   ^~~~~~~~~~~~~~~~~~~~~
    |                                                   (any TransactionRepository)
    |  /Users/mayenikhalo/Public/From aEroPartition/Dev/ClariFi iOS/ClariFi iOS/Core/DependencyInjection/AppDIContainer+Registration.swift:145:45: warning: use of protocol 'BudgetRepository' as a type must be written 'any BudgetRepository'; this will be an error in a future Swift language mode
    |                  budgetRepository: c.resolve(BudgetRepository.self),
    |                                              ^~~~~~~~~~~~~~~~
    |                                              (any BudgetRepository)
    |  /Users/mayenikhalo/Public/From aEroPartition/Dev/ClariFi iOS/ClariFi iOS/Core/DependencyInjection/AppDIContainer+Registration.swift:146:53: warning: use of protocol 'BudgetCategoryRepository' as a type must be written 'any BudgetCategoryRepository'; this will be an error in a future Swift language mode
    |                  budgetCategoryRepository: c.resolve(BudgetCategoryRepository.self),
    |                                                      ^~~~~~~~~~~~~~~~~~~~~~~~
    |                                                      (any BudgetCategoryRepository)
    |  /Users/mayenikhalo/Public/From aEroPartition/Dev/ClariFi iOS/ClariFi iOS/Core/DependencyInjection/AppDIContainer+Registration.swift:147:50: warning: use of protocol 'TransactionRepository' as a type must be written 'any TransactionRepository'; this will be an error in a future Swift language mode
    |                  transactionRepository: c.resolve(TransactionRepository.self),
    |                                                   ^~~~~~~~~~~~~~~~~~~~~
    |                                                   (any TransactionRepository)
    |  /Users/mayenikhalo/Public/From aEroPartition/Dev/ClariFi iOS/ClariFi iOS/Core/DependencyInjection/AppDIContainer+Registration.swift:158:48: warning: use of protocol 'RecurringTransactionRepository' as a type must be written 'any RecurringTransactionRepository'; this will be an error in a future Swift language mode
    |                  recurringRepository: c.resolve(RecurringTransactionRepository.self),
    |                                                 ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    |                                                 (any RecurringTransactionRepository)
    |  /Users/mayenikhalo/Public/From aEroPartition/Dev/ClariFi iOS/ClariFi iOS/Core/DependencyInjection/AppDIContainer+Registration.swift:159:50: warning: use of protocol 'TransactionRepository' as a type must be written 'any TransactionRepository'; this will be an error in a future Swift language mode
    |                  transactionRepository: c.resolve(TransactionRepository.self),
    |                                                   ^~~~~~~~~~~~~~~~~~~~~
    |                                                   (any TransactionRepository)
    |  /Users/mayenikhalo/Public/From aEroPartition/Dev/ClariFi iOS/ClariFi iOS/Core/DependencyInjection/AppDIContainer+Registration.swift:183:45: warning: use of protocol 'BudgetRepository' as a type must be written 'any BudgetRepository'; this will be an error in a future Swift language mode
    |                  budgetRepository: c.resolve(BudgetRepository.self),
    |                                              ^~~~~~~~~~~~~~~~
    |                                              (any BudgetRepository)
    |  /Users/mayenikhalo/Public/From aEroPartition/Dev/ClariFi iOS/ClariFi iOS/Core/DependencyInjection/AppDIContainer+Registration.swift:184:53: warning: use of protocol 'BudgetCategoryRepository' as a type must be written 'any BudgetCategoryRepository'; this will be an error in a future Swift language mode
    |                  budgetCategoryRepository: c.resolve(BudgetCategoryRepository.self),
    |                                                      ^~~~~~~~~~~~~~~~~~~~~~~~
    |                                                      (any BudgetCategoryRepository)
    |  /Users/mayenikhalo/Public/From aEroPartition/Dev/ClariFi iOS/ClariFi iOS/Core/DependencyInjection/AppDIContainer+Registration.swift:29:37: warning: use of protocol 'TransactionRepository' as a type must be written 'any TransactionRepository'; this will be an error in a future Swift language mode
    |          container.registerSingleton(TransactionRepository.self) { _ in
    |                                      ^~~~~~~~~~~~~~~~~~~~~
    |                                      (any TransactionRepository)
    |  /Users/mayenikhalo/Public/From aEroPartition/Dev/ClariFi iOS/ClariFi iOS/Core/DependencyInjection/AppDIContainer+Registration.swift:33:37: warning: use of protocol 'AccountRepository' as a type must be written 'any AccountRepository'; this will be an error in a future Swift language mode
    |          container.registerSingleton(AccountRepository.self) { _ in
    |                                      ^~~~~~~~~~~~~~~~~
    |                                      (any AccountRepository)
    |  /Users/mayenikhalo/Public/From aEroPartition/Dev/ClariFi iOS/ClariFi iOS/Core/DependencyInjection/AppDIContainer+Registration.swift:37:37: warning: use of protocol 'BudgetRepository' as a type must be written 'any BudgetRepository'; this will be an error in a future Swift language mode
    |          container.registerSingleton(BudgetRepository.self) { _ in
    |                                      ^~~~~~~~~~~~~~~~
    |                                      (any BudgetRepository)
    |  /Users/mayenikhalo/Public/From aEroPartition/Dev/ClariFi iOS/ClariFi iOS/Core/DependencyInjection/AppDIContainer+Registration.swift:41:37: warning: use of protocol 'BudgetCategoryRepository' as a type must be written 'any BudgetCategoryRepository'; this will be an error in a future Swift language mode
    |          container.registerSingleton(BudgetCategoryRepository.self) { _ in
    |                                      ^~~~~~~~~~~~~~~~~~~~~~~~
    |                                      (any BudgetCategoryRepository)
    |  /Users/mayenikhalo/Public/From aEroPartition/Dev/ClariFi iOS/ClariFi iOS/Core/DependencyInjection/AppDIContainer+Registration.swift:45:37: warning: use of protocol 'StatementRepository' as a type must be written 'any StatementRepository'; this will be an error in a future Swift language mode
    |          container.registerSingleton(StatementRepository.self) { _ in
    |                                      ^~~~~~~~~~~~~~~~~~~
    |                                      (any StatementRepository)
    |  /Users/mayenikhalo/Public/From aEroPartition/Dev/ClariFi iOS/ClariFi iOS/Core/DependencyInjection/AppDIContainer+Registration.swift:49:37: warning: use of protocol 'RecurringTransactionRepository' as a type must be written 'any RecurringTransactionRepository'; this will be an error in a future Swift language mode
    |          container.registerSingleton(RecurringTransactionRepository.self) { _ in
    |                                      ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    |                                      (any RecurringTransactionRepository)
    |  /Users/mayenikhalo/Public/From aEroPartition/Dev/ClariFi iOS/ClariFi iOS/Core/DependencyInjection/AppDIContainer+Registration.swift:182:13: error: call to main actor-isolated initializer 'init(budgetRepository:budgetCategoryRepository:templateService:context:)' in a synchronous nonisolated context
    |              BudgetCreationViewModel(
    |              ^
    |  /Users/mayenikhalo/Public/From aEroPartition/Dev/ClariFi iOS/ClariFi iOS/ViewModels/BudgetCreationViewModel.swift:52:5: note: calls to initializer 'init(budgetRepository:budgetCategoryRepository:templateService:context:)' from outside of its actor context are implicitly asynchronous
    |      init(
    |      ^
    |  /Users/mayenikhalo/Public/From aEroPartition/Dev/ClariFi iOS/ClariFi iOS/ViewModels/BudgetCreationViewModel.swift:52:5: note: main actor isolation inferred from inheritance from class 'BaseViewModel'
    |      init(
    |      ^
    |  /Users/mayenikhalo/Public/From aEroPartition/Dev/ClariFi iOS/ClariFi iOS/Core/DependencyInjection/AppDIContainer+Registration.swift:281:50: warning: use of protocol 'TransactionRepository' as a type must be written 'any TransactionRepository'; this will be an error in a future Swift language mode
    |                  transactionRepository: c.resolve(TransactionRepository.self),
    |                                                   ^~~~~~~~~~~~~~~~~~~~~
    |                                                   (any TransactionRepository)
    |  /Users/mayenikhalo/Public/From aEroPartition/Dev/ClariFi iOS/ClariFi iOS/Core/DependencyInjection/AppDIContainer+Registration.swift:295:50: warning: use of protocol 'TransactionRepository' as a type must be written 'any TransactionRepository'; this will be an error in a future Swift language mode
    |                  transactionRepository: c.resolve(TransactionRepository.self),
    |                                                   ^~~~~~~~~~~~~~~~~~~~~
    |                                                   (any TransactionRepository)
    |  /Users/mayenikhalo/Public/From aEroPartition/Dev/ClariFi iOS/ClariFi iOS/Core/DependencyInjection/AppDIContainer+Registration.swift:310:45: warning: use of protocol 'BudgetRepository' as a type must be written 'any BudgetRepository'; this will be an error in a future Swift language mode
    |                  budgetRepository: c.resolve(BudgetRepository.self),
    |                                              ^~~~~~~~~~~~~~~~
    |                                              (any BudgetRepository)
    |  /Users/mayenikhalo/Public/From aEroPartition/Dev/ClariFi iOS/ClariFi iOS/Core/DependencyInjection/AppDIContainer+Registration.swift:311:53: warning: use of protocol 'BudgetCategoryRepository' as a type must be written 'any BudgetCategoryRepository'; this will be an error in a future Swift language mode
    |                  budgetCategoryRepository: c.resolve(BudgetCategoryRepository.self),
    |                                                      ^~~~~~~~~~~~~~~~~~~~~~~~
    |                                                      (any BudgetCategoryRepository)
    |  /Users/mayenikhalo/Public/From aEroPartition/Dev/ClariFi iOS/ClariFi iOS/Core/DependencyInjection/AppDIContainer+Registration.swift:312:50: warning: use of protocol 'TransactionRepository' as a type must be written 'any TransactionRepository'; this will be an error in a future Swift language mode
    |                  transactionRepository: c.resolve(TransactionRepository.self),
    |                                                   ^~~~~~~~~~~~~~~~~~~~~
    |                                                   (any TransactionRepository)
    |  /Users/mayenikhalo/Public/From aEroPartition/Dev/ClariFi iOS/ClariFi iOS/Core/DependencyInjection/AppDIContainer+Registration.swift:323:48: warning: use of protocol 'RecurringTransactionRepository' as a type must be written 'any RecurringTransactionRepository'; this will be an error in a future Swift language mode
    |                  recurringRepository: c.resolve(RecurringTransactionRepository.self),
    |                                                 ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    |                                                 (any RecurringTransactionRepository)
    |  /Users/mayenikhalo/Public/From aEroPartition/Dev/ClariFi iOS/ClariFi iOS/Core/DependencyInjection/AppDIContainer+Registration.swift:324:50: warning: use of protocol 'TransactionRepository' as a type must be written 'any TransactionRepository'; this will be an error in a future Swift language mode
    |                  transactionRepository: c.resolve(TransactionRepository.self),
    |                                                   ^~~~~~~~~~~~~~~~~~~~~
    |                                                   (any TransactionRepository)
    |  /Users/mayenikhalo/Public/From aEroPartition/Dev/ClariFi iOS/ClariFi iOS/Core/DependencyInjection/AppDIContainer+Registration.swift:346:45: warning: use of protocol 'BudgetRepository' as a type must be written 'any BudgetRepository'; this will be an error in a future Swift language mode
    |                  budgetRepository: c.resolve(BudgetRepository.self),
    |                                              ^~~~~~~~~~~~~~~~
    |                                              (any BudgetRepository)
    |  /Users/mayenikhalo/Public/From aEroPartition/Dev/ClariFi iOS/ClariFi iOS/Core/DependencyInjection/AppDIContainer+Registration.swift:347:53: warning: use of protocol 'BudgetCategoryRepository' as a type must be written 'any BudgetCategoryRepository'; this will be an error in a future Swift language mode
    |                  budgetCategoryRepository: c.resolve(BudgetCategoryRepository.self),
    |                                                      ^~~~~~~~~~~~~~~~~~~~~~~~
    |                                                      (any BudgetCategoryRepository)
    |  /Users/mayenikhalo/Public/From aEroPartition/Dev/ClariFi iOS/ClariFi iOS/Core/DependencyInjection/AppDIContainer+Registration.swift:205:37: warning: use of protocol 'TransactionRepository' as a type must be written 'any TransactionRepository'; this will be an error in a future Swift language mode
    |          container.registerSingleton(TransactionRepository.self) { _ in
    |                                      ^~~~~~~~~~~~~~~~~~~~~
    |                                      (any TransactionRepository)
    |  /Users/mayenikhalo/Public/From aEroPartition/Dev/ClariFi iOS/ClariFi iOS/Core/DependencyInjection/AppDIContainer+Registration.swift:209:37: warning: use of protocol 'AccountRepository' as a type must be written 'any AccountRepository'; this will be an error in a future Swift language mode
    |          container.registerSingleton(AccountRepository.self) { _ in
    |                                      ^~~~~~~~~~~~~~~~~
    |                                      (any AccountRepository)
    |  /Users/mayenikhalo/Public/From aEroPartition/Dev/ClariFi iOS/ClariFi iOS/Core/DependencyInjection/AppDIContainer+Registration.swift:213:37: warning: use of protocol 'BudgetRepository' as a type must be written 'any BudgetRepository'; this will be an error in a future Swift language mode
    |          container.registerSingleton(BudgetRepository.self) { _ in
    |                                      ^~~~~~~~~~~~~~~~
    |                                      (any BudgetRepository)
    |  /Users/mayenikhalo/Public/From aEroPartition/Dev/ClariFi iOS/ClariFi iOS/Core/DependencyInjection/AppDIContainer+Registration.swift:217:37: warning: use of protocol 'BudgetCategoryRepository' as a type must be written 'any BudgetCategoryRepository'; this will be an error in a future Swift language mode
    |          container.registerSingleton(BudgetCategoryRepository.self) { _ in
    |                                      ^~~~~~~~~~~~~~~~~~~~~~~~
    |                                      (any BudgetCategoryRepository)
    |  /Users/mayenikhalo/Public/From aEroPartition/Dev/ClariFi iOS/ClariFi iOS/Core/DependencyInjection/AppDIContainer+Registration.swift:221:37: warning: use of protocol 'StatementRepository' as a type must be written 'any StatementRepository'; this will be an error in a future Swift language mode
    |          container.registerSingleton(StatementRepository.self) { _ in
    |                                      ^~~~~~~~~~~~~~~~~~~
    |                                      (any StatementRepository)
    |  /Users/mayenikhalo/Public/From aEroPartition/Dev/ClariFi iOS/ClariFi iOS/Core/DependencyInjection/AppDIContainer+Registration.swift:225:37: warning: use of protocol 'RecurringTransactionRepository' as a type must be written 'any RecurringTransactionRepository'; this will be an error in a future Swift language mode
    |          container.registerSingleton(RecurringTransactionRepository.self) { _ in
    |                                      ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    |                                      (any RecurringTransactionRepository)
    |  



== PREVIEW UPDATE ERROR:

    GroupRecordingError
    
    Error encountered during update group #143
    
    ==================================
    
    |  SchemeBuildError: Failed to build the scheme “ClariFi iOS”
    |  
    |  call to main actor-isolated initializer 'init(budgetRepository:budgetCategoryRepository:templateService:context:)' in a synchronous nonisolated context
    |  
    |  Compiling AppDIContainer.swift, AppDIContainer+Registration.swift, CategoryPickerView.swift, DIContainer.swift, DIContainer+Environment.swift, ColorSystem.swift, Decimal+Currency.swift, Typography.swift, View+ErrorAlert.swift, PremiumUpsellView.swift, View+ErrorAlert+Example.swift, AccountSetupData.swift:
    |  Failed frontend command:
    |  /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swift-frontend -frontend -c -filelist /Users/aero/Library/Developer/Xcode/DerivedData/ClariFi_iOS-gmrlhvqnuqrbwdaistjzehzlpfwz/Build/Intermediates.noindex/ClariFi\ iOS.build/Debug-iphonesimulator/ClariFi\ iOS.build/Objects-normal/arm64/sources-135 -primary-file /Users/mayenikhalo/Public/From\ aEroPartition/Dev/ClariFi\ iOS/ClariFi\ iOS/Core/DependencyInjection/AppDIContainer.swift -primary-file /Users/mayenikhalo/Public/From\ aEroPartition/Dev/ClariFi\ iOS/ClariFi\ iOS/Core/DependencyInjection/AppDIContainer+Registration.swift -primary-file /Users/mayenikhalo/Public/From\ aEroPartition/Dev/ClariFi\ iOS/ClariFi\ iOS/Views/Components/CategoryPickerView.swift -primary-file /Users/mayenikhalo/Public/From\ aEroPartition/Dev/ClariFi\ iOS/ClariFi\ iOS/Core/DependencyInjection/DIContainer.swift -primary-file /Users/mayenikhalo/Public/From\ aEroPartition/Dev/ClariFi\ iOS/ClariFi\ iOS/Core/DependencyInjection/DIContainer+Environment.swift -primary-file /Users/mayenikhalo/Public/From\ aEroPartition/Dev/ClariFi\ iOS/ClariFi\ iOS/Core/Extensions/ColorSystem.swift -primary-file /Users/mayenikhalo/Public/From\ aEroPartition/Dev/ClariFi\ iOS/ClariFi\ iOS/Core/Extensions/Decimal+Currency.swift -primary-file /Users/mayenikhalo/Public/From\ aEroPartition/Dev/ClariFi\ iOS/ClariFi\ iOS/Core/Extensions/Typography.swift -primary-file /Users/mayenikhalo/Public/From\ aEroPartition/Dev/ClariFi\ iOS/ClariFi\ iOS/Core/Extensions/View+ErrorAlert.swift -primary-file /Users/mayenikhalo/Public/From\ aEroPartition/Dev/ClariFi\ iOS/ClariFi\ iOS/Views/Components/PremiumUpsellView.swift -primary-file /Users/mayenikhalo/Public/From\ aEroPartition/Dev/ClariFi\ iOS/ClariFi\ iOS/Core/Extensions/View+ErrorAlert+Example.swift -primary-file /Users/mayenikhalo/Public/From\ aEroPartition/Dev/ClariFi\ iOS/ClariFi\ iOS/Models/AccountSetupData.swift -supplementary-output-file-map /Users/aero/Library/Developer/Xcode/DerivedData/ClariFi_iOS-gmrlhvqnuqrbwdaistjzehzlpfwz/Build/Intermediates.noindex/ClariFi\ iOS.build/Debug-iphonesimulator/ClariFi\ iOS.build/Objects-normal/arm64/supplementaryOutputs-1080 -emit-localized-strings -emit-localized-strings-path /Users/aero/Library/Developer/Xcode/DerivedData/ClariFi_iOS-gmrlhvqnuqrbwdaistjzehzlpfwz/Build/Intermediates.noindex/ClariFi\ iOS.build/Debug-iphonesimulator/ClariFi\ iOS.build/Objects-normal/arm64 -target arm64-apple-ios18.5-simulator -module-can-import-version DeveloperToolsSupport 23.0.4 23.0.4 -module-can-import-version SwiftUI 7.0.84.1 7.0.84 -module-can-import-version UIKit 9088.1.113 9088.1.113 -disable-cross-import-overlay-search -swift-module-cross-import AppIntents /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk/System/Library/Frameworks/AppIntents.framework/Modules/AppIntents.swiftcrossimport/SwiftUI.swiftoverlay -swift-module-cross-import AppIntents /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk/System/Library/Frameworks/AppIntents.framework/Modules/AppIntents.swiftcrossimport/UIKit.swiftoverlay -swift-module-cross-import AppIntents /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator26.0.sdk/System/Library/Frameworks/AppIntents.framework/Modules/AppIntents.swiftcrossimport/SwiftUI.swiftoverlay -swift-module-cross-import AppIntents /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator26.0.sdk/System/Library/Frameworks/AppIntents.framework/Modules/AppIntents.swiftcrossimport/UIKit.swiftoverlay -swift-module-cross-import CoreData /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk/System/Library/Frameworks/CoreData.framework/Modules/CoreData.swiftcrossimport/CloudKit.swiftoverlay -swift-module-cross-import CoreData /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator26.0.sdk/System/Library/Frameworks/CoreData.framework/Modules/CoreData.swiftcrossimport/CloudKit.swiftoverlay -swift-module-cross-import PhotosUI /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk/System/Library/Frameworks/PhotosUI.framework/Modules/PhotosUI.swiftcrossimport/SwiftUI.swiftoverlay -swift-module-cross-import PhotosUI /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk/System/Library/Frameworks/PhotosUI.framework/Modules/PhotosUI.swiftcrossimport/WidgetKit.swiftoverlay -swift-module-cross-import PhotosUI /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator26.0.sdk/System/Library/Frameworks/PhotosUI.framework/Modules/PhotosUI.swiftcrossimport/SwiftUI.swiftoverlay -swift-module-cross-import PhotosUI /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator26.0.sdk/System/Library/Frameworks/PhotosUI.framework/Modules/PhotosUI.swiftcrossimport/WidgetKit.swiftoverlay -swift-module-cross-import RelevanceKit /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk/System/Library/Frameworks/RelevanceKit.framework/Modules/RelevanceKit.swiftcrossimport/MapKit.swiftoverlay -swift-module-cross-import RelevanceKit /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator26.0.sdk/System/Library/Frameworks/RelevanceKit.framework/Modules/RelevanceKit.swiftcrossimport/MapKit.swiftoverlay -swift-module-cross-import StoreKit /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk/System/Library/Frameworks/StoreKit.framework/Modules/StoreKit.swiftcrossimport/SwiftUI.swiftoverlay -swift-module-cross-import StoreKit /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator26.0.sdk/System/Library/Frameworks/StoreKit.framework/Modules/StoreKit.swiftcrossimport/SwiftUI.swiftoverlay -load-resolved-plugin /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/usr/lib/swift/host/plugins/libAppIntentsMacros.dylib\#/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/usr/bin/swift-plugin-server\#AppIntentsMacros -load-resolved-plugin /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/usr/lib/swift/host/plugins/libFoundationMacros.dylib\#/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/usr/bin/swift-plugin-server\#FoundationMacros -load-resolved-plugin /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/usr/lib/swift/host/plugins/libObservationMacros.dylib\#/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/usr/bin/swift-plugin-server\#ObservationMacros -load-resolved-plugin /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/usr/lib/swift/host/plugins/libPreviewsMacros.dylib\#/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/usr/bin/swift-plugin-server\#PreviewsMacros -load-resolved-plugin /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/usr/lib/swift/host/plugins/libSwiftMacros.dylib\#/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/usr/bin/swift-plugin-server\#SwiftMacros -load-resolved-plugin /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/usr/lib/swift/host/plugins/libSwiftUIMacros.dylib\#/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/usr/bin/swift-plugin-server\#SwiftUIMacros -disable-implicit-swift-modules -Xcc -fno-implicit-modules -Xcc -fno-implicit-module-maps -explicit-swift-module-map-file /Users/aero/Library/Developer/Xcode/DerivedData/ClariFi_iOS-gmrlhvqnuqrbwdaistjzehzlpfwz/Build/Intermediates.noindex/ClariFi\ iOS.build/Debug-iphonesimulator/ClariFi\ iOS.build/Objects-normal/arm64/ClariFi_iOS-dependencies-134.json -Xllvm -aarch64-use-tbi -enable-objc-interop -sdk /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator26.0.sdk -I /Users/aero/Library/Developer/Xcode/DerivedData/ClariFi_iOS-gmrlhvqnuqrbwdaistjzehzlpfwz/Build/Products/Debug-iphonesimulator -F /Users/aero/Library/Developer/Xcode/DerivedData/ClariFi_iOS-gmrlhvqnuqrbwdaistjzehzlpfwz/Build/Products/Debug-iphonesimulator -no-color-diagnostics -Xcc -fno-color-diagnostics -enable-testing -g -debug-info-format\=dwarf -dwarf-version\=5 -module-cache-path /Users/aero/Library/Developer/Xcode/DerivedData/ClariFi_iOS-gmrlhvqnuqrbwdaistjzehzlpfwz/Build/Intermediates.noindex/SwiftExplicitPrecompiledModules -profile-generate -profile-coverage-mapping -swift-version 5 -enforce-exclusivity\=checked -Onone -D DEBUG -serialize-debugging-options -const-gather-protocols-file /Users/aero/Library/Developer/Xcode/DerivedData/ClariFi_iOS-gmrlhvqnuqrbwdaistjzehzlpfwz/Build/Intermediates.noindex/ClariFi\ iOS.build/Debug-iphonesimulator/ClariFi\ iOS.build/Objects-normal/arm64/ClariFi\ iOS_const_extract_protocols.json -enable-experimental-feature DebugDescriptionMacro -enable-bare-slash-regex -empty-abi-descriptor -validate-clang-modules-once -clang-build-session-file /Users/aero/Library/Developer/Xcode/DerivedData/ModuleCache.noindex/Session.modulevalidation -Xcc -working-directory -Xcc /Users/mayenikhalo/Public/From\ aEroPartition/Dev/ClariFi\ iOS -enable-anonymous-context-mangled-names -file-compilation-dir /Users/mayenikhalo/Public/From\ aEroPartition/Dev/ClariFi\ iOS -Xcc -D_LIBCPP_HARDENING_MODE\=_LIBCPP_HARDENING_MODE_DEBUG -Xcc -ivfsstatcache -Xcc /Users/aero/Library/Developer/Xcode/DerivedData/SDKStatCaches.noindex/iphonesimulator26.0-23A339-26257891a6c027eb51374368541b8346.sdkstatcache -Xcc -I/Users/aero/Library/Developer/Xcode/DerivedData/ClariFi_iOS-gmrlhvqnuqrbwdaistjzehzlpfwz/Build/Intermediates.noindex/ClariFi\ iOS.build/Debug-iphonesimulator/ClariFi\ iOS.build/swift-overrides.hmap -Xcc -iquote -Xcc /Users/aero/Library/Developer/Xcode/DerivedData/ClariFi_iOS-gmrlhvqnuqrbwdaistjzehzlpfwz/Build/Intermediates.noindex/ClariFi\ iOS.build/Debug-iphonesimulator/ClariFi\ iOS.build/ClariFi\ iOS-generated-files.hmap -Xcc -I/Users/aero/Library/Developer/Xcode/DerivedData/ClariFi_iOS-gmrlhvqnuqrbwdaistjzehzlpfwz/Build/Intermediates.noindex/ClariFi\ iOS.build/Debug-iphonesimulator/ClariFi\ iOS.build/ClariFi\ iOS-own-target-headers.hmap -Xcc -I/Users/aero/Library/Developer/Xcode/DerivedData/ClariFi_iOS-gmrlhvqnuqrbwdaistjzehzlpfwz/Build/Intermediates.noindex/ClariFi\ iOS.build/Debug-iphonesimulator/ClariFi\ iOS.build/ClariFi\ iOS-all-target-headers.hmap -Xcc -iquote -Xcc /Users/aero/Library/Developer/Xcode/DerivedData/ClariFi_iOS-gmrlhvqnuqrbwdaistjzehzlpfwz/Build/Intermediates.noindex/ClariFi\ iOS.build/Debug-iphonesimulator/ClariFi\ iOS.build/ClariFi\ iOS-project-headers.hmap -Xcc -I/Users/aero/Library/Developer/Xcode/DerivedData/ClariFi_iOS-gmrlhvqnuqrbwdaistjzehzlpfwz/Build/Products/Debug-iphonesimulator/include -Xcc -I/Users/aero/Library/Developer/Xcode/DerivedData/ClariFi_iOS-gmrlhvqnuqrbwdaistjzehzlpfwz/Build/Intermediates.noindex/ClariFi\ iOS.build/Debug-iphonesimulator/ClariFi\ iOS.build/DerivedSources-normal/arm64 -Xcc -I/Users/aero/Library/Developer/Xcode/DerivedData/ClariFi_iOS-gmrlhvqnuqrbwdaistjzehzlpfwz/Build/Intermediates.noindex/ClariFi\ iOS.build/Debug-iphonesimulator/ClariFi\ iOS.build/DerivedSources/arm64 -Xcc -I/Users/aero/Library/Developer/Xcode/DerivedData/ClariFi_iOS-gmrlhvqnuqrbwdaistjzehzlpfwz/Build/Intermediates.noindex/ClariFi\ iOS.build/Debug-iphonesimulator/ClariFi\ iOS.build/DerivedSources -Xcc -DDEBUG\=1 -no-auto-bridging-header-chaining -module-name ClariFi_iOS -frontend-parseable-output -disable-clang-spi -target-sdk-version 26.0 -target-sdk-name iphonesimulator26.0 -clang-target arm64-apple-ios26.0-simulator -in-process-plugin-server-path /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/lib/swift/host/libSwiftInProcPluginServer.dylib -o /Users/aero/Library/Developer/Xcode/DerivedData/ClariFi_iOS-gmrlhvqnuqrbwdaistjzehzlpfwz/Build/Intermediates.noindex/ClariFi\ iOS.build/Debug-iphonesimulator/ClariFi\ iOS.build/Objects-normal/arm64/AppDIContainer.o -o /Users/aero/Library/Developer/Xcode/DerivedData/ClariFi_iOS-gmrlhvqnuqrbwdaistjzehzlpfwz/Build/Intermediates.noindex/ClariFi\ iOS.build/Debug-iphonesimulator/ClariFi\ iOS.build/Objects-normal/arm64/AppDIContainer+Registration.o -o /Users/aero/Library/Developer/Xcode/DerivedData/ClariFi_iOS-gmrlhvqnuqrbwdaistjzehzlpfwz/Build/Intermediates.noindex/ClariFi\ iOS.build/Debug-iphonesimulator/ClariFi\ iOS.build/Objects-normal/arm64/CategoryPickerView.o -o /Users/aero/Library/Developer/Xcode/DerivedData/ClariFi_iOS-gmrlhvqnuqrbwdaistjzehzlpfwz/Build/Intermediates.noindex/ClariFi\ iOS.build/Debug-iphonesimulator/ClariFi\ iOS.build/Objects-normal/arm64/DIContainer.o -o /Users/aero/Library/Developer/Xcode/DerivedData/ClariFi_iOS-gmrlhvqnuqrbwdaistjzehzlpfwz/Build/Intermediates.noindex/ClariFi\ iOS.build/Debug-iphonesimulator/ClariFi\ iOS.build/Objects-normal/arm64/DIContainer+Environment.o -o /Users/aero/Library/Developer/Xcode/DerivedData/ClariFi_iOS-gmrlhvqnuqrbwdaistjzehzlpfwz/Build/Intermediates.noindex/ClariFi\ iOS.build/Debug-iphonesimulator/ClariFi\ iOS.build/Objects-normal/arm64/ColorSystem.o -o /Users/aero/Library/Developer/Xcode/DerivedData/ClariFi_iOS-gmrlhvqnuqrbwdaistjzehzlpfwz/Build/Intermediates.noindex/ClariFi\ iOS.build/Debug-iphonesimulator/ClariFi\ iOS.build/Objects-normal/arm64/Decimal+Currency.o -o /Users/aero/Library/Developer/Xcode/DerivedData/ClariFi_iOS-gmrlhvqnuqrbwdaistjzehzlpfwz/Build/Intermediates.noindex/ClariFi\ iOS.build/Debug-iphonesimulator/ClariFi\ iOS.build/Objects-normal/arm64/Typography.o -o /Users/aero/Library/Developer/Xcode/DerivedData/ClariFi_iOS-gmrlhvqnuqrbwdaistjzehzlpfwz/Build/Intermediates.noindex/ClariFi\ iOS.build/Debug-iphonesimulator/ClariFi\ iOS.build/Objects-normal/arm64/View+ErrorAlert.o -o /Users/aero/Library/Developer/Xcode/DerivedData/ClariFi_iOS-gmrlhvqnuqrbwdaistjzehzlpfwz/Build/Intermediates.noindex/ClariFi\ iOS.build/Debug-iphonesimulator/ClariFi\ iOS.build/Objects-normal/arm64/PremiumUpsellView.o -o /Users/aero/Library/Developer/Xcode/DerivedData/ClariFi_iOS-gmrlhvqnuqrbwdaistjzehzlpfwz/Build/Intermediates.noindex/ClariFi\ iOS.build/Debug-iphonesimulator/ClariFi\ iOS.build/Objects-normal/arm64/View+ErrorAlert+Example.o -o /Users/aero/Library/Developer/Xcode/DerivedData/ClariFi_iOS-gmrlhvqnuqrbwdaistjzehzlpfwz/Build/Intermediates.noindex/ClariFi\ iOS.build/Debug-iphonesimulator/ClariFi\ iOS.build/Objects-normal/arm64/AccountSetupData.o -index-unit-output-path /ClariFi\ iOS.build/Debug-iphonesimulator/ClariFi\ iOS.build/Objects-normal/arm64/AppDIContainer.o -index-unit-output-path /ClariFi\ iOS.build/Debug-iphonesimulator/ClariFi\ iOS.build/Objects-normal/arm64/AppDIContainer+Registration.o -index-unit-output-path /ClariFi\ iOS.build/Debug-iphonesimulator/ClariFi\ iOS.build/Objects-normal/arm64/CategoryPickerView.o -index-unit-output-path /ClariFi\ iOS.build/Debug-iphonesimulator/ClariFi\ iOS.build/Objects-normal/arm64/DIContainer.o -index-unit-output-path /ClariFi\ iOS.build/Debug-iphonesimulator/ClariFi\ iOS.build/Objects-normal/arm64/DIContainer+Environment.o -index-unit-output-path /ClariFi\ iOS.build/Debug-iphonesimulator/ClariFi\ iOS.build/Objects-normal/arm64/ColorSystem.o -index-unit-output-path /ClariFi\ iOS.build/Debug-iphonesimulator/ClariFi\ iOS.build/Objects-normal/arm64/Decimal+Currency.o -index-unit-output-path /ClariFi\ iOS.build/Debug-iphonesimulator/ClariFi\ iOS.build/Objects-normal/arm64/Typography.o -index-unit-output-path /ClariFi\ iOS.build/Debug-iphonesimulator/ClariFi\ iOS.build/Objects-normal/arm64/View+ErrorAlert.o -index-unit-output-path /ClariFi\ iOS.build/Debug-iphonesimulator/ClariFi\ iOS.build/Objects-normal/arm64/PremiumUpsellView.o -index-unit-output-path /ClariFi\ iOS.build/Debug-iphonesimulator/ClariFi\ iOS.build/Objects-normal/arm64/View+ErrorAlert+Example.o -index-unit-output-path /ClariFi\ iOS.build/Debug-iphonesimulator/ClariFi\ iOS.build/Objects-normal/arm64/AccountSetupData.o -index-store-path /Users/aero/Library/Developer/Xcode/DerivedData/ClariFi_iOS-gmrlhvqnuqrbwdaistjzehzlpfwz/Index.noindex/DataStore -index-system-modules
    |  
    |  
    |  Compile AppDIContainer+Registration.swift (arm64):
    |  /Users/mayenikhalo/Public/From aEroPartition/Dev/ClariFi iOS/ClariFi iOS/Core/DependencyInjection/AppDIContainer+Registration.swift:116:50: warning: use of protocol 'TransactionRepository' as a type must be written 'any TransactionRepository'; this will be an error in a future Swift language mode
    |                  transactionRepository: c.resolve(TransactionRepository.self),
    |                                                   ^~~~~~~~~~~~~~~~~~~~~
    |                                                   (any TransactionRepository)
    |  /Users/mayenikhalo/Public/From aEroPartition/Dev/ClariFi iOS/ClariFi iOS/Core/DependencyInjection/AppDIContainer+Registration.swift:130:50: warning: use of protocol 'TransactionRepository' as a type must be written 'any TransactionRepository'; this will be an error in a future Swift language mode
    |                  transactionRepository: c.resolve(TransactionRepository.self),
    |                                                   ^~~~~~~~~~~~~~~~~~~~~
    |                                                   (any TransactionRepository)
    |  /Users/mayenikhalo/Public/From aEroPartition/Dev/ClariFi iOS/ClariFi iOS/Core/DependencyInjection/AppDIContainer+Registration.swift:145:45: warning: use of protocol 'BudgetRepository' as a type must be written 'any BudgetRepository'; this will be an error in a future Swift language mode
    |                  budgetRepository: c.resolve(BudgetRepository.self),
    |                                              ^~~~~~~~~~~~~~~~
    |                                              (any BudgetRepository)
    |  /Users/mayenikhalo/Public/From aEroPartition/Dev/ClariFi iOS/ClariFi iOS/Core/DependencyInjection/AppDIContainer+Registration.swift:146:53: warning: use of protocol 'BudgetCategoryRepository' as a type must be written 'any BudgetCategoryRepository'; this will be an error in a future Swift language mode
    |                  budgetCategoryRepository: c.resolve(BudgetCategoryRepository.self),
    |                                                      ^~~~~~~~~~~~~~~~~~~~~~~~
    |                                                      (any BudgetCategoryRepository)
    |  /Users/mayenikhalo/Public/From aEroPartition/Dev/ClariFi iOS/ClariFi iOS/Core/DependencyInjection/AppDIContainer+Registration.swift:147:50: warning: use of protocol 'TransactionRepository' as a type must be written 'any TransactionRepository'; this will be an error in a future Swift language mode
    |                  transactionRepository: c.resolve(TransactionRepository.self),
    |                                                   ^~~~~~~~~~~~~~~~~~~~~
    |                                                   (any TransactionRepository)
    |  /Users/mayenikhalo/Public/From aEroPartition/Dev/ClariFi iOS/ClariFi iOS/Core/DependencyInjection/AppDIContainer+Registration.swift:158:48: warning: use of protocol 'RecurringTransactionRepository' as a type must be written 'any RecurringTransactionRepository'; this will be an error in a future Swift language mode
    |                  recurringRepository: c.resolve(RecurringTransactionRepository.self),
    |                                                 ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    |                                                 (any RecurringTransactionRepository)
    |  /Users/mayenikhalo/Public/From aEroPartition/Dev/ClariFi iOS/ClariFi iOS/Core/DependencyInjection/AppDIContainer+Registration.swift:159:50: warning: use of protocol 'TransactionRepository' as a type must be written 'any TransactionRepository'; this will be an error in a future Swift language mode
    |                  transactionRepository: c.resolve(TransactionRepository.self),
    |                                                   ^~~~~~~~~~~~~~~~~~~~~
    |                                                   (any TransactionRepository)
    |  /Users/mayenikhalo/Public/From aEroPartition/Dev/ClariFi iOS/ClariFi iOS/Core/DependencyInjection/AppDIContainer+Registration.swift:183:45: warning: use of protocol 'BudgetRepository' as a type must be written 'any BudgetRepository'; this will be an error in a future Swift language mode
    |                  budgetRepository: c.resolve(BudgetRepository.self),
    |                                              ^~~~~~~~~~~~~~~~
    |                                              (any BudgetRepository)
    |  /Users/mayenikhalo/Public/From aEroPartition/Dev/ClariFi iOS/ClariFi iOS/Core/DependencyInjection/AppDIContainer+Registration.swift:184:53: warning: use of protocol 'BudgetCategoryRepository' as a type must be written 'any BudgetCategoryRepository'; this will be an error in a future Swift language mode
    |                  budgetCategoryRepository: c.resolve(BudgetCategoryRepository.self),
    |                                                      ^~~~~~~~~~~~~~~~~~~~~~~~
    |                                                      (any BudgetCategoryRepository)
    |  /Users/mayenikhalo/Public/From aEroPartition/Dev/ClariFi iOS/ClariFi iOS/Core/DependencyInjection/AppDIContainer+Registration.swift:29:37: warning: use of protocol 'TransactionRepository' as a type must be written 'any TransactionRepository'; this will be an error in a future Swift language mode
    |          container.registerSingleton(TransactionRepository.self) { _ in
    |                                      ^~~~~~~~~~~~~~~~~~~~~
    |                                      (any TransactionRepository)
    |  /Users/mayenikhalo/Public/From aEroPartition/Dev/ClariFi iOS/ClariFi iOS/Core/DependencyInjection/AppDIContainer+Registration.swift:33:37: warning: use of protocol 'AccountRepository' as a type must be written 'any AccountRepository'; this will be an error in a future Swift language mode
    |          container.registerSingleton(AccountRepository.self) { _ in
    |                                      ^~~~~~~~~~~~~~~~~
    |                                      (any AccountRepository)
    |  /Users/mayenikhalo/Public/From aEroPartition/Dev/ClariFi iOS/ClariFi iOS/Core/DependencyInjection/AppDIContainer+Registration.swift:37:37: warning: use of protocol 'BudgetRepository' as a type must be written 'any BudgetRepository'; this will be an error in a future Swift language mode
    |          container.registerSingleton(BudgetRepository.self) { _ in
    |                                      ^~~~~~~~~~~~~~~~
    |                                      (any BudgetRepository)
    |  /Users/mayenikhalo/Public/From aEroPartition/Dev/ClariFi iOS/ClariFi iOS/Core/DependencyInjection/AppDIContainer+Registration.swift:41:37: warning: use of protocol 'BudgetCategoryRepository' as a type must be written 'any BudgetCategoryRepository'; this will be an error in a future Swift language mode
    |          container.registerSingleton(BudgetCategoryRepository.self) { _ in
    |                                      ^~~~~~~~~~~~~~~~~~~~~~~~
    |                                      (any BudgetCategoryRepository)
    |  /Users/mayenikhalo/Public/From aEroPartition/Dev/ClariFi iOS/ClariFi iOS/Core/DependencyInjection/AppDIContainer+Registration.swift:45:37: warning: use of protocol 'StatementRepository' as a type must be written 'any StatementRepository'; this will be an error in a future Swift language mode
    |          container.registerSingleton(StatementRepository.self) { _ in
    |                                      ^~~~~~~~~~~~~~~~~~~
    |                                      (any StatementRepository)
    |  /Users/mayenikhalo/Public/From aEroPartition/Dev/ClariFi iOS/ClariFi iOS/Core/DependencyInjection/AppDIContainer+Registration.swift:49:37: warning: use of protocol 'RecurringTransactionRepository' as a type must be written 'any RecurringTransactionRepository'; this will be an error in a future Swift language mode
    |          container.registerSingleton(RecurringTransactionRepository.self) { _ in
    |                                      ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    |                                      (any RecurringTransactionRepository)
    |  /Users/mayenikhalo/Public/From aEroPartition/Dev/ClariFi iOS/ClariFi iOS/Core/DependencyInjection/AppDIContainer+Registration.swift:182:13: error: call to main actor-isolated initializer 'init(budgetRepository:budgetCategoryRepository:templateService:context:)' in a synchronous nonisolated context
    |              BudgetCreationViewModel(
    |              ^
    |  /Users/mayenikhalo/Public/From aEroPartition/Dev/ClariFi iOS/ClariFi iOS/ViewModels/BudgetCreationViewModel.swift:52:5: note: calls to initializer 'init(budgetRepository:budgetCategoryRepository:templateService:context:)' from outside of its actor context are implicitly asynchronous
    |      init(
    |      ^
    |  /Users/mayenikhalo/Public/From aEroPartition/Dev/ClariFi iOS/ClariFi iOS/ViewModels/BudgetCreationViewModel.swift:52:5: note: main actor isolation inferred from inheritance from class 'BaseViewModel'
    |      init(
    |      ^
    |  /Users/mayenikhalo/Public/From aEroPartition/Dev/ClariFi iOS/ClariFi iOS/Core/DependencyInjection/AppDIContainer+Registration.swift:281:50: warning: use of protocol 'TransactionRepository' as a type must be written 'any TransactionRepository'; this will be an error in a future Swift language mode
    |                  transactionRepository: c.resolve(TransactionRepository.self),
    |                                                   ^~~~~~~~~~~~~~~~~~~~~
    |                                                   (any TransactionRepository)
    |  /Users/mayenikhalo/Public/From aEroPartition/Dev/ClariFi iOS/ClariFi iOS/Core/DependencyInjection/AppDIContainer+Registration.swift:295:50: warning: use of protocol 'TransactionRepository' as a type must be written 'any TransactionRepository'; this will be an error in a future Swift language mode
    |                  transactionRepository: c.resolve(TransactionRepository.self),
    |                                                   ^~~~~~~~~~~~~~~~~~~~~
    |                                                   (any TransactionRepository)
    |  /Users/mayenikhalo/Public/From aEroPartition/Dev/ClariFi iOS/ClariFi iOS/Core/DependencyInjection/AppDIContainer+Registration.swift:310:45: warning: use of protocol 'BudgetRepository' as a type must be written 'any BudgetRepository'; this will be an error in a future Swift language mode
    |                  budgetRepository: c.resolve(BudgetRepository.self),
    |                                              ^~~~~~~~~~~~~~~~
    |                                              (any BudgetRepository)
    |  /Users/mayenikhalo/Public/From aEroPartition/Dev/ClariFi iOS/ClariFi iOS/Core/DependencyInjection/AppDIContainer+Registration.swift:311:53: warning: use of protocol 'BudgetCategoryRepository' as a type must be written 'any BudgetCategoryRepository'; this will be an error in a future Swift language mode
    |                  budgetCategoryRepository: c.resolve(BudgetCategoryRepository.self),
    |                                                      ^~~~~~~~~~~~~~~~~~~~~~~~
    |                                                      (any BudgetCategoryRepository)
    |  /Users/mayenikhalo/Public/From aEroPartition/Dev/ClariFi iOS/ClariFi iOS/Core/DependencyInjection/AppDIContainer+Registration.swift:312:50: warning: use of protocol 'TransactionRepository' as a type must be written 'any TransactionRepository'; this will be an error in a future Swift language mode
    |                  transactionRepository: c.resolve(TransactionRepository.self),
    |                                                   ^~~~~~~~~~~~~~~~~~~~~
    |                                                   (any TransactionRepository)
    |  /Users/mayenikhalo/Public/From aEroPartition/Dev/ClariFi iOS/ClariFi iOS/Core/DependencyInjection/AppDIContainer+Registration.swift:323:48: warning: use of protocol 'RecurringTransactionRepository' as a type must be written 'any RecurringTransactionRepository'; this will be an error in a future Swift language mode
    |                  recurringRepository: c.resolve(RecurringTransactionRepository.self),
    |                                                 ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    |                                                 (any RecurringTransactionRepository)
    |  /Users/mayenikhalo/Public/From aEroPartition/Dev/ClariFi iOS/ClariFi iOS/Core/DependencyInjection/AppDIContainer+Registration.swift:324:50: warning: use of protocol 'TransactionRepository' as a type must be written 'any TransactionRepository'; this will be an error in a future Swift language mode
    |                  transactionRepository: c.resolve(TransactionRepository.self),
    |                                                   ^~~~~~~~~~~~~~~~~~~~~
    |                                                   (any TransactionRepository)
    |  /Users/mayenikhalo/Public/From aEroPartition/Dev/ClariFi iOS/ClariFi iOS/Core/DependencyInjection/AppDIContainer+Registration.swift:346:45: warning: use of protocol 'BudgetRepository' as a type must be written 'any BudgetRepository'; this will be an error in a future Swift language mode
    |                  budgetRepository: c.resolve(BudgetRepository.self),
    |                                              ^~~~~~~~~~~~~~~~
    |                                              (any BudgetRepository)
    |  /Users/mayenikhalo/Public/From aEroPartition/Dev/ClariFi iOS/ClariFi iOS/Core/DependencyInjection/AppDIContainer+Registration.swift:347:53: warning: use of protocol 'BudgetCategoryRepository' as a type must be written 'any BudgetCategoryRepository'; this will be an error in a future Swift language mode
    |                  budgetCategoryRepository: c.resolve(BudgetCategoryRepository.self),
    |                                                      ^~~~~~~~~~~~~~~~~~~~~~~~
    |                                                      (any BudgetCategoryRepository)
    |  /Users/mayenikhalo/Public/From aEroPartition/Dev/ClariFi iOS/ClariFi iOS/Core/DependencyInjection/AppDIContainer+Registration.swift:205:37: warning: use of protocol 'TransactionRepository' as a type must be written 'any TransactionRepository'; this will be an error in a future Swift language mode
    |          container.registerSingleton(TransactionRepository.self) { _ in
    |                                      ^~~~~~~~~~~~~~~~~~~~~
    |                                      (any TransactionRepository)
    |  /Users/mayenikhalo/Public/From aEroPartition/Dev/ClariFi iOS/ClariFi iOS/Core/DependencyInjection/AppDIContainer+Registration.swift:209:37: warning: use of protocol 'AccountRepository' as a type must be written 'any AccountRepository'; this will be an error in a future Swift language mode
    |          container.registerSingleton(AccountRepository.self) { _ in
    |                                      ^~~~~~~~~~~~~~~~~
    |                                      (any AccountRepository)
    |  /Users/mayenikhalo/Public/From aEroPartition/Dev/ClariFi iOS/ClariFi iOS/Core/DependencyInjection/AppDIContainer+Registration.swift:213:37: warning: use of protocol 'BudgetRepository' as a type must be written 'any BudgetRepository'; this will be an error in a future Swift language mode
    |          container.registerSingleton(BudgetRepository.self) { _ in
    |                                      ^~~~~~~~~~~~~~~~
    |                                      (any BudgetRepository)
    |  /Users/mayenikhalo/Public/From aEroPartition/Dev/ClariFi iOS/ClariFi iOS/Core/DependencyInjection/AppDIContainer+Registration.swift:217:37: warning: use of protocol 'BudgetCategoryRepository' as a type must be written 'any BudgetCategoryRepository'; this will be an error in a future Swift language mode
    |          container.registerSingleton(BudgetCategoryRepository.self) { _ in
    |                                      ^~~~~~~~~~~~~~~~~~~~~~~~
    |                                      (any BudgetCategoryRepository)
    |  /Users/mayenikhalo/Public/From aEroPartition/Dev/ClariFi iOS/ClariFi iOS/Core/DependencyInjection/AppDIContainer+Registration.swift:221:37: warning: use of protocol 'StatementRepository' as a type must be written 'any StatementRepository'; this will be an error in a future Swift language mode
    |          container.registerSingleton(StatementRepository.self) { _ in
    |                                      ^~~~~~~~~~~~~~~~~~~
    |                                      (any StatementRepository)
    |  /Users/mayenikhalo/Public/From aEroPartition/Dev/ClariFi iOS/ClariFi iOS/Core/DependencyInjection/AppDIContainer+Registration.swift:225:37: warning: use of protocol 'RecurringTransactionRepository' as a type must be written 'any RecurringTransactionRepository'; this will be an error in a future Swift language mode
    |          container.registerSingleton(RecurringTransactionRepository.self) { _ in
    |                                      ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    |                                      (any RecurringTransactionRepository)
    |  



== VERSION INFO:

    Tools: 17A400
    OS:    25A362
    PID:   631
    Model: MacBook Air
    Arch:  arm64e



== EXECUTION MODE PROPERTIES:

    Automatically Refresh Previews: true
    JIT Mode User Enabled: true
    Falling back to Dynamic Replacement: false



== PACKAGE RESOLUTION ERRORS:

    



== REFERENCED SOURCE PACKAGES:

    



== JIT LINKAGE:

    



== ENVIRONMENT:

    openFiles = [
        /Users/mayenikhalo/Public/From aEroPartition/Dev/ClariFi iOS/ClariFi iOS/Views/AboutView.swift
    ]
    wantsNewBuildSystem = true
    newBuildSystemAvailable = true
    activeScheme = ClariFi iOS
    activeRunDestination = iPhone 17 Pro variant iphonesimulator arm64
    workspaceArena = [x]
    buildArena = [x]
    buildableEntries = [
        ClariFi iOS.app
    ]
    runMode = JIT Executor



== SELECTED RUN DESTINATION:

    Simulator - iOS 26.0 | iphonesimulator | arm64 | iPhone 17 Pro | no proxy



== SESSION GROUP 143 (START):

    workspace identifier: workspace:85E9C8FD-CD0B-4780-AEEB-A3BF3E43FE98
    previewPreflights [
           Preview Preflight | Registry-AboutView.swift#1[preview]: from Editor(5894) for local
    ]
    externalRegistryPreflights [
    ]
    providers [
           Preview Provider | Registry-AboutView.swift#1[preview] [Editor(5894)]
    ]
    translation units [
           /Users/mayenikhalo/Public/From aEroPartition/Dev/ClariFi iOS/ClariFi iOS/Views/AboutView.swift
    ]
    attributes: [
        Editor(5894):     
            isAppPreviewEnabled: false
            destinationMode: automatic
            previewSettings: [
                preview(Registry-AboutAppView.swift#1[preview]):     isEnabled: false
                    boxedCanvasControlStates: []
            ]
    ]



== SESSION GROUP 142 (START):

    workspace identifier: workspace:85E9C8FD-CD0B-4780-AEEB-A3BF3E43FE98
    previewPreflights [
           Preview Preflight | Registry-AboutView.swift#1[preview]: from Editor(5894) for local
    ]
    externalRegistryPreflights [
    ]
    providers [
           Preview Provider | Registry-AboutView.swift#1[preview] [Editor(5894)]
    ]
    translation units [
           /Users/mayenikhalo/Public/From aEroPartition/Dev/ClariFi iOS/ClariFi iOS/Views/AboutView.swift
    ]
    attributes: [
        Editor(5894):     
            isAppPreviewEnabled: false
            destinationMode: automatic
            previewSettings: [
                preview(Registry-AboutAppView.swift#1[preview]):     isEnabled: false
                    boxedCanvasControlStates: []
            ]
    ]



== SESSION GROUP 141 (START):

    workspace identifier: workspace:85E9C8FD-CD0B-4780-AEEB-A3BF3E43FE98
    previewPreflights [
           Preview Preflight | Registry-AboutView.swift#1[preview]: from Editor(5894) for local
    ]
    externalRegistryPreflights [
    ]
    providers [
           Preview Provider | Registry-AboutView.swift#1[preview] [Editor(5894)]
    ]
    translation units [
           /Users/mayenikhalo/Public/From aEroPartition/Dev/ClariFi iOS/ClariFi iOS/Views/AboutView.swift
    ]
    attributes: [
        Editor(5894):     
            isAppPreviewEnabled: false
            destinationMode: automatic
            previewSettings: [
                preview(Registry-AboutAppView.swift#1[preview]):     isEnabled: false
                    boxedCanvasControlStates: []
            ]
    ]
    build graph {
        ClariFi iOS.app (#3)
           sourceFile(file:///Users/mayenikhalo/Public/From%20aEroPartition/Dev/ClariFi%20iOS/ClariFi%20iOS/Views/AboutView.swift -> AboutView.swift) (#1)
           AboutView.swift (#2)
    }
    update plan {
        iOS [arm64 iphonesimulator26.0 iphonesimulator] (iPhone 17 Pro, DC949F89-CF3A-4B38-97E9-E4B9A67DF1E0-iphonesimulator26.0-arm64-iphonesimulator), [], thinning disabled, thunking enabled) {
            Destination: iPhone 17 Pro DC949F89-CF3A-4B38-97E9-E4B9A67DF1E0 | default device for iphonesimulator [
                ClariFi_iOS app - Previews {
                    execution point packs [
                        [source: AboutView.swift, role: Previews] (in ClariFi_iOS)
                    ]
                    translation units [
                        AboutView.swift (in ClariFi iOS.app)
                    ]
                    modules [
                        ClariFi iOS.app
                    ]
                    jit link description [
                        ClariFi iOS.app
                    ]
                }
            ]
        }
    }



== SESSION GROUP 140 (START):

    workspace identifier: workspace:85E9C8FD-CD0B-4780-AEEB-A3BF3E43FE98
    previewPreflights [
           Preview Preflight | Registry-AboutView.swift#1[preview]: from Editor(5894) for local
    ]
    externalRegistryPreflights [
    ]
    providers [
           Preview Provider | Registry-AboutView.swift#1[preview] [Editor(5894)]
    ]
    translation units [
           /Users/mayenikhalo/Public/From aEroPartition/Dev/ClariFi iOS/ClariFi iOS/Views/AboutView.swift
    ]
    attributes: [
        Editor(5894):     
            isAppPreviewEnabled: false
            destinationMode: automatic
            previewSettings: [
                preview(Registry-AboutAppView.swift#1[preview]):     isEnabled: false
                    boxedCanvasControlStates: []
            ]
    ]
    build graph {
        ClariFi iOS.app (#3)
           sourceFile(file:///Users/mayenikhalo/Public/From%20aEroPartition/Dev/ClariFi%20iOS/ClariFi%20iOS/Views/AboutView.swift -> AboutView.swift) (#1)
           AboutView.swift (#2)
    }
    update plan {
        iOS [arm64 iphonesimulator26.0 iphonesimulator] (iPhone 17 Pro, DC949F89-CF3A-4B38-97E9-E4B9A67DF1E0-iphonesimulator26.0-arm64-iphonesimulator), [], thinning disabled, thunking enabled) {
            Destination: iPhone 17 Pro DC949F89-CF3A-4B38-97E9-E4B9A67DF1E0 | default device for iphonesimulator [
                ClariFi_iOS app - Previews {
                    execution point packs [
                        [source: AboutView.swift, role: Previews] (in ClariFi_iOS)
                    ]
                    translation units [
                        AboutView.swift (in ClariFi iOS.app)
                    ]
                    modules [
                        ClariFi iOS.app
                    ]
                    jit link description [
                        ClariFi iOS.app
                    ]
                }
            ]
        }
    }



== BUILD PRODUCTS CACHE:

    BuildCache {
    }



== POWER STATE LOGS:

    2025-10-14, 2:06 PM Received power source state: Battery Powered (lowPowerMode: false, status: charged, level: 100%)
    2025-10-14, 2:06 PM No device power state user override user default value.Current power state: Full Power



== DISPLAYABLE CONTENT STATE:

    updateIdentifier: 16988
    buildingState: Running
    isUpdateInProgress: false
    providers [
        Registry[Registry-AboutView.swift#1[preview] (line 145)] {
            status: Failed: GroupRecordingError
            
            Error encountered during update group #143
            
            ==================================
            
            |  SchemeBuildError: Failed to build the scheme “ClariFi iOS”
            |  
            |  call to main actor-isolated initializer 'init(budgetRepository:budgetCategoryRepository:templateService:context:)' in a synchronous nonisolated context
            |  
            |  Compiling AppDIContainer.swift, AppDIContainer+Registration.swift, CategoryPickerView.swift, DIContainer.swift, DIContainer+Environment.swift, ColorSystem.swift, Decimal+Currency.swift, Typography.swift, View+ErrorAlert.swift, PremiumUpsellView.swift, View+ErrorAlert+Example.swift, AccountSetupData.swift:
            |  Failed frontend command:
            |  /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swift-frontend -frontend -c -filelist /Users/aero/Library/Developer/Xcode/DerivedData/ClariFi_iOS-gmrlhvqnuqrbwdaistjzehzlpfwz/Build/Intermediates.noindex/ClariFi\ iOS.build/Debug-iphonesimulator/ClariFi\ iOS.build/Objects-normal/arm64/sources-135 -primary-file /Users/mayenikhalo/Public/From\ aEroPartition/Dev/ClariFi\ iOS/ClariFi\ iOS/Core/DependencyInjection/AppDIContainer.swift -primary-file /Users/mayenikhalo/Public/From\ aEroPartition/Dev/ClariFi\ iOS/ClariFi\ iOS/Core/DependencyInjection/AppDIContainer+Registration.swift -primary-file /Users/mayenikhalo/Public/From\ aEroPartition/Dev/ClariFi\ iOS/ClariFi\ iOS/Views/Components/CategoryPickerView.swift -primary-file /Users/mayenikhalo/Public/From\ aEroPartition/Dev/ClariFi\ iOS/ClariFi\ iOS/Core/DependencyInjection/DIContainer.swift -primary-file /Users/mayenikhalo/Public/From\ aEroPartition/Dev/ClariFi\ iOS/ClariFi\ iOS/Core/DependencyInjection/DIContainer+Environment.swift -primary-file /Users/mayenikhalo/Public/From\ aEroPartition/Dev/ClariFi\ iOS/ClariFi\ iOS/Core/Extensions/ColorSystem.swift -primary-file /Users/mayenikhalo/Public/From\ aEroPartition/Dev/ClariFi\ iOS/ClariFi\ iOS/Core/Extensions/Decimal+Currency.swift -primary-file /Users/mayenikhalo/Public/From\ aEroPartition/Dev/ClariFi\ iOS/ClariFi\ iOS/Core/Extensions/Typography.swift -primary-file /Users/mayenikhalo/Public/From\ aEroPartition/Dev/ClariFi\ iOS/ClariFi\ iOS/Core/Extensions/View+ErrorAlert.swift -primary-file /Users/mayenikhalo/Public/From\ aEroPartition/Dev/ClariFi\ iOS/ClariFi\ iOS/Views/Components/PremiumUpsellView.swift -primary-file /Users/mayenikhalo/Public/From\ aEroPartition/Dev/ClariFi\ iOS/ClariFi\ iOS/Core/Extensions/View+ErrorAlert+Example.swift -primary-file /Users/mayenikhalo/Public/From\ aEroPartition/Dev/ClariFi\ iOS/ClariFi\ iOS/Models/AccountSetupData.swift -supplementary-output-file-map /Users/aero/Library/Developer/Xcode/DerivedData/ClariFi_iOS-gmrlhvqnuqrbwdaistjzehzlpfwz/Build/Intermediates.noindex/ClariFi\ iOS.build/Debug-iphonesimulator/ClariFi\ iOS.build/Objects-normal/arm64/supplementaryOutputs-1080 -emit-localized-strings -emit-localized-strings-path /Users/aero/Library/Developer/Xcode/DerivedData/ClariFi_iOS-gmrlhvqnuqrbwdaistjzehzlpfwz/Build/Intermediates.noindex/ClariFi\ iOS.build/Debug-iphonesimulator/ClariFi\ iOS.build/Objects-normal/arm64 -target arm64-apple-ios18.5-simulator -module-can-import-version DeveloperToolsSupport 23.0.4 23.0.4 -module-can-import-version SwiftUI 7.0.84.1 7.0.84 -module-can-import-version UIKit 9088.1.113 9088.1.113 -disable-cross-import-overlay-search -swift-module-cross-import AppIntents /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk/System/Library/Frameworks/AppIntents.framework/Modules/AppIntents.swiftcrossimport/SwiftUI.swiftoverlay -swift-module-cross-import AppIntents /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk/System/Library/Frameworks/AppIntents.framework/Modules/AppIntents.swiftcrossimport/UIKit.swiftoverlay -swift-module-cross-import AppIntents /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator26.0.sdk/System/Library/Frameworks/AppIntents.framework/Modules/AppIntents.swiftcrossimport/SwiftUI.swiftoverlay -swift-module-cross-import AppIntents /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator26.0.sdk/System/Library/Frameworks/AppIntents.framework/Modules/AppIntents.swiftcrossimport/UIKit.swiftoverlay -swift-module-cross-import CoreData /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk/System/Library/Frameworks/CoreData.framework/Modules/CoreData.swiftcrossimport/CloudKit.swiftoverlay -swift-module-cross-import CoreData /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator26.0.sdk/System/Library/Frameworks/CoreData.framework/Modules/CoreData.swiftcrossimport/CloudKit.swiftoverlay -swift-module-cross-import PhotosUI /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk/System/Library/Frameworks/PhotosUI.framework/Modules/PhotosUI.swiftcrossimport/SwiftUI.swiftoverlay -swift-module-cross-import PhotosUI /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk/System/Library/Frameworks/PhotosUI.framework/Modules/PhotosUI.swiftcrossimport/WidgetKit.swiftoverlay -swift-module-cross-import PhotosUI /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator26.0.sdk/System/Library/Frameworks/PhotosUI.framework/Modules/PhotosUI.swiftcrossimport/SwiftUI.swiftoverlay -swift-module-cross-import PhotosUI /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator26.0.sdk/System/Library/Frameworks/PhotosUI.framework/Modules/PhotosUI.swiftcrossimport/WidgetKit.swiftoverlay -swift-module-cross-import RelevanceKit /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk/System/Library/Frameworks/RelevanceKit.framework/Modules/RelevanceKit.swiftcrossimport/MapKit.swiftoverlay -swift-module-cross-import RelevanceKit /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator26.0.sdk/System/Library/Frameworks/RelevanceKit.framework/Modules/RelevanceKit.swiftcrossimport/MapKit.swiftoverlay -swift-module-cross-import StoreKit /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk/System/Library/Frameworks/StoreKit.framework/Modules/StoreKit.swiftcrossimport/SwiftUI.swiftoverlay -swift-module-cross-import StoreKit /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator26.0.sdk/System/Library/Frameworks/StoreKit.framework/Modules/StoreKit.swiftcrossimport/SwiftUI.swiftoverlay -load-resolved-plugin /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/usr/lib/swift/host/plugins/libAppIntentsMacros.dylib\#/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/usr/bin/swift-plugin-server\#AppIntentsMacros -load-resolved-plugin /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/usr/lib/swift/host/plugins/libFoundationMacros.dylib\#/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/usr/bin/swift-plugin-server\#FoundationMacros -load-resolved-plugin /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/usr/lib/swift/host/plugins/libObservationMacros.dylib\#/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/usr/bin/swift-plugin-server\#ObservationMacros -load-resolved-plugin /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/usr/lib/swift/host/plugins/libPreviewsMacros.dylib\#/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/usr/bin/swift-plugin-server\#PreviewsMacros -load-resolved-plugin /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/usr/lib/swift/host/plugins/libSwiftMacros.dylib\#/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/usr/bin/swift-plugin-server\#SwiftMacros -load-resolved-plugin /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/usr/lib/swift/host/plugins/libSwiftUIMacros.dylib\#/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/usr/bin/swift-plugin-server\#SwiftUIMacros -disable-implicit-swift-modules -Xcc -fno-implicit-modules -Xcc -fno-implicit-module-maps -explicit-swift-module-map-file /Users/aero/Library/Developer/Xcode/DerivedData/ClariFi_iOS-gmrlhvqnuqrbwdaistjzehzlpfwz/Build/Intermediates.noindex/ClariFi\ iOS.build/Debug-iphonesimulator/ClariFi\ iOS.build/Objects-normal/arm64/ClariFi_iOS-dependencies-134.json -Xllvm -aarch64-use-tbi -enable-objc-interop -sdk /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator26.0.sdk -I /Users/aero/Library/Developer/Xcode/DerivedData/ClariFi_iOS-gmrlhvqnuqrbwdaistjzehzlpfwz/Build/Products/Debug-iphonesimulator -F /Users/aero/Library/Developer/Xcode/DerivedData/ClariFi_iOS-gmrlhvqnuqrbwdaistjzehzlpfwz/Build/Products/Debug-iphonesimulator -no-color-diagnostics -Xcc -fno-color-diagnostics -enable-testing -g -debug-info-format\=dwarf -dwarf-version\=5 -module-cache-path /Users/aero/Library/Developer/Xcode/DerivedData/ClariFi_iOS-gmrlhvqnuqrbwdaistjzehzlpfwz/Build/Intermediates.noindex/SwiftExplicitPrecompiledModules -profile-generate -profile-coverage-mapping -swift-version 5 -enforce-exclusivity\=checked -Onone -D DEBUG -serialize-debugging-options -const-gather-protocols-file /Users/aero/Library/Developer/Xcode/DerivedData/ClariFi_iOS-gmrlhvqnuqrbwdaistjzehzlpfwz/Build/Intermediates.noindex/ClariFi\ iOS.build/Debug-iphonesimulator/ClariFi\ iOS.build/Objects-normal/arm64/ClariFi\ iOS_const_extract_protocols.json -enable-experimental-feature DebugDescriptionMacro -enable-bare-slash-regex -empty-abi-descriptor -validate-clang-modules-once -clang-build-session-file /Users/aero/Library/Developer/Xcode/DerivedData/ModuleCache.noindex/Session.modulevalidation -Xcc -working-directory -Xcc /Users/mayenikhalo/Public/From\ aEroPartition/Dev/ClariFi\ iOS -enable-anonymous-context-mangled-names -file-compilation-dir /Users/mayenikhalo/Public/From\ aEroPartition/Dev/ClariFi\ iOS -Xcc -D_LIBCPP_HARDENING_MODE\=_LIBCPP_HARDENING_MODE_DEBUG -Xcc -ivfsstatcache -Xcc /Users/aero/Library/Developer/Xcode/DerivedData/SDKStatCaches.noindex/iphonesimulator26.0-23A339-26257891a6c027eb51374368541b8346.sdkstatcache -Xcc -I/Users/aero/Library/Developer/Xcode/DerivedData/ClariFi_iOS-gmrlhvqnuqrbwdaistjzehzlpfwz/Build/Intermediates.noindex/ClariFi\ iOS.build/Debug-iphonesimulator/ClariFi\ iOS.build/swift-overrides.hmap -Xcc -iquote -Xcc /Users/aero/Library/Developer/Xcode/DerivedData/ClariFi_iOS-gmrlhvqnuqrbwdaistjzehzlpfwz/Build/Intermediates.noindex/ClariFi\ iOS.build/Debug-iphonesimulator/ClariFi\ iOS.build/ClariFi\ iOS-generated-files.hmap -Xcc -I/Users/aero/Library/Developer/Xcode/DerivedData/ClariFi_iOS-gmrlhvqnuqrbwdaistjzehzlpfwz/Build/Intermediates.noindex/ClariFi\ iOS.build/Debug-iphonesimulator/ClariFi\ iOS.build/ClariFi\ iOS-own-target-headers.hmap -Xcc -I/Users/aero/Library/Developer/Xcode/DerivedData/ClariFi_iOS-gmrlhvqnuqrbwdaistjzehzlpfwz/Build/Intermediates.noindex/ClariFi\ iOS.build/Debug-iphonesimulator/ClariFi\ iOS.build/ClariFi\ iOS-all-target-headers.hmap -Xcc -iquote -Xcc /Users/aero/Library/Developer/Xcode/DerivedData/ClariFi_iOS-gmrlhvqnuqrbwdaistjzehzlpfwz/Build/Intermediates.noindex/ClariFi\ iOS.build/Debug-iphonesimulator/ClariFi\ iOS.build/ClariFi\ iOS-project-headers.hmap -Xcc -I/Users/aero/Library/Developer/Xcode/DerivedData/ClariFi_iOS-gmrlhvqnuqrbwdaistjzehzlpfwz/Build/Products/Debug-iphonesimulator/include -Xcc -I/Users/aero/Library/Developer/Xcode/DerivedData/ClariFi_iOS-gmrlhvqnuqrbwdaistjzehzlpfwz/Build/Intermediates.noindex/ClariFi\ iOS.build/Debug-iphonesimulator/ClariFi\ iOS.build/DerivedSources-normal/arm64 -Xcc -I/Users/aero/Library/Developer/Xcode/DerivedData/ClariFi_iOS-gmrlhvqnuqrbwdaistjzehzlpfwz/Build/Intermediates.noindex/ClariFi\ iOS.build/Debug-iphonesimulator/ClariFi\ iOS.build/DerivedSources/arm64 -Xcc -I/Users/aero/Library/Developer/Xcode/DerivedData/ClariFi_iOS-gmrlhvqnuqrbwdaistjzehzlpfwz/Build/Intermediates.noindex/ClariFi\ iOS.build/Debug-iphonesimulator/ClariFi\ iOS.build/DerivedSources -Xcc -DDEBUG\=1 -no-auto-bridging-header-chaining -module-name ClariFi_iOS -frontend-parseable-output -disable-clang-spi -target-sdk-version 26.0 -target-sdk-name iphonesimulator26.0 -clang-target arm64-apple-ios26.0-simulator -in-process-plugin-server-path /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/lib/swift/host/libSwiftInProcPluginServer.dylib -o /Users/aero/Library/Developer/Xcode/DerivedData/ClariFi_iOS-gmrlhvqnuqrbwdaistjzehzlpfwz/Build/Intermediates.noindex/ClariFi\ iOS.build/Debug-iphonesimulator/ClariFi\ iOS.build/Objects-normal/arm64/AppDIContainer.o -o /Users/aero/Library/Developer/Xcode/DerivedData/ClariFi_iOS-gmrlhvqnuqrbwdaistjzehzlpfwz/Build/Intermediates.noindex/ClariFi\ iOS.build/Debug-iphonesimulator/ClariFi\ iOS.build/Objects-normal/arm64/AppDIContainer+Registration.o -o /Users/aero/Library/Developer/Xcode/DerivedData/ClariFi_iOS-gmrlhvqnuqrbwdaistjzehzlpfwz/Build/Intermediates.noindex/ClariFi\ iOS.build/Debug-iphonesimulator/ClariFi\ iOS.build/Objects-normal/arm64/CategoryPickerView.o -o /Users/aero/Library/Developer/Xcode/DerivedData/ClariFi_iOS-gmrlhvqnuqrbwdaistjzehzlpfwz/Build/Intermediates.noindex/ClariFi\ iOS.build/Debug-iphonesimulator/ClariFi\ iOS.build/Objects-normal/arm64/DIContainer.o -o /Users/aero/Library/Developer/Xcode/DerivedData/ClariFi_iOS-gmrlhvqnuqrbwdaistjzehzlpfwz/Build/Intermediates.noindex/ClariFi\ iOS.build/Debug-iphonesimulator/ClariFi\ iOS.build/Objects-normal/arm64/DIContainer+Environment.o -o /Users/aero/Library/Developer/Xcode/DerivedData/ClariFi_iOS-gmrlhvqnuqrbwdaistjzehzlpfwz/Build/Intermediates.noindex/ClariFi\ iOS.build/Debug-iphonesimulator/ClariFi\ iOS.build/Objects-normal/arm64/ColorSystem.o -o /Users/aero/Library/Developer/Xcode/DerivedData/ClariFi_iOS-gmrlhvqnuqrbwdaistjzehzlpfwz/Build/Intermediates.noindex/ClariFi\ iOS.build/Debug-iphonesimulator/ClariFi\ iOS.build/Objects-normal/arm64/Decimal+Currency.o -o /Users/aero/Library/Developer/Xcode/DerivedData/ClariFi_iOS-gmrlhvqnuqrbwdaistjzehzlpfwz/Build/Intermediates.noindex/ClariFi\ iOS.build/Debug-iphonesimulator/ClariFi\ iOS.build/Objects-normal/arm64/Typography.o -o /Users/aero/Library/Developer/Xcode/DerivedData/ClariFi_iOS-gmrlhvqnuqrbwdaistjzehzlpfwz/Build/Intermediates.noindex/ClariFi\ iOS.build/Debug-iphonesimulator/ClariFi\ iOS.build/Objects-normal/arm64/View+ErrorAlert.o -o /Users/aero/Library/Developer/Xcode/DerivedData/ClariFi_iOS-gmrlhvqnuqrbwdaistjzehzlpfwz/Build/Intermediates.noindex/ClariFi\ iOS.build/Debug-iphonesimulator/ClariFi\ iOS.build/Objects-normal/arm64/PremiumUpsellView.o -o /Users/aero/Library/Developer/Xcode/DerivedData/ClariFi_iOS-gmrlhvqnuqrbwdaistjzehzlpfwz/Build/Intermediates.noindex/ClariFi\ iOS.build/Debug-iphonesimulator/ClariFi\ iOS.build/Objects-normal/arm64/View+ErrorAlert+Example.o -o /Users/aero/Library/Developer/Xcode/DerivedData/ClariFi_iOS-gmrlhvqnuqrbwdaistjzehzlpfwz/Build/Intermediates.noindex/ClariFi\ iOS.build/Debug-iphonesimulator/ClariFi\ iOS.build/Objects-normal/arm64/AccountSetupData.o -index-unit-output-path /ClariFi\ iOS.build/Debug-iphonesimulator/ClariFi\ iOS.build/Objects-normal/arm64/AppDIContainer.o -index-unit-output-path /ClariFi\ iOS.build/Debug-iphonesimulator/ClariFi\ iOS.build/Objects-normal/arm64/AppDIContainer+Registration.o -index-unit-output-path /ClariFi\ iOS.build/Debug-iphonesimulator/ClariFi\ iOS.build/Objects-normal/arm64/CategoryPickerView.o -index-unit-output-path /ClariFi\ iOS.build/Debug-iphonesimulator/ClariFi\ iOS.build/Objects-normal/arm64/DIContainer.o -index-unit-output-path /ClariFi\ iOS.build/Debug-iphonesimulator/ClariFi\ iOS.build/Objects-normal/arm64/DIContainer+Environment.o -index-unit-output-path /ClariFi\ iOS.build/Debug-iphonesimulator/ClariFi\ iOS.build/Objects-normal/arm64/ColorSystem.o -index-unit-output-path /ClariFi\ iOS.build/Debug-iphonesimulator/ClariFi\ iOS.build/Objects-normal/arm64/Decimal+Currency.o -index-unit-output-path /ClariFi\ iOS.build/Debug-iphonesimulator/ClariFi\ iOS.build/Objects-normal/arm64/Typography.o -index-unit-output-path /ClariFi\ iOS.build/Debug-iphonesimulator/ClariFi\ iOS.build/Objects-normal/arm64/View+ErrorAlert.o -index-unit-output-path /ClariFi\ iOS.build/Debug-iphonesimulator/ClariFi\ iOS.build/Objects-normal/arm64/PremiumUpsellView.o -index-unit-output-path /ClariFi\ iOS.build/Debug-iphonesimulator/ClariFi\ iOS.build/Objects-normal/arm64/View+ErrorAlert+Example.o -index-unit-output-path /ClariFi\ iOS.build/Debug-iphonesimulator/ClariFi\ iOS.build/Objects-normal/arm64/AccountSetupData.o -index-store-path /Users/aero/Library/Developer/Xcode/DerivedData/ClariFi_iOS-gmrlhvqnuqrbwdaistjzehzlpfwz/Index.noindex/DataStore -index-system-modules
            |  
            |  
            |  Compile AppDIContainer+Registration.swift (arm64):
            |  /Users/mayenikhalo/Public/From aEroPartition/Dev/ClariFi iOS/ClariFi iOS/Core/DependencyInjection/AppDIContainer+Registration.swift:116:50: warning: use of protocol 'TransactionRepository' as a type must be written 'any TransactionRepository'; this will be an error in a future Swift language mode
            |                  transactionRepository: c.resolve(TransactionRepository.self),
            |                                                   ^~~~~~~~~~~~~~~~~~~~~
            |                                                   (any TransactionRepository)
            |  /Users/mayenikhalo/Public/From aEroPartition/Dev/ClariFi iOS/ClariFi iOS/Core/DependencyInjection/AppDIContainer+Registration.swift:130:50: warning: use of protocol 'TransactionRepository' as a type must be written 'any TransactionRepository'; this will be an error in a future Swift language mode
            |                  transactionRepository: c.resolve(TransactionRepository.self),
            |                                                   ^~~~~~~~~~~~~~~~~~~~~
            |                                                   (any TransactionRepository)
            |  /Users/mayenikhalo/Public/From aEroPartition/Dev/ClariFi iOS/ClariFi iOS/Core/DependencyInjection/AppDIContainer+Registration.swift:145:45: warning: use of protocol 'BudgetRepository' as a type must be written 'any BudgetRepository'; this will be an error in a future Swift language mode
            |                  budgetRepository: c.resolve(BudgetRepository.self),
            |                                              ^~~~~~~~~~~~~~~~
            |                                              (any BudgetRepository)
            |  /Users/mayenikhalo/Public/From aEroPartition/Dev/ClariFi iOS/ClariFi iOS/Core/DependencyInjection/AppDIContainer+Registration.swift:146:53: warning: use of protocol 'BudgetCategoryRepository' as a type must be written 'any BudgetCategoryRepository'; this will be an error in a future Swift language mode
            |                  budgetCategoryRepository: c.resolve(BudgetCategoryRepository.self),
            |                                                      ^~~~~~~~~~~~~~~~~~~~~~~~
            |                                                      (any BudgetCategoryRepository)
            |  /Users/mayenikhalo/Public/From aEroPartition/Dev/ClariFi iOS/ClariFi iOS/Core/DependencyInjection/AppDIContainer+Registration.swift:147:50: warning: use of protocol 'TransactionRepository' as a type must be written 'any TransactionRepository'; this will be an error in a future Swift language mode
            |                  transactionRepository: c.resolve(TransactionRepository.self),
            |                                                   ^~~~~~~~~~~~~~~~~~~~~
            |                                                   (any TransactionRepository)
            |  /Users/mayenikhalo/Public/From aEroPartition/Dev/ClariFi iOS/ClariFi iOS/Core/DependencyInjection/AppDIContainer+Registration.swift:158:48: warning: use of protocol 'RecurringTransactionRepository' as a type must be written 'any RecurringTransactionRepository'; this will be an error in a future Swift language mode
            |                  recurringRepository: c.resolve(RecurringTransactionRepository.self),
            |                                                 ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
            |                                                 (any RecurringTransactionRepository)
            |  /Users/mayenikhalo/Public/From aEroPartition/Dev/ClariFi iOS/ClariFi iOS/Core/DependencyInjection/AppDIContainer+Registration.swift:159:50: warning: use of protocol 'TransactionRepository' as a type must be written 'any TransactionRepository'; this will be an error in a future Swift language mode
            |                  transactionRepository: c.resolve(TransactionRepository.self),
            |                                                   ^~~~~~~~~~~~~~~~~~~~~
            |                                                   (any TransactionRepository)
            |  /Users/mayenikhalo/Public/From aEroPartition/Dev/ClariFi iOS/ClariFi iOS/Core/DependencyInjection/AppDIContainer+Registration.swift:183:45: warning: use of protocol 'BudgetRepository' as a type must be written 'any BudgetRepository'; this will be an error in a future Swift language mode
            |                  budgetRepository: c.resolve(BudgetRepository.self),
            |                                              ^~~~~~~~~~~~~~~~
            |                                              (any BudgetRepository)
            |  /Users/mayenikhalo/Public/From aEroPartition/Dev/ClariFi iOS/ClariFi iOS/Core/DependencyInjection/AppDIContainer+Registration.swift:184:53: warning: use of protocol 'BudgetCategoryRepository' as a type must be written 'any BudgetCategoryRepository'; this will be an error in a future Swift language mode
            |                  budgetCategoryRepository: c.resolve(BudgetCategoryRepository.self),
            |                                                      ^~~~~~~~~~~~~~~~~~~~~~~~
            |                                                      (any BudgetCategoryRepository)
            |  /Users/mayenikhalo/Public/From aEroPartition/Dev/ClariFi iOS/ClariFi iOS/Core/DependencyInjection/AppDIContainer+Registration.swift:29:37: warning: use of protocol 'TransactionRepository' as a type must be written 'any TransactionRepository'; this will be an error in a future Swift language mode
            |          container.registerSingleton(TransactionRepository.self) { _ in
            |                                      ^~~~~~~~~~~~~~~~~~~~~
            |                                      (any TransactionRepository)
            |  /Users/mayenikhalo/Public/From aEroPartition/Dev/ClariFi iOS/ClariFi iOS/Core/DependencyInjection/AppDIContainer+Registration.swift:33:37: warning: use of protocol 'AccountRepository' as a type must be written 'any AccountRepository'; this will be an error in a future Swift language mode
            |          container.registerSingleton(AccountRepository.self) { _ in
            |                                      ^~~~~~~~~~~~~~~~~
            |                                      (any AccountRepository)
            |  /Users/mayenikhalo/Public/From aEroPartition/Dev/ClariFi iOS/ClariFi iOS/Core/DependencyInjection/AppDIContainer+Registration.swift:37:37: warning: use of protocol 'BudgetRepository' as a type must be written 'any BudgetRepository'; this will be an error in a future Swift language mode
            |          container.registerSingleton(BudgetRepository.self) { _ in
            |                                      ^~~~~~~~~~~~~~~~
            |                                      (any BudgetRepository)
            |  /Users/mayenikhalo/Public/From aEroPartition/Dev/ClariFi iOS/ClariFi iOS/Core/DependencyInjection/AppDIContainer+Registration.swift:41:37: warning: use of protocol 'BudgetCategoryRepository' as a type must be written 'any BudgetCategoryRepository'; this will be an error in a future Swift language mode
            |          container.registerSingleton(BudgetCategoryRepository.self) { _ in
            |                                      ^~~~~~~~~~~~~~~~~~~~~~~~
            |                                      (any BudgetCategoryRepository)
            |  /Users/mayenikhalo/Public/From aEroPartition/Dev/ClariFi iOS/ClariFi iOS/Core/DependencyInjection/AppDIContainer+Registration.swift:45:37: warning: use of protocol 'StatementRepository' as a type must be written 'any StatementRepository'; this will be an error in a future Swift language mode
            |          container.registerSingleton(StatementRepository.self) { _ in
            |                                      ^~~~~~~~~~~~~~~~~~~
            |                                      (any StatementRepository)
            |  /Users/mayenikhalo/Public/From aEroPartition/Dev/ClariFi iOS/ClariFi iOS/Core/DependencyInjection/AppDIContainer+Registration.swift:49:37: warning: use of protocol 'RecurringTransactionRepository' as a type must be written 'any RecurringTransactionRepository'; this will be an error in a future Swift language mode
            |          container.registerSingleton(RecurringTransactionRepository.self) { _ in
            |                                      ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
            |                                      (any RecurringTransactionRepository)
            |  /Users/mayenikhalo/Public/From aEroPartition/Dev/ClariFi iOS/ClariFi iOS/Core/DependencyInjection/AppDIContainer+Registration.swift:182:13: error: call to main actor-isolated initializer 'init(budgetRepository:budgetCategoryRepository:templateService:context:)' in a synchronous nonisolated context
            |              BudgetCreationViewModel(
            |              ^
            |  /Users/mayenikhalo/Public/From aEroPartition/Dev/ClariFi iOS/ClariFi iOS/ViewModels/BudgetCreationViewModel.swift:52:5: note: calls to initializer 'init(budgetRepository:budgetCategoryRepository:templateService:context:)' from outside of its actor context are implicitly asynchronous
            |      init(
            |      ^
            |  /Users/mayenikhalo/Public/From aEroPartition/Dev/ClariFi iOS/ClariFi iOS/ViewModels/BudgetCreationViewModel.swift:52:5: note: main actor isolation inferred from inheritance from class 'BaseViewModel'
            |      init(
            |      ^
            |  /Users/mayenikhalo/Public/From aEroPartition/Dev/ClariFi iOS/ClariFi iOS/Core/DependencyInjection/AppDIContainer+Registration.swift:281:50: warning: use of protocol 'TransactionRepository' as a type must be written 'any TransactionRepository'; this will be an error in a future Swift language mode
            |                  transactionRepository: c.resolve(TransactionRepository.self),
            |                                                   ^~~~~~~~~~~~~~~~~~~~~
            |                                                   (any TransactionRepository)
            |  /Users/mayenikhalo/Public/From aEroPartition/Dev/ClariFi iOS/ClariFi iOS/Core/DependencyInjection/AppDIContainer+Registration.swift:295:50: warning: use of protocol 'TransactionRepository' as a type must be written 'any TransactionRepository'; this will be an error in a future Swift language mode
            |                  transactionRepository: c.resolve(TransactionRepository.self),
            |                                                   ^~~~~~~~~~~~~~~~~~~~~
            |                                                   (any TransactionRepository)
            |  /Users/mayenikhalo/Public/From aEroPartition/Dev/ClariFi iOS/ClariFi iOS/Core/DependencyInjection/AppDIContainer+Registration.swift:310:45: warning: use of protocol 'BudgetRepository' as a type must be written 'any BudgetRepository'; this will be an error in a future Swift language mode
            |                  budgetRepository: c.resolve(BudgetRepository.self),
            |                                              ^~~~~~~~~~~~~~~~
            |                                              (any BudgetRepository)
            |  /Users/mayenikhalo/Public/From aEroPartition/Dev/ClariFi iOS/ClariFi iOS/Core/DependencyInjection/AppDIContainer+Registration.swift:311:53: warning: use of protocol 'BudgetCategoryRepository' as a type must be written 'any BudgetCategoryRepository'; this will be an error in a future Swift language mode
            |                  budgetCategoryRepository: c.resolve(BudgetCategoryRepository.self),
            |                                                      ^~~~~~~~~~~~~~~~~~~~~~~~
            |                                                      (any BudgetCategoryRepository)
            |  /Users/mayenikhalo/Public/From aEroPartition/Dev/ClariFi iOS/ClariFi iOS/Core/DependencyInjection/AppDIContainer+Registration.swift:312:50: warning: use of protocol 'TransactionRepository' as a type must be written 'any TransactionRepository'; this will be an error in a future Swift language mode
            |                  transactionRepository: c.resolve(TransactionRepository.self),
            |                                                   ^~~~~~~~~~~~~~~~~~~~~
            |                                                   (any TransactionRepository)
            |  /Users/mayenikhalo/Public/From aEroPartition/Dev/ClariFi iOS/ClariFi iOS/Core/DependencyInjection/AppDIContainer+Registration.swift:323:48: warning: use of protocol 'RecurringTransactionRepository' as a type must be written 'any RecurringTransactionRepository'; this will be an error in a future Swift language mode
            |                  recurringRepository: c.resolve(RecurringTransactionRepository.self),
            |                                                 ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
            |                                                 (any RecurringTransactionRepository)
            |  /Users/mayenikhalo/Public/From aEroPartition/Dev/ClariFi iOS/ClariFi iOS/Core/DependencyInjection/AppDIContainer+Registration.swift:324:50: warning: use of protocol 'TransactionRepository' as a type must be written 'any TransactionRepository'; this will be an error in a future Swift language mode
            |                  transactionRepository: c.resolve(TransactionRepository.self),
            |                                                   ^~~~~~~~~~~~~~~~~~~~~
            |                                                   (any TransactionRepository)
            |  /Users/mayenikhalo/Public/From aEroPartition/Dev/ClariFi iOS/ClariFi iOS/Core/DependencyInjection/AppDIContainer+Registration.swift:346:45: warning: use of protocol 'BudgetRepository' as a type must be written 'any BudgetRepository'; this will be an error in a future Swift language mode
            |                  budgetRepository: c.resolve(BudgetRepository.self),
            |                                              ^~~~~~~~~~~~~~~~
            |                                              (any BudgetRepository)
            |  /Users/mayenikhalo/Public/From aEroPartition/Dev/ClariFi iOS/ClariFi iOS/Core/DependencyInjection/AppDIContainer+Registration.swift:347:53: warning: use of protocol 'BudgetCategoryRepository' as a type must be written 'any BudgetCategoryRepository'; this will be an error in a future Swift language mode
            |                  budgetCategoryRepository: c.resolve(BudgetCategoryRepository.self),
            |                                                      ^~~~~~~~~~~~~~~~~~~~~~~~
            |                                                      (any BudgetCategoryRepository)
            |  /Users/mayenikhalo/Public/From aEroPartition/Dev/ClariFi iOS/ClariFi iOS/Core/DependencyInjection/AppDIContainer+Registration.swift:205:37: warning: use of protocol 'TransactionRepository' as a type must be written 'any TransactionRepository'; this will be an error in a future Swift language mode
            |          container.registerSingleton(TransactionRepository.self) { _ in
            |                                      ^~~~~~~~~~~~~~~~~~~~~
            |                                      (any TransactionRepository)
            |  /Users/mayenikhalo/Public/From aEroPartition/Dev/ClariFi iOS/ClariFi iOS/Core/DependencyInjection/AppDIContainer+Registration.swift:209:37: warning: use of protocol 'AccountRepository' as a type must be written 'any AccountRepository'; this will be an error in a future Swift language mode
            |          container.registerSingleton(AccountRepository.self) { _ in
            |                                      ^~~~~~~~~~~~~~~~~
            |                                      (any AccountRepository)
            |  /Users/mayenikhalo/Public/From aEroPartition/Dev/ClariFi iOS/ClariFi iOS/Core/DependencyInjection/AppDIContainer+Registration.swift:213:37: warning: use of protocol 'BudgetRepository' as a type must be written 'any BudgetRepository'; this will be an error in a future Swift language mode
            |          container.registerSingleton(BudgetRepository.self) { _ in
            |                                      ^~~~~~~~~~~~~~~~
            |                                      (any BudgetRepository)
            |  /Users/mayenikhalo/Public/From aEroPartition/Dev/ClariFi iOS/ClariFi iOS/Core/DependencyInjection/AppDIContainer+Registration.swift:217:37: warning: use of protocol 'BudgetCategoryRepository' as a type must be written 'any BudgetCategoryRepository'; this will be an error in a future Swift language mode
            |          container.registerSingleton(BudgetCategoryRepository.self) { _ in
            |                                      ^~~~~~~~~~~~~~~~~~~~~~~~
            |                                      (any BudgetCategoryRepository)
            |  /Users/mayenikhalo/Public/From aEroPartition/Dev/ClariFi iOS/ClariFi iOS/Core/DependencyInjection/AppDIContainer+Registration.swift:221:37: warning: use of protocol 'StatementRepository' as a type must be written 'any StatementRepository'; this will be an error in a future Swift language mode
            |          container.registerSingleton(StatementRepository.self) { _ in
            |                                      ^~~~~~~~~~~~~~~~~~~
            |                                      (any StatementRepository)
            |  /Users/mayenikhalo/Public/From aEroPartition/Dev/ClariFi iOS/ClariFi iOS/Core/DependencyInjection/AppDIContainer+Registration.swift:225:37: warning: use of protocol 'RecurringTransactionRepository' as a type must be written 'any RecurringTransactionRepository'; this will be an error in a future Swift language mode
            |          container.registerSingleton(RecurringTransactionRepository.self) { _ in
            |                                      ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
            |                                      (any RecurringTransactionRepository)
            |  
        }
    ]
    registries [
        Registry-AboutView.swift#1[preview] {
            status: Failed: GroupRecordingError
            
            Error encountered during update group #143
            
            ==================================
            
            |  SchemeBuildError: Failed to build the scheme “ClariFi iOS”
            |  
            |  call to main actor-isolated initializer 'init(budgetRepository:budgetCategoryRepository:templateService:context:)' in a synchronous nonisolated context
            |  
            |  Compiling AppDIContainer.swift, AppDIContainer+Registration.swift, CategoryPickerView.swift, DIContainer.swift, DIContainer+Environment.swift, ColorSystem.swift, Decimal+Currency.swift, Typography.swift, View+ErrorAlert.swift, PremiumUpsellView.swift, View+ErrorAlert+Example.swift, AccountSetupData.swift:
            |  Failed frontend command:
            |  /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swift-frontend -frontend -c -filelist /Users/aero/Library/Developer/Xcode/DerivedData/ClariFi_iOS-gmrlhvqnuqrbwdaistjzehzlpfwz/Build/Intermediates.noindex/ClariFi\ iOS.build/Debug-iphonesimulator/ClariFi\ iOS.build/Objects-normal/arm64/sources-135 -primary-file /Users/mayenikhalo/Public/From\ aEroPartition/Dev/ClariFi\ iOS/ClariFi\ iOS/Core/DependencyInjection/AppDIContainer.swift -primary-file /Users/mayenikhalo/Public/From\ aEroPartition/Dev/ClariFi\ iOS/ClariFi\ iOS/Core/DependencyInjection/AppDIContainer+Registration.swift -primary-file /Users/mayenikhalo/Public/From\ aEroPartition/Dev/ClariFi\ iOS/ClariFi\ iOS/Views/Components/CategoryPickerView.swift -primary-file /Users/mayenikhalo/Public/From\ aEroPartition/Dev/ClariFi\ iOS/ClariFi\ iOS/Core/DependencyInjection/DIContainer.swift -primary-file /Users/mayenikhalo/Public/From\ aEroPartition/Dev/ClariFi\ iOS/ClariFi\ iOS/Core/DependencyInjection/DIContainer+Environment.swift -primary-file /Users/mayenikhalo/Public/From\ aEroPartition/Dev/ClariFi\ iOS/ClariFi\ iOS/Core/Extensions/ColorSystem.swift -primary-file /Users/mayenikhalo/Public/From\ aEroPartition/Dev/ClariFi\ iOS/ClariFi\ iOS/Core/Extensions/Decimal+Currency.swift -primary-file /Users/mayenikhalo/Public/From\ aEroPartition/Dev/ClariFi\ iOS/ClariFi\ iOS/Core/Extensions/Typography.swift -primary-file /Users/mayenikhalo/Public/From\ aEroPartition/Dev/ClariFi\ iOS/ClariFi\ iOS/Core/Extensions/View+ErrorAlert.swift -primary-file /Users/mayenikhalo/Public/From\ aEroPartition/Dev/ClariFi\ iOS/ClariFi\ iOS/Views/Components/PremiumUpsellView.swift -primary-file /Users/mayenikhalo/Public/From\ aEroPartition/Dev/ClariFi\ iOS/ClariFi\ iOS/Core/Extensions/View+ErrorAlert+Example.swift -primary-file /Users/mayenikhalo/Public/From\ aEroPartition/Dev/ClariFi\ iOS/ClariFi\ iOS/Models/AccountSetupData.swift -supplementary-output-file-map /Users/aero/Library/Developer/Xcode/DerivedData/ClariFi_iOS-gmrlhvqnuqrbwdaistjzehzlpfwz/Build/Intermediates.noindex/ClariFi\ iOS.build/Debug-iphonesimulator/ClariFi\ iOS.build/Objects-normal/arm64/supplementaryOutputs-1080 -emit-localized-strings -emit-localized-strings-path /Users/aero/Library/Developer/Xcode/DerivedData/ClariFi_iOS-gmrlhvqnuqrbwdaistjzehzlpfwz/Build/Intermediates.noindex/ClariFi\ iOS.build/Debug-iphonesimulator/ClariFi\ iOS.build/Objects-normal/arm64 -target arm64-apple-ios18.5-simulator -module-can-import-version DeveloperToolsSupport 23.0.4 23.0.4 -module-can-import-version SwiftUI 7.0.84.1 7.0.84 -module-can-import-version UIKit 9088.1.113 9088.1.113 -disable-cross-import-overlay-search -swift-module-cross-import AppIntents /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk/System/Library/Frameworks/AppIntents.framework/Modules/AppIntents.swiftcrossimport/SwiftUI.swiftoverlay -swift-module-cross-import AppIntents /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk/System/Library/Frameworks/AppIntents.framework/Modules/AppIntents.swiftcrossimport/UIKit.swiftoverlay -swift-module-cross-import AppIntents /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator26.0.sdk/System/Library/Frameworks/AppIntents.framework/Modules/AppIntents.swiftcrossimport/SwiftUI.swiftoverlay -swift-module-cross-import AppIntents /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator26.0.sdk/System/Library/Frameworks/AppIntents.framework/Modules/AppIntents.swiftcrossimport/UIKit.swiftoverlay -swift-module-cross-import CoreData /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk/System/Library/Frameworks/CoreData.framework/Modules/CoreData.swiftcrossimport/CloudKit.swiftoverlay -swift-module-cross-import CoreData /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator26.0.sdk/System/Library/Frameworks/CoreData.framework/Modules/CoreData.swiftcrossimport/CloudKit.swiftoverlay -swift-module-cross-import PhotosUI /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk/System/Library/Frameworks/PhotosUI.framework/Modules/PhotosUI.swiftcrossimport/SwiftUI.swiftoverlay -swift-module-cross-import PhotosUI /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk/System/Library/Frameworks/PhotosUI.framework/Modules/PhotosUI.swiftcrossimport/WidgetKit.swiftoverlay -swift-module-cross-import PhotosUI /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator26.0.sdk/System/Library/Frameworks/PhotosUI.framework/Modules/PhotosUI.swiftcrossimport/SwiftUI.swiftoverlay -swift-module-cross-import PhotosUI /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator26.0.sdk/System/Library/Frameworks/PhotosUI.framework/Modules/PhotosUI.swiftcrossimport/WidgetKit.swiftoverlay -swift-module-cross-import RelevanceKit /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk/System/Library/Frameworks/RelevanceKit.framework/Modules/RelevanceKit.swiftcrossimport/MapKit.swiftoverlay -swift-module-cross-import RelevanceKit /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator26.0.sdk/System/Library/Frameworks/RelevanceKit.framework/Modules/RelevanceKit.swiftcrossimport/MapKit.swiftoverlay -swift-module-cross-import StoreKit /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk/System/Library/Frameworks/StoreKit.framework/Modules/StoreKit.swiftcrossimport/SwiftUI.swiftoverlay -swift-module-cross-import StoreKit /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator26.0.sdk/System/Library/Frameworks/StoreKit.framework/Modules/StoreKit.swiftcrossimport/SwiftUI.swiftoverlay -load-resolved-plugin /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/usr/lib/swift/host/plugins/libAppIntentsMacros.dylib\#/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/usr/bin/swift-plugin-server\#AppIntentsMacros -load-resolved-plugin /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/usr/lib/swift/host/plugins/libFoundationMacros.dylib\#/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/usr/bin/swift-plugin-server\#FoundationMacros -load-resolved-plugin /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/usr/lib/swift/host/plugins/libObservationMacros.dylib\#/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/usr/bin/swift-plugin-server\#ObservationMacros -load-resolved-plugin /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/usr/lib/swift/host/plugins/libPreviewsMacros.dylib\#/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/usr/bin/swift-plugin-server\#PreviewsMacros -load-resolved-plugin /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/usr/lib/swift/host/plugins/libSwiftMacros.dylib\#/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/usr/bin/swift-plugin-server\#SwiftMacros -load-resolved-plugin /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/usr/lib/swift/host/plugins/libSwiftUIMacros.dylib\#/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/usr/bin/swift-plugin-server\#SwiftUIMacros -disable-implicit-swift-modules -Xcc -fno-implicit-modules -Xcc -fno-implicit-module-maps -explicit-swift-module-map-file /Users/aero/Library/Developer/Xcode/DerivedData/ClariFi_iOS-gmrlhvqnuqrbwdaistjzehzlpfwz/Build/Intermediates.noindex/ClariFi\ iOS.build/Debug-iphonesimulator/ClariFi\ iOS.build/Objects-normal/arm64/ClariFi_iOS-dependencies-134.json -Xllvm -aarch64-use-tbi -enable-objc-interop -sdk /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator26.0.sdk -I /Users/aero/Library/Developer/Xcode/DerivedData/ClariFi_iOS-gmrlhvqnuqrbwdaistjzehzlpfwz/Build/Products/Debug-iphonesimulator -F /Users/aero/Library/Developer/Xcode/DerivedData/ClariFi_iOS-gmrlhvqnuqrbwdaistjzehzlpfwz/Build/Products/Debug-iphonesimulator -no-color-diagnostics -Xcc -fno-color-diagnostics -enable-testing -g -debug-info-format\=dwarf -dwarf-version\=5 -module-cache-path /Users/aero/Library/Developer/Xcode/DerivedData/ClariFi_iOS-gmrlhvqnuqrbwdaistjzehzlpfwz/Build/Intermediates.noindex/SwiftExplicitPrecompiledModules -profile-generate -profile-coverage-mapping -swift-version 5 -enforce-exclusivity\=checked -Onone -D DEBUG -serialize-debugging-options -const-gather-protocols-file /Users/aero/Library/Developer/Xcode/DerivedData/ClariFi_iOS-gmrlhvqnuqrbwdaistjzehzlpfwz/Build/Intermediates.noindex/ClariFi\ iOS.build/Debug-iphonesimulator/ClariFi\ iOS.build/Objects-normal/arm64/ClariFi\ iOS_const_extract_protocols.json -enable-experimental-feature DebugDescriptionMacro -enable-bare-slash-regex -empty-abi-descriptor -validate-clang-modules-once -clang-build-session-file /Users/aero/Library/Developer/Xcode/DerivedData/ModuleCache.noindex/Session.modulevalidation -Xcc -working-directory -Xcc /Users/mayenikhalo/Public/From\ aEroPartition/Dev/ClariFi\ iOS -enable-anonymous-context-mangled-names -file-compilation-dir /Users/mayenikhalo/Public/From\ aEroPartition/Dev/ClariFi\ iOS -Xcc -D_LIBCPP_HARDENING_MODE\=_LIBCPP_HARDENING_MODE_DEBUG -Xcc -ivfsstatcache -Xcc /Users/aero/Library/Developer/Xcode/DerivedData/SDKStatCaches.noindex/iphonesimulator26.0-23A339-26257891a6c027eb51374368541b8346.sdkstatcache -Xcc -I/Users/aero/Library/Developer/Xcode/DerivedData/ClariFi_iOS-gmrlhvqnuqrbwdaistjzehzlpfwz/Build/Intermediates.noindex/ClariFi\ iOS.build/Debug-iphonesimulator/ClariFi\ iOS.build/swift-overrides.hmap -Xcc -iquote -Xcc /Users/aero/Library/Developer/Xcode/DerivedData/ClariFi_iOS-gmrlhvqnuqrbwdaistjzehzlpfwz/Build/Intermediates.noindex/ClariFi\ iOS.build/Debug-iphonesimulator/ClariFi\ iOS.build/ClariFi\ iOS-generated-files.hmap -Xcc -I/Users/aero/Library/Developer/Xcode/DerivedData/ClariFi_iOS-gmrlhvqnuqrbwdaistjzehzlpfwz/Build/Intermediates.noindex/ClariFi\ iOS.build/Debug-iphonesimulator/ClariFi\ iOS.build/ClariFi\ iOS-own-target-headers.hmap -Xcc -I/Users/aero/Library/Developer/Xcode/DerivedData/ClariFi_iOS-gmrlhvqnuqrbwdaistjzehzlpfwz/Build/Intermediates.noindex/ClariFi\ iOS.build/Debug-iphonesimulator/ClariFi\ iOS.build/ClariFi\ iOS-all-target-headers.hmap -Xcc -iquote -Xcc /Users/aero/Library/Developer/Xcode/DerivedData/ClariFi_iOS-gmrlhvqnuqrbwdaistjzehzlpfwz/Build/Intermediates.noindex/ClariFi\ iOS.build/Debug-iphonesimulator/ClariFi\ iOS.build/ClariFi\ iOS-project-headers.hmap -Xcc -I/Users/aero/Library/Developer/Xcode/DerivedData/ClariFi_iOS-gmrlhvqnuqrbwdaistjzehzlpfwz/Build/Products/Debug-iphonesimulator/include -Xcc -I/Users/aero/Library/Developer/Xcode/DerivedData/ClariFi_iOS-gmrlhvqnuqrbwdaistjzehzlpfwz/Build/Intermediates.noindex/ClariFi\ iOS.build/Debug-iphonesimulator/ClariFi\ iOS.build/DerivedSources-normal/arm64 -Xcc -I/Users/aero/Library/Developer/Xcode/DerivedData/ClariFi_iOS-gmrlhvqnuqrbwdaistjzehzlpfwz/Build/Intermediates.noindex/ClariFi\ iOS.build/Debug-iphonesimulator/ClariFi\ iOS.build/DerivedSources/arm64 -Xcc -I/Users/aero/Library/Developer/Xcode/DerivedData/ClariFi_iOS-gmrlhvqnuqrbwdaistjzehzlpfwz/Build/Intermediates.noindex/ClariFi\ iOS.build/Debug-iphonesimulator/ClariFi\ iOS.build/DerivedSources -Xcc -DDEBUG\=1 -no-auto-bridging-header-chaining -module-name ClariFi_iOS -frontend-parseable-output -disable-clang-spi -target-sdk-version 26.0 -target-sdk-name iphonesimulator26.0 -clang-target arm64-apple-ios26.0-simulator -in-process-plugin-server-path /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/lib/swift/host/libSwiftInProcPluginServer.dylib -o /Users/aero/Library/Developer/Xcode/DerivedData/ClariFi_iOS-gmrlhvqnuqrbwdaistjzehzlpfwz/Build/Intermediates.noindex/ClariFi\ iOS.build/Debug-iphonesimulator/ClariFi\ iOS.build/Objects-normal/arm64/AppDIContainer.o -o /Users/aero/Library/Developer/Xcode/DerivedData/ClariFi_iOS-gmrlhvqnuqrbwdaistjzehzlpfwz/Build/Intermediates.noindex/ClariFi\ iOS.build/Debug-iphonesimulator/ClariFi\ iOS.build/Objects-normal/arm64/AppDIContainer+Registration.o -o /Users/aero/Library/Developer/Xcode/DerivedData/ClariFi_iOS-gmrlhvqnuqrbwdaistjzehzlpfwz/Build/Intermediates.noindex/ClariFi\ iOS.build/Debug-iphonesimulator/ClariFi\ iOS.build/Objects-normal/arm64/CategoryPickerView.o -o /Users/aero/Library/Developer/Xcode/DerivedData/ClariFi_iOS-gmrlhvqnuqrbwdaistjzehzlpfwz/Build/Intermediates.noindex/ClariFi\ iOS.build/Debug-iphonesimulator/ClariFi\ iOS.build/Objects-normal/arm64/DIContainer.o -o /Users/aero/Library/Developer/Xcode/DerivedData/ClariFi_iOS-gmrlhvqnuqrbwdaistjzehzlpfwz/Build/Intermediates.noindex/ClariFi\ iOS.build/Debug-iphonesimulator/ClariFi\ iOS.build/Objects-normal/arm64/DIContainer+Environment.o -o /Users/aero/Library/Developer/Xcode/DerivedData/ClariFi_iOS-gmrlhvqnuqrbwdaistjzehzlpfwz/Build/Intermediates.noindex/ClariFi\ iOS.build/Debug-iphonesimulator/ClariFi\ iOS.build/Objects-normal/arm64/ColorSystem.o -o /Users/aero/Library/Developer/Xcode/DerivedData/ClariFi_iOS-gmrlhvqnuqrbwdaistjzehzlpfwz/Build/Intermediates.noindex/ClariFi\ iOS.build/Debug-iphonesimulator/ClariFi\ iOS.build/Objects-normal/arm64/Decimal+Currency.o -o /Users/aero/Library/Developer/Xcode/DerivedData/ClariFi_iOS-gmrlhvqnuqrbwdaistjzehzlpfwz/Build/Intermediates.noindex/ClariFi\ iOS.build/Debug-iphonesimulator/ClariFi\ iOS.build/Objects-normal/arm64/Typography.o -o /Users/aero/Library/Developer/Xcode/DerivedData/ClariFi_iOS-gmrlhvqnuqrbwdaistjzehzlpfwz/Build/Intermediates.noindex/ClariFi\ iOS.build/Debug-iphonesimulator/ClariFi\ iOS.build/Objects-normal/arm64/View+ErrorAlert.o -o /Users/aero/Library/Developer/Xcode/DerivedData/ClariFi_iOS-gmrlhvqnuqrbwdaistjzehzlpfwz/Build/Intermediates.noindex/ClariFi\ iOS.build/Debug-iphonesimulator/ClariFi\ iOS.build/Objects-normal/arm64/PremiumUpsellView.o -o /Users/aero/Library/Developer/Xcode/DerivedData/ClariFi_iOS-gmrlhvqnuqrbwdaistjzehzlpfwz/Build/Intermediates.noindex/ClariFi\ iOS.build/Debug-iphonesimulator/ClariFi\ iOS.build/Objects-normal/arm64/View+ErrorAlert+Example.o -o /Users/aero/Library/Developer/Xcode/DerivedData/ClariFi_iOS-gmrlhvqnuqrbwdaistjzehzlpfwz/Build/Intermediates.noindex/ClariFi\ iOS.build/Debug-iphonesimulator/ClariFi\ iOS.build/Objects-normal/arm64/AccountSetupData.o -index-unit-output-path /ClariFi\ iOS.build/Debug-iphonesimulator/ClariFi\ iOS.build/Objects-normal/arm64/AppDIContainer.o -index-unit-output-path /ClariFi\ iOS.build/Debug-iphonesimulator/ClariFi\ iOS.build/Objects-normal/arm64/AppDIContainer+Registration.o -index-unit-output-path /ClariFi\ iOS.build/Debug-iphonesimulator/ClariFi\ iOS.build/Objects-normal/arm64/CategoryPickerView.o -index-unit-output-path /ClariFi\ iOS.build/Debug-iphonesimulator/ClariFi\ iOS.build/Objects-normal/arm64/DIContainer.o -index-unit-output-path /ClariFi\ iOS.build/Debug-iphonesimulator/ClariFi\ iOS.build/Objects-normal/arm64/DIContainer+Environment.o -index-unit-output-path /ClariFi\ iOS.build/Debug-iphonesimulator/ClariFi\ iOS.build/Objects-normal/arm64/ColorSystem.o -index-unit-output-path /ClariFi\ iOS.build/Debug-iphonesimulator/ClariFi\ iOS.build/Objects-normal/arm64/Decimal+Currency.o -index-unit-output-path /ClariFi\ iOS.build/Debug-iphonesimulator/ClariFi\ iOS.build/Objects-normal/arm64/Typography.o -index-unit-output-path /ClariFi\ iOS.build/Debug-iphonesimulator/ClariFi\ iOS.build/Objects-normal/arm64/View+ErrorAlert.o -index-unit-output-path /ClariFi\ iOS.build/Debug-iphonesimulator/ClariFi\ iOS.build/Objects-normal/arm64/PremiumUpsellView.o -index-unit-output-path /ClariFi\ iOS.build/Debug-iphonesimulator/ClariFi\ iOS.build/Objects-normal/arm64/View+ErrorAlert+Example.o -index-unit-output-path /ClariFi\ iOS.build/Debug-iphonesimulator/ClariFi\ iOS.build/Objects-normal/arm64/AccountSetupData.o -index-store-path /Users/aero/Library/Developer/Xcode/DerivedData/ClariFi_iOS-gmrlhvqnuqrbwdaistjzehzlpfwz/Index.noindex/DataStore -index-system-modules
            |  
            |  
            |  Compile AppDIContainer+Registration.swift (arm64):
            |  /Users/mayenikhalo/Public/From aEroPartition/Dev/ClariFi iOS/ClariFi iOS/Core/DependencyInjection/AppDIContainer+Registration.swift:116:50: warning: use of protocol 'TransactionRepository' as a type must be written 'any TransactionRepository'; this will be an error in a future Swift language mode
            |                  transactionRepository: c.resolve(TransactionRepository.self),
            |                                                   ^~~~~~~~~~~~~~~~~~~~~
            |                                                   (any TransactionRepository)
            |  /Users/mayenikhalo/Public/From aEroPartition/Dev/ClariFi iOS/ClariFi iOS/Core/DependencyInjection/AppDIContainer+Registration.swift:130:50: warning: use of protocol 'TransactionRepository' as a type must be written 'any TransactionRepository'; this will be an error in a future Swift language mode
            |                  transactionRepository: c.resolve(TransactionRepository.self),
            |                                                   ^~~~~~~~~~~~~~~~~~~~~
            |                                                   (any TransactionRepository)
            |  /Users/mayenikhalo/Public/From aEroPartition/Dev/ClariFi iOS/ClariFi iOS/Core/DependencyInjection/AppDIContainer+Registration.swift:145:45: warning: use of protocol 'BudgetRepository' as a type must be written 'any BudgetRepository'; this will be an error in a future Swift language mode
            |                  budgetRepository: c.resolve(BudgetRepository.self),
            |                                              ^~~~~~~~~~~~~~~~
            |                                              (any BudgetRepository)
            |  /Users/mayenikhalo/Public/From aEroPartition/Dev/ClariFi iOS/ClariFi iOS/Core/DependencyInjection/AppDIContainer+Registration.swift:146:53: warning: use of protocol 'BudgetCategoryRepository' as a type must be written 'any BudgetCategoryRepository'; this will be an error in a future Swift language mode
            |                  budgetCategoryRepository: c.resolve(BudgetCategoryRepository.self),
            |                                                      ^~~~~~~~~~~~~~~~~~~~~~~~
            |                                                      (any BudgetCategoryRepository)
            |  /Users/mayenikhalo/Public/From aEroPartition/Dev/ClariFi iOS/ClariFi iOS/Core/DependencyInjection/AppDIContainer+Registration.swift:147:50: warning: use of protocol 'TransactionRepository' as a type must be written 'any TransactionRepository'; this will be an error in a future Swift language mode
            |                  transactionRepository: c.resolve(TransactionRepository.self),
            |                                                   ^~~~~~~~~~~~~~~~~~~~~
            |                                                   (any TransactionRepository)
            |  /Users/mayenikhalo/Public/From aEroPartition/Dev/ClariFi iOS/ClariFi iOS/Core/DependencyInjection/AppDIContainer+Registration.swift:158:48: warning: use of protocol 'RecurringTransactionRepository' as a type must be written 'any RecurringTransactionRepository'; this will be an error in a future Swift language mode
            |                  recurringRepository: c.resolve(RecurringTransactionRepository.self),
            |                                                 ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
            |                                                 (any RecurringTransactionRepository)
            |  /Users/mayenikhalo/Public/From aEroPartition/Dev/ClariFi iOS/ClariFi iOS/Core/DependencyInjection/AppDIContainer+Registration.swift:159:50: warning: use of protocol 'TransactionRepository' as a type must be written 'any TransactionRepository'; this will be an error in a future Swift language mode
            |                  transactionRepository: c.resolve(TransactionRepository.self),
            |                                                   ^~~~~~~~~~~~~~~~~~~~~
            |                                                   (any TransactionRepository)
            |  /Users/mayenikhalo/Public/From aEroPartition/Dev/ClariFi iOS/ClariFi iOS/Core/DependencyInjection/AppDIContainer+Registration.swift:183:45: warning: use of protocol 'BudgetRepository' as a type must be written 'any BudgetRepository'; this will be an error in a future Swift language mode
            |                  budgetRepository: c.resolve(BudgetRepository.self),
            |                                              ^~~~~~~~~~~~~~~~
            |                                              (any BudgetRepository)
            |  /Users/mayenikhalo/Public/From aEroPartition/Dev/ClariFi iOS/ClariFi iOS/Core/DependencyInjection/AppDIContainer+Registration.swift:184:53: warning: use of protocol 'BudgetCategoryRepository' as a type must be written 'any BudgetCategoryRepository'; this will be an error in a future Swift language mode
            |                  budgetCategoryRepository: c.resolve(BudgetCategoryRepository.self),
            |                                                      ^~~~~~~~~~~~~~~~~~~~~~~~
            |                                                      (any BudgetCategoryRepository)
            |  /Users/mayenikhalo/Public/From aEroPartition/Dev/ClariFi iOS/ClariFi iOS/Core/DependencyInjection/AppDIContainer+Registration.swift:29:37: warning: use of protocol 'TransactionRepository' as a type must be written 'any TransactionRepository'; this will be an error in a future Swift language mode
            |          container.registerSingleton(TransactionRepository.self) { _ in
            |                                      ^~~~~~~~~~~~~~~~~~~~~
            |                                      (any TransactionRepository)
            |  /Users/mayenikhalo/Public/From aEroPartition/Dev/ClariFi iOS/ClariFi iOS/Core/DependencyInjection/AppDIContainer+Registration.swift:33:37: warning: use of protocol 'AccountRepository' as a type must be written 'any AccountRepository'; this will be an error in a future Swift language mode
            |          container.registerSingleton(AccountRepository.self) { _ in
            |                                      ^~~~~~~~~~~~~~~~~
            |                                      (any AccountRepository)
            |  /Users/mayenikhalo/Public/From aEroPartition/Dev/ClariFi iOS/ClariFi iOS/Core/DependencyInjection/AppDIContainer+Registration.swift:37:37: warning: use of protocol 'BudgetRepository' as a type must be written 'any BudgetRepository'; this will be an error in a future Swift language mode
            |          container.registerSingleton(BudgetRepository.self) { _ in
            |                                      ^~~~~~~~~~~~~~~~
            |                                      (any BudgetRepository)
            |  /Users/mayenikhalo/Public/From aEroPartition/Dev/ClariFi iOS/ClariFi iOS/Core/DependencyInjection/AppDIContainer+Registration.swift:41:37: warning: use of protocol 'BudgetCategoryRepository' as a type must be written 'any BudgetCategoryRepository'; this will be an error in a future Swift language mode
            |          container.registerSingleton(BudgetCategoryRepository.self) { _ in
            |                                      ^~~~~~~~~~~~~~~~~~~~~~~~
            |                                      (any BudgetCategoryRepository)
            |  /Users/mayenikhalo/Public/From aEroPartition/Dev/ClariFi iOS/ClariFi iOS/Core/DependencyInjection/AppDIContainer+Registration.swift:45:37: warning: use of protocol 'StatementRepository' as a type must be written 'any StatementRepository'; this will be an error in a future Swift language mode
            |          container.registerSingleton(StatementRepository.self) { _ in
            |                                      ^~~~~~~~~~~~~~~~~~~
            |                                      (any StatementRepository)
            |  /Users/mayenikhalo/Public/From aEroPartition/Dev/ClariFi iOS/ClariFi iOS/Core/DependencyInjection/AppDIContainer+Registration.swift:49:37: warning: use of protocol 'RecurringTransactionRepository' as a type must be written 'any RecurringTransactionRepository'; this will be an error in a future Swift language mode
            |          container.registerSingleton(RecurringTransactionRepository.self) { _ in
            |                                      ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
            |                                      (any RecurringTransactionRepository)
            |  /Users/mayenikhalo/Public/From aEroPartition/Dev/ClariFi iOS/ClariFi iOS/Core/DependencyInjection/AppDIContainer+Registration.swift:182:13: error: call to main actor-isolated initializer 'init(budgetRepository:budgetCategoryRepository:templateService:context:)' in a synchronous nonisolated context
            |              BudgetCreationViewModel(
            |              ^
            |  /Users/mayenikhalo/Public/From aEroPartition/Dev/ClariFi iOS/ClariFi iOS/ViewModels/BudgetCreationViewModel.swift:52:5: note: calls to initializer 'init(budgetRepository:budgetCategoryRepository:templateService:context:)' from outside of its actor context are implicitly asynchronous
            |      init(
            |      ^
            |  /Users/mayenikhalo/Public/From aEroPartition/Dev/ClariFi iOS/ClariFi iOS/ViewModels/BudgetCreationViewModel.swift:52:5: note: main actor isolation inferred from inheritance from class 'BaseViewModel'
            |      init(
            |      ^
            |  /Users/mayenikhalo/Public/From aEroPartition/Dev/ClariFi iOS/ClariFi iOS/Core/DependencyInjection/AppDIContainer+Registration.swift:281:50: warning: use of protocol 'TransactionRepository' as a type must be written 'any TransactionRepository'; this will be an error in a future Swift language mode
            |                  transactionRepository: c.resolve(TransactionRepository.self),
            |                                                   ^~~~~~~~~~~~~~~~~~~~~
            |                                                   (any TransactionRepository)
            |  /Users/mayenikhalo/Public/From aEroPartition/Dev/ClariFi iOS/ClariFi iOS/Core/DependencyInjection/AppDIContainer+Registration.swift:295:50: warning: use of protocol 'TransactionRepository' as a type must be written 'any TransactionRepository'; this will be an error in a future Swift language mode
            |                  transactionRepository: c.resolve(TransactionRepository.self),
            |                                                   ^~~~~~~~~~~~~~~~~~~~~
            |                                                   (any TransactionRepository)
            |  /Users/mayenikhalo/Public/From aEroPartition/Dev/ClariFi iOS/ClariFi iOS/Core/DependencyInjection/AppDIContainer+Registration.swift:310:45: warning: use of protocol 'BudgetRepository' as a type must be written 'any BudgetRepository'; this will be an error in a future Swift language mode
            |                  budgetRepository: c.resolve(BudgetRepository.self),
            |                                              ^~~~~~~~~~~~~~~~
            |                                              (any BudgetRepository)
            |  /Users/mayenikhalo/Public/From aEroPartition/Dev/ClariFi iOS/ClariFi iOS/Core/DependencyInjection/AppDIContainer+Registration.swift:311:53: warning: use of protocol 'BudgetCategoryRepository' as a type must be written 'any BudgetCategoryRepository'; this will be an error in a future Swift language mode
            |                  budgetCategoryRepository: c.resolve(BudgetCategoryRepository.self),
            |                                                      ^~~~~~~~~~~~~~~~~~~~~~~~
            |                                                      (any BudgetCategoryRepository)
            |  /Users/mayenikhalo/Public/From aEroPartition/Dev/ClariFi iOS/ClariFi iOS/Core/DependencyInjection/AppDIContainer+Registration.swift:312:50: warning: use of protocol 'TransactionRepository' as a type must be written 'any TransactionRepository'; this will be an error in a future Swift language mode
            |                  transactionRepository: c.resolve(TransactionRepository.self),
            |                                                   ^~~~~~~~~~~~~~~~~~~~~
            |                                                   (any TransactionRepository)
            |  /Users/mayenikhalo/Public/From aEroPartition/Dev/ClariFi iOS/ClariFi iOS/Core/DependencyInjection/AppDIContainer+Registration.swift:323:48: warning: use of protocol 'RecurringTransactionRepository' as a type must be written 'any RecurringTransactionRepository'; this will be an error in a future Swift language mode
            |                  recurringRepository: c.resolve(RecurringTransactionRepository.self),
            |                                                 ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
            |                                                 (any RecurringTransactionRepository)
            |  /Users/mayenikhalo/Public/From aEroPartition/Dev/ClariFi iOS/ClariFi iOS/Core/DependencyInjection/AppDIContainer+Registration.swift:324:50: warning: use of protocol 'TransactionRepository' as a type must be written 'any TransactionRepository'; this will be an error in a future Swift language mode
            |                  transactionRepository: c.resolve(TransactionRepository.self),
            |                                                   ^~~~~~~~~~~~~~~~~~~~~
            |                                                   (any TransactionRepository)
            |  /Users/mayenikhalo/Public/From aEroPartition/Dev/ClariFi iOS/ClariFi iOS/Core/DependencyInjection/AppDIContainer+Registration.swift:346:45: warning: use of protocol 'BudgetRepository' as a type must be written 'any BudgetRepository'; this will be an error in a future Swift language mode
            |                  budgetRepository: c.resolve(BudgetRepository.self),
            |                                              ^~~~~~~~~~~~~~~~
            |                                              (any BudgetRepository)
            |  /Users/mayenikhalo/Public/From aEroPartition/Dev/ClariFi iOS/ClariFi iOS/Core/DependencyInjection/AppDIContainer+Registration.swift:347:53: warning: use of protocol 'BudgetCategoryRepository' as a type must be written 'any BudgetCategoryRepository'; this will be an error in a future Swift language mode
            |                  budgetCategoryRepository: c.resolve(BudgetCategoryRepository.self),
            |                                                      ^~~~~~~~~~~~~~~~~~~~~~~~
            |                                                      (any BudgetCategoryRepository)
            |  /Users/mayenikhalo/Public/From aEroPartition/Dev/ClariFi iOS/ClariFi iOS/Core/DependencyInjection/AppDIContainer+Registration.swift:205:37: warning: use of protocol 'TransactionRepository' as a type must be written 'any TransactionRepository'; this will be an error in a future Swift language mode
            |          container.registerSingleton(TransactionRepository.self) { _ in
            |                                      ^~~~~~~~~~~~~~~~~~~~~
            |                                      (any TransactionRepository)
            |  /Users/mayenikhalo/Public/From aEroPartition/Dev/ClariFi iOS/ClariFi iOS/Core/DependencyInjection/AppDIContainer+Registration.swift:209:37: warning: use of protocol 'AccountRepository' as a type must be written 'any AccountRepository'; this will be an error in a future Swift language mode
            |          container.registerSingleton(AccountRepository.self) { _ in
            |                                      ^~~~~~~~~~~~~~~~~
            |                                      (any AccountRepository)
            |  /Users/mayenikhalo/Public/From aEroPartition/Dev/ClariFi iOS/ClariFi iOS/Core/DependencyInjection/AppDIContainer+Registration.swift:213:37: warning: use of protocol 'BudgetRepository' as a type must be written 'any BudgetRepository'; this will be an error in a future Swift language mode
            |          container.registerSingleton(BudgetRepository.self) { _ in
            |                                      ^~~~~~~~~~~~~~~~
            |                                      (any BudgetRepository)
            |  /Users/mayenikhalo/Public/From aEroPartition/Dev/ClariFi iOS/ClariFi iOS/Core/DependencyInjection/AppDIContainer+Registration.swift:217:37: warning: use of protocol 'BudgetCategoryRepository' as a type must be written 'any BudgetCategoryRepository'; this will be an error in a future Swift language mode
            |          container.registerSingleton(BudgetCategoryRepository.self) { _ in
            |                                      ^~~~~~~~~~~~~~~~~~~~~~~~
            |                                      (any BudgetCategoryRepository)
            |  /Users/mayenikhalo/Public/From aEroPartition/Dev/ClariFi iOS/ClariFi iOS/Core/DependencyInjection/AppDIContainer+Registration.swift:221:37: warning: use of protocol 'StatementRepository' as a type must be written 'any StatementRepository'; this will be an error in a future Swift language mode
            |          container.registerSingleton(StatementRepository.self) { _ in
            |                                      ^~~~~~~~~~~~~~~~~~~
            |                                      (any StatementRepository)
            |  /Users/mayenikhalo/Public/From aEroPartition/Dev/ClariFi iOS/ClariFi iOS/Core/DependencyInjection/AppDIContainer+Registration.swift:225:37: warning: use of protocol 'RecurringTransactionRepository' as a type must be written 'any RecurringTransactionRepository'; this will be an error in a future Swift language mode
            |          container.registerSingleton(RecurringTransactionRepository.self) { _ in
            |                                      ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
            |                                      (any RecurringTransactionRepository)
            |  
        }
    ]


