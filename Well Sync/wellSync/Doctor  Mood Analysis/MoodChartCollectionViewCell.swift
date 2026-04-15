//
//  MoodChartCollectionViewCell.swift
//  wellSync
//
//  Created by Vidit Agarwal on 04/02/26.
//

import UIKit
import DGCharts

// MARK: - MoodBubbleMarker

class MoodBubbleMarker: MarkerView {

    private let label               = UILabel()
    private let padding: CGFloat    = 10
    var xToLog: [Double: MoodLog]   = [:]

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor             = UIColor.black.withAlphaComponent(0.85)
        layer.cornerRadius          = 10
        layer.masksToBounds         = true
        label.font                  = .systemFont(ofSize: 12, weight: .semibold)
        label.textColor             = .white
        label.textAlignment         = .center
        addSubview(label)
    }

    required init?(coder: NSCoder) { fatalError() }

    override func refreshContent(entry: ChartDataEntry, highlight: Highlight) {

        let timeFormatter           = DateFormatter()
        timeFormatter.dateFormat    = "HH:mm"

        let dayFormatter            = DateFormatter()
        dayFormatter.dateFormat     = "EEE, d MMM"

        var timeStr                 = ""
        var dayStr                  = ""
        var moodVal                 = Int(entry.y)

        if let log = xToLog[entry.x] {
            timeStr                 = timeFormatter.string(from: log.date)
            dayStr                  = dayFormatter.string(from: log.date)
            moodVal                 = Int(log.mood)
        }

        label.text                  = "\(dayStr)   \(timeStr)   Mood \(moodVal)"
        label.sizeToFit()

        frame.size                  = CGSize(
            width:  label.frame.width + padding * 2,
            height: label.frame.height + padding
        )
        label.center                = CGPoint(x: frame.width / 2, y: frame.height / 2)

        guard let chart = chartView else {
            self.offset = CGPoint(x: -frame.width / 2, y: -frame.height - 12)
            return
        }

        let chartWidth              = chart.bounds.width
        let bubbleW                 = frame.width
        let bubbleH                 = frame.height
        let gap: CGFloat            = 12
        let dotX                    = highlight.xPx
        let dotY                    = highlight.yPx

        var offsetX                 = -bubbleW / 2
        var offsetY                 = -bubbleH - gap

        let projectedLeft           = dotX + offsetX
        let projectedRight          = dotX + offsetX + bubbleW

        if projectedLeft < 4 {
            offsetX                 = -dotX + 4
        } else if projectedRight > chartWidth - 4 {
            offsetX                 = chartWidth - dotX - bubbleW - 4
        }

        if dotY + offsetY < 4 {
            offsetY                 = gap
        }

        self.offset                 = CGPoint(x: offsetX, y: offsetY)
    }
}

// MARK: - MoodChartCollectionViewCell

class MoodChartCollectionViewCell: UICollectionViewCell, ChartViewDelegate {

    @IBOutlet weak var moodChartView: LineChartView!

    private var _moodLogs:   [MoodLog] = []
    private var _isWeekly:   Bool      = true
    private var _rangeStart: Date      = Calendar.current.startOfDay(for: Date())

    private var detailedEntries: [ChartDataEntry] = []
    private let marker = MoodBubbleMarker()

    var moodLogs: [MoodLog] {
        get { _moodLogs }
        set { configure(moodLogs: newValue, rangeStart: _rangeStart, isWeekly: _isWeekly) }
    }

    var isWeekly: Bool {
        get { _isWeekly }
        set { configure(moodLogs: _moodLogs, rangeStart: _rangeStart, isWeekly: newValue) }
    }

    // MARK: - Lifecycle

    override func awakeFromNib() {
        super.awakeFromNib()
        setupChart()
        setData()
    }

    // MARK: - Configure  ← preferred entry-point
    func configure(moodLogs: [MoodLog], rangeStart: Date, isWeekly: Bool) {
        _moodLogs   = moodLogs
        _rangeStart = rangeStart
        _isWeekly   = isWeekly
        setupChart()
        setData()
    }

    // MARK: - Setup

