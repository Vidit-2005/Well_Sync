//
//  ViewController.swift
//  breath ball
//
//  Created by Pranjal Raturi on 09/05/26.
//

import UIKit

final class breatheCircleViewController: UIViewController {

    @IBOutlet private weak var backgroundGradientView: UIView!
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var timerLabel: UILabel!
    @IBOutlet private weak var timerUnderlineView: UIView!
    @IBOutlet private weak var ringsContainerView: UIView!
    @IBOutlet private weak var outerRingView: UIView!
    @IBOutlet private weak var innerRingView: UIView!
    @IBOutlet private weak var bubbleView: UIView!
    @IBOutlet private weak var guidanceLabel: UILabel!
    @IBOutlet private weak var dot1: UIView!
    @IBOutlet private weak var dot2: UIView!
    @IBOutlet private weak var dot3: UIView!
    @IBOutlet private weak var shiftLabel: UILabel!
    @IBOutlet private weak var startStopButton: UIButton!
    @IBOutlet private weak var calibratingPillView: UIView!

    private enum BreathPhase: String {
        case inhale = "Inhale"
        case hold = "Hold"
        case exhale = "Exhale"
        case pause = "Pause"

        var guidanceText: String {
            switch self {
            case .inhale: return "Inhale through nose"
            case .hold: return "Hold gently"
            case .exhale: return "Exhale with whoosh"
            case .pause: return "Settle"
            }
        }
    }

    private struct BreathMetrics {
        let phase: BreathPhase
        let bubbleScale: CGFloat
        let glowAlpha: CGFloat
        let ringScale: CGFloat
        let remainingInPhase: Int
    }

    private struct BreathingCycle {
        let inhale: Double = 4
        let hold: Double = 7
        let exhale: Double = 8
        let pause: Double = 0
        let repetitions: Int = 4

        var total: Double { inhale + hold + exhale + pause }
        var totalSessionDuration: Double { total * Double(repetitions) }

        func metrics(at elapsed: TimeInterval) -> BreathMetrics {
            let t = elapsed.truncatingRemainder(dividingBy: total)

            if t < inhale {
                let p = eased(t / inhale)
                return BreathMetrics(
                    phase: .inhale,
                    bubbleScale: 0.82 + 0.26 * p,
                    glowAlpha: 0.40 + 0.45 * p,
                    ringScale: 0.95 + 0.10 * p,
                    remainingInPhase: max(1, Int(ceil(inhale - t)))
                )
            }

            if t < inhale + hold {
                return BreathMetrics(
                    phase: .hold,
                    bubbleScale: 1.08,
                    glowAlpha: 0.85,
                    ringScale: 1.05,
                    remainingInPhase: max(1, Int(ceil((inhale + hold) - t)))
                )
            }

            if t < inhale + hold + exhale {
                let p = eased((t - inhale - hold) / exhale)
                return BreathMetrics(
                    phase: .exhale,
                    bubbleScale: 1.08 - 0.26 * p,
                    glowAlpha: 0.85 - 0.45 * p,
                    ringScale: 1.05 - 0.10 * p,
                    remainingInPhase: max(1, Int(ceil((inhale + hold + exhale) - t)))
                )
            }

            return BreathMetrics(
                phase: .pause,
                bubbleScale: 0.82,
                glowAlpha: 0.40,
                ringScale: 0.95,
                remainingInPhase: max(1, Int(ceil(total - t)))
            )
        }

        private func eased(_ value: Double) -> Double {
            let v = max(0, min(1, value))
            return 0.5 - 0.5 * cos(.pi * v)
        }
    }

    private let cycle = BreathingCycle()
    private var displayLink: CADisplayLink?
    private var isSessionActive = false
    private var sessionStartDate: Date?
    private var accumulatedElapsed: TimeInterval = 0
    private var currentElapsed: TimeInterval = 0

