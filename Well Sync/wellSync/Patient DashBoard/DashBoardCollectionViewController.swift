import UIKit

class ActivityRingView: UIView {

    private let trackLayer    = CAShapeLayer()
    private let progressLayer = CAShapeLayer()
    private var didSetup      = false

    override func layoutSubviews() {
        super.layoutSubviews()
        if !didSetup {
            setupLayers()
            didSetup = true
        }
    }

    private func setupLayers() {
        let center = CGPoint(x: bounds.midX, y: bounds.midY)
        let radius = min(bounds.width, bounds.height) / 2 - 8

        let path = UIBezierPath(
            arcCenter: center,
            radius: radius,
            startAngle: -.pi / 2,
            endAngle: 1.5 * .pi,
            clockwise: true
        )

        trackLayer.path         = path.cgPath
        trackLayer.strokeColor  = UIColor.systemGray4.cgColor
        trackLayer.lineWidth    = 12
        trackLayer.fillColor    = UIColor.clear.cgColor

        progressLayer.path        = path.cgPath
        progressLayer.strokeColor = UIColor.systemCyan.cgColor
        progressLayer.lineWidth   = 12
        progressLayer.fillColor   = UIColor.clear.cgColor
        progressLayer.lineCap     = .round
        progressLayer.strokeEnd   = 0

        layer.addSublayer(trackLayer)
        layer.addSublayer(progressLayer)
    }

    func setProgress(_ value: CGFloat, animated: Bool = true, duration: CFTimeInterval = 0.8) {
        let clamped = min(max(value, 0), 1)
        if animated {
            animateProgress(to: clamped, duration: duration)
        } else {
            progressLayer.strokeEnd = clamped
        }
    }

    private func animateProgress(to value: CGFloat, duration: CFTimeInterval) {
        let animation              = CABasicAnimation(keyPath: "strokeEnd")
        animation.fromValue        = 0
        animation.toValue          = value
        animation.duration         = duration
        animation.timingFunction   = CAMediaTimingFunction(name: .easeInEaseOut)
        progressLayer.strokeEnd    = value
        progressLayer.add(animation, forKey: "progress")
    }

    func reset() {
        progressLayer.removeAllAnimations()
        progressLayer.strokeEnd = 0
    }
}

class DashboardCollectionViewController: UICollectionViewController, UICollectionViewDelegateFlowLayout {

    let items  = ["Streak", "Activity Ring", "Mood Count", "Next Session", "Mood Log", "Logs", "Journaling", "Art"]
    let images = [UIImage(systemName: "book"), UIImage(systemName: "paintpalette")]

    @IBOutlet var moodCount: UILabel!

    var toDoItems:    [TodayActivityItem] = []
    var ActivityLogs: [ActivityLog]       = []
    var mood:         [MoodLog]           = []
    
    var currentStreak: Int = 0

    var patient: Patient? {
        didSet {
            guard patient != nil else { return }
            load()
        }
    }

    private func makeDashboardMenu() -> UIMenu {
        let profile = UIAction(title: "Profile", image: UIImage(systemName: "person")) { _ in
            self.performSegue(withIdentifier: "PatientProfile", sender: nil)
        }
        let appointments = UIAction(title: "Appointments", image: UIImage(systemName: "calendar")) { _ in }
        let settings = UIAction(title: "Settings", image: UIImage(systemName: "gear")) { _ in
            self.performSegue(withIdentifier: "PateintSetting", sender: nil)
        }
        return UIMenu(title: "", children: [profile, appointments, settings])
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.largeTitleDisplayMode = .always
        collectionView.collectionViewLayout  = generateLayout()
        collectionView.alwaysBounceVertical  = true

        let menu = makeDashboardMenu()
        let more = UIBarButtonItem(image: UIImage(systemName: "ellipsis"), menu: menu)
        navigationItem.rightBarButtonItem = more
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        load()
        resetMoodViews()
    }

