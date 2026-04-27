//
// Copyright © 2025 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// A recursive `Sendable` representation of JSON-compatible values.
/// Used to wrap `[String: Any]` config dictionaries so they can be
/// stored safely in `Sendable` types.
enum SendableValue: Sendable {
    case string(String)
    case int(Int)
    case double(Double)
    case bool(Bool)
    case dictionary([String: SendableValue])
    case array([SendableValue])
    case null

    init(_ value: Any) {
        switch value {
        case let s as String: self = .string(s)
        case let b as Bool: self = .bool(b)
        case let i as Int: self = .int(i)
        case let d as Double: self = .double(d)
        case let dict as [String: Any]: self = .dictionary(dict.mapValues(SendableValue.init))
        case let arr as [Any]: self = .array(arr.map(SendableValue.init))
        default: self = .null
        }
    }

    var rawValue: Any {
        switch self {
        case .string(let s): return s
        case .int(let i): return i
        case .double(let d): return d
        case .bool(let b): return b
        case .dictionary(let d): return d.mapValues(\.rawValue)
        case .array(let a): return a.map(\.rawValue)
        case .null: return NSNull()
        }
    }
}
