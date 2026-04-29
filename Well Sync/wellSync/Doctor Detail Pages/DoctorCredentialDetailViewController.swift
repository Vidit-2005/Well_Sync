//
//  DoctorCredentialDetailViewController.swift
//  wellSync
//
//  Created by Codex on 24/04/26.
//

import UIKit

final class DoctorCredentialDetailViewController: UITableViewController {

    var screenType: DoctorCredentialScreenType = .education

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
        buildSections()
        configureHeader()
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
            content.secondaryTextProperties.color = .secondaryLabel
            content.secondaryTextProperties.numberOfLines = 0
        } else {
            content = UIListContentConfiguration.valueCell()
        }

        content.text = row.title
        content.textProperties.font = .systemFont(ofSize: 17, weight: .semibold)
        content.image = nil
        content.prefersSideBySideTextAndSecondaryText = false
        content.secondaryText = row.value ?? content.secondaryText
        content.secondaryTextProperties.color = .secondaryLabel
        content.secondaryTextProperties.numberOfLines = 0
        content.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 14, leading: 0, bottom: 14, trailing: 0)
        cell.contentConfiguration = content
        cell.accessoryType = row.accessory == .disclosure ? .disclosureIndicator : .none
        cell.selectionStyle = row.action == nil ? .none : .default
        cell.backgroundColor = .tertiarySystemBackground
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        sections[indexPath.section].rows[indexPath.row].action?()
    }

    private func buildSections() {
        guard let doctor = SessionManager.shared.currentDoctor else {
            sections = [
                DoctorDetailSection(
                    title: "Profile Status",
                    rows: [
                        DoctorDetailRow(
                            title: "Doctor profile unavailable",
                            detail: "Sign in again to load your saved profile information."
                        )
                    ],
                    footer: nil
                )
            ]
            return
        }

        let profileSummary = DoctorDetailSection(
            title: "Current Record",
            rows: summaryRows(for: doctor),
            footer: nil
        )

        let guidance = DoctorDetailSection(
            title: "Why It Matters",
            rows: guidanceRows(),
            footer: "These details help keep the doctor profile complete, trustworthy, and ready for operational review."
        )

        sections = [profileSummary, guidance]
    }

    private func summaryRows(for doctor: Doctor) -> [DoctorDetailRow] {
        switch screenType {
        case .education:
            let qualification = nonEmpty(doctor.qualification, fallback: "Not added yet")
            let documentName = formattedFileName(from: doctor.educationImageData, fallback: "No certificate uploaded")
            return [
                DoctorDetailRow(title: "Qualification", value: qualification),
                DoctorDetailRow(title: "Document Status", value: statusText(for: doctor.educationImageData)),
                DoctorDetailRow(
                    title: "Certificate",
                    detail: "Stored file: \(documentName)"
                )
            ]
        case .registration:
            let registrationNumber = nonEmpty(doctor.registrationNumber, fallback: "Not added yet")
            let documentName = formattedFileName(from: doctor.registrationImageData, fallback: "No registration proof uploaded")
            return [
                DoctorDetailRow(title: "Registration Number", value: registrationNumber),
                DoctorDetailRow(title: "Verification Status", value: statusText(for: doctor.registrationImageData)),
                DoctorDetailRow(
                    title: "Registration Proof",
                    detail: "Stored file: \(documentName)"
                )
            ]
        case .identity:
            let identityNumber = nonEmpty(doctor.identityNumber, fallback: "Not added yet")
            let documentName = formattedFileName(from: doctor.identityImageData, fallback: "No identity document uploaded")
            return [
                DoctorDetailRow(title: "Identity Number", value: identityNumber),
                DoctorDetailRow(title: "Document Status", value: statusText(for: doctor.identityImageData)),
                DoctorDetailRow(
                    title: "Proof on File",
                    detail: "Stored file: \(documentName)"
                )
            ]
        }
    }

    private func guidanceRows() -> [DoctorDetailRow] {
        switch screenType {
        case .education:
            return [
                DoctorDetailRow(
                    title: "Professional credibility",
                    detail: "Qualifications reassure patients that their care is managed by a verified professional."
                ),
                DoctorDetailRow(
                    title: "Recommended format",
                    detail: "Use a degree name, specialization, or board-recognized qualification for clearer profile presentation."
                )
            ]
        case .registration:
            return [
                DoctorDetailRow(
                    title: "Compliance readiness",
                    detail: "Registration details make it easier to validate practice credentials during reviews or onboarding."
                ),
                DoctorDetailRow(
                    title: "Best practice",
                    detail: "Keep the registration identifier current and ensure the proof matches the active medical record."
                )
            ]
        case .identity:
            return [
                DoctorDetailRow(
                    title: "Safer account management",
                    detail: "Identity proof helps protect the account and supports secure verification workflows."
                ),
                DoctorDetailRow(
                    title: "Document quality",
                    detail: "Readable, up-to-date documents reduce manual verification delays."
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

    private func nonEmpty(_ value: String?, fallback: String) -> String {
        guard let trimmed = value?.trimmingCharacters(in: .whitespacesAndNewlines),
              !trimmed.isEmpty else {
            return fallback
        }
        return trimmed
    }

    private func statusText(for path: String?) -> String {
        let hasValue = !(path?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true)
        return hasValue ? "On file" : "Pending upload"
    }

    private func formattedFileName(from path: String?, fallback: String) -> String {
        guard let path, !path.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return fallback
        }
        return URL(string: path)?.lastPathComponent ?? URL(fileURLWithPath: path).lastPathComponent
    }
}
