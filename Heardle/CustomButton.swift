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

// A customizable button that supports reusable styles throughout the app.
@IBDesignable
class CustomButton: UIButton {

    // Adjusts the corner radius of the button from Interface Builder.
    @IBInspectable var cornerRadius: CGFloat = 0 {
        didSet {
            layer.cornerRadius = cornerRadius
        }
    }
    
    // Sets the border color of the button from Interface Builder.
    @IBInspectable var borderColor: CGColor = UIColor.clear.cgColor {
        didSet {
            layer.borderColor = borderColor
        }
    }
    
    private static let submitButtonFont =
        UIFont(name: "Arial Rounded MT Bold", size: 20.0)
    
    // Configures the Rules button with its icon and appearance.
    static func rulesButtonConfig(_ rulesButton: CustomButton) {
        var configuration = UIButton.Configuration.clearGlass()
        configuration.image = UIImage(systemName: "questionmark.circle.dashed")
        configuration.baseForegroundColor = .white
        configuration.baseBackgroundColor = .clear
        rulesButton.configuration = configuration
    }
    
    // Applies a common configuration used by all submit button styles.
    private static func configureSubmitButton(
        _ button: CustomButton,
        title: String,
        color: UIColor,
        alpha: CGFloat,
        enabled: Bool
    ) {
        var configuration = UIButton.Configuration.filled()
        configuration.title = title
        configuration.baseBackgroundColor = color
        configuration.cornerStyle = .capsule
        button.configuration = configuration
        button.titleLabel?.font = submitButtonFont
        button.alpha = alpha
        button.isUserInteractionEnabled = enabled
        button.cornerRadius = 50
    }
    
    // Configures the submit button to indicate the song has already been guessed.
    static func alreadyGuessSubmitConfig(_ submitButton: CustomButton) {
        configureSubmitButton(submitButton, title: "ALREADY GUESSED", color: .systemRed, alpha: 1.0, enabled: false)
    }
    
    // Configures the submit button for a valid guess.
    static func validGuessSubmitConfig(_ submitButton: CustomButton) {
        configureSubmitButton(submitButton, title: "SUBMIT", color: .spotifyGreen, alpha: 1.0, enabled: true)
    }
    
    // Configures the default disabled submit button when no guess has been entered.
    static func noGuessSubmitConfig(_ submitButton: CustomButton) {
        configureSubmitButton(submitButton, title: "SUBMIT", color: .systemGray, alpha: 0.2, enabled: false)
    }
    
    // Configures the Previous Attempts button.
    static func prevAttemptButtonConfig(_ prevAttemptsButton: CustomButton) {
        var configuration = UIButton.Configuration.clearGlass()
        configuration.baseForegroundColor = .white
        configuration.title = "Attempt 0 / 6 "
        configuration.image = UIImage(systemName: "info.circle")
        configuration.imagePlacement = .trailing
        prevAttemptsButton.configuration = configuration
    }
    
    // Configures the play button using the specified SF Symbol.
    static func playButtonConfig(systemName: String, _ playButton: CustomButton) {
        var configuration = UIButton.Configuration.filled()
        configuration.title = ""
        configuration.baseBackgroundColor = .white
        configuration.image = UIImage(systemName: systemName)
        configuration.baseForegroundColor = .black
        playButton.configuration = configuration
        playButton.cornerRadius = playButton.bounds.height / 2
    }
    
    // Updates the button's corner radius whenever its layout changes.
    override func layoutSubviews() {
        super.layoutSubviews()
        layer.cornerRadius = cornerRadius
    }

}
