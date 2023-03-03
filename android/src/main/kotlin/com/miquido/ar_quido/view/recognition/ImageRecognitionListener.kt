package com.miquido.ar_quido.view.recognition

import com.miquido.ar_quido.view.recognition.ErrorCode

interface ImageRecognitionListener {
    fun onRecognitionStarted()
    fun onError(errorCode: ErrorCode)
    fun onDetected(detectedImage: String)
}