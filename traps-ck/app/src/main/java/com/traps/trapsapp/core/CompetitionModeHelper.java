package com.traps.trapsapp.core;

import android.content.Context;

import com.traps.trapsapp.ConnectActivity;
import com.traps.trapsapp.ModeSelectActivity;

/** Mode de compétition choisi après connexion Manager (prefs TRAPS_PREF). */
public final class CompetitionModeHelper {

    private CompetitionModeHelper() {
    }

    public static int getMode(Context context) {
        if (context == null) {
            return ModeSelectActivity.MODE_INDIVIDUAL;
        }
        return context.getSharedPreferences(ConnectActivity.PREF_NAME, Context.MODE_PRIVATE)
                .getInt(ConnectActivity.PREF_COMPETITION_MODE, ModeSelectActivity.MODE_INDIVIDUAL);
    }

    public static boolean isPatrol(Context context) {
        return getMode(context) == ModeSelectActivity.MODE_PATROL;
    }

    public static boolean isKCross(Context context) {
        return getMode(context) == ModeSelectActivity.MODE_KCROSS;
    }
}
