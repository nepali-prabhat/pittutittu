import Foundation

class TagParser {
    private class TagNode {
        let tag: Tag
        let indent: Int
        
        init(tag: Tag, indent: Int) {
            self.tag = tag
            self.indent = indent
        }
    }
    
    static func parse(_ string: String) -> [Tag] {
        var tags: [Tag] = []
        var currentIndent = 0
        var parentStack: [TagNode] = []
        
        let lines = string.components(separatedBy: .newlines)
            .filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
        
        for line in lines {
            let trimmedLine = line.trimmingCharacters(in: .whitespaces)
            let indent = line.prefix(while: { $0 == " " }).count / 2
            let content = trimmedLine
            
            // Parse name, uuid, and color
            let (name, uuid, color) = parseTagContent(content)
            
            var tag = Tag(
                id: uuid,
                name: name,
                color: color
            )
            
            // Handle indentation and parent-child relationships
            if indent > currentIndent {
                // This is a child of the previous tag
                if let parent = parentStack.last {
                    var parentTag = parent.tag
                    parentTag.children.append(tag)
                    tag = parentTag
                }
            } else {
                // This is a sibling or parent of a previous tag
                while let parent = parentStack.last, parent.indent >= indent {
                    parentStack.removeLast()
                }
                
                if let parent = parentStack.last {
                    var parentTag = parent.tag
                    parentTag.children.append(tag)
                    tag = parentTag
                } else {
                    tags.append(tag)
                }
            }
            
            parentStack.append(TagNode(tag: tag, indent: indent))
            currentIndent = indent
        }
        
        return tags
    }
    
    private static func parseTagContent(_ content: String) -> (name: String, uuid: UUID, color: CatppuccinFrappe) {
        let pattern = #"^(.*?)(?:\s*\(([^;]*)(?:;\s*([^)]*))?\))?$"#
        let regex = try! NSRegularExpression(pattern: pattern)
        let range = NSRange(content.startIndex..<content.endIndex, in: content)
        
        guard let match = regex.firstMatch(in: content, range: range) else {
            return (content, UUID(), .blue)
        }
        
        let name = String(content[Range(match.range(at: 1), in: content)!]).trimmingCharacters(in: .whitespaces)
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
            
            for child in tag.children {
                appendTag(child, indent: indent + 1)
            }
        }
        
        for tag in tags {
            appendTag(tag, indent: 0)
        }
        
        return result
    }
} 