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
    
    private struct Conversion {
        static func degreesToRadians (value:CGFloat) -> CGFloat {
            return value * CGFloat(M_PI) / 180.0
        }
        
        static func radiansToDegrees (value:CGFloat) -> CGFloat {
            return value * 180.0 / CGFloat(M_PI)
        }
    }
    
    private struct Utility {
        static func clamp<T: Comparable>(value: T, minMax: (T, T)) -> T {
            let (min, max) = minMax
            if value < min {
                return min
            } else if value > max {
                return max
            } else {
                return value
            }
        }
        
        static func inverseLerp(value: CGFloat, minMax: (CGFloat, CGFloat)) -> CGFloat {
            return (value - minMax.0) / (minMax.1 - minMax.0)
        }
        
        static func lerp(value: CGFloat, minMax: (CGFloat, CGFloat)) -> CGFloat {
            return (minMax.1 - minMax.0) * value + minMax.0
        }
        
        static func colorLerp(value: CGFloat, minMax: (UIColor, UIColor)) -> UIColor {
            let clampedValue = clamp(value, minMax: (0, 1))
            
            let zero: CGFloat = 0
            
            var (r0, g0, b0, a0) = (zero, zero, zero, zero)
            minMax.0.getRed(&r0, green: &g0, blue: &b0, alpha: &a0)
            
            var (r1, g1, b1, a1) = (zero, zero, zero, zero)
            minMax.1.getRed(&r1, green: &g1, blue: &b1, alpha: &a1)
            
            return UIColor(red: lerp(clampedValue, minMax: (r0, r1)), green: lerp(clampedValue, minMax: (g0, g1)), blue: lerp(clampedValue, minMax: (b0, b1)), alpha: lerp(clampedValue, minMax: (a0, a1)))
        }
        
        static func mod(value: Double, range: Double, minMax: (Double, Double)) -> Double {
            let (min, max) = minMax
            assert(abs(range) <= abs(max - min), "range should be <= than the interval")
            if value >= min && value <= max {
                return value
            } else if value < min {
                return mod(value + range, range: range, minMax: minMax)
            } else {
                return mod(value - range, range: range, minMax: minMax)
            }
        }
    }
    
    private var progressLayer: KDCircularProgressViewLayer {
        get {
            return layer as! KDCircularProgressViewLayer
        }
    }
    
    private var radius: CGFloat! {
        didSet {
            progressLayer.radius = radius
        }
    }
    
    @IBInspectable public var angle: Double = 0 {
        didSet {
            if self.isAnimating() {
                self.pauseAnimation()
            }
            progressLayer.angle = angle
        }
    }
    
    @IBInspectable public var startAngle: Double = 0 {
        didSet {
            startAngle = Utility.mod(startAngle, range: 360, minMax: (0, 360))
            progressLayer.startAngle = startAngle
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
    
    @IBInspectable public var lerpColorMode: Bool = false {
        didSet {
            progressLayer.lerpColorMode = lerpColorMode
        }
    }
    
    @IBInspectable public var gradientRotateSpeed: CGFloat = 0 {
        didSet {
            progressLayer.gradientRotateSpeed = gradientRotateSpeed
        }
    }
    
    @IBInspectable public var glowAmount: CGFloat = 1.0 {//Between 0 and 1
        didSet {
            glowAmount = Utility.clamp(glowAmount, minMax: (0, 1))
            progressLayer.glowAmount = glowAmount
        }
    }
    
    @IBInspectable public var glowMode: KDCircularProgressGlowMode = .Forward {
        didSet {
            progressLayer.glowMode = glowMode
        }
    }
    
    @IBInspectable public var progressThickness: CGFloat = 0.4 {//Between 0 and 1
        didSet {
            progressThickness = Utility.clamp(progressThickness, minMax: (0, 1))
            progressLayer.progressThickness = progressThickness/2
        }
    }
    
    @IBInspectable public var trackThickness: CGFloat = 0.5 {//Between 0 and 1
        didSet {
            trackThickness = Utility.clamp(trackThickness, minMax: (0, 1))
            progressLayer.trackThickness = trackThickness/2
        }
    }
    
    @IBInspectable public var trackColor: UIColor = .blackColor() {
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
                progressLayer.progressInsideFillColor = .clearColor()
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
        setColors(.whiteColor(), .cyanColor())
    }
    
    private func refreshValues() {
        progressLayer.angle = angle
        progressLayer.startAngle = startAngle
        progressLayer.clockwise = clockwise
        progressLayer.roundedCorners = roundedCorners
        progressLayer.lerpColorMode = lerpColorMode
        progressLayer.gradientRotateSpeed = gradientRotateSpeed
        progressLayer.glowAmount = glowAmount
        progressLayer.glowMode = glowMode
        progressLayer.progressThickness = progressThickness/2
        progressLayer.trackColor = trackColor
        progressLayer.trackThickness = trackThickness/2
    }
    
    private func checkAndSetIBColors() {
        let nonNilColors = [IBColor1, IBColor2, IBColor3].flatMap { $0 }
        if !nonNilColors.isEmpty {
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
    
    public func animateFromAngle(fromAngle: Double, toAngle: Double, duration: NSTimeInterval, relativeDuration: Bool = true, completion: ((Bool) -> Void)?) {
        if isAnimating() {
            pauseAnimation()
        }
        
        let animationDuration: NSTimeInterval
        if relativeDuration {
            animationDuration = duration
        } else {
            let traveledAngle = Utility.mod(toAngle - fromAngle, range: 360, minMax: (0, 360))
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
    
    public func animateToAngle(toAngle: Double, duration: NSTimeInterval, relativeDuration: Bool = true, completion: ((Bool) -> Void)?) {
        if isAnimating() {
            pauseAnimation()
        }
        animateFromAngle(angle, toAngle: toAngle, duration: duration, relativeDuration: relativeDuration, completion: completion)
    }
    
    public func pauseAnimation() {
        guard let presentationLayer = progressLayer.presentationLayer() as? KDCircularProgressViewLayer else { return }
        let currentValue = presentationLayer.angle
        progressLayer.removeAllAnimations()
        animationCompletionBlock = nil
        angle = currentValue
    }
    
    public func stopAnimation() {
        animationCompletionBlock = nil
        progressLayer.removeAllAnimations()
        angle = 0
    }
    
    public func isAnimating() -> Bool {
        return progressLayer.animationForKey("angle") != nil
    }
    
    override public func animationDidStop(anim: CAAnimation, finished flag: Bool) {
        if let completionBlock = animationCompletionBlock {
            if flag {
               animationCompletionBlock = nil
            }
            
            completionBlock(flag)
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
        @NSManaged var angle: Double
        var radius: CGFloat! {
            didSet {
                invalidateGradientCache()
            }
        }
        var startAngle: Double!
        var clockwise: Bool! {
            didSet {
                if clockwise != oldValue {
                    invalidateGradientCache()
                }
            }
        }
        var roundedCorners: Bool!
        var lerpColorMode: Bool!
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
            static func glowAmountForAngle(angle: Double, glowAmount: CGFloat, glowMode: KDCircularProgressGlowMode, size: CGFloat) -> CGFloat {
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
            lerpColorMode = progressLayer.lerpColorMode
            gradientRotateSpeed = progressLayer.gradientRotateSpeed
            glowAmount = progressLayer.glowAmount
            glowMode = progressLayer.glowMode
            progressThickness = progressLayer.progressThickness
            trackThickness = progressLayer.trackThickness
            trackColor = progressLayer.trackColor
            colorsArray = progressLayer.colorsArray
            progressInsideFillColor = progressLayer.progressInsideFillColor
        }
        
        override init() {
            super.init()
        }
        
        required init?(coder aDecoder: NSCoder) {
            super.init(coder: aDecoder)
        }
        
        override func drawInContext(ctx: CGContext) {
            UIGraphicsPushContext(ctx)
            
            let size = bounds.size
            let width = size.width
            let height = size.height
            
            let trackLineWidth = radius * trackThickness
            let progressLineWidth = radius * progressThickness
            let arcRadius = max(radius - trackLineWidth/2, radius - progressLineWidth/2)
            CGContextAddArc(ctx, width/2.0, height/2.0, arcRadius, 0, CGFloat(M_PI * 2), 0)
            trackColor.set()
            CGContextSetStrokeColorWithColor(ctx, trackColor.CGColor)
            CGContextSetFillColorWithColor(ctx, progressInsideFillColor.CGColor)
            CGContextSetLineWidth(ctx, trackLineWidth)
            CGContextSetLineCap(ctx, CGLineCap.Butt)
            CGContextDrawPath(ctx, .FillStroke)
            
            UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
            
            let imageCtx = UIGraphicsGetCurrentContext()
            let reducedAngle = Utility.mod(angle, range: 360, minMax: (0, 360))
            let fromAngle = Conversion.degreesToRadians(CGFloat(-startAngle))
            let toAngle = Conversion.degreesToRadians(CGFloat((clockwise == true ? -reducedAngle : reducedAngle) - startAngle))
            
            CGContextAddArc(imageCtx, width/2.0, height/2.0, arcRadius, fromAngle, toAngle, clockwise == true ? 1 : 0)
            
            let glowValue = GlowConstants.glowAmountForAngle(reducedAngle, glowAmount: glowAmount, glowMode: glowMode, size: width)
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
            if !lerpColorMode && colorsArray.count > 1 {
                let rgbColorsArray: [UIColor] = colorsArray.map { color in // Make sure every color in colors array is in RGB color space
                    if CGColorGetNumberOfComponents(color.CGColor) == 2 {
                        let whiteValue = CGColorGetComponents(color.CGColor)[0]
                        return UIColor(red: whiteValue, green: whiteValue, blue: whiteValue, alpha: 1.0)
                    } else {
                        return color
                    }
                }
                
                let componentsArray = rgbColorsArray.flatMap { color -> [CGFloat] in
                    let components: UnsafePointer<CGFloat> = CGColorGetComponents(color.CGColor)
                    return [components[0], components[1], components[2], 1.0]
                }
                
                drawGradientWithContext(ctx, componentsArray: componentsArray)
            } else {
                var color: UIColor?
                if colorsArray.isEmpty {
                    color = UIColor.whiteColor()
                } else if colorsArray.count == 1 {
                    color = colorsArray[0]
                } else {
                    // lerpColorMode is true
                    let t = CGFloat(reducedAngle) / 360
                    let steps = colorsArray.count - 1
                    let step = 1 / CGFloat(steps)
                    for i in 1...steps {
                        let fi = CGFloat(i)
                        if (t <= fi * step || i == steps) {
                            let colorT = Utility.inverseLerp(t, minMax: ((fi - 1) * step, fi * step))
                            color = Utility.colorLerp(colorT, minMax: (colorsArray[i - 1], colorsArray[i]))
                            break
                        }
                    }
                }
                
                if let color = color {
                    fillRectWithContext(ctx, color: color)
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
            let locations = locationsCache ?? gradientLocationsForColorCount(componentsArray.count/4, gradientWidth: bounds.size.width)
            let gradient: CGGradient
            
            if let cachedGradient = gradientCache {
                gradient = cachedGradient
            } else {
                guard let cachedGradient = CGGradientCreateWithColorComponents(baseSpace, componentsArray, locations,componentsArray.count / 4) else {
                    return
                }
                
                gradientCache = cachedGradient
                gradient = cachedGradient
            }
            
            let halfX = bounds.size.width / 2.0
            let floatPi = CGFloat(M_PI)
            let rotateSpeed = clockwise == true ? gradientRotateSpeed : gradientRotateSpeed * -1
            let angleInRadians = Conversion.degreesToRadians(rotateSpeed * CGFloat(angle) - 90)
            let oppositeAngle = angleInRadians > floatPi ? angleInRadians - floatPi : angleInRadians + floatPi
            
            let startPoint = CGPoint(x: (cos(angleInRadians) * halfX) + halfX, y: (sin(angleInRadians) * halfX) + halfX)
            let endPoint = CGPoint(x: (cos(oppositeAngle) * halfX) + halfX, y: (sin(oppositeAngle) * halfX) + halfX)
            
            CGContextDrawLinearGradient(ctx, gradient, startPoint, endPoint, .DrawsBeforeStartLocation)
        }
        
        private func gradientLocationsForColorCount(colorCount: Int, gradientWidth: CGFloat) -> [CGFloat] {
            if colorCount == 0 || gradientWidth == 0 {
                return []
            } else {
                let progressLineWidth = radius * progressThickness
                let firstPoint = gradientWidth/2 - (radius - progressLineWidth/2)
                let increment = (gradientWidth - (2*firstPoint))/CGFloat(colorCount - 1)
                
                let locationsArray = (0..<colorCount).map { firstPoint + (CGFloat($0) * increment) }
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
