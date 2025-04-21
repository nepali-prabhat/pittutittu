import SwiftUI

enum CatppuccinFrappe: String, CaseIterable {
    case rosewater = "#F2D5CF"
    case flamingo = "#EEBEBE"
    case pink = "#F4B8E4"
    case mauve = "#CA9EE6"
    case red = "#E78284"
    case maroon = "#EA999C"
    case peach = "#EF9F76"
    case yellow = "#E5C890"
    case green = "#A6D189"
    case teal = "#81C8BE"
    case sky = "#99D1DB"
    case sapphire = "#85C1DC"
    case blue = "#8CAAEE"
    case lavender = "#BABBF1"
    
    var color: Color {
        Color(hex: rawValue) ?? .black
    }
    
    static var allColors: [Color] {
        allCases.map { $0.color }
    }
}