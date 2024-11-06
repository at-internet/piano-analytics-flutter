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
            var skipResult = false
            switch call.method {
            // Main
            case "init":
                try handleInit(call)
            case "send":
                try handleSend(call)
            // User
            case "getUser":
                skipResult = true
                try handleGetUser(result)
            case "setUser":
                try handleSetUser(call)
            case "deleteUser":
                PianoAnalytics.shared.deleteUser()
            // Visitor
            case "getVisitorId":
                skipResult = true
                handleGetVisitorId(result)
            case "setVisitorId":
                try handleSetVisitorId(call)
            // Privacy
            case "privacyIncludeStorageFeatures":
                try privacyChangeStorageFeatures(call)
            case "privacyExcludeStorageFeatures":
                try privacyChangeStorageFeatures(call, false)
            case "privacyIncludeProperties":
                try privacyChangeProperties(call)
            case "privacyExcludeProperties":
                try privacyChangeProperties(call, false)
            case "privacyIncludeEvents":
                try privacyChangeEvents(call)
            case "privacyExcludeEvents":
                try privacyChangeEvents(call, false)
            default:
                result(FlutterMethodNotImplemented)
            }
            if !skipResult {
                result(nil)
            }
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
        let visitorIdType = VisitorIdType.from(try getArgument(call, arguments, "visitorIDType"))
        
        var configurationBuilder = ConfigurationBuilder()
            .withSite(try getArgument(call, arguments, "site"))
            .withCollectDomain(try getArgument(call, arguments, "collectDomain"))
            .withVisitorIdType(visitorIdType.rawValue)
        
        if let storageLifetimeVisitor = arguments["storageLifetimeVisitor"] as? Int {
            _ = configurationBuilder.withStorageLifetimeVisitor(storageLifetimeVisitor)
        }
        
        if let visitorStorageMode = arguments["visitorStorageMode"] as? String {
            _ = configurationBuilder.withVisitorStorageMode(try PianoAnalyticsPlugin.getVisitorStorageMode(visitorStorageMode))
        }
        
        if let ignoreLimitedAdvertisingTracking = arguments["ignoreLimitedAdvertisingTracking"] as? Bool {
            _ = configurationBuilder.enableIgnoreLimitedAdTracking(ignoreLimitedAdvertisingTracking)
        }
        
        PianoAnalytics.shared.setConfiguration(configurationBuilder.build())
        
        if let visitorId = arguments["visitorId"] as? String, visitorIdType == .Custom {
            PianoAnalytics.shared.setVisitorId(visitorId)
        }
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
    
    private func handleGetUser(_ result: @escaping FlutterResult) throws {
        PianoAnalytics.shared.getUser { user in
            guard let user else {
                result(nil)
                return
            }
            
            result([
                "id": user.id,
                "category": user.category
            ])
        }
    }
    
    private func handleSetUser(_ call: FlutterMethodCall) throws {
        let arguments = try getArguments(call)
        
        PianoAnalytics.shared.setUser(
            try getArgument(call, arguments, "id"),
            category: arguments["category"] as? String,
            enableStorage: arguments["enableStorage"] as? Bool ?? true
        )
    }
    
    private func handleGetVisitorId(_ result: @escaping FlutterResult) {
        PianoAnalytics.shared.getVisitorId { visitorId in
            result(visitorId)
        }
    }
    
    private func handleSetVisitorId(_ call: FlutterMethodCall) throws {
        let arguments = try getArguments(call)
        let visitorId: String = try getArgument(call, arguments, "visitorId")
        
        PianoAnalytics.shared.getConfiguration(.VisitorIdType) { type in
            if type == VisitorIdType.Custom.rawValue {
                PianoAnalytics.shared.setVisitorId(visitorId)
            }
        }
    }
    
    private func privacyChangeStorageFeatures(_ call: FlutterMethodCall, _ include: Bool = true) throws {
        let arguments = try getArguments(call)
        
        let features: [String] = try getArgument(call, arguments, "features")
        let keys = try features.map { try PianoAnalyticsPlugin.getStorageKeyByFeature($0) }
        
        let modes: [String] = try getArgument(call, arguments, "modes")
        let privacyModes = try modes.map { try PianoAnalyticsPlugin.getPrivacyMode($0) }
        
        if include {
            PianoAnalytics.shared.privacyIncludeStorageKeys(keys, privacyModes: privacyModes)
        } else {
            PianoAnalytics.shared.privacyExcludeStorageKeys(keys, privacyModes: privacyModes)
        }
    }
    
    private func privacyChangeProperties(_ call: FlutterMethodCall, _ include: Bool = true) throws {
        let arguments = try getArguments(call)
        
        let propertyNames: [String] = try getArgument(call, arguments, "propertyNames")
        
        let modes: [String] = try getArgument(call, arguments, "modes")
        let privacyModes = try modes.map { try PianoAnalyticsPlugin.getPrivacyMode($0) }
        
        let eventNames = arguments["eventNames"] as? [String]
        
        if include {
            PianoAnalytics.shared.privacyIncludeProperties(propertyNames, privacyModes: privacyModes, eventNames: eventNames)
        } else {
            PianoAnalytics.shared.privacyExcludeProperties(propertyNames, privacyModes: privacyModes, eventNames: eventNames)
        }
    }
    
    private func privacyChangeEvents(_ call: FlutterMethodCall, _ include: Bool = true) throws {
        let arguments = try getArguments(call)
        
        let eventNames: [String] = try getArgument(call, arguments, "eventNames")
        
        let modes: [String] = try getArgument(call, arguments, "modes")
        let privacyModes = try modes.map { try PianoAnalyticsPlugin.getPrivacyMode($0) }
        
        if include {
            PianoAnalytics.shared.privacyIncludeEvents(eventNames, privacyModes: privacyModes)
        } else {
            PianoAnalytics.shared.privacyExcludeEvents(eventNames, privacyModes: privacyModes)
        }
    }
    
    private static func getStorageKeyByFeature(_ feature: String) throws -> String {
        switch feature {
        case "VISITOR":
            return PA.Privacy.Storage.VisitorId
        case "CRASH":
            return PA.Privacy.Storage.Crash
        case "LIFECYCLE":
            return PA.Privacy.Storage.Lifecycle
        case "PRIVACY":
            return PA.Privacy.Storage.Privacy
        case "USER":
            return PA.Privacy.Storage.User
        default:
            throw PluginError.message("Invalid feature \"\(feature)\"")
        }
    }
    
    private static func getPrivacyMode(_ name: String) throws -> String {
        switch name {
        case "opt-in":
            return "optin"
        case "opt-out":
            return "optout"
        case "exempt":
            return "exempt"
        case "custom":
            return "custom"
        case "no-consent":
            return "no-consent"
        case "no-storage":
            return "no-storage"
        default:
            throw PluginError.message("Invalid privacy mode \"\(name)\"")
        }
    }
    
    private static func getVisitorStorageMode(_ name: String) throws -> String {
        switch name {
        case "fixed":
            return "fixed"
        case "relative":
            return "relative"
        default:
            throw PluginError.message("Invalid visitor storage mode \"\(name)\"")
        }
    }
}

fileprivate extension VisitorIdType {
    
    static func from(_ name: String) -> Self {
        switch name {
        case "ADID": return VisitorIdType.IDFA
        case "CUSTOM": return VisitorIdType.Custom
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
