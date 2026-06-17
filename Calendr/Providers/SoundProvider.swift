//
//  SoundProvider.swift
//  Calendr
//
//  Created by Paker on 02/11/2024.
//

import AppKit

enum SystemSound: NSSound.Name {
    case funk = "Funk"
    case pop = "Pop"
    case submarine = "Submarine"
    case hero = "Hero"
    case basso = "Basso"
    case blow = "Blow"
    case bottle = "Bottle"
    case glass = "Glass"
    case morse = "Morse"
    case ping = "Ping"
    case purr = "Purr"
    case sosumi = "Sosumi"
    case tink = "Tink"
}

protocol SoundProviding {
    func play(_ name: SystemSound)
}

class SoundProvider: SoundProviding {

    fileprivate init() {}

    func play(_ name: SystemSound) {
        guard let sound = NSSound(named: name.rawValue) else {
            print("Could not find \(name) sound")
            return NSSound.beep()
        }
        sound.play()
    }
}

private let soundPlayer = SoundProvider()

extension SoundProviding where Self == SoundProvider {

    static var shared: Self { soundPlayer }
}
