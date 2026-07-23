package com.traps.trapsapp.core;

import java.util.HashSet;
import java.util.Set;

public class SystemParam {

	private static Set<Integer> validPenaltySet = new HashSet<Integer>();
	public static final int MAX_GATE_PER_TERMINAL = 5;
	/** Patrouille : jusqu'à 5 portes × 3 bateaux A/B/C. */
	public static final int MAX_PATROL_PAD_ROWS = MAX_GATE_PER_TERMINAL * 3;
	/** Slots pénalités max (individuel = GATE_COUNT ; patrouille = GATE_COUNT × 3). */
	public static final int MAX_PENALTY_SLOTS = 75;
	public static long timeshift = 0; // difference of time between TRAPSManager and the terminal
	
	static {
		validPenaltySet.add(-1);
		validPenaltySet.add(0);
		validPenaltySet.add(2);
		validPenaltySet.add(50); 
	}	
	
	public static int GATE_COUNT = 25;

	/** Index plat Manager : porte 0-based + bateau 0=A,1=B,2=C → clé JSON = slot+1. */
	public static int flatSlot(int gateIndex0, int boat0) {
		return gateIndex0 * 3 + boat0;
	}

	public static int gateFromFlatSlot(int flatSlot0) {
		return flatSlot0 / 3;
	}

	public static int boatFromFlatSlot(int flatSlot0) {
		return flatSlot0 % 3;
	}

	public static String boatLetter(int boat0) {
		switch (boat0) {
			case 0: return "A";
			case 1: return "B";
			case 2: return "C";
			default: return "?";
		}
	}
		
	public static boolean isPenaltyValid(int value) {
		if (validPenaltySet.contains(value)) return true;
		return false;
	}
		
		
}
