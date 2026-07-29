//
//  DualMatchingFields.swift
//  Heardle
//
//  Created by Sanchez, Victor J on 7/24/26.
//  Project: Heardle
//  Team Number: 3
//  Team Members: Jeremiah Franklin, Victor Sanchez, Haroon Memon, Perry Ehimuh
//  Course: CS371L
//

import Foundation
import FirebaseFirestore

enum GameStatus: String, Codable {
    // Represents the current state of a multiplayer game session.
    case waiting      // Lobby, waiting for guest to join
    case playing      // Active round in progress
    case roundResults // Showing results between rounds
    case finished     // All rounds complete
}

enum PlayerStatus: String, Codable {
    // Represents the current state of an individual player's progress.
    case playing      // Currently guessing
    case won          // Guessed correctly this round
    case lost         // Failed this round
    case ready        // Ready for next round
}

// Stores all multiplayer game data shared between players through Firebase.
struct Game: Codable {
    // Unique identifier for the game document stored in Firestore.
    @DocumentID var code: String?
    
    // User ID of the player who created the game.
    var hostId: String
    
    // User ID of the player who joins the host's game.
    var guestId: String?
    
    // Current status of the multiplayer game.
    var status: GameStatus
    
    // Information about the song currently being played in the round.
    var trackId: String?
    var trackTitle: String?
    var trackArtist: String?
    var previewURL: String?
    
    // Match configuration settings selected by the host.
    var playlistName: String?
    var totalRounds: Int?
    var currentRound: Int?
    var clipDurations: [Int]
    
    // Tracks each player's progress and status throughout the game.
    var playerAttempt: [String: Int]
    var playerStatus: [String: PlayerStatus]
    
    // Stores when each player finishes their current round.
    var playerFinishedAt: [String: Timestamp]
    
    // Tracks whether each player is ready to begin the next round.
    var playerReadyForNext: [String: Bool]?
    
    // Stores the number of rounds won by each player.
    var playerRoundsWon: [String: Int]?
    
    // Firebase timestamps used to track game creation and round timing.
    @ServerTimestamp var createdAt: Timestamp?
    var startedAt: Timestamp?
    var roundStartedAt: Timestamp?
}
