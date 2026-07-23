package com.traps.trapsapp;

import android.content.Intent;
import android.content.SharedPreferences;
import android.os.Bundle;
import android.view.View;
import android.view.WindowManager;
import android.widget.Button;
import android.widget.Toast;

import androidx.appcompat.app.AppCompatActivity;

import com.traps.trapsapp.network.DeviceConnectionClient;

/**
 * Phase A — choix du mode de compétition après connexion autorisée.
 */
public class ModeSelectActivity extends AppCompatActivity {

    public static final int MODE_INDIVIDUAL = 0;
    public static final int MODE_PATROL = 1;
    public static final int MODE_KCROSS = 2;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_mode_select);
        getWindow().setFlags(WindowManager.LayoutParams.FLAG_FULLSCREEN,
                WindowManager.LayoutParams.FLAG_FULLSCREEN);

        DeviceConnectionClient client = DeviceConnectionClient.getInstance();
        client.setAppContext(this);
        client.setListener(new DeviceConnectionClient.Listener() {
            @Override
            public void onRegistered(String deviceId, long serverTime) {
            }

            @Override
            public void onRejected(String reason, String message) {
                returnToConnect(message);
            }

            @Override
            public void onError(String message) {
                returnToConnect(message);
            }

            @Override
            public void onDisconnected() {
                returnToConnect(getString(R.string.connect_disconnected));
            }

            @Override
            public void onHeartbeatAck(long serverTime) {
                getSharedPreferences(ConnectActivity.PREF_NAME, 0)
                        .edit()
                        .putLong("lastServerTime", serverTime)
                        .apply();
            }

            @Override
            public void onLoadBibList(int count) {
                // Appliqué en base ; JudgeHub affichera la liste
            }
        });

        if (!client.isConnected()) {
            returnToConnect(getString(R.string.connect_disconnected));
            return;
        }

        Button individual = findViewById(R.id.modeIndividualButton);
        Button patrol = findViewById(R.id.modePatrolButton);
        Button kcross = findViewById(R.id.modeKcrossButton);

        individual.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                selectMode(MODE_INDIVIDUAL);
            }
        });
        patrol.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                selectMode(MODE_PATROL);
            }
        });
        kcross.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                selectMode(MODE_KCROSS);
            }
        });
    }

    private void selectMode(int mode) {
        SharedPreferences.Editor editor = getSharedPreferences(ConnectActivity.PREF_NAME, 0).edit();
        editor.putInt(ConnectActivity.PREF_COMPETITION_MODE, mode);
        editor.apply();

        // Aligne le layout pénalités avec le mode (KCross → pad secteurs)
        String layout = (mode == MODE_KCROSS)
                ? TerminalConfigActivity.LAYOUT_MODE_KCROSS
                : TerminalConfigActivity.LAYOUT_MODE_SLALOM;
        getSharedPreferences("SETTINGS_TRANSFER", MODE_PRIVATE).edit()
                .putString(TerminalConfigActivity.KEY_PENALTY_LAYOUT_MODE, layout)
                .apply();

        Intent intent = new Intent(this, JudgeHubActivity.class);
        intent.putExtra(ConnectActivity.PREF_COMPETITION_MODE, mode);
        startActivity(intent);
    }

    private void returnToConnect(String message) {
        if (message != null && !message.isEmpty()) {
            Toast.makeText(this, message, Toast.LENGTH_LONG).show();
        }
        Intent intent = new Intent(this, ConnectActivity.class);
        intent.addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP | Intent.FLAG_ACTIVITY_NEW_TASK);
        startActivity(intent);
        finish();
    }
}
