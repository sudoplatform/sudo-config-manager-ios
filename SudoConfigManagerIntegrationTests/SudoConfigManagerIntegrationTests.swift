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
    
    func testValidateConfig() throws {
        let expectation = self.expectation(description: "")
        do {
            try self.configManager.validateConfig { (result) in
                defer {
                    expectation.fulfill()
                }
                
                switch result {
                case let .failure(cause):
                    switch cause {
                    case SudoConfigManagerError.compatibilityIssueFound(let incompatible, let deprecated):
                        XCTAssertTrue(incompatible.isEmpty)
                        XCTAssertFalse(deprecated.isEmpty)
                    default:
                        XCTFail("Expected error not returned.")
                    }
                case .success:
                    XCTFail("Unexpected success result returned.")
                }
            }
        } catch {
            XCTFail("Failed to validate config: \(error)")
        }
        self.wait(for: [expectation], timeout: 20)
    }
    
}
