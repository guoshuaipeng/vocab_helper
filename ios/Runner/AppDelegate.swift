import Flutter
import UIKit
import Vision

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    let messenger = engineBridge.applicationRegistrar.messenger()
    let channel = FlutterMethodChannel(
      name: "com.vocab_helper/vision_ocr",
      binaryMessenger: messenger
    )
    channel.setMethodCallHandler { call, result in
      guard call.method == "recognizeText" else {
        result(FlutterMethodNotImplemented)
        return
      }
      guard
        let args = call.arguments as? [String: Any],
        let path = args["path"] as? String
      else {
        result(FlutterError(code: "bad_args", message: "path required", details: nil))
        return
      }
      Self.recognizeText(at: path, result: result)
    }
  }

  private static func recognizeText(at path: String, result: @escaping FlutterResult) {
    let url = URL(fileURLWithPath: path)
    guard let data = try? Data(contentsOf: url),
          let image = UIImage(data: data),
          let cgImage = image.cgImage
    else {
      result(FlutterError(code: "bad_image", message: "cannot load image", details: nil))
      return
    }

    let request = VNRecognizeTextRequest { request, error in
      if let error = error {
        result(FlutterError(code: "vision", message: error.localizedDescription, details: nil))
        return
      }
      let observations = (request.results as? [VNRecognizedTextObservation]) ?? []
      let lines: [String] = observations.compactMap { obs in
        obs.topCandidates(1).first?.string
      }
      result(lines.joined(separator: "\n"))
    }
    request.recognitionLevel = .accurate
    request.usesLanguageCorrection = true
    request.recognitionLanguages = ["en-US"]

    let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
    DispatchQueue.global(qos: .userInitiated).async {
      do {
        try handler.perform([request])
      } catch {
        result(FlutterError(code: "vision", message: error.localizedDescription, details: nil))
      }
    }
  }
}
