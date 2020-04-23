//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import SudoLogging

/// Protocol that encapsulates the APIs common to all configuration manager implementations.
/// A configuration manager is responsible for locating the platform configuration file (sudoplatformconfig.json)
/// in the app bundle, parsing it and returning the configuration set specific to a given namespace.
public protocol SudoConfigManager: class {

    /// Returns the configuration set under the specified namespace.
    ///
    /// - Parameter namespace: Configuration namespace.
    /// - Returns: Dictionary of configuration parameters or nil if the namespace does not exists.
    func getConfigSet(namespace: String) -> [String: Any]?

}

/// Default `SudoConfigManager` implementation.
public class DefaultSudoConfigManager: SudoConfigManager {

    public struct Constants {
        public static let defaultConfigFileName = "sudoplatformconfig"
        public static let defaultConfigFileExtension = "json"
    }

    private let logger: Logger

    private var config: [String: Any] = [:]

    /// Initializes a `DefaultSudoConfigManager` instance.`
    ///
    /// - Parameter logger: Logger used for logging.
    /// - Parameter configFileName: Configuration file name. Defaults to "sudoplatformconfig".
    /// - Parameter configFileExtension: Configuration file extension. Defaults to "json".
    public init?(logger: Logger? = nil, configFileName: String = Constants.defaultConfigFileName, configFileExtension: String = Constants.defaultConfigFileExtension) {
        self.logger = logger ?? Logger.sudoConfigManagerLogger

        guard let url = Bundle.main.url(forResource: configFileName, withExtension: configFileExtension) else {
            self.logger.error("Configuration file missing.")
            return nil
        }

        do {
            let data = try Data(contentsOf: url)
            guard let config = data.toJSONObject() as? [String: Any] else {
                self.logger.error("Configuration file was not a valid JSON file.")
                return
            }

            self.config = config

            self.logger.info("Loaded the config: \(config)")
        } catch let error {
            self.logger.error("Cannot read the configuration file: \(error).")
        }
    }

    public func getConfigSet(namespace: String) -> [String: Any]? {
        return self.config[namespace] as? [String: Any]
    }

}
