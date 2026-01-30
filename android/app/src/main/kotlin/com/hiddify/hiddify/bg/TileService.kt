package com.hiddify.hiddify.bg

import android.app.KeyguardManager
import android.content.Context
import android.content.Intent
import android.service.quicksettings.Tile
import android.service.quicksettings.TileService
import android.util.Log
import androidx.annotation.RequiresApi
import androidx.core.content.ContextCompat
import androidx.lifecycle.lifecycleScope
import com.hiddify.hiddify.Application
import com.hiddify.hiddify.MainActivity
import com.hiddify.hiddify.Settings
import com.hiddify.hiddify.constant.ServiceMode
import com.hiddify.hiddify.constant.Status
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext

@RequiresApi(24)
class TileService : TileService(), ServiceConnection.Callback {

    private val connection = ServiceConnection(this, this)

    override fun onServiceStatusChanged(status: Status) {
        qsTile?.apply {
            state =
                when (status) {
                    Status.Started -> Tile.STATE_ACTIVE
                    Status.Stopped -> Tile.STATE_INACTIVE
                    else -> Tile.STATE_UNAVAILABLE
                }
            updateTile()
        }
    }

    override fun onStartListening() {
        super.onStartListening()
        connection.connect()
    }

    override fun onStopListening() {
        connection.disconnect()
        super.onStopListening()
    }
    private fun toggleService() {
        when (connection.status) {
            Status.Stopped -> {
                Settings.startCoreAfterStartingService = true
                BoxService.start()
                qsTile?.apply {
                    state = Tile.STATE_ACTIVE
                    updateTile()
                }
            }
            Status.Started -> {
                BoxService.stop()
                qsTile?.apply {
                    state = Tile.STATE_INACTIVE
                    updateTile()
                }
            }
            else -> {}
        }
    }

    override fun onClick() {
        val keyguardManager = getSystemService(Context.KEYGUARD_SERVICE) as KeyguardManager
        if (keyguardManager.isKeyguardLocked) {
            unlockAndRun {
                toggleService()
            }
        } else {
            toggleService()
        }
    }

}