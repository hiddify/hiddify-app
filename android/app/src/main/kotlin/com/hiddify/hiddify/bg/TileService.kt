package com.hiddify.hiddify.bg

import android.service.quicksettings.Tile
import android.service.quicksettings.TileService
import androidx.annotation.RequiresApi
import com.hiddify.hiddify.constant.Status

@RequiresApi(24)
class TileService : TileService(), ServiceConnection.Callback {

    private val connection = ServiceConnection(this, this)

    override fun onServiceStatusChanged(status: Status) {
        qsTile?.apply {
            state = when (status) {
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

    override fun onClick() {
        when (connection.status) {
            Status.Stopped -> {
                BoxService.start()
            }

            Status.Started -> {
                BoxService.stop()
            }

            else -> {}
        }
    }

}