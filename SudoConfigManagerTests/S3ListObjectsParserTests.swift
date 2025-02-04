//
// Copyright © 2025 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
@testable import SudoConfigManager
import XCTest

class S3ListObjectsParserTests: XCTestCase {

    // MARK: - Properties

    var instanceUnderTest: S3ListObjectsParser!

    // MARK: - Lifecycle

    override func setUp() {
        instanceUnderTest = DefaultS3ListObjectsParser()
    }

    // MARK: - Tests

    func test_withValidXmlData_willExtractKeys() throws {
        // given
        let xmlString = """
        <ListBucketResult>
        <Name>
        ids-data-gc-dev-serviceinfobucketcf6c8b79-msluppq8sxow
        </Name>
        <Prefix/>
        <Marker/>
        <MaxKeys>1000</MaxKeys>
        <IsTruncated>false</IsTruncated>
        <Contents>
        <Key>identityService.json</Key>
        <LastModified>2024-11-07T06:31:22.000Z</LastModified>
        <ETag>"9012c50b4d1aeca7443e44713ff6594f"</ETag>
        <Size>84</Size>
        <StorageClass>STANDARD</StorageClass>
        </Contents>
        <Contents>
        <Key>vcService.json</Key>
        <LastModified>2024-10-14T05:48:26.000Z</LastModified>
        <ETag>"831feeac8d69c8b5ebedce05f798c7e1"</ETag>
        <Size>78</Size>
        <StorageClass>STANDARD</StorageClass>
        </Contents>
        </ListBucketResult>
        """
        let xmlData = try XCTUnwrap(xmlString.data(using: .utf8))
        // when
        let keys = instanceUnderTest.parse(data: xmlData)
        // then
        XCTAssertEqual(keys, ["identityService.json", "vcService.json"])
    }

    func test_withInvalidData_willReturnNil() throws {
        // given
        let xmlData = try XCTUnwrap(UUID().uuidString.data(using: .utf8))
        // when
        let keys = instanceUnderTest.parse(data: xmlData)
        // then
        XCTAssertNil(keys)
    }

}
