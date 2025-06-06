import Foundation
import AVFoundation
import CoreImage

struct CubeParser {
    enum CubeParserError: Error {
        case invalidSize
        case valueMismatch
        case invalidDataLine
    }

    static func load(url: URL) throws -> (Data, Int) {
        let content = try String(contentsOf: url, encoding: .ascii)
        var size: Int = 0
        var rawValues: [Float] = []
        
        for line in content.components(separatedBy: .newlines) {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.isEmpty || trimmed.hasPrefix("#") {
                continue
            }
            
            let parts = trimmed.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
            if parts.isEmpty {
                continue
            }
            
            let key = parts[0].uppercased()
            
            if key == "TITLE" || key == "DOMAIN_MIN" || key == "DOMAIN_MAX" {
                continue
            }
            
            if key == "LUT_3D_SIZE" {
                if parts.count >= 2, let value = Int(parts[1]) {
                    size = value
                }
            } else {
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
        guard rawValues.count == expectedValues else {
            throw CubeParserError.valueMismatch
        }
        
        var cubeData: [Float] = []
        var index = 0
        for _ in 0..<(size * size * size) {
            let r = rawValues[index]
            let g = rawValues[index+1]
            let b = rawValues[index+2]
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
        lutIntensity: Double,
        flipHorizontally: Bool,
        cropSquareSize: Int?,
        onProgress: @escaping (Double) -> Void,
        onCompleted: @escaping (String) -> Void,
        onError: @escaping (String, String?) -> Void
    ) {
        DispatchQueue.global(qos: .userInitiated).async {
            let inputURL = URL(fileURLWithPath: inputPath)
            let asset = AVURLAsset(url: inputURL)
            guard let track = asset.tracks(withMediaType: .video).first else {
                DispatchQueue.main.async { onError("NO_VIDEO_TRACK", "No video track found") }
                return
            }
            let naturalSize = track.naturalSize.applying(track.preferredTransform)
            let width = abs(naturalSize.width)
            let height = abs(naturalSize.height)
            let side = CGFloat(cropSquareSize ?? Int(min(width, height)))
            let xOffset = (width - side) / 2
            let yOffset = (height - side) / 2

            var lutData: Data?
            var lutDimension: Int = 0
            if let lutPath = lutPath {
                do {
                    let url = URL(fileURLWithPath: lutPath)
                    let parsed = try CubeParser.load(url: url)
                    lutData = parsed.0
                    lutDimension = parsed.1
                } catch {
                    DispatchQueue.main.async { onError("LUT_PARSE_ERROR", error.localizedDescription) }
                    return
                }
            }

            let videoComposition = AVMutableVideoComposition(asset: asset, applyingCIFiltersWithHandler: { request in
                // The `sourceImage` is already oriented correctly based on `preferredTransform`.
                let image = request.sourceImage

                // 1. Create a transform to crop and flip (if needed).
                let transform: CGAffineTransform
                if flipHorizontally {
                    // This transform maps the crop rect `(xOffset, yOffset, side, side)` to the output rect `(0, 0, side, side)` with a horizontal flip.
                    transform = CGAffineTransform(a: -1, b: 0, c: 0, d: 1, tx: xOffset + side, ty: -yOffset)
                } else {
                    // This transform maps the crop rect `(xOffset, yOffset, side, side)` to the output rect `(0, 0, side, side)`.
                    transform = CGAffineTransform(translationX: -xOffset, y: -yOffset)
                }

                // 2. Apply the transform and then crop to the final size.
                var processedImage = image.transformed(by: transform)
                let cropRect = CGRect(x: 0, y: 0, width: side, height: side)
                processedImage = processedImage.cropped(to: cropRect)

                // 3. Apply the LUT filter.
                if let data = lutData, lutDimension > 0, lutIntensity > 0 {
                    let originalImage = processedImage
                    let lutAppliedImage: CIImage
                    
                    let colorCubeFilter = CIFilter(name: "CIColorCube")!
                    colorCubeFilter.setValue(lutDimension, forKey: "inputCubeDimension")
                    colorCubeFilter.setValue(data, forKey: "inputCubeData")
                    colorCubeFilter.setValue(originalImage, forKey: kCIInputImageKey)
                    
                    lutAppliedImage = colorCubeFilter.outputImage ?? originalImage
                    
                    if lutIntensity < 1.0 {
                        let dissolveFilter = CIFilter(name: "CIDissolveTransition")!
                        dissolveFilter.setValue(lutAppliedImage, forKey: kCIInputImageKey)
                        dissolveFilter.setValue(originalImage, forKey: kCIInputTargetImageKey)
                        dissolveFilter.setValue(lutIntensity, forKey: kCIInputTimeKey)
                        if let output = dissolveFilter.outputImage {
                            processedImage = output
                        }
                    } else {
                        processedImage = lutAppliedImage
                    }
                }
                request.finish(with: processedImage, context: nil)
            })

            // Set the render size to the size of our cropped square.
            videoComposition.renderSize = CGSize(width: side, height: side)
            // Use the source video's frame rate for a smoother output.
            videoComposition.frameDuration = track.minFrameDuration

            let outputURL = FileManager.default.temporaryDirectory
                .appendingPathComponent(UUID().uuidString)
                .appendingPathExtension("mp4")

            guard let export = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetHighestQuality) else {
                DispatchQueue.main.async { onError("EXPORT_SESSION", "Could not create export session") }
                return
            }
            export.outputURL = outputURL
            export.outputFileType = .mp4
            export.videoComposition = videoComposition
            export.shouldOptimizeForNetworkUse = true
            
            DispatchQueue.main.async { onProgress(0.0) }

            export.exportAsynchronously {
                DispatchQueue.main.async {
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
    }
}