    func load() {
        guard let patientID = patient?.patientID else { return }
        let today = Date()
        let cal   = Calendar.current

        Task {
            do {
                // ✅ All 3 fetched in parallel
                async let todayTask = buildTodayItems(for: patientID)
                async let logsTask  = AccessSupabase.shared.fetchLogs(for: patientID)
                async let moodTask  = AccessSupabase.shared.fetchMoodLogs(patientID: patientID)

                let allItems = try await todayTask
                let logs     = try await logsTask
                let moods    = try await moodTask

                let allToday = allItems.map { item -> TodayActivityItem in
                    let todayLogs = item.logs.filter {
                        cal.isDate($0.date, inSameDayAs: today)
                    }
                    return TodayActivityItem(
                        activity:       item.activity,
                        assignment:     item.assignment,
                        completedToday: todayLogs.count,
                        logs:           todayLogs
                    )
                }

                // ✅ Compute streak here once, not inside cellForItemAt
                let allLoggedDates: Set<Date> = Set(logs.map { cal.startOfDay(for: $0.date) })
                var streak = 0
                if let mostRecentDate = allLoggedDates.sorted().last {
                    var checkDate = mostRecentDate
                    while allLoggedDates.contains(checkDate) {
                        streak += 1
                        guard let prev = cal.date(byAdding: .day, value: -1, to: checkDate) else { break }
                        checkDate = prev
                    }
                }

                await MainActor.run {
                    self.ActivityLogs   = logs
                    self.mood           = moods
                    self.currentStreak  = streak
                    self.toDoItems      = allToday.filter { !$0.isCompletedToday }
                    self.collectionView.reloadSections(IndexSet([0, 2]))
                    self.collectionView.reloadItems(at: [IndexPath(row: 1, section: 1)])
                }

            } catch {
                print("Load error: \(error)")
            }
        }
    }

    override func numberOfSections(in collectionView: UICollectionView) -> Int { 3 }

    override func collectionView(_ collectionView: UICollectionView,
                                 numberOfItemsInSection section: Int) -> Int {
        switch section {
        case 0:  return 1
        case 1:  return 5
        default: return toDoItems.count
        }
    }

    override func collectionView(_ collectionView: UICollectionView,
                                 cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        switch indexPath.section {

        case 0:
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: "streakCell", for: indexPath
            ) as! StreakCell

            // ✅ ActivityLogs has ALL logs, toDoItems only has incomplete ones
            let cal = Calendar.current
            let thisWeekDates: [Date] = ActivityLogs
                .map { $0.date }
                .filter { cal.isDate($0, equalTo: Date(), toGranularity: .weekOfYear) }

            cell.loggedDates = thisWeekDates
            cell.configure()
            cell.updateStreak(currentStreak)
            style(cell)
            return cell

        case 1:
            if indexPath.row == 0 {
                let cell = collectionView.dequeueReusableCell(
                    withReuseIdentifier: "activityRing", for: indexPath
                ) as! ActivityRingCell
                cell.configure(progress: 1/3)
                if let label = cell.viewWithTag(1) as? UILabel { label.text = items[indexPath.row + 1] }
                style(cell)
                return cell
            }
            else if indexPath.row == 1 {
                let cell = collectionView.dequeueReusableCell(
                    withReuseIdentifier: "moodCount", for: indexPath
                ) as! MoodCollectionViewCell
                cell.configure(mood: mood)
                style(cell)
                return cell
            }
            else if indexPath.row == 2 {
                let cell = collectionView.dequeueReusableCell(
                    withReuseIdentifier: "nextSession", for: indexPath
                ) as! NextSessionCell
                var comps  = DateComponents()
                comps.year = 2026; comps.month = 3; comps.day = 26
                comps.hour = 14;   comps.minute = 0
                let sessionDate = Calendar.current.date(from: comps) ?? Date()
                cell.configure(doctorName: "Dr. Meena Kumari", sessionDate: sessionDate)
                style(cell)
                return cell
            }
            else if indexPath.row == 3 {
                let cell = collectionView.dequeueReusableCell(
                    withReuseIdentifier: "moodLog", for: indexPath
                ) as! MoodLogCollectionViewCell
                cell.configureTap(target: self, action: #selector(moodTapped(_:)))
                if let label = cell.viewWithTag(1) as? UILabel { label.text = items[indexPath.row + 1] }
                style(cell)
                return cell
            }
            else {
                let cell = collectionView.dequeueReusableCell(
                    withReuseIdentifier: "section", for: indexPath
                )
                return cell
            }

        default:
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: "BasicCell", for: indexPath
            )
            let item = toDoItems[indexPath.row]
            if let label = cell.viewWithTag(1) as? UILabel  { label.text  = item.activity.name }
            if let image = cell.viewWithTag(2) as? UIImageView { image.image = UIImage(systemName: item.activity.iconName) }
            style(cell)
            return cell
        }
    }

    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        let fullWidth = collectionView.frame.width - 32
        let halfWidth = (fullWidth - 8) / 2

        switch indexPath.section {
        case 0:  return CGSize(width: fullWidth, height: 150)
        case 1:
            if indexPath.row == 0 || indexPath.row == 1 { return CGSize(width: halfWidth, height: 150) }
            else if indexPath.row == 2 { return CGSize(width: fullWidth, height: 122) }
            else if indexPath.row == 3 { return CGSize(width: fullWidth, height: 215) }
            else                        { return CGSize(width: fullWidth, height: 30)  }
        default: return CGSize(width: fullWidth, height: 70)
        }
    }

    func generateLayout() -> UICollectionViewLayout {
        let layout = UICollectionViewFlowLayout()
        layout.minimumInteritemSpacing = 8
        layout.minimumLineSpacing      = 16
        layout.sectionInset = UIEdgeInsets(top: 16, left: 12, bottom: 16, right: 12)
        return layout
    }

