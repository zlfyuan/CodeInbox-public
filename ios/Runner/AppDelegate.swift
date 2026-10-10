import Flutter
import UIKit
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    let ok = super.application(application, didFinishLaunchingWithOptions: launchOptions)
    // Registrar does not need window; UIScene leaves window nil at launch.
    if let registrar = self.registrar(forPlugin: "CodeInboxBadge") {
      let channel = FlutterMethodChannel(name: "codeinbox/badge", binaryMessenger: registrar.messenger())
      channel.setMethodCallHandler { call, result in
        guard call.method == "setBadge", let n = call.arguments as? Int else {
          result(FlutterMethodNotImplemented)
          return
        }
        UNUserNotificationCenter.current().requestAuthorization(options: [.badge]) { _, _ in
          DispatchQueue.main.async {
            if #available(iOS 16.0, *) {
              UNUserNotificationCenter.current().setBadgeCount(n)
            } else {
              UIApplication.shared.applicationIconBadgeNumber = n
            }
          }
        }
        result(nil)
      }
    }
    return ok
  }
}
