package com.miquido.ar_quido.view.recognition

import android.opengl.GLES30
import android.util.Log
import cn.easyar.*
import io.flutter.FlutterInjector
import java.nio.ByteBuffer

class ARImageRecognizer(private val imageNames: List<String>) {

    companion object {
        private const val REFERENCE_IMAGES_DIRECTORY_PATH = "assets/reference_images/"
        private const val REFERENCE_IMAGE_FILE_EXTENSION = ".jpg"
        private const val TAG = "AR_IMAGE_RECOGNIZER"
    }

    private var scheduler: DelayedCallbackScheduler? = null
    private var camera: CameraDevice? = null
    private val trackers = ArrayList<ImageTracker>()
    private var bgRenderer: BGRenderer? = null
    private var boxRenderer: BoxRenderer? = null
    private var throttler: InputFrameThrottler? = null
    private var feedbackFrameFork: FeedbackFrameFork? = null
    private var i2OAdapter: InputFrameToOutputFrameAdapter? = null
    private var inputFrameFork: InputFrameFork? = null
    private var join: OutputFrameJoin? = null
    private var outputFrameBuffer: OutputFrameBuffer? = null
    private var i2FAdapter: InputFrameToFeedbackFrameAdapter? = null
    private var outputFrameFork: OutputFrameFork? = null
    private var previousInputFrameIndex = -1
    private var imageBytes: ByteArray? = null

    private var recognitionListener: ImageRecognitionListener? = null

    fun initialize(onImagesLoadedCallback: ImageRecognitionListener): Boolean {
        scheduler = DelayedCallbackScheduler()
        recognitionListener = onImagesLoadedCallback

        camera = CameraDeviceSelector.createCameraDevice(CameraDevicePreference.PreferObjectSensing)
        throttler = InputFrameThrottler.create()
        inputFrameFork = InputFrameFork.create(2)
        join = OutputFrameJoin.create(2)
        outputFrameBuffer = OutputFrameBuffer.create()
        i2OAdapter = InputFrameToOutputFrameAdapter.create()
        i2FAdapter = InputFrameToFeedbackFrameAdapter.create()
        outputFrameFork = OutputFrameFork.create(2)

        val cameraStatus = camera?.openWithPreferredType(CameraDeviceType.Back) ?: false
        camera?.setSize(Vec2I(640, 480))
        camera?.setFocusMode(CameraDeviceFocusMode.Continousauto)

        if (!cameraStatus) {
            return false
        }

        val tracker = prepareImageTracker()
        trackers.add(tracker)

        feedbackFrameFork = FeedbackFrameFork.create(trackers.size)

        camera?.inputFrameSource()?.connect(throttler!!.input())
        throttler!!.output().connect(inputFrameFork!!.input())
        inputFrameFork!!.output(0).connect(i2OAdapter!!.input())
        i2OAdapter!!.output().connect(join!!.input(0))

        inputFrameFork!!.output(1).connect(i2FAdapter!!.input())
        i2FAdapter!!.output().connect(feedbackFrameFork!!.input())
        var trackerBufferRequirement = 0
        for ((k, _tracker) in trackers.withIndex()) {
            feedbackFrameFork!!.output(k).connect(_tracker.feedbackFrameSink())
            _tracker.outputFrameSource().connect(join!!.input(k + 1))
            trackerBufferRequirement += _tracker.bufferRequirement()
        }

        join!!.output().connect(outputFrameFork!!.input())
        outputFrameFork!!.output(0).connect(outputFrameBuffer!!.input())
        outputFrameFork!!.output(1).connect(i2FAdapter!!.sideInput())
        outputFrameBuffer!!.signalOutput().connect(throttler!!.signalInput())

        //CameraDevice and rendering each require an additional buffer
        camera?.setBufferCapacity(throttler!!.bufferRequirement() + i2FAdapter!!.bufferRequirement() + outputFrameBuffer!!.bufferRequirement() + trackerBufferRequirement + 2)
        return true
    }

    fun start(): Boolean {
        var status = true
        status = status and (camera != null && camera!!.start())

        for (tracker in trackers) {
            status = status and tracker.start()
        }
        recognitionListener?.onRecognitionStarted()
        return status
    }

    fun stop() {
        camera?.stop()
        trackers.forEach { it.stop() }
    }

