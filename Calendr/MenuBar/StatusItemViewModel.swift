//
//  StatusItemViewModel.swift
//  Calendr
//
//  Created by Paker on 18/01/21.
//

import Cocoa
import RxSwift

class StatusItemViewModel {

    let text: Observable<NSAttributedString>

    init(
        dateObservable: Observable<Date>,
        settings: StatusItemSettings,
        dateProvider: DateProviding,
        screenProvider: ScreenProviding,
        notificationCenter: NotificationCenter
    ) {

        let localeChangeObservable = notificationCenter.rx
            .notification(NSLocale.currentLocaleDidChangeNotification)
            .void()

        let dateFormatterObservable = Observable
            .combineLatest(settings.statusItemDateStyle, settings.statusItemDateFormat)
            .repeat(when: localeChangeObservable)
            .map { style, format in

                let formatter = DateFormatter(calendar: dateProvider.calendar)

                if style.isCustom {
                    formatter.dateFormat = format
                } else {
                    formatter.dateStyle = style
                }

                return formatter
            }

        let shouldCompact = Observable
            .combineLatest(settings.eventStatusItemDetectNotch, screenProvider.hasNotchObservable)
            .map { $0 && $1 }
            .distinctUntilChanged()

        let showIcon = Observable
            .combineLatest(
                settings.showStatusItemIcon,
                settings.showStatusItemDate,
                shouldCompact
            )
            .map { showIcon, showDate, shouldCompact -> Bool in
                guard showDate else { return true }
                return showIcon && !shouldCompact
            }
            .distinctUntilChanged()

        text = Observable.combineLatest(
            dateObservable,
            showIcon,
            settings.showStatusItemDate,
            dateFormatterObservable
        )
        .map { date, showIcon, showDate, dateFormatter in

            let title = NSMutableAttributedString()

            if showIcon {
                let attachment = NSTextAttachment()
                attachment.image = Icons.MenuBar.icon.with(scale: .large)
                title.append(NSAttributedString(attachment: attachment))
                title.addAttributes(
                    [.font: NSFont.systemFont(ofSize: 13)],
                    range: NSRange(location: 0, length: title.length)
                )
            }

            if showDate {
                if title.length > 0 {
                    title.append(NSAttributedString(string: "  "))
                }
                let text = dateFormatter.string(from: date)
                title.append(NSAttributedString(string: text.isEmpty ? "???" : text))
            }

            return title
        }
    }
}
