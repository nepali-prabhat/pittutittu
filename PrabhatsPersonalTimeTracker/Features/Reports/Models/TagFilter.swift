import Foundation

struct TagFilter: Identifiable, Hashable {
    let id = UUID()
    var path: [String]
    var isOptional: Bool
    
    init(path: [String], isOptional: Bool = false) {
        self.path = path
        self.isOptional = isOptional
    }
    
    // Creates a filter from a string like "foo > bar > baz"
    init(from string: String) {
        let components = string.components(separatedBy: " > ")
        self.path = components
        self.isOptional = false
    }
    
    // Creates a filter from a string like "foo > (bar|bat)"
    init(fromPattern pattern: String) {
        var components = pattern.components(separatedBy: " > ")
        if let lastComponent = components.last, lastComponent.hasPrefix("(") && lastComponent.hasSuffix(")") {
            let options = lastComponent.dropFirst().dropLast().components(separatedBy: "|")
            components.removeLast()
            components.append(contentsOf: options)
        }
        self.path = components
        self.isOptional = true
    }
    
    func matches(_ tagPath: String) -> Bool {
        let tagComponents = tagPath.components(separatedBy: " > ")
        
        if isOptional {
            // For optional filters, check if any of the optional paths match
            let basePath = Array(path.dropLast())
            let options = [path.last!]
            
            // Check if the base path matches
            guard basePath.count <= tagComponents.count else { return false }
            for (index, component) in basePath.enumerated() {
                if component != tagComponents[index] {
                    return false
                }
            }
            
            // Check if any of the options match
            return options.contains { option in
                tagComponents.contains(option)
            }
        } else {
            // For exact matches, check if the entire path matches
            guard path.count == tagComponents.count else { return false }
            for (index, component) in path.enumerated() {
                if component != tagComponents[index] {
                    return false
                }
            }
            return true
        }
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: TagFilter, rhs: TagFilter) -> Bool {
        lhs.id == rhs.id
    }
} 