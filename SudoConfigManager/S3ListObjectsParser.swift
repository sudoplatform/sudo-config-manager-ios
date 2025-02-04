//
// Copyright © 2025 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// Utility for parsing the XML response from a get request to list all items in a S3 bucket.
protocol S3ListObjectsParser {
    
    /// Will parse the provided XML data and extract the "Key" values.
    /// - Parameter data: The XML data from a S3 list objects request.
    /// - Returns: An array of the extracted keys, or `nil` if an error was encountered.
    func parse(data: Data) -> [String]?
}

class DefaultS3ListObjectsParser: NSObject, S3ListObjectsParser, XMLParserDelegate {

    // MARK: - Properties

    /// Keeps track of the parsed object keys found in the XML response data.
    var objectKeys: [String] = []

    /// Stores the name of the current element when a start tag is encountered.
    var currentElement = ""

    // MARK: - Conformance: S3ListObjectsParser

    func parse(data: Data) -> [String]? {
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
