

import Foundation
import Cocoa

class GradientUtil {
    
    static func setGradientGreenBlue(view: NSView) {
        
        let colorTop =  NSColor(red: 15.0/255.0, green: 118.0/255.0, blue: 128.0/255.0, alpha: 1.0).cgColor
        let colorBottom = NSColor(red: 84.0/255.0, green: 187.0/255.0, blue: 187.0/255.0, alpha: 1.0).cgColor
        
        let renderLayer = CALayer()
        view.wantsLayer = true
        view.layer = renderLayer

        let gradientLayer = CAGradientLayer()
        gradientLayer.colors = [ colorTop, colorBottom]
        gradientLayer.locations = [ 0.0, 1.0]
        gradientLayer.frame = view.bounds
        gradientLayer.autoresizingMask = [.layerWidthSizable, .layerHeightSizable]
        gradientLayer.needsDisplayOnBoundsChange = true
        
        view.layer!.insertSublayer(gradientLayer, at: 0)
    }
}
