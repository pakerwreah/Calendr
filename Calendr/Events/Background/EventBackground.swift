//
//  EventBackground.swift
//  Calendr
//
//  Created by Paker on 06/01/2025.
//

import Cocoa

enum EventBackground: Equatable {
    case clear
    case pending
    case color(NSColor)
}

extension EventBackground {

    var cgColor: CGColor {
        switch self {
            case .clear: .clear
            case .pending: pendingBackground
            case .color(let color): color.cgColor
        }
    }
}

private let pendingBackground: CGColor = {

    let stripes = CIFilter.stripesGenerator()
    stripes.color0 = CIColor(color: NSColor.gray.withAlphaComponent(0.25))!
    stripes.color1 = .clear
    stripes.width = 2.5
    stripes.sharpness = 0

    let rotated = CIFilter.affineClamp()
    rotated.inputImage = stripes.outputImage!
    rotated.transform = CGAffineTransform(rotationAngle: -.pi / 4)

    let ciImage = rotated.outputImage!.cropped(to: CGRect(x: 0, y: 0, width: 300, height: 300))
    let rep = NSCIImageRep(ciImage: ciImage)
    let nsImage = NSImage(size: rep.size)
    nsImage.addRepresentation(rep)

    return NSColor(patternImage: nsImage).cgColor
}()
