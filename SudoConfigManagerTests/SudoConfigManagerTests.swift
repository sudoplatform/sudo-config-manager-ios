//
// Copyright © 2022 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@testable import SudoConfigManager
import SudoLogging
import XCTest

class SudoConfigManagerTests: XCTestCase {

    // MARK: - Properties

    var instanceUnderTest: DefaultSudoConfigManager!
    var storageServiceMock: StorageServiceMock!
    var config: [String: Any]!

    // MARK: - Lifecycle

    override func setUp() {
        config = [
            "sudoService": [
                "version": 1
            ],
            "identityService": [
                "version": 2,
                "region": "test-region",
                "serviceInfoBucket": "test-bucket"
            ]
        ]
        storageServiceMock = StorageServiceMock()
        instanceUnderTest = DefaultSudoConfigManager(config: config, storageService: storageServiceMock, logger: .sudoConfigManagerLogger)
    }

    // MARK: - Tests: Get Config Set

    func test_getConfigSet_withDefaultManager_willReturnConfigSetFromBundle() {
        // when
        let result = instanceUnderTest.getConfigSet(namespace: "sudoService")
        // then
        XCTAssertEqual(result as? [String: Int], ["version": 1])
    }

    // MARK: - Tests: Validate Config

    func test_validateConfig_withNoServiceInfo_willValidateSuccessfully() async throws {
        // given
        storageServiceMock.listObjectsResult = .success([])
        // when
        try await instanceUnderTest.validateConfig()
        // then
        XCTAssertTrue(storageServiceMock.listObjectsCalled)
        XCTAssertFalse(storageServiceMock.getObjectCalled)
    }

    func test_validateConfig_withServiceInfo_withServicesMissing_willValidateSuccessfully() async throws {
        // given
        storageServiceMock.listObjectsResult = .success(["telephonyService.json", "vcService.json"])
        // when
        try await instanceUnderTest.validateConfig()
        // then
        XCTAssertTrue(storageServiceMock.listObjectsCalled)
        XCTAssertFalse(storageServiceMock.getObjectCalled)
    }

    func test_validateConfig_withOnlyNonJsonFilesInBucket_willValidateSuccessfully() async throws {
        // given
        storageServiceMock.listObjectsResult = .success(["identityService.txt", "sudoService"])
        // when
        try await instanceUnderTest.validateConfig()
        // then
        XCTAssertTrue(storageServiceMock.listObjectsCalled)
        XCTAssertFalse(storageServiceMock.getObjectCalled)
    }

    func test_validateConfig_withMinVersionLowerOrEqualToConfigVersion_willValidateSuccessfully() async throws {
        // given
        mockConfigInfo([
            .init(name: "sudoService", configVersion: 1, minSupportedVersion: 1),
            .init(name: "identityService", configVersion: 2, minSupportedVersion: 1)
        ])
        // when
        try await instanceUnderTest.validateConfig()
        // then
        XCTAssertTrue(storageServiceMock.listObjectsCalled)
        XCTAssertTrue(storageServiceMock.getObjectCalled)
    }

    func test_validateConfig_withMinVersionHigherThanConfigVersion_willValidateWithError() async throws {
        // given
        // given
        let sudoServiceInfo = ServiceCompatibilityInfo(name: "sudoService", configVersion: 1, minSupportedVersion: 1)
        let identityServiceInfo = ServiceCompatibilityInfo(name: "identityService", configVersion: 2, minSupportedVersion: 3)
        mockConfigInfo([sudoServiceInfo, identityServiceInfo])
        // when
        do {
            try await instanceUnderTest.validateConfig()
            XCTFail("Validate should not succeed")
        } catch SudoConfigManagerError.compatibilityIssueFound(let incompatible, let deprecated) {
            // then
            XCTAssertEqual(1, incompatible.count)
            XCTAssertEqual(0, deprecated.count)
            let incompatibleIdentityServiceInfo = try XCTUnwrap(incompatible.first(where: { $0.name == "identityService" }))
            XCTAssertEqual(incompatibleIdentityServiceInfo, identityServiceInfo)
        }
        XCTAssertTrue(storageServiceMock.listObjectsCalled)
        XCTAssertTrue(storageServiceMock.getObjectCalled)
    }

