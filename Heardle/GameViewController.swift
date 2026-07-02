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
    @IBOutlet weak var rulesButton: UIButton!
    @IBOutlet weak var prevAttemptsButton: UIButton!
    @IBOutlet weak var submitButton: UIButton!
    
    // Add gradient with Sptofy's green
    override func viewDidLoad() {
        super.viewDidLoad()

        // Add gradient like on spotify's music player
        let gradient = CAGradientLayer()
        gradient.frame = view.bounds
        gradient.colors = [UIColor.spotifyGreen.cgColor, UIColor.black.cgColor]
        gradient.locations = [0.0, 0.65]
        view.layer.insertSublayer(gradient, at: 0)
        
//        playButton.layer.cornerRadius = playButton.bounds.height / 2
        
        
    }
    
    // configure playbutton to be a circle
    // configure rules & attempt buttons to be glass like
    // configure submit button to not be clicked if haven't
    // picked song initally and capusle shaped
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

        let rulesButt = rulesButton as! CustomButton
        configuration = UIButton.Configuration.clearGlass()
        configuration.image = UIImage(systemName: "questionmark.circle.dashed")
        configuration.baseForegroundColor = .white
        configuration.baseBackgroundColor = .clear
        rulesButt.configuration = configuration
        let attemptsButton = prevAttemptsButton as! CustomButton
        configuration = UIButton.Configuration.clearGlass()
        configuration.baseForegroundColor = .white
        configuration.title = "Attempt 0 / 6 "
        configuration.image = UIImage(systemName: "info.circle")
        configuration.imagePlacement = .trailing
        attemptsButton.configuration = configuration
        
        noGuessSubmitConfig()
    }
    
    // Default submit button of unclickable and hard to see
    private func noGuessSubmitConfig() {
        let submit = submitButton as! CustomButton
        var configuration = UIButton.Configuration.filled()
        configuration.title = "SUBMIT"
        configuration.baseBackgroundColor = .systemGray
        configuration.cornerStyle = .capsule
        submit.configuration = configuration
        submit.titleLabel?.font = UIFont(name: "Arial Rounded MT Bold", size: 20.0)
        submit.alpha = 0.20
        submit.isUserInteractionEnabled = false
        submit.cornerRadius = 50
    }
    
    // When guess is valid, make submit button clickable and green
    private func validGuessSubmitConfig() {
        let submit = submitButton as! CustomButton
        var configuration = UIButton.Configuration.filled()
        configuration.title = "SUBMIT"
        configuration.baseBackgroundColor = .spotifyGreen
        configuration.cornerStyle = .capsule
        submit.configuration = configuration
        submit.titleLabel?.font = UIFont(name: "Arial Rounded MT Bold", size: 20.0)
        submit.alpha = 1.0
        submit.isUserInteractionEnabled = true
        submit.cornerRadius = 50
    }
    
    // Make submit button red and warn player that
    // they already guessed this song
    private func alreadyGuessSubmitConfig() {
        let submit = submitButton as! CustomButton
        var configuration = UIButton.Configuration.filled()
        configuration.title = "ALREADY GUESSED"
        configuration.baseBackgroundColor = .systemRed
        configuration.cornerStyle = .capsule
        submit.configuration = configuration
        submit.titleLabel?.font = UIFont(name: "Arial Rounded MT Bold", size: 20.0)
        submit.alpha = 1.0
        submit.isUserInteractionEnabled = true
        submit.cornerRadius = 50
    }
    
    @IBAction func playButtonPressed(_ sender: Any) {
        print("playButton should work!")
    }
    
}
