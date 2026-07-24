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

class PreviousAttemptsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    @IBOutlet weak var exitButton: UIButton!
    
    @IBOutlet weak var tableView: UITableView!
    
    @IBOutlet weak var prevGuessesTitle: UILabel!
    // This will hold only the actual failed guesses, no nils.
    var validGuesses: [Song] = []
    
    let cellID = "GuessCell"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        validGuesses = prevGuesses.compactMap { $0 } // Removes the nils from the guesses array
        tableView.delegate = self
        tableView.dataSource = self
        self.view.overrideUserInterfaceStyle = .dark
        prevGuessesTitle.font = UIFont.systemFont(ofSize: 20, weight: .bold)
    }
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return validGuesses.count
    }
    
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
        return cell
    }
    
    
    @IBAction func exitPressed(_ sender: Any) {
        self.dismiss(animated: true)
    }
}