    func test_validateConfig_withMultipleMinVersionHigherThanConfigVersion_willValidateWithError() async throws {
        // given
        let sudoServiceInfo = ServiceCompatibilityInfo(name: "sudoService", configVersion: 1, minSupportedVersion: 2)
        let identityServiceInfo = ServiceCompatibilityInfo(name: "identityService", configVersion: 2, minSupportedVersion: 3)
        mockConfigInfo([sudoServiceInfo, identityServiceInfo])
        // when
        do {
            try await instanceUnderTest.validateConfig()
            XCTFail("Validate should not succeed")
        } catch SudoConfigManagerError.compatibilityIssueFound(let incompatible, let deprecated) {
            // then
            XCTAssertEqual(2, incompatible.count)
            XCTAssertEqual(0, deprecated.count)
            let incompatibleIdentityServiceInfo = try XCTUnwrap(incompatible.first(where: { $0.name == "identityService" }))
            let incompatibleSudoServiceInfo = try XCTUnwrap(incompatible.first(where: { $0.name == "sudoService" }))
            XCTAssertEqual(incompatibleSudoServiceInfo,sudoServiceInfo)
            XCTAssertEqual(incompatibleIdentityServiceInfo, identityServiceInfo)
        }
        XCTAssertTrue(storageServiceMock.listObjectsCalled)
        XCTAssertTrue(storageServiceMock.getObjectCalled)
    }

    func test_validateConfig_withDeprecatedVersionLowerThanConfigVersion_willValidateSuccessfully() async throws {
        // given
        mockConfigInfo([
            .init(name: "sudoService", configVersion: 1, minSupportedVersion: 0, deprecatedVersion: 0),
            .init(name: "identityService", configVersion: 2, minSupportedVersion: 1, deprecatedVersion: 1)
        ])
        // when
        try await instanceUnderTest.validateConfig()
        // then
        XCTAssertTrue(storageServiceMock.listObjectsCalled)
        XCTAssertTrue(storageServiceMock.getObjectCalled)
    }

    func test_validateConfig_withDeprecatedVersionHigherOrEqualToConfigVersion_willValidateWithError() async throws {
        // given
        let sudoServiceInfo = ServiceCompatibilityInfo(
            name: "sudoService",
            configVersion: 1,
            deprecatedVersion: 1,
            deprecationGrace: Date(timeIntervalSince1970: 1)
        )
        let identityServiceInfo = ServiceCompatibilityInfo(
            name: "identityService",
            configVersion: 2,
            minSupportedVersion: 1,
            deprecatedVersion: 3,
            deprecationGrace: Date(timeIntervalSince1970: 2)
        )
        mockConfigInfo([sudoServiceInfo, identityServiceInfo])
        // when
        do {
            try await instanceUnderTest.validateConfig()
            XCTFail("Validate should not succeed")
        } catch SudoConfigManagerError.compatibilityIssueFound(let incompatible, let deprecated) {
            // then
            XCTAssertEqual(0, incompatible.count)
            XCTAssertEqual(2, deprecated.count)
            let deprecatedIdentityServiceInfo = try XCTUnwrap(deprecated.first(where: { $0.name == "identityService" }))
            let deprecatedSudoServiceInfo = try XCTUnwrap(deprecated.first(where: { $0.name == "sudoService" }))
            XCTAssertEqual(deprecatedIdentityServiceInfo, identityServiceInfo)
            XCTAssertEqual(deprecatedSudoServiceInfo, sudoServiceInfo)
        }
        XCTAssertTrue(storageServiceMock.listObjectsCalled)
        XCTAssertTrue(storageServiceMock.getObjectCalled)
    }

    // MARK: - Helpers

    func mockConfigInfo(_ info: [ServiceCompatibilityInfo]) {
        let keysAndResults: [(String, Result<Data, URLError>)] = info.map {
            var versionMap: [String: Int] = [:]
            if let minVersion = $0.minSupportedVersion {
                versionMap["minVersion"] = minVersion
            }
            if let deprecatedVersion = $0.deprecatedVersion {
                versionMap["deprecated"] = deprecatedVersion
            }
            if let deprecationGrace = $0.deprecationGrace {
                versionMap["deprecationGrace"] = deprecationGrace.millisecondsSinceEpoch
            }
            let data = [$0.name: versionMap].toJSONData()
            return ("\($0.name).json", .success(data!))
        }
        storageServiceMock.listObjectsResult = .success(keysAndResults.map { $0.0 })
        storageServiceMock.getObjectResultMap = Dictionary(keysAndResults, uniquingKeysWith: { lhs, _ in lhs })
    }
}
