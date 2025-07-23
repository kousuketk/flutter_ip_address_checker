import Flutter
import UIKit
import Foundation

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
      } else if call.method == "getSystemProxyDetails" {
        self.getSystemProxyDetails(result: result)
      } else if call.method == "getNSURLSessionProxy" {
        self.getNSURLSessionProxy(result: result)
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
  
  private func getSystemProxyDetails(result: @escaping FlutterResult) {
    // Get system proxy settings using SystemConfiguration framework
    guard let proxySettings = CFNetworkCopySystemProxySettings()?.takeRetainedValue() as? [String: Any] else {
      result(["error": "Failed to get CFNetworkCopySystemProxySettings"])
      return
    }
    
    // Convert all values to strings for safe transmission to Flutter
    var detailsDict: [String: String] = [:]
    
    for (key, value) in proxySettings {
      let keyStr = String(describing: key)
      let valueStr = String(describing: value)
      detailsDict[keyStr] = valueStr
    }
    
    // Add metadata
    detailsDict["_metadata_total_keys"] = String(proxySettings.count)
    detailsDict["_metadata_source"] = "CFNetworkCopySystemProxySettings"
    
    print("iOS CFNetwork Debug: Returning \(detailsDict.count) settings")
    result(detailsDict)
  }
  
  private func getNSURLSessionProxy(result: @escaping FlutterResult) {
    // Get proxy settings from NSURLSessionConfiguration
    let defaultConfig = URLSessionConfiguration.default
    
    var proxyInfo: [String: Any] = [:]
    
    // Check if connectionProxyDictionary exists
    if let proxyDict = defaultConfig.connectionProxyDictionary {
      print("iOS NSURLSession Debug: Found connectionProxyDictionary with \(proxyDict.count) keys")
      
      // Convert proxy dictionary to string representation for debugging
      var proxyDetails: [String: String] = [:]
      for (key, value) in proxyDict {
        let keyStr = String(describing: key)
        let valueStr = String(describing: value)
        proxyDetails[keyStr] = valueStr
        print("iOS NSURLSession Debug: \(keyStr) = \(valueStr)")
      }
      
      // Try to extract HTTP proxy information
      if let httpProxy = proxyDict[kCFNetworkProxiesHTTPProxy] as? String,
         let httpPort = proxyDict[kCFNetworkProxiesHTTPPort] as? Int {
        print("iOS NSURLSession Debug: Found HTTP proxy: \(httpProxy):\(httpPort)")
        proxyInfo["host"] = httpProxy
        proxyInfo["port"] = httpPort
        proxyInfo["type"] = "HTTP"
      }
      
      // Try to extract HTTPS proxy information (if available)
      // Note: kCFNetworkProxiesHTTPSProxy may not be available in all iOS versions
      let httpsProxyKey = "HTTPSProxy"
      let httpsPortKey = "HTTPSPort"
      
      if let httpsProxy = proxyDict[httpsProxyKey] as? String,
         let httpsPort = proxyDict[httpsPortKey] as? Int {
        print("iOS NSURLSession Debug: Found HTTPS proxy: \(httpsProxy):\(httpsPort)")
        if proxyInfo["host"] == nil {
          proxyInfo["host"] = httpsProxy
          proxyInfo["port"] = httpsPort
          proxyInfo["type"] = "HTTPS"
        } else {
          proxyInfo["httpsHost"] = httpsProxy
          proxyInfo["httpsPort"] = httpsPort
        }
      }
      
      // Add all proxy details for debugging
      proxyInfo["allProxySettings"] = proxyDetails
      proxyInfo["source"] = "NSURLSessionConfiguration"
      
    } else {
      print("iOS NSURLSession Debug: No connectionProxyDictionary found")
      proxyInfo["source"] = "NSURLSessionConfiguration"
      proxyInfo["message"] = "No proxy configuration found"
    }
    
    // Also check other configuration properties
    proxyInfo["allowsCellularAccess"] = defaultConfig.allowsCellularAccess
    
    // Check iOS version for newer properties
    if #available(iOS 13.0, *) {
      proxyInfo["allowsConstrainedNetworkAccess"] = defaultConfig.allowsConstrainedNetworkAccess
      proxyInfo["allowsExpensiveNetworkAccess"] = defaultConfig.allowsExpensiveNetworkAccess
    } else {
      proxyInfo["allowsConstrainedNetworkAccess"] = "Not available (iOS 13.0+)"
      proxyInfo["allowsExpensiveNetworkAccess"] = "Not available (iOS 13.0+)"
    }
    
    result(proxyInfo)
  }
  
}
