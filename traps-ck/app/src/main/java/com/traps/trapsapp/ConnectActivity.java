package com.traps.trapsapp;

import android.content.Intent;
import android.content.SharedPreferences;
import android.os.Bundle;
import android.view.View;
import android.view.WindowManager;
import android.widget.Button;
import android.widget.EditText;
import android.widget.ProgressBar;
import android.widget.TextView;

import androidx.appcompat.app.AppCompatActivity;

import com.traps.trapsapp.core.DeviceIdentityHelper;
import com.traps.trapsapp.core.TrapsDB;
import com.traps.trapsapp.network.DeviceConnectionClient;
import com.traps.trapsapp.network.UDPListener;

/**
 * Phase A — écran IP/MAC/port + connexion Manager (garde-fou TCP appareils).
 */
public class ConnectActivity extends AppCompatActivity implements DeviceConnectionClient.Listener {

    public static final String PREF_NAME = "TRAPS_PREF";
    public static final String PREF_COMPETITION_MODE = "competitionMode";
    public static final String PREF_DEVICE_PORT = "deviceConnectionPort";

    private TextView macValue;
    private TextView ipValue;
    private TextView macHint;
    private EditText portField;
    private TextView targetText;
    private TextView statusText;
    private Button connectButton;
    private ProgressBar progress;

