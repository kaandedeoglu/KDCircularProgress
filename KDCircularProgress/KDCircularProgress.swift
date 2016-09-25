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
public class KDCircularProgress: UIView, CAAnimationDelegate {
    
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
            let clampedValue = clamp(value: value, minMax: (0, 1))
            
            let zero: CGFloat = 0
            
            var (r0, g0, b0, a0) = (zero, zero, zero, zero)
            minMax.0.getRed(&r0, green: &g0, blue: &b0, alpha: &a0)
            
            var (r1, g1, b1, a1) = (zero, zero, zero, zero)
            minMax.1.getRed(&r1, green: &g1, blue: &b1, alpha: &a1)
            
            return UIColor(red: lerp(value: clampedValue, minMax: (r0, r1)), green: lerp(value: clampedValue, minMax: (g0, g1)), blue: lerp(value: clampedValue, minMax: (b0, b1)), alpha: lerp(value: clampedValue, minMax: (a0, a1)))
        }
        
        static func mod(value: Double, range: Double, minMax: (Double, Double)) -> Double {
            let (min, max) = minMax
            assert(abs(range) <= abs(max - min), "range should be <= than the interval")
            if value >= min && value <= max {
                return value
            } else if value < min {
                return mod(value: value + range, range: range, minMax: minMax)
            } else {
                return mod(value: value - range, range: range, minMax: minMax)
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
            startAngle = Utility.mod(value: startAngle, range: 360, minMax: (0, 360))
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
            glowAmount = Utility.clamp(value: glowAmount, minMax: (0, 1))
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
            progressThickness = Utility.clamp(value: progressThickness, minMax: (0, 1))
            progressLayer.progressThickness = progressThickness/2
        }
    }
    
    @IBInspectable public var trackThickness: CGFloat = 0.5 {//Between 0 and 1
        didSet {
            trackThickness = Utility.clamp(value: trackThickness, minMax: (0, 1))
            progressLayer.trackThickness = trackThickness/2
        }
    }
    
    @IBInspectable public var trackColor: UIColor = .black {
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
                progressLayer.progressInsideFillColor = .clear
            }
        }
    }
    
    @IBInspectable public var progressColors: [UIColor]! {
        get {
            return progressLayer.colorsArray
        }
        
        set(newValue) {
            setColors(colors: newValue)
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
        isUserInteractionEnabled = false
        setInitialValues()
        refreshValues()
        checkAndSetIBColors()
    }
    
    convenience public init(frame:CGRect, colors: UIColor...) {
        self.init(frame: frame)
        setColors(colors: colors)
    }
    
    required public init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)!
        translatesAutoresizingMaskIntoConstraints = false
        isUserInteractionEnabled = false
        setInitialValues()
        refreshValues()
    }
    
    public override func awakeFromNib() {
        checkAndSetIBColors()
    }
    
    override public class var layerClass: AnyClass {
        return KDCircularProgressViewLayer.self
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        radius = (frame.size.width/2.0) * 0.8
    }
    
    private func setInitialValues() {
        radius = (frame.size.width/2.0) * 0.8 //We always apply a 20% padding, stopping glows from being clipped
        backgroundColor = .clear
        setColors(colors: [.white, .cyan])
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
            setColors(colors: nonNilColors)
        }
    }
    
    public func setColors(colors: UIColor...) {
        setColors(colors: colors)
    }
    
    private func setColors(colors: [UIColor]) {
        progressLayer.colorsArray = colors
        progressLayer.setNeedsDisplay()
    }
    
    public func animateFromAngle(fromAngle: Double, toAngle: Double, duration: TimeInterval, relativeDuration: Bool = true, completion: ((Bool) -> Void)?) {
        if isAnimating() {
            pauseAnimation()
        }
        
        let animationDuration: TimeInterval
        if relativeDuration {
            animationDuration = duration
        } else {
            let traveledAngle = Utility.mod(value: toAngle - fromAngle, range: 360, minMax: (0, 360))
            let scaledDuration = (TimeInterval(traveledAngle) * duration) / 360
            animationDuration = scaledDuration
        }
        
        let animation = CABasicAnimation(keyPath: "angle")
        animation.fromValue = fromAngle
        animation.toValue = toAngle
        animation.duration = animationDuration
        animation.delegate = self
        angle = toAngle
        animationCompletionBlock = completion
        
        progressLayer.add(animation, forKey: "angle")
    }
    
    public func animateToAngle(toAngle: Double, duration: TimeInterval, relativeDuration: Bool = true, completion: ((Bool) -> Void)?) {
        if isAnimating() {
            pauseAnimation()
        }
        animateFromAngle(fromAngle: angle, toAngle: toAngle, duration: duration, relativeDuration: relativeDuration, completion: completion)
    }
    
    public func pauseAnimation() {
        guard let presentationLayer = progressLayer.presentation() else { return }
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
        return progressLayer.animation(forKey: "angle") != nil
    }
    
    public func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
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
    
    public override func willMove(toSuperview newSuperview: UIView?) {
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
        var progressInsideFillColor: UIColor = UIColor.clear
        var colorsArray: [UIColor]! {
            didSet {
                invalidateGradientCache()
            }
        }
        private var gradientCache: CGGradient?
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
        
        override class func needsDisplay(forKey key: String) -> Bool {
            return key == "angle" ? true : super.needsDisplay(forKey: key)
        }
        
        override init(layer: Any) {
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
        
        override func draw(in ctx: CGContext) {
            UIGraphicsPushContext(ctx)
            
            let size = bounds.size
            let width = size.width
            let height = size.height
            
            let trackLineWidth = radius * trackThickness
            let progressLineWidth = radius * progressThickness
            let arcRadius = max(radius - trackLineWidth/2, radius - progressLineWidth/2)
            ctx.addArc(center: CGPoint(x: width/2, y: height/2), radius: arcRadius, startAngle: 0, endAngle: CGFloat(M_PI * 2), clockwise: true)
            trackColor.set()
            ctx.setStrokeColor(trackColor.cgColor)
            ctx.setFillColor(progressInsideFillColor.cgColor)
            ctx.setLineWidth(trackLineWidth)
            ctx.setLineCap(CGLineCap.butt)
            ctx.drawPath(using: .fillStroke)
            
            UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
            let reducedAngle = Utility.mod(value: angle, range: 360, minMax: (0, 360))
            
            if let imageCtx = UIGraphicsGetCurrentContext(){
                let fromAngle = Conversion.degreesToRadians(value: CGFloat(-startAngle))
                let toAngle = Conversion.degreesToRadians(value: CGFloat((clockwise == true ? -reducedAngle : reducedAngle) - startAngle))
                
                imageCtx.addArc(center: CGPoint(x: width/2, y: height/2), radius: arcRadius, startAngle: fromAngle, endAngle: toAngle, clockwise: clockwise)
                
                let glowValue = GlowConstants.glowAmountForAngle(angle: reducedAngle, glowAmount: glowAmount, glowMode: glowMode, size: width)
                if glowValue > 0 {
                    imageCtx.setShadow(offset: .zero, blur: glowValue, color: UIColor.black.cgColor)
                }
                imageCtx.setLineCap(roundedCorners == true ? .round : .butt)
                imageCtx.drawPath(using: .stroke)
                
                guard let currentGraphicsContext = UIGraphicsGetCurrentContext() else{
                    return
                }
                
                if let drawMask: CGImage = currentGraphicsContext.makeImage(){
                    UIGraphicsEndImageContext()
                    ctx.saveGState()
                    ctx.clip(to: bounds, mask: drawMask)
                }else{
                    UIGraphicsEndImageContext()
                }
            }
            //Gradient - Fill
            if !lerpColorMode && colorsArray.count > 1 {
                let rgbColorsArray: [UIColor] = colorsArray.map { color in // Make sure every color in colors array is in RGB color space
                    if color.cgColor.numberOfComponents == 2 {
                        let whiteValue = color.cgColor.components?[0]
                        return UIColor(red: whiteValue!, green: whiteValue!, blue: whiteValue!, alpha: 1.0)
                    } else {
                        return color
                    }
                }
                
                let componentsArray = rgbColorsArray.flatMap { color -> [CGFloat] in
                    let components: [CGFloat] = color.cgColor.components!
                    return [components[0], components[1], components[2], 1.0]
                }
                
                drawGradientWithContext(ctx: ctx, componentsArray: componentsArray)
            } else {
                var color: UIColor?
                if colorsArray.isEmpty {
                    color = UIColor.white
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
                            let colorT = Utility.inverseLerp(value: t, minMax: ((fi - 1) * step, fi * step))
                            color = Utility.colorLerp(value: colorT, minMax: (colorsArray[i - 1], colorsArray[i]))
                            break
                        }
                    }
                }
                
                if let color = color {
                    fillRectWithContext(ctx: ctx, color: color)
                }
            }
            ctx.restoreGState()
            UIGraphicsPopContext()
        }
        
        private func fillRectWithContext(ctx: CGContext!, color: UIColor) {
            ctx.setFillColor(color.cgColor)
            ctx.fill(bounds)
        }
        
        private func drawGradientWithContext(ctx: CGContext!, componentsArray: [CGFloat]) {
            let baseSpace = CGColorSpaceCreateDeviceRGB()
            let locations = locationsCache ?? gradientLocationsForColorCount(colorCount: componentsArray.count/4, gradientWidth: bounds.size.width)
            let gradient: CGGradient
            
            if let cachedGradient = gradientCache {
                gradient = cachedGradient
            } else {
                guard let cachedGradient = CGGradient(colorSpace: baseSpace, colorComponents: componentsArray, locations: locations, count: componentsArray.count / 4) else {
                    return
                }
                
                gradientCache = cachedGradient
                gradient = cachedGradient
            }
            
            let halfX = bounds.size.width / 2.0
            let floatPi = CGFloat(M_PI)
            let rotateSpeed = clockwise == true ? gradientRotateSpeed : gradientRotateSpeed * -1
            let angleInRadians = Conversion.degreesToRadians(value: rotateSpeed! * CGFloat(angle) - 90)
            let oppositeAngle = angleInRadians > floatPi ? angleInRadians - floatPi : angleInRadians + floatPi
            
            let startPoint = CGPoint(x: (cos(angleInRadians) * halfX) + halfX, y: (sin(angleInRadians) * halfX) + halfX)
            let endPoint = CGPoint(x: (cos(oppositeAngle) * halfX) + halfX, y: (sin(oppositeAngle) * halfX) + halfX)
            
            ctx.drawLinearGradient(gradient, start: startPoint, end: endPoint, options: .drawsBeforeStartLocation)
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

