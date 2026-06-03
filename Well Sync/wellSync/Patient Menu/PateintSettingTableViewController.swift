//
//  PateintSettingTableViewController.swift
//  wellSync
//
//  Created by Vidit Agarwal on 11/02/26.
//

import UIKit

class PateintSettingTableViewController: BaseInsetGroupedTableViewController {

    private var isRemindersEnabled = true
    private var isMoodLogEnabled = true
    private var isActivityEnabled = true

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.largeTitleDisplayMode = .never
        
        isRemindersEnabled = UserDefaults.standard.object(forKey: "wellsync_patient_reminders_enabled") as? Bool ?? true
        isMoodLogEnabled = UserDefaults.standard.object(forKey: "wellsync_patient_mood_log_enabled") as? Bool ?? true
        isActivityEnabled = UserDefaults.standard.object(forKey: "wellsync_patient_activity_enabled") as? Bool ?? true
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }

    // MARK: - Table View DataSource / Delegate

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = super.tableView(tableView, cellForRowAt: indexPath)
        
        if indexPath.section == 1 {
            if indexPath.row == 0 {
                // Enable row
                if let reminderSwitch = cell.contentView.subviews.compactMap({ $0 as? UISwitch }).first {
                    reminderSwitch.isOn = isRemindersEnabled
                    reminderSwitch.removeTarget(nil, action: nil, for: .allEvents)
                    reminderSwitch.addTarget(self, action: #selector(reminderSwitchChanged(_:)), for: .valueChanged)
                }
            } else if indexPath.row == 1 {
                // Mood Log
                cell.accessoryType = (isRemindersEnabled && isMoodLogEnabled) ? .checkmark : .none
                if let label = cell.contentView.subviews.compactMap({ $0 as? UILabel }).first {
                    label.textColor = isRemindersEnabled ? .label : .secondaryLabel
                }
            } else if indexPath.row == 2 {
                // Activity
                cell.accessoryType = (isRemindersEnabled && isActivityEnabled) ? .checkmark : .none
                if let label = cell.contentView.subviews.compactMap({ $0 as? UILabel }).first {
                    label.textColor = isRemindersEnabled ? .label : .secondaryLabel
                }
            }
        }
        
        return cell
    }

    @objc private func reminderSwitchChanged(_ sender: UISwitch) {
        isRemindersEnabled = sender.isOn
        UserDefaults.standard.set(isRemindersEnabled, forKey: "wellsync_patient_reminders_enabled")
        
        // Sync token with Supabase (updates active state)
        PushNotificationService.shared.syncCurrentUserDeviceTokenIfPossible()
        
        // Refresh local scheduling
        NotificationScheduler.shared.refreshForCurrentSession()
        
        // Update visible cells directly without reloading
        updateReminderCellsUI()
    }

    private func updateReminderCellsUI() {
        // Row 1: Mood Log
        let moodIndexPath = IndexPath(row: 1, section: 1)
        if let moodCell = tableView.cellForRow(at: moodIndexPath) {
            moodCell.accessoryType = (isRemindersEnabled && isMoodLogEnabled) ? .checkmark : .none
            if let label = moodCell.contentView.subviews.compactMap({ $0 as? UILabel }).first {
                label.textColor = isRemindersEnabled ? .label : .secondaryLabel
            }
        }
        
        // Row 2: Activity
        let activityIndexPath = IndexPath(row: 2, section: 1)
        if let activityCell = tableView.cellForRow(at: activityIndexPath) {
            activityCell.accessoryType = (isRemindersEnabled && isActivityEnabled) ? .checkmark : .none
            if let label = activityCell.contentView.subviews.compactMap({ $0 as? UILabel }).first {
                label.textColor = isRemindersEnabled ? .label : .secondaryLabel
            }
        }
    }

    override func tableView(
        _ tableView: UITableView,
        didSelectRowAt indexPath: IndexPath
    ) {
        tableView.deselectRow(at: indexPath, animated: true)

        // Section 0 "General" — Row 0: Change Password
        if indexPath.section == 0 && indexPath.row == 0 {
            showCurrentPasswordAlert()
            return
        }

        // Section 1: Reminders toggling (checkmark cells)
        if indexPath.section == 1 {
            guard isRemindersEnabled else { return }
            if indexPath.row == 1 {
                // Toggle Mood Log
                isMoodLogEnabled.toggle()
                UserDefaults.standard.set(isMoodLogEnabled, forKey: "wellsync_patient_mood_log_enabled")
                if let cell = tableView.cellForRow(at: indexPath) {
                    cell.accessoryType = isMoodLogEnabled ? .checkmark : .none
                }
                NotificationScheduler.shared.refreshForCurrentSession()
                return
            } else if indexPath.row == 2 {
                // Toggle Activity
                isActivityEnabled.toggle()
                UserDefaults.standard.set(isActivityEnabled, forKey: "wellsync_patient_activity_enabled")
                if let cell = tableView.cellForRow(at: indexPath) {
                    cell.accessoryType = isActivityEnabled ? .checkmark : .none
                }
                NotificationScheduler.shared.refreshForCurrentSession()
                return
            }
        }

        if indexPath.section == 2 {
            if indexPath.row == 4 {
                logout()
                return
            }

            let storyboard = UIStoryboard(name: "DoctorDetailScreens", bundle: nil)
            guard let detailVC = storyboard.instantiateViewController(
                withIdentifier: "doctorSupportDetail"
            ) as? DoctorSupportDetailViewController else {
                return
            }

            switch indexPath.row {
            case 0: detailVC.screenType = .aboutUs
            case 1: detailVC.screenType = .reportProblem
            case 2: detailVC.screenType = .contactUs
            case 3: detailVC.screenType = .rateUs
            default: return
            }

            navigationController?.pushViewController(detailVC, animated: true)
            return
        }
    }

    // MARK: - Change Password Flow

    /// Step 1 — Ask for the current password.
    private func showCurrentPasswordAlert() {
        let alert = UIAlertController(
            title: "Change Password",
            message: "Enter your current password to continue.",
            preferredStyle: .alert
        )

        alert.addTextField { tf in
            tf.placeholder = "Current Password"
            tf.isSecureTextEntry = true
            tf.returnKeyType = .next
        }

        let verifyAction = UIAlertAction(title: "Verify", style: .default) { [weak self, weak alert] _ in
            guard let currentPassword = alert?.textFields?.first?.text, !currentPassword.isEmpty else {
                self?.showErrorAlert(message: "Please enter your current password.")
                return
            }
            self?.verifyCurrentPassword(currentPassword)
        }

        alert.addAction(verifyAction)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }

    /// Validates the current password against Supabase, then moves to Step 2 on success.
    private func verifyCurrentPassword(_ currentPassword: String) {
        // Resolve the patient's email from the active session.
        guard let email = SessionManager.shared.currentPatient?.email else {
            showErrorAlert(message: "Could not determine your account email. Please log in again.")
            return
        }

        Task {
            do {
                // Re-authenticate to verify; a successful signIn proves the password is correct.
                _ = try await SupabaseManager.shared.signIn(email: email, password: currentPassword)

                await MainActor.run {
                    self.showNewPasswordAlert(email: email, currentPassword: currentPassword)
                }
            } catch {
                await MainActor.run {
                    self.showErrorAlert(message: "Incorrect current password. Please try again.")
                }
            }
        }
    }

    /// Step 2 — Ask for the new password and its confirmation.
    private func showNewPasswordAlert(email: String, currentPassword: String) {
        let alert = UIAlertController(
            title: "New Password",
            message: "Enter and confirm your new password.",
            preferredStyle: .alert
        )

        alert.addTextField { tf in
            tf.placeholder = "New Password"
            tf.isSecureTextEntry = true
            tf.returnKeyType = .next
        }

        alert.addTextField { tf in
            tf.placeholder = "Confirm New Password"
            tf.isSecureTextEntry = true
            tf.returnKeyType = .done
        }

        let updateAction = UIAlertAction(title: "Update", style: .default) { [weak self, weak alert] _ in
            let fields = alert?.textFields
            let newPassword = fields?[0].text ?? ""
            let confirmPassword = fields?[1].text ?? ""

            guard !newPassword.isEmpty else {
                self?.showErrorAlert(message: "New password cannot be empty.")
                return
            }
            guard newPassword.count >= 6 else {
                self?.showErrorAlert(message: "Password must be at least 6 characters.")
                return
            }
            guard newPassword == confirmPassword else {
                self?.showErrorAlert(message: "Passwords do not match. Please try again.")
                return
            }

            self?.performPasswordChange(email: email, currentPassword: currentPassword, newPassword: newPassword)
        }

        alert.addAction(updateAction)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }

    /// Calls the Supabase service to execute the password change.
    private func performPasswordChange(email: String, currentPassword: String, newPassword: String) {
        Task {
            do {
                try await SupabaseManager.shared.changePassword(
                    email: email,
                    currentPassword: currentPassword,
                    newPassword: newPassword
                )
                await MainActor.run {
                    self.showSuccessAlert(message: "Your password has been updated successfully.")
                }
            } catch let error as SupabaseManager.PasswordChangeError {
                await MainActor.run {
                    self.showErrorAlert(message: error.localizedDescription ?? "An error occurred.")
                }
            } catch {
                await MainActor.run {
                    self.showErrorAlert(message: "An unexpected error occurred. Please try again.")
                }
            }
        }
    }

    // MARK: - Alert Helpers

    private func showErrorAlert(message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    private func showSuccessAlert(message: String) {
        let alert = UIAlertController(title: "Success", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    // MARK: - Logout

    func logout() {
        Task {
            do {
                // Step 1: logout from Supabase
                try await SupabaseManager.shared.signOut()

                // Step 2: clear local session
                SessionManager.shared.clearSession()

                // Step 3: UI update on main thread
                await MainActor.run {
                    let storyboard = UIStoryboard(name: "Main", bundle: nil)
                    let loginVC = storyboard.instantiateViewController(withIdentifier: "login")

                    let nav = UINavigationController(rootViewController: loginVC)
                    nav.isNavigationBarHidden = true

                    if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                       let window = scene.windows.first {
                        window.rootViewController = nav
                        window.makeKeyAndVisible()
                    }
                }

            } catch {
                print("Logout failed: \(error)")
            }
        }
    }
}
