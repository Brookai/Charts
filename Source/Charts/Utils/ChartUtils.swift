//
//  Utils.swift
//  Charts
//
//  Copyright 2015 Daniel Cohen Gindi & Philipp Jahoda
//  A port of MPAndroidChart for iOS
//  Licensed under Apache License 2.0
//
//  https://github.com/danielgindi/Charts
//

import Foundation
import CoreGraphics

extension Comparable {
    func clamped(to range: ClosedRange<Self>) -> Self {
        if self > range.upperBound {
            return range.upperBound
        } else if self < range.lowerBound {
            return range.lowerBound
        } else {
            return self
        }
    }
}

extension FloatingPoint
{
    var DEG2RAD: Self
    {
        return self * .pi / 180
    }

    var RAD2DEG: Self
    {
        return self * 180 / .pi
    }

    /// - returns: An angle between 0.0 < 360.0 (not less than zero, less than 360)
    /// NOTE: Value must be in degrees
    var normalizedAngle: Self
    {
        let angle = truncatingRemainder(dividingBy: 360)
        return (sign == .minus) ? angle + 360 : angle
    }
}

extension CGSize
{
    func rotatedBy(degrees: CGFloat) -> CGSize
    {
        let radians = degrees.DEG2RAD
        return rotatedBy(radians: radians)
    }

    func rotatedBy(radians: CGFloat) -> CGSize
    {
        return CGSize(
            width: abs(width * cos(radians)) + abs(height * sin(radians)),
            height: abs(width * sin(radians)) + abs(height * cos(radians))
        )
    }
}

extension Double
{
    /// Rounds the number to the nearest multiple of it's order of magnitude, rounding away from zero if halfway.
    func roundedToNextSignificant() -> Double
    {
        guard
            !isInfinite,
            !isNaN,
            self != 0
            else { return self }

        let d = ceil(log10(self < 0 ? -self : self))
        let pw = 1 - Int(d)
        let magnitude = pow(10.0, Double(pw))
        let shifted = (self * magnitude).rounded()
        return shifted / magnitude
    }

    var decimalPlaces: Int
    {
        guard
            !isNaN,
            !isInfinite,
            self != 0.0
            else { return 0 }

        let i = roundedToNextSignificant()

        guard
            !i.isInfinite,
            !i.isNaN
            else { return 0 }

        return Int(ceil(-log10(i))) + 2
    }
}

extension CGPoint
{
    /// Calculates the position around a center point, depending on the distance from the center, and the angle of the position around the center.
    func moving(distance: CGFloat, atAngle angle: CGFloat) -> CGPoint
    {
        return CGPoint(x: x + distance * cos(angle.DEG2RAD),
                       y: y + distance * sin(angle.DEG2RAD))
    }
}

extension CGContext {

    open func drawImage(_ image: NSUIImage, atCenter center: CGPoint, size: CGSize)
    {
        var drawOffset = CGPoint()
        drawOffset.x = center.x - (size.width / 2)
        drawOffset.y = center.y - (size.height / 2)
        
        NSUIGraphicsPushContext(self)
        
        let scaledImage :  UIImage
        if image.size.width > size.width && image.size.height > size.height
        {
            let key = "resized_\(size.width)_\(size.height)"

            // Try to take scaled image from cache of this image
            var cachedScaledImage = objc_getAssociatedObject(image, key) as? NSUIImage
            if cachedScaledImage == nil
            {
                // Scale the image
                NSUIGraphicsBeginImageContextWithOptions(size, false, 0.0)

                image.draw(in: CGRect(origin: .zero, size: size))

                cachedScaledImage = NSUIGraphicsGetImageFromCurrentImageContext()
                NSUIGraphicsEndImageContext()

                // Put the scaled image in a cache owned by the original image
                objc_setAssociatedObject(image, key, cachedScaledImage, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            }
            scaledImage = cachedScaledImage!
        }else{
            scaledImage = image
        }
        let darkBlueGradient = UIColor.darkBlueGradient()
        let offset : CGFloat = 10
        let gradientFrame = CGRect(origin: .zero, size: CGSize(width: size.width+offset, height: size.height+offset))
        let locations = darkBlueGradient.locations.map{ $0 as! CGFloat}
        let colors = darkBlueGradient.colors as CFArray
        let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                                  colors: colors,
                                  locations:  locations)
        
        
        let renderer = UIGraphicsImageRenderer(size: gradientFrame.size)
        let gradientImage =  renderer.image { context in
            let path = UIBezierPath(roundedRect: gradientFrame,
                                    cornerRadius: gradientFrame.width/2)
            path.addClip()
            context.cgContext.drawLinearGradient(gradient!, start: .zero, end: CGPoint(x: 0, y: gradientFrame.height), options: [])
            let origin = CGPoint(x: (gradientFrame.width - image.size.width)/2,
            y: (gradientFrame.height - image.size.height)/2)
            scaledImage.draw(at: origin)
        }
        
        gradientImage.draw(in: CGRect(origin: drawOffset, size: gradientFrame.size) )

        NSUIGraphicsPopContext()
    }

