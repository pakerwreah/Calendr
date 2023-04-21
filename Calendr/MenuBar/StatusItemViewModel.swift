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
    let image: Observable<NSImage?>

    init(
        dateObservable: Observable<Date>,
        nextEventCalendars: Observable<[String]>,
        settings: StatusItemSettings,
        dateProvider: DateProviding,
        screenProvider: ScreenProviding,
        calendarService: CalendarServiceProviding,
        notificationCenter: NotificationCenter
    ) {

        let hasBirthdaysObservable = Observable.combineLatest(
            dateObservable,
            nextEventCalendars
        )
        .repeat(when: calendarService.changeObservable)
        .flatMapLatest { date, calendars in
            let start = dateProvider.calendar.startOfDay(for: date)
            let end = dateProvider.calendar.endOfDay(for: date)
            return calendarService
                .events(from: start, to: end, calendars: calendars)
                .map { $0.contains(where: \.type.isBirthday) }
        }

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

        let textObservable = Observable.combineLatest(
            dateObservable,
            showIcon,
            settings.showStatusItemDate,
            settings.showStatusItemBackground,
            dateFormatterObservable,
            hasBirthdaysObservable
        )
        .map { date, showIcon, showDate, showBackground, dateFormatter, hasBirthdays in

            let title = NSMutableAttributedString()

            if showIcon || hasBirthdays {
                let attachment = NSTextAttachment()
                let icon = hasBirthdays ? Icons.Event.birthday : Icons.MenuBar.icon
                attachment.image = icon.with(scale: .large)
                title.append(NSAttributedString(attachment: attachment))

                let size: CGFloat
                switch (showDate, hasBirthdays) {
                case (true, true):
                    size = 11
                case (false, false):
                    size = 13
                default:
                    size = 12
                }

                title.addAttributes(
                    [.font: NSFont.systemFont(ofSize: size)],
                    range: NSRange(location: 0, length: title.length)
                )
            }

            if showDate {
                if title.length > 0 {
                    title.append(NSAttributedString(string: " "))
                }
                let text = dateFormatter.string(from: date)
                title.append(
                    NSAttributedString(
                        string: text.isEmpty ? "???" : text,
                        attributes: [.font: NSFont.systemFont(ofSize: 13)]
                    )
                )
            }

            return title
        }
        .share(replay: 1)

        self.text = Observable.combineLatest(
            textObservable,
            settings.showStatusItemBackground
        )
        .map { text, showBackground in
            showBackground ? .init() : text
        }

        self.image = Observable.combineLatest(
            textObservable,
            settings.showStatusItemBackground
        )
        .map { text, showBackground in
            guard showBackground else { return nil }

            let radius: CGFloat = 3
            let padding: CGFloat = 4
            var size = text.size()
            size.width += 2 * padding

            let textImage = NSImage(size: size, flipped: false) { _ in
                text.draw(at: .init(x: padding, y: 0))
                return true
            }

            let image = NSImage(size: size, flipped: false) {
                NSBezierPath(roundedRect: $0, xRadius: radius, yRadius: radius).addClip()
                NSColor.white.drawSwatch(in: $0)
                textImage.draw(at: .zero, from: $0, operation: .destinationOut, fraction: 1)
                return true
            }

            image.isTemplate = true

            return image
        }
    }
}
