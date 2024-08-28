package io.piano.flutter.piano_analytics

import android.content.Context
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.StandardMessageCodec
import io.flutter.plugin.common.StandardMethodCodec
import io.piano.android.analytics.Configuration
import io.piano.android.analytics.PianoAnalytics
import io.piano.android.analytics.model.Event
import io.piano.android.analytics.model.Property
import io.piano.android.analytics.model.PropertyName
import io.piano.android.analytics.model.VisitorIDType
import io.piano.android.consents.PianoConsents
import java.lang.ref.WeakReference
import java.nio.ByteBuffer
import java.util.Date

private class Codec: StandardMessageCodec() {

    override fun readValueOfType(type: Byte, buffer: ByteBuffer): Any? = when (type) {
        DATE -> Date(buffer.getLong())
        else -> super.readValueOfType(type, buffer)
    }

    companion object {
        const val DATE = 128.toByte()
    }
}

class PianoAnalyticsPlugin : FlutterPlugin, MethodCallHandler, ActivityAware {

    private lateinit var channel: MethodChannel

    private val consentsPlugin = PianoConsentsPlugin()

    private var context: WeakReference<Context?> = WeakReference(null)

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        context = WeakReference(binding.activity)
        consentsPlugin.onAttachedToActivity(binding)
    }

    override fun onDetachedFromActivityForConfigChanges() {
        context = WeakReference(null)
        consentsPlugin.onDetachedFromActivityForConfigChanges()
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        context = WeakReference(binding.activity)
        consentsPlugin.onReattachedToActivityForConfigChanges(binding)
    }

    override fun onDetachedFromActivity() {
        context = WeakReference(null)
        consentsPlugin.onDetachedFromActivity()
    }

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(
            flutterPluginBinding.binaryMessenger,
            "piano_analytics",
            StandardMethodCodec(Codec())
        )
        channel.setMethodCallHandler(this)

        consentsPlugin
        consentsPlugin.onAttachedToEngine(flutterPluginBinding)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        consentsPlugin.onAttachedToEngine(binding)
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        try {
            when (call.method) {
                "init" -> handleInit(call)
                "send" -> handleSend(call)
                else -> error("Unknown method")
            }
            result.success(null)
        } catch (e: Throwable) {
            result.error(call.method, e.message, null)
        }
    }

    private fun handleInit(call: MethodCall) {
        PianoAnalytics.init(
            context = context.get() ?: error("Activity not attached"),
            configuration = Configuration.Builder(
                site = call.arg("site"),
                collectDomain = call.arg("collectDomain"),
                visitorIDType = getVisitorIDType(call.arg("visitorIDType"))
            ).build(),
            pianoConsents = getPianoConsents()
        )
    }

    private fun handleSend(call: MethodCall) {
        val events = call.arg<List<Map<String, Any>>>("events").map {
            val name = it["name"] as? String ?: error("Undefined event name")
            Event.Builder(
                name = name,
                properties = (it["data"] as? Map<*, *>)?.map { property ->
                    getProperty(
                        property.key as? String ?: error("Undefined property name of event \"$name\""),
                        property.value
                    )
                }?.toMutableSet() ?: mutableSetOf()
            ).build()
        }.toTypedArray()
        PianoAnalytics.getInstance().sendEvents(*events)
    }

    companion object {

        @JvmStatic
        private fun getPianoConsents() = try {
            PianoConsents.getInstance()
        } catch (_: IllegalStateException) {
            null
        }

        @JvmStatic
        private fun getVisitorIDType(name: String) = when (name) {
            "ADID" -> VisitorIDType.ADVERTISING_ID
            else -> VisitorIDType.UUID
        }

        @JvmStatic
        private fun getProperty(name: String, value: Any?) = when (value) {
            is Boolean -> Property(PropertyName(name), value)
            is Int -> Property(PropertyName(name), value)
            is Long -> Property(PropertyName(name), value)
            is Double -> Property(PropertyName(name), value)
            is String -> Property(PropertyName(name), value)
            is Date -> Property(PropertyName(name), value)
            is List<*> -> {
                when (value.first()) {
                    is Int -> Property(PropertyName(name), value.filterIsInstance<Int>().toTypedArray())
                    is Double -> Property(PropertyName(name), value.filterIsInstance<Double>().toTypedArray())
                    is String -> Property(PropertyName(name), value.filterIsInstance<String>().toTypedArray())
                    else -> { error("Invalid array value type of property \"$name\"") }
                }
            }
            else -> error("Invalid type of property \"$name\"")
        }
    }
}
