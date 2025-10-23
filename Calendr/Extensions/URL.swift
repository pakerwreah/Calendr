//
//  URL.swift
//  Calendr
//
//  Created by Paker on 04/09/2024.
//

import Foundation

extension URL {
    /// Returns the relative path from the given base URL if the URL's path starts with the base URL's path.
    func relativePath(from base: URL) -> String? {
        // Ensure both URLs share the same scheme and host.
        guard self.scheme == base.scheme, self.host == base.host else { return nil }

        let baseComponents = base.pathComponents
        let targetComponents = self.pathComponents

        // Check if the target URL's path starts with the base URL's path.
        guard targetComponents.count >= baseComponents.count else { return nil }
        for (index, component) in baseComponents.enumerated() {
            if targetComponents[index] != component {
                return nil
            }
        }

        // Remove the base components to get the relative path.
        let relativeComponents = targetComponents.dropFirst(baseComponents.count)
        return relativeComponents.joined(separator: "/")
    }
}
