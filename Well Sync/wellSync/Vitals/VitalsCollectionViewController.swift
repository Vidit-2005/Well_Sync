import UIKit

class VitalsCollectionViewController: UICollectionViewController, VitalsRangeNavigating, VitalsBarRangeNavigating {
    
    enum DisplayRange: Int {
        case weekly = 0
        case monthly = 1
    }
    
    private let allVitals: [(title: String, color: UIColor)] = [
        ("Sleep", .systemIndigo),
        ("Steps", .systemOrange)
    ]
    
    private var displayedVitals: [(title: String, color: UIColor)] = []
    
    private var displayRange: DisplayRange = .weekly {
        didSet {
            // Sync bar ranges with main segment selection while keeping offsets independent
            barRanges = Array(repeating: displayRange, count: allVitals.count)
            reloadAllCharts()
        }
    }
    
    private var lineOffset: Int = 0
    
    // Independent bar ranges and offsets per bar index (0: Sleep, 1: Steps)
    private var barRanges: [DisplayRange] = [.weekly, .weekly]
    private var barOffsets: [Int] = [0, 0]

    
    private func currentRangeText() -> String {
        let calendar = Calendar.current
        let today = Date()

        switch displayRange {

        case .weekly:
            // 3 week window
            let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: today)!.start
            let targetStart = calendar.date(byAdding: .weekOfYear, value: lineOffset, to: startOfWeek)!

            let targetEnd = calendar.date(byAdding: .day, value: 6, to: targetStart)!

            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d"

            return "\(formatter.string(from: targetStart)) – \(formatter.string(from: targetEnd))"


        case .monthly:
            let startOfMonth = calendar.dateInterval(of: .month, for: today)!.start
            let target = calendar.date(byAdding: .month, value: lineOffset, to: startOfMonth)!

            let formatter = DateFormatter()
            formatter.dateFormat = "MMM yyyy"

            return formatter.string(from: target)
        }
    }
    
    private func barRangeText(for index: Int) -> String {
        let calendar = Calendar.current
        let today = Date()
        let barRange = barRanges[safe: index] ?? .weekly
        let offset = barOffsets[safe: index] ?? 0
        switch barRange {
        case .weekly:
            let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: today)!.start
            let targetStart = calendar.date(byAdding: .weekOfYear, value: offset, to: startOfWeek)!
            let targetEnd = calendar.date(byAdding: .day, value: 6, to: targetStart)!
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d"
            return "\(formatter.string(from: targetStart)) – \(formatter.string(from: targetEnd))"
        case .monthly:
            let startOfMonth = calendar.dateInterval(of: .month, for: today)!.start
            let target = calendar.date(byAdding: .month, value: offset, to: startOfMonth)!
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM yyyy"
            return formatter.string(from: target)
        }
    }

    private func makeLineGraphData(for range: DisplayRange) -> LineGraphData {

        switch range {

        // ------------------------
        // WEEKLY (7 random days)
        // ------------------------
        case .weekly:

            let calendar = Calendar.current
            let today = Date()

            let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: today)!.start
            let targetStart = calendar.date(byAdding: .weekOfYear, value: lineOffset, to: startOfWeek)!

            var labels: [String] = []

            let formatter = DateFormatter()
            formatter.dateFormat = "EEE"

            for i in 0..<7 {
                let date = calendar.date(byAdding: .day, value: i, to: targetStart)!
                labels.append(formatter.string(from: date))
            }

            let points = (0..<7).map { _ in Double.random(in: 60...100) }

            return LineGraphData(xLabels: labels, points: points)


        // ------------------------
        // MONTHLY (4 weeks random)
        // ------------------------
        case .monthly:

            let labels = ["W1","W2","W3","W4"]

            let points = (0..<4).map { _ in Double.random(in: 400...600) }

            return LineGraphData(xLabels: labels, points: points)
        }
    }

    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Register cell classes
        self.collectionView!.register(UINib(nibName: "VitalsCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: "vitalCell")
        self.collectionView!.register(UINib(nibName: "VitalsBarCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: "vitalBarCell")
        collectionView.collectionViewLayout = generateLayout()
//        collectionView.dataSource = self   // UICollectionViewController provides dataSource already
        
        reloadAllCharts()
        // Do any additional setup after loading the view.
    }
    
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 2
    }


    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of items
        if section == 0{
            return 1
        }
        return 1 + displayedVitals.count
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if indexPath.section == 0{
            if indexPath.row == 0{
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "segment", for: indexPath)
                if let segmented = cell.contentView.subviews.compactMap({ $0 as? UISegmentedControl }).first ?? cell.viewWithTag(100) as? UISegmentedControl {
                    segmented.removeTarget(nil, action: nil, for: .allEvents)
                    segmented.selectedSegmentIndex = displayRange.rawValue
                    segmented.addTarget(self, action: #selector(segmentValueChanged(_:)), for: .valueChanged)
                }
                return cell
            }
//            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "filter", for: indexPath)
//            
//            return cell
        }
        
        if indexPath.section == 1 && indexPath.row == 0{
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "vitalCell", for: indexPath) as! VitalsCollectionViewCell
            cell.rangeDelegate = self
            let lineData = makeLineGraphData(for: displayRange)
            cell.configure(rangeText: currentRangeText(), xLabels: lineData.xLabels, points: lineData.points)
            return cell
        }
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "vitalBarCell", for: indexPath) as! VitalsBarCollectionViewCell
        
        let dataIndex = indexPath.row - 1
        guard dataIndex >= 0, dataIndex < displayedVitals.count else {
            return cell
        }

        if let label = cell.viewWithTag(1) as? UILabel {
            label.text = displayedVitals[dataIndex].title
            label.textColor = displayedVitals[dataIndex].color
        }

        let offset = barOffsets[safe: dataIndex] ?? 0
        let barRange = barRanges[safe: dataIndex] ?? .weekly

        cell.configure(
            index: dataIndex,
            range: barRange == .weekly ? .weekly : .monthly,
            offset: offset
        )

        cell.rangeDelegate = self
        return cell

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
            default:
                height = .absolute(280)
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
    
    private func reloadLineSection() {
        displayedVitals = allVitals
        let lineIndexPath = IndexPath(item: 0, section: 1)
        if collectionView.numberOfSections > 1 && collectionView.numberOfItems(inSection: 1) > 0 {
            collectionView.reloadItems(at: [lineIndexPath])
        } else {
            collectionView.reloadData()
        }
    }

    private func reloadBar(at row: Int) {
        let index = IndexPath(item: row, section: 1)
        guard collectionView.numberOfSections > 1, row < collectionView.numberOfItems(inSection: 1) else { return }
        collectionView.reloadItems(at: [index])
    }
    
    private struct LineGraphData {
        let xLabels: [String]
        let points: [Double]
    }
    
    @objc private func segmentValueChanged(_ sender: UISegmentedControl) {
        guard let range = DisplayRange(rawValue: sender.selectedSegmentIndex) else { return }
        displayRange = range
    }
    
    @IBAction func valueChnaged(_ sender: UISegmentedControl) {
        guard let range = DisplayRange(rawValue: sender.selectedSegmentIndex) else { return }
        displayRange = range
    }
    
    
    // MARK: - VitalsRangeNavigating
    func didTapPrevRange() {
        lineOffset = max(lineOffset - 1, -2)
        reloadLineSection()
    }
    
    func didTapNextRange() {
        lineOffset = min(lineOffset + 1, 0)
        reloadLineSection()
    }
    
    // MARK: - VitalsBarRangeNavigating
    func didTapPrevBarRange(for index: Int) {
        let dataIndex = max(0, index - 1)
        barOffsets[dataIndex] = max((barOffsets[safe: dataIndex] ?? 0) - 1, -2)
        reloadBar(at: index)
    }

    func didTapNextBarRange(for index: Int) {
        let dataIndex = max(0, index - 1)
        barOffsets[dataIndex] = min((barOffsets[safe: dataIndex] ?? 0) + 1, 0)
        reloadBar(at: index)
    }
    
    func didChangeBarRange(for index: Int, to range: Int) {
        let dataIndex = max(0, index - 1)
        let new = DisplayRange(rawValue: range) ?? .weekly
        if barRanges.indices.contains(dataIndex) {
            barRanges[dataIndex] = new
            // Clamp offset when switching to monthly: use the same bounds
            barOffsets[dataIndex] = min(max(barOffsets[dataIndex], -2), 0)
            reloadBar(at: index)
        }
    }
    private func reloadAllCharts() {
        displayedVitals = allVitals

        let items = [
            IndexPath(item: 0, section: 1), // line
            IndexPath(item: 1, section: 1), // sleep
            IndexPath(item: 2, section: 1)  // steps
        ]

        collectionView.reloadItems(at: items)
    }
    
}

private extension Array {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

