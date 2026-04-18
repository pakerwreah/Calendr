//
//  CalendarSection.swift
//  Calendr
//
//  Created by Paker on 18/04/2026.
//

import OrderedCollections


struct CalendarSection: Equatable {
    let account: CalendarAccount
    let calendars: [CalendarModel]
}

extension Array where Element == CalendarModel {

    func groupedByAccount() -> [CalendarSection] {

        Dictionary(grouping: self, by: \.account)
            .sorted {
                func isOther(_ account: CalendarAccount) -> Bool {
                    account.title == Strings.Calendars.Source.others
                }
                if isOther($0.key) && !isOther($1.key) {
                    return false // $0 is Other, so it should go down
                }
                if !isOther($0.key) && isOther($1.key) {
                    return true // $1 is Other, so it should go down
                }
                return $0.key.title.localizedLowercase < $1.key.title.localizedLowercase // Otherwise, sort by name
            }
            .map { account, calendars in
                CalendarSection(account: account, calendars: calendars.sorted(by: \.title.localizedLowercase))
            }
    }
}
