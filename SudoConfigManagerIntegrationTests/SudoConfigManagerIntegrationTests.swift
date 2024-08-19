//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@testable import SudoConfigManager

class SudoConfigManagerIntegrationTests: XCTestCase {
    
    var configManager: SudoConfigManager!
    
    override func setUpWithError() throws {
        guard let configManager = DefaultSudoConfigManager(bundle: Bundle(for: type(of: self))) else {
            return XCTFail("Failed to retrieve config manager.")
        }
        
        self.configManager = configManager
    }
    
    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    func testValidateConfig() async throws {
        do {
            try await self.configManager.validateConfig()
        } catch SudoConfigManagerError.compatibilityIssueFound(let incompatible, let deprecated) {
            if !incompatible.isEmpty {
                print("\n# Incompatible is not empty: (\(incompatible)")
            }
            XCTAssertTrue(incompatible.isEmpty)
            XCTAssertFalse(deprecated.isEmpty)
        } catch {
            XCTFail("Failed to validate config: \(error)")
        }
    }
    
}
