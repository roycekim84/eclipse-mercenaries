import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

private let columns = 8
private let rows = 5
private let outputCellSize = 224
private let targetCenterX = outputCellSize / 2
private let targetBaselineY = 208
private let alphaThreshold: UInt8 = 12

private struct Bounds {
  var minX: Int
  var minY: Int
  var maxX: Int
  var maxY: Int

  var centerX: Double { Double(minX + maxX) / 2 }
}

private func fail(_ message: String) -> Never {
  FileHandle.standardError.write(Data((message + "\n").utf8))
  exit(1)
}

private func median(_ values: [Double]) -> Double {
  let sorted = values.sorted()
  guard !sorted.isEmpty else { return 0 }
  if sorted.count.isMultiple(of: 2) {
    return (sorted[sorted.count / 2 - 1] + sorted[sorted.count / 2]) / 2
  }
  return sorted[sorted.count / 2]
}

guard CommandLine.arguments.count > 1 else {
  fail("usage: align_battle_sheets <sheet.png> [sheet.png ...]")
}

for path in CommandLine.arguments.dropFirst() {
  let inputURL = URL(fileURLWithPath: path)
  guard let source = CGImageSourceCreateWithURL(inputURL as CFURL, nil),
        let image = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
    fail("could not decode \(path)")
  }
  if image.width == outputCellSize * columns,
     image.height == outputCellSize * rows {
    print("already aligned \(inputURL.lastPathComponent)")
    continue
  }
  guard image.width.isMultiple(of: columns),
        image.height.isMultiple(of: rows) else {
    fail("sheet does not use an 8 x 5 grid: \(path)")
  }

  let sourceCellWidth = image.width / columns
  let sourceCellHeight = image.height / rows
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

  func frameBounds(row: Int, column: Int) -> Bounds {
    var bounds = Bounds(
      minX: sourceCellWidth,
      minY: sourceCellHeight,
      maxX: -1,
      maxY: -1
    )
    for y in 0..<sourceCellHeight {
      for x in 0..<sourceCellWidth {
        let sourceX = column * sourceCellWidth + x
        let sourceY = row * sourceCellHeight + y
        if sourcePixels[(sourceY * sourceWidth + sourceX) * 4 + 3] <= alphaThreshold {
          continue
        }
        bounds.minX = min(bounds.minX, x)
        bounds.minY = min(bounds.minY, y)
        bounds.maxX = max(bounds.maxX, x)
        bounds.maxY = max(bounds.maxY, y)
      }
    }
    return bounds
  }

  let bounds = (0..<rows).map { row in
    (0..<columns).map { column in frameBounds(row: row, column: column) }
  }

  // Use the idle and walk rows to estimate the body center. Attack VFX often
  // extend far outside the body and must not pull the character off-axis.
  let locomotionCenters = (0..<columns).map { column in
    median([bounds[0][column].centerX, bounds[1][column].centerX])
  }
  let targetWidth = outputCellSize * columns
  let targetHeight = outputCellSize * rows
  var outputPixels = [UInt8](repeating: 0, count: targetWidth * targetHeight * 4)

  for row in 0..<rows {
    for column in 0..<columns {
      let frame = bounds[row][column]
      // Idle, walk, hit and dead poses have no large detached attack arc, so
      // their own opaque center is the most stable frame anchor. The attack
      // row instead inherits the locomotion anchor to keep weapon VFX from
      // dragging the actor in the opposite direction.
      let frameCenter = row == 2
        ? locomotionCenters[column]
        : frame.centerX
      let offsetX = Int((Double(targetCenterX) - frameCenter).rounded())
      let offsetY = targetBaselineY - frame.maxY
      for y in 0..<sourceCellHeight {
        let destinationY = row * outputCellSize + y + offsetY
        guard destinationY >= row * outputCellSize,
              destinationY < (row + 1) * outputCellSize else { continue }
        for x in 0..<sourceCellWidth {
          let destinationX = column * outputCellSize + x + offsetX
          guard destinationX >= column * outputCellSize,
                destinationX < (column + 1) * outputCellSize else { continue }
          let sourceIndex = (
            (row * sourceCellHeight + y) * sourceWidth +
              column * sourceCellWidth + x
          ) * 4
          if sourcePixels[sourceIndex + 3] == 0 { continue }
          let destinationIndex = (destinationY * targetWidth + destinationX) * 4
          outputPixels[destinationIndex] = sourcePixels[sourceIndex]
          outputPixels[destinationIndex + 1] = sourcePixels[sourceIndex + 1]
          outputPixels[destinationIndex + 2] = sourcePixels[sourceIndex + 2]
          outputPixels[destinationIndex + 3] = sourcePixels[sourceIndex + 3]
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
        ) else {
    fail("could not create normalized sheet for \(path)")
  }

  let temporaryURL = inputURL
    .deletingLastPathComponent()
    .appendingPathComponent(".\(inputURL.lastPathComponent).aligned")
    .appendingPathExtension("png")
  guard let destination = CGImageDestinationCreateWithURL(
          temporaryURL as CFURL,
          UTType.png.identifier as CFString,
          1,
          nil
        ) else {
    fail("could not create output for \(path)")
  }
  CGImageDestinationAddImage(destination, outputImage, nil)
  guard CGImageDestinationFinalize(destination) else {
    fail("could not write output for \(path)")
  }
  do {
    _ = try FileManager.default.replaceItemAt(inputURL, withItemAt: temporaryURL)
  } catch {
    fail("could not replace \(path): \(error)")
  }
  print("aligned \(inputURL.lastPathComponent) to \(targetWidth)x\(targetHeight)")
}
