package com.traps.trapsapp;

import java.net.InetSocketAddress;
import java.text.SimpleDateFormat;

import java.util.ArrayList;
import java.util.Date;
import java.util.Locale;


import android.app.AlertDialog;
import android.content.DialogInterface;
import android.content.SharedPreferences;
import android.content.pm.ActivityInfo;
import android.media.AudioManager;
import android.media.SoundPool;
import android.os.Build;
import android.os.Bundle;
import android.os.Handler;
import androidx.appcompat.app.AppCompatActivity;
import android.telephony.PhoneNumberUtils;
import android.telephony.SmsManager;
import android.util.Log;
import android.view.Menu;
import android.view.MenuItem;
import android.view.View;
import android.view.ViewConfiguration;
import android.view.Window;
import android.view.WindowManager;
import android.widget.AdapterView;
import android.widget.AdapterView.OnItemSelectedListener;
import android.widget.ArrayAdapter;
import android.widget.Button;
import android.widget.ImageButton;
import android.widget.Spinner;
import android.widget.TextView;

import android.content.pm.PackageManager;
import android.Manifest;
import androidx.core.app.ActivityCompat;
import androidx.core.content.ContextCompat;
import androidx.annotation.NonNull;
import android.content.Intent;
import android.net.Uri;
import android.provider.Settings;

import com.traps.trapsapp.core.Bib;
import com.traps.trapsapp.core.CompetitionModeHelper;
import com.traps.trapsapp.core.SystemParam;
import com.traps.trapsapp.core.TrapsDB;
import com.traps.trapsapp.core.Utility;
import com.traps.trapsapp.network.TRAPSChrono;
import com.traps.trapsapp.network.TRAPSManagerThread;

public class ChronoActivity extends AppCompatActivity {

	private static final boolean SMS_ACTIVATED = true;
	private static SimpleDateFormat dateFormatter1 = new SimpleDateFormat("HH:mm:ss", Locale.US);
		 
	private int bibIndex = 0;
	private int chronoType = 0;  // 0=start, 1=finish (legacy / 3ème)
	private boolean lock = false;
	private boolean patrolFinishMode = false;
	/** Après déverrouillage manuel : autorise de reprendre A1 et A3 sans re-cadenas auto. */
	private boolean editingUnlocked = false;

	private boolean smsEnabled = false;
	private boolean transferEnabled = false;
	private SmsManager smsManager = SmsManager.getDefault();
	private String dAddress;
	private TRAPSManagerThread trapsManager;
	private SharedPreferences settings;
	
	private ArrayList<Bib> bibList;
	private Spinner spinner;
	private TrapsDB db;
	private TextView chronoTextView;
	private TextView chronoFirstTextView;
	private TextView runningTextView;
	private ImageButton lockButton;
	private Button lapButton;
	private Button lapButtonFirst;
	private Button lapButtonThird;
	private Handler handler = new Handler();
	private Runnable runnable;
	private boolean autodetect = true;
	private InetSocketAddress lanAddress;
	private int pendingChronoType = -1;

	private SoundPool soundPool;
	public int sndHighPitch;
	
