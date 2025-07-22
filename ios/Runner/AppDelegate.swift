import Flutter
import UIKit
import SystemConfiguration

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    
    let controller : FlutterViewController = window?.rootViewController as! FlutterViewController
    let proxyChannel = FlutterMethodChannel(name: "proxy_helper",
                                          binaryMessenger: controller.binaryMessenger)
    
    proxyChannel.setMethodCallHandler({
      (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
      if call.method == "getSystemProxy" {
        self.getSystemProxy(result: result)
      } else {
        result(FlutterMethodNotImplemented)
      }
    })
    
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
  
  private func getSystemProxy(result: @escaping FlutterResult) {
    // Get system proxy settings using SystemConfiguration framework
    guard let proxySettings = CFNetworkCopySystemProxySettings()?.takeRetainedValue() as? [String: Any] else {
      result(nil)
      return
    }
    
    // Check for HTTP proxy using string literals to avoid iOS availability issues
    if let httpEnable = proxySettings["HTTPEnable"] as? Int,
       httpEnable == 1,
       let httpProxy = proxySettings["HTTPProxy"] as? String,
       let httpPort = proxySettings["HTTPPort"] as? Int {
      
      let proxyInfo: [String: Any] = [
        "host": httpProxy,
        "port": httpPort
      ]
      result(proxyInfo)
      return
    }
    
    // Check using kCFNetworkProxies constants that are available in iOS
    if let httpEnable = proxySettings[kCFNetworkProxiesHTTPEnable as String] as? Int,
       httpEnable == 1,
       let httpProxy = proxySettings[kCFNetworkProxiesHTTPProxy as String] as? String,
       let httpPort = proxySettings[kCFNetworkProxiesHTTPPort as String] as? Int {
      
      let proxyInfo: [String: Any] = [
        "host": httpProxy,
        "port": httpPort
      ]
      result(proxyInfo)
      return
    }
    
    // No proxy configured
    result(nil)
  }
}
