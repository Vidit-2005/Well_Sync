//
//  MoodAnalysisCollectionViewController.swift
//  wellSync
//
//  Created by Vidit Agarwal on 04/02/26.
//

import UIKit


private let reuseIdentifier = "Cell"

class MoodAnalysisCollectionViewController: UICollectionViewController {

    let cards = ["Segment","Calender","Mood Count","Mood Chart","Insights"]
    private var selectedSegmentIndex: Int = 0
    private var calendarCellHeight: CGFloat = 250
    private var moodLogs: [MoodLog] = []
    var currPatient: Patient?
    // MARK: - Computed Filters

    var weeklyMoodLog: [MoodLog] {
        let calendar = Calendar.current
        let now = Date()
        
        guard let startOfWeek = calendar.date(byAdding: .day, value: -6, to: now) else {
            return []
        }
        
        return moodLogs.filter {
            $0.date >= calendar.startOfDay(for: startOfWeek) &&
            $0.date <= now
        }
        .sorted { $0.date < $1.date }
    }
    var monthlyMoodLogs: [MoodLog] {
        let calendar = Calendar.current
        let now = Date()
        
        guard let startOfMonth = calendar.date(byAdding: .day, value: -29, to: now) else {
            return []
        }
        
        return moodLogs.filter {
            $0.date >= calendar.startOfDay(for: startOfMonth) &&
            $0.date <= now
        }
        .sorted { $0.date < $1.date }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Register cell classes
        self.collectionView.register(UINib(nibName: "CalendarCell1", bundle: nil), forCellWithReuseIdentifier: "calender")
        self.collectionView.register(UINib(nibName: "MoodChartCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: "bar_cell")
//        self.collectionView.register(UINib(nibName: "MoodCountCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: "count_cell")
        self.collectionView.register(UINib(nibName: "MoodDistributionCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: "count_cell")
        self.collectionView.register(UINib(nibName: "insightsCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: "insights_cell")
        collectionView.collectionViewLayout = generateLayout()
        Task {
            do {
                let logs = try await AccessSupabase.shared.fetchMoodLogs(
                    patientID: currPatient?.patientID ?? UUID(uuidString: "00000000-0000-0000-0000-000000000000")!
                )
                
                await MainActor.run {
                    self.moodLogs = logs
                    self.collectionView.reloadData()
                }
                
            } catch {
                print("Error in mood Fetch", error)
            }
        }
        // Do any additional setup after loading the view.
    }

    
    
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return cards.count
    }

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 1
    }

    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {

        switch indexPath.section {
        case 1:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "calender", for: indexPath) as! CalendarCell1
                        style(cell)
            cell.moodLogs = monthlyMoodLogs
                        cell.onHeightChange = { [weak self] newHeight in
                            guard let self = self else { return }

                            self.calendarCellHeight = newHeight + 16

                            self.collectionView.collectionViewLayout = self.generateLayout()
                        }
                    
                        cell.configure(segment: selectedSegmentIndex)
                        return cell

        case 2:
//            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "count_cell", for: indexPath) as! MoodCountCollectionViewCell
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "count_cell", for: indexPath) as! MoodDistributionCollectionViewCell
            style(cell)
//            cell.moodLogs = weeklyMoodLog
            return cell

        case 3:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "bar_cell", for: indexPath) as! MoodChartCollectionViewCell
            style(cell)
            cell.moodLogs = weeklyMoodLog
            return cell
        case 4:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "insights_cell", for: indexPath) as! insightsCollectionViewCell
            style(cell)
            return cell
        default:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "segment", for: indexPath)
            return cell
        }
    }

    func style(_ cell: UICollectionViewCell) {
        cell.layer.cornerRadius = 16
        cell.layer.masksToBounds = true
    }

    func generateLayout() -> UICollectionViewCompositionalLayout {

        return UICollectionViewCompositionalLayout { sectionIndex, _ in

            let height: NSCollectionLayoutDimension
            
            switch sectionIndex {
            case 0:
                height = .estimated(50)
                let itemSize = NSCollectionLayoutSize(
                    widthDimension: .fractionalWidth(1.0),
                    heightDimension: .fractionalHeight(1.0)
                )

                let item = NSCollectionLayoutItem(layoutSize: itemSize)

                let groupSize = NSCollectionLayoutSize(
                    widthDimension: .fractionalWidth(1.0),
                    heightDimension: height
                )

                let group = NSCollectionLayoutGroup.vertical(
                    layoutSize: groupSize,
                    subitems: [item]
                )
                group.interItemSpacing = .fixed(12)
                let section = NSCollectionLayoutSection(group: group)
                section.interGroupSpacing = 12
                section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16)

                return section
            case 1:
                height = .absolute(self.calendarCellHeight)
            case 2:
                height = .estimated(380)
            case 3:
                height = .estimated(240)
            default:
                height = .estimated(160)
            }

            let itemSize = NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1.0),
                heightDimension: .fractionalHeight(1.0)
            )

            let item = NSCollectionLayoutItem(layoutSize: itemSize)

            let groupSize = NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1.0),
                heightDimension: height
            )

            let group = NSCollectionLayoutGroup.vertical(
                layoutSize: groupSize,
                subitems: [item]
            )
            group.interItemSpacing = .fixed(8)
            let section = NSCollectionLayoutSection(group: group)
            section.interGroupSpacing = 8
            section.contentInsets = NSDirectionalEdgeInsets(top: 16, leading: 16, bottom: 0, trailing: 16)
            

            return section
        }
    }
    
    @IBAction func sectionChanged(_ sender: UISegmentedControl) {
        selectedSegmentIndex = sender.selectedSegmentIndex

            if let calCell = collectionView.cellForItem(
                at: IndexPath(item: 0, section: 1)
            ) as? CalendarCell1 {
                calCell.configure(segment: selectedSegmentIndex)
            }
        if let chartCell = collectionView.cellForItem(at: IndexPath(item: 0, section: 3)) as? MoodChartCollectionViewCell {
            chartCell.isWeekly = (selectedSegmentIndex == 0)
            if chartCell.isWeekly{
                chartCell.moodLogs = weeklyMoodLog
            }
            else{
                chartCell.moodLogs = monthlyMoodLogs
            }
        }
        if let countCell = collectionView.cellForItem(at: IndexPath(item: 0, section: 2)) as? MoodCountCollectionViewCell {
            countCell.isWeekly = (selectedSegmentIndex == 0)
            if countCell.isWeekly{
                countCell.moodLogs = weeklyMoodLog
            }
            else{
                countCell.moodLogs = monthlyMoodLogs
            }
        }
    }
}

