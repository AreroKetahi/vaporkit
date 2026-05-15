//
//  StaticCheckSeverity.swift
//  vaporkit
//
//  Created by Arkivili Collindort on 15/05/2026
//

/// Controls how syntax-only static checks are silenced.
///
/// Use `StaticCheckSeverity` with ``DisableParameterCheck(as:)`` or ``Bypass(as:_:)`` to
/// choose whether static route-parameter diagnostics should be fully disabled
/// or downgraded to warnings.
public enum StaticCheckSeverity {
    /// Silences static-check errors and warnings.
    ///
    /// This is the default behavior for explicit check bypasses.
    case error

    /// Downgrades static-check errors to warnings and silences lower-severity warnings.
    ///
    /// Use this mode when a route should still surface likely mismatches without
    /// failing compilation.
    case warning
}
