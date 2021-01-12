//
//  DateProvider.swift
//  Calendr
//
//  Created by Paker on 12/01/21.
//

import Foundation

protocol DateProviding {
    var today: Date { get }
}

class DateProvider: DateProviding {
    var today: Date { Date() }
}
