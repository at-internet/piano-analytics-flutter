import Flutter
import UIKit

import PianoConsents

public class PianoConsentsPlugin: NSObject, FlutterPlugin {
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(
            name: "piano_consents", binaryMessenger: registrar.messenger()
        )
        let instance = PianoConsentsPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        do {
            switch call.method {
            case "init":
                try handleInit(call)
            case "set":
                try handleSet(call)
            case "setAll":
                try handleSetAll(call)
            case "clear":
                handleClear()
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
        
        let requireConsents = arguments["requireConsents"] as? Bool ?? false
        
        var defaultPurposes: [PianoConsentProduct:PianoConsentPurpose]?
        if let purposes = arguments["defaultPurposes"] as? [String:String], !purposes.isEmpty {
            defaultPurposes = Dictionary(
                try purposes.map { (try PianoConsentProduct.from($0), try PianoConsentPurpose.from($1)) },
                uniquingKeysWith: { key, _ in key }
            )
        }
        
        PianoConsents.initialize(
            configuration: PianoConsentsConfiguration(
                requireConsents: requireConsents,
                defaultPurposes: defaultPurposes
            )
        )
    }
    
    private func handleSet(_ call: FlutterMethodCall) throws {
        let arguments = try getArguments(call)

        try PianoConsents.shared.set(
            purpose: try PianoConsentPurpose.from(try getArgument(call, arguments, "purpose")),
            mode: try PianoConsentMode.from(try getArgument(call, arguments, "mode")),
            products: try (arguments["products"] as? [String])?.map { try PianoConsentProduct.from($0) } ?? []
        )
    }
    
    private func handleSetAll(_ call: FlutterMethodCall) throws {
        try PianoConsents.shared.setAll(
            mode: try PianoConsentMode.from(try getArgument(call, try getArguments(call), "mode"))
        )
    }
    
    private func handleClear() {
        PianoConsents.shared.clear()
    }
}

fileprivate extension PianoConsentProduct {
    
    static func from(_ name: String) throws -> Self {
        switch name {
        case "PA": return PianoConsentProduct.PA
        case "DMP": return PianoConsentProduct.DMP
        case "COMPOSER": return PianoConsentProduct.COMPOSER
        case "ID": return PianoConsentProduct.ID
        case "VX": return PianoConsentProduct.VX
        case "ESP": return PianoConsentProduct.ESP
        case "SOCIAL_FLOW": return PianoConsentProduct.SOCIAL_FLOW
        default: throw PluginError.message("Invalid value for consent product \"\(name)\"")
        }
    }
}

fileprivate extension PianoConsentPurpose {
    
    static func from(_ name: String) throws -> Self {
        switch name {
        case "AM": return PianoConsentPurpose.AUDIENCE_MEASUREMENT
        case "CP": return PianoConsentPurpose.CONTENT_PERSONALISATION
        case "AD": return PianoConsentPurpose.ADVERTISING
        case "PR": return PianoConsentPurpose.PERSONAL_RELATIONSHIP
        default: throw PluginError.message("Invalid value for consent purpose \"\(name)\"")
        }
    }
}

fileprivate extension PianoConsentMode {

    static func from(_ name: String) throws -> Self {
        switch name {
        case "opt-in": return PianoConsentMode.OPT_IN
        case "essential": return PianoConsentMode.ESSENTIAL
        case "opt-out": return PianoConsentMode.OPT_OUT
        case "custom": return PianoConsentMode.CUSTOM
        case "not-acquired": return PianoConsentMode.NOT_ACQUIRED
        default: throw PluginError.message("Invalid value for consent mode \"\(name)\"")
        }
    }
}
