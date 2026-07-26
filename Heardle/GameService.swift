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
            clipDurations: Self.defaultClipDurations,
            playerAttempt: [uid: 0],
            playerStatus: [uid: .playing],
            playerFinishedAt: [:]
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
                "status": GameStatus.playing.rawValue,
                "startedAt": FieldValue.serverTimestamp(),
                "playerAttempt.\(uid)": 0,
                "playerStatus.\(uid)": PlayerStatus.playing.rawValue
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
}