    private DeviceIdentityHelper.Identity identity;
    private DeviceConnectionClient connectionClient;
    private boolean connecting;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_connect);
        getWindow().setFlags(WindowManager.LayoutParams.FLAG_FULLSCREEN,
                WindowManager.LayoutParams.FLAG_FULLSCREEN);

        macValue = findViewById(R.id.connectMacValue);
        ipValue = findViewById(R.id.connectIpValue);
        macHint = findViewById(R.id.connectMacHint);
        portField = findViewById(R.id.connectPortField);
        targetText = findViewById(R.id.connectTarget);
        statusText = findViewById(R.id.connectStatus);
        connectButton = findViewById(R.id.connectButton);
        progress = findViewById(R.id.connectProgress);

        identity = DeviceIdentityHelper.resolve(this);

        if (identity.ip == null || identity.ip.isEmpty()) {
            ipValue.setText(R.string.connect_ip_unknown);
        } else {
            ipValue.setText(identity.ip);
        }

        SharedPreferences prefs = getSharedPreferences(PREF_NAME, 0);
        int savedPort = prefs.getInt(PREF_DEVICE_PORT, DeviceConnectionClient.DEFAULT_DEVICE_PORT);
        if (!isValidDevicePort(savedPort)) {
            savedPort = DeviceConnectionClient.DEFAULT_DEVICE_PORT;
        }
        portField.setText(String.valueOf(savedPort));

        if (identity.macReliable) {
            macValue.setText(identity.mac);
            macHint.setVisibility(View.GONE);
        } else {
            macValue.setText(R.string.connect_mac_unavailable);
            macHint.setVisibility(View.VISIBLE);
            macHint.setText(R.string.connect_mac_unreliable_hint);
        }

        // Démarrer l'écoute UDP Hello (IP Manager + port données)
        if (UDPListener.getInstance() == null) {
            new UDPListener(this);
        }

        connectionClient = DeviceConnectionClient.getInstance();
        connectionClient.setAppContext(this);
        TrapsDB.init(this);
        connectionClient.setListener(this);

        // Déjà connecté (retour arrière) → passer aux modes
        if (connectionClient.isConnected()) {
            goToModeSelect();
            return;
        }

        connectButton.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                startConnection();
            }
        });
    }

    @Override
    protected void onResume() {
        super.onResume();
        connectionClient.setListener(this);
    }

    /**
     * Port supervision appareils : 1024–65535, 8080 exclu (port données).
     */
    public static boolean isValidDevicePort(int port) {
        return port >= 1024 && port <= 65535
                && port != DeviceConnectionClient.FORBIDDEN_DATA_PORT;
    }

    private int readPortFromField() {
        String raw = portField.getText() != null ? portField.getText().toString().trim() : "";
        if (raw.isEmpty()) {
            return -1;
        }
        try {
            return Integer.parseInt(raw);
        } catch (NumberFormatException e) {
            return -1;
        }
    }

    private void startConnection() {
        if (connecting) {
            return;
        }

        final int port = readPortFromField();
        if (port == DeviceConnectionClient.FORBIDDEN_DATA_PORT) {
            statusText.setTextColor(0xFFF44336);
            statusText.setText(R.string.connect_port_forbidden_8080);
            return;
        }
        if (!isValidDevicePort(port)) {
            statusText.setTextColor(0xFFF44336);
            statusText.setText(R.string.connect_port_invalid);
            return;
        }

        getSharedPreferences(PREF_NAME, 0).edit().putInt(PREF_DEVICE_PORT, port).apply();

        statusText.setText("");
        targetText.setVisibility(View.GONE);
        setConnecting(true);

        new Thread(new Runnable() {
            @Override
            public void run() {
                UDPListener udp = UDPListener.getInstance();
                if (udp != null) {
                    udp.waitforUpdate();
                }
                SharedPreferences pref = getSharedPreferences(PREF_NAME, 0);
                final String host = pref.getString("address", "");
                runOnUiThread(new Runnable() {
                    @Override
                    public void run() {
                        if (host == null || host.isEmpty()) {
                            setConnecting(false);
                            statusText.setText(R.string.connect_manager_not_found);
                            return;
                        }
                        targetText.setVisibility(View.VISIBLE);
                        targetText.setText(getString(R.string.connect_target_format, host, port));
                        String deviceName = "TRAPS-CK " + android.os.Build.MODEL;
                        connectionClient.connectAndRegister(
                                host,
                                port,
                                identity.macReliable ? identity.mac : "",
                                identity.ip,
                                identity.deviceId,
                                deviceName,
                                "4.0"
                        );
                    }
                });
            }
        }, "Connect-Discover").start();
    }

    private void setConnecting(boolean value) {
        connecting = value;
        connectButton.setEnabled(!value);
        portField.setEnabled(!value);
        progress.setVisibility(value ? View.VISIBLE : View.GONE);
        if (value) {
            statusText.setText(R.string.connect_in_progress);
            statusText.setTextColor(0xFFAAAAAA);
        }
    }

    private void goToModeSelect() {
        startActivity(new Intent(this, ModeSelectActivity.class));
        finish();
    }

    @Override
    public void onRegistered(String deviceId, long serverTime) {
        setConnecting(false);
        SharedPreferences.Editor editor = getSharedPreferences(PREF_NAME, 0).edit();
        editor.putString("deviceId", deviceId);
        editor.putLong("lastServerTime", serverTime);
        editor.apply();
        goToModeSelect();
    }

    @Override
    public void onRejected(String reason, String message) {
        setConnecting(false);
        statusText.setTextColor(0xFFF44336);
        if (message != null && !message.isEmpty()) {
            statusText.setText(message);
        } else {
            statusText.setText(R.string.connect_not_authorized);
        }
    }

    @Override
    public void onError(String message) {
        setConnecting(false);
        statusText.setTextColor(0xFFF44336);
        statusText.setText(message != null ? message : getString(R.string.connect_not_authorized));
    }

    @Override
    public void onDisconnected() {
        // Reste sur cet écran ; heartbeat perdu après navigation = ModeSelect gère
    }

    @Override
    public void onHeartbeatAck(long serverTime) {
        getSharedPreferences(PREF_NAME, 0).edit().putLong("lastServerTime", serverTime).apply();
    }

    @Override
    public void onLoadBibList(int count) {
        // Liste appliquée en arrière-plan ; affichage sur JudgeHub
    }
}