	@Override
	protected void onCreate(Bundle savedInstanceState) {
		super.onCreate(savedInstanceState);
		setRequestedOrientation(ActivityInfo.SCREEN_ORIENTATION_PORTRAIT);
		if(Build.VERSION.SDK_INT <= 10 || (Build.VERSION.SDK_INT >= 14 &&    
                ViewConfiguration.get(this).hasPermanentMenuKey())) {
			requestWindowFeature(Window.FEATURE_NO_TITLE);
		}   
		setContentView(R.layout.activity_chrono);
		getWindow().setFlags(          
				WindowManager.LayoutParams.FLAG_FULLSCREEN,  
				WindowManager.LayoutParams.FLAG_FULLSCREEN);  
	
		settings = getSharedPreferences("SETTINGS_TRANSFER", MODE_PRIVATE);
		dAddress = settings.getString(TerminalConfigActivity.KEY_SMS_ADDRESS, "");
		smsEnabled = settings.getBoolean(TerminalConfigActivity.KEY_SMS_ENABLED, false);
		transferEnabled = settings.getBoolean(TerminalConfigActivity.KEY_TRANSFER_ENABLED, false);
		chronoType = getIntent().getExtras().getInt("chronoType", 0);
		patrolFinishMode = (chronoType == 1) && CompetitionModeHelper.isPatrol(this);
				
		autodetect = settings.getBoolean(TerminalConfigActivity.KEY_AUTODETECT, true);
		lanAddress = new InetSocketAddress(settings.getString(
				TerminalConfigActivity.KEY_IP_ADDRESS, ""), settings.getInt(
				TerminalConfigActivity.KEY_PORT, 8080));

		String title = "CHRONO ";
		if (patrolFinishMode) title += "PATROUILLE ";
		if (smsEnabled && transferEnabled) title += "SMS";
		else if (transferEnabled) title += "WIFI";
		setTitle(title);
		
		db = TrapsDB.getInstance();
		bibList = db.getBibList();
		
		String stringArray[] = new String[bibList.size()];
		for (int index = 0; index < stringArray.length; index++) {
			stringArray[index] = bibList.get(index).getStringBibnumber();
		}
		ArrayAdapter<String> adapter = new ArrayAdapter<String>(this,
				R.layout.spinnerlayout, stringArray);
		spinner = (Spinner) findViewById(R.id.chronoSpinner); 
		spinner.setAdapter(adapter);
		spinner.setOnItemSelectedListener(new OnItemSelectedListener() {
			@Override
			public void onItemSelected(AdapterView<?> arg0, View arg1, int arg2, long arg3) {
				changeBib(arg2);
			}
			@Override
			public void onNothingSelected(AdapterView<?> arg0) {
			}
		}); 
		
		chronoTextView = (TextView)findViewById(R.id.textViewChrono);
		chronoFirstTextView = (TextView)findViewById(R.id.textViewChronoFirst);
		
		ImageButton prevButton = (ImageButton) findViewById(R.id.chrono_previous_button);
		prevButton.setOnClickListener(new View.OnClickListener() {
			public void onClick(View v) { prevBib(); }
		});
		ImageButton nextButton = (ImageButton) findViewById(R.id.chrono_next_button);
		nextButton.setOnClickListener(new View.OnClickListener() {
			public void onClick(View v) { nextBib(); }
		});
	
		lockButton = (ImageButton) findViewById(R.id.lockImageButton);
		lockButton.setOnClickListener(new View.OnClickListener() {
			public void onClick(View v) {
				if (lock) {
					new AlertDialog.Builder(ChronoActivity.this)
							.setTitle("Déverrouiller")
							.setMessage("Déverrouiller pour reprendre un temps ?")
							.setPositiveButton(R.string.OK, new DialogInterface.OnClickListener() {
								@Override
								public void onClick(DialogInterface dialog, int which) {
									editingUnlocked = true;
									setLock(false);
								}
							})
							.setNegativeButton(R.string.cancel, null)
							.show();
				} else {
					editingUnlocked = false;
					setLock(true);
				}
			}
		});
		
		lapButton = (Button)findViewById(R.id.lapButton);
		lapButtonFirst = (Button)findViewById(R.id.lapButtonFirst);
		lapButtonThird = (Button)findViewById(R.id.lapButtonThird);

		if (patrolFinishMode) {
			lapButton.setVisibility(View.GONE);
			lapButtonFirst.setVisibility(View.VISIBLE);
			lapButtonThird.setVisibility(View.VISIBLE);
			chronoFirstTextView.setVisibility(View.VISIBLE);
			lapButtonFirst.setOnClickListener(new View.OnClickListener() {
				@Override
				public void onClick(View v) {
					requestLap(Bib.CHRONO_FINISH_FIRST);
				}
			});
			lapButtonThird.setOnClickListener(new View.OnClickListener() {
				@Override
				public void onClick(View v) {
					requestLap(Bib.CHRONO_FINISH);
				}
			});
		} else {
			if (chronoType==0) lapButton.setText("\nDÉPART\n");
			else lapButton.setText("\nARRIVÉE\n");
			lapButton.setOnClickListener(new View.OnClickListener() {
				@Override
				public void onClick(View v) {
					requestLap(chronoType);
				}
			});
		}
		
		trapsManager = new TRAPSManagerThread();
		if (transferEnabled && !smsEnabled) {
			trapsManager.start();
			if (autodetect)
				trapsManager.setAddress(this, null);
			else
				trapsManager.setAddress(this, lanAddress);
		}
		
		runningTextView = (TextView)findViewById(R.id.textViewTime);
		runnable = new Runnable() {
			    @Override
			    public void run() {
			    	long currentTime = System.currentTimeMillis()+ SystemParam.timeshift;
			    	Date date = new Date(currentTime);
			    	runningTextView.setText(" "+dateFormatter1.format(date)+"."+((currentTime/100)%10)+" ");
			    	handler.postDelayed(runnable, 100);
			    }
			  }; 

		handler.postDelayed(runnable, 100);
		soundPool = new SoundPool(5, AudioManager.STREAM_MUSIC, 0);
		sndHighPitch = soundPool.load(this, R.raw.hz600ms100, 1);
		paintBib();
	}

