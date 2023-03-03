package com.miquido.image_recognition_scanner.view.recognition

interface ImageRecognitionListener {
    fun onRecognitionStarted()
    fun onError(errorCode: ErrorCode)
    fun onDetected(detectedImage: String)
}