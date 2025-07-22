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
      print("iOS Proxy Debug: Failed to get proxy settings")
      result(nil)
      return
    }
    
    print("iOS Proxy Debug: Proxy settings keys: \(proxySettings.keys)")
    
    // Check for HTTP proxy using string literals to avoid iOS availability issues
    if let httpEnable = proxySettings["HTTPEnable"] as? Int {
      print("iOS Proxy Debug: HTTPEnable = \(httpEnable)")
      if httpEnable == 1,
         let httpProxy = proxySettings["HTTPProxy"] as? String,
         let httpPort = proxySettings["HTTPPort"] as? Int {
        
        print("iOS Proxy Debug: Found HTTP proxy: \(httpProxy):\(httpPort)")
        let proxyInfo: [String: Any] = [
          "host": httpProxy,
          "port": httpPort
        ]
        result(proxyInfo)
        return
      }
    }
    
    // Check using kCFNetworkProxies constants that are available in iOS
    let httpEnableKey = kCFNetworkProxiesHTTPEnable as String
    let httpProxyKey = kCFNetworkProxiesHTTPProxy as String
    let httpPortKey = kCFNetworkProxiesHTTPPort as String
    
    print("iOS Proxy Debug: Checking keys - Enable: \(httpEnableKey), Proxy: \(httpProxyKey), Port: \(httpPortKey)")
    
    if let httpEnable = proxySettings[httpEnableKey] as? Int {
      print("iOS Proxy Debug: kCFNetworkProxiesHTTPEnable = \(httpEnable)")
      if httpEnable == 1,
         let httpProxy = proxySettings[httpProxyKey] as? String,
         let httpPort = proxySettings[httpPortKey] as? Int {
        
        print("iOS Proxy Debug: Found HTTP proxy via constants: \(httpProxy):\(httpPort)")
        let proxyInfo: [String: Any] = [
          "host": httpProxy,
          "port": httpPort
        ]
        result(proxyInfo)
        return
      }
    }
    
    // Debug: Print all available settings
    for (key, value) in proxySettings {
      print("iOS Proxy Debug: \(key) = \(value)")
    }
    
    print("iOS Proxy Debug: No proxy configured")
    result(nil)
  }
}
