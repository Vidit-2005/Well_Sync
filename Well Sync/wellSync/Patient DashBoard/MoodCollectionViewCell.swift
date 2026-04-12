//
//  MoodCountCollectionViewCell.swift
//  wellSync
//
//  Created by Vidit Saran Agarwal on 30/03/26.

//import UIKit
//
//class MoodCollectionViewCell: UICollectionViewCell {
//
//    @IBOutlet var MoodCount: UILabel!
//    @IBOutlet var logNowBadge: UILabel!
//    @IBOutlet var timerStack: UIStackView!
//    @IBOutlet var timerLabel: UILabel!
//
//    var totalMood: [MoodLog] = []
//    var todayMood: [MoodLog] = []
//
//    private var countdownTimer: Timer?
//    private let cooldown: TimeInterval = 3.5 * 3600   // 3.5 hours in seconds
//
//    override func awakeFromNib() {
//        super.awakeFromNib()
//    }
//
//    override func prepareForReuse() {
//        super.prepareForReuse()
//        countdownTimer?.invalidate()
//        countdownTimer = nil
//    }
//
//    func configure(mood: [MoodLog]) {
//        totalMood = mood
//        let today = Date()
//        todayMood = totalMood.filter { Calendar.current.isDate($0.date, inSameDayAs: today) }
//        MoodCount.text = "\(todayMood.count)"
//
//        guard logNowBadge != nil else { return }  // ← don't start if outlet missing
//        startCountdown()
//    }
//
//    // ─── Countdown ────────────────────────────────────────────────────────────
//
//    private func startCountdown() {
//        countdownTimer?.invalidate()
//        updateTimerLabel()
//        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
//            self?.updateTimerLabel()
//        }
//    }
//
//    private func updateTimerLabel() {
//        guard let lastLog = totalMood.sorted(by: { $0.date > $1.date }).first else {
//            showReadyState()
//            return
//        }
//
//        let remaining = lastLog.date.addingTimeInterval(cooldown).timeIntervalSinceNow
//
//        if remaining <= 0 {
//            showReadyState()
//            countdownTimer?.invalidate()
//        } else {
//            let h = Int(remaining) / 3600
//            let m = (Int(remaining) % 3600) / 60
//            let s = Int(remaining) % 60
//            logNowBadge?.text      = String(format: "%02d:%02d:%02d", h, m, s)  // ← just the time
//            logNowBadge?.textColor = .secondaryLabel
//        }
//    }
//
//    private func showReadyState() {
//        logNowBadge?.text      = "Log ✓"   // ← short and clear
//        logNowBadge?.textColor = .systemGreen
//    }
//
//    // ─── Public helper so Dashboard can gate the tap ──────────────────────────
//
//    var canLogNow: Bool {
//        guard let lastLog = totalMood.sorted(by: { $0.date > $1.date }).first else { return true }
//        return lastLog.date.addingTimeInterval(cooldown).timeIntervalSinceNow <= 0
//    }
//}

import UIKit

class MoodCollectionViewCell: UICollectionViewCell {

    // MARK: - Outlets
    @IBOutlet weak var MoodCount: UILabel!
    @IBOutlet weak var logNowBadge: UILabel!
    @IBOutlet weak var timerStack: UIStackView!
    @IBOutlet weak var timerLabel: UILabel!
    
    // Connect the 6 dots from Storyboard (Left to Right)
    @IBOutlet var moodDots: [UIView]!

    // MARK: - Data Properties
    var totalMood: [MoodLog] = []
    var todayMood: [MoodLog] = []

    private var countdownTimer: Timer?
    private let cooldown: TimeInterval = 3.5 * 3600   // 3.5 hours in seconds
    private let maxDailyLogs = 6 // Maximum logs per day

    // MARK: - Lifecycle
    override func awakeFromNib() {
        super.awakeFromNib()
        setupCardStyle()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        countdownTimer?.invalidate()
        countdownTimer = nil
        
        // Clean up animations before cell is reused
        logNowBadge?.layer.removeAllAnimations()
        moodDots?.forEach { dot in
            dot.layer.removeAllAnimations()
            dot.layer.sublayers?.filter { $0.name == "pulseLayer" }.forEach { $0.removeFromSuperlayer() }
        }
    }
    
    private func setupCardStyle() {
        logNowBadge?.layer.cornerRadius = 6
        logNowBadge?.layer.masksToBounds = true
    }

    func configure(mood: [MoodLog]) {
        totalMood = mood
        let today = Date()
        todayMood = totalMood.filter { Calendar.current.isDate($0.date, inSameDayAs: today) }
        
        // Cap visual count at maxDailyLogs
        MoodCount.text = "\(min(todayMood.count, maxDailyLogs))"

        guard logNowBadge != nil else { return }

        if todayMood.count >= maxDailyLogs {
            showAllDoneState()
        } else {
            startCountdown()
        }
        
        updateStepperUI()
    }

