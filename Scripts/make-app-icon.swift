#!/usr/bin/env swift
// Generates the MacInside app icon set: a dark rounded-square background with
// a two-tone circular gauge ring (orange/blue), echoing the CPU/Memory rings
// used throughout the dashboard (see Views/Components/CircularGauge.swift).
// Usage: ./Scripts/make-app-icon.swift
import AppKit

// Resolve the appiconset next to this script (…/Scripts/../MacInside/Assets…).
let scriptDir = URL(fileURLWithPath: CommandLine.arguments[0]).deletingLastPathComponent()
let root = scriptDir.deletingLastPathComponent()
let fm = FileManager.default
guard let assets = try? fm.contentsOfDirectory(at: root, includingPropertiesForKeys: nil)
        .first(where: { $0.pathExtension == "" && fm.fileExists(atPath: $0.appendingPathComponent("Assets.xcassets").path) })
        .map({ $0.appendingPathComponent("Assets.xcassets/AppIcon.appiconset") }) else {
    FileHandle.standardError.write(Data("could not locate AppIcon.appiconset\n".utf8))
    exit(1)
}

/// Points along a ring arc, walked clockwise from the top (12 o'clock) as
/// `fraction` goes 0→1 — matches CircularGauge's `.rotationEffect(-90)` trim
/// convention, computed manually to avoid NSBezierPath arc sign ambiguity.
func arcPath(center: NSPoint, radius: CGFloat, from startFraction: CGFloat, to endFraction: CGFloat) -> NSBezierPath {
    let path = NSBezierPath()
    let steps = 96
    for i in 0...steps {
        let f = startFraction + (endFraction - startFraction) * CGFloat(i) / CGFloat(steps)
        let angle = (90 - f * 360) * .pi / 180
        let point = NSPoint(x: center.x + radius * cos(angle), y: center.y + radius * sin(angle))
        if i == 0 { path.move(to: point) } else { path.line(to: point) }
    }
    return path
}

func render(_ size: Int) -> Data {
    let s = CGFloat(size)
    // Draw into a bitmap of EXACTLY `size`×`size` pixels. NSImage.lockFocus()
    // would render at the screen's backing scale (2× on Retina) and double every
    // icon, which iOS rejects ("did not have any applicable content").
    let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil, pixelsWide: size, pixelsHigh: size,
        bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
        colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
    rep.size = NSSize(width: s, height: s)

    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)

    // Background: dark slate → near-black, rounded square (system-monitor
    // aesthetic à la Stats/iStat Menus, distinct from a generic flat-color icon).
    let rect = NSRect(x: 0, y: 0, width: s, height: s)
    let radius = s * 0.22
    let bgPath = NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius)
    let bgGradient = NSGradient(colors: [
        NSColor(calibratedRed: 0.17, green: 0.19, blue: 0.23, alpha: 1),
        NSColor(calibratedRed: 0.06, green: 0.07, blue: 0.09, alpha: 1),
    ])!
    bgGradient.draw(in: bgPath, angle: -90)

    // Gauge ring: subtle track + two stacked segments (system/user), same
    // colors and stacking convention as CircularGauge — orange then blue,
    // with a visible gap left open at the bottom like a speedometer.
    let center = NSPoint(x: s / 2, y: s / 2)
    let lineWidth = s * 0.115
    let ringRadius = s * 0.5 - lineWidth / 2 - s * 0.09

    let track = NSBezierPath(ovalIn: NSRect(
        x: center.x - ringRadius, y: center.y - ringRadius,
        width: ringRadius * 2, height: ringRadius * 2))
    track.lineWidth = lineWidth
    NSColor.white.withAlphaComponent(0.12).setStroke()
    track.stroke()

    let systemColor = NSColor(calibratedRed: 1.0, green: 0.584, blue: 0.0, alpha: 1)   // Color.orange
    let userColor = NSColor(calibratedRed: 0.0, green: 0.478, blue: 1.0, alpha: 1)     // Color.blue

    let systemArc = arcPath(center: center, radius: ringRadius, from: 0, to: 0.36)
    systemArc.lineWidth = lineWidth
    systemArc.lineCapStyle = .round
    systemColor.setStroke()
    systemArc.stroke()

    let userArc = arcPath(center: center, radius: ringRadius, from: 0.36, to: 0.70)
    userArc.lineWidth = lineWidth
    userArc.lineCapStyle = .round
    userColor.setStroke()
    userArc.stroke()

    NSGraphicsContext.restoreGraphicsState()
    return rep.representation(using: .png, properties: [:])!
}

for size in [16, 32, 64, 128, 256, 512, 1024] {
    let url = assets.appendingPathComponent("icon_\(size).png")
    try! render(size).write(to: url)
    print("wrote \(url.lastPathComponent)")
}
print("✅ app icon set generated (dashboard gauge)")
