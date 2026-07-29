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

// Displays the results screen after a solo game has finished.
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
    
    // Data passed from GameViewController
    var didWin: Bool = false
    var totalAttempts: Int = 0
    var currentSong: Song? = nil
    var clipDurations: [Int] = [1, 2, 4, 7, 11, 16]  // Default song times
    
    var audioPlayer: AVPlayer?
    var progressBlocks: [UIView] = []
    var totalTries: Int { clipDurations.count }
    
    // Sets up the results screen when the view is first loaded.
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    // Updates the interface with the completed game's results before the view appears.
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        guard let currentSong = currentSong else {
            print("Error: No song data provided")
            return
        }
        
        totalAttempts += 1  // Off by one error fix
        startButtonAnimation()
        setupProgressBlocks()
        
        if let artworkData = currentSong.albumArtData {
            songLargeImage.image = UIImage(data: artworkData)
            songSmallImage.image = UIImage(data: artworkData)
        } else if let artworkURL = currentSong.albumArt,
                  let data = try? Data(contentsOf: artworkURL) {
            songLargeImage.image = UIImage(data: data)
            songSmallImage.image = UIImage(data: data)
        }
        
        if let url = currentSong.audioURL {
            let playerItem = AVPlayerItem(url: url)
            audioPlayer = AVPlayer(playerItem: playerItem)
        }
        
        songNameLabel.text = currentSong.name
        songAuthorLabel.text = currentSong.artist
        
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
        
        if let image = songLargeImage.image {
            let blurredBackground = createAmbientBackground(image: image)
            blurredSongBackground.image = blurredBackground
        }
        
        if didWin {
            resultLabel.text = "Correct"
            resultIcon.image = UIImage(systemName: "checkmark.circle")
            resultLabel.textColor = UIColor.spotifyGreen
            resultIcon.tintColor = UIColor.spotifyGreen
            solvedAmountLabel.text = "Solved in \(totalAttempts)/\(totalTries)"
            
            // Show the time needed for the attempt they solved it on
            if totalAttempts > 0 && totalAttempts <= clipDurations.count {
                solvedSecondsLabel.text = "NEEDED \(clipDurations[totalAttempts - 1]) SEC"
            }
        } else {
            resultLabel.text = "Wrong"
            resultIcon.image = UIImage(systemName: "x.circle")
            resultLabel.textColor = .systemRed
            resultIcon.tintColor = .systemRed
            solvedAmountLabel.text = "Could not solve in \(totalTries) attempts"
            solvedSecondsLabel.text = ""
        }
        playButtonButtonPressed(self)
    }
    
    // Stops audio playback and releases the audio player before the view disappears.
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // Stop the audio when leaving this screen
        audioPlayer?.pause()
        audioPlayer = nil
    }
    
    // Cleans up audio resources when the view controller is deallocated.
    deinit {
        // Additional cleanup when the view controller is deallocated
        audioPlayer?.pause()
        audioPlayer = nil
        print("[RESULTS] SoloGameResultsViewController deallocated")
    }
    
    // Stops the Continue button animation when the button is pressed.
    @IBAction func continueButtonTouchDown(_ sender: Any) {
        stopButtonAnimation()
    }
    
    // Restarts the Continue button animation when the button is released.
    @IBAction func continueButtonTouchUp(_ sender: Any) {
        startButtonAnimation()
    }
    
    // Plays or pauses the song preview when the Play button is tapped.
    @IBAction func playButtonButtonPressed(_ sender: Any) {
        UIView.performWithoutAnimation {
            playButton.isSelected.toggle()
        }
        if playButton.isSelected {
            audioPlayer?.play()
        }
        else {
            audioPlayer?.pause()
        }
    }
    
    // Starts the glowing animation for the Continue button.
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
    
    // Creates the text that will be shared through the system share sheet.
    func makeShareText() -> String {
        let filled = didWin ? totalAttempts : totalTries
        let blocks = (1...totalTries).map { num -> String in
            guard num <= filled else { return "⬜" }
            return didWin ? "🟩" : "🟥"
        }.joined()

        if didWin {
            var tagline = "Beat that 🔥"
            if totalAttempts > 0, totalAttempts <= clipDurations.count {
                tagline = "Needed only \(clipDurations[totalAttempts - 1]) sec 🔥"
            }
            return """
            🎵 Heardle — \(totalAttempts)/\(totalTries)

            \(blocks)
            \(tagline)
            """
        } else {
            return """
            🎵 Heardle — X/\(totalTries)

            \(blocks)
            This one destroyed me. Your turn.
            """
        }
    }
    
    // Opens the system share sheet to share the game results.
    @IBAction func shareButtonPressed(_ sender: Any) {
        let vc = UIActivityViewController(activityItems: [makeShareText()],
                                          applicationActivities: nil)
        vc.popoverPresentationController?.sourceView = sender as? UIView
        present(vc, animated: true)
    }
    
    // Stops the glowing animation on the Continue button.
    func stopButtonAnimation() {
        continueButton.layer.removeAllAnimations()
        UIView.animate(withDuration: 0.2) {
            self.continueButton.transform = .identity
        }
    }
    
    // Configures the progress blocks showing the player's attempts.
    func setupProgressBlocks() {
        for num in 1...totalTries {
            let block = UIView()
            if num <= totalAttempts {
                if didWin {
                    block.backgroundColor = UIColor.spotifyGreen
                } else {
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
    
    // Creates a blurred version of the album artwork for the background.
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
