//
//  CreatePasswordViewController.swift
//  Heardle
//
//  Created by Ehimuh, Perry on 6/29/26.
//  Project: Heardle
//  Team Number: 3
//  Team Members: Jeremiah Franklin, Victor Sanchez, Haroon Memon, Perry Ehimuh
//  Course: CS371L
//

import UIKit
import FirebaseAuth

class CreatePasswordViewController: UIViewController {

    @IBOutlet weak var passwordField: UITextField!
    @IBOutlet weak var nextButton: UIButton!
    
    var email : String?
    let eyeButton = UIButton(type: .system)

    override func viewDidLoad() {
        super.viewDidLoad()

        passwordField.isSecureTextEntry = true
        eyeButton.setImage(UIImage(systemName: "eye"), for: .normal)
        eyeButton.tintColor = .white
        eyeButton.sizeToFit()
        eyeButton.addAction(UIAction(handler: togglePasswordAction), for: .touchUpInside)
        passwordField.rightView = eyeButton
        passwordField.rightViewMode = .always

        nextButton.isEnabled = false

    }

    private func togglePasswordAction(_ action: UIAction) {
        passwordField.isSecureTextEntry.toggle()
        let symbol = passwordField.isSecureTextEntry ? "eye" : "eye.slash"
        eyeButton.setImage(UIImage(systemName: symbol), for: .normal)
    }

    private func checkNextEnabled() {
        let isValid = (passwordField.text?.count ?? 0) >= 8
        nextButton.isEnabled = isValid ? true : false
        nextButton.backgroundColor = isValid ? .spotifyGreen : .spotifyGrey
        nextButton.titleLabel?.textColor = isValid ? .white : .black


    }

    @IBAction func passwordFieldEditingChanged(_ sender: UITextField) {
        checkNextEnabled()
    }

    
    @IBAction func nextButtonPressed(_ sender: Any) {
        Auth.auth().createUser(withEmail: email!, password: passwordField.text!){
            result, error in
            if let error = error{
                print(error.localizedDescription)
            }
            return
        }
        
        
        performSegue(withIdentifier: "passwordToHomeSegue", sender: nil)
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
