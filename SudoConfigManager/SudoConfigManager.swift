//
// Copyright © 2025 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import SudoLogging

/// Protocol that encapsulates the APIs common to all configuration manager implementations.
/// A configuration manager is responsible for locating the platform configuration file (sudoplatformconfig.json)
/// in the app bundle, parsing it and returning the configuration set specific to a given namespace.
/// Use the `SudoConfigManagerFactory` to resolve an instance.
public protocol SudoConfigManager: AnyObject {

    /// Returns the configuration set under the specified namespace.
    /// - Parameter namespace: Configuration namespace.
    /// - Returns: Dictionary of configuration parameters or nil if the namespace does not exists.
    func getConfigSet(namespace: String) -> [String: Any]?
    
    /// Validates the client configuration (sudoplatformconfig.json) against the currently deployed set of
    /// backend services. If the client configuration is valid, i.e. the client is compatible will all deployed
    /// backend services, then the call will complete without an error. If any part of the client configuration
    /// is incompatible then a detailed information on the incompatible services will be included in the
    /// `SudoConfigManagerError.compatibilityIssueFound` error thrown.
    func validateConfig() async throws
}

/// Default `SudoConfigManager` implementation.
class DefaultSudoConfigManager: SudoConfigManager {

    // MARK: - Properties

    /// Contains the service version numbers which are validated by this manager.
    let config: [String: Any]

    /// The utility responsible for downloading the service compatibility information.
    let storageService: StorageService

    /// A logging instance.
    let logger: Logger

    // MARK: - Lifecycle

    /// Initializes a `DefaultSudoConfigManager` instance.`
    /// - Parameters:
    ///   - config: The configuration data containing service info.
    ///   - storageService: The service for fetching the service compatibility info.
    ///   - logger: A logging instance.
    init(config: [String: Any], storageService: StorageService, logger: Logger) {
        self.config = config
        self.storageService = storageService
        self.logger = logger
    }

    // MARK: - Conformance: SudoConfigManager

    public func getConfigSet(namespace: String) -> [String: Any]? {
        config[namespace] as? [String: Any]
    }

    public func validateConfig() async throws {
        let keys = try await storageService.listObjects()

        // Only fetch the service info docs for the services that are present in client config
        // to minimize the network calls.
        let configKeys = Set(config.keys.map { "\($0).json"} )
        let keysToFetch = keys.filter { configKeys.contains($0) }
        return try await withThrowingTaskGroup(of: ServiceCompatibilityInfo?.self) { taskGroup in
            for key in keysToFetch {
                taskGroup.addTask { try await self.getCompatibilityInfo(key: key) }
            }
            var incompatible: [ServiceCompatibilityInfo] = []
            var deprecated: [ServiceCompatibilityInfo] = []
            for try await result in taskGroup {
                guard let compatibilityInfo = result else {
                    continue
                }
                // If the service config in `sudoplatformconfig.json` is less than the
                // minimum supported version then the client is incompatible.
                if compatibilityInfo.configVersion < (compatibilityInfo.minSupportedVersion ?? 0) {
                    incompatible.append(compatibilityInfo)
                }
                // If the service config is less than or equal to the deprecated version
                // then it will be made incompatible after the deprecation grace.
                if compatibilityInfo.configVersion <= (compatibilityInfo.deprecatedVersion ?? 0) {
                    deprecated.append(compatibilityInfo)
                }
            }
            guard incompatible.isEmpty, deprecated.isEmpty else {
                throw SudoConfigManagerError.compatibilityIssueFound(incompatible: incompatible, deprecated: deprecated)
            }
        }
    }

    // MARK: - Helpers

    func getCompatibilityInfo(key: String) async throws -> ServiceCompatibilityInfo? {
        let data = try await storageService.getObject(key: key)
        guard let jsonObject = data.toJSONObject() as? [String: Any] else {
            throw SudoConfigManagerError.fatalError(description: "Result did not contain JSON data.")
        }
        guard
            let serviceName = jsonObject.keys.first,
            let serviceInfo = jsonObject[serviceName] as? [String: Any],
            let serviceConfig = config[serviceName] as? [String: Any]
        else {
            return nil
        }
        return ServiceCompatibilityInfo(
            name: serviceName,
            configVersion: serviceConfig["version"] as? Int ?? 1,
            minSupportedVersion: serviceInfo["minVersion"] as? Int,
            deprecatedVersion: serviceInfo["deprecated"] as? Int,
            deprecationGrace: (serviceInfo["deprecationGrace"] as? Int).map { Date(millisecondsSinceEpoch: Double($0)) }
        )
    }
}
