//import UIKit
//import FSCalendar
//
//class StreakCell: UICollectionViewCell {
//
//    @IBOutlet weak var calendar: FSCalendar!
//    private var loggedDates: Set<Date> = []
//
//    override func awakeFromNib() {
//        super.awakeFromNib()
//        setupCalendar()
//    }
//
//    // ✅ rowHeight set here — AFTER frame is real
//    override func layoutSubviews() {
//        super.layoutSubviews()
//        calendar.rowHeight    = 80
//        calendar.weekdayHeight = 22
//    }
//
//    private func setupCalendar() {
//        calendar.delegate    = self
//        calendar.dataSource  = self
//
//        calendar.scope       = .week
//        calendar.scrollEnabled = false
//        calendar.firstWeekday  = 2
//
//        calendar.allowsSelection         = true
//        calendar.allowsMultipleSelection = true
//        calendar.isUserInteractionEnabled = false
//
//        calendar.headerHeight = 0
//        calendar.appearance.headerMinimumDissolvedAlpha = 0
//
//        calendar.appearance.weekdayFont      = .systemFont(ofSize: 10, weight: .medium)
//        calendar.appearance.weekdayTextColor = .secondaryLabel
//
//        calendar.appearance.borderRadius    = 1.0
//        calendar.appearance.titleFont         = .systemFont(ofSize: 15, weight: .semibold)
//        calendar.appearance.titleDefaultColor = .secondaryLabel
//
//        calendar.appearance.todayColor      = .systemBlue
//        calendar.appearance.titleTodayColor = .white
//
//        calendar.appearance.selectionColor      = UIColor.systemBlue.withAlphaComponent(0.18)
//        calendar.appearance.titleSelectionColor = .systemBlue
//
//        calendar.backgroundColor = .clear
//    }
//
//    func configure(streakCount: Int, loggedDates: [Date]) {
//        let cal = Calendar.current
//        self.loggedDates = Set(loggedDates.map { cal.startOfDay(for: $0) })
//
//        calendar.setCurrentPage(Date(), animated: false)
//        calendar.selectedDates.forEach { calendar.deselect($0) }
//        calendar.reloadData()
//
//        for date in self.loggedDates {
//            calendar.select(date, scrollToDate: false)
//        }
//    }
//}
//
//extension StreakCell: FSCalendarDataSource { }
//extension StreakCell: FSCalendarDelegate { }
//import UIKit
//import FSCalendar
//
//class StreakCell: UICollectionViewCell {
//
//    @IBOutlet weak var calendar: FSCalendar!
//    private var loggedDates: Set<Date> = []
//
//    override func awakeFromNib() {
//        super.awakeFromNib()
//        setupCalendar()
//    }
//
//    // ✅ rowHeight set here — AFTER frame is real
//    override func layoutSubviews() {
//        super.layoutSubviews()
//        calendar.rowHeight    = 80
//        calendar.weekdayHeight = 22
//    }
//
//    private func setupCalendar() {
//        calendar.delegate    = self
//        calendar.dataSource  = self
//
//        calendar.scope       = .week
//        calendar.scrollEnabled = false
//        calendar.firstWeekday  = 2
//
//        calendar.allowsSelection         = true
//        calendar.allowsMultipleSelection = true
//        calendar.isUserInteractionEnabled = false
//
//        calendar.headerHeight = 0
//        calendar.appearance.headerMinimumDissolvedAlpha = 0
//
//        calendar.appearance.weekdayFont      = .systemFont(ofSize: 10, weight: .medium)
//        calendar.appearance.weekdayTextColor = .secondaryLabel
//
//        calendar.appearance.borderRadius    = 1.0
//        calendar.appearance.titleFont         = .systemFont(ofSize: 15, weight: .semibold)
//        calendar.appearance.titleDefaultColor = .secondaryLabel
//
//        calendar.appearance.todayColor      = .systemBlue
//        calendar.appearance.titleTodayColor = .white
//
//        calendar.appearance.selectionColor      = UIColor.systemBlue.withAlphaComponent(0.18)
//        calendar.appearance.titleSelectionColor = .systemBlue
//
//        calendar.backgroundColor = .clear
//    }
//
//    func configure(streakCount: Int, loggedDates: [Date]) {
//        let cal = Calendar.current
//        self.loggedDates = Set(loggedDates.map { cal.startOfDay(for: $0) })
//
//        calendar.setCurrentPage(Date(), animated: false)
//        calendar.selectedDates.forEach { calendar.deselect($0) }
//        calendar.reloadData()
//
//        for date in self.loggedDates {
//            calendar.select(date, scrollToDate: false)
//        }
//    }
//}
//
//extension StreakCell: FSCalendarDataSource { }
//extension StreakCell: FSCalendarDelegate { }