    open func drawText(_ text: String, in rect: CGRect, align: NSTextAlignment, anchor: CGPoint = CGPoint(x: 0.5, y: 0.5), angleRadians: CGFloat = 0.0, attributes: [NSAttributedString.Key : Any] ){
        guard text.trim().count > 0  else {
            return
        }
        
        NSUIGraphicsPushContext(self)
        let darkBlueGradient = UIColor.darkBlueGradient()
        let offset : CGFloat = 10
        let gradientFrame = CGRect(origin: .zero, size: CGSize(width: rect.size.width+offset, height: rect.size.height+offset))
        let locations = darkBlueGradient.locations.map{ $0 as! CGFloat}
        let colors = darkBlueGradient.colors as CFArray
        let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                                 colors: colors,
                                 locations:  locations)
        
        let at :  CGPoint
        
        if let valueFont = attributes[NSAttributedString.Key.font] as? UIFont {
            let textSize = text.sizeWith(font: valueFont)
            at = CGPoint(x: gradientFrame.midX - textSize.width/2, y: gradientFrame.midY - valueFont.lineHeight/2 )
        }else {
           at =  CGPoint(x: gradientFrame.midX, y: gradientFrame.midY )
        }

        let renderer = UIGraphicsImageRenderer(size: gradientFrame.size)
        let gradientImage =  renderer.image { context in

            let path = UIBezierPath(roundedRect: gradientFrame,
                                    cornerRadius: gradientFrame.width/2)
            path.addClip()
            
            context.cgContext.drawLinearGradient(gradient!, start: .zero, end: CGPoint(x: 0, y: gradientFrame.height), options: [])
            (text as NSString).draw(at: at, withAttributes: attributes)
        }
        
        
        gradientImage.draw(in: rect )
        NSUIGraphicsPopContext()
    }
    
    open func drawText(_ text: String, at point: CGPoint, align: NSTextAlignment, anchor: CGPoint = CGPoint(x: 0.5, y: 0.5), angleRadians: CGFloat = 0.0, attributes: [NSAttributedString.Key : Any]?)
    {
        let drawPoint = getDrawPoint(text: text, point: point, align: align, attributes: attributes)
        
        if (angleRadians == 0.0)
        {
            NSUIGraphicsPushContext(self)
            
            (text as NSString).draw(at: drawPoint, withAttributes: attributes)
            
            NSUIGraphicsPopContext()
        }
        else
        {
            drawText(text, at: drawPoint, anchor: anchor, angleRadians: angleRadians, attributes: attributes)
        }
    }
    
    open func drawText(_ text: String, at point: CGPoint, anchor: CGPoint = CGPoint(x: 0.5, y: 0.5), angleRadians: CGFloat, attributes: [NSAttributedString.Key : Any]?)
    {
        var drawOffset = CGPoint()

        NSUIGraphicsPushContext(self)

        if angleRadians != 0.0
        {
            let size = text.size(withAttributes: attributes)

            // Move the text drawing rect in a way that it always rotates around its center
            drawOffset.x = -size.width * 0.5
            drawOffset.y = -size.height * 0.5

            var translate = point

            // Move the "outer" rect relative to the anchor, assuming its centered
            if anchor.x != 0.5 || anchor.y != 0.5
            {
                let rotatedSize = size.rotatedBy(radians: angleRadians)

                translate.x -= rotatedSize.width * (anchor.x - 0.5)
                translate.y -= rotatedSize.height * (anchor.y - 0.5)
            }

            saveGState()
            translateBy(x: translate.x, y: translate.y)
            rotate(by: angleRadians)

            (text as NSString).draw(at: drawOffset, withAttributes: attributes)

            restoreGState()
        }
        else
        {
            if anchor.x != 0.0 || anchor.y != 0.0
            {
                let size = text.size(withAttributes: attributes)

                drawOffset.x = -size.width * anchor.x
                drawOffset.y = -size.height * anchor.y
            }

            drawOffset.x += point.x
            drawOffset.y += point.y

            (text as NSString).draw(at: drawOffset, withAttributes: attributes)
        }

        NSUIGraphicsPopContext()
    }

    private func getDrawPoint(text: String, point: CGPoint, align: NSTextAlignment, attributes: [NSAttributedString.Key : Any]?) -> CGPoint
    {
        var point = point
        
        if align == .center
        {
            point.x -= text.size(withAttributes: attributes).width / 2.0
        }
        else if align == .right
        {
            point.x -= text.size(withAttributes: attributes).width
        }
        return point
    }
    
    func drawMultilineText(_ text: String, at point: CGPoint, constrainedTo size: CGSize, anchor: CGPoint, knownTextSize: CGSize, angleRadians: CGFloat, attributes: [NSAttributedString.Key : Any]?)
    {
        var rect = CGRect(origin: .zero, size: knownTextSize)

        NSUIGraphicsPushContext(self)

        if angleRadians != 0.0
        {
            // Move the text drawing rect in a way that it always rotates around its center
            rect.origin.x = -knownTextSize.width * 0.5
            rect.origin.y = -knownTextSize.height * 0.5

            var translate = point

            // Move the "outer" rect relative to the anchor, assuming its centered
            if anchor.x != 0.5 || anchor.y != 0.5
            {
                let rotatedSize = knownTextSize.rotatedBy(radians: angleRadians)

                translate.x -= rotatedSize.width * (anchor.x - 0.5)
                translate.y -= rotatedSize.height * (anchor.y - 0.5)
            }

            saveGState()
            translateBy(x: translate.x, y: translate.y)
            rotate(by: angleRadians)

            (text as NSString).draw(with: rect, options: .usesLineFragmentOrigin, attributes: attributes, context: nil)

            restoreGState()
        }
        else
        {
            if anchor.x != 0.0 || anchor.y != 0.0
            {
                rect.origin.x = -knownTextSize.width * anchor.x
                rect.origin.y = -knownTextSize.height * anchor.y
            }

            rect.origin.x += point.x
            rect.origin.y += point.y

            (text as NSString).draw(with: rect, options: .usesLineFragmentOrigin, attributes: attributes, context: nil)
        }

        NSUIGraphicsPopContext()
    }

    func drawMultilineText(_ text: String, at point: CGPoint, constrainedTo size: CGSize, anchor: CGPoint, angleRadians: CGFloat, attributes: [NSAttributedString.Key : Any]?)
    {
        let rect = text.boundingRect(with: size, options: .usesLineFragmentOrigin, attributes: attributes, context: nil)
        drawMultilineText(text, at: point, constrainedTo: size, anchor: anchor, knownTextSize: rect.size, angleRadians: angleRadians, attributes: attributes)
    }
}
