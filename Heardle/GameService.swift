//
//  GameService.swift
//  Heardle
//
//  Created by Sanchez, Victor J on 7/24/26.
//

import Foundation
import FirebaseCore
import FirebaseAuth
import FirebaseFirestore

enum GameError: LocalizedError {
    case notSignedIn
    case gameNotFound
    case gameFull
    case cannotJoinOwnGame
    case noSongsAvailable
    case invalidSongData
    
    var errorDescription: String? {
        switch self {
        case .notSignedIn:
            return "You must be signed in to create a game"
        case .gameNotFound:
            return "Game not found"
        case .gameFull:
            return "Game is full"
        case .cannotJoinOwnGame:
            return "Cannot join your own game"
        case .noSongsAvailable:
            return "No songs available"
        case .invalidSongData:
            return "That song is missing data needed to play"
        
        }
    }
}

final class GameService {
    static let shared = GameService()
    private let db = Firestore.firestore()
    private static let alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZ23456789"
    private static let codeLength = 6
    private init() {
        
    }
    
    private func generateCode() -> String {
        String((0..<Self.codeLength).map { _ in
            Self.alphabet.randomElement()!
        })
    }
    
    func pickRandomSong(playlist: [Song]) -> Song {
        return playlist.randomElement()!
    }
    
    func createGame() async throws -> String {
        guard let uid = Auth.auth().currentUser?.uid else {
            throw GameError.notSignedIn
        }
        
        let song = pickRandomSong(playlist: songList)
        
        guard let trackId = song.trackId, let previewURL = song.previewURL else {
            throw GameError.invalidSongData
        }
        
        let code = generateCode()
        
        let game = Game(hostId: uid, status: .waiting, trackId: String(song.trackId!), trackTitle: song.name, trackArtist: song.artist, previewURL: song.previewURL!, clipDurations: clipDurations, playerAttempt: [uid: 0], playerStatus: [uid: .playing], playerFinishedAt: [:])
        
        try await withCheckedThrowingContinuation { (cont: CheckedContinuation <Void, Error>) in
            do {
                try db.collection("games").document(code).setData(from: game) { error in
                    if let error {
                        cont.resume(throwing: error)
                    }
                    else {
                        cont.resume()
                    }
                }
            } catch {
                cont.resume(throwing: error)
            }
        }
        return code
    }
}
