//
//  KDCircularProgress.swift
//  KDCircularProgress
//
//  Copyright (c) 2019 Kaan Dedeoglu. All rights reserved.
//

import UIKit

@objc public enum KDCircularProgressGlowMode: Int {
    case forward, reverse, constant, noGlow
}

@IBDesignable
@objcMembers
public class KDCircularProgress: UIView, CAAnimationDelegate {
    private var progressLayer: KDCircularProgressViewLayer {
        get {
            return layer as! KDCircularProgressViewLayer
        }
    }
    
    private var radius: CGFloat = 0.0 {
        didSet {
            progressLayer.radius = radius
        }
    }
    
    public var progress: Double {
        get { return angle.mod(between: 0.0, and: 360.0, byIncrementing: 360.0) / 360.0 }
        set { angle = newValue.clamp(lowerBound: 0.0, upperBound: 1.0) * 360.0 }
    }
    
    @IBInspectable public var angle: Double = 0.0 {
        didSet {
            pauseIfAnimating()
            progressLayer.angle = angle
        }
    }
    
    @IBInspectable public var startAngle: Double = 0.0 {
        didSet {
            startAngle = startAngle.mod(between: 0.0, and: 360.0, byIncrementing: 360.0)
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
    
    @IBInspectable public var gradientRotateSpeed: CGFloat = 0.0 {
        didSet {
            progressLayer.gradientRotateSpeed = gradientRotateSpeed
        }
    }
    
    @IBInspectable public var glowAmount: CGFloat = 1.0 {
        didSet {
            glowAmount = glowAmount.clamp(lowerBound: 0.0, upperBound: 1.0)
            progressLayer.glowAmount = glowAmount
        }
    }
    
    public var glowMode: KDCircularProgressGlowMode = .forward {
        didSet {
            progressLayer.glowMode = glowMode
        }
    }
    
    @IBInspectable public var progressThickness: CGFloat = 0.4 {
        didSet {
            progressThickness = progressThickness.clamp(lowerBound: 0.0, upperBound: 1.0)
            progressLayer.progressThickness = progressThickness / 2.0
        }
    }
    
    @IBInspectable public var trackThickness: CGFloat = 0.5 {//Between 0 and 1
        didSet {
            trackThickness = trackThickness.clamp(lowerBound: 0.0, upperBound: 1.0)
            progressLayer.trackThickness = trackThickness / 2.0
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
        get { return progressLayer.colorsArray }
        set { set(colors: newValue) }
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
    }
    
    convenience public init(frame:CGRect, colors: UIColor...) {
        self.init(frame: frame)
        set(colors: colors)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
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
        radius = (frame.size.width / 2.0) * 0.8
    }
    
    private func setInitialValues() {
        radius = (frame.size.width / 2.0) * 0.8 //We always apply a 20% padding, stopping glows from being clipped
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
        progressLayer.progressThickness = progressThickness / 2.0
        progressLayer.trackColor = trackColor
        progressLayer.trackThickness = trackThickness / 2.0
    }
    
    private func checkAndSetIBColors() {
        let IBColors = [IBColor1, IBColor2, IBColor3].compactMap { $0 }
        if IBColors.isEmpty == false {
            set(colors: IBColors)
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
        pauseIfAnimating()
        let animationDuration: TimeInterval
        if relativeDuration {
            animationDuration = duration
        } else {
            let traveledAngle = (toAngle - fromAngle).mod(between: 0.0, and: 360.0, byIncrementing: 360.0)
            let scaledDuration = TimeInterval(traveledAngle) * duration / 360.0
            animationDuration = scaledDuration
        }
        
        let animation = CABasicAnimation(keyPath: #keyPath(KDCircularProgressViewLayer.angle))
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
        pauseIfAnimating()
        animate(fromAngle: angle, toAngle: toAngle, duration: duration, relativeDuration: relativeDuration, completion: completion)
    }
    
    public func pauseAnimation() {
        guard let presentationLayer = progressLayer.presentation() else { return }
        
        let currentValue = presentationLayer.angle
        progressLayer.removeAllAnimations()
        angle = currentValue
    }
    
    private func pauseIfAnimating() {
        if isAnimating() {
            pauseAnimation()
        }
    }
    
    public func stopAnimation() {
        progressLayer.removeAllAnimations()
        angle = 0
    }
    
    public func isAnimating() -> Bool {
        return progressLayer.animation(forKey: "angle") != nil
    }
    
    public func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
        animationCompletionBlock?(flag)
        animationCompletionBlock = nil
    }
    
    public override func didMoveToWindow() {
        window.map { progressLayer.contentsScale = $0.screen.scale }
    }
    
    public override func willMove(toSuperview newSuperview: UIView?) {
        if newSuperview == nil {
            pauseIfAnimating()
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
        var radius: CGFloat = 0.0 {
            didSet { invalidateGradientCache() }
        }
        var startAngle: Double = 0.0
        var clockwise: Bool = true {
            didSet {
                if clockwise != oldValue {
                    invalidateGradientCache()
                }
            }
        }
        var roundedCorners: Bool = true
        var lerpColorMode: Bool = false
        var gradientRotateSpeed: CGFloat = 0.0 {
            didSet { invalidateGradientCache() }
        }
        var glowAmount: CGFloat = 0.0
        var glowMode: KDCircularProgressGlowMode = .forward
        var progressThickness: CGFloat = 0.5
        var trackThickness: CGFloat = 0.5
        var trackColor: UIColor = .black
        var progressInsideFillColor: UIColor = .clear
        var colorsArray: [UIColor] = [] {
            didSet { invalidateGradientCache() }
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
                    return CGFloat(360.0 - angle) * size * sizeToGlowRatio * glowAmount
                case .constant:
                    return 360.0 * size * sizeToGlowRatio * glowAmount
                default:
                    return 0
                }
            }
        }
        
        override class func needsDisplay(forKey key: String) -> Bool {
            if key == #keyPath(angle) {
                return true
            }
            return super.needsDisplay(forKey: key)
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
            let arcRadius = max(radius - trackLineWidth / 2.0, radius - progressLineWidth / 2.0)
            ctx.addArc(center: CGPoint(x: width / 2.0, y: height / 2.0),
                       radius: arcRadius,
                       startAngle: 0,
                       endAngle: CGFloat.pi * 2,
                       clockwise: false)
            ctx.setStrokeColor(trackColor.cgColor)
            ctx.setFillColor(progressInsideFillColor.cgColor)
            ctx.setLineWidth(trackLineWidth)
            ctx.setLineCap(CGLineCap.butt)
            ctx.drawPath(using: .fillStroke)
            
            UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
            
            let imageCtx = UIGraphicsGetCurrentContext()
            let canonicalAngle = angle.mod(between: 0.0, and: 360.0, byIncrementing: 360.0)
            let fromAngle = -startAngle.radians
            let toAngle: Double
            if clockwise {
                toAngle = (-canonicalAngle - startAngle).radians
            } else {
                toAngle = (canonicalAngle - startAngle).radians
            }
            
            imageCtx?.addArc(center: CGPoint(x: width / 2.0, y: height / 2.0),
                             radius: arcRadius,
                             startAngle: CGFloat(fromAngle),
                             endAngle: CGFloat(toAngle),
                             clockwise: clockwise)
            
            let glowValue = GlowConstants.glowAmount(forAngle: canonicalAngle, glowAmount: glowAmount, glowMode: glowMode, size: width)
            if glowValue > 0 {
                imageCtx?.setShadow(offset: .zero, blur: glowValue, color: UIColor.black.cgColor)
            }
            
            let linecap: CGLineCap = roundedCorners ? .round : .butt
            imageCtx?.setLineCap(linecap)
            imageCtx?.setLineWidth(progressLineWidth)
            imageCtx?.drawPath(using: .stroke)
            
            let drawMask: CGImage = UIGraphicsGetCurrentContext()!.makeImage()!
            UIGraphicsEndImageContext()
            
            ctx.saveGState()
            ctx.clip(to: bounds, mask: drawMask)
            
            if colorsArray.isEmpty {
                fillRect(withContext: ctx, color: .white)
            } else if colorsArray.count == 1 {
                fillRect(withContext: ctx, color: colorsArray[0])
            } else if lerpColorMode {
                lerp(withContext: ctx, colorsArray: colorsArray)
            } else {
                drawGradient(withContext: ctx, colorsArray: colorsArray)
            }

            ctx.restoreGState()
            UIGraphicsPopContext()
        }
        
        private func lerp(withContext context: CGContext, colorsArray: [UIColor]) {
            let canonicalAngle = angle.mod(between: 0.0, and: 360.0, byIncrementing: 360.0)
            let percentage = canonicalAngle / 360.0
            let steps = colorsArray.count - 1
            let step = 1.0 / Double(steps)
            
            for i in 1...steps {
                let di = Double(i)
                if percentage <= di * step || i == steps {
                    let colorT = percentage.inverseLerp(min: (di - 1) * step, max: di * step)
                    let color = colorT.colorLerp(minColor: colorsArray[i - 1], maxColor: colorsArray[i])
                    fillRect(withContext: context, color: color)
                    break
                }
            }
        }
        
        private func fillRect(withContext context: CGContext, color: UIColor) {
            context.setFillColor(color.cgColor)
            context.fill(bounds)
        }
        
        private func drawGradient(withContext context: CGContext, colorsArray: [UIColor]) {
            let baseSpace = CGColorSpaceCreateDeviceRGB()
            let locations = locationsCache ?? gradientLocationsFor(colorCount: colorsArray.count, gradientWidth: bounds.size.width)
            let gradient: CGGradient
            
            if let cachedGradient = gradientCache {
                gradient = cachedGradient
            } else {
                guard let newGradient = CGGradient(colorSpace: baseSpace, colorComponents: colorsArray.rgbNormalized.componentsJoined,
                                                   locations: locations, count: colorsArray.count) else { return }
                
                gradientCache = newGradient
                gradient = newGradient
            }
            
            let halfX = bounds.size.width / 2.0
            let floatPi = CGFloat.pi
            let rotateSpeed = clockwise == true ? gradientRotateSpeed : gradientRotateSpeed * -1.0
            let angleInRadians = (rotateSpeed * CGFloat(angle) - 90.0).radians
            let oppositeAngle = angleInRadians > floatPi ? angleInRadians - floatPi : angleInRadians + floatPi
            
            let startPoint = CGPoint(x: (cos(angleInRadians) * halfX) + halfX, y: (sin(angleInRadians) * halfX) + halfX)
            let endPoint = CGPoint(x: (cos(oppositeAngle) * halfX) + halfX, y: (sin(oppositeAngle) * halfX) + halfX)
            
            context.drawLinearGradient(gradient, start: startPoint, end: endPoint, options: .drawsBeforeStartLocation)
        }
        
        private func gradientLocationsFor(colorCount: Int, gradientWidth: CGFloat) -> [CGFloat] {
            guard colorCount > 0, gradientWidth > 0 else { return [] }

            let progressLineWidth = radius * progressThickness
            let firstPoint = gradientWidth / 2.0 - (radius - progressLineWidth / 2.0)
            let increment = (gradientWidth - (2.0 * firstPoint)) / CGFloat(colorCount - 1)
            
            let locationsArray = (0..<colorCount).map { firstPoint + (CGFloat($0) * increment) }
            let result = locationsArray.map { $0 / gradientWidth }
            locationsCache = result
            return result
        }
        
        private func invalidateGradientCache() {
            gradientCache = nil
            locationsCache = nil
        }
    }
}

//Some helper extensions below

private extension Array where Element == UIColor {
    // Make sure every color in colors array is in RGB color space
    var rgbNormalized: [UIColor] {
        return map { color in
            guard color.cgColor.numberOfComponents == 2 else {
                return color
            }
            
            let white: CGFloat = color.cgColor.components![0]
            return UIColor(red: white, green: white, blue: white, alpha: 1.0)
        }
    }
    
    var componentsJoined: [CGFloat] {
        return flatMap { $0.cgColor.components ?? [] }
    }
}

private extension Comparable {
    func clamp(lowerBound: Self, upperBound: Self) -> Self {
        return min(max(self, lowerBound), upperBound)
    }
}

private extension FloatingPoint {
    var radians: Self {
        return self * .pi / Self(180)
    }
    
    func mod(between left: Self, and right: Self, byIncrementing interval: Self) -> Self {
        assert(interval > 0)
        assert(interval <= right - left)
        assert(right > left)
        
        if self >= left, self <= right {
            return self
        } else if self < left {
            return (self + interval).mod(between: left, and: right, byIncrementing: interval)
        } else {
            return (self - interval).mod(between: left, and: right, byIncrementing: interval)
        }
    }
}

private extension BinaryFloatingPoint {
    func inverseLerp(min: Self, max: Self) -> Self {
        return (self - min) / (max - min)
    }
    
    func lerp(min: Self, max: Self) -> Self {
        return (max - min) * self + min
    }
    
    func colorLerp(minColor: UIColor, maxColor: UIColor) -> UIColor {
        let clampedValue = CGFloat(self.clamp(lowerBound: 0.0, upperBound: 1.0))
        let zero = CGFloat(0.0)
        
        
        var (r0, g0, b0, a0) = (zero, zero, zero, zero)
        minColor.getRed(&r0, green: &g0, blue: &b0, alpha: &a0)
        
        var (r1, g1, b1, a1) = (zero, zero, zero, zero)
        maxColor.getRed(&r1, green: &g1, blue: &b1, alpha: &a1)
        
        return UIColor(red: clampedValue.lerp(min: r0, max: r1),
                       green: clampedValue.lerp(min: g0, max: g1),
                       blue: clampedValue.lerp(min: b0, max: b1),
                       alpha: clampedValue.lerp(min: a0, max: a1))
    }
}
