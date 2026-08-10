import Foundation
import Flutter

internal enum PluginError: Error {
    case message(String)
    case inner(FlutterError)
}

internal extension FlutterPlugin {
    
    func getArguments(_ call: FlutterMethodCall) throws -> [String:Any] {
        guard let arguments = call.arguments as? [String:Any] else {
            throw PluginError.inner(FlutterError(code: call.method, message: "Undefined arguments", details: nil))
        }
        return arguments
    }
    
    func getArgument<T>(_ call: FlutterMethodCall, _ arguments: [String:Any], _ key: String) throws -> T {
        guard let argument = arguments[key] as? T else {
            throw PluginError.inner(FlutterError(code: call.method, message: "Undefined argument \"\(key)\"", details: nil))
        }
        return argument
    }
}

internal extension FlutterError {
    
    static func from(_ call: FlutterMethodCall, _ message: String) -> FlutterError {
        FlutterError(code: call.method, message: message, details: nil)
    }
}
