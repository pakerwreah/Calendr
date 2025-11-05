//
//  NSColor.swift
//  Calendr
//
//  Created by Paker on 07/12/2022.
//

import AppKit

extension NSColor {

    // 🔨 Fix issue with cgColor returning the wrong color after switching between dark & light themes
    var effectiveCGColor: CGColor {
        var color: CGColor!
        NSApp.effectiveAppearance.performAsCurrentDrawingAppearance {
            color = cgColor
        }
        return color
    }

    func striped(alpha: CGFloat = 1) -> NSColor {

        let stripes = CIFilter.stripesGenerator()
        stripes.color0 = CIColor(color: self.withAlphaComponent(alpha))!
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

        return NSColor(patternImage: nsImage)
    }
}
