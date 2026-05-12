//
// Copyright © 2025 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@testable import SudoConfigManager

class SudoConfigManagerIntegrationTests: XCTestCase {
    
    // MARK: - Properties

    var configManager: SudoConfigManager!
    
    // MARK: - Lifecycle

    override func setUpWithError() throws {
        executionTimeAllowance = 10
        configManager = try XCTUnwrap(
            SudoConfigManagerFactory.instance.getConfigManager(name: SudoConfigManagerFactory.Constants.defaultConfigManagerName)
        )
    }

    // MARK: - Tests

    func test_validateConfig_willThrowErrorWithDeprecatedService() async throws {
        do {
            try await configManager.validateConfig()
            XCTFail("Validate should not succeed")
        } catch SudoConfigManagerError.compatibilityIssueFound(let incompatible, let deprecated) {
            XCTAssertTrue(incompatible.isEmpty)
            XCTAssertEqual(deprecated.map(\.name), ["vcService"])
        }
    }

    func test_getConfigSet_numericValuesAreNotConvertedToBooleans() throws {
        let configSet = try XCTUnwrap(configManager.getConfigSet(namespace: "identityService"))

        // Numeric 1 must remain Int, not be converted to Bool (true).
        let version = try XCTUnwrap(configSet["version"])
        XCTAssertTrue(version is Int, "Expected 'version' to be Int but got \(type(of: version)): \(version)")
        XCTAssertEqual(version as? Int, 1)
        XCTAssertFalse(version is Bool, "'version' with value 1 should not be represented as Bool")

        // Numeric 0 must also remain Int, not be converted to Bool (false).
        let additionalNumeric = try XCTUnwrap(configSet["additionalNumericTestValue"])
        XCTAssertTrue(additionalNumeric is Int, "Expected 'additionalNumericTestValue' to be Int but got \(type(of: additionalNumeric)): \(additionalNumeric)")
        XCTAssertEqual(additionalNumeric as? Int, 0)
        XCTAssertFalse(additionalNumeric is Bool, "'additionalNumericTestValue' with value 0 should not be represented as Bool")

        // Actual booleans must still be returned as Bool.
        let additionalBoolean = try XCTUnwrap(configSet["additionalBooleanTestValue"])
        XCTAssertTrue(additionalBoolean is Bool, "Expected 'additionalBooleanTestValue' to be Bool but got \(type(of: additionalBoolean)): \(additionalBoolean)")
        XCTAssertEqual(additionalBoolean as? Bool, true)
    }
}
