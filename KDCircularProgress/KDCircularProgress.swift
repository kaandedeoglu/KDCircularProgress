//
//  KDCircularProgress.swift
//  KDCircularProgress
//
//  Created by Kaan Dedeoglu on 1/14/15.
//  Copyright (c) 2015 Kaan Dedeoglu. All rights reserved.
//

import UIKit

public enum KDCircularProgressGlowMode {
    case Forward, Reverse, Constant, NoGlow
}

public class KDCircularProgress: UIView {
    
    private struct ConversionFunctions {
        static func DegreesToRadians (value:CGFloat) -> CGFloat {
            return value * CGFloat(M_PI) / 180.0
        }
        
        static func RadiansToDegrees (value:CGFloat) -> CGFloat {
            return value * 180.0 / CGFloat(M_PI)
        }
    }
    
    private struct UtilityFunctions {
        static func Clamp<T: Comparable>(value: T, minMax: (T, T)) -> T {
            let (min, max) = minMax
            if value < min {
                return min
            } else if value > max {
                return max
            } else {
                return value
            }
        }
        
        static func Mod(value: Int, range: Int, minMax: (Int, Int)) -> Int {
            let (min, max) = minMax
            assert(abs(range) <= abs(max - min), "range should be <= than the interval")
            if value >= min && value <= max {
                return value
            } else if value < min {
                return Mod(value + range, range: range, minMax: minMax)
            } else {
                return Mod(value - range, range: range, minMax: minMax)
            }
        }
    }
    
    private var progressLayer: KDCircularProgressViewLayer! {
        get {
            return layer as KDCircularProgressViewLayer
        }
    }
    
    private var radius: CGFloat! {
        didSet {
            progressLayer.radius = radius
        }
    }
    
    public var angle: Int! {
        didSet {
            if self.isAnimating() {
                self.pauseAnimation()
            }
            progressLayer.angle = angle
        }
    }
    
    public var startAngle: Int! {
        didSet {
            progressLayer.startAngle = UtilityFunctions.Mod(startAngle, range: 360, minMax: (0,360))
            progressLayer.setNeedsDisplay()
        }
    }
    
    public var clockwise: Bool! {
        didSet {
            progressLayer.clockwise = clockwise
            progressLayer.setNeedsDisplay()
        }
    }
    
    public var roundedCorners: Bool! {
        didSet {
            progressLayer.roundedCorners = roundedCorners
        }
    }
    
    public var gradientRotateSpeed: CGFloat! {
        didSet {
            progressLayer.gradientRotateSpeed = gradientRotateSpeed
        }
    }
    
    public var glowAmount: CGFloat! {//Between 0 and 1
        didSet {
            progressLayer.glowAmount = UtilityFunctions.Clamp(glowAmount, minMax: (0, 1))
        }
    }
    
    public var glowMode: KDCircularProgressGlowMode! {
        didSet {
            progressLayer.glowMode = glowMode
        }
    }
    
    public var progressThickness: CGFloat! {//Between 0 and 1
        didSet {
            progressThickness = UtilityFunctions.Clamp(progressThickness, minMax: (0, 1))
            progressLayer.progressThickness = progressThickness/2
        }
    }
    
    public var trackThickness: CGFloat! {//Between 0 and 1
        didSet {
            trackThickness = UtilityFunctions.Clamp(trackThickness, minMax: (0, 1))
            progressLayer.trackThickness = trackThickness/2
        }
    }
    
    public var trackColor: UIColor! {
        didSet {
            progressLayer.trackColor = trackColor
            progressLayer.setNeedsDisplay()
        }
    }
    
    public var progressColors: [UIColor]! {
        get {
            return progressLayer.colorsArray
        }
        
        set(newValue) {
            setColors(newValue)
        }
    }
    
    private var animationCompletionBlock: ((Bool) -> Void)?
    
