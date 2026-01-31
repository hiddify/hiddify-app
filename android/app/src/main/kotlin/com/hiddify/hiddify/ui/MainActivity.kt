package com.hiddify.hiddify.ui

import android.Manifest
import android.app.Activity
import android.content.Intent
import android.content.pm.PackageManager
import android.net.VpnService
import android.os.Build
import android.os.Bundle
import android.util.Log
import androidx.activity.result.contract.ActivityResultContracts
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import androidx.lifecycle.MutableLiveData
import androidx.lifecycle.Observer
import com.hiddify.hiddify.core.channel.*
import com.hiddify.hiddify.core.service.BoxService
import com.hiddify.hiddify.core.service.VPNService
import com.hiddify.hiddify.core.constant.Alert
import com.hiddify.hiddify.core.constant.Status
import com.hiddify.hiddify.core.model.ServiceEvent
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob

class MainActivity : FlutterFragmentActivity() {

    companion object {
        private const val TAG = "A/MainActivity"
        private const val REQUEST_CODE_VPN = 1001
        private const val REQUEST_CODE_NOTIFICATION = 1002
        
        lateinit var instance: MainActivity
            private set
    }

    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.Main)
    
    val serviceStatus: MutableLiveData<Status>
        get() = BoxService.status
    
    val serviceAlerts: MutableLiveData<ServiceEvent?>
        get() = BoxService.serviceAlerts

    private val vpnPermissionLauncher = registerForActivityResult(
        ActivityResultContracts.StartActivityForResult()
    ) { result ->
        if (result.resultCode == Activity.RESULT_OK) {
            Log.d(TAG, "VPN permission granted")
            BoxService.start(this)
        } else {
            Log.w(TAG, "VPN permission denied")
            serviceAlerts.postValue(ServiceEvent(Status.Stopped, Alert.RequestVPNPermission))
        }
    }

    private val notificationPermissionLauncher = registerForActivityResult(
        ActivityResultContracts.RequestPermission()
    ) { isGranted ->
        if (isGranted) {
            Log.d(TAG, "Notification permission granted")
        } else {
            Log.w(TAG, "Notification permission denied")
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        instance = this
        
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            if (ContextCompat.checkSelfPermission(this, Manifest.permission.POST_NOTIFICATIONS) 
                != PackageManager.PERMISSION_GRANTED) {
                notificationPermissionLauncher.launch(Manifest.permission.POST_NOTIFICATIONS)
            }
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        flutterEngine.plugins.add(PlatformSettingsHandler())
        flutterEngine.plugins.add(MethodHandler(scope))
        flutterEngine.plugins.add(EventHandler())
        flutterEngine.plugins.add(LogHandler())
        flutterEngine.plugins.add(StatsChannel())
        flutterEngine.plugins.add(GroupsChannel())
        flutterEngine.plugins.add(ActiveGroupsChannel())
    }

    override fun onDestroy() {
        super.onDestroy()
    }

    fun startService() {
        Log.d(TAG, "startService called")
        
        val vpnIntent = VpnService.prepare(this)
        if (vpnIntent != null) {
            Log.d(TAG, "Requesting VPN permission")
            vpnPermissionLauncher.launch(vpnIntent)
            return
        }
        
        BoxService.start(this)
    }

    fun reconnect() {
        Log.d(TAG, "reconnect called")
        serviceAlerts.postValue(ServiceEvent(Status.Starting))
    }

    fun onServiceResetLogs(logs: MutableList<*>) {
        Log.d(TAG, "onServiceResetLogs called")
        BoxService.logList.clear()
    }

    fun addLog(message: String) {
        BoxService.logList.add(message)
        BoxService.logCallback?.invoke(message)
    }
}
