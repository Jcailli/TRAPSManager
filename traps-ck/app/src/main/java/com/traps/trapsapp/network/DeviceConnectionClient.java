package com.traps.trapsapp.network;

import android.os.Handler;
import android.os.Looper;
import android.util.Log;

import org.json.JSONArray;
import org.json.JSONObject;

import java.io.BufferedReader;
import java.io.InputStreamReader;
import java.io.OutputStreamWriter;
import java.io.PrintWriter;
import java.net.InetSocketAddress;
import java.net.Socket;
import java.nio.charset.Charset;
import java.util.Locale;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.atomic.AtomicBoolean;

/**
 * Client TCP supervision Manager (port 8081) : register + heartbeat.
 * Messages JSON, une ligne = un message (\\n).
 */
public class DeviceConnectionClient {

    /** Port supervision appareils par défaut (≠ 8080 = port données). */
    public static final int DEFAULT_DEVICE_PORT = 8081;
    /** Port données pénalités/chronos — interdit pour la supervision. */
    public static final int FORBIDDEN_DATA_PORT = 8080;
    private static final String TAG = "DeviceConn";
    private static final long HEARTBEAT_INTERVAL_MS = 15000;
    private static final int CONNECT_TIMEOUT_MS = 8000;

    public interface Listener {
        void onRegistered(String deviceId, long serverTime);

        void onRejected(String reason, String message);

        void onError(String message);

        void onDisconnected();

        void onHeartbeatAck(long serverTime);
    }

    private static DeviceConnectionClient instance;

    private final Handler mainHandler = new Handler(Looper.getMainLooper());
    private final ExecutorService executor = Executors.newSingleThreadExecutor();
    private final AtomicBoolean running = new AtomicBoolean(false);

    private Socket socket;
    private PrintWriter writer;
    private BufferedReader reader;
    private Listener listener;
    private final Handler heartbeatHandler = new Handler(Looper.getMainLooper());
    private final Runnable heartbeatRunnable = new Runnable() {
        @Override
        public void run() {
            if (!running.get()) {
                return;
            }
            sendHeartbeat();
            heartbeatHandler.postDelayed(this, HEARTBEAT_INTERVAL_MS);
        }
    };

    public static synchronized DeviceConnectionClient getInstance() {
        if (instance == null) {
            instance = new DeviceConnectionClient();
        }
        return instance;
    }

    public void setListener(Listener listener) {
        this.listener = listener;
    }

    public boolean isConnected() {
        return running.get() && socket != null && socket.isConnected() && !socket.isClosed();
    }

    public void connectAndRegister(final String host, final int port,
                                   final String mac, final String ip,
                                   final String deviceId, final String deviceName,
                                   final String version) {
        disconnectInternal(false);
        executor.execute(new Runnable() {
            @Override
            public void run() {
                try {
                    Log.i(TAG, "Connecting to " + host + ":" + port);
                    Socket s = new Socket();
                    s.connect(new InetSocketAddress(host, port), CONNECT_TIMEOUT_MS);
                    s.setTcpNoDelay(true);
                    socket = s;
                    writer = new PrintWriter(new OutputStreamWriter(s.getOutputStream(), Charset.forName("UTF-8")), true);
                    reader = new BufferedReader(new InputStreamReader(s.getInputStream(), Charset.forName("UTF-8")));
                    running.set(true);

                    JSONObject register = new JSONObject();
                    register.put("type", "register");
                    register.put("deviceId", deviceId);
                    register.put("deviceName", deviceName);
                    register.put("mac", mac != null ? mac : "");
                    register.put("ip", ip != null ? ip : "");
                    register.put("version", version);
                    register.put("capabilities", new JSONArray());
                    sendLine(register.toString());

                    startReaderLoop();
                } catch (Exception e) {
                    Log.e(TAG, "connect failed", e);
                    disconnectInternal(false);
                    notifyError(buildConnectErrorMessage(host, port, e));
                }
            }
        });
    }

    private static String buildConnectErrorMessage(String host, int port, Exception e) {
        String detail;
        String name = e.getClass().getSimpleName();
        String msg = e.getMessage() != null ? e.getMessage().toLowerCase(Locale.US) : "";
        if (e instanceof java.net.SocketTimeoutException || msg.contains("timed out")) {
            detail = "délai dépassé (timeout)";
        } else if (e instanceof java.net.ConnectException || msg.contains("refused") || msg.contains("econnrefused")) {
            detail = "connexion refusée";
        } else if (msg.contains("unreachable") || msg.contains("enetunreach") || msg.contains("ehostunreach")) {
            detail = "hôte injoignable";
        } else if (msg.contains("network is unreachable") || msg.contains("no route")) {
            detail = "réseau injoignable";
        } else {
            detail = name + (e.getMessage() != null ? ": " + e.getMessage() : "");
        }
        return "Impossible de joindre le Manager " + host + ":" + port
                + " (" + detail + ").\n"
                + "Vérifiez que TRAPSManager écoute sur le port " + port
                + " et autorisez TCP " + port + " dans le pare-feu Windows.";
    }

