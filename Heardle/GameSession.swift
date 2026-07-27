//
//  GameSession.swift
//  Heardle
//

import Foundation

struct RoundTrack {
    let title: String
    let artist: String
    let audioURL: URL
}

protocol GameSession {
    var clipDurations: [Int] { get }
    var allowsSkip: Bool { get }
    func isCorrect(_ guess: Song) -> Bool
    func recordAttempt(_ attempt: Int)
    func recordFinish(won: Bool, attempts: Int)
}

extension GameSession {
    var maxAttempts: Int { clipDurations.count }
}


final class SoloSession: GameSession {
    let clipDurations: [Int]
    let allowsSkip = true

    private let answerProvider: () -> Song

    init(clipDurations: [Int] = [1, 2, 4, 7, 11, 16],
         answerProvider: @escaping () -> Song) {
        self.clipDurations = clipDurations
        self.answerProvider = answerProvider
    }

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

    func recordAttempt(_ attempt: Int) { }
    func recordFinish(won: Bool, attempts: Int) { }
}


final class MultiplayerSession: GameSession {
    let gameCode: String
    let clipDurations: [Int]
    let allowsSkip = false

    private(set) var answerTrackId: String

    init(gameCode: String, game: Game) {
        self.gameCode = gameCode
        self.clipDurations = game.clipDurations
        self.answerTrackId = game.trackId ?? ""
    }

    func isCorrect(_ guess: Song) -> Bool {
        guard let id = guess.trackId else { return false }
        return String(id) == answerTrackId
    }

    func recordAttempt(_ attempt: Int) {
        Task {
            try? await GameService.shared.recordAttempt(code: gameCode, attempt: attempt)
        }
    }

    func recordFinish(won: Bool, attempts: Int) {
        Task {
            try? await GameService.shared.recordFinish(code: gameCode, won: won)
        }
    }
}
