//
//  CreateAccountViewController.swift
//  Heardle
//
//  Created by Ehimuh, Perry on 6/29/26.
//  Project: Heardle
//  Team Number: 3
//  Team Members: Jeremiah Franklin, Victor Sanchez, Haroon Memon, Perry Ehimuh
//  Course: CS371L
//

import UIKit

class CreateAccountViewController: UIViewController {

    @IBOutlet weak var spotifyButton: UIButton!
    @IBOutlet weak var emailField: UITextField!
    
    @IBOutlet weak var googleButton: UIButton!
    
    @IBOutlet weak var appleButton: UIButton!
    
    @IBAction func continueButtonPressed(_ sender: Any) {
        let email = emailField.text ?? ""
        if !(email == "") {
            performSegue(withIdentifier: "accountToPasswordSegue", sender: nil)
        }
    }
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        emailField.layer.borderColor = UIColor.darkGray.cgColor
        emailField.layer.borderWidth = 1.0
        emailField.layer.cornerRadius = 6
        
        if let icon = UIImage(named: "spotify-xxl"){
            let size = CGSize(width: 30, height: 30)
            let resized = UIGraphicsImageRenderer(size: size).image { _ in
                icon.draw(in: CGRect(origin: .zero, size: size))
                
            }
            spotifyButton.setImage(resized.withRenderingMode(.alwaysOriginal), for: .normal)
            spotifyButton.configuration?.imagePadding = 10
        }
        
        if let icon = UIImage(named: "Google_\"G\"_logo.svg"){
            let size = CGSize(width: 30, height: 30)
            let resized = UIGraphicsImageRenderer(size: size).image { _ in
                icon.draw(in: CGRect(origin: .zero, size: size))
                
            }
            googleButton.setImage(resized.withRenderingMode(.alwaysOriginal), for: .normal)
            googleButton.configuration?.imagePadding = 10
            googleButton.layer.borderColor = UIColor.darkGray.cgColor
            googleButton.layer.borderWidth = 1.0
            googleButton.layer.cornerRadius = 6
        }
        if let icon = UIImage(named: "Apple_logo_white.svg"){
            let size = CGSize(width: 30, height: 30)
            let resized = UIGraphicsImageRenderer(size: size).image { _ in
                icon.draw(in: CGRect(origin: .zero, size: size))
                
            }
            appleButton.setImage(resized.withRenderingMode(.alwaysOriginal), for: .normal)
            appleButton.configuration?.imagePadding = 10
            appleButton.layer.borderColor = UIColor.darkGray.cgColor
            appleButton.layer.borderWidth = 1.0
            appleButton.layer.cornerRadius = 6
        }
        
        // Do any additional setup after loading the view.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
