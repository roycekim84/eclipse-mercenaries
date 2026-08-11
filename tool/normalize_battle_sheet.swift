import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

private let rows = 5
private let outputCellWidth = 288
private let outputCellHeight = 256
private let outputBaseline = 238
private let searchBleed = 76
private let alphaThreshold: UInt8 = 20

private struct Component {
  var pixels: [Int]
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

guard CommandLine.arguments.count == 4,
      let columns = Int(CommandLine.arguments[3]), columns > 0 else {
  fail("usage: normalize_battle_sheet <input.png> <output.png> <columns>")
}

let inputURL = URL(fileURLWithPath: CommandLine.arguments[1])
let outputURL = URL(fileURLWithPath: CommandLine.arguments[2])
guard let source = CGImageSourceCreateWithURL(inputURL as CFURL, nil),
      let image = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
  fail("could not decode \(inputURL.path)")
}

let sourceWidth = image.width
let sourceHeight = image.height
guard sourceWidth % columns == 0, sourceHeight % rows == 0 else {
  fail("sheet is not divisible by \(columns)x\(rows): \(sourceWidth)x\(sourceHeight)")
}
let sourceCellWidth = sourceWidth / columns
let sourceCellHeight = sourceHeight / rows
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

func opaque(_ x: Int, _ y: Int) -> Bool {
  sourcePixels[(y * sourceWidth + x) * 4 + 3] >= alphaThreshold
}

let outputWidth = columns * outputCellWidth
let outputHeight = rows * outputCellHeight
var outputPixels = [UInt8](repeating: 0, count: outputWidth * outputHeight * 4)

for row in 0..<rows {
  let rowY0 = row * sourceCellHeight
  let rowY1 = (row + 1) * sourceCellHeight
  for column in 0..<columns {
    let cellX0 = column * sourceCellWidth
    let cellX1 = (column + 1) * sourceCellWidth
    let searchX0 = max(0, cellX0 - searchBleed)
    let searchX1 = min(sourceWidth, cellX1 + searchBleed)
    let searchWidth = searchX1 - searchX0
    let searchHeight = rowY1 - rowY0
    var visited = [Bool](repeating: false, count: searchWidth * searchHeight)
    var components: [Component] = []

    for y in rowY0..<rowY1 {
      for x in searchX0..<searchX1 {
        let local = (y - rowY0) * searchWidth + (x - searchX0)
        if visited[local] || !opaque(x, y) { continue }
        var queue = [(x, y)]
        visited[local] = true
        var cursor = 0
        var component = Component(
          pixels: [], minX: x, minY: y, maxX: x, maxY: y
        )
        while cursor < queue.count {
          let (px, py) = queue[cursor]
          cursor += 1
          component.pixels.append(py * sourceWidth + px)
          component.minX = min(component.minX, px)
          component.minY = min(component.minY, py)
          component.maxX = max(component.maxX, px)
          component.maxY = max(component.maxY, py)
          for dy in -1...1 {
            for dx in -1...1 where dx != 0 || dy != 0 {
              let nx = px + dx
              let ny = py + dy
              if nx < searchX0 || nx >= searchX1 || ny < rowY0 || ny >= rowY1 {
                continue
              }
              let neighbor = (ny - rowY0) * searchWidth + (nx - searchX0)
              if visited[neighbor] || !opaque(nx, ny) { continue }
              visited[neighbor] = true
              queue.append((nx, ny))
            }
          }
        }
        if component.pixels.count >= 12 { components.append(component) }
      }
    }

    let centerX = Double(cellX0 + cellX1) / 2
    let centerY = Double(rowY0) + Double(sourceCellHeight) * 0.58
    guard let primary = components.max(by: { left, right in
      func score(_ component: Component) -> Double {
        let cx = Double(component.minX + component.maxX) / 2
        let cy = Double(component.minY + component.maxY) / 2
        let distance = abs(cx - centerX) + abs(cy - centerY) * 0.35
        let intersectsCore = component.maxX >= cellX0 + sourceCellWidth / 4 &&
          component.minX <= cellX1 - sourceCellWidth / 4
        return Double(component.pixels.count) / (1 + distance * 0.025) * (intersectsCore ? 2.4 : 0.15)
      }
      return score(left) < score(right)
    }) else { continue }

    let scale = min(
      1.0,
      min(
        Double(outputCellWidth - 20) / Double(primary.width),
        Double(outputBaseline - 10) / Double(primary.height)
      )
    )
    let renderedWidth = max(1, Int((Double(primary.width) * scale).rounded()))
    let renderedHeight = max(1, Int((Double(primary.height) * scale).rounded()))
    let destinationX0 = column * outputCellWidth + (outputCellWidth - renderedWidth) / 2
    let destinationY0 = row * outputCellHeight + outputBaseline - renderedHeight
    let primaryPixelSet = Set(primary.pixels)

    for destinationY in 0..<renderedHeight {
      let sourceY = min(primary.maxY, primary.minY + Int(Double(destinationY) / scale))
      for destinationX in 0..<renderedWidth {
        let sourceX = min(primary.maxX, primary.minX + Int(Double(destinationX) / scale))
        let sourcePixel = sourceY * sourceWidth + sourceX
        if !primaryPixelSet.contains(sourcePixel) { continue }
        let sourceIndex = sourcePixel * 4
        let targetX = destinationX0 + destinationX
        let targetY = destinationY0 + destinationY
        let destinationIndex = (targetY * outputWidth + targetX) * 4
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
        width: outputWidth,
        height: outputHeight,
        bitsPerComponent: 8,
        bitsPerPixel: 32,
        bytesPerRow: outputWidth * 4,
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
  fail("could not create output")
}
CGImageDestinationAddImage(destination, outputImage, nil)
guard CGImageDestinationFinalize(destination) else { fail("could not write output") }
print("normalized \(outputURL.lastPathComponent): \(columns)x\(rows), \(outputCellWidth)x\(outputCellHeight) cells")
