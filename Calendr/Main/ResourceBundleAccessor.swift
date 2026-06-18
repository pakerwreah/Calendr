import Foundation

#if SWIFT_MODULE_RESOURCE_BUNDLE_AVAILABLE

extension Bundle {
    /// This fixes the auto-generated `resource_bundle_accessor.swift`,
    /// which tries to access `Bundle.module` from root.
    ///
    /// Sandboxed apps need bundles to be in `Contents/Resources`.
    ///
    /// Call this at the absolute top of your launch sequence (e.g., in `main.swift` or app init).
    public static func swizzleResourceBundleAccessor() {
        let bundleClass: AnyClass = Bundle.self

        let originalSelector = #selector(Bundle.init(path:))
        let swizzledSelector = #selector(Bundle.init(sandbox_path:))

        guard
            let originalMethod = class_getInstanceMethod(bundleClass, originalSelector),
            let swizzledMethod = class_getInstanceMethod(bundleClass, swizzledSelector)
        else {
            return
        }

        method_exchangeImplementations(originalMethod, swizzledMethod)
    }

    @objc private convenience init?(sandbox_path path: String) {

        // Check if the unmodifiable 3rd-party code looked inside Contents/MacOS
        guard path.hasPrefix(Bundle.main.bundlePath), path.hasSuffix(".bundle") else {
            // Due to swizzling, calling 'init(sandbox_path:)' calls the original 'init(path:)'
            self.init(sandbox_path: path)
            return
        }

        // Transform the path to point safely into Contents/Resources/
        let correctedPath = path.replacing(
            Bundle.main.bundlePath, with: Bundle.main.resourcePath!)

        // Try initializing with the sandbox-approved path
        self.init(sandbox_path: correctedPath)
    }
}

#endif
