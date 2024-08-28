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
            return dateFormatter.string(from: Date(timeIntervalSince1970: TimeInterval(value / 1000 )))
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
        
        PianoConsentsPlugin.register(with: registrar)
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
                return Event(name, data: event["data"] as? [String:Any] ?? [:])
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
