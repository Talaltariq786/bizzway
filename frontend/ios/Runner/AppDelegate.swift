import Flutter
import GoogleMaps
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Must always run before any GoogleMap widget — skipping this crashes on iOS.
    let key = (Bundle.main.object(forInfoDictionaryKey: "GMSApiKey") as? String) ?? ""
    GMSServices.provideAPIKey(key)
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
