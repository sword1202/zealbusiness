//
//  UIColor.swift
//  SlideMenuControllerSwift
//
//  Created by Yuji Hato on 11/5/15.
//  Copyright © 2015 Yuji Hato. All rights reserved.
//

import UIKit

extension UIColor {
    
    convenience init(hex: String) {
        self.init(hex: hex, alpha:1)
    }
    
    convenience init(hex: String, alpha: CGFloat) {
        var hexWithoutSymbol = hex
        if hexWithoutSymbol.hasPrefix("#") {
            hexWithoutSymbol = hex.substring(1)
        }
        
        let scanner = Scanner(string: hexWithoutSymbol)
        var hexInt:UInt32 = 0x0
        scanner.scanHexInt32(&hexInt)
        
        var r:UInt32!, g:UInt32!, b:UInt32!
        switch (hexWithoutSymbol.length) {
        case 3: // #RGB
            r = ((hexInt >> 4) & 0xf0 | (hexInt >> 8) & 0x0f)
            g = ((hexInt >> 0) & 0xf0 | (hexInt >> 4) & 0x0f)
            b = ((hexInt << 4) & 0xf0 | hexInt & 0x0f)
            break;
        case 6: // #RRGGBB
            r = (hexInt >> 16) & 0xff
            g = (hexInt >> 8) & 0xff
            b = hexInt & 0xff
            break;
        default:
            // TODO:ERROR
            break;
        }
        
        self.init(
            red: (CGFloat(r)/255),
            green: (CGFloat(g)/255),
            blue: (CGFloat(b)/255),
            alpha:alpha)
    }
    
    
    class func frozieColor() -> UIColor {
        
        return UIColor(red: 0.42, green: 0.81, blue: 0.81, alpha: 1.0);
    }
    
    class func wcDarkGreyColor() -> UIColor {
        
        return UIColor(red: 0.20, green: 0.23, blue: 0.26, alpha: 1.0);
    }
    
    class func wcBlueItemColor() -> UIColor {
        
        return UIColor(red: 0.32, green: 0.57, blue: 0.79, alpha: 1.0);
    }
    
    class func wcBlueMenuColor() -> UIColor {
        
        return UIColor(hex: "4093E5");
    }
    
    class func wcTextDarkBlueColor() -> UIColor {
        
        return UIColor(red: 0.11, green: 0.26, blue: 0.39, alpha: 1.0);
    }
    
    
    class func wcBlueButtonColor() -> UIColor {
        
        return UIColor(hex: "0F6D9E");
    }
    
    class func eiRedClockColor() -> UIColor {
        return UIColor(hex: "EB1C24")
    }
}
