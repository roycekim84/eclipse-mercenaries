import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

func fail(_ message: String) -> Never {
  FileHandle.standardError.write(Data((message + "\n").utf8))
  exit(1)
}

guard CommandLine.arguments.count == 6 else {
  fail("usage: normalize_animation_grid <input> <output> <source-columns> <target-columns> <rows>")
}

let inputURL = URL(fileURLWithPath: CommandLine.arguments[1])
let outputURL = URL(fileURLWithPath: CommandLine.arguments[2])
guard let sourceColumns = Int(CommandLine.arguments[3]), sourceColumns > 0,
      let targetColumns = Int(CommandLine.arguments[4]), targetColumns > 0,
      let rows = Int(CommandLine.arguments[5]), rows > 0 else {
  fail("column and row counts must be positive integers")
}
guard let source = CGImageSourceCreateWithURL(inputURL as CFURL, nil),
      let image = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
  fail("could not decode \(inputURL.path)")
}

let cellSize = image.height / rows
let targetWidth = cellSize * targetColumns
let targetHeight = cellSize * rows
let colorSpace = CGColorSpaceCreateDeviceRGB()
guard let context = CGContext(
  data: nil,
  width: targetWidth,
  height: targetHeight,
  bitsPerComponent: 8,
  bytesPerRow: targetWidth * 4,
  space: colorSpace,
  bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
) else {
  fail("could not create output canvas")
}

context.interpolationQuality = .none
context.setShouldAntialias(false)

for row in 0..<rows {
  for targetColumn in 0..<targetColumns {
    // Preserve the first and last poses and hold the middle pose once when
    // expanding seven generated frames into the eight-frame Flame contract.
    let sourceColumn: Int
    if targetColumns == sourceColumns + 1 && targetColumn > sourceColumns / 2 {
      sourceColumn = targetColumn - 1
    } else {
      sourceColumn = min(targetColumn, sourceColumns - 1)
    }
    let x0 = sourceColumn * image.width / sourceColumns
    let x1 = (sourceColumn + 1) * image.width / sourceColumns
    let y0 = row * image.height / rows
    let y1 = (row + 1) * image.height / rows
    guard let frame = image.cropping(
      to: CGRect(x: x0, y: y0, width: x1 - x0, height: y1 - y0)
    ) else {
      fail("could not crop row \(row), column \(sourceColumn)")
    }
    context.draw(
      frame,
      in: CGRect(
        x: targetColumn * cellSize,
        y: (rows - 1 - row) * cellSize,
        width: cellSize,
        height: cellSize
      )
    )
  }
}

guard let outputImage = context.makeImage(),
      let destination = CGImageDestinationCreateWithURL(
        outputURL as CFURL,
        UTType.png.identifier as CFString,
        1,
        nil
      ) else {
  fail("could not create \(outputURL.path)")
}
CGImageDestinationAddImage(destination, outputImage, nil)
guard CGImageDestinationFinalize(destination) else {
  fail("could not write \(outputURL.path)")
}
