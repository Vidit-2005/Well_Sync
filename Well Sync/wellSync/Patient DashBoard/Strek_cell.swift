import UIKit
import FSCalendar

class StreakCell: UICollectionViewCell,FSCalendarDataSource, FSCalendarDelegate {

    @IBOutlet weak var calendar: FSCalendar!
    @IBOutlet weak var calendarHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var streakLabel: UILabel!

    private var loggedDatesSet: Set<Date> = []
    var loggedDates: [Date]?

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
    // MARK: - Selection Appearance (Band Style)

    func calendar(_ calendar: FSCalendar,
                  appearance: FSCalendarAppearance,
                  fillSelectionColorFor date: Date) -> UIColor? {
        return .label   // black band like the screenshot; change to .systemIndigo for indigo
    }

    func calendar(_ calendar: FSCalendar,
                  appearance: FSCalendarAppearance,
                  fillDefaultColorFor date: Date) -> UIColor? {
        let day  = Calendar.current.startOfDay(for: date)
        let prev = Calendar.current.date(byAdding: .day, value: -1, to: day)!
        let next = Calendar.current.date(byAdding: .day, value:  1, to: day)!

        // Bridge the gap between two selected dates
        if !loggedDatesSet.contains(day) &&
            loggedDatesSet.contains(prev) &&
            loggedDatesSet.contains(next) {
            return UIColor.label.withAlphaComponent(0.15)
        }
        return nil
    }

    func calendar(_ calendar: FSCalendar,
                  appearance: FSCalendarAppearance,
                  titleDefaultColorFor date: Date) -> UIColor? {
        let day = Calendar.current.startOfDay(for: date)
        return loggedDatesSet.contains(day) ? .white : nil
    }

    func calendar(_ calendar: FSCalendar,
                  appearance: FSCalendarAppearance,
                  borderRadiusFor date: Date) -> CGFloat {
        let day  = Calendar.current.startOfDay(for: date)
        let prev = Calendar.current.date(byAdding: .day, value: -1, to: day)!
        let next = Calendar.current.date(byAdding: .day, value:  1, to: day)!

        let hasPrev = loggedDatesSet.contains(prev)
        let hasNext = loggedDatesSet.contains(next)

        if hasPrev && hasNext { return 0.0 }   // ← middle of streak: square, blends into band
        if hasPrev || hasNext { return 0.35 }  // ← streak edge: slightly rounded cap
        return 1.0                             // ← isolated day: full circle
    }
    
    func configure() {
//        let cal = Calendar.current
//        loggedDatesSet = Set(loggedDates.map { cal.startOfDay(for: $0) })
//
//        // Deselect first to clear old state when scrolling
//        calendar.selectedDates.forEach { calendar.deselect($0) }
//
//        for date in loggedDatesSet {
//            calendar.select(date, scrollToDate: false)
//        }

    }

    func updateStreak(_ count:Int) {
        streakLabel.text = "🔥 \(count) Days"
    }
}


