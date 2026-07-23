# Protocole appareils Traps App ↔ TRAPSManager

## Architecture à 2 ports (compatibilité)

| Port | Rôle | Clients |
|------|------|---------|
| **Données** (UDP Hello, ~8080) | Pénalités / chronos JSON+EOT + `command:0` liste dossards | **Ancienne** Traps App |
| **8081** (`deviceConnectionPort`) | register / heartbeat / `loadBibList` enrichi | **Nouvelle** app (en cours) |

## Découverte UDP
HelloBroadcaster annonce : `timestamp,ip,**portDonnées**,httpPort` (port UDP 5432).  
L’ancienne app se connecte au **port données** annoncé.

## Protocole legacy (port données) — liste dossards
Requête :
```json
{"command":0}
```
Réponse :
```json
{"response":0,"bibList":[123,45,56]}
```
Fin de trame : octet EOT (4) + `\n`.

## register (nouvelle app → Manager) — port 8081
```json
{"type":"register","deviceId":"...","deviceName":"Porte 5","mac":"AA:BB:CC:DD:EE:FF","version":"x.y","capabilities":[]}
```
- **mac** recommandé (garde-fou principal)
- Réponse OK : `{"type":"registered","deviceId":"...","serverTime":...}`
- Réponse KO : `{"type":"rejected","reason":"not_authorized","message":"..."}`

## heartbeat — port 8081
```json
{"type":"heartbeat"}
```
Ack : `{"type":"heartbeat_ack","serverTime":...}`  
Sans heartbeat > 45 s → appareil considéré perdu / déconnecté.

## loadBibList (Manager → nouvelle app) — port 8081
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
