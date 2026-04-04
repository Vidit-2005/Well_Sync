//
//  MoodCountCollectionViewCell.swift
//  wellSync
//
//  Created by Vidit Saran Agarwal on 30/03/26.

import UIKit

class MoodCollectionViewCell: UICollectionViewCell {

    @IBOutlet var MoodCount: UILabel!
    @IBOutlet var indicator: UIView!
    @IBOutlet var timerForNext: UILabel!

    var totalMood: [MoodLog] = []
    var todayMood: [MoodLog] = []

    private var chartView: MoodBarChartView?
    private var countdownTimer: Timer?
    private let cooldown: TimeInterval = 3.5 * 3600   // 3.5 hours in seconds

    override func awakeFromNib() {
        super.awakeFromNib()
        setupChartView()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        countdownTimer?.invalidate()
        countdownTimer = nil
    }

    private func setupChartView() {
        let chart = MoodBarChartView()
        chart.translatesAutoresizingMaskIntoConstraints = false
        chart.backgroundColor = .clear
        indicator.addSubview(chart)
        NSLayoutConstraint.activate([
            chart.leadingAnchor.constraint(equalTo: indicator.leadingAnchor),
            chart.trailingAnchor.constraint(equalTo: indicator.trailingAnchor),
            chart.topAnchor.constraint(equalTo: indicator.topAnchor),
            chart.bottomAnchor.constraint(equalTo: indicator.bottomAnchor)
        ])
        chartView = chart
    }

    func configure(mood: [MoodLog]) {
        totalMood = mood
        let today = Date()
        todayMood = totalMood.filter { Calendar.current.isDate($0.date, inSameDayAs: today) }
        chartView?.update(with: todayMood)
        MoodCount.text = "\(todayMood.count)"

        guard timerForNext != nil else { return }  // ← don't start if outlet missing
        startCountdown()
    }

    // ─── Countdown ────────────────────────────────────────────────────────────

    private func startCountdown() {
        countdownTimer?.invalidate()
        updateTimerLabel()
        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            self?.updateTimerLabel()
        }
    }

    private func updateTimerLabel() {
        guard let lastLog = totalMood.sorted(by: { $0.date > $1.date }).first else {
            showReadyState()
            return
        }

        let remaining = lastLog.date.addingTimeInterval(cooldown).timeIntervalSinceNow

        if remaining <= 0 {
            showReadyState()
            countdownTimer?.invalidate()
        } else {
            let h = Int(remaining) / 3600
            let m = (Int(remaining) % 3600) / 60
            let s = Int(remaining) % 60
            timerForNext?.text      = String(format: "%02d:%02d:%02d", h, m, s)  // ← just the time
            timerForNext?.textColor = .secondaryLabel
        }
    }

    private func showReadyState() {
        timerForNext?.text      = "Log ✓"   // ← short and clear
        timerForNext?.textColor = .systemGreen
    }

    // ─── Public helper so Dashboard can gate the tap ──────────────────────────

    var canLogNow: Bool {
        guard let lastLog = totalMood.sorted(by: { $0.date > $1.date }).first else { return true }
        return lastLog.date.addingTimeInterval(cooldown).timeIntervalSinceNow <= 0
    }
}

class MoodBarChartView: UIView {

    private let moodColors: [UIColor] = [
        UIColor(red: 0.87, green: 0.26, blue: 0.26, alpha: 1), // red      - mood 1
        UIColor(red: 0.94, green: 0.51, blue: 0.13, alpha: 1), // orange   - mood 2
        UIColor(red: 0.95, green: 0.78, blue: 0.18, alpha: 1), // yellow   - mood 3
        UIColor(red: 0.55, green: 0.76, blue: 0.29, alpha: 1), // lt green - mood 4
        UIColor(red: 0.20, green: 0.53, blue: 0.20, alpha: 1)  // dk green - mood 5
    ]

    // counts[0] = mood 1 count ... counts[4] = mood 5 count
    var counts: [Int] = [0, 0, 0, 0, 0] {
        didSet { setNeedsLayout() }
    }

    private var barLayers: [CAShapeLayer] = []

    override func layoutSubviews() {
        super.layoutSubviews()
        drawBars()
    }
    private func drawBars() {
        barLayers.forEach { $0.removeFromSuperlayer() }
        barLayers.removeAll()

        let fixedMax:       CGFloat = 6
        let barCount        = 5
        let spacing:        CGFloat = 12
        let barWidth:       CGFloat = (bounds.width - spacing * CGFloat(barCount - 1)) / CGFloat(barCount)
        let maxBarHeight:   CGFloat = bounds.height - 1
        let emptyBarHeight: CGFloat = barWidth * 0.5

        for i in 0..<barCount {
            let count = counts[i]

            let barHeight: CGFloat
            let alpha: CGFloat

            if count == 0 {
                barHeight = emptyBarHeight
                alpha = 0.25
            } else {
                let ratio = CGFloat(count) / fixedMax
                barHeight = emptyBarHeight + ratio * (maxBarHeight - emptyBarHeight)
                alpha = 1.0
            }

            let xOrigin = CGFloat(i) * (barWidth + spacing)
            let yOrigin = bounds.height - barHeight

            let rect   = CGRect(x: xOrigin, y: yOrigin, width: barWidth, height: barHeight)
            let path   = UIBezierPath(roundedRect: rect, cornerRadius: barWidth / 2)

            let shapeLayer       = CAShapeLayer()
            shapeLayer.path      = path.cgPath
            shapeLayer.fillColor = moodColors[i].withAlphaComponent(alpha).cgColor

            layer.addSublayer(shapeLayer)
            barLayers.append(shapeLayer)
        }
    }
    
    func update(with logs: [MoodLog]) {
        var c = [0, 0, 0, 0, 0]
        for log in logs {
            let index = log.mood - 1
            if index >= 0 && index < 5 {
                c[index] += 1
            }
        }
        counts = c
    }
}
