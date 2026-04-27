//
// Copyright © 2025 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// Utility for parsing the XML response from a get request to list all items in a S3 bucket.
protocol S3ListObjectsParser: Sendable {
    
    /// Will parse the provided XML data and extract the "Key" values.
    /// - Parameter data: The XML data from a S3 list objects request.
    /// - Returns: An array of the extracted keys, or `nil` if an error was encountered.
    func parse(data: Data) -> [String]?
}

/// `@unchecked Sendable` is acceptable here because instances are created fresh
/// via the `resolveListObjectsParser` closure, used synchronously within a single
/// `parse()` call, and then discarded. The mutable state never crosses a concurrency boundary.
class DefaultS3ListObjectsParser: NSObject, S3ListObjectsParser, XMLParserDelegate, @unchecked Sendable {

    // MARK: - Properties

    /// Keeps track of the parsed object keys found in the XML response data.
    /// Member attribute so it is accessible to the callback
    var objectKeys: [String] = []

    /// Stores the name of the current element when a start tag is encountered.
    /// Member attribute so it is accessible to the callback
    var currentElement = ""

    // MARK: - Conformance: S3ListObjectsParser

    func parse(data: Data) -> [String]? {
        objectKeys = []
        currentElement = ""
        let parser = XMLParser(data: data)
        parser.delegate = self
        return parser.parse() ? objectKeys : nil
    }

    // MARK: - Conformance: XMLParserDelegate

    func parser(
        _ parser: XMLParser,
        didStartElement elementName: String,
        namespaceURI: String?,
        qualifiedName: String?,
        attributes attributeDict: [String: String] = [:]
    ) {
        currentElement = elementName
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        guard currentElement == "Key" else {
            return
        }
        let trimmedString = string.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedString.isEmpty {
            objectKeys.append(trimmedString)
        }
    }
}
