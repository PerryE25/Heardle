//
//  MultiplayerSession.swift
//  Heardle
//
//  Created by Ehimuh, Perry on 7/28/26.
//  Created by Ehimuh, Perry on 6/29/26.
//  Project: Heardle
//  Team Number: 3
//  Team Members: Jeremiah Franklin, Victor Sanchez, Haroon Memon, Perry Ehimuh
//  Course: CS371L
//

import Foundation

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
