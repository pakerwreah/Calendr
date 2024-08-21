//
//  StatusItemViewModel.swift
//  Calendr
//
//  Created by Paker on 18/01/21.
//

import Cocoa
import RxSwift

class StatusItemViewModel {

    struct BirthdayIcon {
        let size: CGFloat
    }

    struct CalendarIcon {
        let size: CGFloat
        let style: StatusItemIconStyle
    }

    typealias IconsAndText = (birthday: BirthdayIcon?, calendar: CalendarIcon?, text: String)

    // only for unit tests
    let iconsAndText: Observable<IconsAndText>

    let image: Observable<NSImage>

    init(
        dateChanged: Observable<Void>,
        nextEventCalendars: Observable<[String]>,
        settings: StatusItemSettings,
        dateProvider: DateProviding,
        screenProvider: ScreenProviding,
        calendarService: CalendarServiceProviding,
        notificationCenter: NotificationCenter,
        scheduler: SchedulerType
    ) {

        let hasBirthdaysObservable = Observable
            .combineLatest(nextEventCalendars, settings.showEventStatusItem)
            .repeat(when: dateChanged)
            .repeat(when: calendarService.changeObservable)
            .flatMapLatest { calendars, showNextEvent -> Single<Bool> in
                guard showNextEvent else { return .just(false) }

                let date = dateProvider.now
                let start = dateProvider.calendar.startOfDay(for: date)
                let end = dateProvider.calendar.endOfDay(for: date)
                return calendarService
                    .events(from: start, to: end, calendars: calendars)
                    .map { $0.contains(where: \.type.isBirthday) }
            }

        let localeChangeObservable = notificationCenter.rx
            .notification(NSLocale.currentLocaleDidChangeNotification)
            .void()

        let dateTextObservable = Observable
            .combineLatest(
                settings.showStatusItemDate,
                settings.statusItemDateStyle,
                settings.statusItemDateFormat
            )
            .repeat(when: localeChangeObservable)
            .flatMapLatest { showDate, style, format -> Observable<String> in

                guard showDate else { return .just("") }

                let formatter = DateFormatter(calendar: dateProvider.calendar)

                let ticker: Observable<Void>

                if style.isCustom {
                    formatter.dateFormat = format
                    if dateFormatContainsTime(format) {
                        ticker = Observable<Int>.interval(.seconds(1), scheduler: scheduler).void()
                    } else {
                        ticker = dateChanged
                    }
                } else {
                    formatter.dateStyle = style
                    ticker = dateChanged
                }

                return ticker.startWith(()).map {
                    let text = formatter.string(from: dateProvider.now)
                    return text.isEmpty ? "???" : text
                }
            }
            .distinctUntilChanged()
            .share(replay: 1)

        self.iconsAndText = Observable.combineLatest(
            dateTextObservable,
            settings.showStatusItemIcon,
            settings.statusItemIconStyle,
            hasBirthdaysObservable
        )
        .map { title, showIcon, iconStyle, hasBirthdays in

            var birthdayIcon: BirthdayIcon?
            var calendarIcon: CalendarIcon?

            let showDate = !title.isEmpty

            let iconSize: CGFloat = showDate ? 15 : 16

            if hasBirthdays {
                birthdayIcon = .init(size: iconSize - 2)
            }

            let isEmpty = !showIcon && !showDate && !hasBirthdays
            let showIcon = showIcon || isEmpty // avoid nothingness
            let isDefaultIcon = iconStyle == .calendar // not important, can be replaced
            let skipIcon = isDefaultIcon && hasBirthdays // replace default icon with birthday

            if showIcon && !skipIcon {
                calendarIcon = .init(size: iconSize, style: iconStyle)
            }

            return (birthdayIcon, calendarIcon, title)
        }
        .share(replay: 1)

        var titleWidth: CGFloat = 0
        var currDateFormat = ""

        self.image = Observable.combineLatest(
            iconsAndText,
            settings.showStatusItemBackground,
            settings.statusItemDateFormat
        )
        .debounce(.nanoseconds(1), scheduler: scheduler)
        .map { iconsAndText, showBackground, dateFormat in

            let (birthdayIcon, calendarIcon, text) = iconsAndText

            var icons: [NSImage] = []

            if let icon = birthdayIcon {
                icons.append(Icons.Event.birthday.with(pointSize: icon.size))
            }

            if let icon = calendarIcon {
                icons.append(StatusItemIconFactory.icon(size: icon.size, style: icon.style, dateProvider: dateProvider))
            }

            let title = text.isEmpty ? nil : NSAttributedString(string: text, attributes: [
                .font: NSFont.systemFont(ofSize: 12.5, weight: showBackground ? .regular : .medium)
            ])

            if let title {
                if currDateFormat == dateFormat && dateFormatContainsTime(dateFormat) {
                    titleWidth = max(titleWidth, title.size().width)
                } else {
                    titleWidth = title.size().width
                }
                currDateFormat = dateFormat
            } else {
                titleWidth = 0
                currDateFormat = ""
            }

            let radius: CGFloat = 3
            let border: CGFloat = 0.5
            let padding: NSPoint = text.isEmpty ? .init(x: border, y: border) : .init(x: 4, y: 1.5)
            let spacing: CGFloat = 4
            var iconsWidth = icons.map(\.size.width).reduce(0) { $0 + $1 + spacing }
            let height = max(icons.map(\.size.height).reduce(0, max), 15)
            if text.isEmpty {
                iconsWidth -= spacing
            }
            var size = CGSize(width: iconsWidth + titleWidth, height: height)

            let textImage = NSImage(size: size, flipped: false) {
                var offsetX: CGFloat = 0
                for icon in icons {
                    icon.draw(at: .init(x: offsetX, y: 0), from: $0, operation: .sourceOver, fraction: 1)
                    offsetX += icon.size.width + spacing
                }
                title?.draw(at: .init(x: offsetX, y: 0))
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

private func dateFormatContainsTime(_ format: String) -> Bool {
    ["H", "h", "m", "s"].contains(where: { format.contains($0) })
}
