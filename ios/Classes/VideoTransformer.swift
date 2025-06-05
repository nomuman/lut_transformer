import Foundation
import AVFoundation
import CoreImage

struct CubeParser {
    enum CubeParserError: Error {
        case invalidSize
        case valueMismatch
    }

    static func load(url: URL) throws -> (Data, Int) {
        let content = try String(contentsOf: url)
        var size: Int = 0
        var rawValues: [Float] = []
        let skipPrefixes = ["#", "TITLE", "DOMAIN_MIN", "DOMAIN_MAX"]
        for line in content.components(separatedBy: .newlines) {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.isEmpty { continue }
            if skipPrefixes.first(where: { trimmed.uppercased().hasPrefix($0) }) != nil {
                continue
            }
            if trimmed.uppercased().hasPrefix("LUT_3D_SIZE") {
                if let value = trimmed.split(separator: " ").last, let intVal = Int(value) {
                    size = intVal
                }
            } else {
                let parts = trimmed.split { $0 == " " || $0 == "\t" }
                if parts.count >= 3,
                   let r = Float(parts[0]),
                   let g = Float(parts[1]),
                   let b = Float(parts[2]) {
                    rawValues.append(contentsOf: [r, g, b])
                }
            }
        }
        guard size > 0 else { throw CubeParserError.invalidSize }
        let expectedValues = size * size * size * 3
        guard rawValues.count == expectedValues else { throw CubeParserError.valueMismatch }
        var cubeData: [Float] = []
        var index = 0
        for _ in 0..<(size * size * size) {
            let r = rawValues[index]; let g = rawValues[index+1]; let b = rawValues[index+2]
            cubeData.append(contentsOf: [r, g, b, 1.0])
            index += 3
        }
        let data = cubeData.withUnsafeBufferPointer { Data(buffer: $0) }
        return (data, size)
    }
}

class VideoTransformer {
    static func transform(
        inputPath: String,
        lutPath: String?,
        flipHorizontally: Bool,
        cropSquareSize: Int?,
        onProgress: @escaping (Double) -> Void,
        onCompleted: @escaping (String) -> Void,
        onError: @escaping (String, String?) -> Void
    ) {
        let inputURL = URL(fileURLWithPath: inputPath)
        let asset = AVURLAsset(url: inputURL)
        guard let track = asset.tracks(withMediaType: .video).first else {
            onError("NO_VIDEO_TRACK", "No video track found")
            return
        }
        let naturalSize = track.naturalSize.applying(track.preferredTransform)
        let width = abs(naturalSize.width)
        let height = abs(naturalSize.height)
        let side = CGFloat(cropSquareSize ?? Int(min(width, height)))
        let xOffset = (width - side) / 2
        let yOffset = (height - side) / 2

        var transform = track.preferredTransform.translatedBy(x: -xOffset, y: -yOffset)
        if flipHorizontally {
            transform = transform.scaledBy(x: -1, y: 1).translatedBy(x: -side, y: 0)
        }

        var lutData: Data?
        var lutDimension: Int = 0
        if let lutPath = lutPath {
            do {
                let url = URL(fileURLWithPath: lutPath)
                let parsed = try CubeParser.load(url: url)
                lutData = parsed.0
                lutDimension = parsed.1
            } catch {
                onError("LUT_PARSE_ERROR", error.localizedDescription)
                return
            }
        }

        let videoComposition = AVMutableVideoComposition(asset: asset) { request in
            var image = request.sourceImage.transformed(by: transform)
            image = image.cropped(to: CGRect(x: 0, y: 0, width: side, height: side))
            if let data = lutData {
                let filter = CIFilter(name: "CIColorCube")!
                filter.setValue(lutDimension, forKey: "inputCubeDimension")
                filter.setValue(data, forKey: "inputCubeData")
                filter.setValue(image, forKey: kCIInputImageKey)
                if let output = filter.outputImage {
                    image = output
                }
            }
            request.finish(with: image, context: nil)
        }
        videoComposition.renderSize = CGSize(width: side, height: side)
        videoComposition.frameDuration = CMTime(value: 1, timescale: 30)

        let outputURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("mp4")

        guard let export = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetHighestQuality) else {
            onError("EXPORT_SESSION", "Could not create export session")
            return
        }
        export.outputURL = outputURL
        export.outputFileType = .mp4
        export.videoComposition = videoComposition
        export.shouldOptimizeForNetworkUse = true
        onProgress(0.0)

        let timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { t in
            onProgress(Double(export.progress))
            if export.status != .exporting { t.invalidate() }
        }

        export.exportAsynchronously {
            timer.invalidate()
            switch export.status {
            case .completed:
                onProgress(1.0)
                onCompleted(outputURL.path)
            case .failed, .cancelled:
                onError("EXPORT_FAILED", export.error?.localizedDescription ?? "unknown")
            default:
                onError("EXPORT_UNKNOWN", export.error?.localizedDescription ?? "unknown")
            }
        }
    }
}

