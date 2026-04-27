//
// Copyright © 2025 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import SudoLogging

/// An abstraction layer on top of AWS S3 SDK.
protocol StorageService: AnyObject, Sendable {

    /// Retrieves a S3 object.
    /// - Parameter key: S3 key associated with the object.
    /// - Returns: Retrieved object as `Data`.
    /// - Throws: `S3ClientError`
    func getObject(key: String) async throws -> Data

    /// Lists the content of the S3 bucket associated with this client.
    /// - Parameter completion: Completion handler to invoke to pass the
    /// - Returns: List of object keys.
    /// - Throws: `S3ClientError`
    func listObjects() async throws -> [String]
}

/// Default S3 client implementation.
final class DefaultStorageService: StorageService, Sendable {

    // MARK: - Properties

    /// The region the bucket is hosted in,
    let region: String
    
    /// The name of the bucket containing the service info JSON files.
    let bucket: String

    /// The URL session used to download the JSON files.
    let urlSession: URLSessionProtocol

    /// A closure that returns a utility for parsing the response from a list objects request.
    let resolveListObjectsParser: @Sendable () -> S3ListObjectsParser

    /// A logging instance.
    let logger: SudoLogging.Logger

    // MARK: - Lifecycle

    /// Initializes a `DefaultStorageService`.
    /// - Parameters:
    ///   - region: AWS region.
    ///   - bucket: Name of S3 bucket to be associated with this client.
    ///   - urlSession: The URL session used to download the JSON files.  Defaults to the shared singleton.
    ///   - resolveListObjectsParser: A closure that returns a utility for parsing the response from a
    ///   list objects request.  A default is provided.
    ///   - logger: A logging instance.  A default logging instance is provided.
    init(
        region: String,
        bucket: String,
        urlSession: URLSessionProtocol = URLSession.shared,
        resolveListObjectsParser: @escaping @Sendable () -> S3ListObjectsParser = { DefaultS3ListObjectsParser() },
        logger: Logger = Logger.sudoConfigManagerLogger
    ) {
        self.region = region
        self.bucket = bucket
        self.urlSession = urlSession
        self.resolveListObjectsParser = resolveListObjectsParser
        self.logger = logger
    }

    // MARK: - Conformance: S3Client

    func getObject(key: String) async throws -> Data {
        try await get(at: "https://\(bucket).s3.\(region).amazonaws.com/\(key)")
    }

    func listObjects() async throws -> [String] {
        let listData = try await get(at: "https://\(bucket).s3.\(region).amazonaws.com/?list-type=2")
        guard let keys = resolveListObjectsParser().parse(data: listData) else {
            throw URLError(.cannotParseResponse)
        }
        return keys
    }

    // MARK: - Helpers

    func get(at urlString: String) async throws -> Data {
        guard let url = URL(string: urlString) else {
            throw URLError(.badURL)
        }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        let (data, response) = try await urlSession.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        return data
    }
}
