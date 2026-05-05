import AppKit
import Foundation

// Usage:
//   swift scripts/generate_icon.swift /path/to/icon-1024.png

let outPath = CommandLine.arguments.dropFirst().first ?? "AppIcon-1024.png"
let outURL = URL(fileURLWithPath: outPath)

let size = 1024
let canvas = CGRect(x: 0, y: 0, width: size, height: size)

guard let rep = NSBitmapImageRep(
    bitmapDataPlanes: nil,
    pixelsWide: size,
    pixelsHigh: size,
    bitsPerSample: 8,
    samplesPerPixel: 4,
    hasAlpha: true,
    isPlanar: false,
    colorSpaceName: .deviceRGB,
    bytesPerRow: 0,
    bitsPerPixel: 0
) else {
    fputs("Failed to create bitmap rep\n", stderr)
    exit(1)
}

guard let gc = NSGraphicsContext(bitmapImageRep: rep) else {
    fputs("Failed to create graphics context\n", stderr)
    exit(1)
}

NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = gc
let ctx = gc.cgContext

ctx.setFillColor(NSColor.clear.cgColor)
ctx.fill(canvas)

let center = CGPoint(x: canvas.midX, y: canvas.midY)
let ringRadius: CGFloat = 360
let lineWidth: CGFloat = 110

// Base ring (light gray)
ctx.setStrokeColor(NSColor(calibratedWhite: 0.90, alpha: 1.0).cgColor)
ctx.setLineWidth(lineWidth)
ctx.setLineCap(.round)
ctx.addArc(center: center, radius: ringRadius, startAngle: 0, endAngle: .pi * 2, clockwise: false)
ctx.strokePath()

// Consumed segment (1/3), clockwise from top
let startAngle: CGFloat = .pi / 2
let endAngle: CGFloat = startAngle - (.pi * 2 / 3)

ctx.setStrokeColor(NSColor(calibratedRed: 0.98, green: 0.56, blue: 0.12, alpha: 1.0).cgColor)
ctx.setLineWidth(lineWidth)
ctx.setLineCap(.round)
ctx.addArc(center: center, radius: ringRadius, startAngle: startAngle, endAngle: endAngle, clockwise: true)
ctx.strokePath()

// A subtle highlight on the consumed segment
ctx.setStrokeColor(NSColor(calibratedRed: 1.00, green: 0.74, blue: 0.30, alpha: 0.70).cgColor)
ctx.setLineWidth(lineWidth * 0.42)
ctx.setLineCap(.round)
ctx.addArc(center: center, radius: ringRadius, startAngle: startAngle, endAngle: endAngle, clockwise: true)
ctx.strokePath()

// Flame at the leading end of the consumed segment.
let theta = endAngle
let nx = cos(theta)
let ny = sin(theta)
let tx = sin(theta)
let ty = -cos(theta) // clockwise tangent

let ringPoint = CGPoint(x: center.x + ringRadius * nx, y: center.y + ringRadius * ny)
let flameAnchor = CGPoint(
    x: ringPoint.x + nx * (lineWidth * 0.55) + tx * (lineWidth * 0.12),
    y: ringPoint.y + ny * (lineWidth * 0.55) + ty * (lineWidth * 0.12)
)
let flameAngle = atan2(ty, tx)

func flamePath(length: CGFloat, width: CGFloat) -> CGPath {
    let p = CGMutablePath()
    let half = width / 2
    p.move(to: CGPoint(x: 0, y: -half))
    p.addCurve(
        to: CGPoint(x: length, y: 0),
        control1: CGPoint(x: length * 0.55, y: -half * 1.20),
        control2: CGPoint(x: length * 0.95, y: -half * 0.25)
    )
    p.addCurve(
        to: CGPoint(x: 0, y: half),
        control1: CGPoint(x: length * 0.95, y: half * 0.25),
        control2: CGPoint(x: length * 0.55, y: half * 1.20)
    )
    p.addCurve(
        to: CGPoint(x: 0, y: -half),
        control1: CGPoint(x: -length * 0.20, y: half * 0.55),
        control2: CGPoint(x: -length * 0.20, y: -half * 0.55)
    )
    p.closeSubpath()
    return p
}

func transformed(_ path: CGPath, at pos: CGPoint, angle: CGFloat, scale: CGFloat) -> CGPath {
    var t = CGAffineTransform.identity
    t = t.scaledBy(x: scale, y: scale)
    t = t.rotated(by: angle)
    t = t.translatedBy(x: pos.x, y: pos.y)
    return path.copy(using: &t) ?? path
}

let outerFlame = flamePath(length: 170, width: 120)
let innerFlame = flamePath(length: 125, width: 90)

ctx.saveGState()
ctx.setShadow(offset: .zero, blur: 26, color: NSColor(calibratedRed: 1.00, green: 0.55, blue: 0.10, alpha: 0.55).cgColor)
ctx.addPath(transformed(outerFlame, at: flameAnchor, angle: flameAngle, scale: 1.0))
ctx.setFillColor(NSColor(calibratedRed: 0.98, green: 0.38, blue: 0.10, alpha: 1.0).cgColor)
ctx.fillPath()
ctx.restoreGState()

ctx.saveGState()
ctx.setShadow(offset: .zero, blur: 12, color: NSColor(calibratedRed: 1.00, green: 0.85, blue: 0.25, alpha: 0.40).cgColor)
ctx.addPath(transformed(innerFlame, at: flameAnchor, angle: flameAngle, scale: 1.0))
ctx.setFillColor(NSColor(calibratedRed: 1.00, green: 0.82, blue: 0.18, alpha: 1.0).cgColor)
ctx.fillPath()
ctx.restoreGState()

NSGraphicsContext.restoreGraphicsState()

guard let png = rep.representation(using: .png, properties: [:]) else {
    fputs("Failed to encode PNG\n", stderr)
    exit(1)
}

do {
    try FileManager.default.createDirectory(at: outURL.deletingLastPathComponent(), withIntermediateDirectories: true)
    try png.write(to: outURL, options: [.atomic])
} catch {
    fputs("Failed to write PNG: \(error)\n", stderr)
    exit(1)
}
