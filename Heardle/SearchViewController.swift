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

class SearchViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate {
    
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var resultsForLabel: UILabel!
    @IBOutlet weak var songTable: UITableView!
    
    let songCellID = "SongCell"
    
    override func viewDidLoad() {
        super.viewDidLoad()

        songTable.delegate = self
        songTable.dataSource = self
        searchBar.delegate = self
        self.view.overrideUserInterfaceStyle = .dark
    }
    
    override func viewDidAppear(_ animated: Bool) {
        searchBar.searchTextField.becomeFirstResponder()
    }

    @IBAction func onCancelButtonPressed(_ sender: Any) {
        searchBar.endEditing(true)
        dismiss(animated: true)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return songs.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: songCellID, for: indexPath)
        
        let song = songs[indexPath.row]
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
    
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        songTable.deselectRow(at: indexPath, animated: true)
        selectedSearch = songs[indexPath.row]
        dismiss(animated: true)
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
        // later will have customize search when textfield !isEmpty
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchText == "" {
            resultsForLabel.text = "Songs"
        } else {
            resultsForLabel.text = "Results for '\(searchText)'"
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        searchBar.endEditing(true)
    }
}
