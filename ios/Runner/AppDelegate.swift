import Flutter
import UIKit
import UserNotifications
import UniformTypeIdentifiers

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate, UIDocumentPickerDelegate {
  private var csvResult: FlutterResult?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    UNUserNotificationCenter.current().delegate = self
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    let channel = FlutterMethodChannel(
      name: "com.lekshan.moneyflow/export",
      binaryMessenger: engineBridge.applicationRegistrar.messenger()
    )
    channel.setMethodCallHandler { [weak self] call, result in
      if call.method == "timeZone" {
        result(TimeZone.current.identifier)
        return
      }
      guard call.method == "shareCsv" || call.method == "pickCsv" else {
        result(FlutterMethodNotImplemented)
        return
      }
      guard
        let root = UIApplication.shared.connectedScenes
          .compactMap({ $0 as? UIWindowScene })
          .first(where: { $0.activationState == .foregroundActive })?
          .windows.first(where: { $0.isKeyWindow })?.rootViewController
      else {
        result(FlutterError(code: "window_unavailable", message: "No active window.", details: nil))
        return
      }
      var presenter = root
      while let presented = presenter.presentedViewController {
        presenter = presented
      }
      if call.method == "pickCsv", let self {
        guard self.csvResult == nil else {
          result(FlutterError(code: "picker_busy", message: "A file picker is already open.", details: nil))
          return
        }
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.commaSeparatedText, .plainText])
        picker.delegate = self
        self.csvResult = result
        presenter.present(picker, animated: true)
        return
      }
      guard let path = call.arguments as? String else {
        result(FlutterError(code: "export_failed", message: "No export file.", details: nil))
        return
      }
      let file = URL(fileURLWithPath: path)
      let share = UIActivityViewController(activityItems: [file], applicationActivities: nil)
      share.popoverPresentationController?.sourceView = presenter.view
      share.popoverPresentationController?.sourceRect = CGRect(
        x: presenter.view.bounds.midX, y: presenter.view.bounds.midY, width: 1, height: 1
      )
      share.completionWithItemsHandler = { _, _, _, _ in
        try? FileManager.default.removeItem(at: file)
      }
      presenter.present(share, animated: true)
      result(nil)
    }
  }

  func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
    csvResult?(nil)
    csvResult = nil
  }

  func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
    guard let result = csvResult else { return }
    csvResult = nil
    guard let url = urls.first else {
      result(nil)
      return
    }
    DispatchQueue.global(qos: .userInitiated).async {
      let accessing = url.startAccessingSecurityScopedResource()
      defer { if accessing { url.stopAccessingSecurityScopedResource() } }
      do {
        let handle = try FileHandle(forReadingFrom: url)
        defer { try? handle.close() }
        let limit = 5_000_000
        var bytes = Data()
        while let chunk = try handle.read(upToCount: 8192), !chunk.isEmpty {
          guard bytes.count + chunk.count <= limit else {
            DispatchQueue.main.async {
              result(FlutterError(code: "file_too_large", message: "Choose a CSV file smaller than 5 MB.", details: nil))
            }
            return
          }
          bytes.append(chunk)
        }
        let typedData = FlutterStandardTypedData(bytes: bytes)
        DispatchQueue.main.async { result(typedData) }
      } catch {
        DispatchQueue.main.async {
          result(FlutterError(code: "read_failed", message: "Couldn’t read the CSV file.", details: nil))
        }
      }
    }
  }
}
