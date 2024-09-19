import Flutter
import UIKit

import PianoAnalytics

fileprivate let dateType = UInt8(128)
fileprivate let dateFormatter = ISO8601DateFormatter()

fileprivate class Reader: FlutterStandardReader {
    
    override func readValue(ofType type: UInt8) -> Any? {
        switch type {
        case dateType:
            var value: Int64 = 0
            readBytes(&value, length: 8)
            return Date(timeIntervalSince1970: TimeInterval(value / 1000 ))
        default:
            return super.readValue(ofType: type)
        }
    }
}

fileprivate class ReaderWriter: FlutterStandardReaderWriter {
    
    override func reader(with data: Data) -> FlutterStandardReader {
        Reader(data: data)
    }
}

public class PianoAnalyticsPlugin: NSObject, FlutterPlugin {
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(
            name: "piano_analytics", binaryMessenger: registrar.messenger(),
            codec: FlutterStandardMethodCodec(readerWriter: ReaderWriter())
        )
        let instance = PianoAnalyticsPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        do {
            switch call.method {
            case "init":
                try handleInit(call)
            case "send":
                try handleSend(call)
            default:
                result(FlutterMethodNotImplemented)
            }
            result(nil)
        } catch let error as PluginError {
            switch error {
            case .message(let message): result(FlutterError.from(call, message))
            case .inner(let inner): result(inner)
            }
        } catch {
            result(FlutterError.from(call, error.localizedDescription))
        }
    }

    private func handleInit(_ call: FlutterMethodCall) throws {
        let arguments = try getArguments(call)
        
        PianoAnalytics.shared.setConfiguration(
            ConfigurationBuilder()
                .withSite(try getArgument(call, arguments, "site"))
                .withCollectDomain(try getArgument(call, arguments, "collectDomain"))
                .withVisitorIdType(VisitorIdType.from(try getArgument(call, arguments, "visitorIDType")).rawValue)
                .build()
        )
    }

    private func handleSend(_ call: FlutterMethodCall) throws {
        let arguments = try getArguments(call)
        let events: [[String:Any]] = try getArgument(call, arguments, "events")
        
        PianoAnalytics.shared.sendEvents(
            try events.map { event in
                guard let name = event["name"] as? String else {
                    throw PluginError.message("Undefined event name")
                }
                let properties = try (event["data"] as? [String:Any])?.map { property in
                    guard let value = property.value as? [String:Any] else {
                        throw PluginError.message("Undefined property value of event \"\(property.key)\"")
                    }
                    guard let propertyValue = value["value"] else {
                        throw PluginError.message("Undefined property value of event \"\(property.key)\"")
                    }
                    return try Property.from(property.key, propertyValue, forceType: Property.forceType(value["forceType"] as? String))
                }
                return Event(name, properties: Set(properties ?? []))
            }
        )
    }
}

fileprivate extension VisitorIdType {
    
    static func from(_ name: String) -> Self {
        switch name {
        case "ADID": return VisitorIdType.IDFA
        default: return VisitorIdType.UUID
        }
    }
}

fileprivate extension Property {
    
    static func forceType(_ name: String?) throws -> PA.PropertyType? {
        guard let name else {
            return nil
        }
        
        switch name {
        case "b":
            return .bool
        case "n":
            return .int
        case "f":
            return .float
        case "s":
            return .string
        case "d":
            return .date
        case "a:n":
            return .intArray
        case "a:f":
            return .floatArray
        case "a:s":
            return .stringArray
        default:
            throw PluginError.message("Undefined force type \"\(name)\"")
        }
    }
    
    static func from(_ name: String, _ value: Any, forceType: PA.PropertyType? = nil) throws -> Property {
        switch value {
        case let v as Bool:
            return try Property(name, v, forceType: forceType)
        case let v as Int:
            return try Property(name, v, forceType: forceType)
        case let v as Int64:
            return try Property(name, v, forceType: forceType)
        case let v as Double:
            return try Property(name, v, forceType: forceType)
        case let v as String:
            return try Property(name, v, forceType: forceType)
        case let v as Date:
            return try Property(name, v)
        case let v as [Int]:
            return try Property(name, v, forceType: forceType)
        case let v as [Double]:
            return try Property(name, v, forceType: forceType)
        case let v as [String]:
            return try Property(name, v, forceType: forceType)
        default:
            throw PluginError.message("Undefined type for event property \"\(name)\"")
        }
    }
}
