//
//  GameSession.swift
//  Heardle
//
//  Project: Heardle
//  Team Number: 3
//  Team Members: Jeremiah Franklin, Victor Sanchez, Haroon Memon, Perry Ehimuh
//  Course: CS371L
//

import Foundation

// Represents the song used for a single game round.
protocol GameSession {
    var clipDurations: [Int] { get }
    var allowsSkip: Bool { get }
    func isCorrect(_ guess: Song) -> Bool
    func recordAttempt(_ attempt: Int)
    func recordFinish(won: Bool, attempts: Int)
}

// Represents the song used for a single game round.
extension GameSession {
    var maxAttempts: Int { clipDurations.count }
}
