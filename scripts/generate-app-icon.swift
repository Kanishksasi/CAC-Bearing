import AppKit

let directory = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
    .appendingPathComponent("Bearing/Bearing/Assets.xcassets/AppIcon.appiconset")

func color(_ hex: UInt32) -> CGColor {
    CGColor(red: CGFloat((hex >> 16) & 255) / 255,
            green: CGFloat((hex >> 8) & 255) / 255,
            blue: CGFloat(hex & 255) / 255, alpha: 1)
}

for (name, background, foreground, arc) in [
    ("BearingIcon", UInt32(0xF6F5EF), UInt32(0x285442), UInt32(0xB9CABB)),
    ("BearingIconDark", UInt32(0x131C19), UInt32(0xA6D4B6), UInt32(0x52735E))
] {
    let context = CGContext(data: nil, width: 1024, height: 1024, bitsPerComponent: 8,
                            bytesPerRow: 4096, space: CGColorSpace(name: CGColorSpace.sRGB)!,
                            bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)!
    context.setFillColor(color(background))
    context.fill(CGRect(x: 0, y: 0, width: 1024, height: 1024))
    context.setStrokeColor(color(arc))
    context.setLineWidth(30)
    context.setLineCap(.round)
    context.addArc(center: CGPoint(x: 512, y: 512), radius: 295,
                   startAngle: -.pi / 4, endAngle: .pi * 5 / 4, clockwise: false)
    context.strokePath()
    context.setStrokeColor(color(foreground))
    context.setLineWidth(52)
    context.setLineJoin(.round)
    context.move(to: CGPoint(x: 512, y: 260))
    context.addLine(to: CGPoint(x: 512, y: 512))
    context.addLine(to: CGPoint(x: 718, y: 718))
    context.strokePath()
    context.setFillColor(color(foreground))
    context.fillEllipse(in: CGRect(x: 460, y: 460, width: 104, height: 104))
    let bitmap = NSBitmapImageRep(cgImage: context.makeImage()!)
    try bitmap.representation(using: .png, properties: [:])!.write(to: directory.appendingPathComponent(name + ".png"))
}
