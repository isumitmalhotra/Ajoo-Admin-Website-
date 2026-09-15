import Flutter
import GoogleMaps
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Google Maps. On Android the key sits in AndroidManifest.xml as
    // com.google.android.geo.API_KEY; the iOS equivalent is handed to the
    // SDK here, before any map is built. Read from Info.plist (GMSApiKey)
    // so the key is configuration, not code — and so the release verifier
    // can refuse a build that still carries the placeholder.
    if let key = Bundle.main.object(forInfoDictionaryKey: "GMSApiKey") as? String,
       !key.isEmpty, !key.hasPrefix("REPLACE_WITH") {
      GMSServices.provideAPIKey(key)
    } else {
      // Without a key every map tile is blank, so say so where a developer
      // running the app will see it rather than fail silently.
      NSLog("Aajoo: GMSApiKey is not set in Info.plist — maps will render blank")
    }

    GeneratedPluginRegistrant.register(with: self)

    // Push. firebase_messaging registers with APNs itself once the Dart side
    // asks for permission; setting the notification-centre delegate here lets
    // a notification tapped while the app is running reach the plugin.
    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self as UNUserNotificationCenterDelegate
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
