# Protocole appareils Traps App ↔ TRAPSManager

Port TCP par défaut : **8081** (configurable). Messages JSON, **une ligne = un message** (`\n`).

## Découverte UDP
HelloBroadcaster annonce : `timestamp,ip,portAppareils,httpPort` (port UDP 5432).

## register (Traps App → Manager)
```json
{"type":"register","deviceId":"...","deviceName":"Porte 5","mac":"AA:BB:CC:DD:EE:FF","version":"x.y","capabilities":[]}
```
- **mac** recommandé (garde-fou principal)
- Réponse OK : `{"type":"registered","deviceId":"...","serverTime":...}`
- Réponse KO : `{"type":"rejected","reason":"not_authorized","message":"..."}`

## heartbeat (toutes les ~10–15 s)
```json
{"type":"heartbeat"}
```
Ack : `{"type":"heartbeat_ack","serverTime":...}`  
Sans heartbeat > 45 s → appareil considéré perdu / déconnecté.

## loadBibList (Manager → App)
```json
{
  "type":"command",
  "command":"loadBibList",
  "parameters":{
    "count":2,
    "bibs":[
      {"bib":123,"id":"123","categ":"K1H","schedule":"10h00","entry":1}
    ]
  },
  "timestamp":0
}
```

## Affichage MAC côté Traps App
Si non connecté à TRAPSManager : afficher la MAC WiFi pour saisie dans la liste blanche Manager.
