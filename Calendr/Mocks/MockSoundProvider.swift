//
//  MockSoundProvider.swift
//  Calendr
//
//  Created by Paker on 02/11/2024.
//

#if DEBUG

import Foundation

class MockSoundProvider: SoundProviding {

    private(set) var played: [SystemSound] = []

    func play(_ name: SystemSound) {
        played.append(name)
    }
}

#endif
