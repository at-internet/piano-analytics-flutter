package io.piano.flutter.piano_analytics

import io.flutter.plugin.common.MethodCall

internal fun <T> MethodCall.arg(key: String): T =
    this.argument<T>(key) ?: error("Undefined argument \"$key\"")