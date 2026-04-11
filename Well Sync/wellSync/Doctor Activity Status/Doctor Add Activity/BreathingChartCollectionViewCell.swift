//
//  BreathingChartCollectionViewCell.swift
//  sample
//
//  Created by Pranjal on 01/04/26.
//

import Charts
import UIKit
import DGCharts

class BarChartMarkerView: MarkerView {

    private let label            = UILabel()
    private let padding: CGFloat = 10

    // Set this before assigning to chartView.marker
    var xLabels: [String]        = []

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor          = UIColor.black.withAlphaComponent(0.85)
        layer.cornerRadius       = 10
        layer.masksToBounds      = true
        label.font               = .systemFont(ofSize: 12, weight: .semibold)
        label.textColor          = .white
        label.textAlignment      = .center
        addSubview(label)
    }

    required init?(coder: NSCoder) { fatalError() }

    override func refreshContent(entry: ChartDataEntry, highlight: Highlight) {

        // Step 1: Get day label from index
        let index   = Int(entry.x)
        let day     = index < xLabels.count ? xLabels[index] : "Day \(index + 1)"

        // Step 2: Format the y value (minutes)
        let minutes = entry.y
        let valueStr: String
        if minutes <= 0 {
            valueStr = "No log"
        } else if minutes < 1.0 {
            let seconds = Int(minutes * 60)
            valueStr = "\(seconds) sec"
        } else {
            valueStr = String(format: "%.1f min", minutes)
        }

        // Step 3: Build label text
        label.text  = "\(day)   \(valueStr)"
        label.sizeToFit()

        // Step 4: Resize bubble to fit label + padding
        frame.size  = CGSize(
            width:  label.frame.width  + padding * 2,
            height: label.frame.height + padding
        )
        label.center = CGPoint(x: frame.width / 2, y: frame.height / 2)

        // Step 5: Smart positioning — avoid clipping at chart edges
        guard let chart = chartView else {
            self.offset = CGPoint(x: -frame.width / 2, y: -frame.height - 12)
            return
        }

        let chartWidth   = chart.bounds.width
        let bubbleW      = frame.width
        let bubbleH      = frame.height
        let gap: CGFloat = 12
        let dotX         = highlight.xPx
        let dotY         = highlight.yPx

        // Default: centered above the bar
        var offsetX      = -bubbleW / 2
        var offsetY      = -bubbleH - gap

        // If bubble goes off left edge → push right
        if dotX + offsetX < 4 {
            offsetX      = -dotX + 4
        }
        // If bubble goes off right edge → push left
        else if dotX + offsetX + bubbleW > chartWidth - 4 {
            offsetX      = chartWidth - dotX - bubbleW - 4
        }

        // If bubble goes above chart top → flip below the bar
        if dotY + offsetY < 4 {
            offsetY      = gap
        }

        self.offset      = CGPoint(x: offsetX, y: offsetY)
    }
}


class BreathingChartCollectionViewCell: UICollectionViewCell, ChartViewDelegate {

    @IBOutlet weak var cardView: UIView!
    @IBOutlet weak var chartView: BarChartView!

    // Stores the current x-axis labels so the marker can look them up by index
    private var currentLabels: [String] = []

    override func awakeFromNib() {
        super.awakeFromNib()

        cardView.layer.cornerRadius = 20
        cardView.layer.shadowColor = UIColor.black.cgColor
        cardView.layer.shadowOpacity = 0.08
        cardView.layer.shadowOffset = CGSize(width: 0, height: 3)
        cardView.layer.shadowRadius = 6

        // Set delegate so chartValueSelected fires
        chartView.delegate = self

        styleChart()
    }

    // MARK: - One-time chart styling

    private func styleChart() {
        chartView.rightAxis.enabled = false
        chartView.legend.enabled = false
        chartView.chartDescription.enabled = false

        chartView.xAxis.drawGridLinesEnabled = false
        chartView.xAxis.labelPosition = .bottom
        chartView.xAxis.granularity = 1

        chartView.leftAxis.gridColor = UIColor.systemGray4
        chartView.leftAxis.gridLineWidth = 0.5
        chartView.leftAxis.axisMinimum = 0
        chartView.leftAxis.spaceTop = 0.15
        chartView.leftAxis.valueFormatter = MinutesAxisFormatter()  // ← ADD THIS

        chartView.drawBordersEnabled = false
        chartView.highlightPerTapEnabled = true
        chartView.highlightPerDragEnabled = false

        chartView.noDataText = "No activity logged"
        chartView.noDataTextColor = .secondaryLabel
    }
    // Converts stored minutes → readable seconds or minutes for the y-axis
    class MinutesAxisFormatter: AxisValueFormatter {
        func stringForValue(_ value: Double, axis: AxisBase?) -> String {
            if value <= 0 { return "0" }
            if value < 1.0 {
                // e.g. 0.30 minutes → "18s"
                return "\(Int(value * 60))s"
            } else {
                // e.g. 2.5 minutes → "2.5m"
                return String(format: "%.1fm", value)
            }
        }
    }

