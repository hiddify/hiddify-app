package com.hiddify.hiddify.bg

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
        when (status) {
            Status.Started -> qsTile?.apply {
                state = Tile.STATE_ACTIVE
                updateTile()
            }

            Status.Stopped -> qsTile?.apply {
                state = Tile.STATE_INACTIVE
                updateTile()
            }

            else -> {}
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

    override fun onClick() {
        when (connection.status) {
            Status.Stopped -> {
//                val mainActivity = MainActivity.instance
                Settings.startCoreAfterStartingService = true


                val intent = Intent(Application.application, Settings.serviceClass())

                ContextCompat.startForegroundService(Application.application, intent)


                qsTile?.apply {
                    state = Tile.STATE_ACTIVE
                    updateTile()
                }
            }

            else -> {
                BoxService.stop()
                qsTile?.apply {
                    state = Tile.STATE_INACTIVE
                    updateTile()
                }
            }
//
//            else -> {}
        }

    }

}