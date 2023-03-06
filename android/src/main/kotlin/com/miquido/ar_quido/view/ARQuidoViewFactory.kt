package com.miquido.ar_quido.view

import android.content.Context
import com.miquido.ar_quido.view.recognition.ARImageRecognizer
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.StandardMessageCodec
import io.flutter.plugin.platform.PlatformView
import io.flutter.plugin.platform.PlatformViewFactory

class ARQuidoViewFactory(private val messenger: BinaryMessenger): PlatformViewFactory(StandardMessageCodec.INSTANCE) {
    companion object {
        const val methodChannelName = "plugins.miquido.com/ar_quido"
    }

    override fun create(context: Context?, viewId: Int, args: Any?): PlatformView {
        val creationParams = args as Map<*, *>
        val referenceImageNames = creationParams["referenceImageNames"] as List<*>
        val imageRecognizer = ARImageRecognizer(referenceImageNames.filterIsInstance<String>())
        val methodChannel = MethodChannel(messenger, methodChannelName)
        return ARQuidoView(context, viewId, imageRecognizer, methodChannel)
    }
}