//
//  EnvParserTests.swift
//  Calendr
//
//  Created by Paker on 05/09/2026.
//

import Foundation
import Testing
@testable import Calendr

class EnvParserTests {

    @Test func testEnvParsing() {

        let rawEnvText = """
        # This is a comment
        API_KEY=12345abcde   
        SERVER_URL = "https://example.com"
        TIMEOUT=30
           # Another comment line
        DB_NAME='production_db'
        INVALID_LINE_WITHOUT_EQUALS
        """

        enum EnvKeys1: String {
            case API_KEY
            case DB_NAME
        }

        let result1: [EnvKeys1: String] = EnvParser.parse(text: rawEnvText)

        #expect(result1 == [
            .API_KEY: "12345abcde",
            .DB_NAME: "production_db"
        ])

        enum EnvKeys2: String {
            case SERVER_URL
            case TIMEOUT
        }

        let result2: [EnvKeys2: String] = EnvParser.parse(text: rawEnvText)

        #expect(result2 == [
            .SERVER_URL: "https://example.com",
            .TIMEOUT: "30",
        ])
    }
}
