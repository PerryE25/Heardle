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

var selectedSearch: Song?

// A search screen of any song in my song list
class SearchViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate {
    
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var resultsForLabel: UILabel!
    @IBOutlet weak var songTable: UITableView!
    
    var filteredSongs: [Song] = []
    let songCellID = "SongCell"
    
    // Make Screen dark mode
    override func viewDidLoad() {
        super.viewDidLoad()

        songTable.delegate = self
        songTable.dataSource = self
        searchBar.delegate = self
        self.view.overrideUserInterfaceStyle = .dark
    }
    
    // User starts searching immediately because they
    // pressed game screen's search bar prior
    override func viewDidAppear(_ animated: Bool) {
        searchBar.searchTextField.becomeFirstResponder()
    }

    // Go back to game screen if cancel is pressed
    @IBAction func onCancelButtonPressed(_ sender: Any) {
        searchBar.endEditing(true)
        dismiss(animated: true)
    }
    
    // Give songs or filteredSongs as the total rows to display
    // based on if we're currently filtering
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return isFiltering() ? filteredSongs.count : songs.count
    }
    
    // Display a song by name/artist/albumCover
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: songCellID, for: indexPath)
        let song = isFiltering() ? filteredSongs[indexPath.row] : songs[indexPath.row]
        var content = cell.defaultContentConfiguration()
        content.text = "\(song.name)"
        content.secondaryText = "Song • \(song.artist)"
        do {
            let data = try Data(contentsOf: song.albumArt)
            content.image = UIImage(data: data)
            content.imageProperties.cornerRadius = 10
            content.imageProperties.maximumSize = CGSize(width: 75, height: 575)
            content.imageProperties.reservedLayoutSize = CGSize(width: 75, height: 75)
        } catch { print(error) }
        
        cell.contentConfiguration = content
        
        return cell
    }
    
    // When press a song cell, it's been selected and go to main game screen
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        songTable.deselectRow(at: indexPath, animated: true)
        selectedSearch = isFiltering() ? filteredSongs[indexPath.row] : songs[indexPath.row]
        dismiss(animated: true)
    }
    
    // Dismiss keyboard whenever search button is pressed
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
        // later will have customize search when textfield !isEmpty
    }
    
    // Update search results whenever new letters (dis)appear
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchText.isEmpty {
            resultsForLabel.text = "Songs"
            filteredSongs = songs
        } else {
            resultsForLabel.text = "Results for '\(searchText)'"
            filteredSongs = songs.filter { song in
                song.name.lowercased().contains(searchText.lowercased())
                || song.artist.lowercased().contains(searchText.lowercased())
            }
        }
        songTable.reloadData()
    }
    
    // Return true if search has text for us to filter
    func isFiltering() -> Bool {
        return searchBar.text?.isEmpty == false
    }
    
    // Dismiss keyboard when you touch outside of keyboard
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        searchBar.endEditing(true)
    }
}