    fun dispose() {
        trackers.forEach { it.dispose() }
        trackers.clear()

        bgRenderer?.dispose()
        bgRenderer = null

        boxRenderer?.dispose()
        boxRenderer = null

        camera?.dispose()
        camera = null

        scheduler?.dispose()
        scheduler = null

        recognitionListener = null
    }

    fun initGL() {
        bgRenderer?.dispose()
        bgRenderer = null
        boxRenderer?.dispose()
        boxRenderer = null

        bgRenderer = BGRenderer()
        boxRenderer = BoxRenderer()
    }

    fun setFlashlightOn(shouldBeOn: Boolean) {
        camera?.setFlashTorchMode(shouldBeOn)
    }

    fun render(width: Int, height: Int, screenRotation: Int) {
        if (scheduler == null) return

        GLES30.glViewport(0, 0, width, height)
        GLES30.glClearColor(0f, 0f, 0f, 1f)
        GLES30.glClear(GLES30.GL_COLOR_BUFFER_BIT or GLES30.GL_DEPTH_BUFFER_BIT)

        val outputFrame = outputFrameBuffer!!.peek() ?: return
        val inputFrame = outputFrame.inputFrame()
        val cameraParameters = inputFrame.cameraParameters()
        val viewportAspectRatio = width.toFloat() / height.toFloat()
        val imageProjection =
            cameraParameters.imageProjection(viewportAspectRatio, screenRotation, true, false)
        val image = inputFrame.image()

        try {
            if (inputFrame.index() != previousInputFrameIndex) {
                val buffer = image.buffer()
                try {
                    if (imageBytes == null || imageBytes?.size != buffer.size()) {
                        imageBytes = ByteArray(buffer.size())
                    }
                    buffer.copyToByteArray(imageBytes!!)
                    bgRenderer?.upload(
                        image.format(),
                        image.width(),
                        image.height(),
                        image.pixelWidth(),
                        image.pixelHeight(),
                        ByteBuffer.wrap(imageBytes!!)
                    )
                } finally {
                    buffer.dispose()
                }
                previousInputFrameIndex = inputFrame.index()
            }
            bgRenderer?.render(imageProjection)

            val projectionMatrix = cameraParameters.projection(
                0.2f,
                500f,
                viewportAspectRatio,
                screenRotation,
                true,
                false
            )
            for (oResult in outputFrame.results()) {
                val result = oResult as? ImageTrackerResult
                if (result != null) {
                    for (targetInstance in result.targetInstances()) {
                        val status = targetInstance.status()
                        if (status == TargetStatus.Tracked) {
                            val target = targetInstance.target()
                            val imagetarget = (if (target is ImageTarget) target else null)
                                ?: continue
                            val images = (target as ImageTarget).images()
                            val targetImg = images[0]
                            val targetScale = imagetarget.scale()
                            val scale = Vec2F(
                                targetScale,
                                targetScale * targetImg.height() / targetImg.width()
                            )
                            recognitionListener?.onDetected(imagetarget.name())
                            boxRenderer?.render(projectionMatrix, targetInstance.pose(), scale)
                            images.forEach { it.dispose() }
                        }
                    }
                    result.dispose()
                }
            }
        } catch (ex: Exception) {
            Log.e(TAG, ex.toString())
        } finally {
            inputFrame.dispose()
            outputFrame.dispose()
            cameraParameters.dispose()
            image.dispose()
        }
    }

    private fun prepareImageTracker(): ImageTracker {
        val tracker = ImageTracker.createWithMode(ImageTrackerMode.PreferPerformance)
        for (imageName in imageNames) {
            val filePath = REFERENCE_IMAGES_DIRECTORY_PATH + imageName + REFERENCE_IMAGE_FILE_EXTENSION
            loadFromImage(tracker, filePath, imageName)
        }
        tracker.setSimultaneousNum(6)
        return tracker
    }

    private fun loadFromImage(tracker: ImageTracker, path: String, name: String) {
        val loader = FlutterInjector.instance().flutterLoader()
        val nativeImagePath = loader.getLookupKeyForAsset(path)
        val target = ImageTarget.createFromImageFile(nativeImagePath, StorageType.Assets, name, "", "", 1.0f)
        if (target == null) {
            Log.e(TAG, "target create failed or key is not correct")
            return
        }
        scheduler?.let {
            tracker.loadTarget(target, it) { target, status ->
                Log.i(
                    TAG,
                    String.format(
                        "load target (%b): %s (%d)",
                        status,
                        target.name(),
                        target.runtimeID()
                    )
                )
            }
        }
        target.dispose()
    }
}
