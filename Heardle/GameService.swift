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
    private static let defaultClipDurations = [1, 2, 4, 7, 11, 16]
    private init() {
        
    }
    
    func generateCode() -> String {
        String((0..<Self.codeLength).map { _ in
            Self.alphabet.randomElement()!
        })
    }
    
    func pickRandomSong(playlist: [Song]) throws -> Song {
        guard let song = playlist.randomElement() else {
            throw GameError.noSongsAvailable
        }
        return song
    }
    
    func createGame(code: String) async throws {
        guard let uid = Auth.auth().currentUser?.uid else {
            throw GameError.notSignedIn
        }

        let game = Game(
            hostId: uid,
            status: .waiting,
            currentRound: 0,
            clipDurations: Self.defaultClipDurations,
            playerAttempt: [uid: 0],
            playerStatus: [uid: .playing],
            playerFinishedAt: [:],
            playerReadyForNext: [:],
            playerRoundsWon: [uid: 0]
        )

        try await withCheckedThrowingContinuation { (cont: CheckedContinuation<Void, Error>) in
            do {
                try db.collection("games").document(code).setData(from: game) { error in
                    if let error { cont.resume(throwing: error) } else { cont.resume() }
                }
            } catch { cont.resume(throwing: error) }
        }
    }
    
    func fetchGame(code: String) async throws -> Game {
        let snapshot = try await db.collection("games")
            .document(code)
            .getDocument(source: .server)
        
        guard snapshot.exists else {
            throw GameError.gameNotFound
        }
        return try snapshot.data(as: Game.self)
    }
    
    func joinGame(code: String) async throws -> Game {
        guard let uid = Auth.auth().currentUser?.uid else {
            throw GameError.notSignedIn
        }
        
        let normalized = code
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .uppercased()
        
        let ref = db.collection("games").document(normalized)
        
        var joinError: GameError?
        
        _ = try await db.runTransaction{
            transaction, errorPointer -> Any? in
            joinError = nil
            
            let snapshot: DocumentSnapshot
            do {
                snapshot = try transaction.getDocument(ref)
            } catch let error as NSError {
                errorPointer?.pointee = error
                return nil
            }
            
            guard let data = snapshot.data() else {
                joinError = .gameNotFound
                return nil
            }
            
            if data["hostId"] as? String == uid {
                joinError = .cannotJoinOwnGame
                return nil
            }
            
            if let existingGuest = data["guestId"] as? String {
                if existingGuest != uid {
                    joinError = .gameFull
                    return nil
                }
                return nil
            }
            
            guard data["status"] as? String == GameStatus.waiting.rawValue else {
                joinError = .gameFull
                return nil
            }
            
            transaction.updateData([
                "guestId": uid,
                "playerAttempt.\(uid)": 0,
                "playerStatus.\(uid)": PlayerStatus.playing.rawValue,
                "playerReadyForNext.\(uid)": false,
                "playerRoundsWon.\(uid)": 0
            ], forDocument: ref)
            
            return nil
        }
        
        if let joinError {
            throw joinError
        }
        
        return try await fetchGame(code: normalized)
    }
    
    func observeGame(
        code: String,
        onChange: @escaping (Result<Game, Error>) -> Void) -> ListenerRegistration {
            db.collection("games").document(code).addSnapshotListener {
                snapshot, error in
                if let error {
                    onChange(.failure(error))
                    return
                }
                guard let snapshot, snapshot.exists else {
                    onChange(.failure(GameError.gameNotFound))
                    return
                }
                do {
                    onChange(.success(try snapshot.data(as: Game.self)))
                } catch {
                    onChange(.failure(error))
                }
            }
    }
    
    func updateSettings(code: String, settings: [String: Any]) async throws {
        try await db.collection("games").document(code).updateData(settings)
    }

    func startGame(code: String, playlist: [Song]) async throws {
        guard let uid = Auth.auth().currentUser?.uid else {
            throw GameError.notSignedIn
        }

        let game = try await fetchGame(code: code)

        guard game.hostId == uid else { throw GameError.cannotJoinOwnGame }
        guard game.guestId != nil else { throw GameError.gameNotFound }

        let song = try pickRandomSong(playlist: playlist)
        guard let songTrackId = song.trackId,
              let songPreviewURL = song.previewURL else {
            throw GameError.invalidSongData
        }

        try await db.collection("games").document(code).updateData([
            "trackId": String(songTrackId),
            "trackTitle": song.name,
            "trackArtist": song.artist,
            "previewURL": songPreviewURL,
            "status": GameStatus.playing.rawValue,
            "currentRound": 1,
            "startedAt": FieldValue.serverTimestamp(),
            "roundStartedAt": FieldValue.serverTimestamp()
        ])
    }
    
    func recordAttempt(code: String, attempt: Int) async throws {
            guard let uid = Auth.auth().currentUser?.uid else {
                throw GameError.notSignedIn
            }
            try await db.collection("games").document(code).updateData([
                "playerAttempt.\(uid)": attempt
            ])
        }

        func recordFinish(code: String, won: Bool) async throws {
            guard let uid = Auth.auth().currentUser?.uid else {
                throw GameError.notSignedIn
            }

            let ref = db.collection("games").document(code)

            _ = try await db.runTransaction { transaction, errorPointer -> Any? in
                let snapshot: DocumentSnapshot
                do {
                    snapshot = try transaction.getDocument(ref)
                } catch let error as NSError {
                    errorPointer?.pointee = error
                    return nil
                }

                guard let data = snapshot.data() else { return nil }

                var statuses = data["playerStatus"] as? [String: String] ?? [:]
                statuses[uid] = won ? PlayerStatus.won.rawValue : PlayerStatus.lost.rawValue

                var update: [String: Any] = [
                    "playerStatus.\(uid)": statuses[uid]!,
                    "playerFinishedAt.\(uid)": FieldValue.serverTimestamp()
                ]

                let hostId = data["hostId"] as? String
                let guestId = data["guestId"] as? String
                let seats = [hostId, guestId].compactMap { $0 }

                let everyoneDone = seats.count == 2 && seats.allSatisfy {
                    statuses[$0] != nil && statuses[$0] != PlayerStatus.playing.rawValue
                }
                
                if everyoneDone {
                    if won {
                        let currentWins = (data["playerRoundsWon"] as? [String: Int])?[uid] ?? 0
                        update["playerRoundsWon.\(uid)"] = currentWins + 1
                    }
                    
                    update["status"] = GameStatus.roundResults.rawValue
                    
                    for seat in seats {
                        update["playerReadyForNext.\(seat)"] = false
                    }
                }

                transaction.updateData(update, forDocument: ref)
                return nil
            }
        }
    
    func markReady(code: String) async throws {
        guard let uid = Auth.auth().currentUser?.uid else {
            throw GameError.notSignedIn
        }
        
        let ref = db.collection("games").document(code)
        
        _ = try await db.runTransaction { transaction, errorPointer -> Any? in
            let snapshot: DocumentSnapshot
            do {
                snapshot = try transaction.getDocument(ref)
            } catch let error as NSError {
                errorPointer?.pointee = error
                return nil
            }
            
            guard let data = snapshot.data() else { return nil }
            
            var update: [String: Any] = [
                "playerReadyForNext.\(uid)": true
            ]
            
            var readyStates = data["playerReadyForNext"] as? [String: Bool] ?? [:]
            readyStates[uid] = true
            
            let hostId = data["hostId"] as? String
            let guestId = data["guestId"] as? String
            let seats = [hostId, guestId].compactMap { $0 }
            
            let allReady = seats.count == 2 && seats.allSatisfy { readyStates[$0] == true }
            
            if allReady {
                let currentRound = data["currentRound"] as? Int ?? 0
                let totalRounds = data["totalRounds"] as? Int ?? 1
                
                if currentRound >= totalRounds {
                    update["status"] = GameStatus.finished.rawValue
                } else {

                }
            }
            
            transaction.updateData(update, forDocument: ref)
            return nil
        }
    }
    
    func startNextRound(code: String, playlist: [Song]) async throws {
        let game = try await fetchGame(code: code)
        
        let currentRound = game.currentRound ?? 0
        let totalRounds = game.totalRounds ?? 1
        
        guard currentRound < totalRounds else {
            try await db.collection("games").document(code).updateData([
                "status": GameStatus.finished.rawValue
            ])
            return
        }
        
        let song = try pickRandomSong(playlist: playlist)
        guard let songTrackId = song.trackId,
              let songPreviewURL = song.previewURL else {
            throw GameError.invalidSongData
        }
        
        let hostId = game.hostId
        let guestId = game.guestId
        let seats = [hostId, guestId].compactMap { $0 }
        
        var update: [String: Any] = [
            "trackId": String(songTrackId),
            "trackTitle": song.name,
            "trackArtist": song.artist,
            "previewURL": songPreviewURL,
            "status": GameStatus.playing.rawValue,
            "currentRound": currentRound + 1,
            "roundStartedAt": FieldValue.serverTimestamp()
        ]
        
        for seat in seats {
            update["playerAttempt.\(seat)"] = 0
            update["playerStatus.\(seat)"] = PlayerStatus.playing.rawValue
            update["playerReadyForNext.\(seat)"] = false
        }
        
        update["playerFinishedAt"] = [:]
        
        try await db.collection("games").document(code).updateData(update)
    }
}
