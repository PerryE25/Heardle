//
//  User.swift
//  Heardle
//
//  Created by Ehimuh, Perry on 7/27/26.
//  Project: Heardle
//  Team Number: 3
//  Team Members: Jeremiah Franklin, Victor Sanchez, Haroon Memon, Perry Ehimuh
//  Course: CS371L
//

import Foundation

// A class to store user's name/pts/image
class User {
    
    var displayName: String
    var points: Int
    var displayImage: String?
    
    init(displayName: String, points: Int, displayImage: String? = nil) {
        self.displayName = displayName
        self.points = points
        self.displayImage = displayImage
    }
}
