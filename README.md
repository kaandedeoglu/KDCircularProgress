# KDCircularProgress

[![Version](https://img.shields.io/cocoapods/v/KDCircularProgress.svg?style=flat)](http://cocoapods.org/pods/KDCircularProgress)
[![License](https://img.shields.io/cocoapods/l/KDCircularProgress.svg?style=flat)](http://cocoapods.org/pods/KDCircularProgress)
[![Platform](https://img.shields.io/cocoapods/p/KDCircularProgress.svg?style=flat)](http://cocoapods.org/pods/KDCircularProgress)

>
`KDCircularProgress` master branch is now compatible with Swift 3 (tag 1.5.2). Check Swift 2 (tag 1.4.1) & Swift 2.3 (tag 1.4.5) branches for older versions.


`KDCircularProgress` is a circular progress view written in Swift. It makes it possible to have gradients in the progress view, along with glows and animations.

KDCircularProgress also has `IBInspectable` and `IBDesignable` support, so you can configure and preview inside the `Interface Builder`. 


Here's an example

[Youtube Link](http://youtu.be/iIdas72MXOg)


![Screenshot](https://raw.githubusercontent.com/kaandedeoglu/KDCircularProgress/master/Assets/screenshot.gif)

![Screenshot](https://raw.githubusercontent.com/kaandedeoglu/KDCircularProgress/master/Assets/screenshot.png)
![Screenshot](https://raw.githubusercontent.com/kaandedeoglu/KDCircularProgress/master/Assets/screenshot2.jpg)
![Screenshot](https://raw.githubusercontent.com/kaandedeoglu/KDCircularProgress/master/Assets/screenshot3.jpg)
![Screenshot](https://raw.githubusercontent.com/kaandedeoglu/KDCircularProgress/master/Assets/screenshot4.jpg)
![Screenshot](https://raw.githubusercontent.com/kaandedeoglu/KDCircularProgress/master/Assets/screenshot5.jpg)
![Screenshot](https://raw.githubusercontent.com/kaandedeoglu/KDCircularProgress/master/Assets/screenshot6.jpg)
![Screenshot](https://raw.githubusercontent.com/kaandedeoglu/KDCircularProgress/master/Assets/screenshot7.jpg)

```swift
progress = KDCircularProgress(frame: CGRect(x: 0, y: 0, width: 300, height: 300))
progress.startAngle = -90
progress.progressThickness = 0.2
progress.trackThickness = 0.6
progress.clockwise = true
progress.gradientRotateSpeed = 2
progress.roundedCorners = false
progress.glowMode = .forward
progress.glowAmount = 0.9
progress.set(colors: UIColor.cyan ,UIColor.white, UIColor.magenta, UIColor.white, UIColor.orange)
progress.center = CGPoint(x: view.center.x, y: view.center.y + 25)
view.addSubview(progress)
```

## Installation
- It's on CocoaPods under the name (you guessed it!) KDCircularProgress
- Just drag `KDCircularProgress.swift` into your project. `Carthage` support is on To-do list.

### CocoaPods

KDCircularProgress is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod 'KDCircularProgress'
```

### Manually

Just drag `KDCircularProgress.swift` into your project.

### Carthage

`Carthage` support is on To-do list.


## Properties

####progressColors: `[UIColor]`
The colors used to generate the gradient of the progress. You can also set this using the variadic `setColors(UIColor...)` method. A gradient is used only if there is more than one color. A fill is used otherwise. The default is a white fill.

------

####angle: `Int`
The angle of the progress. Between 0 and 360 (inclusive). Simply change its value in order to change the visual progress of the component. Default is 0.

------

####startAngle: `Int`
The angle at which the progress will begin. Between 0 and 360 (inclusive), however you can pass any negative or positive values and the component will mod them automatically to the required range. Default is 0.

------

####clockwise: `Bool`
Clockwise if true, Counter-clockwise if false. Default is true.

------

####roundedCorners: `Bool`
When true, the ends of the progress track will be drawn with a half circle radius. Default is false.

------

####gradientRotateSpeed: `CGFloat`
Describes how many times the underlying gradient will perform a 2π rotation for each full cycle of the progress. Integer values recommended. Default is 0.

------

####glowAmount: `CGFloat`
The intensity of the glow. Between 0 and 1.0. Default is 1.0.

------

####glowMode: `KDCircularProgressGlowMode`
- **.forward** - The glow increases proportionaly to the angle. No glow at 0 degrees and full glow at 360 degrees.

- **.reverse** - The glow increases inversely proportional to the angle. Full glow at 0 degrees and no glow at 360 degrees.

- **.constant** - Constant glow.

- **.noGlow** - No glow

The default is **.forward**

------

####progressThickness: `CGFloat`
The thickness of the progress. Between 0 and 1. Default is 0.4

------

####trackThickness: `CGFloat`
The thickness of the background track. Between 0 and 1. Default is 0.5

------

####trackColor: `UIColor`
The color of the background track. Default is `UIColor.blackColor()`.

------

####progressInsideFillColor: `UIColor`
The color of the center of the circle. Default is `UIColor.clearColor()`.

------

##Methods
```swift 
override public init(frame: CGRect)
```
Initialize with a frame. Please only use square frames.

------

```swift 
convenience public init(frame:CGRect, colors: UIColor...)
```
Initialize with a frame and the gradient colors.

------

```swift 
public func set(colors: UIColor...)
public func set(colors: [UIColor])
```

Set the colors for the progress gradient.

------

```swift
public func animateFromAngle(fromAngle: Int, toAngle: Int, duration: NSTimeInterval, relativeDuration: Bool = true, completion: ((Bool) -> Void)?)
```

Animate the progress from an initial value to a final value, with a completion block that fires after the animation is done.

`relativeDuration` - specify if the duration is for the specific animation or is the duration that would make a full turn.

------

```swift
public func animateToAngle(toAngle: Int, duration: NSTimeInterval, completion: ((Bool) -> Void)?)
```

Animate the progress from the current state to a target value.

------

```swift 
public func pauseAnimation()
```

Pause the animation, if any.

------

```swift 
public func isAnimating() -> Bool
```

Check if there's an active animation.

##Misc
Prefering light colors in the gradients gives better results. As mentioned before, use square frames. Rectangular frames are not tested and might produce unexpected results.

##To-Do
- [x] Add example project
- [ ] Carthage Support
- [x] CocoaPods Support
- [x] IBDesignable/IBInspectable support
- [x] Adding a `progress` property as an alternative to `angle`
- [ ] Clean up

##Contact
Drop me an email if you want discuss anything further.

[Email](kaandedeoglu@me.com)

##License

The MIT License (MIT)

Copyright (c) 2016 Kaan Dedeoglu

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
