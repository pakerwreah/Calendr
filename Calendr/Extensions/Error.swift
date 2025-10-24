//
//  Error.swift
//  Calendr
//
//  Created by Paker on 27/09/23.
//

import Foundation

struct UnexpectedError: LocalizedError {

    let message: String

    var errorDescription: String? { message }
}

extension Error where Self == UnexpectedError {

    static func unexpected(_ message: String) -> Self { .init(message: message) }
}

extension Error {

    var unexpected: UnexpectedError { .unexpected(localizedDescription) }
}