    private var backgroundGradientLayer = CAGradientLayer()
    private var bubbleGradientLayer = CAGradientLayer()
    private var buttonGradientLayer = CAGradientLayer()
    
    private var isDarkMode: Bool {
        traitCollection.userInterfaceStyle == .dark
    }
    
    var onSave: (() -> Void)?
    var activityItem: TodayActivityItem?
    var patient: Patient?

    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigationButtons()
        configureUI()
        apply(metrics: cycle.metrics(at: 0))
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        layoutLayers()
    }

    @IBAction private func startStopTapped(_ sender: UIButton) {
        isSessionActive.toggle()

        if isSessionActive {
            if accumulatedElapsed >= cycle.totalSessionDuration {
                accumulatedElapsed = 0
            }
            sessionStartDate = Date()
            startDisplayLinkIfNeeded()
        } else {
            if let sessionStartDate {
                accumulatedElapsed += Date().timeIntervalSince(sessionStartDate)
            }
            sessionStartDate = nil
            stopDisplayLink()
        }

        updateButtonTitle()
        apply(metrics: cycle.metrics(at: min(accumulatedElapsed, cycle.totalSessionDuration)))
    }

    private func configureUI() {
        view.backgroundColor = isDarkMode
            ? UIColor(red: 0.19, green: 0.20, blue: 0.22, alpha: 1.0)
            : UIColor(red: 0.92, green: 0.97, blue: 0.98, alpha: 1.0)
        [outerRingView, innerRingView, bubbleView, dot1, dot2, dot3, timerUnderlineView].forEach {
            $0?.layer.masksToBounds = true
        }

        outerRingView.layer.cornerRadius = outerRingView.bounds.width / 2
        innerRingView.layer.cornerRadius = innerRingView.bounds.width / 2
        bubbleView.layer.cornerRadius = bubbleView.bounds.width / 2
        timerUnderlineView.layer.cornerRadius = 2
        calibratingPillView.isHidden = true

        [dot1, dot2, dot3].forEach { $0?.layer.cornerRadius = 4 }

        outerRingView.layer.borderColor = isDarkMode
            ? UIColor(red: 0.21, green: 0.21, blue: 0.24, alpha: 1.0).cgColor
            : UIColor(red: 0.45, green: 0.76, blue: 0.80, alpha: 0.35).cgColor
        outerRingView.layer.borderWidth = 1.5
        innerRingView.layer.borderColor = isDarkMode
            ? UIColor(red: 0.24, green: 0.24, blue: 0.28, alpha: 1.0).cgColor
            : UIColor(red: 0.45, green: 0.76, blue: 0.80, alpha: 0.25).cgColor
        innerRingView.layer.borderWidth = 1.0

        bubbleView.layer.borderColor = isDarkMode
            ? UIColor.white.withAlphaComponent(0.08).cgColor
            : UIColor.white.withAlphaComponent(0.55).cgColor
        bubbleView.layer.borderWidth = 1.2
        bubbleView.layer.shadowColor = isDarkMode
            ? UIColor.black.cgColor
            : UIColor(red: 0.52, green: 0.80, blue: 0.84, alpha: 1.0).cgColor
        bubbleView.layer.shadowOpacity = 0.22
        bubbleView.layer.shadowRadius = 18
        bubbleView.layer.shadowOffset = CGSize(width: 0, height: 14)

        titleLabel.text = "4-7-8 Breathing"
        titleLabel.font = .systemFont(ofSize: 24, weight: .semibold)
        titleLabel.textColor = isDarkMode
            ? UIColor.white.withAlphaComponent(0.95)
            : UIColor(red: 0.11, green: 0.26, blue: 0.30, alpha: 1.0)
        titleLabel.adjustsFontSizeToFitWidth = true
        titleLabel.minimumScaleFactor = 0.72
        titleLabel.lineBreakMode = .byTruncatingTail

        timerLabel.font = .monospacedDigitSystemFont(ofSize: 52, weight: .bold)
        timerLabel.textColor = isDarkMode
            ? UIColor.white.withAlphaComponent(0.90)
            : UIColor(red: 0.12, green: 0.29, blue: 0.34, alpha: 1.0)
        timerUnderlineView.backgroundColor = isDarkMode
            ? UIColor(red: 0.35, green: 0.52, blue: 0.57, alpha: 1.0)
            : UIColor(red: 0.47, green: 0.81, blue: 0.85, alpha: 1.0)
        shiftLabel.numberOfLines = 1
        shiftLabel.textColor = isDarkMode
            ? UIColor.white.withAlphaComponent(0.65)
            : UIColor(red: 0.24, green: 0.44, blue: 0.49, alpha: 1.0)
        guidanceLabel.numberOfLines = 1
        guidanceLabel.adjustsFontSizeToFitWidth = true
        guidanceLabel.minimumScaleFactor = 0.75
        guidanceLabel.font = .systemFont(ofSize: 18, weight: .semibold)
        guidanceLabel.textColor = isDarkMode
            ? UIColor.white.withAlphaComponent(0.82)
            : UIColor(red: 0.15, green: 0.33, blue: 0.38, alpha: 1.0)

        buttonGradientLayer.colors = [
            (isDarkMode
             ? UIColor(red: 0.25, green: 0.29, blue: 0.33, alpha: 1.0)
             : UIColor(red: 0.84, green: 0.94, blue: 0.98, alpha: 1.0)).cgColor,
            (isDarkMode
             ? UIColor(red: 0.22, green: 0.25, blue: 0.29, alpha: 1.0)
             : UIColor(red: 0.74, green: 0.89, blue: 0.96, alpha: 1.0)).cgColor
        ]
        buttonGradientLayer.startPoint = CGPoint(x: 0, y: 0.5)
        buttonGradientLayer.endPoint = CGPoint(x: 1, y: 0.5)
        startStopButton.layer.insertSublayer(buttonGradientLayer, at: 0)
        startStopButton.layer.cornerRadius = startStopButton.bounds.height / 2
        startStopButton.layer.masksToBounds = true

        backgroundGradientLayer.colors = [
            (isDarkMode
             ? UIColor(red: 0.27, green: 0.40, blue: 0.43, alpha: 1.0)
             : UIColor(red: 0.84, green: 0.92, blue: 0.94, alpha: 1.0)).cgColor,
            (isDarkMode
             ? UIColor(red: 0.24, green: 0.35, blue: 0.38, alpha: 1.0)
             : UIColor(red: 0.73, green: 0.88, blue: 0.90, alpha: 1.0)).cgColor,
            (isDarkMode
             ? UIColor(red: 0.18, green: 0.19, blue: 0.22, alpha: 1.0)
             : UIColor(red: 0.53, green: 0.80, blue: 0.82, alpha: 1.0)).cgColor
        ]
        backgroundGradientLayer.startPoint = CGPoint(x: 0.5, y: 0)
        backgroundGradientLayer.endPoint = CGPoint(x: 0.5, y: 1)
        backgroundGradientView.layer.insertSublayer(backgroundGradientLayer, at: 0)

        bubbleGradientLayer.colors = [
            (isDarkMode
             ? UIColor(red: 0.28, green: 0.37, blue: 0.40, alpha: 1.0)
             : UIColor(red: 0.82, green: 0.95, blue: 0.97, alpha: 0.98)).cgColor,
            (isDarkMode
             ? UIColor(red: 0.24, green: 0.33, blue: 0.36, alpha: 1.0)
             : UIColor(red: 0.63, green: 0.84, blue: 0.88, alpha: 0.98)).cgColor,
            (isDarkMode
             ? UIColor(red: 0.20, green: 0.28, blue: 0.31, alpha: 1.0)
             : UIColor(red: 0.44, green: 0.67, blue: 0.73, alpha: 1.0)).cgColor
        ]
        bubbleGradientLayer.type = .radial
        bubbleGradientLayer.startPoint = CGPoint(x: 0.35, y: 0.28)
        bubbleGradientLayer.endPoint = CGPoint(x: 1.0, y: 1.0)
        bubbleView.layer.insertSublayer(bubbleGradientLayer, at: 0)

        updateButtonTitle()
        timerLabel.text = formatTime(Int(cycle.totalSessionDuration))
    }

    private func layoutLayers() {
        backgroundGradientLayer.frame = backgroundGradientView.bounds
        bubbleGradientLayer.frame = bubbleView.bounds
        bubbleView.layer.cornerRadius = bubbleView.bounds.width / 2
        outerRingView.layer.cornerRadius = outerRingView.bounds.width / 2
        innerRingView.layer.cornerRadius = innerRingView.bounds.width / 2
        buttonGradientLayer.frame = startStopButton.bounds
        buttonGradientLayer.cornerRadius = startStopButton.bounds.height / 2
        startStopButton.layer.cornerRadius = startStopButton.bounds.height / 2
    }

    private func startDisplayLinkIfNeeded() {
        guard displayLink == nil else { return }
        let link = CADisplayLink(target: self, selector: #selector(onTick))
        link.add(to: .main, forMode: .common)
        displayLink = link
    }

    private func stopDisplayLink() {
        displayLink?.invalidate()
        displayLink = nil
    }

    @objc private func onTick() {
        let elapsed: TimeInterval
        if let sessionStartDate {
            elapsed = accumulatedElapsed + Date().timeIntervalSince(sessionStartDate)
        } else {
            elapsed = accumulatedElapsed
        }
        currentElapsed = elapsed

        if elapsed >= cycle.totalSessionDuration {
            accumulatedElapsed = cycle.totalSessionDuration
            currentElapsed = cycle.totalSessionDuration
            isSessionActive = false
            sessionStartDate = nil
            stopDisplayLink()
            updateButtonTitle()
        }

        let clampedElapsed = min(elapsed, cycle.totalSessionDuration)
        let metrics = cycle.metrics(at: clampedElapsed)
        apply(metrics: metrics)
    }

    private func apply(metrics: BreathMetrics) {
        UIView.performWithoutAnimation {
            bubbleView.transform = CGAffineTransform(scaleX: metrics.bubbleScale, y: metrics.bubbleScale)
            outerRingView.transform = CGAffineTransform(scaleX: metrics.ringScale, y: metrics.ringScale)
            innerRingView.transform = .identity
            bubbleView.layer.shadowOpacity = Float(metrics.glowAlpha)
        }

        guidanceLabel.text = metrics.phase.guidanceText
        let remainingSession = max(0, Int(ceil(cycle.totalSessionDuration - accumulatedElapsed - (sessionStartDate.map { Date().timeIntervalSince($0) } ?? 0))))
        timerLabel.text = formatTime(remainingSession)
        switch metrics.phase {
        case .inhale:
            shiftLabel.text = "Inhale • \(metrics.remainingInPhase)s"
            setDots(activeIndex: 0)
        case .hold:
            shiftLabel.text = "Hold • \(metrics.remainingInPhase)s"
            setDots(activeIndex: 1)
        case .exhale:
            shiftLabel.text = "Exhale • \(metrics.remainingInPhase)s"
            setDots(activeIndex: 2)
        case .pause:
            shiftLabel.text = "Pause • \(metrics.remainingInPhase)s"
            setDots(activeIndex: 0)
        }
    }

    private func setDots(activeIndex: Int) {
        let active = UIColor(red: 0.07, green: 0.74, blue: 0.87, alpha: 1.0)
        let inactive = UIColor(red: 0.58, green: 0.74, blue: 0.78, alpha: 0.55)
        [dot1, dot2, dot3].enumerated().forEach { idx, view in
            view?.backgroundColor = idx == activeIndex ? active : inactive
        }
    }

    private func updateButtonTitle() {
        let title = isSessionActive ? "End Session" : "Start Session"
        let full = NSAttributedString(string: title, attributes: [
            .foregroundColor: isDarkMode
                ? UIColor.white.withAlphaComponent(0.90)
                : UIColor(red: 0.09, green: 0.27, blue: 0.33, alpha: 1.0),
            .font: UIFont.systemFont(ofSize: 20, weight: .medium)
        ])
        startStopButton.setAttributedTitle(full, for: .normal)
    }
    
    private func setupNavigationButtons() {
        title = "Activity Log"
        let close = UIBarButtonItem(
            barButtonSystemItem: .close,
            target: self,
            action: #selector(closeTapped)
        )
        let save = UIBarButtonItem(
            image: UIImage(systemName: "checkmark"),
            style: .done,
            target: self,
            action: #selector(saveTapped)
        )
        navigationItem.leftBarButtonItem = close
        navigationItem.rightBarButtonItem = save
        navigationController?.navigationBar.tintColor = isDarkMode
            ? UIColor.white.withAlphaComponent(0.92)
            : UIColor(red: 0.20, green: 0.52, blue: 0.58, alpha: 1.0)
    }
    
    @objc private func closeTapped() {
        stopDisplayLink()
        dismiss(animated: true)
    }
    
    @objc private func saveTapped() {
        if let sessionStartDate {
            accumulatedElapsed += Date().timeIntervalSince(sessionStartDate)
            self.sessionStartDate = nil
        }
        currentElapsed = accumulatedElapsed
        isSessionActive = false
        stopDisplayLink()
        updateButtonTitle()
        
        let duration = max(0, Int(currentElapsed.rounded()))
        guard duration > 0 else {
            let alert = UIAlertController(
                title: "No Activity",
                message: "Start the breathing session before logging.",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
            return
        }
        
        guard let item = activityItem, let patient = patient else {
            dismiss(animated: true)
            return
        }
        
        Task {
            do {
                let formatter = DateFormatter()
                formatter.dateFormat = "HH:mm:ss"
                let timeString = formatter.string(from: Date())
                
                let log = ActivityLog(
                    logID: UUID(),
                    assignedID: item.assignment.assignedID,
                    activityID: item.activity.activityID,
                    patientID: patient.patientID,
                    date: Date(),
                    time: timeString,
                    duration: duration,
                    uploadPath: nil,
                    summary: nil
                )
                
                _ = try await AccessSupabase.shared.saveActivityLog(log)
                await MainActor.run {
                    NotificationCenter.default.post(
                        name: NSNotification.Name("ActivityLogSaved"),
                        object: nil
                    )
                    self.onSave?()
                    self.dismiss(animated: true)
                }
            } catch {
                await MainActor.run {
                    let alert = UIAlertController(
                        title: "Save Failed",
                        message: "\(error)",
                        preferredStyle: .alert
                    )
                    alert.addAction(UIAlertAction(title: "OK", style: .default))
                    self.present(alert, animated: true)
                }
            }
        }
    }

    private func formatTime(_ seconds: Int) -> String {
        let m = max(0, seconds) / 60
        let s = max(0, seconds) % 60
        return String(format: "%02d:%02d", m, s)
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        guard previousTraitCollection?.userInterfaceStyle != traitCollection.userInterfaceStyle else { return }
        backgroundGradientLayer.removeFromSuperlayer()
        bubbleGradientLayer.removeFromSuperlayer()
        buttonGradientLayer.removeFromSuperlayer()
        backgroundGradientLayer = CAGradientLayer()
        bubbleGradientLayer = CAGradientLayer()
        buttonGradientLayer = CAGradientLayer()
        configureUI()
        layoutLayers()
        apply(metrics: cycle.metrics(at: min(accumulatedElapsed, cycle.totalSessionDuration)))
    }
}