//
////
////  MoodAnalysisCollectionViewController.swift
////  wellSync
////
////  Created by Vidit Agarwal on 04/02/26.
////
//
//import UIKit
//
//class MoodAnalysisCollectionViewController: UICollectionViewController {
//
//    // MARK: - Properties
//
//    let cards = ["Segment", "Calender", "Mood Count", "Mood Chart", "Insights"]
//
//    private var selectedSegmentIndex: Int = 0
//    private var calendarCellHeight: CGFloat = 250
//
//    // All raw logs fetched once from Supabase
//    private var moodLogs: [MoodLog] = []
//
//    // The date range currently visible in the calendar cell.
//    // Starts as "current week" and updates whenever the user swipes or switches segment.
//    private var currentVisibleRange: ClosedRange<Date> = {
//        let cal   = Calendar.current
//        let today = cal.startOfDay(for: Date())
//        // Default to the current week (Sun–Sat)
//        let sun   = cal.date(from: cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: today))!
//        let sat   = cal.date(byAdding: .day, value: 6, to: sun)!
//        let endOfSat = cal.date(bySettingHour: 23, minute: 59, second: 59, of: sat)!
//        return sun...endOfSat
//    }()
//
//    var currPatient: Patient?
//
//    // MARK: - Helpers
//
//    /// Returns logs that fall inside `range`, sorted ascending by date.
//    private func filteredLogs(for range: ClosedRange<Date>) -> [MoodLog] {
//        return moodLogs
//            .filter { range.contains($0.date) }
//            .sorted { $0.date < $1.date }
//    }
//
//    // MARK: - View Lifecycle
//
//    override func viewDidLoad() {
//        super.viewDidLoad()
//
//        collectionView.register(UINib(nibName: "CalendarCell1",                    bundle: nil), forCellWithReuseIdentifier: "calender")
//        collectionView.register(UINib(nibName: "MoodChartCollectionViewCell",      bundle: nil), forCellWithReuseIdentifier: "bar_cell")
//        collectionView.register(UINib(nibName: "MoodDistributionCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: "count_cell")
//        collectionView.register(UINib(nibName: "insightsCollectionViewCell",       bundle: nil), forCellWithReuseIdentifier: "insights_cell")
//
//        collectionView.collectionViewLayout = generateLayout()
//
//        Task {
//            do {
//                let logs = try await AccessSupabase.shared.fetchMoodLogs(
//                    patientID: currPatient?.patientID
//                        ?? UUID(uuidString: "00000000-0000-0000-0000-000000000000")!
//                )
//                await MainActor.run {
//                    self.moodLogs = logs
//                    self.collectionView.reloadData()
//                    // After reload, push the initial range data to all visible cells.
//                    self.refreshDataCells(for: self.currentVisibleRange,
//                                         isWeekly: self.selectedSegmentIndex == 0)
//                }
//            } catch {
//                print("Error fetching mood logs:", error)
//            }
//        }
//    }
//
//    // MARK: - Data Push  ← the single place that updates Distribution + Chart
//    //
//    // Called by:
//    //   • CalendarCell1Delegate when the user swipes to a new page
//    //   • viewDidLoad after the Supabase fetch completes
//    //   • sectionChanged when the segment toggle fires
//    //
//    // Uses prepare-style configure() on each cell — no closures, no callbacks.
//
//    private func refreshDataCells(for range: ClosedRange<Date>, isWeekly: Bool) {
//        currentVisibleRange = range
//
//        let filtered   = filteredLogs(for: range)
//        let rangeStart = range.lowerBound   // midnight of first visible day
//
//        // ── Distribution cell ─────────────────────────────────────────────────
//        if let countCell = collectionView.cellForItem(
//            at: IndexPath(item: 0, section: 2)
//        ) as? MoodDistributionCollectionViewCell {
//            countCell.configure(moodLogs: filtered)
//        }
//
//        // ── Chart cell ────────────────────────────────────────────────────────
//        if let chartCell = collectionView.cellForItem(
//            at: IndexPath(item: 0, section: 3)
//        ) as? MoodChartCollectionViewCell {
//            chartCell.configure(moodLogs: filtered,
//                                rangeStart: rangeStart,
//                                isWeekly: isWeekly)
//        }
//    }
//
//    // MARK: - UICollectionViewDataSource
//
//    override func numberOfSections(in collectionView: UICollectionView) -> Int {
//        return cards.count
//    }
//
//    override func collectionView(_ collectionView: UICollectionView,
//                                 numberOfItemsInSection section: Int) -> Int {
//        return 1
//    }
//
//    override func collectionView(_ collectionView: UICollectionView,
//                                 cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
//        switch indexPath.section {
//
//        // ── Section 1: Calendar ───────────────────────────────────────────────
//        case 1:
//            let cell = collectionView.dequeueReusableCell(
//                withReuseIdentifier: "calender", for: indexPath
//            ) as! CalendarCell1
//            style(cell)
//
//            // Pass ALL logs — the cell uses them only for day colours.
//            cell.moodLogs = moodLogs
//
//            // Wire up our delegate (no closures).
//            cell.delegate = self
//
//            // Set scope to match current segment; this also fires
//            // calendarCell(_:didChangeVisibleRange:isWeekly:) immediately.
//            cell.configure(segment: selectedSegmentIndex)
//            return cell
//
//        // ── Section 2: Distribution ───────────────────────────────────────────
//        case 2:
//            let cell = collectionView.dequeueReusableCell(
//                withReuseIdentifier: "count_cell", for: indexPath
//            ) as! MoodDistributionCollectionViewCell
//            style(cell)
//            // Populate with whatever range is currently visible
//            cell.configure(moodLogs: filteredLogs(for: currentVisibleRange))
//            return cell
//
//        // ── Section 3: Chart ──────────────────────────────────────────────────
//        case 3:
//            let cell = collectionView.dequeueReusableCell(
//                withReuseIdentifier: "bar_cell", for: indexPath
//            ) as! MoodChartCollectionViewCell
//            style(cell)
//            cell.configure(
//                moodLogs:   filteredLogs(for: currentVisibleRange),
//                rangeStart: currentVisibleRange.lowerBound,
//                isWeekly:   selectedSegmentIndex == 0
//            )
//            return cell
//
//        // ── Section 4: Insights ───────────────────────────────────────────────
//        case 4:
//            let cell = collectionView.dequeueReusableCell(
//                withReuseIdentifier: "insights_cell", for: indexPath
//            ) as! insightsCollectionViewCell
//            style(cell)
//            return cell
//
//        // ── Section 0: Segment control (default) ─────────────────────────────
//        default:
//            let cell = collectionView.dequeueReusableCell(
//                withReuseIdentifier: "segment", for: indexPath)
//            return cell
//        }
//    }
//
//    // MARK: - IBAction: Segment Toggle
//    //
//    // Simplified: just tell the calendar cell to switch scope.
//    // CalendarCell1.configure() fires the delegate which calls refreshDataCells().
//    // No manual chart/count updating needed here.
//
//    @IBAction func sectionChanged(_ sender: UISegmentedControl) {
//        selectedSegmentIndex = sender.selectedSegmentIndex
//
//        if let calCell = collectionView.cellForItem(
//            at: IndexPath(item: 0, section: 1)
//        ) as? CalendarCell1 {
//            calCell.configure(segment: selectedSegmentIndex)
//        }
//    }
//
//    // MARK: - Styling
//
//    func style(_ cell: UICollectionViewCell) {
//        cell.layer.cornerRadius  = 16
//        cell.layer.masksToBounds = true
//    }
//
//    // MARK: - Layout
//
//    func generateLayout() -> UICollectionViewCompositionalLayout {
//        return UICollectionViewCompositionalLayout { sectionIndex, _ in
//
//            let height: NSCollectionLayoutDimension
//
//            switch sectionIndex {
//            case 0:
//                // Segment control — compact height
//                let itemSize  = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .fractionalHeight(1.0))
//                let item      = NSCollectionLayoutItem(layoutSize: itemSize)
//                let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .estimated(50))
//                let group     = NSCollectionLayoutGroup.vertical(layoutSize: groupSize, subitems: [item])
//                group.interItemSpacing = .fixed(12)
//                let section   = NSCollectionLayoutSection(group: group)
//                section.interGroupSpacing = 12
//                section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16)
//                return section
//
//            case 1:
//                height = .absolute(self.calendarCellHeight)
//            case 2:
//                height = .estimated(380)
//            case 3:
//                height = .estimated(240)
//            default:
//                height = .estimated(160)
//            }
//
//            let itemSize  = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .fractionalHeight(1.0))
//            let item      = NSCollectionLayoutItem(layoutSize: itemSize)
//            let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: height)
//            let group     = NSCollectionLayoutGroup.vertical(layoutSize: groupSize, subitems: [item])
//            group.interItemSpacing = .fixed(8)
//            let section   = NSCollectionLayoutSection(group: group)
//            section.interGroupSpacing = 8
//            section.contentInsets = NSDirectionalEdgeInsets(top: 16, leading: 16, bottom: 0, trailing: 16)
//            return section
//        }
//    }
//}
//
//// MARK: - CalendarCell1Delegate
////
//// The calendar calls these two methods instead of the old onHeightChange closure.
//
//extension MoodAnalysisCollectionViewController: CalendarCell1Delegate {
//
//    /// Fires whenever the user swipes to a new week/month page, OR when
//    /// configure(segment:) is called (scope switch).  This is the single
//    /// data-sync trigger — no other call site needs to update the cells.
//    func calendarCell(_ cell: CalendarCell1,
//                      didChangeVisibleRange range: ClosedRange<Date>,
//                      isWeekly: Bool) {
//        refreshDataCells(for: range, isWeekly: isWeekly)
//    }
//
//    /// Fires during the week ↔ month animation so the layout can resize smoothly.
//    func calendarCell(_ cell: CalendarCell1,
//                      didChangeHeight height: CGFloat) {
//        calendarCellHeight = height + 16
//        collectionView.collectionViewLayout = generateLayout()
//    }
//}

