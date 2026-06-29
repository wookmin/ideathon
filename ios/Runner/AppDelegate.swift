import Flutter
import GoogleMaps
import UIKit
import Vision

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    if let apiKey = Bundle.main.object(forInfoDictionaryKey: "GoogleMapsApiKey") as? String,
       !apiKey.isEmpty,
       !apiKey.hasPrefix("$(") {
      GMSServices.provideAPIKey(apiKey)
    } else {
      fatalError("GoogleMapsApiKey is missing. Set GOOGLE_MAPS_API_KEY in ios/Flutter/GoogleMapsKeys.xcconfig.")
    }

    guard let ocrRegistrar = registrar(forPlugin: "MeomchitOcrPlugin") else {
      fatalError("Unable to register Meomchit OCR plugin.")
    }
    let ocrChannel = FlutterMethodChannel(
      name: "meomchit/ocr",
      binaryMessenger: ocrRegistrar.messenger()
    )
    ocrChannel.setMethodCallHandler { call, result in
      guard call.method == "extractText" else {
        result(FlutterMethodNotImplemented)
        return
      }
      guard let args = call.arguments as? [String: Any],
            let path = args["path"] as? String else {
        result(FlutterError(code: "INVALID_ARGUMENT", message: "Image path is missing.", details: nil))
        return
      }

      Self.extractText(from: path, result: result)
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }

  private static func extractText(from path: String, result: @escaping FlutterResult) {
    guard let image = UIImage(contentsOfFile: path),
          let cgImage = image.cgImage else {
      result(FlutterError(code: "IMAGE_LOAD_FAILED", message: "Unable to load image.", details: nil))
      return
    }

    let request = VNRecognizeTextRequest { request, error in
      if let error = error {
        result(FlutterError(code: "OCR_FAILED", message: error.localizedDescription, details: nil))
        return
      }

      let lines = (request.results as? [VNRecognizedTextObservation])?
        .compactMap { $0.topCandidates(1).first?.string } ?? []
      result(lines.joined(separator: "\n"))
    }
    request.recognitionLevel = .accurate
    request.usesLanguageCorrection = true
    request.recognitionLanguages = ["ko-KR", "en-US"]

    DispatchQueue.global(qos: .userInitiated).async {
      do {
        try VNImageRequestHandler(cgImage: cgImage, options: [:]).perform([request])
      } catch {
        result(FlutterError(code: "OCR_FAILED", message: error.localizedDescription, details: nil))
      }
    }
  }
}
