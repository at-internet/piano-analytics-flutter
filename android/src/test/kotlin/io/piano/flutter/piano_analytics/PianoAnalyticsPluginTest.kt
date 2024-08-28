package io.piano.flutter.piano_analytics

import io.mockk.every
import io.mockk.mockk
import io.mockk.mockkObject
import io.mockk.slot
import io.mockk.verify
import io.piano.android.analytics.Configuration
import io.piano.android.analytics.PianoAnalytics
import io.piano.android.analytics.model.Event
import io.piano.android.analytics.model.Property
import io.piano.android.analytics.model.PropertyName
import io.piano.android.analytics.model.VisitorIDType
import java.util.Date
import kotlin.test.BeforeTest
import kotlin.test.Test
import kotlin.test.assertEquals

internal class PianoAnalyticsPluginTest: BasePluginTest() {

    @BeforeTest
    fun setUp() {
        mockkObject(PianoAnalytics.Companion)
    }

    @Test
    fun `Check PianoAnalytics init`() {
        every { PianoAnalytics.Companion.init(any(), any(), any(), any()) } returns mockk()

        call("init", mapOf(
          "site" to 123456789,
          "collectDomain" to "xxxxxxx.pa-cd.com",
          "visitorIDType" to "UUID"
        ))

        val slot = slot<Configuration>()
        verify { PianoAnalytics.init(any(), capture(slot), any(), any()) }

        val configuration = slot.captured
        assertEquals(123456789, configuration.site)
        assertEquals("xxxxxxx.pa-cd.com", configuration.collectDomain)
        assertEquals(VisitorIDType.UUID, configuration.visitorIDType)
    }

    @Test
    fun `Check PianoAnalytics send`() {
        val pianoAnalytics: PianoAnalytics = mockk()
        every { PianoAnalytics.Companion.getInstance() } returns pianoAnalytics
        every { pianoAnalytics.sendEvents(any()) } returns Unit

        call("send", mapOf(
            "events" to listOf(
                mapOf(
                    "name" to "page.display",
                    "data" to mapOf(
                        "bool" to true,
                        "int" to 1,
                        "long" to 1L,
                        "double" to 1.0,
                        "string" to "value",
                        "intArray" to listOf(1, 2, 3),
                        "doubleArray" to listOf(1.0, 2.0, 3.0),
                        "stringArray" to listOf("a", "b", "c"),
                        "date" to Date(0)
                    )
                )
            )
        ))

        val slot = slot<Event>()
        verify { pianoAnalytics.sendEvents(capture(slot)) }

        val event = slot.captured
        assertEquals("page.display", event.name)
        assertEquals(true, event.properties.valueOf("bool"))
        assertEquals(1, event.properties.valueOf("int"))
        assertEquals(1L, event.properties.valueOf("long"))
        assertEquals(1.0, event.properties.valueOf("double"))
        assertEquals("value", event.properties.valueOf("string"))

        assertEquals(
            Property(PropertyName("date"), Date(0)).value,
            event.properties.valueOf("date")
        )

        assertEquals(setOf(1, 2, 3), event.properties.setOf("intArray"))
        assertEquals(setOf(1.0, 2.0, 3.0), event.properties.setOf("doubleArray"))
        assertEquals(setOf("a", "b", "c"), event.properties.setOf("stringArray"))
    }

    private fun Set<Property>.valueOf(name: String) = this.firstOrNull { it.name.key == name }?.value
    private fun Set<Property>.setOf(name: String) = (this.valueOf(name) as? Array<*>)?.toSet()

    private fun call(method: String, parameters: Map<String, Any>? = null) {
        return call(method, parameters) { PianoAnalyticsPlugin() }
    }
}
