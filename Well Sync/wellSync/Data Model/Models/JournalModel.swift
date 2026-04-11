//
//  JournalModel.swift
//  wellSync
//
//  Created by Pranjal on 07/02/26.
//

import Foundation

enum JournalType {
    case written   // Image upload
    case audio     // Recording upload
}

struct JournalEntry {
    let logID: UUID
    let assignmentID: UUID
    let title: String
    let subtitle: String
    let summary: String
    let type: JournalType
    let uploadPath: String?       // kept for backward compatibility
    let uploadPaths: [String]
    let date: Date
    let time: String

    // MARK: - Initializer from ActivityLog

    init(from log: ActivityLog, assignment: AssignedActivity) {
        self.logID        = log.logID
        self.assignmentID = log.assignedID
        self.date         = log.date
        self.time         = log.time
        self.uploadPath   = log.uploadPath

        self.uploadPaths = log.uploadPath
            .map { $0.split(separator: ",").map { String($0).trimmingCharacters(in: .whitespaces) } }
            ?? []

        self.type = Self.determineType(
            uploadPath: log.uploadPath,
            assignment: assignment
        )

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEEE, MMM d"
        self.title = dateFormatter.string(from: log.date)

        let typeText   = self.type == .audio ? "Voice Journal" : "Written Journal"
        self.subtitle  = "\(log.time) • \(typeText)"
        self.summary   = "sample summary"
    }

    // MARK: - Type Determination

    private static func determineType(
        uploadPath: String?,
        assignment: AssignedActivity
    ) -> JournalType {

        if assignment.hasRecording { return .audio }
        if assignment.hasImage     { return .written }

        guard let path = uploadPath else {
            return assignment.hasRecording ? .audio : .written
        }

        let firstPath = path.split(separator: ",").first.map(String.init) ?? path
        let lp = firstPath.lowercased()

        let audioExtensions = [".mp3", ".m4a", ".wav", ".aac", ".ogg"]
        if audioExtensions.contains(where: { lp.hasSuffix($0) }) { return .audio }

        let imageExtensions = [".jpg", ".jpeg", ".png", ".gif", ".heic", ".webp"]
        if imageExtensions.contains(where: { lp.hasSuffix($0) }) { return .written }

        return assignment.hasRecording ? .audio : .written
    }
}
