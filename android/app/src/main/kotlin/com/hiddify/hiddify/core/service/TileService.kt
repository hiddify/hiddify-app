package com.hiddify.hiddify.core.service

import android.content.Intent
import android.graphics.drawable.Icon
import android.os.Build
import android.service.quicksettings.Tile
import android.service.quicksettings.TileService as AndroidTileService
import android.util.Log
import androidx.annotation.RequiresApi
import androidx.lifecycle.Observer
import com.hiddify.hiddify.core.HiddifyApp
import com.hiddify.hiddify.ui.MainActivity
import com.hiddify.hiddify.R
import com.hiddify.hiddify.core.settings.Settings
import com.hiddify.hiddify.core.constant.Status

@RequiresApi(Build.VERSION_CODES.N)
class TileService : AndroidTileService() {

    companion object {
        private const val TAG = "A/TileService"
    }

    private var statusObserver: Observer<Status>? = null

    override fun onStartListening() {
        super.onStartListening()
        Log.d(TAG, "TileService onStartListening")
        
        statusObserver = Observer { status ->
            updateTile(status)
        }
        BoxService.status.observeForever(statusObserver!!)
    }

    override fun onStopListening() {
        super.onStopListening()
        Log.d(TAG, "TileService onStopListening")
        
        statusObserver?.let {
            BoxService.status.removeObserver(it)
        }
        statusObserver = null
    }

    override fun onClick() {
        super.onClick()
        Log.d(TAG, "TileService onClick")
        
        when (BoxService.status.value) {
            Status.Stopped -> {
                if (Settings.activeConfigPath.isNotBlank()) {
                    BoxService.start(HiddifyApp.instance)
                } else {
                    openApp()
                }
            }
            Status.Started -> {
                BoxService.stop()
            }
            Status.Starting, Status.Stopping -> {
                Log.d(TAG, "Service is transitioning, ignoring click")
            }
            null -> {
                openApp()
            }
        }
    }

    private fun openApp() {
        val intent = Intent(this, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK
        }
        
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
            startActivityAndCollapse(intent)
        } else {
            @Suppress("DEPRECATION")
            startActivityAndCollapse(intent)
        }
    }

    private fun updateTile(status: Status) {
        val tile = qsTile ?: return
        
        when (status) {
            Status.Stopped -> {
                tile.state = Tile.STATE_INACTIVE
                tile.label = "Hiddify"
                tile.subtitle = "Disconnected"
            }
            Status.Starting -> {
                tile.state = Tile.STATE_ACTIVE
                tile.label = "Hiddify"
                tile.subtitle = "Connecting..."
            }
            Status.Started -> {
                tile.state = Tile.STATE_ACTIVE
                tile.label = "Hiddify"
                tile.subtitle = Settings.activeProfileName.ifBlank { "Connected" }
            }
            Status.Stopping -> {
                tile.state = Tile.STATE_INACTIVE
                tile.label = "Hiddify"
                tile.subtitle = "Disconnecting..."
            }
        }
        
        tile.icon = Icon.createWithResource(this, R.drawable.ic_stat_logo)
        tile.updateTile()
    }
}
