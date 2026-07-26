//
//  DualMatchingFields.swift
//  Heardle
//
//  Created by Sanchez, Victor J on 7/24/26.
//

import Foundation
import FirebaseFirestore

enum GameStatus: String, Codable {
    case waiting, playing, finished
}

enum PlayerStatus: String, Codable {
    case playing, won, lost
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
    var rounds: Int?
    var guessTimerOn: Bool?
    var clipDurations: [Int]
    
    var playerAttempt: [String: Int]
    var playerStatus: [String: PlayerStatus]
    var playerFinishedAt: [String: Timestamp]
    
    @ServerTimestamp var createdAt: Timestamp?
    var startedAt: Timestamp?
}
