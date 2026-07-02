//
//  GameViewController.swift
//  Heardle
//
//  Created by Ehimuh, Perry on 6/29/26.
//  Project: Heardle
//  Team Number: 3
//  Team Members: Jeremiah Franklin, Victor Sanchez, Haroon Memon, Perry Ehimuh
//  Course: CS371L
//

import UIKit

class GameViewController: UIViewController, UISearchBarDelegate {

    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var rulesButton: UIButton!
    @IBOutlet weak var prevAttemptsButton: UIButton!
    @IBOutlet weak var submitButton: UIButton!
    @IBOutlet weak var mysteryAlbum: UIImageView!
    @IBOutlet weak var progressBar: UIProgressView!
    @IBOutlet weak var currentTime: UILabel!
    @IBOutlet weak var maxTime: UILabel!
    @IBOutlet weak var unlockSongButton: UIButton!
    @IBOutlet weak var skipSongButton: UIButton!
    @IBOutlet weak var selectedSong: UIView!
    @IBOutlet weak var songSearchBar: UISearchBar!
    
    // Add gradient with Sptofy's green
    override func viewDidLoad() {
        super.viewDidLoad()

        // Add gradient like on spotify's music player
        let gradient = CAGradientLayer()
        gradient.frame = view.bounds
        gradient.colors = [UIColor.spotifyGreen.cgColor, UIColor.black.cgColor]
        gradient.locations = [0.0, 0.65]
        view.layer.insertSublayer(gradient, at: 0)
        
        CustomButton.playButtonConfig(systemName: "play.fill", playButton)
        CustomButton.noGuessSubmitConfig(submitButton)
        CustomButton.rulesButtonConfig(rulesButton)
        CustomButton.configPrevAttemptButton(prevAttemptsButton)
        selectedSong.layer.cornerRadius = 10
        selectedSong.layer.sublayers?[0].cornerRadius = 10
        songSearchBar.delegate = self
    }
    
    // Change play to pause and vice versa
    @IBAction func playButtonPressed(_ sender: Any) {
        if playButton.imageView?.image == UIImage(systemName: "play.fill") {
            CustomButton.playButtonConfig(systemName: "pause.fill", playButton)
        } else {
            CustomButton.playButtonConfig(systemName: "play.fill", playButton)
        }
    }
    
    // When searched, remove keyboard, like textfield return pressed
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
    
    // Touch outside of keyboard and keyboard is removed
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        view.endEditing(true)
    }
}
