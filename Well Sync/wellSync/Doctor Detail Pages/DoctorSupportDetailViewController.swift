//
//  DoctorSupportDetailViewController.swift
//  wellSync
//
//  Created by Codex on 24/04/26.
//

import StoreKit
import UIKit

final class DoctorSupportDetailViewController: UITableViewController {

    var screenType: DoctorSupportScreenType = .aboutUs

    private var sections: [DoctorDetailSection] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.largeTitleDisplayMode = .never
        title = screenType.title
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "valueCell")
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "detailCell")
        tableView.separatorStyle = .singleLine
        tableView.backgroundColor = .systemGroupedBackground
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 76
        tableView.sectionFooterHeight = UITableView.automaticDimension
        tableView.estimatedSectionFooterHeight = 44
        tableView.sectionHeaderHeight = UITableView.automaticDimension
        tableView.estimatedSectionHeaderHeight = 28
        configureHeader()
        buildSections()
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        sections.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        sections[section].rows.count
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        sections[section].title
    }

    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        sections[section].footer
    }

    override func tableView(
        _ tableView: UITableView,
        cellForRowAt indexPath: IndexPath
    ) -> UITableViewCell {
        let row = sections[indexPath.section].rows[indexPath.row]
        let hasDetail = row.detail != nil
        let identifier = hasDetail ? "detailCell" : "valueCell"
        let cell = tableView.dequeueReusableCell(withIdentifier: identifier, for: indexPath)

        var content: UIListContentConfiguration
        if hasDetail {
            content = UIListContentConfiguration.subtitleCell()
            content.secondaryText = row.detail
            content.secondaryTextProperties.numberOfLines = 0
            content.secondaryTextProperties.color = .secondaryLabel
        } else {
            content = UIListContentConfiguration.valueCell()
        }

        content.text = row.title
        content.textProperties.font = .systemFont(ofSize: 17, weight: .semibold)
        content.secondaryText = row.value ?? content.secondaryText
        content.secondaryTextProperties.numberOfLines = 0
        content.secondaryTextProperties.color = .secondaryLabel
        content.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 14, leading: 0, bottom: 14, trailing: 0)
        cell.contentConfiguration = content
        cell.accessoryType = row.accessory == .disclosure ? .disclosureIndicator : .none
        cell.selectionStyle = row.action == nil ? .none : .default
        cell.backgroundColor = .secondarySystemGroupedBackground
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        sections[indexPath.section].rows[indexPath.row].action?()
    }

    private func buildSections() {
        switch screenType {
        case .aboutUs:
            sections = [
                DoctorDetailSection(
                    title: "Well Sync",
                    rows: [
                        DoctorDetailRow(
                            title: "Built for connected care",
                            detail: "Well Sync helps doctors and patients stay aligned through profile management, scheduling, reports, notes, and health activity tracking."
                        ),
                        DoctorDetailRow(
                            title: "Designed for clarity",
                            detail: "The app focuses on clean workflows so professionals can review key patient information quickly and confidently."
                        )
                    ],
                    footer: "This page reflects the doctor-side experience and uses the current app theme for consistency."
                ),
                DoctorDetailSection(
                    title: "Core Experience",
                    rows: [
                        DoctorDetailRow(title: "Doctor workflows", value: "Profiles, appointments, reports, notes"),
                        DoctorDetailRow(title: "Patient support", value: "Tracking, mood logs, activity and vitals")
                    ],
                    footer: nil
                )
            ]
        case .reportProblem:
            sections = [
                DoctorDetailSection(
                    title: "Before Reporting",
                    rows: [
                        DoctorDetailRow(
                            title: "Capture what happened",
                            detail: "Include the screen name, the action you took, and whether the issue can be reproduced."
                        ),
                        DoctorDetailRow(
                            title: "Helpful details",
                            detail: "Mention the doctor account used, internet state, and any visible error message."
                        )
                    ],
                    footer: nil
                ),
                DoctorDetailSection(
                    title: "Quick Action",
                    rows: [
                        DoctorDetailRow(
                            title: "Copy issue summary",
                            detail: "Creates a ready-to-send problem report template for the Well Sync team.",
                            accessory: .disclosure
                        ) { [weak self] in
                            self?.copyIssueTemplate()
                        }
                    ],
                    footer: "Attaching a screenshot and the exact time of the issue helps support resolve problems faster."
                )
            ]
        case .contactUs:
            sections = [
                DoctorDetailSection(
                    title: "Support Guidance",
                    rows: [
                        DoctorDetailRow(
                            title: "Best contact route",
                            detail: "Use your registered Well Sync account details when contacting support so your request can be matched quickly."
                        ),
                        DoctorDetailRow(
                            title: "Recommended message",
                            detail: "Share your role, affected screen, and the outcome you expected."
                        )
                    ],
                    footer: nil
                ),
                DoctorDetailSection(
                    title: "Quick Action",
                    rows: [
                        DoctorDetailRow(
                            title: "Copy contact template",
                            detail: "Copies a concise support request template tailored to the doctor portal.",
                            accessory: .disclosure
                        ) { [weak self] in
                            self?.copyContactTemplate()
                        }
                    ],
                    footer: "Keep patient-sensitive information out of general support requests unless specifically required by your workflow."
                )
            ]
        case .rateUs:
            sections = [
                DoctorDetailSection(
                    title: "Feedback",
                    rows: [
                        DoctorDetailRow(
                            title: "Why ratings matter",
                            detail: "Doctor feedback helps prioritize the improvements that reduce friction in everyday clinical workflows."
                        ),
                        DoctorDetailRow(
                            title: "What to mention",
                            detail: "You can highlight stability, appointment flow, reporting, or profile management based on your experience."
                        )
                    ],
                    footer: nil
                ),
                DoctorDetailSection(
                    title: "Quick Action",
                    rows: [
                        DoctorDetailRow(
                            title: "Rate Well Sync",
                            detail: "Opens the in-app review prompt when available on this device.",
                            accessory: .disclosure
                        ) { [weak self] in
                            self?.requestReview()
                        }
                    ],
                    footer: "If the review prompt does not appear, Apple may already have shown it recently."
                )
            ]
        }
    }

    private func configureHeader() {
        let headerHeight: CGFloat = 208
        let horizontalPadding: CGFloat = 20
        let container = UIView(frame: CGRect(x: 0, y: 0, width: tableView.bounds.width, height: headerHeight))
        container.backgroundColor = .clear

        let card = UIView(frame: CGRect(x: horizontalPadding, y: 16, width: tableView.bounds.width - (horizontalPadding * 2), height: 172))
        card.autoresizingMask = [.flexibleWidth]
        card.backgroundColor = screenType.accentColor.withAlphaComponent(0.14)
        card.layer.cornerRadius = 24

        let iconView = UIImageView(frame: CGRect(x: 20, y: 20, width: 44, height: 44))
        iconView.image = UIImage(systemName: screenType.symbolName)
        iconView.tintColor = screenType.accentColor
        iconView.contentMode = .scaleAspectFit

        let titleLabel = UILabel(frame: CGRect(x: 20, y: 72, width: card.bounds.width - 40, height: 68))
        titleLabel.autoresizingMask = [.flexibleWidth]
        titleLabel.font = .systemFont(ofSize: 25, weight: .bold)
        titleLabel.textColor = .label
        titleLabel.numberOfLines = 2
        titleLabel.text = screenType.title

        let subtitleLabel = UILabel(frame: CGRect(x: 20, y: 132, width: card.bounds.width - 40, height: 32))
        subtitleLabel.autoresizingMask = [.flexibleWidth]
        subtitleLabel.font = .systemFont(ofSize: 15, weight: .medium)
        subtitleLabel.textColor = .secondaryLabel
        subtitleLabel.numberOfLines = 0
        subtitleLabel.text = screenType.subtitle

        card.addSubview(iconView)
        card.addSubview(titleLabel)
        card.addSubview(subtitleLabel)
        container.addSubview(card)
        tableView.tableHeaderView = container
    }

    private func requestReview() {
        guard let scene = view.window?.windowScene ??
                UIApplication.shared.connectedScenes.first as? UIWindowScene else {
            showAlert(title: "Rate Us", message: "The review prompt is not available right now.")
            return
        }

        SKStoreReviewController.requestReview(in: scene)
        showAlert(title: "Thanks", message: "Your feedback helps improve the Well Sync experience.")
    }

    private func copyIssueTemplate() {
        let doctorName = SessionManager.shared.currentDoctor?.name ?? "Doctor"
        UIPasteboard.general.string = """
        Well Sync Problem Report
        Doctor: \(doctorName)
        Screen:
        Issue summary:
        Expected result:
        Actual result:
        Time of issue:
        """
        showAlert(title: "Copied", message: "A problem report template has been copied to the clipboard.")
    }

    private func copyContactTemplate() {
        let doctorName = SessionManager.shared.currentDoctor?.name ?? "Doctor"
        UIPasteboard.general.string = """
        Well Sync Support Request
        Name: \(doctorName)
        Role: Doctor
        Screen:
        Request:
        Best callback detail:
        """
        showAlert(title: "Copied", message: "A support contact template has been copied to the clipboard.")
    }

    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
