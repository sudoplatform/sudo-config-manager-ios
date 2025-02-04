//
// Copyright © 2025 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
@testable import SudoConfigManager
import XCTest

class StorageServiceTests: XCTestCase {

    // MARK: - Properties

    var instanceUnderTest: DefaultStorageService!
    var s3ListObjectsParserMock: S3ListObjectsParserMock!
    var urlSessionMock: URLSessionMock!
    var region: String!
    var bucket: String!

    // MARK: - Lifecycle

    override func setUp() {
        region = UUID().uuidString
        bucket = UUID().uuidString
        urlSessionMock = URLSessionMock()
        let parserMock = S3ListObjectsParserMock()
        s3ListObjectsParserMock = parserMock
        instanceUnderTest = DefaultStorageService(
            region: region,
            bucket: bucket,
            urlSession: urlSessionMock,
            resolveListObjectsParser: {
                parserMock
            }
        )
    }

    // MARK: - Tests

    func test_get_willTriggerGetRequestWithCorrectUrl() async {
        // given
        let key = UUID().uuidString
        // when
        _ = try? await instanceUnderTest.getObject(key: key)
        // then
        XCTAssertTrue(urlSessionMock.dataForRequestCalled)
        XCTAssertEqual(urlSessionMock.dataForRequestParameters?.request.httpMethod, "GET")
        XCTAssertEqual(
            urlSessionMock.dataForRequestParameters?.request.url?.absoluteString,
            "https://\(bucket!).s3.\(region!).amazonaws.com/\(key)"
        )
    }

    func test_get_withValidResponse_willReturnData() async throws {
        // given
        let data = try XCTUnwrap(UUID().uuidString.data(using: .utf8))
        let url = try XCTUnwrap(URL(string: "test"))
        let response = try XCTUnwrap(HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: nil))
        urlSessionMock.dataForRequestResult = .success((data, response))
        // when
        let result = try await instanceUnderTest.getObject(key: UUID().uuidString)
        // then
        XCTAssertEqual(result, data)
    }

    func test_get_withInvalidResponseCode_willThrowError() async throws {
        // given
        let data = try XCTUnwrap(UUID().uuidString.data(using: .utf8))
        let url = try XCTUnwrap(URL(string: "test"))
        let response = try XCTUnwrap(HTTPURLResponse(url: url, statusCode: 404, httpVersion: nil, headerFields: nil))
        urlSessionMock.dataForRequestResult = .success((data, response))
        // when
        do {
            _ = try await instanceUnderTest.getObject(key: UUID().uuidString)
            XCTFail("Should not succeed")
        } catch let error as URLError {
            // then
            XCTAssertEqual(error.code, URLError.Code.badServerResponse)
        }
    }

    func test_get_withUrlSessionError_willThrowError() async throws {
        // given
        let urlError = URLError(.cancelled)
        urlSessionMock.dataForRequestResult = .failure(urlError)
        // when
        do {
            _ = try await instanceUnderTest.getObject(key: UUID().uuidString)
            XCTFail("Should not succeed")
        } catch let error as URLError {
            // then
            XCTAssertEqual(error.code, .cancelled)
        }
    }

    func test_listObjects_willTriggerGetRequestWithCorrectUrl() async {
        // when
        _ = try? await instanceUnderTest.listObjects()
        // then
        XCTAssertTrue(urlSessionMock.dataForRequestCalled)
        XCTAssertEqual(urlSessionMock.dataForRequestParameters?.request.httpMethod, "GET")
        XCTAssertEqual(
            urlSessionMock.dataForRequestParameters?.request.url?.absoluteString,
            "https://\(bucket!).s3.\(region!).amazonaws.com/?list-type=2"
        )
    }

    func test_listObjects_withValidResponse_willAttemptToParseXmlData() async throws {
        // given
        let data = try XCTUnwrap(UUID().uuidString.data(using: .utf8))
        let url = try XCTUnwrap(URL(string: "test"))
        let response = try XCTUnwrap(HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: nil))
        urlSessionMock.dataForRequestResult = .success((data, response))
        // when
        _ = try? await instanceUnderTest.listObjects()
        // then
        XCTAssertTrue(s3ListObjectsParserMock.parseCalled)
        XCTAssertEqual(s3ListObjectsParserMock.parseParameters?.data, data)
    }

    func test_listObjects_withInvalidResponseCode_willThrowError() async throws {
        // given
        let data = try XCTUnwrap(UUID().uuidString.data(using: .utf8))
        let url = try XCTUnwrap(URL(string: "test"))
        let response = try XCTUnwrap(HTTPURLResponse(url: url, statusCode: 404, httpVersion: nil, headerFields: nil))
        urlSessionMock.dataForRequestResult = .success((data, response))
        // when
        do {
            _ = try await instanceUnderTest.listObjects()
            XCTFail("Should not succeed")
        } catch let error as URLError {
            // then
            XCTAssertEqual(error.code, URLError.Code.badServerResponse)
        }
    }

    func test_listObjects_withUrlSessionError_willThrowError() async throws {
        // given
        let urlError = URLError(.cancelled)
        urlSessionMock.dataForRequestResult = .failure(urlError)
        // when
        do {
            _ = try await instanceUnderTest.listObjects()
            XCTFail("Should not succeed")
        } catch let error as URLError {
            // then
            XCTAssertEqual(error.code, .cancelled)
        }
    }

    func test_listObjects_withXmlParseSuccess_willReturnListOfKeys() async throws {
        // given
        let data = try XCTUnwrap(UUID().uuidString.data(using: .utf8))
        let url = try XCTUnwrap(URL(string: "test"))
        let response = try XCTUnwrap(HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: nil))
        urlSessionMock.dataForRequestResult = .success((data, response))
        let keys: [String] = [UUID().uuidString, UUID().uuidString]
        s3ListObjectsParserMock.parseResult = keys
        // when
        let result = try await instanceUnderTest.listObjects()
        // then
        XCTAssertEqual(result, keys)
    }

    func test_listObjects_withXmlParseFailure_willThrowError() async throws {
        // given
        let data = try XCTUnwrap(UUID().uuidString.data(using: .utf8))
        let url = try XCTUnwrap(URL(string: "test"))
        let response = try XCTUnwrap(HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: nil))
        urlSessionMock.dataForRequestResult = .success((data, response))
        s3ListObjectsParserMock.parseResult = nil
        // when
        do {
            _ = try await instanceUnderTest.listObjects()
        } catch let error as URLError {
            // then
            XCTAssertEqual(error.code, URLError.Code.cannotParseResponse)
        }
    }
}
