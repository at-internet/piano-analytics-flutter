package io.piano.flutter.piano_analytics

import android.app.Activity
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.mockk.every
import io.mockk.mockk

internal open class BasePluginTest {

    protected fun <T> call(method: String, parameters: Map<String, Any>?, factory: () -> T)
        where T: FlutterPlugin, T: MethodCallHandler, T: ActivityAware {
        val plugin = factory()

        val call = MethodCall(method, parameters)

        val result: MethodChannel.Result = mockk()
        every { result.success(any()) } returns Unit

        val activityBinding: ActivityPluginBinding = mockk()
        every { activityBinding.activity } returns Activity()
        plugin.onAttachedToActivity(activityBinding)

        plugin.onMethodCall(call, result)
    }
}