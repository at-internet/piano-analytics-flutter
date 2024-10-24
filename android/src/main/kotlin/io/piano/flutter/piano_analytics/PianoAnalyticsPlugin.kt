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
import io.piano.android.analytics.model.PrivacyMode
import io.piano.android.analytics.model.PrivacyStorageFeature
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
            "piano_analytics",
            StandardMethodCodec(Codec())
        )
        channel.setMethodCallHandler(this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        try {
            when (call.method) {
                "init" -> handleInit(call)
                "send" -> handleSend(call)
                "privacyIncludeStorageFeatures" -> privacyChangeStorageFeatures(call)
                "privacyExcludeStorageFeatures" -> privacyChangeStorageFeatures(call, false)
                "privacyIncludeProperties" -> privacyChangeProperties(call)
                "privacyExcludeProperties" -> privacyChangeProperties(call, false)
                "privacyIncludeEvents" -> privacyChangeEvents(call)
                "privacyExcludeEvents" -> privacyChangeEvents(call, false)
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
                    val propertyName = property.key as? String ?: error("Undefined property name of event \"$name\"")
                    val value = property.value as? Map<*, *> ?: error("Undefined property value of event \"$propertyName\"")
                    val propertyValue = value["value"] ?: error("Undefined property value of event \"$propertyName\"")
                    val forceType = (value["forceType"] as? String)?.let { type ->
                        Property.Type.entries.firstOrNull { t -> t.prefix == type }
                    }
                    getProperty(
                        propertyName,
                        propertyValue,
                        forceType
                    )
                }?.toMutableSet() ?: mutableSetOf()
            ).build()
        }.toTypedArray()
        PianoAnalytics.getInstance().sendEvents(*events)
    }

    private fun privacyChangeStorageFeatures(call: MethodCall, include: Boolean = true) {
        val features = call.arg<List<String>>("features").map { feature ->
            PrivacyStorageFeature.entries.first { it.name == feature }
        }
        call.arg<List<String>>("modes").forEach {
            val mode = getPrivacyMode(it)
            (if (include) mode.allowedStorageFeatures else mode.forbiddenStorageFeatures) += features
        }
    }

    private fun privacyChangeProperties(call: MethodCall, include: Boolean = true) {
        val propertyNames = call.arg<List<String>>("propertyNames")
        val eventNames = call.argument<List<String>>("eventNames") ?: listOf(Event.ANY)

        call.arg<List<String>>("modes").forEach {
            val mode = getPrivacyMode(it)
            val propertyKeys = if (include) mode.allowedPropertyKeys else mode.forbiddenPropertyKeys

            eventNames.forEach { eventName ->
                propertyKeys
                    .getOrPut(eventName) { mutableSetOf() }
                    .addAll(propertyNames.map { name -> PropertyName(name) })
            }
        }
    }

    private fun privacyChangeEvents(call: MethodCall, include: Boolean = true) {
        val eventNames = call.arg<List<String>>("eventNames")

        call.arg<List<String>>("modes").forEach {
            val mode = getPrivacyMode(it)
            (if (include) mode.allowedEventNames else mode.forbiddenEventNames).addAll(eventNames)
        }
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
        private fun getProperty(name: String, value: Any?, forceType: Property.Type? = null) = when (value) {
            is Boolean -> Property(PropertyName(name), value, forceType)
            is Int -> Property(PropertyName(name), value, forceType)
            is Long -> Property(PropertyName(name), value, forceType)
            is Double -> Property(PropertyName(name), value, forceType)
            is String -> Property(PropertyName(name), value, forceType)
            is Date -> Property(PropertyName(name), value)
            is List<*> -> {
                when (value.first()) {
                    is Int -> Property(PropertyName(name), value.filterIsInstance<Int>().toTypedArray(), forceType)
                    is Double -> Property(PropertyName(name), value.filterIsInstance<Double>().toTypedArray(), forceType)
                    is String -> Property(PropertyName(name), value.filterIsInstance<String>().toTypedArray(), forceType)
                    else -> { error("Invalid array value type of property \"$name\"") }
                }
            }
            else -> error("Invalid type of property \"$name\"")
        }

        @JvmStatic
        private fun getPrivacyMode(name: String) = when(name) {
            "opt-in" -> PrivacyMode.OPTIN
            "opt-out" -> PrivacyMode.OPTOUT
            "exempt" -> PrivacyMode.EXEMPT
            "custom" -> PrivacyMode.CUSTOM
            "no-consent" -> PrivacyMode.NO_CONSENT
            "no-storage" -> PrivacyMode.NO_STORAGE
            else -> error("Invalid privacy mode \"$name\"")
        }

        @JvmStatic
        private fun updatePropertyKeys(
            eventNames: List<String>,
            propertyKeys: MutableMap<String, MutableSet<PropertyName>>,
            propertyName: String
        ) {
            eventNames.forEach { eventName ->
                var propertyNames = propertyKeys[eventName]
                if (propertyNames == null) {
                    propertyNames = mutableSetOf()
                    propertyKeys[eventName] = propertyNames
                }

                val newPropertyName = PropertyName(propertyName)
                if (!propertyNames.contains(newPropertyName)) {
                    propertyNames.add(newPropertyName)
                }
            }
        }
    }
}
