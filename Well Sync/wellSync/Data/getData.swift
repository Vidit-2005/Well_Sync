//
//  getData.swift
//  wellSync
//
//  Created by Vidit Agarwal on 14/03/26.
//

import Foundation

func makeDate(_ year: Int, _ month: Int, _ day: Int, hour: Int = 0, minute: Int = 0) -> Date {
    var components = DateComponents()
    components.year = year
    components.month = month
    components.day = day
    components.hour = hour
    components.minute = minute
    print(Calendar.current.date(from: components)!)
    return Calendar.current.date(from: components)!
}

struct TodayActivityItem {
    let activity: Activity
    let assignment: AssignedActivity
    let completedToday: Int
    let logs: [ActivityLog]

    var remaining: Int {
        return max(0, assignment.frequency - completedToday)
    }

    var progressRatio: Float {
        guard assignment.frequency > 0 else { return 0 }
        return min(Float(completedToday) / Float(assignment.frequency), 1.0)
    }
    var isUploadType: Bool {
        return assignment.isUploadType
    }

    var isCompletedToday: Bool {
        return completedToday >= assignment.frequency
    }

    var frequencyText: String {
        return "\(completedToday) of \(assignment.frequency) done today"
    }

}
struct LogSummaryItem {
    let assignment: AssignedActivity  // Store the full assignment
    let activity: Activity
    let logs: [ActivityLog]
    let totalLogs: Int
    
    // Convenience property for cell type
    var isUploadType: Bool {
        return assignment.isUploadType
    }
}

func buildTodayItems(for patientID: UUID) async throws -> [TodayActivityItem] {
    let today = Date()
    
    // Fetch all assignments for this patient
    let allAssignments = try await AccessSupabase.shared.fetchAssignments(for: patientID)
    
    let todayAssignments = allAssignments.filter { $0.isActiveToday }
    
    // Fetch ALL logs for this patient (across all assignments)
    let allLogs = try await AccessSupabase.shared.fetchLogs(for: patientID)

    var items: [TodayActivityItem] = []

    for assignment in todayAssignments {
        // Fetch the activity details
        guard let activity = try await AccessSupabase.shared.fetchActivityByID(
            assignment.activityID
        ) else {
            print("❌ Activity not found for ID: \(assignment.activityID)")
            continue
        }

        // Filter logs for THIS assignment
        let logsForThisAssignment = allLogs.filter {
            $0.assignedID == assignment.assignedID
        }
        
        
        // Filter logs for TODAY
        let todayLogs = logsForThisAssignment.filter {
            Calendar.current.isDate($0.date, inSameDayAs: today)
        }
        
        items.append(TodayActivityItem(
            activity: activity,
            assignment: assignment,
            completedToday: todayLogs.count,
            logs: logsForThisAssignment  // All logs for this assignment
        ))
    }
    
    return items
}
func buildLogSummaries(for patientID: UUID) async throws -> [LogSummaryItem] {

    // Was: assignedActivities.filter
    let allAssignments = try await AccessSupabase.shared.fetchAssignments(for: patientID)
    let inactiveAssignments = allAssignments.filter { !$0.isActiveToday }

    // Was: activityLogs.filter
    let allLogs = try await AccessSupabase.shared.fetchLogs(for: patientID)

    var summaries: [LogSummaryItem] = []

    for assignment in inactiveAssignments {

        guard let activity = try await AccessSupabase.shared.fetchActivityByID(
            assignment.activityID
        ) else {
            print("Activity not found for ID: \(assignment.activityID)")
            continue
        }

        let logs = allLogs.filter { $0.assignedID == assignment.assignedID }

        summaries.append(LogSummaryItem(
                            assignment: assignment,
                            activity: activity,
                            logs: logs,
                            totalLogs: logs.count
                        ))
    }
    return summaries.sorted { $0.totalLogs > $1.totalLogs }
}
