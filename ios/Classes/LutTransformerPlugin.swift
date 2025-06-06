import Flutter
import UIKit
import AVFoundation

public class LutTransformerPlugin: NSObject, FlutterPlugin, FlutterStreamHandler {
  private var eventSink: FlutterEventSink?
  private var registrar: FlutterPluginRegistrar?

  public static func register(with registrar: FlutterPluginRegistrar) {
    let methodChannel = FlutterMethodChannel(name: "lut_transformer/method", binaryMessenger: registrar.messenger())
    let eventChannel = FlutterEventChannel(name: "lut_transformer/event", binaryMessenger: registrar.messenger())
    let instance = LutTransformerPlugin()
    registrar.addMethodCallDelegate(instance, channel: methodChannel)
    eventChannel.setStreamHandler(instance)
    instance.registrar = registrar
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "getPlatformVersion":
      result("iOS " + UIDevice.current.systemVersion)
    case "transformVideo":
      guard let args = call.arguments as? [String: Any],
            let inputPath = args["inputPath"] as? String else {
        result(FlutterError(code: "INVALID_ARGUMENTS", message: "Missing inputPath", details: nil))
        return
      }
      let lutAsset = args["lutAsset"] as? String
      let flipHorizontally = args["flipHorizontally"] as? Bool ?? false
      let cropSquareSize = args["cropSquareSize"] as? Int

      var lutPath: String?
      if let asset = lutAsset, let registrar = registrar {
        let key = registrar.lookupKey(forAsset: asset)
        if !key.isEmpty {
            lutPath = Bundle.main.path(forResource: key, ofType: nil)
        }
      }

      VideoTransformer.transform(
        inputPath: inputPath,
        lutPath: lutPath,
        flipHorizontally: flipHorizontally,
        cropSquareSize: cropSquareSize,
        onProgress: { [weak self] progress in
          self?.eventSink?(["progress": progress])
        },
        onCompleted: { [weak self] output in
          self?.eventSink?(["progress": 1.0, "outputPath": output])
          self?.eventSink?(FlutterEndOfEventStream)
        },
        onError: { [weak self] code, message in
          self?.eventSink?(["progress": 0.0, "errorCode": code, "errorMessage": message ?? "error", "errorDetails": nil])
          self?.eventSink?(FlutterEndOfEventStream)
        }
      )
      result(nil)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
    self.eventSink = events
    return nil
  }

  public func onCancel(withArguments arguments: Any?) -> FlutterError? {
    self.eventSink = nil
    return nil
  }
}
