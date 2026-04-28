//
//  ScheduleViewController.swift
//  wellSync
//

import UIKit
import FSCalendar

class ScheduleViewController: UIViewController, FSCalendarDelegate, FSCalendarDataSource, FSCalendarDelegateAppearance {
    
    var patient: Patient?
    var allAppointments: [Appointment] = []
    
    let calendar = FSCalendar()
    let timePicker = UIDatePicker()
    let scheduleButton = UIButton()
    
    var onScheduleConfirmed: ((Date) -> Void)?
    var onScheduleCancelled: (() -> Void)?
    var onScheduleChange: ((Date) -> Void)?
    
    var selectedDate: Date?
    var scheduleDate: Date?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        
        setupUI()
        calendarLogic()
        loadAllAppointments()
    }
    
    // MARK: - Load Data
    
    func loadAllAppointments(){
        guard let patient = patient else { return }
        
        Task{
            do{
                let fetched = try await AccessSupabase.shared
                    .fetchAppointments(patientID: patient.patientID)
                
                await MainActor.run {
                    self.allAppointments = fetched
                    self.calendar.reloadData()
                    self.updateButtonText()
                }
                
            } catch {
                print("Error loading appointments: \(error)")
            }
        }
    }
    
    func updateButtonText() {
        var config = UIButton.Configuration.tinted()
        config.cornerStyle = .capsule

        guard let selected = selectedDate else {
            scheduleButton.setTitle("Select a Date", for: .normal)
            scheduleButton.isEnabled = false
            config.baseBackgroundColor = .systemGray4
            scheduleButton.configuration = config
            return
        }

        scheduleButton.isEnabled = true
        let cal = Calendar.current

        let existingOnSelectedDate = allAppointments.first {
            $0.status == .scheduled &&
            cal.isDate($0.scheduledAt, inSameDayAs: selected)
        }

        let hasTodayAppointment = allAppointments.contains {
            $0.status == .scheduled &&
            cal.isDateInToday($0.scheduledAt)
        }

        if let _ = existingOnSelectedDate {
            if cal.isDateInToday(selected) {
                scheduleButton.setTitle("Update Time", for: .normal)
                config.baseBackgroundColor = .systemBlue
            } else {
                scheduleButton.setTitle("Cancel Session", for: .normal)
                config.baseBackgroundColor = .systemRed
            }
        } else {
            if cal.isDateInToday(selected) && hasTodayAppointment {
                scheduleButton.setTitle("Update Time", for: .normal)
                config.baseBackgroundColor = .systemBlue
            } else {
                scheduleButton.setTitle("Schedule", for: .normal)
                config.baseBackgroundColor = .systemGreen
            }
        }

        scheduleButton.configuration = config
    }
    
    func setupUI(){
        calendar.translatesAutoresizingMaskIntoConstraints = false
        timePicker.translatesAutoresizingMaskIntoConstraints = false
        scheduleButton.translatesAutoresizingMaskIntoConstraints = false
        
        timePicker.datePickerMode = .time
        timePicker.preferredDatePickerStyle = .compact
        
        updateButtonText()
        
        scheduleButton.addTarget(self, action: #selector(scheduleButtonTapped), for: .touchUpInside)
        
        view.addSubview(calendar)
        view.addSubview(timePicker)
        view.addSubview(scheduleButton)
        
        NSLayoutConstraint.activate([
            
            calendar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            calendar.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 12),
            calendar.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -12),
            calendar.heightAnchor.constraint(equalToConstant: 320),
            
            timePicker.topAnchor.constraint(equalTo: calendar.bottomAnchor, constant: 2),
            timePicker.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            scheduleButton.topAnchor.constraint(equalTo: timePicker.bottomAnchor, constant: 4),
            scheduleButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            scheduleButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40),
            scheduleButton.heightAnchor.constraint(equalToConstant: 40),
            
            scheduleButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -8)
        ])
    }
    
    func calendarLogic(){
        calendar.delegate = self
        calendar.dataSource = self
        
        calendar.scope = .month
        calendar.scrollDirection = .horizontal
        
        calendar.placeholderType = .none
        
        calendar.appearance.headerDateFormat = "MMMM yyyy"
        calendar.appearance.headerTitleFont = .systemFont(ofSize: 16, weight: .semibold)
        calendar.appearance.headerTitleColor = .systemIndigo
        calendar.appearance.headerMinimumDissolvedAlpha = 0
        
        calendar.appearance.weekdayFont = .systemFont(ofSize: 12, weight: .medium)
        calendar.appearance.titleFont = .systemFont(ofSize: 14)
        calendar.appearance.weekdayTextColor = .systemIndigo
        
        calendar.appearance.titleFont = .systemFont(ofSize: 15, weight: .regular)
           calendar.appearance.titleDefaultColor = .label
        
        calendar.appearance.todayColor = .clear
        calendar.appearance.titleTodayColor = .label
        
        calendar.appearance.selectionColor = .systemBlue
        
        calendar.appearance.eventDefaultColor = .clear
        calendar.appearance.borderRadius = 1.0 // 🔥 full circle
        calendar.appearance.headerMinimumDissolvedAlpha = 0
    }
    
    @objc func scheduleButtonTapped(){
        let currentTitle = scheduleButton.title(for: .normal)
        
        if currentTitle == "Cancel Session" {
            handleCancellation()
        } else {
            handleScheduling()
        }
    }
    
    private func handleCancellation() {
        guard selectedDate != nil else { return }
        onScheduleCancelled?()
        dismiss(animated: true)
    }

    private func handleScheduling() {
        guard let day = selectedDate else { return }

        let cal = Calendar.current

        let timeComponents = cal.dateComponents([.hour, .minute], from: timePicker.date)

        var finalComponents = cal.dateComponents([.year, .month, .day], from: day)
        finalComponents.hour = timeComponents.hour
        finalComponents.minute = timeComponents.minute

        guard let finalDate = cal.date(from: finalComponents) else { return }

        let isToday = cal.isDateInToday(day)

        if isToday {
            onScheduleChange?(finalDate)

        } else {
            let futureAppointments = allAppointments.filter {
                $0.status == .scheduled &&
                $0.scheduledAt > finalDate &&
                !cal.isDateInToday($0.scheduledAt)
            }

            for appt in futureAppointments {
                if let id = appt.appointmentId {
                    Task {
                        try? await AccessSupabase.shared.deleteAppointment(id: id)
                        print("🗑 Deleted future appointment")
                    }
                }
            }
            onScheduleConfirmed?(finalDate)
        }

        dismiss(animated: true)
    }
}

