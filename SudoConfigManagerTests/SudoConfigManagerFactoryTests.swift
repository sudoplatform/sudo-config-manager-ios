//
// Copyright © 2025 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
@testable import SudoConfigManager
import XCTest

class SudoConfigManagerFactoryTests: XCTestCase {

    // MARK: - Properties

    var instanceUnderTest: SudoConfigManagerFactory!

    // MARK: - Lifecycle

    override func setUp() {
        instanceUnderTest = SudoConfigManagerFactory.instance
    }

    // MARK: - Tests: Init

    func test_init_willRegisterDefaultSudoConfigManager() {
        // then
        let manager = instanceUnderTest.getConfigManager(name: SudoConfigManagerFactory.Constants.defaultConfigManagerName)
        XCTAssertNotNil(manager)
    }

    // MARK: - Tests: Get Config Manager

    func test_getConfigManager_willReturnRegisteredInstance() {
        // given
        let dummyConfig: [String: Any] = [
            "identityService": [
                "region": "dummy_region",
                "serviceInfoBucket": "dummy_service_info_bucket"
            ],
            "dummy_namespace": [
                "dummy_key": "dummy_value"
            ]
        ]
        let name = "dummy_name"
        instanceUnderTest.registerConfigManager(name: name, config: dummyConfig)
        // when
        let result = instanceUnderTest.getConfigManager(name: name)
        // then
        let config = result?.getConfigSet(namespace: "dummy_namespace")
        XCTAssertEqual("dummy_value", config?["dummy_key"] as? String)
    }
}
