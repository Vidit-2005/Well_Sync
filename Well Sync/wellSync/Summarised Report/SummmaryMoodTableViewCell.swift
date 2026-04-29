//
//  SummmaryMoodTableViewCell.swift
//  wellSync
//
//  Created by Vidit Saran Agarwal on 07/02/26.
//

import UIKit
import DGCharts

class SummmaryMoodTableViewCell: UITableViewCell, ChartViewDelegate {

    @IBOutlet weak var lineChart: LineChartView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var leftButton: UIButton!
    @IBOutlet weak var rightButton: UIButton!

    private var moodLogs: [MoodLog] = []
    private let marker = MoodBubbleMarker()

    private var currentWeekStart: Date = Calendar.current.startOfDay(for: Date())

    override func awakeFromNib() {
        super.awakeFromNib()
        setupUI()
        setupChart()
        setupButtons()
    }

    // MARK: - Configure

    func configure(moodLogs: [MoodLog]) {
        self.moodLogs = moodLogs
        setCurrentWeek()
        updateChart()
    }

    // MARK: - UI

    private func setupUI() {
        backgroundColor = .clear
        contentView.backgroundColor = .tertiarySystemBackground

        contentView.layer.cornerRadius = 16
        contentView.layer.masksToBounds = true

        titleLabel.font = .systemFont(ofSize: 16, weight: .semibold)
    }

    private func setupButtons() {
        leftButton.addTarget(self, action: #selector(previousWeek), for: .touchUpInside)
        rightButton.addTarget(self, action: #selector(nextWeek), for: .touchUpInside)
    }

    // MARK: - Week Navigation

    private func setCurrentWeek() {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        let weekday = cal.component(.weekday, from: today) // Sun = 1
        currentWeekStart = cal.date(byAdding: .day, value: -(weekday - 1), to: today)!
    }

    @objc private func previousWeek() {
        currentWeekStart = Calendar.current.date(byAdding: .day, value: -7, to: currentWeekStart)!
        updateChart()
    }

    @objc private func nextWeek() {
        currentWeekStart = Calendar.current.date(byAdding: .day, value: 7, to: currentWeekStart)!
        updateChart()
    }

    // MARK: - Chart Setup

    private func setupChart() {
        lineChart.delegate = self
        marker.chartView = lineChart
        lineChart.marker = marker

        // Axis
        let xAxis = lineChart.xAxis
        xAxis.labelPosition = .bottom
        xAxis.granularity = 1
        xAxis.drawGridLinesEnabled = false
        xAxis.labelFont = .systemFont(ofSize: 11)

        let leftAxis = lineChart.leftAxis
        leftAxis.axisMinimum = 0
        leftAxis.axisMaximum = 6
        leftAxis.granularity = 1
        leftAxis.drawGridLinesEnabled = true
        leftAxis.labelFont = .systemFont(ofSize: 11)

        lineChart.rightAxis.enabled = false

        // General
        lineChart.legend.enabled = true
        lineChart.chartDescription.enabled = false
        lineChart.setScaleEnabled(false)
        lineChart.doubleTapToZoomEnabled = false
        lineChart.highlightPerTapEnabled = true

        // Spacing
        lineChart.extraTopOffset = 10
        lineChart.extraBottomOffset = 10
    }

    // MARK: - Chart Data

    private func updateChart() {

        guard !moodLogs.isEmpty else {
            lineChart.data = nil
            return
        }

        let cal = Calendar.current
        let startDate = currentWeekStart
        let totalDays = 7

        let dayDates: [Date] = (0..<totalDays).compactMap {
            cal.date(byAdding: .day, value: $0, to: startDate)
        }

        // Title
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM"
        let endDate = dayDates.last!
        titleLabel.text = "\(formatter.string(from: startDate)) - \(formatter.string(from: endDate))"

        // X Labels
        let xFormatter = DateFormatter()
        xFormatter.dateFormat = "EEE"

        let labels = dayDates.map { xFormatter.string(from: $0) }

        let xAxis = lineChart.xAxis
        xAxis.valueFormatter = IndexAxisValueFormatter(values: labels)
        xAxis.axisMinimum = -0.5
        xAxis.axisMaximum = 6.5

        // Group logs
        var perDayValues: [Int: [(Double, MoodLog)]] = [:]

        for log in moodLogs {
            let day = cal.startOfDay(for: log.date)
            if let index = dayDates.firstIndex(of: day) {
                perDayValues[index, default: []].append((Double(log.mood), log))
            }
        }

        // MARK: Detailed Entries
        var entries: [(ChartDataEntry, MoodLog)] = []

        for (dayIndex, pairs) in perDayValues {
            let n = pairs.count

            for (idx, (value, log)) in pairs.enumerated() {
                let t = n == 1 ? 0.5 : Double(idx) / Double(n - 1)
                let x = Double(dayIndex) - 0.175 + 0.35 * t
                entries.append((ChartDataEntry(x: x, y: value), log))
            }
        }

        entries.sort { $0.0.x < $1.0.x }

        var xToLog: [Double: MoodLog] = [:]
        for (entry, log) in entries {
            xToLog[entry.x] = log
        }
        marker.xToLog = xToLog

        let detailedEntries = entries.map { $0.0 }

        let detailedSet = LineChartDataSet(entries: detailedEntries, label: "Mood logs")
        detailedSet.mode = .linear
        detailedSet.lineWidth = 1.5
        detailedSet.setColor(.systemBlue.withAlphaComponent(0.9))
        detailedSet.setCircleColor(.systemBlue)

        detailedSet.circleRadius = 4.0
        detailedSet.circleHoleRadius = 2.0
        detailedSet.circleHoleColor = .systemBackground

        detailedSet.drawCirclesEnabled = true
        detailedSet.drawValuesEnabled = false

        detailedSet.highlightEnabled = true
        detailedSet.highlightColor = .systemOrange
        detailedSet.highlightLineWidth = 1.5

        detailedSet.drawFilledEnabled = false

        // MARK: AVG LINE
        var avgEntries: [ChartDataEntry] = []

        for i in 0..<7 {
            if let values = perDayValues[i]?.map({ $0.0 }), !values.isEmpty {
                let avg = values.reduce(0, +) / Double(values.count)
                avgEntries.append(ChartDataEntry(x: Double(i), y: avg))
            }
        }

        // Neutral Line
        let neutralLine = ChartLimitLine(limit: 3)
        neutralLine.lineColor = .systemGray3
        lineChart.leftAxis.removeAllLimitLines()
        lineChart.leftAxis.addLimitLine(neutralLine)

        // FINAL DATA
        lineChart.data = LineChartData(dataSets: [detailedSet])
        lineChart.notifyDataSetChanged()

        // 🔥 SLOW SMOOTH ANIMATION
        lineChart.animate(
            xAxisDuration: 0.8,
            yAxisDuration: 1.0,
            easingOption: .easeOutQuart
        )
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        contentView.frame = contentView.frame.inset(
            by: UIEdgeInsets(top: 12, left: 16, bottom: 8, right: 16)
        )
    }
}
