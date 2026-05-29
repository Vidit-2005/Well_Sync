//
//  MoodAnalysisCollectionViewController.swift
//  wellSync
//
//  Created by Vidit Agarwal on 04/02/26.
//

import UIKit
import FirebaseCore
import FirebaseAILogic
import FoundationModels

class MoodAnalysisCollectionViewController: UICollectionViewController {
    
    // MARK: - Properties
    
    let cards = ["Segment", "Calender", "Mood Count", "Mood Chart", "Insights"]
    var isPreloaded = false
    var moodLogs: [MoodLog] = []
    private var selectedSegmentIndex: Int = 0
    private var calendarCellHeight: CGFloat = 250
    
    
    private var currentVisibleRange: ClosedRange<Date>?
    
    var currPatient: Patient?
    
    var insign: String = ""
    private var insightCache: [String: String] = [:]
    private var isInsightLoading = false
    //    let model = SystemLanguageModel.default
    
    private let rangeCacheKeyFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()
    private var onboardingSequence: FeatureOnboardingSequence?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        collectionView.register(UINib(nibName: "CalendarCell1",                      bundle: nil), forCellWithReuseIdentifier: "calender")
        collectionView.register(UINib(nibName: "MoodChartCollectionViewCell",        bundle: nil), forCellWithReuseIdentifier: "bar_cell")
        collectionView.register(UINib(nibName: "MoodDistributionCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: "count_cell")
        collectionView.register(UINib(nibName: "insightsCollectionViewCell",         bundle: nil), forCellWithReuseIdentifier: "insights_cell")
        
        collectionView.collectionViewLayout = generateLayout()
        onboardingSequence = FeatureOnboardingSequence(
            viewController: self,
            storageKey: "doctor_mood_analysis"
        ) { [weak self] in
            self?.makeOnboardingSteps() ?? []
        }
        load()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        startOnboardingIfPossible()
    }
    
    // MARK: - Data Loading
    
    func load() {
        
        if isPreloaded {
            self.collectionView.reloadData()
            return
        }
        
        Task {
            do {
                let logs = try await AccessSupabase.shared.fetchMoodLogs(
                    patientID: currPatient?.patientID ??
                    UUID(uuidString: "00000000-0000-0000-0000-000000000000")!
                )
                
                await MainActor.run {
                    self.moodLogs = logs
                    self.collectionView.reloadData()
                    self.startOnboardingIfPossible()
                }
                
            } catch {
                print("Error fetching mood logs:", error)
            }
        }
    }
    
    // MARK: - Helpers
    
    private func filteredLogs(for range: ClosedRange<Date>) -> [MoodLog] {
        return moodLogs
            .filter { range.contains($0.date) }
            .sorted { $0.date < $1.date }
    }
    
    private func refreshDataCells(for range: ClosedRange<Date>, isWeekly: Bool) {
        currentVisibleRange = range
        let filtered   = filteredLogs(for: range)
        let rangeStart = range.lowerBound
        let cacheKey   = rangeCacheKeyFormatter.string(from: rangeStart)
        
        if let countCell = collectionView.cellForItem(
            at: IndexPath(item: 0, section: 2)
        ) as? MoodDistributionCollectionViewCell {
            countCell.configure(moodLogs: filtered)
        }
        
        if let chartCell = collectionView.cellForItem(
            at: IndexPath(item: 0, section: 3)
        ) as? MoodChartCollectionViewCell {
            chartCell.configure(moodLogs: filtered, rangeStart: rangeStart, isWeekly: isWeekly)
        }
        
        if let cached = insightCache[cacheKey] {
            // Previously seen range — show instantly.
            insign = cached
            if let insightCell = collectionView.cellForItem(
                at: IndexPath(item: 0, section: 4)
            ) as? insightsCollectionViewCell {
                insightCell.configur(with: cached)
            }
        } else if filtered.isEmpty {
            insign = "No mood logs recorded for this period."
            if let insightCell = collectionView.cellForItem(
                at: IndexPath(item: 0, section: 4)
            ) as? insightsCollectionViewCell {
                insightCell.configur(with: insign)
            }
        } else {
            insign = ""
            if let insightCell = collectionView.cellForItem(
                at: IndexPath(item: 0, section: 4)
            ) as? insightsCollectionViewCell {
                insightCell.configur(with: "Analyzing patient mood patterns…")
            }
            loadInsight(logs: filtered, rangeKey: cacheKey)
        }
    }
    
    private func loadInsight(logs: [MoodLog], rangeKey: String) {
        
        guard !isInsightLoading else { return }
        isInsightLoading = true
        
        Task {
            let result = await insightLocal(moodLog: logs)
            
            await MainActor.run {
                self.insightCache[rangeKey] = result
                self.isInsightLoading = false
                
                // Only update the UI if the user is still on this range.
                let currentKey = self.currentVisibleRange.map {
                    self.rangeCacheKeyFormatter.string(from: $0.lowerBound)
                }
                guard currentKey == rangeKey else { return }
                
                self.insign = result
                DispatchQueue.main.async {
                    self.collectionView.reloadSections(IndexSet(integer: 4))
                }
            }
        }
    }
    
    // MARK: - UICollectionViewDataSource
    
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return cards.count
    }
    
