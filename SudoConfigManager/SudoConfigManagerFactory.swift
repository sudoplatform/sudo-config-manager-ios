//
// Copyright © 2025 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import SudoLogging

/// Creates and manages `SudoConfigManager` instances. By default it has 1 `SudoConfigManager`
/// instance named "default" that holds the config loaded from `sudoplatformconfig.json` file located in the app
/// bundle.
public class SudoConfigManagerFactory {

    // MARK: - Supplementary

    public enum Constants {

        /// The name by which the default config manager is registered.
        public static let defaultConfigManagerName = "default"

        /// The filename of the Sudo Platform configuration file in the main app bundle.
        public static let defaultConfigFileName = "sudoplatformconfig"

        /// The extension of the Sudo Platform configuration file in the main app bundle.
        public static let defaultConfigFileExtension = "json"
    }

    // MARK: - Properties: Public
    
    /// Shared singleton instance.
    public static let instance = SudoConfigManagerFactory()

    // MARK: - Properties: Internal
    
    /// Provides thread-safe access when registering and getting config managers.
    var configManagersLock = NSLock()
    
    /// The backing value for config managers.
    var _configManagers: [String: SudoConfigManager] = [:]

    /// Stores registered config managers keyed by name.
    var configManagers: [String: SudoConfigManager] {
        get {
            configManagersLock.withCriticalScope { _configManagers }
        }
        set {
            configManagersLock.withCriticalScope { _configManagers = newValue }
        }
    }

    // MARK: - Lifecycle

    init() {
        guard let url = Bundle.main.url(
            forResource: Constants.defaultConfigFileName,
            withExtension: Constants.defaultConfigFileExtension
        ) else {
            Logger.sudoConfigManagerLogger.error("Failed to register default config manager: Configuration file missing.")
            return
        }
        guard let data = try? Data(contentsOf: url), let config = data.toJSONObject() as? [String: Any] else {
            Logger.sudoConfigManagerLogger.error("Failed to register default config manager: Configuration file was not a valid JSON file.")
            return
        }
        registerConfigManager(name: Constants.defaultConfigManagerName, config: config)
    }

    // MARK: - Methods

    /// Registers a new `SudoConfigManager`of the specified name with the provided configuration.
    /// - Parameters:
    ///   - name: `SudoConfigManager` instance name.
    ///   - config: Configuration to load into the new `SudoConfigManager` instance.
    ///   - logger: Logger to use for the new `SudoConfigManager` instance..
    public func registerConfigManager(name: String, config: [String: Any], logger: Logger? = nil) {
        let logger = logger ?? Logger.sudoConfigManagerLogger
        guard
            let identityServiceConfig = config["identityService"] as? [String: Any],
            let region = identityServiceConfig["region"] as? String,
            let bucket = identityServiceConfig["serviceInfoBucket"] as? String
        else {
            logger.error("Failed to register config manager: config missing required values.")
            return
        }
        let storageService = DefaultStorageService(region: region, bucket: bucket)
        configManagers[name] = DefaultSudoConfigManager(config: config, storageService: storageService, logger: logger)
    }

    /// Returns the `SudoConfigManager` instance of the specified name.
    /// - Parameter name: `SudoConfigManager` instance name.
    /// - Returns: `SudoConfigManager` instance or nil if it is not found.
    public func getConfigManager(name: String) -> SudoConfigManager? {
        configManagers[name]
    }
}
