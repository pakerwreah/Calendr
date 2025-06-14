//
//  String.swift
//  Calendr
//
//  Created by Paker on 21/02/2021.
//

import Cocoa

extension StringProtocol {

    static var uuid: String { UUID().uuidString }

    var trimmed: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func replacingOccurrences(of set: CharacterSet, with replacement: any StringProtocol) -> String {

        String(components(separatedBy: set).joined(separator: replacement))
    }

    func html(font: NSFont, color: NSColor) -> NSAttributedString? {

        guard
            let data = replacingOccurrences(of: .newlines, with: "<br>").data(using: .unicode),
            let attribStr = NSMutableAttributedString(html: data, documentAttributes: nil)
        else { return nil }

        let range = NSMakeRange(0, attribStr.length)

        // 🔨 Fix huge spacing in <li> tags
        if let paragraphStyle = attribStr.rulerAttributes(in: range)[.paragraphStyle] as? NSMutableParagraphStyle {
            paragraphStyle.defaultTabInterval = 12
            attribStr.addAttribute(.paragraphStyle, value: paragraphStyle, range: range)
        }

        attribStr.addAttributes([
            .foregroundColor: color,
            .font: font
        ], range: range)

        return attribStr
    }

    var ucfirst: String {
        replacingCharacters(in: ...startIndex, with: prefix(1).uppercased())
    }

    var urlEncodedQueryItem: String? {
        addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)?
            .replacingOccurrences(of: "+", with: "%2B")
            .replacingOccurrences(of: "/", with: "%2F")
            .replacingOccurrences(of: "=", with: "%3D")
            .replacingOccurrences(of: ">", with: "%3E")
            .replacingOccurrences(of: "<", with: "%3C")
            .replacingOccurrences(of: "@", with: "%40")
            .replacingOccurrences(of: "?", with: "%3F")
            .replacingOccurrences(of: "&", with: "%26")
    }
}

extension Optional where Wrapped: StringProtocol {
    
    var isNilOrEmpty: Bool { self == nil || self!.isEmpty }
}
