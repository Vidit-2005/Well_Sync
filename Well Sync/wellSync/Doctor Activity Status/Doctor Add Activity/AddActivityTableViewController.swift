//
//  AddActivityTableViewController.swift
//  wellSync
//
//  Created by Vidit Saran Agarwal on 07/02/26.
//

import UIKit

class AddActivityTableViewController: BaseInsetGroupedTableViewController {

    @IBOutlet weak var activityListButton: UIButton!
    @IBOutlet weak var frequencyButton: UIButton!
    @IBOutlet weak var doctorNote: UITextView!
    @IBOutlet weak var activityCell: UITableViewCell!
    @IBOutlet weak var nameCell: UITableViewCell!
    @IBOutlet weak var startDatePicker: UIDatePicker!
    @IBOutlet weak var endDatePicker: UIDatePicker!
    @IBOutlet weak var customNameTextField: UITextField!
    
    @IBOutlet weak var imageSwitch: UISwitch!
    @IBOutlet weak var recordingSwitch: UISwitch!
    @IBOutlet weak var timerSwitch: UISwitch!
    
    var patient: Patient?
    var isCustomSelected = false
    var onSave: (() -> Void)?

    /// Activities loaded from the database for this doctor
    private var doctorActivities: [Activity] = []

    override func viewDidLoad() {
        super.viewDidLoad()

        doctorNote.layer.cornerRadius = 20
        doctorNote.clipsToBounds = true
        imageSwitch.isOn = false
        recordingSwitch.isOn = false
        timerSwitch.isOn = true
        startDatePicker.date = Date()
        endDatePicker.date   = Date()

        // Load activities from DB, then build menu
        loadActivitiesAndBuildMenu()
        setupFrequencyMenu()
    }
    @IBAction func imageSwitchChanged(_ sender: UISwitch) {
        if sender.isOn {
            timerSwitch.isOn = false
        }
    }
        
    @IBAction func recordingSwitchChanged(_ sender: UISwitch) {
        if sender.isOn {
            timerSwitch.isOn = false
        }
    }
        
    @IBAction func timerSwitchChanged(_ sender: UISwitch) {
        if sender.isOn {
            imageSwitch.isOn = false
            recordingSwitch.isOn = false
        }
    }

    // MARK: - Load activities from DB for this doctor

    private func loadActivitiesAndBuildMenu() {
        guard let doctorID = patient?.docID else {
            // Fallback to hardcoded list if no doctor
            setupActivityMenuWithNames(defaultActivityNames)
            return
        }

        Task {
            do {
                doctorActivities = try await AccessSupabase.shared.fetchActivities(for: doctorID)
                let names = doctorActivities.map { $0.name }

                // Merge defaults that aren't already in DB
                var allNames = names
                for defaultName in defaultActivityNames {
                    if !allNames.contains(where: { $0.caseInsensitiveCompare(defaultName) == .orderedSame }) {
                        allNames.append(defaultName)
                    }
                }

                DispatchQueue.main.async {
                    self.setupActivityMenuWithNames(allNames)
                }
            } catch {
                print("Failed to load doctor activities: \(error)")
                DispatchQueue.main.async {
                    self.setupActivityMenuWithNames(self.defaultActivityNames)
                }
            }
        }
    }

    /// Default activity names (fallback / seed list)
    private var defaultActivityNames: [String] {
        [
            "Morning Walk",
            "Breathing Exercise",
            "Journaling",
            "Art",
            "Yoga",
            "Meditation",
            "Exercise",
            "Reading"
        ]
    }

    private func setupActivityMenuWithNames(_ names: [String]) {
        let activityActions = names.map { option in
            UIAction(title: option) { [weak self] _ in
                guard let self = self else { return }
                self.activityListButton.setTitle(option, for: .normal)
                self.toggleCustomRows(show: false)
            }
        }

        let custom = UIAction(title: "Custom") { [weak self] _ in
            guard let self = self else { return }
            self.activityListButton.setTitle("Custom", for: .normal)
            self.toggleCustomRows(show: true)
        }

        let customGroup = UIMenu(options: .displayInline, children: [custom])
        let mainGroup = UIMenu(options: .displayInline, children: activityActions)

        activityListButton.menu = UIMenu(children: [mainGroup, customGroup])
        activityListButton.showsMenuAsPrimaryAction = true
    }

    private func setupFrequencyMenu() {
        let frequencyList = ["Once a day", "Twice a day", "Three times a day", "Alternate days"]

        let frequencyActions = frequencyList.map { option in
            UIAction(title: option) { [weak self] _ in
                self?.frequencyButton.setTitle(option, for: .normal)
            }
        }

        frequencyButton.menu = UIMenu(children: frequencyActions)
        frequencyButton.showsMenuAsPrimaryAction = true
    }

    func toggleCustomRows(show: Bool) {

        guard show != isCustomSelected else { return }

        isCustomSelected = show

        let indexPaths = [
            IndexPath(row: 1, section: 0)
        ]

        tableView.beginUpdates()
        if isCustomSelected {
            tableView.insertRows(at: indexPaths, with: .fade)
        } else {
            tableView.deleteRows(at: indexPaths, with: .fade)
        }

        tableView.endUpdates()
    }
    override func tableView(_ tableView: UITableView,
                                numberOfRowsInSection section: Int) -> Int {

        if section == 0 {
            return isCustomSelected ? 5 : 4
        }

        return super.tableView(tableView, numberOfRowsInSection: section)
    }