    // MARK: - Configure entry point

    func configure(with logs: [ActivityLog], mode: Int, referenceDate: Date) {
        if mode == 0 {
            configureWeekly(logs: logs, referenceDate: referenceDate)
        } else {
            configureMonthly(logs: logs, referenceDate: referenceDate)
        }
    }

    // MARK: - Weekly

    private func configureWeekly(logs: [ActivityLog], referenceDate: Date) {
        let calendar = Calendar.current

        let weekday = calendar.component(.weekday, from: referenceDate)
        let daysFromSunday = weekday - 1
        guard let weekStart = calendar.date(
            byAdding: .day,
            value: -daysFromSunday,
            to: calendar.startOfDay(for: referenceDate)
        ) else { return }

        let dayLabels = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
        var minutesPerSlot: [Double] = Array(repeating: 0.0, count: 7)

        for log in logs {
            let logDay = calendar.startOfDay(for: log.date)
            let diff = calendar.dateComponents([.day], from: weekStart, to: logDay).day ?? -1
            guard diff >= 0 && diff < 7 else { continue }
            minutesPerSlot[diff] += Double(log.duration ?? 0) / 60.0
        }

        let entries = minutesPerSlot.enumerated().map { i, value in
            BarChartDataEntry(x: Double(i), y: value)
        }

        applyToChart(entries: entries, labels: dayLabels)
    }

    // MARK: - Monthly

    private func configureMonthly(logs: [ActivityLog], referenceDate: Date) {
        let calendar = Calendar.current

        let components = calendar.dateComponents([.year, .month], from: referenceDate)
        guard
            let firstOfMonth = calendar.date(from: components),
            let range = calendar.range(of: .day, in: .month, for: firstOfMonth)
        else { return }

        let daysInMonth = range.count
        var minutesPerDay: [Double] = Array(repeating: 0.0, count: daysInMonth)

        for log in logs {
            let logComps = calendar.dateComponents([.year, .month, .day], from: log.date)
            guard
                logComps.year  == components.year,
                logComps.month == components.month,
                let day = logComps.day,
                day >= 1 && day <= daysInMonth
            else { continue }
            minutesPerDay[day - 1] += Double(log.duration ?? 0) / 60.0
        }

        let entries = minutesPerDay.enumerated().map { i, value in
            BarChartDataEntry(x: Double(i), y: value)
        }

        // Full day-number labels for marker lookup, sparse display on x-axis
        let allDayLabels: [String] = (1...daysInMonth).map { "\($0)" }
        let displayLabels: [String] = (1...daysInMonth).map { day in
            day % 5 == 1 ? "\(day)" : ""
        }

        // Store full labels for marker, pass display labels for x-axis
        applyToChart(entries: entries, labels: displayLabels, markerLabels: allDayLabels)
    }

    // MARK: - Shared chart rendering

    /// - Parameters:
    ///   - entries: bar entries
    ///   - labels: what appears on the x-axis (may have empty strings)
    ///   - markerLabels: full labels used by the tap marker (defaults to labels if not provided)
    private func applyToChart(
        entries: [BarChartDataEntry],
        labels: [String],
        markerLabels: [String]? = nil
    ) {
        // Save labels for the marker to use
        currentLabels = markerLabels ?? labels

        guard !entries.isEmpty else {
            chartView.data = nil
            chartView.notifyDataSetChanged()
            return
        }

        let dataSet = BarChartDataSet(entries: entries)
        dataSet.setColor(UIColor.systemTeal.withAlphaComponent(0.8))
        dataSet.drawValuesEnabled = false
        dataSet.highlightColor = UIColor.systemIndigo.withAlphaComponent(0.4)
        dataSet.highlightAlpha = 1.0

        let data = BarChartData(dataSet: dataSet)
        data.barWidth = 0.6

        chartView.data = data

        chartView.xAxis.valueFormatter = IndexAxisValueFormatter(values: labels)
        chartView.xAxis.labelCount = labels.count
        chartView.fitBars = true

        // Create and assign the marker with current labels
        let marker = BarChartMarkerView()
        marker.xLabels = currentLabels
        marker.chartView = chartView
        chartView.marker = marker

        chartView.notifyDataSetChanged()
        chartView.animate(yAxisDuration: 0.4)
    }

    // MARK: - ChartViewDelegate — tap on a bar

    func chartValueSelected(_ chartView: ChartViewBase,
                            entry: ChartDataEntry,
                            highlight: Highlight) {
        // Marker appears automatically — nothing extra needed here.
        // Add any additional action on tap below if needed.
    }

    func chartValueNothingSelected(_ chartView: ChartViewBase) {
        // Tapping empty area hides the marker automatically
        chartView.highlightValue(nil)
    }
}
