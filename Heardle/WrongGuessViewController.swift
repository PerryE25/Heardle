//
//  WrongGuessViewController.swift
//  Heardle
//
//  Created by Ehimuh, Perry on 6/29/26.
//  Project: Heardle
//  Team Number: 3
//  Team Members: Jeremiah Franklin, Victor Sanchez, Haroon Memon, Perry Ehimuh
//  Course: CS371L
//

import UIKit

class WrongGuessViewController: UIViewController {
    @IBOutlet weak var xMark1: UIImageView!
    @IBOutlet weak var xMark2: UIImageView!
    @IBOutlet weak var xMark3: UIImageView!
    @IBOutlet weak var xMark4: UIImageView!
    @IBOutlet weak var xMark5: UIImageView!
    @IBOutlet weak var xMark6: UIImageView!
    @IBOutlet weak var topText: UILabel!
    @IBOutlet weak var miniView: UIView!
    
    // Keeps track of all of the ImageViews (Could not get the Collection version working)
    var xMarks: [UIImageView] = []
    
    // Data passed from GameViewController
    var currentAttempts: Int!
    var wrongGuessCount: Int = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        miniView.layer.cornerRadius = 30
        topText.font = UIFont.boldSystemFont(ofSize: 40.0)
        xMarks = [xMark1, xMark2, xMark3, xMark4, xMark5, xMark6]
        // Set wrongGuessCount from passed data
        wrongGuessCount  = currentAttempts
        
        // Makes it so that all previous guesses are gray and the current is also gray in the pre build
        if wrongGuessCount > 0 {
            wrongGuessCount -= 1
        }
        updateXMarks(animated: true)
    }
    
    // We need to create the board of X and then add the animation so we use viewDidAppear
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        wrongGuessCount = currentAttempts
        updateXMarks(animated: true)
    }
    
    @IBAction func returnToGame(_ sender: Any) {
        self.dismiss(animated: true)
    }
    // Updates the onscreen x marks 
    func updateXMarks(animated: Bool) {
        for (index, imageView) in xMarks.enumerated() {
            let isGuessed = index < wrongGuessCount
            let targetColor: UIColor = isGuessed ? .systemRed : .darkGray
            
            // Always ensure the color is correct immediately
            imageView.tintColor = targetColor
            
            // Skip if this icon is already correctly styled and not the new one
            if !isGuessed || (imageView.alpha == 1.0 && imageView.transform == .identity && index != wrongGuessCount - 1) {
                continue
            }
            
            if animated && index == wrongGuessCount - 1 {
                // Starts tiny and invisible
                imageView.transform = CGAffineTransform(scaleX: 0.1, y: 0.1)
                imageView.alpha = 0.0
                
                // Sets up the duration of the animation
                UIView.animateKeyframes(withDuration: 0.75, delay: 0, options: .calculationModeCubic, animations: {
                    // Fade in and expand to be oversized
                    UIView.addKeyframe(withRelativeStartTime: 0.0, relativeDuration: 0.2) {
                        imageView.alpha = 1.0
                        imageView.transform = CGAffineTransform(scaleX: 1.4, y: 1.4)
                    }
                    // Contracting
                    UIView.addKeyframe(withRelativeStartTime: 0.2, relativeDuration: 0.2) {
                        imageView.transform = CGAffineTransform(scaleX: 0.7, y: 0.7)
                    }
                    // Expanding
                    UIView.addKeyframe(withRelativeStartTime: 0.4, relativeDuration: 0.2) {
                        imageView.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)
                    }
                    // Contract again
                    UIView.addKeyframe(withRelativeStartTime: 0.6, relativeDuration: 0.2) {
                        imageView.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
                    }
                    // Get to normal size
                    UIView.addKeyframe(withRelativeStartTime: 0.8, relativeDuration: 0.2) {
                        imageView.transform = .identity
                    }
                }, completion: nil)
            } else if animated {
                // Animation for EXISTING guesses
                imageView.transform = CGAffineTransform(scaleX: 0.3, y: 0.3)
                imageView.alpha = 0.5
                
                UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.5, initialSpringVelocity: 0.8, options: .curveEaseOut, animations: {
                    imageView.transform = .identity
                    imageView.alpha = 1.0
                }, completion: nil)
            } else {
                // No animation
                imageView.transform = .identity
                imageView.alpha = 1.0
            }
        }
    }
    
}

