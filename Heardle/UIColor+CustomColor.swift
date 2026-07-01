//
//  UIColor+CustomColor.swift
//  Heardle
//
//  Created by Ehimuh, Perry on 6/30/26.
//  Project: Heardle
//  Team Number: 3
//  Team Members: Jeremiah Franklin, Victor Sanchez, Haroon Memon, Perry Ehimuh
//  Course: CS371L
//

import UIKit

// An extension that allows for custom Spotify Green
extension UIColor {
    
    // Spotify's green is #1DB954
    class var spotifyGreen: UIColor {
        let hexSpotifygreen = 0x1DB954
        return UIColor.rgb(fromHex: hexSpotifygreen)
    }
    
    // Hex to RGB is #RRGGBB given the hex value,
    // return the rgb version of the color
    class func rgb(fromHex: Int) -> UIColor {
        let red = CGFloat((fromHex & 0xFF0000) >> 16) / 255.0
        let green = CGFloat((fromHex & 0x00FF00) >> 8) / 255.0
        let blue = CGFloat(fromHex & 0x0000FF) / 255.0
        let alpha: CGFloat = 1.0
        return UIColor(red: red, green: green, blue: blue, alpha: alpha)
    }
}
