import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    
    // Register Liquid Glass Tab Bar platform view
    let controller = window?.rootViewController as! FlutterViewController
    let factory = LiquidGlassTabBarFactory(messenger: controller.binaryMessenger)
    registrar(forPlugin: "LiquidGlassTabBar")?.register(
      factory,
      withId: "com.cleanslate/liquid_glass_tab_bar"
    )
    
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