    // ─── Countdown & Dynamic Header ───────────────────────────────────────────

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
            // State: Waiting for Cooldown (Show Timer Stack)
            logNowBadge?.isHidden = true
            timerStack?.isHidden = false
            
            let h = Int(remaining) / 3600
            let m = (Int(remaining) % 3600) / 60
            let s = Int(remaining) % 60
            timerLabel?.text = String(format: "%02d:%02d:%02d", h, m, s)
            
            updateStepperUI() // Keep stepper updated during transition
        }
    }

    private func showReadyState() {
        // State: Ready to Log (Show LOG NOW badge)
        logNowBadge?.isHidden = false
        timerStack?.isHidden = true
        
        logNowBadge?.text = "LOG NOW"
        logNowBadge?.textColor = .systemBlue
        logNowBadge?.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.1)
        
        updateStepperUI()
    }
    
    private func showAllDoneState() {
        // State: Completed for the day
        countdownTimer?.invalidate()
        logNowBadge?.isHidden = false
        timerStack?.isHidden = true
        
        logNowBadge?.text = "ALL DONE"
        logNowBadge?.textColor = .systemGreen
        logNowBadge?.backgroundColor = UIColor.systemGreen.withAlphaComponent(0.1)
        logNowBadge?.layer.removeAllAnimations()
        
        updateStepperUI()
    }

    // ─── Stepper UI logic ─────────────────────────────────────────────────────
    
    private func updateStepperUI() {
        guard let dots = moodDots, !dots.isEmpty else { return }
        
        let loggedCount = todayMood.count
        let isReady = canLogNow
        
        for (index, dot) in dots.enumerated() {
            dot.layer.cornerRadius = dot.frame.height / 2
            
            // Reset transforms and remove old pulse layers
            dot.transform = .identity
            dot.layer.sublayers?.filter { $0.name == "pulseLayer" }.forEach { $0.removeFromSuperlayer() }
            
            if index < loggedCount {
                // 1. Logged (Green)
                dot.backgroundColor = .systemGreen
                dot.layer.borderColor = UIColor.white.cgColor
                dot.layer.borderWidth = 2
                
            } else if index == loggedCount && isReady && loggedCount < maxDailyLogs {
                // 2. Current / Ready to log (Blue Pulsing)
                dot.backgroundColor = .white
                dot.layer.borderColor = UIColor.systemBlue.cgColor
                dot.layer.borderWidth = 3
                addPulseAnimation(to: dot)
                
            } else {
                // 3. Future / Waiting for timer (Small Grey)
                dot.transform = CGAffineTransform(scaleX: 0.75, y: 0.75)
                dot.backgroundColor = .systemGray5
                dot.layer.borderColor = UIColor.white.cgColor
                dot.layer.borderWidth = 2
            }
        }
    }
    
    // ─── Animations ───────────────────────────────────────────────────────────
    
    private func addPulseAnimation(to view: UIView) {
        // Prevent duplicate animations
        guard view.layer.animation(forKey: "pulse") == nil else { return }
        
        let pulseLayer = CALayer()
        pulseLayer.name = "pulseLayer"
        pulseLayer.frame = view.bounds
        pulseLayer.cornerRadius = view.bounds.height / 2
        pulseLayer.borderColor = UIColor.systemBlue.withAlphaComponent(0.5).cgColor
        pulseLayer.borderWidth = 2
        view.layer.addSublayer(pulseLayer)
        
        let scaleAnimation = CABasicAnimation(keyPath: "transform.scale")
        scaleAnimation.toValue = 1.6
        
        let opacityAnimation = CABasicAnimation(keyPath: "opacity")
        opacityAnimation.fromValue = 1.0
        opacityAnimation.toValue = 0.0
        
        let group = CAAnimationGroup()
        group.animations = [scaleAnimation, opacityAnimation]
        group.duration = 1.5
        group.repeatCount = .infinity
        group.timingFunction = CAMediaTimingFunction(name: .easeOut)
        
        pulseLayer.add(group, forKey: "pulse")
    }

    // ─── Public helper so Dashboard can gate the tap ──────────────────────────

    var canLogNow: Bool {
        if todayMood.count >= maxDailyLogs { return false } // Max daily logs reached
        guard let lastLog = totalMood.sorted(by: { $0.date > $1.date }).first else { return true }
        return lastLog.date.addingTimeInterval(cooldown).timeIntervalSinceNow <= 0
    }
}