extension ScheduleViewController {
    func calendar(_ calendar: FSCalendar, didSelect date: Date, at monthPosition: FSCalendarMonthPosition) {
        
        let today = Calendar.current.startOfDay(for: Date())
        
        if date < today {
            calendar.deselect(date)
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            selectedDate = nil
        } else {
            selectedDate = date
        }
        
        updateButtonText()
    }
    func calendar(_ calendar: FSCalendar, numberOfEventsFor date: Date) -> Int {
        let cal = Calendar.current
        
        let hasAppointment = allAppointments.contains {
            cal.isDate($0.scheduledAt, inSameDayAs: date)
        }
        
        let isNextSession = patient?.nextSessionDate.map {
            cal.isDate($0, inSameDayAs: date)
        } ?? false
        
        return (hasAppointment || isNextSession) ? 1 : 0
    }
    func calendar(_ calendar: FSCalendar, appearance: FSCalendarAppearance, fillDefaultColorFor date: Date) -> UIColor? {
        
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        
        let appts = allAppointments.filter {
            cal.isDate($0.scheduledAt, inSameDayAs: date)
        }
        
        let isNextSession = patient?.nextSessionDate != nil &&
            cal.isDate(patient!.nextSessionDate!, inSameDayAs: date)
        
        if appts.contains(where: { $0.status == .missed }) {
            return UIColor.systemRed.withAlphaComponent(0.25)
        }
        
        if appts.contains(where: { $0.status == .completed }) {
            return UIColor.systemGreen.withAlphaComponent(0.25)
        }
        
        if appts.contains(where: { $0.status == .scheduled }) {
            return UIColor.systemBlue.withAlphaComponent(0.25)
        }
        
        if let nextSession = patient?.nextSessionDate,
           isNextSession,
           nextSession > today {
            return UIColor.systemBlue.withAlphaComponent(0.25)
        }
        
        if isNextSession {
            return UIColor.systemGray.withAlphaComponent(0.25)
        }
        
        return nil
    }
}