//    @objc func moodTapped(_ sender: UITapGestureRecognizer) {
//        guard let selectedView = sender.view else { return }
//        let selectedIndex = selectedView.tag
//        UIView.animate(withDuration: 0.15, delay: 0,
//                       usingSpringWithDamping: 0.6,
//                       initialSpringVelocity: 0.8, options: []) {
//            selectedView.transform = CGAffineTransform(scaleX: 1.15, y: 1.15)
//        }
//        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
//            self.performSegue(withIdentifier: "moodLog", sender: selectedIndex)
//        }
//    }
    @objc func moodTapped(_ sender: UITapGestureRecognizer) {
        guard let selectedView = sender.view else { return }

        // ✅ Find the mood count cell and check cooldown
        if let moodCell = collectionView.cellForItem(at: IndexPath(row: 1, section: 1)) as? MoodCollectionViewCell,
           !moodCell.canLogNow {
            // Shake to signal "not yet"
            let shake = CAKeyframeAnimation(keyPath: "transform.translation.x")
            shake.values   = [0, -8, 8, -6, 6, -4, 4, 0]
            shake.duration = 0.4
            selectedView.layer.add(shake, forKey: "shake")

            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.warning)
            return
        }

        let selectedIndex = selectedView.tag
        UIView.animate(withDuration: 0.15, delay: 0,
                       usingSpringWithDamping: 0.6,
                       initialSpringVelocity: 0.8, options: []) {
            selectedView.transform = CGAffineTransform(scaleX: 1.15, y: 1.15)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.performSegue(withIdentifier: "moodLog", sender: selectedIndex)
        }
    }
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "moodLog",
           let nav  = segue.destination as? UINavigationController,
           let vc   = nav.viewControllers.first as? MoodLogCollectionViewController,
           let data = sender as? Int {
            vc.selectedMood = data
            vc.patientId    = self.patient?.patientID
            vc.onDismiss    = { [weak self] in self?.resetMoodViews() }
            vc.onCheck      = { [weak self] in
                self?.load()
                self?.resetMoodViews()
            }
        }
    }

    func resetMoodViews() {
        for cell in collectionView.visibleCells {
            if let moodCell = cell as? MoodLogCollectionViewCell {
                UIView.animate(withDuration: 0.1) {
                    for view in moodCell.moodViews { view.transform = .identity }
                }
            }
        }
    }

    func style(_ cell: UICollectionViewCell) {
        cell.layer.shadowColor             = UIColor.black.cgColor
        cell.layer.shadowOpacity           = 0.08
        cell.layer.shadowOffset            = CGSize(width: 0, height: 2)
        cell.layer.shadowRadius            = 5
        cell.layer.masksToBounds           = false
        cell.contentView.layer.cornerRadius  = 20
        cell.contentView.layer.masksToBounds = true
        cell.layer.cornerRadius            = 20
        cell.layer.shadowPath              = UIBezierPath(roundedRect: cell.bounds, cornerRadius: 20).cgPath
    }
}
