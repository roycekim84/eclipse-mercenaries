import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

private let sourceColumns = 7
private let rows = 5
private let cellSize = 224
private let baselineY = 208
private let contentInset = 8

private struct Bounds {
  var minX: Int
  var minY: Int
  var maxX: Int
  var maxY: Int

  var width: Int { maxX - minX + 1 }
  var height: Int { maxY - minY + 1 }
}

private func fail(_ message: String) -> Never {
  FileHandle.standardError.write(Data((message + "\n").utf8))
  exit(1)
}

guard CommandLine.arguments.count == 3 else {
  fail("usage: prepare_generated_battle_sheet <source.png> <output.png>")
}

let inputURL = URL(fileURLWithPath: CommandLine.arguments[1])
let outputURL = URL(fileURLWithPath: CommandLine.arguments[2])
guard let source = CGImageSourceCreateWithURL(inputURL as CFURL, nil),
      let image = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
  fail("could not decode \(inputURL.path)")
}

let sourceWidth = image.width
let sourceHeight = image.height
var sourcePixels = [UInt8](repeating: 0, count: sourceWidth * sourceHeight * 4)
sourcePixels.withUnsafeMutableBytes { bytes in
  let context = CGContext(
    data: bytes.baseAddress,
    width: sourceWidth,
    height: sourceHeight,
    bitsPerComponent: 8,
    bytesPerRow: sourceWidth * 4,
    space: CGColorSpaceCreateDeviceRGB(),
    bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
  )!
  context.interpolationQuality = .none
  context.setShouldAntialias(false)
  context.draw(image, in: CGRect(x: 0, y: 0, width: sourceWidth, height: sourceHeight))
}

let background = (
  sourcePixels[0],
  sourcePixels[1],
  sourcePixels[2]
)

func isBackground(_ pixelIndex: Int) -> Bool {
  let red = Int(sourcePixels[pixelIndex])
  let green = Int(sourcePixels[pixelIndex + 1])
  let blue = Int(sourcePixels[pixelIndex + 2])
  let redDelta = red - Int(background.0)
  let greenDelta = green - Int(background.1)
  let blueDelta = blue - Int(background.2)
  let nearKey = redDelta * redDelta + greenDelta * greenDelta + blueDelta * blueDelta < 104 * 104
  let greenScreen = Int(background.1) > Int(background.0) + 80 &&
    green > 100 && green > red * 3 / 2 && green > blue * 3 / 2
  let magentaScreen = Int(background.0) > Int(background.1) + 80 &&
    red > 100 && blue > 70 && red > green * 3 / 2 && blue > green * 3 / 2
  return nearKey || greenScreen || magentaScreen
}

let targetWidth = sourceColumns * cellSize
let targetHeight = rows * cellSize
var outputPixels = [UInt8](repeating: 0, count: targetWidth * targetHeight * 4)

for row in 0..<rows {
  // Generated cells sometimes let hair, ears, or antlers cross the nominal
  // row guide. Include a small upper bleed so those pixels are not guillotined.
  let sourceY0 = max(0, row * sourceHeight / rows - (row == 0 ? 0 : 24))
  let sourceY1 = (row + 1) * sourceHeight / rows
  for column in 0..<sourceColumns {
    let sourceX0 = column * sourceWidth / sourceColumns
    let sourceX1 = (column + 1) * sourceWidth / sourceColumns
    var bounds = Bounds(
      minX: sourceX1,
      minY: sourceY1,
      maxX: sourceX0 - 1,
      maxY: sourceY0 - 1
    )
    for sourceY in sourceY0..<sourceY1 {
      for sourceX in sourceX0..<sourceX1 {
        let sourceIndex = (sourceY * sourceWidth + sourceX) * 4
        if isBackground(sourceIndex) { continue }
        bounds.minX = min(bounds.minX, sourceX)
        bounds.minY = min(bounds.minY, sourceY)
        bounds.maxX = max(bounds.maxX, sourceX)
        bounds.maxY = max(bounds.maxY, sourceY)
      }
    }
    guard bounds.maxX >= bounds.minX, bounds.maxY >= bounds.minY else { continue }

    let maxContentWidth = cellSize - contentInset * 2
    let maxContentHeight = baselineY - contentInset
    let scale = min(
      1.0,
      min(
        Double(maxContentWidth) / Double(bounds.width),
        Double(maxContentHeight) / Double(bounds.height)
      )
    )
    let renderedWidth = max(1, Int((Double(bounds.width) * scale).rounded()))
    let renderedHeight = max(1, Int((Double(bounds.height) * scale).rounded()))
    let destinationX0 = column * cellSize + (cellSize - renderedWidth) / 2
    let destinationY0 = row * cellSize + baselineY - renderedHeight

    for destinationY in 0..<renderedHeight {
      let sourceY = min(
        bounds.maxY,
        bounds.minY + Int(Double(destinationY) / scale)
      )
      for destinationX in 0..<renderedWidth {
        let sourceX = min(
          bounds.maxX,
          bounds.minX + Int(Double(destinationX) / scale)
        )
        let sourceIndex = (sourceY * sourceWidth + sourceX) * 4
        if isBackground(sourceIndex) { continue }
        let targetX = destinationX0 + destinationX
        let targetY = destinationY0 + destinationY
        let destinationIndex = (targetY * targetWidth + targetX) * 4
        outputPixels[destinationIndex] = sourcePixels[sourceIndex]
        outputPixels[destinationIndex + 1] = sourcePixels[sourceIndex + 1]
        outputPixels[destinationIndex + 2] = sourcePixels[sourceIndex + 2]
        outputPixels[destinationIndex + 3] = 255
      }
    }
  }
}

guard let provider = CGDataProvider(data: Data(outputPixels) as CFData),
      let outputImage = CGImage(
        width: targetWidth,
        height: targetHeight,
        bitsPerComponent: 8,
        bitsPerPixel: 32,
        bytesPerRow: targetWidth * 4,
        space: CGColorSpaceCreateDeviceRGB(),
        bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue),
        provider: provider,
        decode: nil,
        shouldInterpolate: false,
        intent: .defaultIntent
      ),
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
print("prepared \(outputURL.lastPathComponent) as 7 x 5 frames")
