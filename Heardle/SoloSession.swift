//
//  SoloSession.swift
//  Heardle
//
//  Created by Ehimuh, Perry on 7/28/26.
//  Project: Heardle
//  Team Number: 3
//  Team Members: Jeremiah Franklin, Victor Sanchez, Haroon Memon, Perry Ehimuh
//  Course: CS371L
//

import Foundation

// Represents the song used for a single game round.
final class SoloSession: GameSession {
    let clipDurations: [Int]
    let allowsSkip = true
    
    private let answerProvider: () -> Song
    
    // Represents the song used for a single game round.
    init(clipDurations: [Int] = [1, 2, 4, 7, 11, 16],
         answerProvider: @escaping () -> Song) {
        self.clipDurations = clipDurations
        self.answerProvider = answerProvider
    }
    
    // Represents the song used for a single game round.
    func isCorrect(_ guess: Song) -> Bool {
        let answer = answerProvider()
        let result = guess == answer
        
        // Debug logging to help diagnose comparison issues
        print("[SOLO] Comparing guess to answer:")
        print("[SOLO]   Guess: '\(guess.name)' by '\(guess.artist)'")
        print("[SOLO]   Answer: '\(answer.name)' by '\(answer.artist)'")
        print("[SOLO]   Result: \(result ? "✅ CORRECT" : "❌ WRONG")")
        
        return result
    }
    
    // Records the player's current attempt during a solo game.
    func recordAttempt(_ attempt: Int) { }
    // Records the player's current attempt during a solo game.
    func recordFinish(won: Bool, attempts: Int) { }
}