//import UIKit
//import FSCalendar
//
//class StreakCell: UICollectionViewCell {
//
//    @IBOutlet weak var calendar: FSCalendar!
//    @IBOutlet weak var calendarHeightConstraint: NSLayoutConstraint!
//    @IBOutlet weak var streakLabel: UILabel!
//
//    private var loggedDatesSet: Set<Date> = []
//
//    override func awakeFromNib() {
//        super.awakeFromNib()
//        
//        contentView.backgroundColor = .secondarySystemBackground
//        contentView.layer.cornerRadius = 24
//        contentView.layer.masksToBounds = true
//        backgroundColor = .clear
//
//        setupCalendar()
//    }
//
//    private func setupCalendar() {
//        calendar.dataSource = self
//        calendar.delegate = self
//
//        // 1. Force Week Scope strictly
//        calendar.scope = .week
//        calendar.scrollEnabled = false
//        calendar.placeholderType = .none
//
//        // 2. Hide the header completely
//        calendar.headerHeight = 0
//        calendar.appearance.headerMinimumDissolvedAlpha = 0
//        calendar.calendarHeaderView.isHidden = true
//
//        // 3. The Golden Sizing Numbers
//        // 45 is large enough to be readable, but small enough that
//        // 7 of them fit perfectly side-by-side without squashing.
//        calendar.rowHeight = 45
//        calendar.weekdayHeight = 24
//        
//        // 4. Fonts and Offsets
//        calendar.appearance.titleFont = .systemFont(ofSize: 16, weight: .bold)
//        calendar.appearance.weekdayFont = .systemFont(ofSize: 13, weight: .semibold)
//        calendar.appearance.titleOffset = .zero
//        
//        // 5. Colors & Perfect Circles
//        calendar.appearance.selectionColor = .systemIndigo
//        calendar.appearance.titleSelectionColor = .white
//        calendar.appearance.todayColor = .clear
//        calendar.appearance.titleTodayColor = .systemIndigo
//        calendar.appearance.borderRadius = 1.0
//        
//        calendar.backgroundColor = .clear
//    }
//
//    // 🔥 This is what actually shrinks the gap dynamically
//    func calendar(_ calendar: FSCalendar,
//                  boundingRectWillChange bounds: CGRect,
//                  animated: Bool) {
//        
//        calendarHeightConstraint.constant = bounds.height
//        
//        // Force the layout to update immediately to prevent the gap flash
//        self.layoutIfNeeded()
//        self.superview?.layoutIfNeeded()
//    }
//
//    func configure(with loggedDates: [Date]) {
//        let cal = Calendar.current
//        loggedDatesSet = Set(loggedDates.map { cal.startOfDay(for: $0) })
//
//        calendar.selectedDates.forEach { calendar.deselect($0) }
//
//        for date in loggedDatesSet {
//            calendar.select(date, scrollToDate: false)
//        }
//
//        updateStreak()
//    }
//
//    private func updateStreak() {
//        streakLabel.text = "🔥 \(loggedDatesSet.count) Days"
//    }
//}
//
//extension StreakCell: FSCalendarDataSource, FSCalendarDelegate {}

import UIKit
import FSCalendar

class StreakCell: UICollectionViewCell {

    @IBOutlet weak var calendar: FSCalendar!
    @IBOutlet weak var calendarHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var streakLabel: UILabel!

    private var loggedDatesSet: Set<Date> = []

    override func awakeFromNib() {
        super.awakeFromNib()
        
        contentView.backgroundColor = .secondarySystemBackground
        contentView.layer.cornerRadius = 24
        contentView.layer.masksToBounds = true
        backgroundColor = .clear

        setupCalendar()
    }

    private func setupCalendar() {
        calendar.dataSource = self
        calendar.delegate = self

        // 1. Force Week Scope strictly
        calendar.scope = .week
        calendar.scrollEnabled = false
        calendar.placeholderType = .none

        // 2. Hide the header completely
        calendar.headerHeight = 0
        calendar.appearance.headerMinimumDissolvedAlpha = 0
        calendar.calendarHeaderView.isHidden = true

        // 3. Maximize Sizes for Larger Circles
        // 55 is typically the largest perfect circle you can fit
        // horizontally 7 times across an iPhone screen.
        calendar.rowHeight = 55
        calendar.weekdayHeight = 35 // Taller weekday row for more calendar height
        
        // 4. Larger Fonts to match the bigger circles
        calendar.appearance.titleFont = .systemFont(ofSize: 18, weight: .bold)
        calendar.appearance.weekdayFont = .systemFont(ofSize: 14, weight: .bold)
        calendar.appearance.titleOffset = .zero
        
        // 5. Colors & Perfect Circles
        calendar.appearance.selectionColor = .systemIndigo
        calendar.appearance.titleSelectionColor = .white
        calendar.appearance.todayColor = .clear
        calendar.appearance.titleTodayColor = .systemIndigo
        calendar.appearance.borderRadius = 1.0
        
        calendar.backgroundColor = .clear
    }

    // 🔥 This dynamically shrinks/grows the calendar to exactly fit the new sizes
    func calendar(_ calendar: FSCalendar,
                  boundingRectWillChange bounds: CGRect,
                  animated: Bool) {
        
        calendarHeightConstraint.constant = bounds.height
        
        // Force the layout to update immediately to prevent the gap flash
        self.layoutIfNeeded()
        self.superview?.layoutIfNeeded()
    }

    func configure(with loggedDates: [Date]) {
        let cal = Calendar.current
        loggedDatesSet = Set(loggedDates.map { cal.startOfDay(for: $0) })

        // Deselect first to clear old state when scrolling
        calendar.selectedDates.forEach { calendar.deselect($0) }

        for date in loggedDatesSet {
            calendar.select(date, scrollToDate: false)
        }

        updateStreak()
    }

    private func updateStreak() {
        streakLabel.text = "🔥 \(loggedDatesSet.count) Days"
    }
}

extension StreakCell: FSCalendarDataSource, FSCalendarDelegate {}
