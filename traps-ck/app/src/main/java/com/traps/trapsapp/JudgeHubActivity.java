package com.traps.trapsapp;

import android.content.Intent;
import android.os.Bundle;
import android.view.View;
import android.view.WindowManager;
import android.widget.ArrayAdapter;
import android.widget.Button;
import android.widget.ListView;
import android.widget.TextView;
import android.widget.Toast;

import androidx.appcompat.app.AppCompatActivity;

import com.traps.trapsapp.core.ManagerBibListApplier;
import com.traps.trapsapp.core.TrapsDB;
import com.traps.trapsapp.network.DeviceConnectionClient;

import java.util.ArrayList;
import java.util.List;

/**
 * Phase B — hub juge : liste dossards Manager + actions Pénalités / Départ / Arrivée.
 */
public class JudgeHubActivity extends AppCompatActivity implements DeviceConnectionClient.Listener {

    private static final int REQ_CONFIG_PENALTY = 1;
    private static final int REQ_CONFIG_CHRONO = 2;
    private static final int REQ_PENALTY = 3;
    private static final int REQ_CHRONO = 4;

    private TextView statusText;
    private TextView emptyHint;
    private ListView bibListView;
    private Button penaltyButton;
    private Button startButton;
    private Button finishButton;
    private ArrayAdapter<String> listAdapter;
    private final ArrayList<String> displayLines = new ArrayList<String>();

    private int pendingChronoType;
    private DeviceConnectionClient connectionClient;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_judge_hub);
        getWindow().setFlags(WindowManager.LayoutParams.FLAG_FULLSCREEN,
                WindowManager.LayoutParams.FLAG_FULLSCREEN);

        TrapsDB.init(this);

        statusText = findViewById(R.id.hubStatus);
        emptyHint = findViewById(R.id.hubEmptyHint);
        bibListView = findViewById(R.id.hubBibList);
        penaltyButton = findViewById(R.id.hubPenaltyButton);
        startButton = findViewById(R.id.hubStartButton);
        finishButton = findViewById(R.id.hubFinishButton);

        listAdapter = new ArrayAdapter<String>(this, R.layout.hub_bib_row, displayLines);
        bibListView.setAdapter(listAdapter);

        int mode = getSharedPreferences(ConnectActivity.PREF_NAME, 0)
                .getInt(ConnectActivity.PREF_COMPETITION_MODE, ModeSelectActivity.MODE_INDIVIDUAL);
        setTitle(modeTitle(mode));

        connectionClient = DeviceConnectionClient.getInstance();
        connectionClient.setAppContext(this);
        connectionClient.setListener(this);

        if (!connectionClient.isConnected()) {
            returnToConnect(getString(R.string.connect_disconnected));
            return;
        }

        penaltyButton.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                openPenalty();
            }
        });
        startButton.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                openChrono(0);
            }
        });
        finishButton.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                openChrono(1);
            }
        });

        refreshList();
    }

    @Override
    protected void onResume() {
        super.onResume();
        connectionClient.setListener(this);
        refreshList();
    }

    private String modeTitle(int mode) {
        switch (mode) {
            case ModeSelectActivity.MODE_PATROL:
                return getString(R.string.mode_patrol);
            case ModeSelectActivity.MODE_KCROSS:
                return getString(R.string.mode_kcross);
            default:
                return getString(R.string.mode_individual);
        }
    }

    private void refreshList() {
        displayLines.clear();
        List<ManagerBibListApplier.Entry> entries = ManagerBibListApplier.getLastEntries();
        if (entries.isEmpty()) {
            // Fallback : numéros déjà en base (ex. après redémarrage activité)
            TrapsDB db = TrapsDB.getInstance();
            if (db != null) {
                ArrayList<com.traps.trapsapp.core.Bib> bibs = db.getBibList();
                if (bibs != null) {
                    for (com.traps.trapsapp.core.Bib bib : bibs) {
                        displayLines.add(bib.getStringBibnumber());
                    }
                }
            }
        } else {
            for (ManagerBibListApplier.Entry e : entries) {
                displayLines.add(e.displayLine());
            }
        }
        listAdapter.notifyDataSetChanged();

        boolean hasBibs = !displayLines.isEmpty();
        emptyHint.setVisibility(hasBibs ? View.GONE : View.VISIBLE);
        bibListView.setVisibility(hasBibs ? View.VISIBLE : View.GONE);
        penaltyButton.setEnabled(hasBibs);
        startButton.setEnabled(hasBibs);
        finishButton.setEnabled(hasBibs);

        if (hasBibs) {
            statusText.setText(getString(R.string.hub_bib_count, displayLines.size()));
            statusText.setTextColor(0xFFAAAAAA);
        } else {
            statusText.setText(R.string.hub_waiting_list);
            statusText.setTextColor(0xFFFF9800);
        }
    }

    private void openPenalty() {
        if (displayLines.isEmpty()) {
            return;
        }
        Intent intent = new Intent(this, TerminalConfigActivity.class);
        intent.putExtra("chrono", false);
        startActivityForResult(intent, REQ_CONFIG_PENALTY);
    }

    private void openChrono(int chronoType) {
        if (displayLines.isEmpty()) {
            return;
        }
        pendingChronoType = chronoType;
        Intent intent = new Intent(this, TerminalConfigActivity.class);
        intent.putExtra("chrono", true);
        startActivityForResult(intent, REQ_CONFIG_CHRONO);
    }

    @Override
    protected void onActivityResult(int requestCode, int resultCode, Intent data) {
        super.onActivityResult(requestCode, resultCode, data);
        if (requestCode == REQ_CONFIG_PENALTY && resultCode == RESULT_OK) {
            startActivityForResult(new Intent(this, PenaltyActivity.class), REQ_PENALTY);
        } else if (requestCode == REQ_CONFIG_CHRONO && resultCode == RESULT_OK) {
            Intent intent = new Intent(this, ChronoActivity.class);
            intent.putExtra("chronoType", pendingChronoType);
            startActivityForResult(intent, REQ_CHRONO);
        } else if (requestCode == REQ_PENALTY || requestCode == REQ_CHRONO) {
            refreshList();
        }
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

    @Override
    public void onRegistered(String deviceId, long serverTime) {
    }

    @Override
    public void onRejected(String reason, String message) {
        returnToConnect(message != null ? message : getString(R.string.connect_not_authorized));
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
        if (count < 0) {
            Toast.makeText(this, R.string.hub_load_error, Toast.LENGTH_LONG).show();
            return;
        }
        Toast.makeText(this, getString(R.string.hub_load_success, count), Toast.LENGTH_SHORT).show();
        refreshList();
    }
}
