//
//  SoloGameResultsViewController.swift
//  Heardle
//
//  Created by Ehimuh, Perry on 6/29/26.
//  Project: Heardle
//  Team Number: 3
//  Team Members: Jeremiah Franklin, Victor Sanchez, Haroon Memon, Perry Ehimuh
//  Course: CS371L
//

import UIKit

class SoloGameResultsViewController: UIViewController {

    @IBOutlet weak var progressStack: UIStackView!
    @IBOutlet weak var continueButton: UIButton!
    @IBOutlet weak var solvedAmountLabel: UILabel!
    @IBOutlet weak var solvedSecondsLabel: UILabel!
    
    var progressBlocks: [UIView] = []
    let currentTries = 2
    let totalTries = 6
    var amountOfSecondsInTry = 1
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        startButtonAnimation()
        setupProgressBlocks()
        solvedAmountLabel.text = "Solved in \(currentTries)/\(totalTries)"
        solvedSecondsLabel.text = "NEEDED \(currentTries * amountOfSecondsInTry) SEC"
    }
    
    @IBAction func continueButtonTouchDown(_ sender: Any) {
        stopButtonAnimation()
    }
    
    @IBAction func continueButtonTouchUp(_ sender: Any) {
        startButtonAnimation()
    }
    
    func startButtonAnimation() {
        UIView.animate(
            withDuration: 1.5,
            delay: 0,
            options: [.repeat, .autoreverse, .allowUserInteraction]) {
                self.continueButton.transform = CGAffineTransform(scaleX: 1.1, y: 1.1)
            }
        
        continueButton.layer.shadowColor = UIColor.spotifyGreen.cgColor
        continueButton.layer.shadowOffset = .zero
        
        let glowAnimation = CABasicAnimation(keyPath: "shadowOpacity")
        glowAnimation.fromValue = 0
        glowAnimation.toValue = 0.8
        glowAnimation.duration = 1.5
        glowAnimation.autoreverses = true
        glowAnimation.repeatCount = .infinity
        continueButton.layer.add(glowAnimation, forKey: "glowOpacity")
        
        let radiusAnimation = CABasicAnimation(keyPath: "shadowRadius")
        radiusAnimation.fromValue = 0
        radiusAnimation.toValue = 10
        radiusAnimation.duration = 1.5
        radiusAnimation.autoreverses = true
        radiusAnimation.repeatCount = .infinity
        continueButton.layer.add(radiusAnimation, forKey: "glowRadius")
    }
    
    func stopButtonAnimation() {
        continueButton.layer.removeAllAnimations()
        UIView.animate(withDuration: 0.2) {
            self.continueButton.transform = .identity
        }
    }
    
    func setupProgressBlocks() {
        for num in 1...totalTries {
            let block = UIView()
            if num <= currentTries {
                block.backgroundColor = UIColor.spotifyGreen
            }
            else {
                block.backgroundColor = UIColor.spotifyLightGrey
            }
            block.layer.cornerRadius = 3
            block.clipsToBounds = true
            block.widthAnchor.constraint(equalToConstant: progressStack.frame.height).isActive = true
            block.heightAnchor.constraint(equalToConstant: progressStack.frame.height).isActive = true
            progressStack.addArrangedSubview(block)
            progressBlocks.append(block)
        }
    }
}
