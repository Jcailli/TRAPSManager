package com.traps.trapsapp.core;

import android.content.Context;
import android.net.wifi.WifiInfo;
import android.net.wifi.WifiManager;
import android.os.Build;
import android.provider.Settings;
import android.util.Log;

import java.net.InetAddress;
import java.net.NetworkInterface;
import java.util.Collections;
import java.util.Enumeration;
import java.util.List;
import java.util.Locale;

/**
 * Identité appareil pour le garde-fou Manager (MAC / IP / ANDROID_ID).
 * Sur Android 6+ la vraie MAC Wi‑Fi est souvent inaccessible aux apps.
 * On ne marque une MAC comme fiable que si elle appartient à l'interface
 * qui porte l'IP Wi‑Fi actuelle.
 */
public final class DeviceIdentityHelper {

    public static final String FAKE_MAC = "02:00:00:00:00:00";

    private DeviceIdentityHelper() {
    }

    public static class Identity {
        public final String mac;
        public final String ip;
        public final String androidId;
        public final String deviceId;
        public final boolean macReliable;

        public Identity(String mac, String ip, String androidId, String deviceId, boolean macReliable) {
            this.mac = mac;
            this.ip = ip;
            this.androidId = androidId;
            this.deviceId = deviceId;
            this.macReliable = macReliable;
        }
    }

    public static Identity resolve(Context context) {
        String ip = getWifiIp(context);
        String mac = "";
        boolean reliable = false;

        // Priorité : MAC de l'interface qui possède l'IP Wi‑Fi
        if (ip != null && !ip.isEmpty() && !"0.0.0.0".equals(ip)) {
            String ifaceMac = getMacForIp(ip);
            if (isUsableMac(ifaceMac)) {
                mac = normalizeMac(ifaceMac);
                reliable = true;
            }
        }

        if (!reliable) {
            mac = "";
        }

        String androidId = Settings.Secure.getString(context.getContentResolver(), Settings.Secure.ANDROID_ID);
        if (androidId == null) {
            androidId = "";
        }

        String deviceId;
        if (reliable) {
            deviceId = mac;
        } else if (ip != null && !ip.isEmpty() && !"0.0.0.0".equals(ip)) {
            deviceId = ip;
        } else if (!androidId.isEmpty()) {
            deviceId = androidId;
        } else {
            deviceId = "unknown-" + Build.MODEL;
        }

        Log.i("DeviceIdentity", "ip=" + ip + " mac=" + mac + " reliable=" + reliable
                + " deviceId=" + deviceId);
        return new Identity(mac, ip, androidId, deviceId, reliable);
    }

    public static String normalizeMac(String mac) {
        if (mac == null) {
            return "";
        }
        return mac.trim().toUpperCase(Locale.US).replace('-', ':');
    }

    private static boolean isUsableMac(String mac) {
        if (mac == null || mac.isEmpty()) {
            return false;
        }
        String n = normalizeMac(mac);
        return !FAKE_MAC.equals(n) && n.matches("([0-9A-F]{2}:){5}[0-9A-F]{2}");
    }

    /**
     * MAC de l'interface réseau qui a cette adresse IPv4.
     */
    private static String getMacForIp(String ipv4) {
        try {
            List<NetworkInterface> all = Collections.list(NetworkInterface.getNetworkInterfaces());
            for (NetworkInterface nif : all) {
                Enumeration<InetAddress> addrs = nif.getInetAddresses();
                boolean hasIp = false;
                while (addrs.hasMoreElements()) {
                    InetAddress addr = addrs.nextElement();
                    if (ipv4.equals(addr.getHostAddress())) {
                        hasIp = true;
                        break;
                    }
                }
                if (!hasIp) {
                    continue;
                }
                byte[] macBytes = nif.getHardwareAddress();
                if (macBytes == null || macBytes.length < 6) {
                    return null;
                }
                StringBuilder sb = new StringBuilder();
                for (byte b : macBytes) {
                    sb.append(String.format(Locale.US, "%02X:", b));
                }
                if (sb.length() > 0) {
                    sb.deleteCharAt(sb.length() - 1);
                }
                Log.i("DeviceIdentity", "MAC for IP " + ipv4 + " on " + nif.getName() + " = " + sb);
                return sb.toString();
            }
        } catch (Exception ex) {
            Log.w("DeviceIdentity", "getMacForIp failed", ex);
        }
        return null;
    }

    public static String getWifiIp(Context context) {
        try {
            WifiManager wifi = (WifiManager) context.getApplicationContext().getSystemService(Context.WIFI_SERVICE);
            if (wifi == null) {
                return getIpFromInterfaces();
            }
            WifiInfo info = wifi.getConnectionInfo();
            if (info == null) {
                return getIpFromInterfaces();
            }
            int ipInt = info.getIpAddress();
            if (ipInt == 0) {
                return getIpFromInterfaces();
            }
            return String.format(Locale.US, "%d.%d.%d.%d",
                    (ipInt & 0xff),
                    (ipInt >> 8 & 0xff),
                    (ipInt >> 16 & 0xff),
                    (ipInt >> 24 & 0xff));
        } catch (Exception e) {
            return getIpFromInterfaces();
        }
    }

    private static String getIpFromInterfaces() {
        try {
            List<NetworkInterface> interfaces = Collections.list(NetworkInterface.getNetworkInterfaces());
            for (NetworkInterface nif : interfaces) {
                for (InetAddress addr : Collections.list(nif.getInetAddresses())) {
                    if (!addr.isLoopbackAddress() && addr.getHostAddress() != null
                            && addr.getHostAddress().indexOf(':') < 0) {
                        return addr.getHostAddress();
                    }
                }
            }
        } catch (Exception ignored) {
        }
        return "";
    }
}
