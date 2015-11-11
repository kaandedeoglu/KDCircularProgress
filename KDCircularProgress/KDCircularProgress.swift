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

@IBDesignable
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
            return layer as! KDCircularProgressViewLayer
        }
    }
    
    private var radius: CGFloat! {
        didSet {
            progressLayer.radius = radius
        }
    }
    
    @IBInspectable public var angle: Int = 0 {
        didSet {
            if self.isAnimating() {
                self.pauseAnimation()
            }
            progressLayer.angle = angle
        }
    }
    
    @IBInspectable public var startAngle: Int = 0 {
        didSet {
            progressLayer.startAngle = UtilityFunctions.Mod(startAngle, range: 360, minMax: (0,360))
            progressLayer.setNeedsDisplay()
        }
    }
    
    @IBInspectable public var clockwise: Bool = true {
        didSet {
            progressLayer.clockwise = clockwise
            progressLayer.setNeedsDisplay()
        }
    }
    
    @IBInspectable public var roundedCorners: Bool = true {
        didSet {
            progressLayer.roundedCorners = roundedCorners
        }
    }
    
    @IBInspectable public var gradientRotateSpeed: CGFloat = 0 {
        didSet {
            progressLayer.gradientRotateSpeed = gradientRotateSpeed
        }
    }
    
    @IBInspectable public var glowAmount: CGFloat = 1.0 {//Between 0 and 1
        didSet {
            progressLayer.glowAmount = UtilityFunctions.Clamp(glowAmount, minMax: (0, 1))
        }
    }
    
    @IBInspectable public var glowMode: KDCircularProgressGlowMode = .Forward {
        didSet {
            progressLayer.glowMode = glowMode
        }
    }
    
    @IBInspectable public var progressThickness: CGFloat = 0.4 {//Between 0 and 1
        didSet {
            progressThickness = UtilityFunctions.Clamp(progressThickness, minMax: (0, 1))
            progressLayer.progressThickness = progressThickness/2
        }
    }
    
    @IBInspectable public var trackThickness: CGFloat = 0.5 {//Between 0 and 1
        didSet {
            trackThickness = UtilityFunctions.Clamp(trackThickness, minMax: (0, 1))
            progressLayer.trackThickness = trackThickness/2
        }
    }
    
    @IBInspectable public var trackColor: UIColor = UIColor.blackColor() {
        didSet {
            progressLayer.trackColor = trackColor
            progressLayer.setNeedsDisplay()
        }
    }
    
    @IBInspectable public var progressInsideFillColor: UIColor? = nil {
        didSet {
            if let color = progressInsideFillColor {
                progressLayer.progressInsideFillColor = color
            } else {
                progressLayer.progressInsideFillColor = UIColor.clearColor()
            }
        }
    }
    
    @IBInspectable public var progressColors: [UIColor]! {
        get {
            return progressLayer.colorsArray
        }
        
        set(newValue) {
            setColors(newValue)
        }
    }
    
    //These are used only from the Interface-Builder. Changing these from code will have no effect.
    //Also IB colors are limited to 3, whereas programatically we can have an arbitrary number of them.
    @objc @IBInspectable private var IBColor1: UIColor?
    @objc @IBInspectable private var IBColor2: UIColor?
    @objc @IBInspectable private var IBColor3: UIColor?
    
    
    private var animationCompletionBlock: ((Bool) -> Void)?
    
    override public init(frame: CGRect) {
        super.init(frame: frame)
        userInteractionEnabled = false
        setInitialValues()
        refreshValues()
        checkAndSetIBColors()
    }
    
    convenience public init(frame:CGRect, colors: UIColor...) {
        self.init(frame: frame)
        setColors(colors)
    }

    required public init(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)!
		translatesAutoresizingMaskIntoConstraints = false
		userInteractionEnabled = false
		setInitialValues()
        refreshValues()
	}
    
    public override func awakeFromNib() {
        checkAndSetIBColors()
    }
	
    override public class func layerClass() -> AnyClass {
        return KDCircularProgressViewLayer.self
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        radius = (frame.size.width/2.0) * 0.8
    }
    
    private func setInitialValues() {
        radius = (frame.size.width/2.0) * 0.8 //We always apply a 20% padding, stopping glows from being clipped
        backgroundColor = .clearColor()
        setColors(UIColor.whiteColor(), UIColor.redColor())
    }
    
    private func refreshValues() {
        progressLayer.angle = angle
        progressLayer.startAngle = UtilityFunctions.Mod(startAngle, range: 360, minMax: (0,360))
        progressLayer.clockwise = clockwise
        progressLayer.roundedCorners = roundedCorners
        progressLayer.gradientRotateSpeed = gradientRotateSpeed
        progressLayer.glowAmount = UtilityFunctions.Clamp(glowAmount, minMax: (0, 1))
        progressLayer.glowMode = glowMode
        progressLayer.progressThickness = progressThickness/2
        progressLayer.trackColor = trackColor
        progressLayer.trackThickness = trackThickness/2
    }
    
    private func checkAndSetIBColors() {
        let nonNilColors = [IBColor1, IBColor2, IBColor3].filter { $0 != nil}.map { $0! }
        if nonNilColors.count > 0 {
            setColors(nonNilColors)
        }
    }
    
    public func setColors(colors: UIColor...) {
        setColors(colors)
    }
    
    private func setColors(colors: [UIColor]) {
        progressLayer.colorsArray = colors
        progressLayer.setNeedsDisplay()
    }
    
    public func animateFromAngle(fromAngle: Int, toAngle: Int, duration: NSTimeInterval, relativeDuration: Bool = true, completion: ((Bool) -> Void)?) {
        if isAnimating() {
            pauseAnimation()
        }
        
        let animationDuration: NSTimeInterval
        if relativeDuration {
           animationDuration = duration
        } else {
            let traveledAngle = UtilityFunctions.Mod(toAngle - fromAngle, range: 360, minMax: (0, 360))
            let scaledDuration = (NSTimeInterval(traveledAngle) * duration) / 360
            animationDuration = scaledDuration
        }

        let animation = CABasicAnimation(keyPath: "angle")
        animation.fromValue = fromAngle
        animation.toValue = toAngle
        animation.duration = animationDuration
        animation.delegate = self
        angle = toAngle
        animationCompletionBlock = completion
        
        progressLayer.addAnimation(animation, forKey: "angle")
    }
    
    public func animateToAngle(toAngle: Int, duration: NSTimeInterval, relativeDuration: Bool = true, completion: ((Bool) -> Void)?) {
        if isAnimating() {
            pauseAnimation()
        }
        animateFromAngle(angle, toAngle: toAngle, duration: duration, relativeDuration: relativeDuration, completion: completion)
    }
    
    public func pauseAnimation() {
        let presentationLayer = progressLayer.presentationLayer() as! KDCircularProgressViewLayer
        let currentValue = presentationLayer.angle
        progressLayer.removeAllAnimations()
        animationCompletionBlock = nil
        angle = currentValue
    }
    
    public func stopAnimation() {
        progressLayer.removeAllAnimations()
        angle = 0
    }
    
    public func isAnimating() -> Bool {
        return progressLayer.animationForKey("angle") != nil
    }
    
    override public func animationDidStop(anim: CAAnimation, finished flag: Bool) {
        if let completionBlock = animationCompletionBlock {
            completionBlock(flag)
            animationCompletionBlock = nil
        }
    }
    
    public override func didMoveToWindow() {
        if let window = window {
            progressLayer.contentsScale = window.screen.scale
        }
    }
    
    public override func willMoveToSuperview(newSuperview: UIView?) {
        if newSuperview == nil && isAnimating() {
            pauseAnimation()
        }
    }
    
    public override func prepareForInterfaceBuilder() {
        setInitialValues()
        refreshValues()
        checkAndSetIBColors()
        progressLayer.setNeedsDisplay()
    }
    
    private class KDCircularProgressViewLayer: CALayer {
        @NSManaged var angle: Int
        var radius: CGFloat! {
            didSet {
                invalidateGradientCache()
            }
        }
        var startAngle: Int!
        var clockwise: Bool! {
            didSet {
                if clockwise != oldValue {
                    invalidateGradientCache()
                }
            }
        }
        var roundedCorners: Bool!
        var gradientRotateSpeed: CGFloat! {
            didSet {
                invalidateGradientCache()
            }
        }
        var glowAmount: CGFloat!
        var glowMode: KDCircularProgressGlowMode!
        var progressThickness: CGFloat!
        var trackThickness: CGFloat!
        var trackColor: UIColor!
        var progressInsideFillColor: UIColor = UIColor.clearColor()
        var colorsArray: [UIColor]! {
            didSet {
                invalidateGradientCache()
            }
        }
        private var gradientCache: CGGradientRef?
        private var locationsCache: [CGFloat]?
        
        private struct GlowConstants {
            private static let sizeToGlowRatio: CGFloat = 0.00015
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
        
        override class func needsDisplayForKey(key: String) -> Bool {
            return key == "angle" ? true : super.needsDisplayForKey(key)
        }
        
        override init(layer: AnyObject) {
            super.init(layer: layer)
            let progressLayer = layer as! KDCircularProgressViewLayer
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

        override init() {
            super.init()
        }

        required init?(coder aDecoder: NSCoder) {
            super.init(coder: aDecoder)
        }
        
        override func drawInContext(ctx: CGContext) {
            UIGraphicsPushContext(ctx)
            let rect = bounds
            let size = rect.size
            
            let trackLineWidth: CGFloat = radius * trackThickness
            let progressLineWidth = radius * progressThickness
            let arcRadius = max(radius - trackLineWidth/2, radius - progressLineWidth/2)
            CGContextAddArc(ctx, CGFloat(size.width/2.0), CGFloat(size.height/2.0), arcRadius, 0, CGFloat(M_PI * 2), 0)
            trackColor.set()
            CGContextSetStrokeColorWithColor(ctx, trackColor.CGColor)
            CGContextSetFillColorWithColor(ctx, progressInsideFillColor.CGColor)
            CGContextSetLineWidth(ctx, trackLineWidth)
            CGContextSetLineCap(ctx, CGLineCap.Butt)
            CGContextDrawPath(ctx, .FillStroke)

            UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
            let imageCtx = UIGraphicsGetCurrentContext()
            let reducedAngle = UtilityFunctions.Mod(angle, range: 360, minMax: (0, 360))
            let fromAngle = ConversionFunctions.DegreesToRadians(CGFloat(-startAngle))
            let toAngle = ConversionFunctions.DegreesToRadians(CGFloat((clockwise == true ? -reducedAngle : reducedAngle) - startAngle))
            CGContextAddArc(imageCtx, CGFloat(size.width/2.0),CGFloat(size.height/2.0), arcRadius, fromAngle, toAngle, clockwise == true ? 1 : 0)
            let glowValue = GlowConstants.glowAmountForAngle(reducedAngle, glowAmount: glowAmount, glowMode: glowMode, size: size.width)
            if glowValue > 0 {
                CGContextSetShadowWithColor(imageCtx, CGSizeZero, glowValue, UIColor.blackColor().CGColor)
            }
            CGContextSetLineCap(imageCtx, roundedCorners == true ? .Round : .Butt)
            CGContextSetLineWidth(imageCtx, progressLineWidth)
            CGContextDrawPath(imageCtx, .Stroke)
            
            let drawMask: CGImageRef = CGBitmapContextCreateImage(UIGraphicsGetCurrentContext())!
            UIGraphicsEndImageContext()
            
            CGContextSaveGState(ctx)
            CGContextClipToMask(ctx, bounds, drawMask)
            
            //Gradient - Fill
            if colorsArray.count > 1 {
                var componentsArray: [CGFloat] = []
                let rgbColorsArray: [UIColor] = colorsArray.map {c in // Make sure every color in colors array is in RGB color space
                    if CGColorGetNumberOfComponents(c.CGColor) == 2 {
                        let whiteValue = CGColorGetComponents(c.CGColor)[0]
                        return UIColor(red: whiteValue, green: whiteValue, blue: whiteValue, alpha: 1.0)
                    } else {
                        return c
                    }
                }
                
                for color in rgbColorsArray {
                    let colorComponents: UnsafePointer<CGFloat> = CGColorGetComponents(color.CGColor)
                    componentsArray.appendContentsOf([colorComponents[0],colorComponents[1],colorComponents[2],1.0])
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
        
        private func fillRectWithContext(ctx: CGContext!, color: UIColor) {
            CGContextSetFillColorWithColor(ctx, color.CGColor)
            CGContextFillRect(ctx, bounds)
        }
        
        private func drawGradientWithContext(ctx: CGContext!, componentsArray: [CGFloat]) {
            let baseSpace = CGColorSpaceCreateDeviceRGB()
            let locations = locationsCache ?? gradientLocationsFromColorCount(componentsArray.count/4, gradientWidth: bounds.size.width)
            let gradient: CGGradient

            if let g = self.gradientCache {
                gradient = g
            } else {
                guard let g = CGGradientCreateWithColorComponents(baseSpace, componentsArray, locations,componentsArray.count / 4) else { return }
                self.gradientCache = g
                gradient = g
            }
            
            let halfX = bounds.size.width/2.0
            let floatPi = CGFloat(M_PI)
            let rotateSpeed = clockwise == true ? gradientRotateSpeed : gradientRotateSpeed * -1
            let angleInRadians = ConversionFunctions.DegreesToRadians(rotateSpeed * CGFloat(angle) - 90)
            let oppositeAngle = angleInRadians > floatPi ? angleInRadians - floatPi : angleInRadians + floatPi
            
            let startPoint = CGPoint(x: (cos(angleInRadians) * halfX) + halfX, y: (sin(angleInRadians) * halfX) + halfX)
            let endPoint = CGPoint(x: (cos(oppositeAngle) * halfX) + halfX, y: (sin(oppositeAngle) * halfX) + halfX)
            
            CGContextDrawLinearGradient(ctx, gradient, startPoint, endPoint, .DrawsBeforeStartLocation)
        }
        
        private func gradientLocationsFromColorCount(colorCount: Int, gradientWidth: CGFloat) -> [CGFloat] {
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
        
        private func invalidateGradientCache() {
            gradientCache = nil
            locationsCache = nil
        }
    }
}
