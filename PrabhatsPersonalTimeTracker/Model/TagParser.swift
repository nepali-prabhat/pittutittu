import Foundation

class TagParser {
    private class TagNode {
        var tag: Tag
        let indent: Int
        var children: [TagNode]
        
        init(tag: Tag, indent: Int) {
            self.tag = tag
            self.indent = indent
            self.children = []
        }
    }
    
    static func parse(_ string: String) -> [Tag] {
        var rootNodes: [TagNode] = []
        var parentStack: [TagNode] = []
        
        let lines = string.components(separatedBy: .newlines)
            .filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
        
        print("Parsing \(lines.count) lines")
        
        // Keep track of siblings at each indent level
        var siblingCountByIndent: [Int: Int] = [:]
        
        for line in lines {
            let indent = line.prefix(while: { $0 == " " }).count / 2
            let content = line.trimmingCharacters(in: .whitespaces)
            
            // Parse name, uuid, and color
            let (name, uuid, color) = parseTagContent(content)
            
            print("Processing line: '\(line)'")
            print("  Indent: \(indent)")
            print("  Name: \(name)")
            print("  UUID: \(uuid)")
            print("  Color: \(color)")
            
            // Get the current index for this indent level
            let currentIndex = siblingCountByIndent[indent] ?? 0
            
            let tag = Tag(
                id: uuid,
                name: name,
                color: color,
                index: currentIndex
            )
            
            // Increment the sibling count for this indent level
            siblingCountByIndent[indent] = currentIndex + 1
            
            let node = TagNode(tag: tag, indent: indent)
            
            // Handle indentation and parent-child relationships
            while let lastParent = parentStack.last, lastParent.indent >= indent {
                print("  Popping parent with indent \(lastParent.indent)")
                parentStack.removeLast()
                
                // Clear sibling counts for deeper levels
                siblingCountByIndent = siblingCountByIndent.filter { $0.key <= indent }
            }
            
            if let parent = parentStack.last {
                print("  Adding as child to parent: \(parent.tag.name)")
                parent.children.append(node)
            } else {
                print("  Adding as root tag")
                rootNodes.append(node)
            }
            
            // Push the current tag onto the stack
            parentStack.append(node)
            print("  Current stack size: \(parentStack.count)")
        }
        
        // Convert the node hierarchy to tag hierarchy
        func convertNodeToTag(_ node: TagNode) -> Tag {
            var tag = node.tag
            tag.children = node.children.map { convertNodeToTag($0) }
            return tag
        }
        
        let tags = rootNodes.map { convertNodeToTag($0) }
        
        print("Final tag count: \(tags.count)")
        for tag in tags {
            printTag(tag, indent: 0)
        }
        
        return tags
    }
    
    private static func printTag(_ tag: Tag, indent: Int) {
        let indentStr = String(repeating: "  ", count: indent)
        print("\(indentStr)Tag: \(tag.name) (children: \(tag.children.count))")
        for child in tag.children {
            printTag(child, indent: indent + 1)
        }
    }
    
    private static func parseTagContent(_ content: String) -> (name: String, uuid: UUID, color: CatppuccinFrappe) {
        let pattern = #"^(.*?)(?:\s*\(([^;]*)(?:;\s*([^)]*))?\))?$"#
        let regex = try! NSRegularExpression(pattern: pattern)
        let range = NSRange(content.startIndex..<content.endIndex, in: content)
        
        guard let match = regex.firstMatch(in: content, range: range) else {
            return (content, UUID(), .blue)
        }
        
        let name = String(content[Range(match.range(at: 1), in: content)!])
            .trimmingCharacters(in: .whitespaces)
            .replacingOccurrences(of: "^\\s*-\\s*", with: "", options: .regularExpression)
        
        let uuidString = match.range(at: 2).location != NSNotFound ? 
            String(content[Range(match.range(at: 2), in: content)!]).trimmingCharacters(in: .whitespaces) : nil
        let colorString = match.range(at: 3).location != NSNotFound ? 
            String(content[Range(match.range(at: 3), in: content)!]).trimmingCharacters(in: .whitespaces) : nil
        
        let uuid = uuidString.flatMap(UUID.init) ?? UUID()
        let color = colorString.flatMap(CatppuccinFrappe.init) ?? .blue
        
        return (name, uuid, color)
    }
    
    static func export(_ tags: [Tag]) -> String {
        var result = ""
        func appendTag(_ tag: Tag, indent: Int) {
            let indentString = String(repeating: "  ", count: indent)
            let uuidString = tag.id.uuidString
            let colorString = tag.color.rawValue
            result += "\(indentString)- \(tag.name) (\(uuidString); \(colorString))\n"
            
            // Sort children by index before exporting
            let sortedChildren = tag.children.sorted(by: { $0.index < $1.index })
            for child in sortedChildren {
                appendTag(child, indent: indent + 1)
            }
        }
        
        // Sort root tags by index before exporting
        let sortedTags = tags.sorted(by: { $0.index < $1.index })
        for tag in sortedTags {
            appendTag(tag, indent: 0)
        }
        
        return result
    }
} 