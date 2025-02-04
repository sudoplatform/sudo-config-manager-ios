//
// Copyright © 2025 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// Result returned by `validateConfig` API if an incompatible client config is found
/// when compared to the deployed backend services.
public struct ServiceCompatibilityInfo: Equatable {

    // MARK: - Properties

    /// Name of the service associated with the compatibility info. This matches one of
    /// the service name present in sudoplatformconfig.json.
    public let name: String

    /// Version of the service config present in sudoplatformconfig.json. It defaults
    /// to 1 if not present.
    public let configVersion: Int

    /// Minimum supported service config version currently supported by the backend.
    public let minSupportedVersion: Int?

    /// Any service config version less than or equal to this version is considered
    /// deprecated and the backend may remove the support for those versions after
    /// a grace period.
    public let deprecatedVersion: Int?

    /// After this time any deprecated service config versions will no longer be compatible
    /// with the backend. It is recommended to warn the user prior to the deprecation
    /// grace.
    public let deprecationGrace: Date?

    // MARK: - Lifecycle

    init(name: String, configVersion: Int, minSupportedVersion: Int? = nil, deprecatedVersion: Int? = nil, deprecationGrace: Date? = nil) {
        self.name = name
        self.configVersion = configVersion
        self.minSupportedVersion = minSupportedVersion
        self.deprecatedVersion = deprecatedVersion
        self.deprecationGrace = deprecationGrace
    }
}
