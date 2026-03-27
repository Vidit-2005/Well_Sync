////
////  CalendarCell1.swift
////  wellSync
////
////  Created by Vidit Saran Agarwal on 17/03/26.
////
//
//import UIKit
//import FSCalendar
//
//class CalendarCell1: UICollectionViewCell,
//                     FSCalendarDataSource,
//                     FSCalendarDelegate,
//                     FSCalendarDelegateAppearance {
//
//    @IBOutlet weak var calendar: FSCalendar!
//    var onHeightChange: ((CGFloat) -> Void)?
//
//    var moodLogs: [MoodLog] = [] {
//        didSet {
//            buildAverageMoodMap()
//            calendar.reloadData()
//        }
//    }
//
//    private var averageMoodByDay: [String: Double] = [:]
//
//    override func awakeFromNib() {
//        super.awakeFromNib()
//        setupCalendar()
//    }
//
//    private func setupCalendar() {
//        calendar.dataSource = self
//        calendar.delegate = self
//        calendar.scrollDirection = .horizontal
//        calendar.placeholderType = .none
//        calendar.firstWeekday = 1
//        calendar.scope = .week
//
//        calendar.appearance.headerMinimumDissolvedAlpha = 0
//        calendar.appearance.headerTitleFont = .systemFont(ofSize: 15, weight: .bold)
//        calendar.appearance.headerTitleColor = UIColor.label
//        calendar.appearance.headerDateFormat = "MMMM yyyy"
//
//        calendar.appearance.weekdayFont = .systemFont(ofSize: 12, weight: .semibold)
//        calendar.appearance.weekdayTextColor = UIColor.secondaryLabel
//
//        calendar.appearance.titleFont = .systemFont(ofSize: 15, weight: .medium)
//        calendar.appearance.titleDefaultColor = UIColor.label
//        calendar.appearance.titleWeekendColor = UIColor.label
//
//        calendar.appearance.selectionColor = UIColor.systemIndigo
//        calendar.appearance.titleSelectionColor = .white
//
//        calendar.appearance.todayColor = UIColor.systemIndigo.withAlphaComponent(0.2)
//        calendar.appearance.titleTodayColor = UIColor.systemIndigo
//
//        calendar.appearance.eventOffset = CGPoint(x: 0, y: 2)
//
//        calendar.appearance.borderRadius = 1.0
//    }
//
//    private func buildAverageMoodMap() {
//        var grouped: [String: [Int]] = [:]
//        let formatter = DateFormatter()
//        formatter.dateFormat = "yyyy-MM-dd"
//
//        for log in moodLogs {
//            let key = formatter.string(from: log.date)
//            grouped[key, default: []].append(log.mood)
//        }
//
//        averageMoodByDay = grouped.mapValues { moods in
//            Double(moods.reduce(0, +)) / Double(moods.count)
//        }
//    }
//
//    private func moodColor(for average: Double) -> UIColor {
//        switch average {
//        case ..<1.5: return UIColor.systemRed
//        case 1.5..<2.5: return UIColor.systemOrange
//        case 2.5..<3.5: return UIColor.systemYellow
//        case 3.5..<4.5: return UIColor(red: 0.6, green: 0.9, blue: 0.4, alpha: 1)
//        default:         return UIColor.systemGreen
//        }
//    }
//
//
//    func calendar(_ calendar: FSCalendar,
//                  numberOfEventsFor date: Date) -> Int {
//        let formatter = DateFormatter()
//        formatter.dateFormat = "yyyy-MM-dd"
//        let key = formatter.string(from: date)
//        return averageMoodByDay[key] != nil ? 1 : 0
//    }
//
//
//    func calendar(_ calendar: FSCalendar,
//                  appearance: FSCalendarAppearance,
//                  eventDefaultColorsFor date: Date) -> [UIColor]? {
//        let formatter = DateFormatter()
//        formatter.dateFormat = "yyyy-MM-dd"
//        let key = formatter.string(from: date)
//        guard let avg = averageMoodByDay[key] else { return nil }
//        return [moodColor(for: avg)]
//    }
//
//    func calendar(_ calendar: FSCalendar,
//                  appearance: FSCalendarAppearance,
//                  eventSelectionColorsFor date: Date) -> [UIColor]? {
//        return self.calendar(calendar,
//                             appearance: appearance,
//                             eventDefaultColorsFor: date)
//    }
//
//    func setupForWeek() {
//        if calendar.scope != .week {
//            calendar.setScope(.week, animated: true)
//        }
//        calendar.scrollEnabled = true
//    }
//
//    func setupForMonth() {
//        if calendar.scope != .month {
//            calendar.setScope(.month, animated: true)
//        }
//        calendar.scrollEnabled = true
//    }
//
//    func configure(segment: Int) {
//        if segment == 0 { setupForWeek() } else { setupForMonth() }
//    }
//
//    func calendar(_ calendar: FSCalendar,
//                  boundingRectWillChange bounds: CGRect,
//                  animated: Bool) {
//        calendar.frame.size.height = bounds.height
//        onHeightChange?(bounds.height)
//    }
//}
//
//
//  CalendarCell1.swift
//  wellSync
//
//  Created by Vidit Saran Agarwal on 17/03/26.
//