//import UIKit
//import FSCalendar
//
//class StreakCell: UICollectionViewCell, FSCalendarDataSource, FSCalendarDelegate {
//
//    @IBOutlet weak var calendar: FSCalendar!
//    @IBOutlet weak var calendarHeightConstraint: NSLayoutConstraint!
//    @IBOutlet weak var streakLabel: UILabel!
//
//    private var loggedDatesSet: Set<Date> = []
//    var loggedDates: [Date]?
//    private var bandView: UIView?
//
//    override func awakeFromNib() {
//        super.awakeFromNib()
//        contentView.backgroundColor = .secondarySystemBackground
//        contentView.layer.cornerRadius = 24
//        contentView.layer.masksToBounds = true
//        backgroundColor = .clear
//        setupCalendar()
//    }
//
//    private func setupCalendar() {
//        calendar.dataSource = self
//        calendar.delegate = self
//        calendar.scope = .week
//        calendar.scrollEnabled = false
//        calendar.placeholderType = .none
//        calendar.headerHeight = 0
//        calendar.appearance.headerMinimumDissolvedAlpha = 0
//        calendar.calendarHeaderView.isHidden = true
//        calendar.rowHeight = 55
//        calendar.weekdayHeight = 35
//        calendar.allowsMultipleSelection = true
//        calendar.isUserInteractionEnabled = false
//
//        calendar.appearance.titleFont        = .systemFont(ofSize: 18, weight: .bold)
//        calendar.appearance.weekdayFont      = .systemFont(ofSize: 14, weight: .bold)
//        calendar.appearance.titleOffset      = .zero
//        calendar.appearance.selectionColor   = .clear          // ✅ hide default circle
//        calendar.appearance.titleSelectionColor = .white
//        calendar.appearance.todayColor       = .clear
//        calendar.appearance.titleTodayColor  = .label
//        calendar.appearance.borderRadius     = 1.0
//        calendar.backgroundColor             = .clear
//    }
//
//    func calendar(_ calendar: FSCalendar,
//                  boundingRectWillChange bounds: CGRect,
//                  animated: Bool) {
//        calendarHeightConstraint.constant = bounds.height
//        self.layoutIfNeeded()
//        self.superview?.layoutIfNeeded()
//    }
//
//    // Keep title white for selected dates
//    func calendar(_ calendar: FSCalendar,
//                  appearance: FSCalendarAppearance,
//                  titleSelectionColorFor date: Date) -> UIColor? {
//        return .white
//    }
//
//    // MARK: - Configure
//
//    func configure() {
//        guard let dates = loggedDates, !dates.isEmpty else { return }
//
//        let cal = Calendar.current
//        loggedDatesSet = Set(dates.map { cal.startOfDay(for: $0) })
//
//        calendar.selectedDates.forEach { calendar.deselect($0) }
//        for date in loggedDatesSet {
//            calendar.select(date, scrollToDate: false)
//        }
//
//        calendar.reloadData()
//
//        // Draw band after layout is ready
//        DispatchQueue.main.async {
//            self.drawBand()
//        }
//    }
//
//    // MARK: - Band Drawing
//
//    private func drawBand() {
//        bandView?.removeFromSuperview()
//
//        let cal = Calendar.current
//        // Get Sunday of current week
//        var comps = cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date())
//        comps.weekday = cal.firstWeekday
//        guard let weekStart = cal.date(from: comps) else { return }
//
//        // Find which columns (0–6) are logged
//        var loggedColumns: [Int] = []
//        for i in 0..<7 {
//            if let day = cal.date(byAdding: .day, value: i, to: weekStart) {
//                if loggedDatesSet.contains(cal.startOfDay(for: day)) {
//                    loggedColumns.append(i)
//                }
//            }
//        }
//
//        guard loggedColumns.count > 1,
//              let first = loggedColumns.min(),
//              let last  = loggedColumns.max() else {
//            // Single day — just keep the circle, no band needed
//            drawSingleDotIfNeeded(loggedColumns.first)
//            return
//        }
//
//        let cellWidth  = calendar.bounds.width / 7
//        let bandHeight: CGFloat = 32
//        let bandY = calendar.weekdayHeight + (calendar.rowHeight - bandHeight) / 2
//
//        // Band spans from center of first to center of last logged column
//        let startX = CGFloat(first) * cellWidth + cellWidth / 2 - bandHeight / 2
//        let endX   = CGFloat(last)  * cellWidth + cellWidth / 2 + bandHeight / 2
//        let bandWidth = endX - startX
//
//        let band = UIView(frame: CGRect(x: startX, y: bandY, width: bandWidth, height: bandHeight))
//        band.backgroundColor       = .label
//        band.layer.cornerRadius    = bandHeight / 2
//        band.isUserInteractionEnabled = false
//
//        calendar.insertSubview(band, at: 0)   // ✅ behind the date labels
//        bandView = band
//    }
//
//    private func drawSingleDotIfNeeded(_ column: Int?) {
//        guard let col = column else { return }
//        let cellWidth  = calendar.bounds.width / 7
//        let bandHeight: CGFloat = 32
//        let bandY = calendar.weekdayHeight + (calendar.rowHeight - bandHeight) / 2
//        let startX = CGFloat(col) * cellWidth + (cellWidth - bandHeight) / 2
//
//        let dot = UIView(frame: CGRect(x: startX, y: bandY, width: bandHeight, height: bandHeight))
//        dot.backgroundColor    = .label
//        dot.layer.cornerRadius = bandHeight / 2
//        dot.isUserInteractionEnabled = false
//
//        calendar.insertSubview(dot, at: 0)
//        bandView = dot
//    }
//
//    func updateStreak(_ count: Int) {
//        streakLabel.text = "🔥 \(count) Days"
//    }
//}
