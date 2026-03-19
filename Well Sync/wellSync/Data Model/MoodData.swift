//
//  MoodData.swift
//  wellSync
//
//  Created by Vidit Agarwal on 17/02/26.
//

import Foundation

struct moodLogFeelings: Codable, Sendable {
    let id:UUID
    let logId:UUID
    let feelingId:UUID
}

struct MoodLog: Codable, Sendable {
    var logId: UUID?
    var patientId: UUID?
    var mood: Int
    var date: Date?
    var moodNote: String?
    var selectedFeeling: [Feeling]?
}

struct Feeling: Codable, Sendable {
    var feelingId: UUID
    var moodLevel: MoodLevel
    var name: String
}

enum MoodLevel: Int, Codable, Sendable {
    case verySad 
    case sad
    case neutral
    case happy
    case veryHappy
}
