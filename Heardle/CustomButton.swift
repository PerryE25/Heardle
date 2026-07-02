//
//  CustomButton.swift
//  Heardle
//
//  Created by Ehimuh, Perry on 7/1/26.
//  Project: Heardle
//  Team Number: 3
//  Team Members: Jeremiah Franklin, Victor Sanchez, Haroon Memon, Perry Ehimuh
//  Course: CS371L
//

import UIKit

// A custom button class to allow for circular buttons
@IBDesignable
class CustomButton: UIButton {

    @IBInspectable var cornerRadius: CGFloat = 0 {
        didSet {
            layer.cornerRadius = cornerRadius
        }
    }
    
    @IBInspectable var borderColor: CGColor = UIColor.clear.cgColor {
        didSet {
            layer.borderColor = borderColor
        }
    }
    
    static func rulesButtonConfig(_ rulesButton: UIButton) {
        let rulesButt = rulesButton as! CustomButton
        var configuration = UIButton.Configuration.clearGlass()
        configuration.image = UIImage(systemName: "questionmark.circle.dashed")
        configuration.baseForegroundColor = .white
        configuration.baseBackgroundColor = .clear
        rulesButt.configuration = configuration
    }
    
    // Make submit button red and warn player that
    // they already guessed this song
    static func alreadyGuessSubmitConfig(_ submitButton: UIButton) {
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
    
    // When guess is valid, make submit button clickable and green
    static func validGuessSubmitConfig(_ submitButton: UIButton) {
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
    
    // Default submit button of unclickable and hard to see
    static func noGuessSubmitConfig(_ submitButton: UIButton) {
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
    
    static func configPrevAttemptButton(_ prevAttemptsutton: UIButton) {
        let attemptsButton = prevAttemptsutton as! CustomButton
        var configuration = UIButton.Configuration.clearGlass()
        configuration.baseForegroundColor = .white
        configuration.title = "Attempt 0 / 6 "
        configuration.image = UIImage(systemName: "info.circle")
        configuration.imagePlacement = .trailing
        attemptsButton.configuration = configuration
    }
    
    // Make the play button config
    static func playButtonConfig(systemName: String, _ playButton: UIButton) {
        print("Setting button to \(systemName)")
        
        let button = playButton as! CustomButton
        var configuration = UIButton.Configuration.filled()
        configuration.title = ""
        configuration.baseBackgroundColor = .white
        configuration.image = UIImage(systemName: systemName)
        configuration.baseForegroundColor = .black
        button.configuration = configuration
        button.cornerRadius = button.bounds.height / 2
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        layer.cornerRadius = cornerRadius
    }

}
