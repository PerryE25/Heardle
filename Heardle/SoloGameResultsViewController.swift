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
import AVFoundation

class SoloGameResultsViewController: UIViewController {
    
    @IBOutlet weak var progressStack: UIStackView!
    @IBOutlet weak var continueButton: UIButton!
    @IBOutlet weak var solvedAmountLabel: UILabel!
    @IBOutlet weak var solvedSecondsLabel: UILabel!
    @IBOutlet weak var songNameLabel: UILabel!
    @IBOutlet weak var songAuthorLabel: UILabel!
    @IBOutlet weak var blurredSongBackground: UIImageView!
    @IBOutlet weak var songLargeImage: UIImageView!
    @IBOutlet weak var songSmallImage: UIImageView!
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var resultLabel: UILabel!
    @IBOutlet weak var resultIcon: UIImageView!
    
    var audioPlayer: AVAudioPlayer?
    var progressBlocks: [UIView] = []
    let totalTries = songTimes.count
    var currentSong: Song? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        startButtonAnimation()
        setupProgressBlocks()

        currentSong = songs[0]
        
        songLargeImage.image = UIImage(data: currentSong!.albumArtData!)
        songSmallImage.image = UIImage(data: currentSong!.albumArtData!)
        
        if let url = currentSong?.audioURL {
            audioPlayer = try? AVAudioPlayer(contentsOf: url)
            audioPlayer?.prepareToPlay()
        }
        songNameLabel.text = currentSong?.name
        songAuthorLabel.text = currentSong?.artist
        if let url = currentSong?.albumArt, let data = try? Data(contentsOf: url) {
            songSmallImage.image = UIImage(data: data)
        }
        playButton.configurationUpdateHandler = { button in
            button.configuration?.background.backgroundColor = .clear
            if button.isSelected {
                UIView.performWithoutAnimation {
                    button.configuration?.image = UIImage(systemName: "pause")
                }
                
                
            }
            else {
                UIView.performWithoutAnimation {
                    button.configuration?.image = UIImage(systemName: "play")
                }
            }
        }
        
        let blurredBackground = createAmbientBackground(image: songLargeImage.image!)
        
        blurredSongBackground.image = blurredBackground
        
        if didWin {
            resultLabel.text = "Correct"
            resultIcon.image = UIImage(systemName: "checkmark.circle")
            resultLabel.textColor = UIColor.spotifyGreen
            resultIcon.tintColor = UIColor.spotifyGreen
            solvedAmountLabel.text = "Solved in \(globalTotalAttempts)/\(totalTries)"
            solvedSecondsLabel.text = "NEEDED \(songTimes[globalTotalAttempts - 1]) SEC"
        } else {
            resultLabel.text = "Wrong"
            resultIcon.image = UIImage(systemName: "x.circle")
            resultLabel.textColor = .systemRed
            resultIcon.tintColor = .systemRed
            solvedAmountLabel.text = "Could not solve in \(totalTries) attempts"
            solvedSecondsLabel.text = ""
        }
    }
    
    @IBAction func continueButtonTouchDown(_ sender: Any) {
        stopButtonAnimation()
    }
    
    @IBAction func continueButtonTouchUp(_ sender: Any) {
        startButtonAnimation()
    }
    
    @IBAction func playButtonButtonPressed(_ sender: Any) {
        UIView.performWithoutAnimation {
            playButton.isSelected.toggle()
        }
        if playButton.isSelected {
            audioPlayer?.play()
            print(currentSong?.audioURL.absoluteString ?? "test")
        }
        else{
            audioPlayer?.stop()
        }
    }
    func startButtonAnimation() {
        UIView.animate(
            withDuration: 1.5,
            delay: 0,
            options: [.repeat, .autoreverse, .allowUserInteraction]) {
                self.continueButton.transform = CGAffineTransform(scaleX: 1.1, y: 1.1)
            }
        if didWin {
            continueButton.configuration?.background.backgroundColor = UIColor.spotifyGreen
            continueButton.layer.shadowColor = UIColor.spotifyGreen.cgColor
        }
        else {
            continueButton.configuration?.background.backgroundColor = .systemRed
            continueButton.layer.shadowColor = UIColor.systemRed.cgColor
        }
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
            if num <= globalTotalAttempts {
                if didWin {
                    block.backgroundColor = UIColor.spotifyGreen
                } else{
                    block.backgroundColor = .systemRed
                }
                
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
    
    func createAmbientBackground(image: UIImage) -> UIImage {
        let ciImage = CIImage(image: image)!
        
        let referenceSize = min(ciImage.extent.width, ciImage.extent.height)
        let blurRadius = referenceSize * 0.15
        let padding = referenceSize * 0.25
        
        let blurFilter = CIFilter(name: "CIGaussianBlur")
        blurFilter?.setValue(ciImage, forKey: kCIInputImageKey)
        blurFilter?.setValue(blurRadius, forKey: kCIInputRadiusKey)
        
        let outputImage = blurFilter?.outputImage
        
        let paddedExtent = ciImage.extent.insetBy(dx: -padding, dy: -padding)
        
        let context = CIContext()
        let cgImage = context.createCGImage(outputImage!, from: paddedExtent)
        
        return UIImage(cgImage: cgImage!)
    }
}
