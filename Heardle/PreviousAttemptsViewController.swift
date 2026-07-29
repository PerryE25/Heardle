//
//  PreviousAttemptsViewController.swift
//  Heardle
//
//  Created by Ehimuh, Perry on 6/29/26.
//  Project: Heardle
//  Team Number: 3
//  Team Members: Jeremiah Franklin, Victor Sanchez, Haroon Memon, Perry Ehimuh
//  Course: CS371L
//

import UIKit

// A class to help user see all previous wrong song guesses
class PreviousAttemptsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var exitButton: UIButton!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var prevGuessesTitle: UILabel!
    
    // This will hold only the actual failed guesses, no nils.
    // Data passed from GameViewController
    var validGuesses: [Song] = []
    
    let cellID = "GuessCell"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // validGuesses is already set by GameViewController before presenting
        // No need to access global variables
        tableView.delegate = self
        tableView.dataSource = self
        self.view.overrideUserInterfaceStyle = .dark
        tableView.backgroundColor = .black
        tableView.rowHeight = 85
        prevGuessesTitle.font = UIFont.systemFont(ofSize: 20, weight: .bold)
    }
    
    // Let there be only valid guesses as total rows
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return validGuesses.count
    }
    
    // Return the cell with song info
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellID, for: indexPath)
        let song = validGuesses[indexPath.row]
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
        cell.backgroundColor = .black
        return cell
    }
    
    // if the x button is pressed then return to the previous screen
    @IBAction func exitPressed(_ sender: Any) {
        self.dismiss(animated: true)
    }
}
