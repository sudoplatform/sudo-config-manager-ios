//
// Copyright © 2022 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import SudoLogging
@testable import SudoConfigManager

class MyS3Client: S3Client {
    
    var data: [String: Data] = [:]
    var keys: [String] = []
    var error: Error?
    var getObjectCalled: Bool = false
    var listObjectsCalled: Bool = false
    
    func getObject(key: String) async throws -> Data {
        self.getObjectCalled = true
        if let error = self.error {
            throw error
        } else {
            if let data = data[key] {
                return data
            } else {
                throw SudoConfigManagerError.fatalError(description: "Bad test setup.")
            }
        }
    }
    
    func listObjects() async throws -> [String] {
        self.listObjectsCalled = true
        if let error = self.error {
            throw error
        } else {
            return self.keys
        }
    }
    
}

class SudoConfigManagerTests: XCTestCase {

    override func setUp() {
    }

    override func tearDown() {
    }

    func testConfigManager() {
        let configManager = DefaultSudoConfigManager()
        let apiConfig = configManager?.getConfigSet(namespace: "apiService")
        XCTAssertNotNil(apiConfig)
        XCTAssertEqual("https://mysudo-dev-api.anonyome.sudoplatform.com/graphql", apiConfig?["apiUrl"] as? String)
        XCTAssertEqual("us-east-1", apiConfig?["region"] as? String)
    }

    func testConfigManagerFactory() {
        var configManager = SudoConfigManagerFactory.instance.getConfigManager(name: SudoConfigManagerFactory.Constants.defaultConfigManagerName)
        let apiConfig = configManager?.getConfigSet(namespace: "apiService")
        XCTAssertNotNil(apiConfig)
        XCTAssertEqual("https://mysudo-dev-api.anonyome.sudoplatform.com/graphql", apiConfig?["apiUrl"] as? String)
        XCTAssertEqual("us-east-1", apiConfig?["region"] as? String)

        SudoConfigManagerFactory.instance.registerConfigManager(name: "dummy_config", config: ["dummy_namespace": ["dummy_name": "dummy_value"]])
        configManager = SudoConfigManagerFactory.instance.getConfigManager(name: "dummy_config")
        let config = configManager?.getConfigSet(namespace: "dummy_namespace")
        XCTAssertEqual("dummy_value", config?["dummy_name"] as? String)
    }
    