    func setupChart() {
        moodChartView.delegate              = self
        marker.chartView                    = moodChartView
        moodChartView.marker                = marker

        let xAxis                           = moodChartView.xAxis
        xAxis.labelPosition                 = .bottom
        xAxis.granularity                   = 1
        xAxis.drawGridLinesEnabled          = false

        let leftAxis                        = moodChartView.leftAxis
        leftAxis.axisMinimum                = 0.0
        leftAxis.axisMaximum                = 6.0
        leftAxis.granularity                = 1
        leftAxis.drawGridLinesEnabled       = true

        moodChartView.rightAxis.enabled             = false
        moodChartView.legend.enabled                = true
        moodChartView.chartDescription.enabled      = false
        moodChartView.setScaleEnabled(false)
        moodChartView.pinchZoomEnabled              = false
        moodChartView.doubleTapToZoomEnabled        = false
        moodChartView.highlightPerTapEnabled        = true
    }

    // MARK: - Data
    func setData() {

        let cal = Calendar.current
        let totalDays: Int
        if _isWeekly {
            totalDays = 7
        } else {
            totalDays = cal.range(of: .day, in: .month, for: _rangeStart)?.count ?? 30
        }

        let dayDates: [Date] = (0..<totalDays).compactMap { offset in
            cal.date(byAdding: .day, value: offset, to: _rangeStart)
        }

        let dateFormatter           = DateFormatter()
        dateFormatter.dateFormat    = _isWeekly ? "EEE" : "d"
        let dayLabels               = dayDates.map { dateFormatter.string(from: $0) }

        let xAxis                   = moodChartView.xAxis
        xAxis.valueFormatter        = IndexAxisValueFormatter(values: dayLabels)
        xAxis.axisMinimum           = -0.5
        xAxis.axisMaximum           = Double(totalDays) - 0.5

        guard !_moodLogs.isEmpty else {
            moodChartView.data = nil
            moodChartView.notifyDataSetChanged()
            return
        }

        var perDayValues: [Int: [(Double, MoodLog)]] = [:]
        for log in _moodLogs {
            let logDay = cal.startOfDay(for: log.date)
            if let idx = dayDates.firstIndex(of: logDay) {
                perDayValues[idx, default: []].append((Double(log.mood), log))
            }
        }

        var entries: [(ChartDataEntry, MoodLog)] = []

        for (dayIndex, pairs) in perDayValues {
            let n = pairs.count
            for (idx, (value, log)) in pairs.enumerated() {
                let t: Double = n == 1 ? 0.5 : Double(idx) / Double(n - 1)
                let x         = Double(dayIndex) - 0.175 + 0.35 * t
                entries.append((ChartDataEntry(x: x, y: value), log))
            }
        }

        entries.sort { $0.0.x < $1.0.x }
        detailedEntries = entries.map { $0.0 }

        var xToLog: [Double: MoodLog] = [:]
        for (entry, log) in entries { xToLog[entry.x] = log }
        marker.xToLog = xToLog

        let dataSet                         = LineChartDataSet(entries: detailedEntries, label: "Mood logs")
        dataSet.mode                        = .linear
        dataSet.lineWidth                   = 1.5
        dataSet.setColor(.systemBlue)
        dataSet.setCircleColor(.systemBlue)
        dataSet.circleRadius                = 4.0
        dataSet.circleHoleRadius            = 2.0
        dataSet.circleHoleColor             = .systemBackground
        dataSet.drawCirclesEnabled          = true
        dataSet.drawValuesEnabled           = false
        dataSet.highlightEnabled            = true
        dataSet.highlightColor              = .systemOrange
        dataSet.highlightLineWidth          = 1.5
        dataSet.drawFilledEnabled           = false

        moodChartView.data = LineChartData(dataSet: dataSet)
        moodChartView.notifyDataSetChanged()
        moodChartView.animate(xAxisDuration: 0.4, yAxisDuration: 0.6, easingOption: .easeOutQuart)
    }

    // MARK: - ChartViewDelegate
    func chartValueNothingSelected(_ chartView: ChartViewBase) {
        moodChartView.highlightValues(nil)
    }
}
