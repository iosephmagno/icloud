import Flutter
import UIKit

public class SwiftIcloudPlugin: NSObject, FlutterPlugin {
    var availabilityStreamHandler: StreamHandler?
    var messenger: FlutterBinaryMessenger?
    var queue = OperationQueue()
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let messenger = registrar.messenger();
        let channel = FlutterMethodChannel(name: "icloud", binaryMessenger: messenger)
        let instance = SwiftIcloudAvailabilityPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
        instance.messenger = messenger
        
        let eventChannel = FlutterEventChannel(name: "icloud/event/availability", binaryMessenger: registrar.messenger())
        instance.availabilityStreamHandler = StreamHandler()
        eventChannel.setStreamHandler(instance.availabilityStreamHandler)
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "isAvailable":
            isAvailable(call, result)
        case "watchAvailability":
            watchAvailability(call, result)
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    private func isAvailable(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
        result(FileManager.default.ubiquityIdentityToken != nil)
    }
    
    private func watchAvailability(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
        result(nil)
        availabilityStreamHandler?.onCancelHandler = { [self] in
            removeObservers()
        }
        NotificationCenter.default.addObserver(forName: NSNotification.Name.NSUbiquityIdentityDidChange, object: nil, queue: queue) {
            [self] (notification) in
            availabilityStreamHandler?.setEvent(FileManager.default.ubiquityIdentityToken != nil)
        }
    }
    
    private func removeObservers(){
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.NSUbiquityIdentityDidChange, object: nil)
    }
}

class StreamHandler: NSObject, FlutterStreamHandler {
    private var _eventSink: FlutterEventSink?
    var onCancelHandler: (() -> Void)?
    
    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        _eventSink = events
        DebugHelper.log("on listen")
        return nil
    }
    
    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        onCancelHandler?()
        _eventSink = nil
        DebugHelper.log("on cancel")
        return nil
    }
    
    func setEvent(_ data: Any) {
        _eventSink?(data)
    }
}

class DebugHelper {
    public static func log(_ message: String) {
        #if DEBUG
        print(message)
        #endif
    }
}
