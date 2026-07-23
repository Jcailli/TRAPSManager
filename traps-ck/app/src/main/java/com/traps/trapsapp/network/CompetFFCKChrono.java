package com.traps.trapsapp.network;


public class CompetFFCKChrono extends CompetFFCKPacket {

	private int chrono;


	public CompetFFCKChrono(int bibnumber, int chrono) {
		this.bibnumber = bibnumber;
		this.chrono = chrono;
	}


	public String toString() {
		return "bibnumber="+bibnumber+" | chrono="+chrono;
	}
	
	public boolean isValid() {
		if (bibnumber <= 0) return false;
		if (chrono < 0) return false;
		return true;
	}

	/**
	 * Returns a text message to be sent to CompetFFCK
	 * Format: "chrono bib chrono\r"
	 * 
	 * @return
	 */
	public String getMessage() {
		return String.format("chrono %d %d\r", bibnumber, chrono);
	}

}
