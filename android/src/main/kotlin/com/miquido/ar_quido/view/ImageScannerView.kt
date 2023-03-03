package com.miquido.ar_quido.view


import android.annotation.SuppressLint
import android.content.Context
import android.hardware.display.DisplayManager
import android.opengl.GLSurfaceView
import android.os.Handler
import android.os.Looper
import android.util.Log
import android.view.Display
import android.view.Surface
import android.view.View
import cn.easyar.Engine
import com.miquido.ar_quido.view.recognition.ARImageRecognizer
import com.miquido.ar_quido.view.recognition.ErrorCode
import com.miquido.ar_quido.view.recognition.ImageRecognitionListener
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.platform.PlatformView
import java.util.Collections
import javax.microedition.khronos.egl.*
import javax.microedition.khronos.opengles.GL10

@SuppressLint("ViewConstructor") //ScannerView is created only via primary constructor in ScannerViewFactory
class ImageScannerView(
    context: Context?,
    private val viewId: Int,
    private val recognizer: ARImageRecognizer,
    private val methodChannel: MethodChannel,
) : GLSurfaceView(context), PlatformView {
    companion object {
        private const val TAG = "ImageScannerView"
    }

    private var shouldFlashlightBeOn = false
    private var surfaceWidth = 1
    private var surfaceHeight = 1
    private var initialized = false

    init {
        methodChannel.setMethodCallHandler(::handleMethodCall)
        setEGLContextFactory(ContextFactory())
        setEGLWindowSurfaceFactory(WindowSurfaceFactory())
        setEGLConfigChooser(ConfigChooser())
        initRenderListener()
        this.setZOrderMediaOverlay(true)
    }

    private val onActionsCallback: ImageRecognitionListener
        get() = object : ImageRecognitionListener {
            override fun onRecognitionStarted() {
                Handler(Looper.getMainLooper()).post {
                    methodChannel.invokeMethod("scanner#start", Collections.singletonMap("view", viewId))
                }
            }

            override fun onError(errorCode: ErrorCode) {
                Handler(Looper.getMainLooper()).post {
                    methodChannel.invokeMethod("scanner#error", Collections.singletonMap("errorCode", errorCode.toString()))
                }
                Log.e(TAG, errorCode.toString())
            }

            override fun onDetected(detectedImage: String) {
                Handler(Looper.getMainLooper()).post {
                    methodChannel.invokeMethod("scanner#onImageDetected", Collections.singletonMap("imageName", detectedImage))
                }
            }
        }

    override fun onAttachedToWindow() {
        super.onAttachedToWindow()

        synchronized(recognizer) {
            if (recognizer.initialize(onActionsCallback)) {
                recognizer.start()
                initialized = true
            }

            refreshFlashlightState()
        }
    }

    override fun onDetachedFromWindow() {
        synchronized(recognizer) {
            recognizer.stop()
            recognizer.dispose()
            initialized = false
        }
        super.onDetachedFromWindow()
    }

    override fun onResume() {
        super.onResume()

        try {
            Engine.onResume()
        } catch (e: UnsatisfiedLinkError) {
            Log.w(TAG, "EasyAR Engine should be reinitialized", e)
        }

        refreshFlashlightState()
    }

    override fun onPause() {
        try {
            Engine.onPause()
        } catch (e: UnsatisfiedLinkError) {
            Log.w(TAG, "EasyAR Engine should be reinitialized", e)
            // no need to reinitialize, it could be done on return to screen in onResume if needed
        }
        super.onPause()
    }

    override fun getView(): View {
        return this
    }

    override fun dispose() {
        recognizer.stop()
        recognizer.dispose()
    }

    private fun handleMethodCall(call: MethodCall, result: MethodChannel.Result) {
        if (call.method == "scanner#toggleFlashlight") {
            val shouldTurnOn = call.argument<Boolean>("shouldTurnOn") ?: false
            toggleFlashlight(shouldTurnOn)
            result.success(null)
        } else {
            result.notImplemented()
        }
    }

    private fun toggleFlashlight(shouldTurnOn: Boolean) {
        recognizer.setFlashlightOn(shouldTurnOn)
        shouldFlashlightBeOn = shouldTurnOn
    }

    private fun refreshFlashlightState() {
        toggleFlashlight(shouldFlashlightBeOn)
    }

    private fun initRenderListener() {
        this.setRenderer(object : Renderer {
            override fun onSurfaceCreated(gl: GL10, config: EGLConfig) {
                synchronized(recognizer) {
                    recognizer.initGL()
                }
            }

            override fun onSurfaceChanged(gl: GL10, w: Int, h: Int) {
                surfaceWidth = w
                surfaceHeight = h
            }

            override fun onDrawFrame(gl: GL10) {
                synchronized(recognizer) {
                    recognizer.render(surfaceWidth, surfaceHeight, getScreenRotation())
                }
            }
        })
    }

    private fun getScreenRotation(): Int {
        val windowManager = context.getSystemService(Context.DISPLAY_SERVICE) as DisplayManager
        val display = windowManager.getDisplay(Display.DEFAULT_DISPLAY)
        val orientation: Int = when (display.rotation) {
            Surface.ROTATION_0 -> 0
            Surface.ROTATION_90 -> 90
            Surface.ROTATION_180 -> 180
            Surface.ROTATION_270 -> 270
            else -> 0
        }
        return orientation
    }

    private class ContextFactory : EGLContextFactory {

        companion object {
            private const val EGL_CONTEXT_CLIENT_VERSION = 0x3098
        }

        override fun createContext(
            egl: EGL10,
            display: EGLDisplay,
            eglConfig: EGLConfig
        ): EGLContext {
            val context: EGLContext
            val attributes = intArrayOf(EGL_CONTEXT_CLIENT_VERSION, 3, EGL10.EGL_NONE)
            context = egl.eglCreateContext(display, eglConfig, EGL10.EGL_NO_CONTEXT, attributes)
            return context
        }

        override fun destroyContext(egl: EGL10, display: EGLDisplay, context: EGLContext) {
            egl.eglDestroyContext(display, context)
        }
    }

    private inner class WindowSurfaceFactory : EGLWindowSurfaceFactory {
        override fun createWindowSurface(
            egl: EGL10,
            display: EGLDisplay,
            config: EGLConfig,
            nativeWindow: Any
        ): EGLSurface? {
            var result: EGLSurface? = null
            try {
                result = egl.eglCreateWindowSurface(display, config, nativeWindow, null)
            } catch (e: IllegalArgumentException) {
                // This exception indicates that the surface flinger surface
                // is not valid. This can happen if the surface flinger surface has
                // been torn down, but the application has not yet been
                // notified via SurfaceHolder.Callback.surfaceDestroyed.
                // In theory the application should be notified first,
                // but in practice sometimes it is not. See b/4588890
                Log.e("GLSurfaceView", "eglCreateWindowSurface", e)
            }

            return result
        }

        override fun destroySurface(egl: EGL10, display: EGLDisplay, surface: EGLSurface) {
            egl.eglDestroySurface(display, surface)
        }
    }

    private class ConfigChooser : EGLConfigChooser {

        companion object {
            private const val EGL_OPENGL_ES2_BIT = 0x0004
        }

        override fun chooseConfig(egl: EGL10, display: EGLDisplay): EGLConfig {
            val attributes = intArrayOf(
                EGL10.EGL_RED_SIZE,
                4,
                EGL10.EGL_GREEN_SIZE,
                4,
                EGL10.EGL_BLUE_SIZE,
                4,
                EGL10.EGL_RENDERABLE_TYPE,
                EGL_OPENGL_ES2_BIT,
                EGL10.EGL_NONE
            )

            val numConfig = IntArray(1)
            egl.eglChooseConfig(display, attributes, null, 0, numConfig)

            val numConfigs = numConfig[0]
            if (numConfigs <= 0)
                throw IllegalArgumentException("fail to choose EGL configs")

            val configs = arrayOfNulls<EGLConfig>(numConfigs)
            egl.eglChooseConfig(
                display, attributes, configs, numConfigs,
                numConfig
            )

            for (config in configs) {
                val value = IntArray(1)
                var r = 0
                var g = 0
                var b = 0
                var a = 0
                var d = 0
                if (egl.eglGetConfigAttrib(display, config, EGL10.EGL_DEPTH_SIZE, value))
                    d = value[0]
                if (d < 16)
                    continue

                if (egl.eglGetConfigAttrib(display, config, EGL10.EGL_RED_SIZE, value))
                    r = value[0]
                if (egl.eglGetConfigAttrib(display, config, EGL10.EGL_GREEN_SIZE, value))
                    g = value[0]
                if (egl.eglGetConfigAttrib(display, config, EGL10.EGL_BLUE_SIZE, value))
                    b = value[0]
                if (egl.eglGetConfigAttrib(display, config, EGL10.EGL_ALPHA_SIZE, value))
                    a = value[0]
                if (r == 8 && g == 8 && b == 8 && a == 0)
                    return config!!
            }

            return configs[0]!!
        }
    }
}

