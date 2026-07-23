package com.traps.trapsapp.network;


import org.json.JSONException;
import org.json.JSONObject;

public class TRAPSChrono extends TRAPSPacket {
	
	protected int type;  // 0 = start, 1 = finish third, 2 = finish first
	protected long chrono;
	protected int finishRole; // 1 ou 3 pour arrivée ; 0 pour départ
	
	public TRAPSChrono(int bibnumber, int type, long chrono) {
		this(bibnumber, type, chrono, type == 2 ? 1 : (type == 1 ? 3 : 0));
	}

	public TRAPSChrono(int bibnumber, int type, long chrono, int finishRole) {
		this.bibnumber = bibnumber;
		this.type = type;
		this.chrono = chrono;
		this.finishRole = finishRole;
	}
	
	public boolean isValid() {
		return true;
	}
	
	public int getBibnumber() {
		return bibnumber;
	}

	public JSONObject getJsonObject() {
		JSONObject json = new JSONObject();
		try {
			if (type == 0) {
				json.put("command", 2);
			} else {
				json.put("command", 3);
				json.put("finishRole", finishRole > 0 ? finishRole : 3);
			}
			json.put("bib", bibnumber);
			json.put("time", chrono);
		} catch (JSONException e) {
			e.printStackTrace();
		}
		return json;
	}
}
