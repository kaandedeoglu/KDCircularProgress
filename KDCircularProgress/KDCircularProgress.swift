//
//  KDCircularProgress.swift
//  KDCircularProgress
//
//  Created by Kaan Dedeoglu on 1/14/15.
//  Copyright (c) 2015 Kaan Dedeoglu. All rights reserved.
//

import UIKit

public enum KDCircularProgressGlowMode {
    case forward, reverse, constant, noGlow
}

@IBDesignable
public class KDCircularProgress: UIView, CAAnimationDelegate {
    
    private enum Conversion {
        static func degreesToRadians (value:CGFloat) -> CGFloat {
            return value * CGFloat.pi / 180.0
        }
    }
    
    private enum Utility {
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
            
            let zero = CGFloat(0)
            
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
    
    private var radius: CGFloat = 0 {
        didSet {
            progressLayer.radius = radius
        }
    }
    
    public var progress: Double = 0 {
        didSet {
            let clampedProgress = Utility.clamp(value: progress, minMax: (0, 1))
                angle = 360 * clampedProgress
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
    
    @IBInspectable public var glowMode: KDCircularProgressGlowMode = .forward {
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
            progressLayer.progressInsideFillColor = progressInsideFillColor ?? .clear
        }
    }
    
    public var progressColors: [UIColor] {
        get {
            return progressLayer.colorsArray
        }
        
        set {
            set(colors: newValue)
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
        setInitialValues()
        refreshValues()
        checkAndSetIBColors()
    }
    
    convenience public init(frame:CGRect, colors: UIColor...) {
        self.init(frame: frame)
        set(colors: colors)
    }
    
    required public init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)!
        translatesAutoresizingMaskIntoConstraints = false
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
        set(colors: .white, .cyan)
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
            set(colors: nonNilColors)
        }
    }
    
    public func set(colors: UIColor...) {
        set(colors: colors)
    }
    
    private func set(colors: [UIColor]) {
        progressLayer.colorsArray = colors
        progressLayer.setNeedsDisplay()
    }
    
    public func animate(fromAngle: Double, toAngle: Double, duration: TimeInterval, relativeDuration: Bool = true, completion: ((Bool) -> Void)?) {
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
        animation.isRemovedOnCompletion = false
        angle = toAngle
        animationCompletionBlock = completion
        
        progressLayer.add(animation, forKey: "angle")
    }
    
    public func animate(toAngle: Double, duration: TimeInterval, relativeDuration: Bool = true, completion: ((Bool) -> Void)?) {
        if isAnimating() {
            pauseAnimation()
        }
        animate(fromAngle: angle, toAngle: toAngle, duration: duration, relativeDuration: relativeDuration, completion: completion)
    }
    
    public func pauseAnimation() {
        guard let presentationLayer = progressLayer.presentation() else { return }
        
        let currentValue = presentationLayer.angle
        progressLayer.removeAllAnimations()
        angle = currentValue
    }
    
    public func stopAnimation() {
        progressLayer.removeAllAnimations()
        angle = 0
    }
    
    public func isAnimating() -> Bool {
        return progressLayer.animation(forKey: "angle") != nil
    }
    
