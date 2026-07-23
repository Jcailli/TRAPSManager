package com.traps.trapsapp.network;


public class CompetFFCKPenalty extends CompetFFCKPacket {

	private int gateId;
	private int penalty;


	public CompetFFCKPenalty(int bibnumber, int gateId, int penalty) {
		this.bibnumber = bibnumber;
		this.gateId = gateId;
		this.penalty = penalty;
	}

	
	public String toString() {
		return "bibnumber="+bibnumber+" | gateId="+gateId+" | penalty="+penalty;
	}
	
	public boolean isValid() {
		if (bibnumber <= 0) return false;
		if (gateId < 0) return false;
		if ((penalty != 0) && (penalty != 2) && (penalty != 50)) return false;
		return true;
	}

	/**
	 * Returns a text message to be sent to CompetFFCK
	 * Format: "penalty bib gateId 1 penalty\r"
	 * 
	 * @return
	 */
	public String getMessage() {
		return String.format("penalty %d %d 1 %d\r", bibnumber, gateId, penalty);
	}

}
