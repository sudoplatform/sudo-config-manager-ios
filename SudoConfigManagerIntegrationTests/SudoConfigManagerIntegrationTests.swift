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
}
