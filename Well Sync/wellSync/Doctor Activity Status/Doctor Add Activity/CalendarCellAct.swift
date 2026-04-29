//
//  CalendarCellAct.swift
//  wellSync
//

import UIKit
import FSCalendar

class CalendarCellAct: UICollectionViewCell,
                       FSCalendarDataSource,
                       FSCalendarDelegate,
                       FSCalendarDelegateAppearance {

    @IBOutlet weak var calendar: FSCalendar!

    var onHeightChange: ((CGFloat) -> Void)?
    var onDateSelected: ((Date) -> Void)?

    // NEW: fires whenever the user swipes to a different week or month
    var onPageChange: ((Date) -> Void)?

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
        calendar.delegate   = self

        calendar.scrollDirection = .horizontal
        calendar.placeholderType = .none
        calendar.firstWeekday    = 1          // Sunday first
        calendar.scope           = .week

        calendar.appearance.headerMinimumDissolvedAlpha = 0
        calendar.appearance.headerTitleFont   = .systemFont(ofSize: 15, weight: .bold)
        calendar.appearance.headerTitleColor  = UIColor.label
        calendar.appearance.headerDateFormat  = "MMMM yyyy"

        calendar.appearance.weekdayFont       = .systemFont(ofSize: 12, weight: .semibold)
        calendar.appearance.weekdayTextColor  = UIColor.secondaryLabel

        calendar.appearance.titleFont             = .systemFont(ofSize: 15, weight: .medium)
        calendar.appearance.titleDefaultColor     = UIColor.label
        calendar.appearance.titleWeekendColor     = UIColor.label

        calendar.appearance.selectionColor        = UIColor.systemIndigo
        calendar.appearance.titleSelectionColor   = UIColor.label

        calendar.appearance.todayColor            = .clear
        calendar.appearance.titleTodayColor       = .accent

        calendar.appearance.borderRadius = 1.0
        calendar.appearance.eventOffset  = .zero
    }

    // MARK: - FSCalendarDelegate — date tap

    func calendar(_ calendar: FSCalendar,
                  didSelect date: Date,
                  at monthPosition: FSCalendarMonthPosition) {
        onDateSelected?(date)
    }

    // MARK: - FSCalendarDelegate — page swipe  ← NEW

    func calendarCurrentPageDidChange(_ calendar: FSCalendar) {
        // currentPage = first day of the visible week (weekly mode)
        //             = first day of the visible month (monthly mode)
        onPageChange?(calendar.currentPage)
    }

    // MARK: - Appearance overrides

    func calendar(_ calendar: FSCalendar,
                  appearance: FSCalendarAppearance,
                  fillDefaultColorFor date: Date) -> UIColor? { nil }

    func calendar(_ calendar: FSCalendar,
                  appearance: FSCalendarAppearance,
                  titleDefaultColorFor date: Date) -> UIColor? { nil }

    func calendar(_ calendar: FSCalendar,
                  appearance: FSCalendarAppearance,
                  fillTodayColorFor date: Date) -> UIColor? {
        UIColor.systemIndigo.withAlphaComponent(0.15)
    }

    func calendar(_ calendar: FSCalendar,
                  appearance: FSCalendarAppearance,
                  fillSelectionColorFor date: Date) -> UIColor? {
        UIColor.systemIndigo.withAlphaComponent(0.7)
    }

    // MARK: - Height change (week ↔ month scope animation)

    func calendar(_ calendar: FSCalendar,
                  boundingRectWillChange bounds: CGRect,
                  animated: Bool) {
        calendar.frame.size.height = bounds.height
        onHeightChange?(bounds.height)
    }

    // MARK: - Scope helpers

    func configure(segment: Int) {
        if segment == 0 {
            calendar.setScope(.week, animated: true)
        } else {
            calendar.setScope(.month, animated: true)
        }
    }
}
