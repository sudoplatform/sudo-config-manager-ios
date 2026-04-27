//
// Copyright © 2025 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
@testable import SudoConfigManager

class StorageServiceMock: StorageService, @unchecked Sendable {

    var getObjectCalled: Bool = false
    var getObjectResult: Result<Data, URLError> = .failure(URLError(.dataNotAllowed))
    var getObjectResultMap: [String: Result<Data, URLError>] = [:]

    func getObject(key: String) async throws -> Data {
        getObjectCalled = true
        if let result = getObjectResultMap[key] {
            return try result.get()
        }
        return try getObjectResult.get()
    }

    var listObjectsCalled: Bool = false
    var listObjectsResult: Result<[String], URLError> = .failure(URLError(.dataNotAllowed))

    func listObjects() async throws -> [String] {
        listObjectsCalled = true
        return try listObjectsResult.get()
    }
}
