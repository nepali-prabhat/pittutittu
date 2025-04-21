import Foundation
import SwiftUI

struct Tag: Identifiable, Hashable {
    let id: UUID
    var name: String
    var color: CatppuccinFrappe
    var children: [Tag]
    var parentId: UUID?
    
    init(id: UUID = UUID(), name: String, color: CatppuccinFrappe = .blue, children: [Tag] = [], parentId: UUID? = nil) {
        self.id = id
        self.name = name
        self.color = color
        self.children = children
        self.parentId = parentId
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: Tag, rhs: Tag) -> Bool {
        lhs.id == rhs.id
    }
}

extension Color {
    init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")
        
        var rgb: UInt64 = 0
        
        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else { return nil }
        
        self.init(
            .sRGB,
            red: Double((rgb & 0xFF0000) >> 16) / 255.0,
            green: Double((rgb & 0x00FF00) >> 8) / 255.0,
            blue: Double(rgb & 0x0000FF) / 255.0,
            opacity: 1.0
        )
    }
} 