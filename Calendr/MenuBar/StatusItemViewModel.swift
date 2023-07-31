//
//  StatusItemViewModel.swift
//  Calendr
//
//  Created by Paker on 18/01/21.
//

import Cocoa
import RxSwift

class StatusItemViewModel {

    // only for unit tests
    let iconsAndText: Observable<([NSImage], String)>

    let image: Observable<NSImage>

    init(
        dateChanged: Observable<Void>,
        nextEventCalendars: Observable<[String]>,
        settings: StatusItemSettings,
        dateProvider: DateProviding,
        screenProvider: ScreenProviding,
        calendarService: CalendarServiceProviding,
        notificationCenter: NotificationCenter
    ) {

        let dateObservable = dateChanged.map { dateProvider.now }

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

        self.iconsAndText = Observable.combineLatest(
            dateObservable,
            settings.showStatusItemIcon,
            settings.showStatusItemDate,
            settings.statusItemIconStyle,
            dateFormatterObservable,
            hasBirthdaysObservable
        )
        .map { date, showIcon, showDate, iconStyle, dateFormatter, hasBirthdays in

            var icons: [NSImage] = []

            let iconSize: CGFloat = showDate ? 15 : 16

            if hasBirthdays {
                icons.append(Icons.Event.birthday.with(pointSize: iconSize - 2))
            }

            let isEmpty = !showIcon && !showDate && !hasBirthdays
            let showIcon = showIcon || isEmpty // avoid nothingness
            let isDefaultIcon = iconStyle == .calendar // not important, can be replaced
            let skipIcon = isDefaultIcon && hasBirthdays // replace default icon with birthday

            if showIcon && !skipIcon {
                icons.append(StatusItemIconFactory.icon(size: iconSize, style: iconStyle, dateProvider: dateProvider))
            }

            let title: String

            if showDate {
                let text = dateFormatter.string(from: date)
                title = text.isEmpty ? "???" : text
            } else {
                title = ""
            }

            return (icons, title)
        }
        .share(replay: 1)

        self.image = Observable.combineLatest(
            iconsAndText,
            settings.showStatusItemDate,
            settings.showStatusItemBackground
        )
        .map { iconsAndText, showDate, showBackground in

            let (icons, text) = iconsAndText

            let title = NSAttributedString(string: text, attributes: [
                .font: NSFont.systemFont(ofSize: 12.5, weight: showBackground ? .regular : .medium)
            ])

            let radius: CGFloat = 3
            let border: CGFloat = 0.5
            let padding: NSPoint = showDate ? .init(x: 4, y: 1.5) : .init(x: border, y: border)
            let textSize = title.length > 0 ? title.size() : .zero
            let spacing: CGFloat = 4
            var iconsWidth = icons.map(\.size.width).reduce(0) { $0 + $1 + spacing }
            let height = max(icons.map(\.size.height).reduce(0, max), 15)
            if title.length == 0 {
                iconsWidth -= spacing
            }
            var size = CGSize(width: iconsWidth + textSize.width, height: height)

            let textImage = NSImage(size: size, flipped: false) {
                var offsetX: CGFloat = 0
                for icon in icons {
                    icon.draw(at: .init(x: offsetX, y: 0), from: $0, operation: .sourceOver, fraction: 1)
                    offsetX += icon.size.width + spacing
                }
                if title.length > 0 {
                    title.draw(at: .init(x: offsetX, y: 0))
                }
                return true
            }

            textImage.isTemplate = true

            guard showBackground else {
                return textImage
            }

            size.width += 2 * padding.x
            size.height += 2 * padding.y

            let image = NSImage(size: size, flipped: false) {
                NSBezierPath(roundedRect: $0, xRadius: radius, yRadius: radius).addClip()
                NSColor.red.drawSwatch(in: $0)
                textImage.draw(at: padding, from: $0, operation: .destinationOut, fraction: 1)
                return true
            }

            image.isTemplate = true

            return image
        }
    }
}
