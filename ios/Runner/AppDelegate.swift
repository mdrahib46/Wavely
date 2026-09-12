import Flutter
import UIKit
import NetworkExtension
import SystemConfiguration.CaptiveNetwork

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private let CHANNEL = "com.wavely.app/wifi_scanner"

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)

    let binaryMessenger = engineBridge.pluginRegistry.registrar(forPlugin: "WifiScannerPlugin").messenger()
    let wifiChannel = FlutterMethodChannel(name: CHANNEL, binaryMessenger: binaryMessenger)

    wifiChannel.setMethodCallHandler { (call: FlutterMethodCall, result: @escaping FlutterResult) in
      switch call.method {
      case "getConnectedNetwork":
        if #available(iOS 14.0, *) {
          NEHotspotNetwork.fetchCurrent { hotspotNetwork in
            guard let network = hotspotNetwork else {
              result(nil)
              return
            }
            result([
              "ssid": network.ssid,
              "bssid": network.bssid,
              "rssi": Int(network.signalStrength * -100.0),
              "security": network.isSecure ? "WPA2/WPA3" : "Open",
              "band": "5 GHz",
              "channel": 36
            ])
          }
        } else {
          result(nil)
        }

      case "getScanResults":
        if #available(iOS 14.0, *) {
          NEHotspotNetwork.fetchCurrent { network in
            if let net = network {
              result([[
                "ssid": net.ssid,
                "bssid": net.bssid,
                "rssi": -55,
                "frequency": 5180,
                "channel": 36,
                "band": "5 GHz",
                "security": net.isSecure ? "WPA3" : "Open",
                "standard": "Wi-Fi 6"
              ]])
            } else {
              result([])
            }
          }
        } else {
          result([])
        }

      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }
}
