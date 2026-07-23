package com.traps.trapsapp.network;

import java.io.IOException;
import java.io.OutputStream;
import java.net.Socket;
import java.net.UnknownHostException;
import java.util.concurrent.LinkedBlockingQueue;

import android.util.Log;

/**
 * Thread de communication avec CompetFFCK
 * Utilise le protocole texte simple de CompetFFCK
 */
public class CompetFFCKThread extends Thread {

	// wait for 250ms between each message sent (comme dans CompetFFCK)
	private static final int COMPETFFCK_PAUSE = 250;
	private boolean connected = false;
	private LinkedBlockingQueue<CompetFFCKPacket> outputQ;
	private OutputStream outputStream;
	private Socket socket;


	public CompetFFCKThread(Socket socket) throws UnknownHostException, IOException {
		this.socket = socket;
		outputStream = socket.getOutputStream();
		connected = true;
		outputQ = new LinkedBlockingQueue<CompetFFCKPacket>();
		start();
	}

	
	public void disconnect() {
		
		connected = false;
		
		try {
			socket.close();
		} catch (Exception e) {}
		try {
			outputQ.put(new CompetFFCKPacket());
		} catch (Exception e) {}

	}


	public boolean isConnected() {
		return connected;
	}

	public void addPenalty(int bibnumber, int gateId, int penalty) {
		try {
			outputQ.put(new CompetFFCKPenalty(bibnumber, gateId, penalty));
		} catch (InterruptedException e) {}
	}
	
	public void addChrono(int bibnumber, int chrono) {
		try {
			outputQ.put(new CompetFFCKChrono(bibnumber, chrono));
		} catch (InterruptedException e) {}
	}
 
 
	private void sleep(int pause) {
		try {
			Thread.sleep(pause);
		} catch (InterruptedException e) {}

	}

	public void run() {

		Log.i("CompetFFCKClient", "Starting thread...");
		if (!connected) {
			Log.i("CompetFFCKClient", "Client not connected");
			return;
		}

		try {
			while (connected) {
				// wait for a packet to be available
				CompetFFCKPacket packet = outputQ.take();
				if (packet.isValid()) {
					// Envoyer le message texte à CompetFFCK
					String message = packet.getMessage();
					outputStream.write(message.getBytes());
					outputStream.flush();
					sleep(COMPETFFCK_PAUSE);
				} 
			}

		} catch (Exception e) {} 
				
		connected = false;
		try {
			socket.close();
		} catch (Exception e) {}
		Log.i("CompetFFCKClient", "Disconnected from CompetFFCK");
		
		
	}

	
}
