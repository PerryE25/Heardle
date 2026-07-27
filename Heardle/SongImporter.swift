//
//  SongImporter.swift
//  Heardle
//
//  Created by Memon, Haroon on 7/18/26.
//  Project: Heardle
//  Team Number: 3
//  Team Members: Jeremiah Franklin, Victor Sanchez, Haroon Memon, Perry Ehimuh
//  Course: CS371L
//

import FirebaseAuth
import FirebaseFirestore
import Foundation

let songImporter = SongImporter()

// Imports Spotify songs for a user and saves playable tracks to Firestore.
class SongImporter {

    let songService = SongService()

    // Imports songs only if not already imported; returns true on success.
    func importSongsIfNeeded(spotifyAccessToken: String, user: User) async -> Bool {

        let userDocument = Firestore.firestore()
            .collection("users")
            .document(user.uid)

        do {
            let snapshot = try await userDocument.getDocument()

            let songsImported =
                snapshot.data()?["songsImported"] as? Bool ?? false

            if songsImported {
                print("Songs were already imported")
                return true
            }

            let topSongs = await fetchTopTracks(
                spotifyAccessToken: spotifyAccessToken
            )

            let savedSongs = await fetchSavedTracks(
                spotifyAccessToken: spotifyAccessToken
            )

            let spotifySongs = combineSongs(
                topSongs: topSongs,
                savedSongs: savedSongs
            )

            if spotifySongs.isEmpty {
                print("No Spotify songs were found")
                return false
            }

            print("Found \(spotifySongs.count) unique Spotify songs")

            await songService.fetchUsersArtworkAndPreview(
                songs: spotifySongs
            )

            let playableSongs = spotifySongs.filter { song in
                song.previewURL != nil
            }

            if playableSongs.isEmpty {
                print("No iTunes previews were found")
                return false
            }

            try await saveSongs(playableSongs, for: user)

            print("Imported \(playableSongs.count) playable songs")
            return true
        } catch {
            print("Song import error: \(error.localizedDescription)")
            return false
        }
    }

    // Fetches the user's top Spotify tracks.
    func fetchTopTracks(spotifyAccessToken: String) async -> [Song] {

        let urlString =
            "https://api.spotify.com/v1/me/top/tracks" +
            "?limit=50&time_range=medium_term"

        guard let url = URL(string: urlString) else {
            print("Invalid top tracks URL")
            return []
        }

        var request = URLRequest(url: url)
        request.setValue(
            "Bearer \(spotifyAccessToken)",
            forHTTPHeaderField: "Authorization"
        )

        do {
            let (data, response) = try await URLSession.shared.data(
                for: request
            )

            guard let httpResponse = response as? HTTPURLResponse else {
                print("Invalid Spotify response")
                return []
            }

            guard httpResponse.statusCode == 200 else {
                print("Top tracks status code: \(httpResponse.statusCode)")
                return []
            }

            guard
                let json = try JSONSerialization.jsonObject(with: data)
                    as? [String: Any],
                let tracks = json["items"] as? [[String: Any]]
            else {
                print("Could not read top tracks")
                return []
            }

            var songs: [Song] = []

            for track in tracks {
                if let song = createSong(from: track) {
                    songs.append(song)
                }
            }

            print("Spotify returned \(songs.count) top tracks")
            return songs
        } catch {
            print("Top tracks error: \(error.localizedDescription)")
            return []
        }
    }

    // Fetches the user's saved Spotify tracks.
    func fetchSavedTracks(
        spotifyAccessToken: String
    ) async -> [Song] {

        let urlString =
            "https://api.spotify.com/v1/me/tracks" +
            "?limit=50"

        guard let url = URL(string: urlString) else {
            print("Invalid saved tracks URL")
            return []
        }

        var request = URLRequest(url: url)
        request.setValue(
            "Bearer \(spotifyAccessToken)",
            forHTTPHeaderField: "Authorization"
        )

        do {
            let (data, response) = try await URLSession.shared.data(
                for: request
            )

            guard let httpResponse = response as? HTTPURLResponse else {
                print("Invalid Spotify response")
                return []
            }

            guard httpResponse.statusCode == 200 else {
                print("Saved tracks status code: \(httpResponse.statusCode)")
                return []
            }

            guard
                let json = try JSONSerialization.jsonObject(with: data)
                    as? [String: Any],
                let items = json["items"] as? [[String: Any]]
            else {
                print("Could not read saved tracks")
                return []
            }

            var songs: [Song] = []

            for item in items {
                guard let track = item["track"] as? [String: Any] else {
                    continue
                }

                if let song = createSong(from: track) {
                    songs.append(song)
                }
            }

            print("Spotify returned \(songs.count) saved tracks")
            return songs
        } catch {
            print("Saved tracks error: \(error.localizedDescription)")
            return []
        }
    }

    // Creates a Song from a Spotify track JSON payload.
    func createSong(from track: [String: Any]) -> Song? {
        guard
            let name = track["name"] as? String,
            let artists = track["artists"] as? [[String: Any]],
            let artist = artists.first?["name"] as? String,
            let albumData = track["album"] as? [String: Any],
            let album = albumData["name"] as? String
        else {
            return nil
        }

        return Song(name: name, artist: artist, album: album)
    }

    // Combines and de-duplicates top and saved tracks, up to 100 songs.
    func combineSongs(
        topSongs: [Song],
        savedSongs: [Song]
    ) -> [Song] {

        var combinedSongs: [Song] = []

        for song in topSongs + savedSongs {
            let alreadyAdded = combinedSongs.contains { existingSong in
                existingSong.name.lowercased() == song.name.lowercased()
                    && existingSong.artist.lowercased()
                        == song.artist.lowercased()
            }

            if !alreadyAdded {
                combinedSongs.append(song)
            }

            if combinedSongs.count == 100 {
                break
            }
        }

        return combinedSongs
    }

    // Saves the provided songs to Firestore with ordering metadata.
    func saveSongs(
        _ songs: [Song],
        for user: User
    ) async throws {

        let database = Firestore.firestore()
        let userDocument = database
            .collection("users")
            .document(user.uid)
        let songsCollection = userDocument.collection("songs")
        let batch = database.batch()

        var order = 0

        for song in songs {
            guard let previewURL = song.previewURL else {
                continue
            }

            let songDocument = songsCollection.document()
            var songData: [String: Any] = [
                "name": song.name,
                "artist": song.artist,
                "album": song.album,
                "audioURL": previewURL,
                "albumArt": song.itunesArtworkURL ?? "",
                "order": order,
            ]
            
            // Add trackId if available (required for multiplayer)
            if let trackId = song.trackId {
                songData["trackId"] = trackId
            }

            batch.setData(songData, forDocument: songDocument)
            order += 1
        }

        batch.setData(
            [
                "songsImported": true,
                "songsImportedAt": FieldValue.serverTimestamp(),
            ],
            forDocument: userDocument,
            merge: true
        )

        try await batch.commit()
        print("Songs saved to Firestore")
    }
}