    private void startReaderLoop() {
        Thread readerThread = new Thread(new Runnable() {
            @Override
            public void run() {
                try {
                    String line;
                    while (running.get() && reader != null && (line = reader.readLine()) != null) {
                        handleIncoming(line.trim());
                    }
                } catch (Exception e) {
                    if (running.get()) {
                        Log.e(TAG, "read error", e);
                        notifyError("Connexion au Manager interrompue");
                    }
                } finally {
                    boolean wasRunning = running.getAndSet(false);
                    stopHeartbeat();
                    closeQuietly();
                    if (wasRunning) {
                        notifyDisconnected();
                    }
                }
            }
        }, "DeviceConn-Reader");
        readerThread.setDaemon(true);
        readerThread.start();
    }

    private void handleIncoming(String line) {
        if (line.isEmpty()) {
            return;
        }
        try {
            JSONObject json = new JSONObject(line);
            String type = json.optString("type", "");
            if ("registered".equals(type)) {
                final String id = json.optString("deviceId", "");
                final long serverTime = json.optLong("serverTime", 0);
                startHeartbeat();
                mainHandler.post(new Runnable() {
                    @Override
                    public void run() {
                        if (listener != null) {
                            listener.onRegistered(id, serverTime);
                        }
                    }
                });
            } else if ("rejected".equals(type)) {
                final String reason = json.optString("reason", "not_authorized");
                final String message = json.optString("message", "Connexion au manager non autorisée");
                running.set(false);
                stopHeartbeat();
                closeQuietly();
                mainHandler.post(new Runnable() {
                    @Override
                    public void run() {
                        if (listener != null) {
                            // Message produit demandé ; le détail Manager reste en log
                            listener.onRejected(reason,
                                    "Connexion au manager non autorisée");
                        }
                    }
                });
            } else if ("heartbeat_ack".equals(type)) {
                final long serverTime = json.optLong("serverTime", 0);
                mainHandler.post(new Runnable() {
                    @Override
                    public void run() {
                        if (listener != null) {
                            listener.onHeartbeatAck(serverTime);
                        }
                    }
                });
            } else {
                Log.d(TAG, "Unhandled message type: " + type);
            }
        } catch (Exception e) {
            Log.e(TAG, "JSON parse error: " + line, e);
        }
    }

    private void startHeartbeat() {
        stopHeartbeat();
        heartbeatHandler.postDelayed(heartbeatRunnable, HEARTBEAT_INTERVAL_MS);
    }

    private void stopHeartbeat() {
        heartbeatHandler.removeCallbacks(heartbeatRunnable);
    }

    private void sendHeartbeat() {
        executor.execute(new Runnable() {
            @Override
            public void run() {
                try {
                    JSONObject hb = new JSONObject();
                    hb.put("type", "heartbeat");
                    sendLine(hb.toString());
                } catch (Exception e) {
                    Log.e(TAG, "heartbeat failed", e);
                }
            }
        });
    }

    private synchronized void sendLine(String line) {
        if (writer == null) {
            return;
        }
        writer.print(line);
        writer.print('\n');
        writer.flush();
    }

    public void disconnect() {
        disconnectInternal(true);
    }

    private void disconnectInternal(boolean notify) {
        running.set(false);
        stopHeartbeat();
        closeQuietly();
        if (notify) {
            notifyDisconnected();
        }
    }

    private void closeQuietly() {
        try {
            if (writer != null) {
                writer.close();
            }
        } catch (Exception ignored) {
        }
        try {
            if (reader != null) {
                reader.close();
            }
        } catch (Exception ignored) {
        }
        try {
            if (socket != null) {
                socket.close();
            }
        } catch (Exception ignored) {
        }
        writer = null;
        reader = null;
        socket = null;
    }

    private void notifyError(final String message) {
        mainHandler.post(new Runnable() {
            @Override
            public void run() {
                if (listener != null) {
                    listener.onError(message);
                }
            }
        });
    }

    private void notifyDisconnected() {
        mainHandler.post(new Runnable() {
            @Override
            public void run() {
                if (listener != null) {
                    listener.onDisconnected();
                }
            }
        });
    }
}
