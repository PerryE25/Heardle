//
//  DualMatchingFields.swift
//  Heardle
//
//  Created by Sanchez, Victor J on 7/24/26.
//

import Foundation
import FirebaseFirestore

enum GameStatus: String, Codable {
    case waiting      // Lobby, waiting for guest to join
    case playing      // Active round in progress
    case roundResults // Showing results between rounds
    case finished     // All rounds complete
}

enum PlayerStatus: String, Codable {
    case playing      // Currently guessing
    case won          // Guessed correctly this round
    case lost         // Failed this round
    case ready        // Ready for next round
}

struct Game: Codable {
    @DocumentID var code: String?
    
    var hostId: String
    var guestId: String?
    var status: GameStatus
    
    var trackId: String?
    var trackTitle: String?
    var trackArtist: String?
    var previewURL: String?
    
    var playlistName: String?
    var totalRounds: Int?
    var currentRound: Int?
    var clipDurations: [Int]
    
    var playerAttempt: [String: Int]
    var playerStatus: [String: PlayerStatus]
    var playerFinishedAt: [String: Timestamp]
    var playerReadyForNext: [String: Bool]?
    
    var playerRoundsWon: [String: Int]?
    
    @ServerTimestamp var createdAt: Timestamp?
    var startedAt: Timestamp?
    var roundStartedAt: Timestamp?
}
