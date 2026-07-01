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

class GameViewController: UIViewController {

    
    @IBOutlet weak var playButton: UIButton!
        
    // Add gradient with Sptofy's green
    override func viewDidLoad() {
        super.viewDidLoad()

        // Add gradient like on spotify's music player
        let gradient = CAGradientLayer()
        gradient.frame = view.bounds
        gradient.colors = [UIColor.spotifyGreen.cgColor, UIColor.black.cgColor]
        gradient.locations = [0.0, 0.65]
        view.layer.insertSublayer(gradient, at: 0)
        
        playButton.layer.cornerRadius = playButton.bounds.height / 2
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        let button = playButton as! CustomButton
        var configuration = UIButton.Configuration.filled()
        configuration.title = ""
        configuration.baseBackgroundColor = .white
        configuration.image = UIImage(systemName: "play.fill")
        configuration.baseForegroundColor = .black
        button.configuration = configuration
        button.cornerRadius = button.bounds.height / 2

        
    }
    
    // this is Perry's favorite screen :D
    

    
    @IBAction func playButtonPressed(_ sender: Any) {
        print("playButton should work!")
    }
    
}
