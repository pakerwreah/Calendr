//
//  SoundPlayer.swift
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

protocol SoundPlaying {
    func play(_ name: SystemSound)
}

class SoundPlayer: SoundPlaying {

    fileprivate init() {}

    func play(_ name: SystemSound) {
        guard let sound = NSSound(named: name.rawValue) else {
            print("Could not find \(name) sound")
            return NSSound.beep()
        }
        sound.play()
    }
}

private let soundPlayer = SoundPlayer()

extension SoundPlaying where Self == SoundPlayer {

    static var shared: Self { soundPlayer }
}
