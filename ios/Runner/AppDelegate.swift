import Flutter
import StoreKit
import UIKit

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
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "WharfTestDevice") {
      TestDeviceChannel.register(messenger: registrar.messenger())
    }
  }
}

/// Tells TestFlight, App Review, Xcode runs and the simulator apart from real
/// installs so analytics can flag them (`is_test`). TestFlight builds are
/// release builds and do emit, so the app cannot rely on debug mode alone.
/// `detect` is the full answer (a StoreKit round-trip on a real phone);
/// `detectLocal` answers at once and only ever says simulator or none.
final class TestDeviceChannel: NSObject {
  static func register(messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(
      name: "app.mentalmetal.wharfwod/test_device",
      binaryMessenger: messenger
    )
    channel.setMethodCallHandler { call, result in
      guard call.method == "detect" || call.method == "detectLocal" else {
        result(FlutterMethodNotImplemented)
        return
      }
      #if targetEnvironment(simulator)
      // A simulator build is never a real install, whatever StoreKit says.
      result("simulator")
      #else
      if call.method == "detectLocal" {
        // Nothing local marks a real phone as a test device; sandbox vs
        // production needs the StoreKit round-trip below.
        result("none")
        return
      }
      if #available(iOS 16.0, *) {
        Task {
          let reason = await environmentReason()
          await MainActor.run { result(reason) }
        }
      } else {
        result(receiptReason())
      }
      #endif
    }
  }

  /// StoreKit 2: sandbox covers TestFlight and App Review; xcode is a local run.
  @available(iOS 16.0, *)
  private static func environmentReason() async -> String {
    do {
      let verification = try await AppTransaction.shared
      let transaction: AppTransaction
      switch verification {
      case .verified(let value), .unverified(let value, _):
        transaction = value
      }
      if transaction.environment == .sandbox { return "sandbox_receipt" }
      if transaction.environment == .xcode { return "xcode" }
      return "none"
    } catch {
      return receiptReason()
    }
  }

  /// iOS 15 fallback: TestFlight and App Review installs carry a sandbox receipt.
  private static func receiptReason() -> String {
    return Bundle.main.appStoreReceiptURL?.lastPathComponent == "sandboxReceipt"
      ? "sandbox_receipt" : "none"
  }
}