    public func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
        if let completionBlock = animationCompletionBlock {
            animationCompletionBlock = nil
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
        var radius: CGFloat = 0 {
            didSet {
                invalidateGradientCache()
            }
        }
        var startAngle: Double = 0
        var clockwise: Bool = true {
            didSet {
                if clockwise != oldValue {
                    invalidateGradientCache()
                }
            }
        }
        var roundedCorners: Bool = true
        var lerpColorMode: Bool = false
        var gradientRotateSpeed: CGFloat = 0 {
            didSet {
                invalidateGradientCache()
            }
        }
        var glowAmount: CGFloat = 0
        var glowMode: KDCircularProgressGlowMode = .forward
        var progressThickness: CGFloat = 0.5
        var trackThickness: CGFloat = 0.5
        var trackColor: UIColor = .black
        var progressInsideFillColor: UIColor = .clear
        var colorsArray: [UIColor] = [] {
            didSet {
                invalidateGradientCache()
            }
        }
        private var gradientCache: CGGradient?
        private var locationsCache: [CGFloat]?
        
        private enum GlowConstants {
            private static let sizeToGlowRatio: CGFloat = 0.00015
            static func glowAmount(forAngle angle: Double, glowAmount: CGFloat, glowMode: KDCircularProgressGlowMode, size: CGFloat) -> CGFloat {
                switch glowMode {
                case .forward:
                    return CGFloat(angle) * size * sizeToGlowRatio * glowAmount
                case .reverse:
                    return CGFloat(360 - angle) * size * sizeToGlowRatio * glowAmount
                case .constant:
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
            ctx.addArc(center: CGPoint(x: width/2.0, y: height/2.0), radius: arcRadius, startAngle: 0, endAngle: CGFloat.pi * 2, clockwise: false)
            trackColor.set()
            ctx.setStrokeColor(trackColor.cgColor)
            ctx.setFillColor(progressInsideFillColor.cgColor)
            ctx.setLineWidth(trackLineWidth)
            ctx.setLineCap(CGLineCap.butt)
            ctx.drawPath(using: .fillStroke)
            
            UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
            
            let imageCtx = UIGraphicsGetCurrentContext()
            let reducedAngle = Utility.mod(value: angle, range: 360, minMax: (0, 360))
            let fromAngle = Conversion.degreesToRadians(value: CGFloat(-startAngle))
            let toAngle = Conversion.degreesToRadians(value: CGFloat((clockwise == true ? -reducedAngle : reducedAngle) - startAngle))
            
            imageCtx?.addArc(center: CGPoint(x: width/2.0, y: height/2.0), radius: arcRadius, startAngle: fromAngle, endAngle: toAngle, clockwise: clockwise)
            
            let glowValue = GlowConstants.glowAmount(forAngle: reducedAngle, glowAmount: glowAmount, glowMode: glowMode, size: width)
            if glowValue > 0 {
                imageCtx?.setShadow(offset: CGSize.zero, blur: glowValue, color: UIColor.black.cgColor)
            }
            
            let linecap: CGLineCap = roundedCorners == true ? .round : .butt
            imageCtx?.setLineCap(linecap)
            imageCtx?.setLineWidth(progressLineWidth)
            imageCtx?.drawPath(using: .stroke)
            
            let drawMask: CGImage = UIGraphicsGetCurrentContext()!.makeImage()!
            UIGraphicsEndImageContext()
            
            ctx.saveGState()
            ctx.clip(to: bounds, mask: drawMask)
            
            //Gradient - Fill
            if !lerpColorMode && colorsArray.count > 1 {
                let rgbColorsArray: [UIColor] = colorsArray.map { color in // Make sure every color in colors array is in RGB color space
                    if color.cgColor.numberOfComponents == 2 {
                        if let whiteValue = color.cgColor.components?[0] {
                            return UIColor(red: whiteValue, green: whiteValue, blue: whiteValue, alpha: 1.0)
                        } else {
                            return UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
                        }
                    } else {
                        return color
                    }
                }
                
                let componentsArray = rgbColorsArray.flatMap { color -> [CGFloat] in
                    guard let components = color.cgColor.components else { return [] }
                    return [components[0], components[1], components[2], 1.0]
                }
                
                drawGradientWith(context: ctx, componentsArray: componentsArray)
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
                    fillRectWith(context: ctx, color: color)
                }
            }
            ctx.restoreGState()
            UIGraphicsPopContext()
        }
        
        private func fillRectWith(context: CGContext!, color: UIColor) {
            context.setFillColor(color.cgColor)
            context.fill(bounds)
        }
        
        private func drawGradientWith(context: CGContext!, componentsArray: [CGFloat]) {
            let baseSpace = CGColorSpaceCreateDeviceRGB()
            let locations = locationsCache ?? gradientLocationsFor(colorCount: componentsArray.count/4, gradientWidth: bounds.size.width)
            let gradient: CGGradient
            
            if let cachedGradient = gradientCache {
                gradient = cachedGradient
            } else {
                guard let cachedGradient = CGGradient(colorSpace: baseSpace, colorComponents: componentsArray, locations: locations, count: componentsArray.count/4) else {
                    return
                }
                
                gradientCache = cachedGradient
                gradient = cachedGradient
            }
            
            let halfX = bounds.size.width / 2.0
            let floatPi = CGFloat.pi
            let rotateSpeed = clockwise == true ? gradientRotateSpeed : gradientRotateSpeed * -1
            let angleInRadians = Conversion.degreesToRadians(value: rotateSpeed * CGFloat(angle) - 90)
            let oppositeAngle = angleInRadians > floatPi ? angleInRadians - floatPi : angleInRadians + floatPi
            
            let startPoint = CGPoint(x: (cos(angleInRadians) * halfX) + halfX, y: (sin(angleInRadians) * halfX) + halfX)
            let endPoint = CGPoint(x: (cos(oppositeAngle) * halfX) + halfX, y: (sin(oppositeAngle) * halfX) + halfX)
            
            context.drawLinearGradient(gradient, start: startPoint, end: endPoint, options: .drawsBeforeStartLocation)
        }
        
        private func gradientLocationsFor(colorCount: Int, gradientWidth: CGFloat) -> [CGFloat] {
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
