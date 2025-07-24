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
  
  
  private func getNSURLSessionProxy(result: @escaping FlutterResult) {
    // Get proxy settings from NSURLSessionConfiguration
    let defaultConfig = URLSessionConfiguration.default
    
    var proxyInfo: [String: Any] = [:]
    
    // Check if connectionProxyDictionary exists
    if let proxyDict = defaultConfig.connectionProxyDictionary {
      // Convert all proxy dictionary entries to string representation
      var allProxySettings: [String: Any] = [:]
      for (key, value) in proxyDict {
        let keyStr = String(describing: key)
        allProxySettings[keyStr] = value
      }
      
      // Try to extract HTTP proxy information for backward compatibility
      if let httpProxy = proxyDict[kCFNetworkProxiesHTTPProxy] as? String,
         let httpPort = proxyDict[kCFNetworkProxiesHTTPPort] as? Int {
        proxyInfo["host"] = httpProxy
        proxyInfo["port"] = httpPort
        proxyInfo["type"] = "HTTP"
      }
      
      // Try to extract HTTPS proxy information (if available)
      let httpsProxyKey = "HTTPSProxy"
      let httpsPortKey = "HTTPSPort"
      
      if let httpsProxy = proxyDict[httpsProxyKey] as? String,
         let httpsPort = proxyDict[httpsPortKey] as? Int {
        if proxyInfo["host"] == nil {
          proxyInfo["host"] = httpsProxy
          proxyInfo["port"] = httpsPort
          proxyInfo["type"] = "HTTPS"
        } else {
          proxyInfo["httpsHost"] = httpsProxy
          proxyInfo["httpsPort"] = httpsPort
        }
      }
      
      // Add all proxy settings (this is the main addition)
      proxyInfo["connectionProxyDictionary"] = allProxySettings
      proxyInfo["proxyDictionaryCount"] = proxyDict.count
      proxyInfo["source"] = "NSURLSessionConfiguration"
      
    } else {
      proxyInfo["source"] = "NSURLSessionConfiguration"
      proxyInfo["message"] = "No proxy configuration found"
      proxyInfo["connectionProxyDictionary"] = [:]
      proxyInfo["proxyDictionaryCount"] = 0
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
    
    // Get HTTPAdditionalHeaders
    if let additionalHeaders = defaultConfig.httpAdditionalHeaders {
      var httpHeaders: [String: Any] = [:]
      for (key, value) in additionalHeaders {
        let keyStr = String(describing: key)
        httpHeaders[keyStr] = value
      }
      proxyInfo["httpAdditionalHeaders"] = httpHeaders
      proxyInfo["httpAdditionalHeadersCount"] = additionalHeaders.count
    } else {
      proxyInfo["httpAdditionalHeaders"] = [:]
      proxyInfo["httpAdditionalHeadersCount"] = 0
    }
    
    result(proxyInfo)
  }
  
}
