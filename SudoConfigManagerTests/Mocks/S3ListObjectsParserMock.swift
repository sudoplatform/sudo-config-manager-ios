//
// Copyright © 2025 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
@testable import SudoConfigManager

class S3ListObjectsParserMock: S3ListObjectsParser, @unchecked Sendable {

    var parseCalled = false
    var parseCallCount = 0
    var parseParameters: (data: Data, Void)?
    var parseParameterList: [(data: Data, Void)] = []
    var parseResult: [String]?

    func parse(data: Data) -> [String]? {
        parseCalled = true
        parseCallCount += 1
        parseParameters = (data, ())
        parseParameterList.append((data, ()))
        return parseResult
    }
}
