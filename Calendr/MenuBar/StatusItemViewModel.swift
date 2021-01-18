//
//  StatusItemViewModel.swift
//  Calendr
//
//  Created by Paker on 18/01/21.
//

import RxCocoa
import RxSwift

class StatusItemViewModel {

    let width: Observable<CGFloat>
    let text: Observable<NSAttributedString>

    init(dateObservable: Observable<Date>, settingsObservable: Observable<(showIcon: Bool, showDate: Bool)>) {

        let titleIcon = NSAttributedString(string: "\u{1f4c5}", attributes: [
            .font: NSFont(name: "SegoeUISymbol", size: Constants.iconPointSize)!,
            .baselineOffset: Constants.iconBaselineOffset
        ])

        let dateFormatter = DateFormatter(template: "yyyyMMdd")

        text = Observable.combineLatest(
            dateObservable, settingsObservable
        )
        .map { date, settings in

            let title = NSMutableAttributedString()

            if settings.showIcon {
                title.append(titleIcon)
            }

            if settings.showDate {
                if title.length > 0 {
                    title.append(NSAttributedString(string: "  "))
                }
                title.append(NSAttributedString(string: dateFormatter.string(from: date)))
            }

            return title
        }

        width = settingsObservable.map { showIcon, showDate in

            var width: CGFloat = 0

            if showIcon {
                width += Constants.iconWidth
            }

            if showDate {
                if showIcon {
                    width += Constants.spacerWidth
                }
                width += Constants.dateWidth
            }

            return width
        }
    }
}

private enum Constants {

    static let iconWidth: CGFloat = 15
    static let dateWidth: CGFloat = 70
    static let spacerWidth: CGFloat = 5
    static let iconPointSize: CGFloat = 14
    static let iconBaselineOffset: CGFloat = -1
}
