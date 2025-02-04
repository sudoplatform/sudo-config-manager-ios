//
// Copyright © 2025 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// List of errors returned `SudoConfigManger` implementations.
public enum SudoConfigManagerError: Error {

    /// Indicates that a compatibility issue was found against the currently deployed set of
    /// backend services.
    ///  - incompatible: List of incompatible services. The client must be upgraded
    /// to the latest version in order to use these services.
    ///  - deprecated: List of services that will be made incompatible with the
    /// current version of the client. The users should be warned
    /// that after the specified grace period these services will
    /// be made incompatible.
    case compatibilityIssueFound(incompatible: [ServiceCompatibilityInfo], deprecated: [ServiceCompatibilityInfo])

    /// Backed service is temporarily unavailable due to network or service availability issues.
    case serviceError(cause: Error)

    /// Indicates that a fatal error occurred. This could be due to coding error, out-of-memory
    /// condition or other conditions that is beyond control of `S3Client` implementation.
    case fatalError(description: String)
}
