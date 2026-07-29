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
struct RoundTrack {
    let title: String
    let artist: String
    let audioURL: URL
}

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

// Manages gameplay logic for multiplayer mode.
final class MultiplayerSession: GameSession {
    
    let gameCode: String
    let clipDurations: [Int]
    let allowsSkip = false
    
    private(set) var answerTrackId: String
    
    // Manages gameplay logic for multiplayer mode.
    init(gameCode: String, game: Game) {
        self.gameCode = gameCode
        self.clipDurations = game.clipDurations
        self.answerTrackId = game.trackId ?? ""
    }
    
    // Manages gameplay logic for multiplayer mode.
    func isCorrect(_ guess: Song) -> Bool {
        guard let id = guess.trackId else { return false }
        return String(id) == answerTrackId
    }
    
    // Manages gameplay logic for multiplayer mode.
    func recordAttempt(_ attempt: Int) {
        Task {
            try? await GameService.shared.recordAttempt(code: gameCode, attempt: attempt)
        }
    }
    
    // Records the player's current attempt in the multiplayer game.
    func recordFinish(won: Bool, attempts: Int) {
        Task {
            try? await GameService.shared.recordFinish(code: gameCode, won: won)
        }
    }
}
