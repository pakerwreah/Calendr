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

        let shouldCompact = Observable
            .combineLatest(settings.eventStatusItemDetectNotch, screenProvider.hasNotchObservable)
            .map { $0 && $1 }
            .distinctUntilChanged()

        let showIcon = Observable
            .combineLatest(
                settings.showStatusItemIcon,
                settings.showStatusItemIconDate,
                settings.showStatusItemDate,
                shouldCompact
            )
            .map { showIcon, showIconDate, showDate, shouldCompact -> Bool in
                guard showDate else { return true }
                return showIcon && (!shouldCompact || showIconDate)
            }
            .distinctUntilChanged()

        self.iconsAndText = Observable.combineLatest(
            dateObservable,
            showIcon,
            settings.showStatusItemDate,
            settings.showStatusItemIconDate,
            settings.showStatusItemBackground,
            dateFormatterObservable,
            hasBirthdaysObservable
        )
        .map { date, showIcon, showDate, showIconDate, showBackground, dateFormatter, hasBirthdays in

            var icons: [NSImage] = []

            let iconSize: CGFloat = showDate ? 15 : 16

            if hasBirthdays {
                icons.append(Icons.Event.birthday.with(pointSize: iconSize - 2))
            }

            if showIcon && (showIconDate || !hasBirthdays) {
                let headerHeight: CGFloat = 3.5
                let borderWidth: CGFloat = 2
                let radius: CGFloat = 2.5
                let ratio: CGFloat = 10 / 9
                let rect = CGRect(x: 0, y: 0, width: iconSize * ratio, height: iconSize)

                let icon = NSImage(size: rect.size, flipped: true) { _ in
                    /// can be any opaque color, but red is good for debugging
                    let color = NSColor.red
                    color.setStroke()
                    color.setFill()

                    drawIconCalendarFrame(rect: rect, radius: radius, borderWidth: borderWidth, headerHeight: headerHeight)

                    if showIconDate {
                        drawIconDate(rect: rect, iconSize: iconSize, dateProvider: dateProvider)
                    } else {
                        drawIconDots(rect: rect, borderWidth: borderWidth, headerHeight: headerHeight)
                    }

                    return true
                }
                icons.append(icon)
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
                .font: NSFont.systemFont(ofSize: 13, weight: showBackground ? .regular : .medium)
            ])

            let radius: CGFloat = 3
            let border: CGFloat = 0.5
            let padding: NSPoint = showDate ? .init(x: 4, y: 1) : .init(x: border, y: border)
            let textSize = title.length > 0 ? title.size() : .zero
            let spacing: CGFloat = 4
            var iconsWidth = icons.map(\.size.width).reduce(0) { $0 + $1 + spacing }
            let height = max(icons.map(\.size.height).reduce(0, max), textSize.height)
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

private func drawIconCalendarFrame(rect: CGRect, radius: CGFloat, borderWidth: CGFloat, headerHeight: CGFloat) {
    let strokePath = NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius)
    strokePath.addClip()
    strokePath.lineWidth = borderWidth
    strokePath.stroke()

    var fillRect = rect
    fillRect.size.height = headerHeight
    let fillPath = NSBezierPath(rect: fillRect)
    fillPath.fill()
}

private func drawIconDots(rect: CGRect, borderWidth: CGFloat, headerHeight: CGFloat) {
    let offsetX: CGFloat = rect.origin.x + borderWidth
    let offsetY: CGFloat = rect.origin.y + headerHeight + 0.5
    let insets: CGFloat = 0.09 * rect.width
    let dotSize: CGFloat = 1.4
    let rows: Int = 3
    let cols: Int = 4
    let availableWidth: CGFloat = rect.size.width - 2 * borderWidth - 2 * insets - CGFloat(cols) * dotSize
    let availableHeight: CGFloat = rect.size.height - headerHeight - borderWidth - 2 * insets - CGFloat(rows) * dotSize
    let spacingX: CGFloat = availableWidth / CGFloat(cols - 1)
    let spacingY: CGFloat = availableHeight / CGFloat(rows - 1)
    for i in 1...10 {
        let row: Int = i % rows
        let col: Int = i / rows
        let dotPath = NSBezierPath(
            ovalIn: .init(
                x: offsetX + insets + CGFloat(col) * (dotSize + spacingX),
                y: offsetY + insets + CGFloat(row) * (dotSize + spacingY),
                width: dotSize,
                height: dotSize
            )
        )
        dotPath.fill()
    }
}

private func drawIconDate(rect: CGRect, iconSize: CGFloat, dateProvider: DateProviding) {
    let formatter = DateFormatter(format: "d", calendar: dateProvider.calendar)
    let date = formatter.string(from: dateProvider.now)
    let paragraph = NSMutableParagraphStyle()
    paragraph.alignment = .center
    NSAttributedString(string: date, attributes: [
        .baselineOffset: -(2.5 / 16) * iconSize,
        .font: NSFont.systemFont(ofSize: (9 / 16) * iconSize),
        .foregroundColor: NSColor.red,
        .paragraphStyle: paragraph
    ]).draw(in: rect.offsetBy(dx: 0.25, dy: 0.5))
}
