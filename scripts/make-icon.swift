// Renders the app icon to a 1024×1024 PNG.  Usage: swift scripts/make-icon.swift out.png
// A clock face whose hands are a soft fan of ghosted strokes: the time, but fuzzy.
import AppKit

let size: CGFloat = 1024
let out = CommandLine.arguments.dropFirst().first ?? "icon_1024.png"

let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: Int(size), pixelsHigh: Int(size),
                           bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
                           colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
let ctx = NSGraphicsContext.current!.cgContext

func rgb(_ hex: UInt32, _ a: CGFloat = 1) -> NSColor {
    NSColor(srgbRed: CGFloat((hex >> 16) & 0xFF) / 255, green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255, alpha: a)
}

// macOS icon grid: 824pt rounded square centred on the 1024 canvas, with a drop shadow.
let tile = CGRect(x: 100, y: 100, width: 824, height: 824)
let tilePath = NSBezierPath(roundedRect: tile, xRadius: 185, yRadius: 185)
ctx.saveGState()
ctx.setShadow(offset: CGSize(width: 0, height: -10), blur: 28, color: rgb(0x000000, 0.35).cgColor)
rgb(0x1E1B4B).setFill()
tilePath.fill()
ctx.restoreGState()

// Background: deep indigo → teal.
ctx.saveGState()
tilePath.addClip()
NSGradient(colors: [rgb(0x312E81), rgb(0x0F766E)])!.draw(in: tile, angle: -60)
ctx.restoreGState()

let center = CGPoint(x: 512, y: 512)
let faceRadius: CGFloat = 300

// Clock face with a soft glow.
ctx.saveGState()
ctx.setShadow(offset: .zero, blur: 60, color: rgb(0x99F6E4, 0.45).cgColor)
rgb(0xF8FAFC).setFill()
NSBezierPath(ovalIn: CGRect(x: center.x - faceRadius, y: center.y - faceRadius,
                            width: faceRadius * 2, height: faceRadius * 2)).fill()
ctx.restoreGState()

func point(_ angleFromTwelve: CGFloat, _ r: CGFloat) -> CGPoint {
    let a = (90 - angleFromTwelve) * .pi / 180
    return CGPoint(x: center.x + cos(a) * r, y: center.y + sin(a) * r)
}

// Hour ticks.
for i in 0..<12 {
    let major = i % 3 == 0
    let p = NSBezierPath()
    p.move(to: point(CGFloat(i) * 30, faceRadius - 30))
    p.line(to: point(CGFloat(i) * 30, faceRadius - (major ? 78 : 56)))
    p.lineWidth = major ? 22 : 14
    p.lineCapStyle = .round
    rgb(0x334155, major ? 0.85 : 0.45).setStroke()
    p.stroke()
}

// A hand drawn as a fan of faint copies around its angle, plus a crisp core: fuzzy time.
func fuzzyHand(angle: CGFloat, length: CGFloat, width: CGFloat, color: UInt32, spread: CGFloat) {
    let steps = 9
    for s in 0..<steps {
        let t = CGFloat(s) / CGFloat(steps - 1) * 2 - 1   // -1...1
        let p = NSBezierPath()
        p.move(to: center)
        p.line(to: point(angle + t * spread, length))
        p.lineWidth = width
        p.lineCapStyle = .round
        rgb(color, 0.10 * (1 - abs(t)) + 0.04).setStroke()
        p.stroke()
    }
    let core = NSBezierPath()
    core.move(to: center)
    core.line(to: point(angle, length))
    core.lineWidth = width
    core.lineCapStyle = .round
    rgb(color, 0.95).setStroke()
    core.stroke()
}

// "Ten to two"-ish: hour hand between 1 and 2, minute hand near the 10.
fuzzyHand(angle: 50, length: 165, width: 38, color: 0x1E1B4B, spread: 14)
fuzzyHand(angle: 300, length: 235, width: 26, color: 0x0F766E, spread: 22)

// Hub.
rgb(0x1E1B4B).setFill()
NSBezierPath(ovalIn: CGRect(x: center.x - 26, y: center.y - 26, width: 52, height: 52)).fill()
rgb(0x5EEAD4).setFill()
NSBezierPath(ovalIn: CGRect(x: center.x - 10, y: center.y - 10, width: 20, height: 20)).fill()

NSGraphicsContext.current = nil
try! rep.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: out))
print("Wrote \(out)")