    override public init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor.clearColor()
        userInteractionEnabled = false
        setInitialValues()
    }
    
    convenience public init(frame:CGRect, colors: UIColor...) {
        self.init(frame: frame)
        setColors(colors)
    }

    required public init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override public class func layerClass() -> AnyClass {
        return KDCircularProgressViewLayer.self
    }
    
    public func setColors(colors: UIColor...) {
        setColors(colors)
    }
    
    private func setColors(colors: [UIColor]) {
        progressLayer.colorsArray = colors
        progressLayer.setNeedsDisplay()
    }
    
    private func setInitialValues() { // We have this because didSet effects are not triggered when invoked directly from init method
        radius = (frame.size.width/2.0) * 0.8 //We always apply a 20% padding, stopping glows from being clipped
        angle = 0
        startAngle = 0
        clockwise = true
        roundedCorners = false
        gradientRotateSpeed = 0
        glowAmount = 1
        glowMode = .Forward
        progressThickness = 0.4
        trackThickness = 0.5
        trackColor = UIColor.blackColor()
        setColors(UIColor.whiteColor(), UIColor.redColor())
    }
    
    public func animateFromAngle(fromAngle: Int, toAngle: Int, duration: NSTimeInterval, completion: ((Bool) -> Void)?) {
        if isAnimating() {
            pauseAnimation()
        }

        let animation = CABasicAnimation(keyPath: "angle")
        animation.fromValue = fromAngle
        animation.toValue = toAngle
        animation.duration = duration
        animation.delegate = self
        angle = toAngle
        animationCompletionBlock = completion
        
        progressLayer.addAnimation(animation, forKey: "angle")
    }
    
    public func animateToAngle(toAngle: Int, duration: NSTimeInterval, completion: ((Bool) -> Void)?) {
        if isAnimating() {
            pauseAnimation()
        }
        animateFromAngle(angle, toAngle: toAngle, duration: duration, completion: completion)
    }
    
    public func pauseAnimation() {
        let presentationLayer = progressLayer.presentationLayer() as KDCircularProgressViewLayer
        let currentValue = presentationLayer.angle
        progressLayer.removeAllAnimations()
        animationCompletionBlock = nil
        angle = currentValue
    }
    
    public func isAnimating() -> Bool {
        return progressLayer.animationForKey("angle") != nil
    }
    
    override public func animationDidStop(anim: CAAnimation!, finished flag: Bool) {
        if let completionBlock = animationCompletionBlock {
            completionBlock(flag)
            animationCompletionBlock = nil
        }
    }
    
    public override func didMoveToWindow() {
        progressLayer.contentsScale = window!.screen.scale
    }
    
    public override func willMoveToSuperview(newSuperview: UIView?) {
        if newSuperview == nil && isAnimating() {
            pauseAnimation()
        }
    }
    
    private class KDCircularProgressViewLayer: CALayer {
        @NSManaged var angle: Int
        var radius: CGFloat!
        var startAngle: Int!
        var clockwise: Bool!
        var roundedCorners: Bool!
        var gradientRotateSpeed: CGFloat!
        var glowAmount: CGFloat!
        var glowMode: KDCircularProgressGlowMode!
        var progressThickness: CGFloat!
        var trackThickness: CGFloat!
        var trackColor: UIColor!
        var colorsArray: [UIColor]! {
            didSet {
                gradientCache = nil
                locationsCache = nil
            }
        }
        var gradientCache: CGGradientRef?
        var locationsCache: [CGFloat]?
        
        struct GlowConstants {
            static let sizeToGlowRatio: CGFloat = 0.00015
            static func glowAmountForAngle(angle: Int, glowAmount: CGFloat, glowMode: KDCircularProgressGlowMode, size: CGFloat) -> CGFloat {
                switch glowMode {
                case .Forward:
                    return CGFloat(angle) * size * sizeToGlowRatio * glowAmount
                case .Reverse:
                    return CGFloat(360 - angle) * size * sizeToGlowRatio * glowAmount
                case .Constant:
                    return 360 * size * sizeToGlowRatio * glowAmount
                default:
                    return 0
                }
            }
        }
        
        override class func needsDisplayForKey(key: String!) -> Bool {
            return key == "angle" ? true : super.needsDisplayForKey(key)
        }
        
        override init!(layer: AnyObject!) {
            super.init(layer: layer)
            let progressLayer = layer as KDCircularProgressViewLayer
            radius = progressLayer.radius
            angle = progressLayer.angle
            startAngle = progressLayer.startAngle
            clockwise = progressLayer.clockwise
            roundedCorners = progressLayer.roundedCorners
            gradientRotateSpeed = progressLayer.gradientRotateSpeed
            glowAmount = progressLayer.glowAmount
            glowMode = progressLayer.glowMode
            progressThickness = progressLayer.progressThickness
            trackThickness = progressLayer.trackThickness
            trackColor = progressLayer.trackColor
            colorsArray = progressLayer.colorsArray
        }

        override init!() {
            super.init()
        }

        required init(coder aDecoder: NSCoder) {
            super.init(coder: aDecoder)
        }
        
        override func drawInContext(ctx: CGContext!) {
            UIGraphicsPushContext(ctx)
            let rect = bounds
            let size = rect.size
            
            let trackLineWidth: CGFloat = radius * trackThickness
            let progressLineWidth = radius * progressThickness
            let arcRadius = max(radius - trackLineWidth/2, radius - progressLineWidth/2)
            CGContextAddArc(ctx, CGFloat(size.width/2.0), CGFloat(size.height/2.0), arcRadius, 0, CGFloat(M_PI * 2), 0)
            trackColor.set()
            CGContextSetLineWidth(ctx, trackLineWidth)
            CGContextSetLineCap(ctx, kCGLineCapButt)
            CGContextDrawPath(ctx, kCGPathStroke)

            UIGraphicsBeginImageContext(CGSize(width: size.width, height: size.height))
            let imageCtx = UIGraphicsGetCurrentContext()
            let reducedAngle = UtilityFunctions.Mod(angle, range: 360, minMax: (0, 360))
            let fromAngle = ConversionFunctions.DegreesToRadians(CGFloat(-startAngle))
            let toAngle = ConversionFunctions.DegreesToRadians(CGFloat((clockwise == true ? -reducedAngle : reducedAngle) - startAngle))
            CGContextAddArc(imageCtx, CGFloat(size.width/2.0),CGFloat(size.height/2.0), arcRadius, fromAngle, toAngle, clockwise == true ? 1 : 0)
            let glowValue = GlowConstants.glowAmountForAngle(reducedAngle, glowAmount: glowAmount, glowMode: glowMode, size: size.width)
            if glowValue > 0 {
                CGContextSetShadowWithColor(imageCtx, CGSizeZero, glowValue, UIColor.blackColor().CGColor)
            }
            CGContextSetLineCap(imageCtx, roundedCorners == true ? kCGLineCapRound : kCGLineCapButt)
            CGContextSetLineWidth(imageCtx, progressLineWidth)
            CGContextDrawPath(imageCtx, kCGPathStroke)
            
            let drawMask: CGImageRef = CGBitmapContextCreateImage(UIGraphicsGetCurrentContext())
            UIGraphicsEndImageContext()
            
            CGContextSaveGState(ctx)
            CGContextClipToMask(ctx, bounds, drawMask)
            
            //Gradient - Fill
            if colorsArray.count > 1 {
                var componentsArray: [CGFloat] = []
                var rgbColorsArray: [UIColor] = colorsArray.map {c in // Make sure every color in colors array is in RGB color space
                    if CGColorGetNumberOfComponents(c.CGColor) == UInt(2) {
                        let whiteValue = CGColorGetComponents(c.CGColor)[0]
                        return UIColor(red: whiteValue, green: whiteValue, blue: whiteValue, alpha: 1.0)
                    } else {
                        return c
                    }
                }
                
                for color in rgbColorsArray {
                    let colorComponents: UnsafePointer<CGFloat> = CGColorGetComponents(color.CGColor)
                    componentsArray.extend([colorComponents[0],colorComponents[1],colorComponents[2],1.0])
                }
                
                drawGradientWithContext(ctx, componentsArray: componentsArray)
            } else {
                if colorsArray.count == 1 {
                    fillRectWithContext(ctx, color: colorsArray[0])
                } else {
                    fillRectWithContext(ctx, color: UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0))
                }
            }
            CGContextRestoreGState(ctx)
            UIGraphicsPopContext()
        }
        
        func fillRectWithContext(ctx: CGContext!, color: UIColor) {
            CGContextSetFillColorWithColor(ctx, color.CGColor)
            CGContextFillRect(ctx, bounds)
        }
        
        func drawGradientWithContext(ctx: CGContext!, componentsArray: [CGFloat]) {
            let baseSpace = CGColorSpaceCreateDeviceRGB()
            let locations = locationsCache ?? gradientLocationsFromColorCount(componentsArray.count/4, gradientWidth: bounds.size.width)
            var gradient: CGGradient = {
                if let g = self.gradientCache {
                    return g
                } else {
                    let g = CGGradientCreateWithColorComponents(baseSpace, componentsArray, locations, UInt(componentsArray.count / 4))
                    self.gradientCache = g
                    return g
                }
            }()
            
            let halfX = bounds.size.width/2.0
            let floatPi = CGFloat(M_PI)
            let rotateSpeed = clockwise == true ? gradientRotateSpeed : gradientRotateSpeed * -1
            let angleInRadians = ConversionFunctions.DegreesToRadians(rotateSpeed * CGFloat(angle) - 90)
            var oppositeAngle = angleInRadians > floatPi ? angleInRadians - floatPi : angleInRadians + floatPi
            
            let startPoint = CGPoint(x: (cos(angleInRadians) * halfX) + halfX, y: (sin(angleInRadians) * halfX) + halfX)
            let endPoint = CGPoint(x: (cos(oppositeAngle) * halfX) + halfX, y: (sin(oppositeAngle) * halfX) + halfX)
            
            CGContextDrawLinearGradient(ctx, gradient, startPoint, endPoint, 0)
        }
        
        func gradientLocationsFromColorCount(colorCount: Int, gradientWidth: CGFloat) -> [CGFloat] {
            if colorCount == 0 || gradientWidth == 0 {
                return []
            } else {
                var locationsArray: [CGFloat] = []
                let progressLineWidth = radius * progressThickness
                let firstPoint = gradientWidth/2 - (radius - progressLineWidth/2)
                let increment = (gradientWidth - (2*firstPoint))/CGFloat(colorCount - 1)
                
                for i in 0..<colorCount {
                    locationsArray.append(firstPoint + (CGFloat(i) * increment))
                }
                assert(locationsArray.count == colorCount, "color counts should be equal")
                let result = locationsArray.map { $0 / gradientWidth }
                locationsCache = result
                return result
            }
        }
    }
}
