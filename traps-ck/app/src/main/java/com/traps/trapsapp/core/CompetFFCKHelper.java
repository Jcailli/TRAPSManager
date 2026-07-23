package com.traps.trapsapp.core;

import java.net.InetSocketAddress;
import java.net.Socket;

import android.content.Context;
import android.util.Log;
import android.widget.Toast;

import com.traps.trapsapp.network.CompetFFCKThread;

public class CompetFFCKHelper {
	
	
	private CompetFFCKThread competFFCKClient;
	private static CompetFFCKHelper instance;

	
	protected CompetFFCKHelper() {	}
		
	public static CompetFFCKHelper getInstance() {
		if (instance==null) instance = new CompetFFCKHelper();
		return instance;
	}
	  
	
	public boolean isActive() {
		if ((competFFCKClient!=null) && (competFFCKClient.isConnected())) return true;
		return false;
	}
	
	
	public boolean addPenalty(int bibnumber, int gateId, int penalty) {
		if (!isActive()) {
			Log.e("TRAPS", "Trying to send penalty but CompetFFCKClient not connected. Ignore");
			return false;
		}
		Log.i("CompetFFCKHelper", "Adding to WIFI queue penalty "+penalty+" for bib number "+bibnumber+" and gate "+gateId);
		competFFCKClient.addPenalty(bibnumber, gateId, penalty);
		return true;
	}
	
	public boolean addChrono(int bibnumber, int chrono) {
		if (!isActive()) {
			Log.e("TRAPS", "Trying to send chrono but CompetFFCKClient not connected. Ignore");
			return false;
		}
		Log.i("CompetFFCKHelper", "Adding to WIFI queue chrono "+chrono+" for bib number "+bibnumber);
		competFFCKClient.addChrono(bibnumber, chrono);
		return true;
	}
	
	public void connect(Context context, InetSocketAddress address, final IConnectedResult cb) {
		
		disconnect(context);
		Log.i("CompetFFCKHelper", "Trying to connect to CompetFFCK");
		(new SocketConnectorTask(context, "Connexion CompetFFCK") {
			
			@Override
			protected void onPostExecute(Socket socket) {
				// dismiss progress bar
				super.onPostExecute(socket);
				if (socket!=null) {
					if (socket.isConnected()) {
				
						try {
							competFFCKClient = new CompetFFCKThread(socket);
							cb.connectedResult(0);
							return;
						} catch (Exception e) {}
					
					} else {
						cb.connectedResult(-1);
						return;
					}
				}
				cb.connectedResult(-2);
				return;
				
			}
		}).execute(address);
	
	}
	

	
	public void disconnect(Context context) {
		
		if (isActive()) {
			competFFCKClient.disconnect();
			Toast.makeText(context, "Déconnexion CompetFFCK", Toast.LENGTH_SHORT).show();
		}		
			
		 
	}



}