    override func collectionView(_ collectionView: UICollectionView,
                                 numberOfItemsInSection section: Int) -> Int {
        return 1
    }
    
    override func collectionView(_ collectionView: UICollectionView,
                                 cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        switch indexPath.section {
            
        case 1:
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: "calender", for: indexPath
            ) as! CalendarCell1
            style(cell)
            cell.moodLogs = moodLogs
            cell.delegate = self
            cell.configure(segment: selectedSegmentIndex)
            cell.onHeightChange = { [weak self] newHeight in
                guard let self = self else { return }
                self.calendarCellHeight = newHeight + 16
                self.collectionView.collectionViewLayout = self.generateLayout()
            }
            return cell
            
        case 2:
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: "count_cell", for: indexPath
            ) as! MoodDistributionCollectionViewCell
            style(cell)
            if let range = currentVisibleRange {
                cell.configure(moodLogs: filteredLogs(for: range))
            } else {
                cell.configure(moodLogs: [])
            }
            return cell
            
        case 3:
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: "bar_cell", for: indexPath
            ) as! MoodChartCollectionViewCell
            style(cell)
            if let range = currentVisibleRange {
                cell.configure(
                    moodLogs:   filteredLogs(for: range),
                    rangeStart: range.lowerBound,
                    isWeekly:   selectedSegmentIndex == 0
                )
            } else {
                cell.configure(
                    moodLogs:   [],
                    rangeStart: Calendar.current.startOfDay(for: Date()),
                    isWeekly:   selectedSegmentIndex == 0
                )
            }
            return cell
            
        case 4:
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: "insights_cell", for: indexPath
            ) as! insightsCollectionViewCell
            style(cell)
            cell.configur(with: insign.isEmpty ? "Analyzing patient mood patterns…" : insign)
            return cell
            
        default:
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: "segment", for: indexPath)
            style(cell)
            return cell
        }
    }
    
    // MARK: - Segment Changed
    
    @IBAction func sectionChanged(_ sender: UISegmentedControl) {
        selectedSegmentIndex = sender.selectedSegmentIndex
        if let calCell = collectionView.cellForItem(
            at: IndexPath(item: 0, section: 1)
        ) as? CalendarCell1 {
            calCell.configure(segment: selectedSegmentIndex)
        }
        if let cell = collectionView.cellForItem(
            at: IndexPath(
                item: 0,
                section: 2
            )) as? MoodDistributionCollectionViewCell {
            if sender.selectedSegmentIndex == 0 {
                cell.distributinoType.text = "Weekly Distribution"
            }
            else{
                cell.distributinoType.text = "Monthly Distribution"
            }
        }
    }
    
    // MARK: - Onboarding

    private func makeOnboardingSteps() -> [FeatureSpotlightStep] {
        collectionView.layoutIfNeeded()
        return [
            FeatureSpotlightStep(
                title: "Switch weekly or monthly",
                message: "Use this toggle to change the analysis range.",
                placement: .below,
                targetProvider: { [weak self] in self?.collectionView.cellForItem(at: IndexPath(item: 0, section: 0)) }
            ),
            FeatureSpotlightStep(
                title: "Pick dates from calendar",
                message: "Select a week or month to load relevant mood logs.",
                placement: .below,
                targetProvider: { [weak self] in self?.collectionView.cellForItem(at: IndexPath(item: 0, section: 1)) }
            ),
            FeatureSpotlightStep(
                title: "Read mood distribution",
                message: "See how frequently each mood appears in the selected period.",
                placement: .above,
                targetProvider: { [weak self] in self?.collectionView.cellForItem(at: IndexPath(item: 0, section: 2)) }
            )
        ]
    }

    private func startOnboardingIfPossible() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            self.onboardingSequence?.startIfNeeded()
        }
    }
    
    // MARK: - Layout
    
    func generateLayout() -> UICollectionViewCompositionalLayout {
        return UICollectionViewCompositionalLayout { sectionIndex, _ in
            let height: NSCollectionLayoutDimension
            
            switch sectionIndex {
            case 0:
                let itemSize  = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .fractionalHeight(1.0))
                let item      = NSCollectionLayoutItem(layoutSize: itemSize)
                let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .estimated(50))
                let group     = NSCollectionLayoutGroup.vertical(layoutSize: groupSize, subitems: [item])
                group.interItemSpacing = .fixed(12)
                let section   = NSCollectionLayoutSection(group: group)
                section.interGroupSpacing = 12
                section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16)
                return section
            case 1:  height = .absolute(self.calendarCellHeight)
            case 2:  height = .estimated(380)
            case 3:  height = .estimated(240)
            default: height = .estimated(300)
            }
            
            let itemSize  = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: height)
            let item      = NSCollectionLayoutItem(layoutSize: itemSize)
            let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: height)
            let group     = NSCollectionLayoutGroup.vertical(layoutSize: groupSize, subitems: [item])
            group.interItemSpacing = .fixed(8)
            let section   = NSCollectionLayoutSection(group: group)
            section.interGroupSpacing = 8
            section.contentInsets = NSDirectionalEdgeInsets(top: 16, leading: 16, bottom: 0, trailing: 16)
            return section
        }
    }
    
    // MARK: - AI Insight (Gemini via Firebase AI Logic)
    
    func insightLocal(moodLog: [MoodLog]) async -> String {
        
        guard !moodLog.isEmpty else {
            return "No mood data available for clinical evaluation."
        }
        
        let sortedLogs = moodLog.sorted { $0.date < $1.date }
        
        let logsText = sortedLogs.map { log -> String in
            let date     = log.date.formatted(date: .abbreviated, time: .omitted)
            let note     = (log.moodNote ?? "No note").prefix(80)
            let feelings = log.selectedFeeling?.map { "\($0)" }.joined(separator: ", ") ?? "None"
            return """
            Date: \(date)
            Mood: \(log.mood)
            Feelings: \(feelings)
            Note: \(note)
            """
        }.joined(separator: "\n\n")
        
//        let prompt = """
//        You are a clinical assistant preparing a summary for a doctor.
//        Analyze the following mood logs and write a clinical summary.
//        Instructions:
//        - Mood scale: 1 = very bad, 2 = bad, 3 = neutral, 4 = happy, 5 = very happy
//        - Maximum 60 words
//        - Write in 2–3 sentences
//        - Use professional, objective tone
//        - Describe mood pattern, emotional indicators, and any noticeable changes
//        - Avoid words like "overall" or "seems" — be specific
//        - Do NOT give advice or recommendations
//        
//        Mood Logs:
//        \(logsText)
//        """
        
        let prompt = """
        You are a behavioral health analyst. Your task is to analyze mood log data and extract \
        meaningful psychological insights — not just describe what happened, but identify \
        patterns, trends, and anomalies.

        Mood Scale: 1 = Very Bad | 2 = Bad | 3 = Neutral | 4 = Happy | 5 = Very Happy

        Mood Logs:
        \(logsText)

        Analyze the data above and provide a concise, single-paragraph clinical summary.

        Rules:
        - Maximum 4 sentences and 60-80 words.
        - Write in a single, cohesive paragraph. Do not use bullet points, bold text, or sections.
        - Identify mood trends, recurring feelings, and any significant anomalies.
        - Be specific — cite mood scores and dates if highly relevant.
        - Do NOT give advice or recommendations.
        - Use professional, objective tone.
        - If data is insufficient to determine a pattern, state that explicitly.
        """
        
        let model = SystemLanguageModel.default
        
        switch model.availability {
        case .available:
            do {
                let session = LanguageModelSession()
                let response = try await session.respond(to: prompt)
                print("Foundation Modell.....")
                return response.content.trimmingCharacters(in: .whitespacesAndNewlines)
            } catch {
                print("⚠️ Foundation model failed, falling back to Gemini: \(error)")
            }
            
        case .unavailable(let reason):
            print("ℹ️ On-device model unavailable: \(reason)")
        }
        
//         ✅ Step C: Fallback — use Gemini
        do {
            let response = try await Summarise.summarise.model.generateContent(prompt)
            return response.text?.trimmingCharacters(in: .whitespacesAndNewlines)
            ?? "Could not generate insight."
        } catch {
            print("❌ Gemini insight error:", error)
            return "Insight unavailable. Please try again later."
        }
    }
}

extension MoodAnalysisCollectionViewController: CalendarCell1Delegate {

    func calendarCell(_ cell: CalendarCell1,
                      didChangeVisibleRange range: ClosedRange<Date>,
                      isWeekly: Bool) {
        refreshDataCells(for: range, isWeekly: isWeekly)
    }

    func calendarCell(_ cell: CalendarCell1,
                      didChangeHeight height: CGFloat) {
        calendarCellHeight = height + 16
        collectionView.collectionViewLayout = generateLayout()
    }
}
