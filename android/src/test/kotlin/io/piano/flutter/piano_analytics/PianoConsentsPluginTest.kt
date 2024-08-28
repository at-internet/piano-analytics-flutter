package io.piano.flutter.piano_analytics

import io.mockk.every
import io.mockk.mockk
import io.mockk.mockkObject
import io.mockk.slot
import io.mockk.verify
import io.piano.android.consents.PianoConsents
import io.piano.android.consents.models.ConsentConfiguration
import io.piano.android.consents.models.ConsentMode
import io.piano.android.consents.models.Product
import io.piano.android.consents.models.Purpose
import kotlin.test.BeforeTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNotNull

internal class PianoConsentsPluginTest: BasePluginTest() {

    @BeforeTest
    fun setUp() {
        mockkObject(PianoConsents.Companion)
    }

    @Test
    fun `Check PianoConsents init`() {
        every { PianoConsents.Companion.init(any(), any()) } returns mockk()

        call("init", mapOf(
            "requireConsents" to true,
            "defaultPurposes" to mapOf(
                "PA" to "AM"
            )
        ))

        val slot = slot<ConsentConfiguration>()
        verify { PianoConsents.init(any(), capture(slot)) }

        val configuration = slot.captured
        assertEquals(true, configuration.requireConsent)
        assertNotNull(configuration.defaultPurposes)
        assertEquals(Purpose.AUDIENCE_MEASUREMENT, configuration.defaultPurposes!![Product.PA])
    }

    @Test
    fun `Check PianoConsents set`() {
        val pianoConsents = getPianoConsents()
        every { pianoConsents.set(any(), any(), any()) } returns Unit

        call("set", mapOf(
            "purpose" to "AM",
            "mode" to "opt-in",
            "products" to listOf("PA")
        ))

        val purpose = slot<Purpose>()
        val mode = slot<ConsentMode>()
        val product = slot<Product>()
        verify { pianoConsents.set(capture(purpose), capture(mode), capture(product)) }

        assertEquals(Purpose.AUDIENCE_MEASUREMENT, purpose.captured)
        assertEquals(ConsentMode.OPT_IN, mode.captured)
        assertEquals(Product.PA, product.captured)
    }

    @Test
    fun `Check PianoConsents setAll`() {
        val pianoConsents = getPianoConsents()
        every { pianoConsents.setAll(any()) } returns Unit

        call("setAll", mapOf(
            "mode" to "opt-in"
        ))

        val mode = slot<ConsentMode>()
        verify { pianoConsents.setAll(capture(mode)) }

        assertEquals(ConsentMode.OPT_IN, mode.captured)
    }

    @Test
    fun `Check PianoConsents clear`() {
        val pianoConsents = getPianoConsents()
        every { pianoConsents.clear() } returns Unit
        call("clear")
        verify { pianoConsents.clear() }
    }

    private fun getPianoConsents(): PianoConsents {
        val pianoConsents: PianoConsents = mockk()
        every { PianoConsents.getInstance() } returns pianoConsents
        return pianoConsents
    }

    private fun call(method: String, parameters: Map<String, Any>? = null) {
        return call(method, parameters) { PianoConsentsPlugin() }
    }
}