    func testValidateConfig() async {
        let s3Client = MyS3Client()
        guard let configManager = DefaultSudoConfigManager(s3Client: s3Client) else {
            return XCTFail("Failed to initialize config manager.")
        }
        
        // If there's no service info doc the config should validate successfully.
        do {
            try await configManager.validateConfig()
        } catch {
            XCTFail("Failed to validate config: \(error)")
        }
        
        XCTAssertTrue(s3Client.listObjectsCalled)
        XCTAssertFalse(s3Client.getObjectCalled)
        
        // If service info docs exists but client config does not include
        // those services then the config should validate sucessfully.
        s3Client.listObjectsCalled = false
        s3Client.keys = ["telephonyService.json", "vcService.json"]
        do {
            try await configManager.validateConfig()
        } catch {
            XCTFail("Failed to validate config: \(error)")
        }
        
        XCTAssertTrue(s3Client.listObjectsCalled)
        XCTAssertFalse(s3Client.getObjectCalled)
        
        // If S3 bucket has non JSON files only then the config should validate
        // successfully.
        s3Client.listObjectsCalled = false
        s3Client.keys = ["identityService.txt", "sudoService"]
        do {
            try await configManager.validateConfig()
        } catch {
            XCTFail("Failed to validate config: \(error)")
        }
        
        XCTAssertTrue(s3Client.listObjectsCalled)
        XCTAssertFalse(s3Client.getObjectCalled)

        // If service info docs have lower or same minimum version than the
        // client config version then the config should validate successfully.
        s3Client.listObjectsCalled = false
        s3Client.keys = ["identityService.json", "sudoService.json"]
        s3Client.data["identityService.json"] = [
            "identityService": [
                "minVersion": 1
            ]
        ].toJSONData()!
        s3Client.data["sudoService.json"] = [
            "sudoService": [
                "minVersion": 2
            ]
        ].toJSONData()!
        
        do {
            try await configManager.validateConfig()
        } catch {
            XCTFail("Failed to validate config: \(error)")
        }
        
        XCTAssertTrue(s3Client.listObjectsCalled)
        XCTAssertTrue(s3Client.getObjectCalled)
        
        // If service info docs has higher minimum version than the client
        // config version then the config should fail to validate.
        s3Client.listObjectsCalled = false
        s3Client.getObjectCalled = false
        s3Client.keys = ["identityService.json", "sudoService.json"]
        s3Client.data["identityService.json"] = [
            "identityService": [
                "minVersion": 2
            ]
        ].toJSONData()!
        s3Client.data["sudoService.json"] = [
            "sudoService": [
                "minVersion": 2
            ]
        ].toJSONData()!
        
        do {
            try await configManager.validateConfig()
        } catch SudoConfigManagerError.compatibilityIssueFound(let incompatible, let deprecated) {
            XCTAssertEqual(1, incompatible.count)
            XCTAssertEqual(0, deprecated.count)
            let compatibilityInfo = incompatible.first
            XCTAssertNotNil(compatibilityInfo)
            XCTAssertEqual("identityService", compatibilityInfo?.name)
            XCTAssertEqual(1, compatibilityInfo?.configVersion)
            XCTAssertEqual(2, compatibilityInfo?.minSupportedVersion)
            XCTAssertNil(compatibilityInfo?.deprecatedVersion)
            XCTAssertNil(compatibilityInfo?.deprecationGrace)
        } catch {
            XCTFail("Failed to validate config: \(error)")
        }
        
        XCTAssertTrue(s3Client.listObjectsCalled)
        XCTAssertTrue(s3Client.getObjectCalled)
        
        s3Client.listObjectsCalled = false
        s3Client.getObjectCalled = false
        s3Client.keys = ["identityService.json", "sudoService.json"]
        s3Client.data["identityService.json"] = [
            "identityService": [
                "minVersion": 2
            ]
        ].toJSONData()!
        s3Client.data["sudoService.json"] = [
            "sudoService": [
                "minVersion": 3
            ]
        ].toJSONData()!
        
        do {
            try await configManager.validateConfig()
        } catch SudoConfigManagerError.compatibilityIssueFound(let incompatible, let deprecated) {
            XCTAssertEqual(2, incompatible.count)
            XCTAssertEqual(0, deprecated.count)
            var found = 0
            for compatibilityInfo in incompatible {
                if compatibilityInfo.name == "identityService",
                   compatibilityInfo.configVersion == 1,
                   compatibilityInfo.minSupportedVersion == 2,
                   compatibilityInfo.deprecatedVersion == nil,
                   compatibilityInfo.deprecationGrace == nil {
                    found += 1
                } else if compatibilityInfo.name == "sudoService",
                   compatibilityInfo.configVersion == 2,
                   compatibilityInfo.minSupportedVersion == 3,
                   compatibilityInfo.deprecatedVersion == nil,
                   compatibilityInfo.deprecationGrace == nil {
                    found += 1
                }
            }
            XCTAssertEqual(2, found)
        } catch {
            XCTFail("Failed to validate config: \(error)")
        }
        
        XCTAssertTrue(s3Client.listObjectsCalled)
        XCTAssertTrue(s3Client.getObjectCalled)
        
        // If service info docs have lower deprecated version than the client
        // config version then the config should validate successfully.
        s3Client.listObjectsCalled = false
        s3Client.keys = ["identityService.json", "sudoService.json"]
        s3Client.data["identityService.json"] = [
            "identityService": [
                "minVersion": 1
            ]
        ].toJSONData()!
        s3Client.data["sudoService.json"] = [
            "sudoService": [
                "deprecated": 1
            ]
        ].toJSONData()!
        
        do {
            try await configManager.validateConfig()
        } catch {
            XCTFail("Failed to validate config: \(error)")
        }
        
        XCTAssertTrue(s3Client.listObjectsCalled)
        XCTAssertTrue(s3Client.getObjectCalled)
        
        // If service info docs have same or higher deprecated version than the
        // client config version then the config should fail to validate.
        s3Client.listObjectsCalled = false
        s3Client.keys = ["identityService.json", "sudoService.json"]
        s3Client.data["identityService.json"] = [
            "identityService": [
                "deprecated": 1,
                "deprecationGrace": 1000
            ]
        ].toJSONData()!
        s3Client.data["sudoService.json"] = [
            "sudoService": [
                "minVersion": 1,
                "deprecated": 3,
                "deprecationGrace": 2000
            ]
        ].toJSONData()!
        
        do {
            try await configManager.validateConfig()
        } catch SudoConfigManagerError.compatibilityIssueFound(let incompatible, let deprecated) {
            XCTAssertEqual(0, incompatible.count)
            XCTAssertEqual(2, deprecated.count)
            var found = 0
            for compatibilityInfo in deprecated {
                if compatibilityInfo.name == "identityService",
                   compatibilityInfo.configVersion == 1,
                   compatibilityInfo.deprecatedVersion == 1,
                   compatibilityInfo.deprecationGrace == Date(timeIntervalSince1970: 1) {
                    found += 1
                } else if compatibilityInfo.name == "sudoService",
                   compatibilityInfo.configVersion == 2,
                   compatibilityInfo.minSupportedVersion == 1,
                   compatibilityInfo.deprecatedVersion == 3,
                   compatibilityInfo.deprecationGrace == Date(timeIntervalSince1970: 2) {
                    found += 1
                }
            }
            XCTAssertEqual(2, found)
        } catch {
            XCTFail("Failed to validate config: \(error)")
        }
        
        XCTAssertTrue(s3Client.listObjectsCalled)
        XCTAssertTrue(s3Client.getObjectCalled)
    }

}