//import UIKit
//
//class MoodAnalysisCollectionViewController: UICollectionViewController {
//
//    let cards = ["Segment", "Calender", "Mood Count", "Mood Chart", "Insights"]
//
//    private var selectedSegmentIndex: Int = 0
//    private var calendarCellHeight: CGFloat = 250
//
//    private var moodLogs: [MoodLog] = []
//
//    // ✅ IMPORTANT: no default calculation
//    private var currentVisibleRange: ClosedRange<Date>?
//
//    var currPatient: Patient?
//
//    // MARK: - Helpers
//
//    private func filteredLogs(for range: ClosedRange<Date>) -> [MoodLog] {
//        return moodLogs
//            .filter { range.contains($0.date) }
//            .sorted { $0.date < $1.date }
//    }
//
//    // MARK: - Lifecycle
//
//    override func viewDidLoad() {
//        super.viewDidLoad()
//
//        collectionView.register(UINib(nibName: "CalendarCell1", bundle: nil), forCellWithReuseIdentifier: "calender")
//        collectionView.register(UINib(nibName: "MoodChartCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: "bar_cell")
//        collectionView.register(UINib(nibName: "MoodDistributionCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: "count_cell")
//        collectionView.register(UINib(nibName: "insightsCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: "insights_cell")
//
//        collectionView.collectionViewLayout = generateLayout()
//
//        Task {
//            do {
//                let logs = try await AccessSupabase.shared.fetchMoodLogs(
//                    patientID: currPatient?.patientID
//                        ?? UUID(uuidString: "00000000-0000-0000-0000-000000000000")!
//                )
//
//                await MainActor.run {
//                    self.moodLogs = logs
//                    self.collectionView.reloadData()
//                }
//
//            } catch {
//                print("Error fetching mood logs:", error)
//            }
//        }
//    }
//
//    // MARK: - Data Refresh (CORE FIX)
//
//    private func refreshDataCells(for range: ClosedRange<Date>, isWeekly: Bool) {
//        currentVisibleRange = range
//
//        DispatchQueue.main.async {
//            self.collectionView.reloadSections(IndexSet(integer: 2))
//            self.collectionView.reloadSections(IndexSet(integer: 3))
//        }
//    }
//
//    // MARK: - DataSource
//
//    override func numberOfSections(in collectionView: UICollectionView) -> Int {
//        return cards.count
//    }
//
//    override func collectionView(_ collectionView: UICollectionView,
//                                 numberOfItemsInSection section: Int) -> Int {
//        return 1
//    }
//
//    override func collectionView(_ collectionView: UICollectionView,
//                                 cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
//
//        switch indexPath.section {
//
//        case 1:
//            let cell = collectionView.dequeueReusableCell(
//                withReuseIdentifier: "calender", for: indexPath
//            ) as! CalendarCell1
//
//            style(cell)
//
//            cell.moodLogs = moodLogs
//            cell.delegate = self
//
//            // ✅ THIS triggers correct range immediately
//            cell.configure(segment: selectedSegmentIndex)
//
//            return cell
//
//        case 2:
//            let cell = collectionView.dequeueReusableCell(
//                withReuseIdentifier: "count_cell", for: indexPath
//            ) as! MoodDistributionCollectionViewCell
//
//            style(cell)
//
//            if let range = currentVisibleRange {
//                cell.configure(moodLogs: filteredLogs(for: range))
//            } else {
//                cell.configure(moodLogs: [])
//            }
//
//            return cell
//
//        case 3:
//            let cell = collectionView.dequeueReusableCell(
//                withReuseIdentifier: "bar_cell", for: indexPath
//            ) as! MoodChartCollectionViewCell
//
//            style(cell)
//
//            if let range = currentVisibleRange {
//                cell.configure(
//                    moodLogs: filteredLogs(for: range),
//                    rangeStart: range.lowerBound,
//                    isWeekly: selectedSegmentIndex == 0
//                )
//            } else {
//                cell.configure(
//                    moodLogs: [],
//                    rangeStart: Date(),
//                    isWeekly: true
//                )
//            }
//
//            return cell
//
//        case 4:
//            let cell = collectionView.dequeueReusableCell(
//                withReuseIdentifier: "insights_cell", for: indexPath
//            ) as! insightsCollectionViewCell
//
//            style(cell)
//            return cell
//
//        default:
//            let cell = collectionView.dequeueReusableCell(
//                withReuseIdentifier: "segment", for: indexPath)
//            return cell
//        }
//    }
//
//    // MARK: - Segment Change
//
//    @IBAction func sectionChanged(_ sender: UISegmentedControl) {
//        selectedSegmentIndex = sender.selectedSegmentIndex
//
//        if let calCell = collectionView.cellForItem(
//            at: IndexPath(item: 0, section: 1)
//        ) as? CalendarCell1 {
//            calCell.configure(segment: selectedSegmentIndex)
//        }
//    }
//
//    // MARK: - Styling
//
//    func style(_ cell: UICollectionViewCell) {
//        cell.layer.cornerRadius = 16
//        cell.layer.masksToBounds = true
//    }
//
//    // MARK: - Layout
//
//    func generateLayout() -> UICollectionViewCompositionalLayout {
//        return UICollectionViewCompositionalLayout { sectionIndex, _ in
//
//            let height: NSCollectionLayoutDimension
//
//            switch sectionIndex {
//            case 0:
//                let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
//                                                      heightDimension: .fractionalHeight(1.0))
//                let item = NSCollectionLayoutItem(layoutSize: itemSize)
//
//                let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
//                                                       heightDimension: .estimated(50))
//                let group = NSCollectionLayoutGroup.vertical(layoutSize: groupSize, subitems: [item])
//
//                let section = NSCollectionLayoutSection(group: group)
//                section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16)
//                return section
//
//            case 1:
//                height = .absolute(self.calendarCellHeight)
//            case 2:
//                height = .estimated(380)
//            case 3:
//                height = .estimated(240)
//            default:
//                height = .estimated(160)
//            }
//
//            let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
//                                                  heightDimension: .fractionalHeight(1.0))
//            let item = NSCollectionLayoutItem(layoutSize: itemSize)
//
//            let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
//                                                   heightDimension: height)
//            let group = NSCollectionLayoutGroup.vertical(layoutSize: groupSize, subitems: [item])
//
//            let section = NSCollectionLayoutSection(group: group)
//            section.contentInsets = NSDirectionalEdgeInsets(top: 16, leading: 16, bottom: 0, trailing: 16)
//
//            return section
//        }
//    }
//}
//
//// MARK: - Calendar Delegate
//
//extension MoodAnalysisCollectionViewController: CalendarCell1Delegate {
//
//    func calendarCell(_ cell: CalendarCell1,
//                      didChangeVisibleRange range: ClosedRange<Date>,
//                      isWeekly: Bool) {
//        refreshDataCells(for: range, isWeekly: isWeekly)
//    }
//
//    func calendarCell(_ cell: CalendarCell1,
//                      didChangeHeight height: CGFloat) {
//        calendarCellHeight = height + 16
//        collectionView.collectionViewLayout = generateLayout()
//    }
//}
