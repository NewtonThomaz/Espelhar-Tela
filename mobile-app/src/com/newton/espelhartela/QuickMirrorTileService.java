package com.newton.espelhartela;

import android.content.SharedPreferences;
import android.service.quicksettings.Tile;
import android.service.quicksettings.TileService;
import android.widget.Toast;

public class QuickMirrorTileService extends TileService {

    @Override
    public void onStartListening() {
        super.onStartListening();
        Tile tile = getQsTile();
        if (tile != null) {
            tile.setLabel("Espelhar PC");
            tile.setState(Tile.STATE_ACTIVE);
            tile.updateTile();
        }
    }

    @Override
    public void onClick() {
        super.onClick();
        SharedPreferences prefs = getSharedPreferences("espelhar_prefs", MODE_PRIVATE);
        String customIp = prefs.getString("custom_ip", "");
        Toast.makeText(getApplicationContext(), "Alternando espelhamento no PC...", Toast.LENGTH_SHORT).show();
        UdpToggleSender.sendToggle(customIp, 8888, null);
    }
}