    override func tableView(_ tableView: UITableView,
                                cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        if indexPath.section == 0 {
            
            if isCustomSelected {
                switch indexPath.row {
                case 0:
                    return activityCell
                case 1:
                    return nameCell
                default:
                    break
                }
            } else {
                switch indexPath.row {
                case 0:
                    return activityCell
                default:
                    let adjustedIndexPath = IndexPath(row: indexPath.row + 1, section: indexPath.section)
                    return super.tableView(tableView, cellForRowAt: adjustedIndexPath)
                }
            }
        }

        return super.tableView(tableView, cellForRowAt: indexPath)
    }


    @IBAction func saveTapped(_ sender: UIBarButtonItem) {
        guard let patientID = patient?.patientID else {
            showAlert("Patient info missing.")
            return
        }

        let selectedName = activityListButton.title(for: .normal) ?? ""
        if selectedName.isEmpty || selectedName == "Select" {
            showAlert("Please select an activity.")
            return
        }

        Task {
            do {
                var savedActivity: Activity
                let doctorID = patient!.docID
                
                if isCustomSelected {
                    let customName = customNameTextField.text?.trimmingCharacters(in: .whitespaces) ?? ""
                    
                    guard !customName.isEmpty else {
                        showAlert("Please enter a custom activity name.")
                        return
                    }
                    
                    // Look up by name + doctorID so it's scoped to this doctor
                    if let existing = try await AccessSupabase.shared.fetchActivity(byName: customName, doctorID: doctorID) {
                        savedActivity = existing
                    } else {
                        let newActivity = Activity(
                            activityID: UUID(),
                            doctorID: doctorID,
                            name: customName,
                            iconName: "sparkles"
                        )
                        savedActivity = try await AccessSupabase.shared.saveActivity(newActivity)
                    }
                }
                else {
                    guard !selectedName.isEmpty, selectedName != "Select" else {
                        showAlert("Please select an activity.")
                        return
                    }

                    // First try doctor-scoped lookup
                    if let existing = try await AccessSupabase.shared.fetchActivity(byName: selectedName, doctorID: doctorID) {
                        savedActivity = existing
                    }
                    // Fallback: global lookup (for seed/predefined activities)
                    else if let existing = try await AccessSupabase.shared.fetchActivity(byName: selectedName) {
                        savedActivity = existing
                    }
                    else {
                        // Activity not in DB yet — create it for this doctor
                        let iconMap: [String: String] = [
                            "Morning Walk": "figure.walk",
                            "Breathing Exercise": "wind",
                            "Journaling": "book",
                            "Art": "paintpalette",
                            "Yoga": "figure.yoga",
                            "Meditation": "brain.head.profile",
                            "Exercise": "dumbbell",
                            "Reading": "book.closed"
                        ]
                        let newActivity = Activity(
                            activityID: UUID(),
                            doctorID: doctorID,
                            name: selectedName,
                            iconName: iconMap[selectedName] ?? "sparkles"
                        )
                        savedActivity = try await AccessSupabase.shared.saveActivity(newActivity)
                    }
                }
                
                guard imageSwitch.isOn || recordingSwitch.isOn || timerSwitch.isOn else {
                    showAlert("Please enable at least one tracking method: Image, Recording, or Timer.")
                    return
                }
                
                if timerSwitch.isOn && (imageSwitch.isOn || recordingSwitch.isOn) {
                    showAlert("Timer cannot be combined with Image or Recording.")
                    return
                }
                guard let frequency = resolveFrequency() else {
                    showAlert("Please select a frequency.")
                    return
                }

                let start = startDatePicker.date
                let end = endDatePicker.date

                guard end >= start else {
                    showAlert("End date must be after start date.")
                    return
                }
                
                // ── KEY FIX: check for existing active assignment ──
                if let existingAssignment = try await AccessSupabase.shared.fetchActiveAssignment(
                    patientID: patientID,
                    activityID: savedActivity.activityID
                ) {
                    // UPDATE the existing row — keep same assigned_id and activity_id
                    var updated = AssignedActivity(
                        assignedID: existingAssignment.assignedID,
                        activityID: savedActivity.activityID,
                        patientID: patientID,
                        doctorID: doctorID,
                        frequency: frequency,
                        startDate: start,
                        endDate: end,
                        doctorNote: doctorNote.text ?? "",
                        status: .active,
                        hasImage: imageSwitch.isOn,
                        hasRecording: recordingSwitch.isOn,
                        hasTimer: timerSwitch.isOn
                    )
                    
                    try await AccessSupabase.shared.updateAssignedActivity(updated)
                    print("✅ Updated existing assignment: \(existingAssignment.assignedID)")
                } else {
                    // No active assignment exists — INSERT new
                    let newAssignment = AssignedActivity(
                        assignedID: UUID(),
                        activityID: savedActivity.activityID,
                        patientID: patientID,
                        doctorID: doctorID,
                        frequency: frequency,
                        startDate: start,
                        endDate: end,
                        doctorNote: doctorNote.text ?? "",
                        status: .active,
                        hasImage: imageSwitch.isOn,
                        hasRecording: recordingSwitch.isOn,
                        hasTimer: timerSwitch.isOn
                    )
                    
                    try await AccessSupabase.shared.assignActivity(newAssignment)
                    print("✅ Created new assignment")
                }

                DispatchQueue.main.async {
                    self.onSave?()
                    self.dismiss(animated: true)
                }

            } catch {
                print("Save error:", error)
                showAlert("Failed to save activity: \(error.localizedDescription)")
            }
        }
    }

 
    @IBAction func cancelTapped(_ sender: UIBarButtonItem) {
        dismiss(animated: true)
    }

    private func resolveFrequency() -> Int? {
        switch frequencyButton.title(for: .normal) {
        case "Once a day":          return 1
        case "Twice a day":         return 2
        case "Three times a day":   return 3
        case "Alternate days":      return 1
        default:                    return nil
        }
    }

    private func showAlert(_ message: String) {
        let alert = UIAlertController(title: "Missing Info",
                                    message: message,
                                    preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
