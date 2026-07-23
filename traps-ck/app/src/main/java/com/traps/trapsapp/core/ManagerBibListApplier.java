package com.traps.trapsapp.core;

import android.content.Context;
import android.util.Log;

import org.json.JSONArray;
import org.json.JSONObject;

import java.util.ArrayList;
import java.util.List;

/**
 * Applique une commande Manager {@code loadBibList} : remplace la liste de
 * dossards. Les pénalités, chronos et cadenas sont réinitialisés
 * (aucune conservation des données locales des dossards précédents).
 */
public final class ManagerBibListApplier {

    private static final String TAG = "BibListApplier";

    public static final class Entry {
        public final int bib;
        public final String id;
        public final String categ;
        public final String schedule;
        public final int entry;

        public Entry(int bib, String id, String categ, String schedule, int entry) {
            this.bib = bib;
            this.id = id != null ? id : String.valueOf(bib);
            this.categ = categ != null ? categ : "";
            this.schedule = schedule != null ? schedule : "";
            this.entry = entry;
        }

        public String displayLine() {
            StringBuilder sb = new StringBuilder();
            sb.append(Utility.digit3(bib));
            if (categ != null && !categ.isEmpty()) {
                sb.append("  ").append(categ);
            }
            if (schedule != null && !schedule.isEmpty()) {
                sb.append("  ").append(schedule);
            }
            return sb.toString();
        }
    }

    private static final Object LOCK = new Object();
    private static List<Entry> lastEntries = new ArrayList<Entry>();

    private ManagerBibListApplier() {
    }

    public static List<Entry> getLastEntries() {
        synchronized (LOCK) {
            return new ArrayList<Entry>(lastEntries);
        }
    }

    /**
     * @return nombre de dossards appliqués, ou -1 en cas d'erreur
     */
    public static int apply(Context context, JSONArray bibsJson) {
        if (context == null || bibsJson == null) {
            return -1;
        }
        Context app = context.getApplicationContext();
        TrapsDB.init(app);
        TrapsDB db = TrapsDB.getInstance();
        if (db == null) {
            Log.e(TAG, "TrapsDB not available");
            return -1;
        }

        ArrayList<Entry> entries = new ArrayList<Entry>();
        ArrayList<Integer> numbers = new ArrayList<Integer>();
        try {
            for (int i = 0; i < bibsJson.length(); i++) {
                JSONObject obj = bibsJson.getJSONObject(i);
                int bib = obj.optInt("bib", 0);
                if (bib <= 0) {
                    String id = obj.optString("id", "");
                    try {
                        bib = Integer.parseInt(id.trim());
                    } catch (Exception ignored) {
                        bib = 0;
                    }
                }
                if (bib <= 0) {
                    continue;
                }
                Entry e = new Entry(
                        bib,
                        obj.optString("id", String.valueOf(bib)),
                        obj.optString("categ", ""),
                        obj.optString("schedule", ""),
                        obj.optInt("entry", 0)
                );
                entries.add(e);
                numbers.add(bib);
            }
        } catch (Exception e) {
            Log.e(TAG, "parse failed", e);
            return -1;
        }

        db.clearBibs();
        db.createBibListInteger(numbers, null);

        // Intentionnellement : pas de restauration pénalités / chronos / cadenas.
        // Une nouvelle liste Manager repart sur des dossards vides.

        synchronized (LOCK) {
            lastEntries = entries;
        }
        Log.i(TAG, "Applied " + entries.size() + " bibs from Manager");
        return entries.size();
    }
}