	private void setLock(boolean lock) {
		this.lock = lock;
		if (lock) {
			// GONE : libère l'espace pour garder les flèches accessibles et lisibles
			lapButton.setVisibility(View.GONE);
			if (patrolFinishMode) {
				lapButtonFirst.setVisibility(View.GONE);
				lapButtonThird.setVisibility(View.GONE);
			}
			lockButton.setImageResource(R.drawable.chronolock);
		}
		else {
			if (patrolFinishMode) {
				lapButton.setVisibility(View.GONE);
				lapButtonFirst.setVisibility(View.VISIBLE);
				lapButtonThird.setVisibility(View.VISIBLE);
			} else {
				lapButton.setVisibility(View.VISIBLE);
			}
			lockButton.setImageResource(R.drawable.chronounlock);
		}
	}

	public void play(int id) {
		soundPool.play(id, 1, 1, 0, 0, 1);
	}
	
	@Override
	public void onRequestPermissionsResult(int requestCode, @NonNull String[] permissions, @NonNull int[] grantResults) {
		super.onRequestPermissionsResult(requestCode, permissions, grantResults);
		if (requestCode == 1001) {
			if (grantResults.length > 0 && grantResults[0] == PackageManager.PERMISSION_GRANTED) {
				if (pendingChronoType >= 0) {
					lapButtonPressed(pendingChronoType);
					pendingChronoType = -1;
				}
			} else {
				if (!ActivityCompat.shouldShowRequestPermissionRationale(this, Manifest.permission.SEND_SMS)) {
					Utility.alert(this, "Permission bloquée",
						"L'envoi de SMS est désactivé. Veuillez l'activer dans les paramètres de l'application.");
					Intent intent = new Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS);
					Uri uri = Uri.fromParts("package", getPackageName(), null);
					intent.setData(uri);
					startActivity(intent);
				} else {
					Utility.alert(this, "Permission requise", "L'envoi SMS nécessite la permission d'envoyer des SMS.");
				}
			}
		}
	}

	private void requestLap(final int type) {
		lapButtonPressed(type);
	}

	private void lapButtonPressed(int type) {
		long currentTime = System.currentTimeMillis()+SystemParam.timeshift;
		Bib bib = bibList.get(bibIndex);

		if (patrolFinishMode) {
			if (type == Bib.CHRONO_FINISH_FIRST && bib.getFinish() > 0 && currentTime > bib.getFinish()) {
				Utility.alert(this, "Arrivée invalide",
						"L'arrivée 1 ne peut pas être après l'arrivée 3.");
				return;
			}
			if (type == Bib.CHRONO_FINISH && bib.getFinishFirst() > 0 && currentTime < bib.getFinishFirst()) {
				Utility.alert(this, "Arrivée invalide",
						"L'arrivée 3 ne peut pas être avant l'arrivée 1.");
				return;
			}
		}

		bib.setChrono(type, currentTime);
		db.updateBibChrono(type, bib.getBibnumber(), bib.getChrono(type));
		if (transferEnabled) {
			if (ContextCompat.checkSelfPermission(this, Manifest.permission.SEND_SMS)
				!= PackageManager.PERMISSION_GRANTED) {
				pendingChronoType = type;
				ActivityCompat.requestPermissions(this,
						new String[]{Manifest.permission.SEND_SMS},
						1001);
			} else {
				sendChrono(bib, type);
			}
		}
		refreshChronoLabels(bib);
		if (patrolFinishMode) {
			// Re-cadenas auto seulement hors édition manuelle, quand 1 et 3 sont pris
			if (!editingUnlocked && bib.getFinishFirst() > 0 && bib.getFinish() > 0) {
				setLock(true);
			}
		} else {
			editingUnlocked = false;
			setLock(true);
		}
		play(sndHighPitch);
	}
	
	private void sendChrono(Bib bib, int type) {
		if (smsEnabled) {
			String text = bib.chronoToSMSString(type);
			if (!SMS_ACTIVATED) {
				Log.e("SMS", "SMS IS HARDCODED AS DISABLED !");
				return;
			}
			if (dAddress == "") {
				Utility.alert(this, "Erreur",
						"Impossible d'envoyer les chronos: numero destinataire SMS incorrect") ;
				return;
			}
			if (PhoneNumberUtils.isWellFormedSmsAddress(dAddress)) {
				try {
					smsManager.sendTextMessage(dAddress, null, text, null, null);
				} catch (Exception e) {
					Log.e("SMS", e.getMessage());
					Utility.alert(this, "Erreur",
							"Impossible d'envoyer les penalités: numero destinataire SMS incorrect"
									+ dAddress);
				}
			} else
				Utility.alert(this, "Erreur", "Numero SMS incorrect:" + dAddress);
		} else {
			int finishRole = 0;
			if (type == Bib.CHRONO_FINISH_FIRST) finishRole = 1;
			else if (type == Bib.CHRONO_FINISH) finishRole = 3;
			Log.i("Terminal", "Adding chronos for bib " + bib.getBibnumber() + " type=" + type);
			trapsManager.addPacket(new TRAPSChrono(bib.getBibnumber(), type, bib.getChrono(type), finishRole));
		}
	}

	private void nextBib() {
		int nextIndex = bibIndex + 1;
		if (nextIndex >= bibList.size()) nextIndex = 0;
		changeBib(nextIndex);
	}

	private void prevBib() {
		int prevIndex = bibIndex - 1;
		if (prevIndex < 0) prevIndex = bibList.size() - 1;
		changeBib(prevIndex);
	}

	private void changeBib(int index) {
		editingUnlocked = false;
		bibIndex = index;
		paintBib();
	}

	public void onBackPressed() {};

	private void refreshChronoLabels(Bib bib) {
		if (patrolFinishMode) {
			String first = bib.getChronoStr(Bib.CHRONO_FINISH_FIRST);
			String third = bib.getChronoStr(Bib.CHRONO_FINISH);
			chronoFirstTextView.setText(first.isEmpty() ? "Arrivée 1 : —" : ("Arrivée 1 : " + first));
			chronoTextView.setText(third.isEmpty() ? "Arrivée 3 : —" : ("Arrivée 3 : " + third));
			chronoTextView.setVisibility(View.VISIBLE);
			chronoFirstTextView.setVisibility(View.VISIBLE);
		} else {
			String chronoStr = bib.getChronoStr(chronoType);
			chronoTextView.setText(chronoStr);
			chronoTextView.setVisibility("".equals(chronoStr) ? View.GONE : View.VISIBLE);
			chronoFirstTextView.setVisibility(View.GONE);
		}
	}

	private void paintBib() {
		if (bibIndex >= bibList.size()) {
			Log.e("TerminalActivity", "bibIndex out of range: " + bibIndex);
		}
		Bib bib = bibList.get(bibIndex);
		refreshChronoLabels(bib);
		if (editingUnlocked) {
			setLock(false);
		} else if (patrolFinishMode) {
			if (bib.getFinishFirst() > 0 && bib.getFinish() > 0) setLock(true);
			else setLock(false);
		} else if (bib.getChrono(chronoType)>0) {
			setLock(true);
		} else {
			setLock(false);
		}
		spinner.setSelection(bibIndex);
	}

	public void closeTerminal() {
		trapsManager.stopThread();
		finish();
	}
	
	@Override
	public boolean onOptionsItemSelected(MenuItem item) {
		int id = item.getItemId();
		if (id == R.id.exitchrono) {
			finish();
			return true;
		}
		return super.onOptionsItemSelected(item);
	}
	
	@Override
	public boolean onCreateOptionsMenu(Menu menu) {
		getMenuInflater().inflate(R.menu.chrono, menu);
		return true;
	}
}
