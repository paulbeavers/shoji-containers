import AppKit

/// The app icon: Shoji's panes, with stacked containers in the active one.
@MainActor
enum AppIcon {
    static func render(to path: String) {
        let s: CGFloat = 1024
        let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: Int(s), pixelsHigh: Int(s), bitsPerSample: 8,
                                   samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB,
                                   bytesPerRow: 0, bitsPerPixel: 0)!
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
        let card = NSBezierPath(roundedRect: CGRect(x: 100, y: 100, width: 824, height: 824), xRadius: 185, yRadius: 185)
        NSColor(hex: 0x11111B).setFill()
        card.fill()
        let panes = [CGRect(x: 190, y: 190, width: 370, height: 644),
                     CGRect(x: 600, y: 532, width: 234, height: 302),
                     CGRect(x: 600, y: 190, width: 234, height: 302)]
        for (i, r) in panes.enumerated() {
            let p = NSBezierPath(roundedRect: r, xRadius: 36, yRadius: 36)
            NSColor(hex: 0x1E1E2E).setFill()
            p.fill()
            p.lineWidth = 22
            if i == 0 {
                NSGradient(colors: [NSColor(hex: 0xCBA6F7), NSColor(hex: 0x89B4FA)])?.draw(in: p.copy() as! NSBezierPath, angle: -45)
                NSColor(hex: 0x1E1E2E).setFill()
                NSBezierPath(roundedRect: r.insetBy(dx: 16, dy: 16), xRadius: 24, yRadius: 24).fill()
                // Stacked shipping containers: ribbed boxes in the theme's accents.
                let colors: [UInt32] = [0x89B4FA, 0xCBA6F7, 0xA6E3A1]
                for k in 0..<3 {
                    let box = CGRect(x: r.minX + 55, y: r.minY + 110 + CGFloat(k) * 150, width: r.width - 110, height: 120)
                    NSColor(hex: colors[k]).setFill()
                    NSBezierPath(roundedRect: box, xRadius: 14, yRadius: 14).fill()
                    NSColor(hex: 0x1E1E2E, alpha: 0.35).setFill()
                    var x = box.minX + 26
                    while x < box.maxX - 20 {
                        NSBezierPath(roundedRect: CGRect(x: x, y: box.minY + 18, width: 10, height: box.height - 36), xRadius: 5, yRadius: 5).fill()
                        x += 30
                    }
                }
            } else {
                NSColor(hex: 0x45475A).setStroke()
                p.stroke()
            }
        }
        NSGraphicsContext.restoreGraphicsState()
        try? rep.representation(using: .png, properties: [:])?.write(to: URL(fileURLWithPath: path))
    }
}