import UIKit
import FSCalendar

class CalendarCell1: UICollectionViewCell,
                     FSCalendarDataSource,
                     FSCalendarDelegate,
                     FSCalendarDelegateAppearance {

    @IBOutlet weak var calendar: FSCalendar!
    var onHeightChange: ((CGFloat) -> Void)?

    var moodLogs: [MoodLog] = [] {
        didSet {
            buildDominantMoodMap()
            calendar.reloadData()
        }
    }

    private var dominantMoodByDay: [String: Int] = [:]

    private let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    // MARK: - Lifecycle

    override func awakeFromNib() {
        super.awakeFromNib()
        setupCalendar()
    }

    // MARK: - Calendar Setup

    private func setupCalendar() {
        calendar.dataSource = self
        calendar.delegate = self
        calendar.scrollDirection = .horizontal
        calendar.placeholderType = .none
        calendar.firstWeekday = 1
        calendar.scope = .week

        calendar.appearance.headerMinimumDissolvedAlpha = 0
        calendar.appearance.headerTitleFont  = .systemFont(ofSize: 15, weight: .bold)
        calendar.appearance.headerTitleColor = UIColor.label
        calendar.appearance.headerDateFormat = "MMMM yyyy"

        calendar.appearance.weekdayFont      = .systemFont(ofSize: 12, weight: .semibold)
        calendar.appearance.weekdayTextColor = UIColor.secondaryLabel

        calendar.appearance.titleFont           = .systemFont(ofSize: 15, weight: .medium)
        calendar.appearance.titleDefaultColor   = UIColor.label
        calendar.appearance.titleWeekendColor   = UIColor.label

        calendar.appearance.selectionColor      = UIColor.systemIndigo
        calendar.appearance.titleSelectionColor = UIColor.label

        calendar.appearance.todayColor          = .clear
        calendar.appearance.titleTodayColor     = UIColor.systemIndigo

        calendar.appearance.borderRadius = 1.0
        calendar.appearance.eventOffset  = .zero
    }

    // MARK: - Data Processing

    private func buildDominantMoodMap() {
        var grouped: [String: [Int]] = [:]
        for log in moodLogs {
            let key = dateFormatter.string(from: log.date)
            grouped[key, default: []].append(log.mood)
        }

        dominantMoodByDay = grouped.mapValues { moods in
            var counts: [Int: Int] = [:]
            for mood in moods {
                counts[mood, default: 0] += 1
            }
            let maxCount = counts.values.max() ?? 1
            return counts
                .filter { $0.value == maxCount }
                .keys
                .max() ?? moods[0]
        }
    }

    private func moodColor(for mood: Int) -> UIColor {
        switch mood {
        case 1:  return UIColor.systemRed
        case 2:  return UIColor.systemOrange
        case 3:  return UIColor.systemYellow
        case 4:  return UIColor(red: 0.6, green: 0.9, blue: 0.4, alpha: 1)
        default: return UIColor.systemGreen
        }
    }

//    private func titleColor(for mood: Int) -> UIColor {
//        return mood == 3 ? UIColor.label : .white
//    }

    // MARK: - Scope Helpers

    func setupForWeek() {
        if calendar.scope != .week {
            calendar.setScope(.week, animated: true)
        }
        calendar.scrollEnabled = true
    }

    func setupForMonth() {
        if calendar.scope != .month {
            calendar.setScope(.month, animated: true)
        }
        calendar.scrollEnabled = true
    }

    func configure(segment: Int) {
        if segment == 0 { setupForWeek() } else { setupForMonth() }
    }

    // MARK: - Height Change Callback

    func calendar(_ calendar: FSCalendar,
                  boundingRectWillChange bounds: CGRect,
                  animated: Bool) {
        calendar.frame.size.height = bounds.height
        onHeightChange?(bounds.height)
    }
}
//
////
////  CalendarCell1.swift
////  wellSync
////
////  Created by Vidit Saran Agarwal on 17/03/26.
////
//
//import UIKit
//import FSCalendar
//
//// MARK: - Delegate Protocol (replaces all closures)
//protocol CalendarCell1Delegate: AnyObject {
//    /// Called whenever the visible week/month page changes (swipe or scope switch).
//    func calendarCell(_ cell: CalendarCell1,
//                      didChangeVisibleRange range: ClosedRange<Date>,
//                      isWeekly: Bool)
//    /// Called when the cell height changes (scope toggle animation).
//    func calendarCell(_ cell: CalendarCell1,
//                      didChangeHeight height: CGFloat)
//}
//
//// MARK: - CalendarCell1
//class CalendarCell1: UICollectionViewCell,
//                     FSCalendarDataSource,
//                     FSCalendarDelegate,
//                     FSCalendarDelegateAppearance {
//
//    @IBOutlet weak var calendar: FSCalendar!
//
//    // Use delegate instead of closure — no capturing, no retain cycles
//    weak var delegate: CalendarCell1Delegate?
//
//    // All mood logs passed in; cell uses them only for coloring
//    var moodLogs: [MoodLog] = [] {
//        didSet {
//            buildDominantMoodMap()
//            calendar.reloadData()
//        }
//    }
//
//    private var dominantMoodByDay: [String: Int] = [:]
//
//    private let dateFormatter: DateFormatter = {
//        let f = DateFormatter()
//        f.dateFormat = "yyyy-MM-dd"
//        return f
//    }()
//
//    // MARK: - Lifecycle
//
//    override func awakeFromNib() {
//        super.awakeFromNib()
//        setupCalendar()
//    }
//
//    // MARK: - Calendar Setup
//
//    private func setupCalendar() {
//        calendar.dataSource     = self
//        calendar.delegate       = self
//        calendar.scrollDirection = .horizontal
//        calendar.placeholderType = .none
//        calendar.firstWeekday   = 1          // Sunday = 1
//        calendar.scope          = .week
//
//        calendar.appearance.headerMinimumDissolvedAlpha = 0
//        calendar.appearance.headerTitleFont  = .systemFont(ofSize: 15, weight: .bold)
//        calendar.appearance.headerTitleColor = UIColor.label
//        // KEY FIX: "MMMM yyyy" lets FSCalendar show the month that owns
//        // *most* visible days, but we also handle the boundary via
//        // currentVisibleRange() which uses actual day dates, not the page date.
//        calendar.appearance.headerDateFormat = "MMMM yyyy"
//
//        calendar.appearance.weekdayFont      = .systemFont(ofSize: 12, weight: .semibold)
//        calendar.appearance.weekdayTextColor = UIColor.secondaryLabel
//
//        calendar.appearance.titleFont           = .systemFont(ofSize: 15, weight: .medium)
//        calendar.appearance.titleDefaultColor   = UIColor.label
//        calendar.appearance.titleWeekendColor   = UIColor.label
//
//        calendar.appearance.selectionColor      = UIColor.systemIndigo
//        calendar.appearance.titleSelectionColor = UIColor.label
//
//        calendar.appearance.todayColor          = .clear
//        calendar.appearance.titleTodayColor     = UIColor.systemIndigo
//
//        calendar.appearance.borderRadius = 1.0
//        calendar.appearance.eventOffset  = .zero
//
//        // Navigate to today so the initial page is the current week/month,
//        // not whatever FSCalendar defaults to (fixes the "Dec instead of Jan" bug).
//        calendar.select(nil)
//        calendar.setCurrentPage(Date(), animated: false)
//    }
//
//    // MARK: - Data Processing
//
//    private func buildDominantMoodMap() {
//        var grouped: [String: [Int]] = [:]
//        for log in moodLogs {
//            let key = dateFormatter.string(from: log.date)
//            grouped[key, default: []].append(log.mood)
//        }
//
//        dominantMoodByDay = grouped.mapValues { moods in
//            var counts: [Int: Int] = [:]
//            for mood in moods { counts[mood, default: 0] += 1 }
//            let maxCount = counts.values.max() ?? 1
//            return counts.filter { $0.value == maxCount }.keys.max() ?? moods[0]
//        }
//    }
//
//    private func moodColor(for mood: Int) -> UIColor {
//        switch mood {
//        case 1:  return .systemRed
//        case 2:  return .systemOrange
//        case 3:  return .systemYellow
//        case 4:  return UIColor(red: 0.6, green: 0.9, blue: 0.4, alpha: 1)
//        default: return .systemGreen
//        }
//    }
//
//    // MARK: - Visible Range Helper
//    //
//    // This is the core fix for the data-sync problem.
//    // Instead of "last 7 days from today", we compute exactly which
//    // dates the user is looking at right now.
//    //
//    // In WEEK scope  → 7 dates starting from the Sunday of currentPage
//    // In MONTH scope → all dates in the displayed month
//    //
//    // Returns (range, startDate, dayCount) so callers don't have to re-derive.
//
//    func currentVisibleRange() -> (range: ClosedRange<Date>, startDate: Date, dayCount: Int) {
//        let cal       = Calendar.current
//        let page      = calendar.currentPage   // always midnight of first day on screen
//
//        if calendar.scope == .week {
//            // currentPage in week scope IS the first weekday of that row (Sunday).
//            // Add 6 to get Saturday. Cap endDate at end-of-day so the filter is inclusive.
//            let endDate   = cal.date(byAdding: .day, value: 6, to: page)!
//            let endOfDay  = cal.date(bySettingHour: 23, minute: 59, second: 59, of: endDate)!
//            return (page...endOfDay, page, 7)
//
//        } else {
//            // Month scope: currentPage = midnight of the 1st of the visible month.
//            // End = last day of that same month.
//            let nextMonth = cal.date(byAdding: .month, value: 1, to: page)!
//            let lastDay   = cal.date(byAdding: .day, value: -1, to: nextMonth)!
//            let endOfDay  = cal.date(bySettingHour: 23, minute: 59, second: 59, of: lastDay)!
//            let dayCount  = cal.range(of: .day, in: .month, for: page)?.count ?? 30
//            return (page...endOfDay, page, dayCount)
//        }
//    }
//
//    // MARK: - FSCalendarDelegateAppearance
//
//    func calendar(_ calendar: FSCalendar,
//                  appearance: FSCalendarAppearance,
//                  fillDefaultColorFor date: Date) -> UIColor? {
//        let key = dateFormatter.string(from: date)
//        guard let mood = dominantMoodByDay[key] else { return nil }
//        return moodColor(for: mood).withAlphaComponent(0.35)
//    }
//
//    func calendar(_ calendar: FSCalendar,
//                  appearance: FSCalendarAppearance,
//                  titleDefaultColorFor date: Date) -> UIColor? {
//        let key = dateFormatter.string(from: date)
//        guard dominantMoodByDay[key] != nil else { return nil }
//        return UIColor.label
//    }
//
//    func calendar(_ calendar: FSCalendar,
//                  appearance: FSCalendarAppearance,
//                  fillTodayColorFor date: Date) -> UIColor? {
//        let key = dateFormatter.string(from: date)
//        if let mood = dominantMoodByDay[key] {
//            return moodColor(for: mood).withAlphaComponent(0.35)
//        }
//        return UIColor.systemIndigo.withAlphaComponent(0.15)
//    }
//
//    func calendar(_ calendar: FSCalendar,
//                  appearance: FSCalendarAppearance,
//                  fillSelectionColorFor date: Date) -> UIColor? {
//        let key = dateFormatter.string(from: date)
//        if let mood = dominantMoodByDay[key] {
//            return moodColor(for: mood).withAlphaComponent(0.35)
//        }
//        return UIColor.systemIndigo.withAlphaComponent(0.7)
//    }
//
//    // MARK: - FSCalendarDelegate — page change (user swiped to new week/month)
//
//    func calendarCurrentPageDidChange(_ calendar: FSCalendar) {
//        let (range, start, count) = currentVisibleRange()
//        _ = start; _ = count   // used by delegate via the range
//        delegate?.calendarCell(self,
//                               didChangeVisibleRange: range,
//                               isWeekly: calendar.scope == .week)
//    }
//
//    // MARK: - Height Change (scope toggle animation)
//
//    func calendar(_ calendar: FSCalendar,
//                  boundingRectWillChange bounds: CGRect,
//                  animated: Bool) {
//        calendar.frame.size.height = bounds.height
//        delegate?.calendarCell(self, didChangeHeight: bounds.height)
//
//        // Also fire range update because scope just changed
//        DispatchQueue.main.async { [weak self] in
//            guard let self else { return }
//            let (range, _, _) = self.currentVisibleRange()
//            self.delegate?.calendarCell(self,
//                                        didChangeVisibleRange: range,
//                                        isWeekly: calendar.scope == .week)
//        }
//    }
//
//    // MARK: - Scope Helpers
//
//    private func setupForWeek() {
//        if calendar.scope != .week { calendar.setScope(.week, animated: true) }
//        calendar.scrollEnabled = true
//    }
//
//    private func setupForMonth() {
//        if calendar.scope != .month { calendar.setScope(.month, animated: true) }
//        calendar.scrollEnabled = true
//    }
//
//    // MARK: - Configure (called from VC, replaces onHeightChange wiring)
//    //
//    // This is the "prepare" entry-point the VC calls.
//    // It sets the scope AND immediately fires the delegate with the
//    // resulting visible range so every other cell can refresh right away.
//
//    func configure(segment: Int) {
//        if segment == 0 { setupForWeek() } else { setupForMonth() }
//
//        // Fire immediately for the initial/scope-change update.
//        // (calendarCurrentPageDidChange does NOT fire on setScope alone.)
//        let (range, _, _) = currentVisibleRange()
//        delegate?.calendarCell(self,
//                               didChangeVisibleRange: range,
//                               isWeekly: calendar.scope == .week)
//    }
//}
