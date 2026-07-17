//
//  SearchViewController.swift
//  Heardle
//
//  Created by Ehimuh, Perry on 7/9/26.
//  Project: Heardle
//  Team Number: 3
//  Team Members: Jeremiah Franklin, Victor Sanchez, Haroon Memon, Perry Ehimuh
//  Course: CS371L
//

import UIKit

var selectedSongCanidate: Song?

// Presents searchable song results and returns the user’s selection to the game screen.
class SearchViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate {
    
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var resultsHeaderLabel: UILabel!
    @IBOutlet weak var songTableView: UITableView!
    
    var filteredSongs: [Song] = []
    var searchedSongResults: [Song] = []
    let songCellID = "SongCell"
    
    // MARK: - Lifecycle
    
    // Sets up delegates and applies dark appearance for the search experience.
    override func viewDidLoad() {
        super.viewDidLoad()

        songTableView.delegate = self
        songTableView.dataSource = self
        searchBar.delegate = self
        self.view.overrideUserInterfaceStyle = .dark
    }
    
    // Focus the search field immediately so the user can start typing.
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        searchBar.searchTextField.becomeFirstResponder()
    }

    // MARK: - Actions
    
    // Dismisses the search and returns to the game screen.
    @IBAction func onCancelButtonPressed(_ sender: Any) {
        searchBar.endEditing(true)
        dismiss(animated: true)
    }
    
    // MARK: - UITableViewDataSource
    
    // Shows filtered results if searching, otherwise shows all songs.
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return isFiltering() ? searchedSongResults.count : songs.count
    }
    
    // Configures a cell with song title, artist, and artwork.
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: songCellID, for: indexPath)
        let song = isFiltering() ? searchedSongResults[indexPath.row] : songs[indexPath.row]
        var content = cell.defaultContentConfiguration()
        content.text = "\(song.name)"
        content.secondaryText = "Song • \(song.artist)"
        if let data = song.albumArtData {
            content.image = UIImage(data: data)
        } else {
            content.image = UIImage(systemName: "music.note")            
        }
        
        content.imageProperties.cornerRadius = 10
        content.imageProperties.maximumSize = CGSize(width: 75, height: 575)
        content.imageProperties.reservedLayoutSize = CGSize(width: 75, height: 75)
        cell.contentConfiguration = content
        
        return cell
    }
    
    // MARK: - UITableViewDelegate
    
    // Selects a song and dismisses back to the game screen.
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        songTableView.deselectRow(at: indexPath, animated: true)
        selectedSongCanidate = isFiltering() ? searchedSongResults[indexPath.row] : songs[indexPath.row]
        dismiss(animated: true)
    }
    
    // MARK: - UISearchBarDelegate
    
    // Dismisses the keyboard when the user commits the search.
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
    
    // Helper function to match song with query
    private func matchesQuery(_ song: Song, query: String) -> Bool {
        let q = query.lowercased()
        return song.name.lowercased().contains(q) || song.artist.lowercased().contains(q)
    }
    
    // Updates results as the user types, matching by song or artist.
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        Task {
            if searchText.isEmpty {
                resultsHeaderLabel.text = "Songs"
                filteredSongs = songs
                searchedSongResults = songs
            } else {
                resultsHeaderLabel.text = "Results for '\(searchText)'"
                searchedSongResults = await songService.searchForSongs(searchTerm: searchText)
                await songService.updateAlbumArtData(songs: searchedSongResults)
                filteredSongs = songs.filter { matchesQuery($0, query: searchText) }
            }

            songTableView.reloadData()
        }
    }
    
    // Returns true when a query is present and filtering should apply.
    func isFiltering() -> Bool {
        return searchBar.text?.isEmpty == false
    }
    
    // Dismisses the keyboard when tapping outside the search field.
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        searchBar.endEditing(true)
    }
}

