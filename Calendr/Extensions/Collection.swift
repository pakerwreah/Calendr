//
//  Collection.swift
//  Calendr
//
//  Created by Paker on 01/05/2025.
//

extension Collection {

    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
