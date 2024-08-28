package io.piano.flutter.piano_analytics

import android.content.Context
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.piano.android.consents.PianoConsents
import io.piano.android.consents.models.ConsentConfiguration
import io.piano.android.consents.models.ConsentMode
import io.piano.android.consents.models.Product
import io.piano.android.consents.models.Purpose
import java.lang.ref.WeakReference

class PianoConsentsPlugin: FlutterPlugin, MethodCallHandler, ActivityAware {

    private lateinit var channel: MethodChannel

    private var context: WeakReference<Context?> = WeakReference(null)

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        context = WeakReference(binding.activity)
    }

    override fun onDetachedFromActivityForConfigChanges() {
        context = WeakReference(null)
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        context = WeakReference(binding.activity)
    }

    override fun onDetachedFromActivity() {
        context = WeakReference(null)
    }

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(
            flutterPluginBinding.binaryMessenger,
            "piano_consents"
        )
        channel.setMethodCallHandler(this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        try {
            when (call.method) {
                "init" -> handleInit(call)
                "set" -> handleSet(call)
                "setAll" -> handleSetAll(call)
                "clear" -> handleClear()
                else -> error("Unknown method")
            }
            result.success(null)
        } catch (e: Throwable) {
            result.error(call.method, e.message, null)
        }
    }

    private fun handleInit(call: MethodCall) {
        PianoConsents.init(
            context = context.get() ?: error("Activity not attached"),
            consentConfiguration = ConsentConfiguration(
                requireConsent = call.argument("requireConsents") as? Boolean ?: false,
                defaultPurposes = (call.argument("defaultPurposes") as? Map<*, *>)?.map {
                    getProduct(it.key as? String) to getPurpose(it.value as? String)
                }?.toMap()
            )
        )
    }

    private fun handleSet(call: MethodCall) {
        PianoConsents.getInstance().set(
            purpose = getPurpose(call.arg("purpose")),
            mode = getMode(call.arg("mode")),
            products = (call.arg("products") as? List<String>)?.map {
                getProduct(it)
            }?.toTypedArray() ?: arrayOf()
        )
    }

    private fun handleSetAll(call: MethodCall) {
        PianoConsents.getInstance().setAll(
            mode = getMode(call.arg("mode"))
        )
    }

    private fun handleClear() {
        PianoConsents.getInstance().clear()
    }

    companion object {

        @JvmStatic
        private fun getProduct(name: String?) =
            Product.entries.firstOrNull { it.alias == name }
                ?: error("Invalid value for consent product \"$name\"")

        @JvmStatic
        private fun getMode(name: String?) =
            ConsentMode.entries.firstOrNull { it.alias == name }
                ?: error("Invalid value for consent mode \"$name\"")

        @JvmStatic
        private fun getPurpose(name: String?) = when (name) {
            "AM" -> Purpose.AUDIENCE_MEASUREMENT
            "CP" -> Purpose.CONTENT_PERSONALISATION
            "AD" -> Purpose.ADVERTISING
            "PR" -> Purpose.PERSONAL_RELATIONSHIP
            else -> error("Invalid value for consent purpose \"$name\"")
        }
    }
}