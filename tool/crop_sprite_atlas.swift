import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

func fail(_ message: String) -> Never {
  FileHandle.standardError.write(Data((message + "\n").utf8))
  exit(1)
}

guard CommandLine.arguments.count == 6 else {
  fail("usage: crop_sprite_atlas <input> <output-dir> <columns> <rows> <comma-separated-names>")
}

let inputURL = URL(fileURLWithPath: CommandLine.arguments[1])
let outputDirectory = URL(fileURLWithPath: CommandLine.arguments[2], isDirectory: true)
guard let columns = Int(CommandLine.arguments[3]), columns > 0,
      let rows = Int(CommandLine.arguments[4]), rows > 0 else {
  fail("columns and rows must be positive integers")
}
let names = CommandLine.arguments[5].split(separator: ",").map(String.init)
guard names.count == columns * rows else {
  fail("expected \(columns * rows) names, received \(names.count)")
}
guard let source = CGImageSourceCreateWithURL(inputURL as CFURL, nil),
      let image = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
  fail("could not decode \(inputURL.path)")
}

try FileManager.default.createDirectory(
  at: outputDirectory,
  withIntermediateDirectories: true
)

for index in names.indices {
  let column = index % columns
  let row = index / columns
  let x0 = column * image.width / columns
  let x1 = (column + 1) * image.width / columns
  let y0 = row * image.height / rows
  let y1 = (row + 1) * image.height / rows
  let rect = CGRect(x: x0, y: y0, width: x1 - x0, height: y1 - y0)
  guard let tile = image.cropping(to: rect) else {
    fail("could not crop tile \(index) at \(rect)")
  }
  let outputURL = outputDirectory.appendingPathComponent(names[index] + ".png")
  guard let destination = CGImageDestinationCreateWithURL(
    outputURL as CFURL,
    UTType.png.identifier as CFString,
    1,
    nil
  ) else {
    fail("could not create \(outputURL.path)")
  }
  CGImageDestinationAddImage(destination, tile, nil)
  guard CGImageDestinationFinalize(destination) else {
    fail("could not write \(outputURL.path)")
  }
}
