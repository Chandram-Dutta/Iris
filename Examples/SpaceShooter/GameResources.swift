import Foundation

enum GameResources {
    static func imagePath(_ named: String) -> String {
        // Try Bundle.module first (SPM resources)
        if let url = Bundle.module.url(
            forResource: named, withExtension: nil, subdirectory: "Resources")
        {
            return url.path
        }
        // Try without subdirectory (flattened resources)
        if let url = Bundle.module.url(
            forResource: (named as NSString).deletingPathExtension,
            withExtension: (named as NSString).pathExtension)
        {
            return url.path
        }
        // Fallback to relative path
        return "Resources/\(named)"
    }
}
