//
// Copyright © 2025 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// A `Sendable` wrapper around the parsed `sudoplatformconfig.json` dictionary.
/// Converts `[String: Any]` into a recursive `SendableValue` tree at init time,
/// preserving the existing public API that returns `[String: Any]?`.
struct SudoConfigManagerConfig: Sendable {

    // MARK: - Properties

    private let storage: [String: SendableValue]

    // MARK: - Lifecycle

    init(_ dictionary: [String: Any]) {
        storage = dictionary.mapValues(SendableValue.init)
    }

    // MARK: - Methods

    /// Returns the keys at the top level of the config.
    var keys: Dictionary<String, SendableValue>.Keys { storage.keys }

    /// Returns the config set for the given namespace as a plain dictionary.
    subscript(namespace: String) -> [String: Any]? {
        guard case .dictionary(let dict) = storage[namespace] else { return nil }
        return dict.mapValues(\.rawValue)
    }
}
