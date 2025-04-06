//
//  Attachment.swift
//  Calendr
//
//  Created by Paker on 06/04/25.
//

import Foundation
import EventKit

/// A wrapper around the private EKAttachment API
struct Attachment: Equatable {
    let url: URL?
    let fileName: String
    let localURL: URL?
    let fileSize: NSNumber?

    init?(from attachment: Any) {
        guard let attachment = attachment as? NSObject else { return nil }

        do {
            self.url = try attachment.safeValue(forKey: "URL")
            self.fileName = try attachment.safeValue(forKey: "fileName")
            self.localURL = try attachment.safeValue(forKey: "localURL")
            self.fileSize = try attachment.safeValue(forKey: "fileSize")
        } catch {
            print("Could not decode attachment", error.localizedDescription)
            return nil
        }
    }
}

extension EKCalendarItem {

    var attachments: [Attachment] {
        guard let attachments: [Any] = try? safeValue(forKey: "attachments") else {
            return []
        }

        return attachments.compactMap(Attachment.init)
    }
}
