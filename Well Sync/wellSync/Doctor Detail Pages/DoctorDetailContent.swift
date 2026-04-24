//
//  DoctorDetailContent.swift
//  wellSync
//
//  Created by Codex on 24/04/26.
//

import UIKit

enum DoctorCredentialScreenType {
    case education
    case registration
    case identity

    var title: String {
        switch self {
        case .education:
            return "Educational Qualification"
        case .registration:
            return "Registration Details"
        case .identity:
            return "Identity Proof"
        }
    }

    var subtitle: String {
        switch self {
        case .education:
            return "Review the qualification details linked to your Well Sync doctor profile."
        case .registration:
            return "Keep registration information clear and ready for patient trust and compliance."
        case .identity:
            return "Use this page to quickly verify the identity document stored for this doctor account."
        }
    }

    var symbolName: String {
        switch self {
        case .education:
            return "graduationcap.fill"
        case .registration:
            return "checkmark.seal.fill"
        case .identity:
            return "person.text.rectangle.fill"
        }
    }

    var accentColor: UIColor {
        switch self {
        case .education:
            return .systemTeal
        case .registration:
            return .systemGreen
        case .identity:
            return .systemIndigo
        }
    }
}

enum DoctorSupportScreenType {
    case aboutUs
    case reportProblem
    case contactUs
    case rateUs

    var title: String {
        switch self {
        case .aboutUs:
            return "About Us"
        case .reportProblem:
            return "Report a Problem"
        case .contactUs:
            return "Contact Us"
        case .rateUs:
            return "Rate Us"
        }
    }

    var subtitle: String {
        switch self {
        case .aboutUs:
            return "Learn how Well Sync supports coordinated care for doctors and patients."
        case .reportProblem:
            return "Capture the right details so issues can be reproduced and resolved faster."
        case .contactUs:
            return "Find the best way to reach the Well Sync support and product team."
        case .rateUs:
            return "Share feedback that helps us keep the doctor experience smooth and reliable."
        }
    }

    var symbolName: String {
        switch self {
        case .aboutUs:
            return "cross.case.fill"
        case .reportProblem:
            return "exclamationmark.bubble.fill"
        case .contactUs:
            return "phone.circle.fill"
        case .rateUs:
            return "star.circle.fill"
        }
    }

    var accentColor: UIColor {
        switch self {
        case .aboutUs:
            return .systemMint
        case .reportProblem:
            return .systemOrange
        case .contactUs:
            return .systemBlue
        case .rateUs:
            return .systemPink
        }
    }
}

struct DoctorDetailSection {
    let title: String?
    let rows: [DoctorDetailRow]
    let footer: String?
}

struct DoctorDetailRow {
    enum Accessory {
        case none
        case disclosure
    }

    let title: String
    let value: String?
    let detail: String?
    let accessory: Accessory
    let action: (() -> Void)?

    init(
        title: String,
        value: String? = nil,
        detail: String? = nil,
        accessory: Accessory = .none,
        action: (() -> Void)? = nil
    ) {
        self.title = title
        self.value = value
        self.detail = detail
        self.accessory = accessory
        self.action = action
    }
}

