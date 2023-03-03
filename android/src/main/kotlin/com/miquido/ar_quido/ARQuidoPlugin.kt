package com.miquido.ar_quido

import android.app.Activity
import android.content.pm.PackageManager
import android.os.Build
import android.util.Log
import cn.easyar.Engine
import com.miquido.ar_quido.view.ImageScannerViewFactory
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding

class ARQuidoPlugin: FlutterPlugin, ActivityAware {

  companion object {
    private const val VIEW_TYPE = "plugins.miquido.com/image_scanner_view_android"
    private const val LOG_TAG = "IMAGE_RECOGNITION_SCANNER"
  }

  override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    System.loadLibrary("EasyAR")
    flutterPluginBinding.platformViewRegistry.registerViewFactory(VIEW_TYPE, ImageScannerViewFactory(flutterPluginBinding.binaryMessenger))
  }


  override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    //no-op
  }

  override fun onAttachedToActivity(binding: ActivityPluginBinding) {
    val apiKey = getApiKey(binding.activity)
    if (!Engine.initialize(binding.activity, apiKey)) {
      Log.e(LOG_TAG, "Could not initialize EasyAR Engine")
      binding.activity.finish()
    }
  }

  override fun onDetachedFromActivityForConfigChanges() {
    //no-op
  }

  override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
    //no-op
  }

  override fun onDetachedFromActivity() {
    //no-op
  }

  private fun getApiKey(activity: Activity): String {
    val packageManager = activity.packageManager
    val appInfo = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
      val flags = PackageManager.ApplicationInfoFlags.of(PackageManager.GET_META_DATA.toLong())
      packageManager.getApplicationInfo(activity.packageName, flags)
    } else {
      @Suppress("DEPRECATION")
      packageManager.getApplicationInfo(activity.packageName, PackageManager.GET_META_DATA)
    }
    val metaData = appInfo.metaData

    return metaData.getString("com.miquido.flutter_easy_ar.API_KEY")
      ?: throw Error("No API_KEY found for EasyAR Sense")
  }
}
