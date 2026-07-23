# Roadmap TRAPS-CK 4.0

Document de cadrage pour l’évolution de l’application Android juges (`traps-ck/`).  
Dernière mise à jour : **2026-07-23**.

---

## 1. Vision

Aligner TRAPS-CK sur TRAPSManager moderne :
- connexion avec **garde-fou** (allowlist MAC / IP) ;
- modes **Individuel / Patrouille / KCross (Trial)** ;
- **liste de dossards** poussée par le Manager ;
- **synchronisation de la base de temps** pilotée par le Manager (pour **toutes** les données horodatées).

**UI métier** : inchangée pour Individuel, KCross Trial et Départ patrouille.  
**Exceptions** (seules adaptations UI juges) :
- Patrouille — **Pénalités** : UI **A/B/C**
- Patrouille — **Arrivée** : UI **Arrivée 1** + **Arrivée 3**

---

## 2. État actuel (3.x)

| Domaine | État |
|---------|------|
| Version documentée | ~3.1 (`Version_note.md` / `versionName` app) |
| Pénalités | Slalom + KCross (config locale) |
| Chronos | Départ / arrivée (config locale) |
| Réseau Manager | UDP Hello + TCP **port données** (~8080), JSON+EOT |
| Liste dossards | Souvent chargée côté téléphone / découverte Manager |
| Supervision 8081 | **Non** (côté Manager prêt ; app pas encore) |
| Modes patrouille A/B/C | Partiel / à aligner sur le protocole Manager |
| FFCanoe / SMS / CompetFFCK direct | Héritage encore présent |

---

## 3. Principes 4.0 (figés)

| Sujet | Décision |
|--------|----------|
| UI Individuel | **Inchangée** |
| UI KCross (Trial) | **Inchangée** |
| UI Patrouille — Départ | **Inchangée** |
| UI Patrouille — Pénalités | **Adaptée A/B/C** |
| UI Patrouille — Arrivée | **Adaptée Arrivée 1 + Arrivée 3** |
| Config pénalités, portes, chrono départ/arrivée | **Locale** sur chaque téléphone |
| Liste de dossards | **Uniquement depuis le Manager** (`loadBibList`) |
| Base de temps | Sync **depuis le Manager** ; s’applique à **départ, arrivée et pénalités** |
| Connexion | Garde-fou avant tout usage métier |
| Cadenas (lock) | Après **envoi réussi** d’une info (pénalité, départ ou arrivée) → cadenas **actif** automatiquement. Après déverrouillage, toute **modification** exige une **confirmation** (comportement déjà en place pour départ/arrivée ; à appliquer aussi aux **pénalités**, y compris A/B/C et Arrivée 1/3) |

---

## 4. Parcours utilisateur 4.0

```
1. Affichage MAC (+ IP / ID si besoin) + bouton Connexion
2. register Manager (8081) → OK / « Connexion au manager non autorisée »
3. Choix du mode : Individuel | Patrouille | KCross (Trial)
4. Affichage de la liste de dossards (reçue du Manager)
5. Choix d’action : Pénalités | Départ | Arrivée
6. Écrans juges :
   - Individuel / KCross / Patrouille-Départ → UI actuelle
   - Patrouille-Pénalités → UI A/B/C
   - Patrouille-Arrivée → UI Arrivée 1 + Arrivée 3
```

Écrans **1 → 5** = nouvelle entrée.  
Écran **6** = UI familière, sauf les deux adaptations patrouille ci-dessus.

---

## 5. Architecture réseau cible

| Canal | Port | Rôle |
|-------|------|------|
| UDP Hello | 5432 | Découverte IP + port **données** |
| TCP supervision | **8081** | `register` / `heartbeat` / `loadBibList` / **sync temps** |
| TCP données | ~8080 | Pénalités + chronos (protocole JSON actuel) |

```
TRAPS-CK ──UDP──► Hello
TRAPS-CK ──TCP 8081──► register + heartbeat + loadBibList + syncTime
TRAPS-CK ──TCP données──► penalty / start / finish
```

**Convention initiale** : port appareils **8081 fixe** (comme Manager).  
Évolution possible : 5ᵉ champ Hello `portAppareils` (changement Manager + compat).

### Identifiant appareil (MAC)
Sur Android récent, la MAC Wi‑Fi réelle est souvent inaccessible.  
Afficher la meilleure MAC possible ; sinon **IP** + identifiant secondaire (`ANDROID_ID`).  
Allowlist Manager : **MAC et/ou IP** (déjà prévu).

---

## 6. Sync base de temps

### Objectif
Tous les TRAPS-CK connectés partagent une **même référence temporelle** fournie / déclenchée par le Manager, pour :
- horodatage des **pénalités** ;
- **départ** ;
- **arrivée**.

### Orientation technique (à spécifier en phase dédiée)
- S’appuyer sur `serverTime` déjà prévu dans `registered` / `heartbeat_ack`, **et/ou**
- commande Manager → appareils : `syncTime` (broadcast ou unitaire) ;
- côté app : offset local `t_manager − t_device` appliqué à tous les timestamps émis.

Détail du protocole à documenter dans `trapsmanager/docs/protocole-appareils-traps.md` lors de l’implémentation.

---

## 7. Modes de compétition & UI métier

| Mode / action | UI métier | Encodage → Manager |
|---------------|-----------|---------------------|
| Individuel — pénalités / départ / arrivée | **Inchangée** | Clés = n° porte ; chronos classiques |
| KCross Trial — tout | **Inchangée** | Selon postes locaux |
| Patrouille — **Départ** | **Inchangée** | Start time classique |
| Patrouille — **Pénalités** | **Adaptée A/B/C** | Clés plates `1A=1, 1B=2, 1C=3…` |
| Patrouille — **Arrivée** | **Adaptée Arrivée 1 + Arrivée 3** | Deux finish (1er / 3ème) → colonnes Manager |

Le **mode choisi sur le téléphone** doit rester cohérent avec le mode configuré sur le Manager (rappel organisateur ; sync mode optionnelle plus tard).

---

## 8. Phases de réalisation

### Phase A — Socle connexion & entrée
- [ ] Écran MAC + Connexion (`register` / `rejected`)
- [ ] Heartbeat 8081
- [ ] Écran choix mode (3 boutons)
- [ ] Version app **4.0**
- [ ] Documenter limite MAC Android

### Phase B — Liste dossards & navigation
- [ ] Réception / application `loadBibList` depuis Manager
- [ ] Écran liste dossards après choix du mode
- [ ] Choix Pénalités / Départ / Arrivée → écrans existants
- [ ] Retirer le chargement autonome de liste comme chemin nominal

### Phase C — Patrouille (seules adaptations UI métier)
- [ ] Pénalités patrouille : UI **A/B/C** + envoi clés plates vers Manager
- [ ] Arrivée patrouille : UI **Arrivée 1** + **Arrivée 3** + mapping colonnes Manager
- [ ] Départ patrouille : conserver UI actuelle
- [ ] Individuel / KCross Trial : valider flux sans changement UI
- [ ] **Cadenas pénalités** : verrouillage auto après envoi (comme départ/arrivée)
- [ ] Après déverrouillage : **confirmation** avant tout changement (pénalités + chronos, tous modes)

### Phase D — Sync base de temps
- [ ] Protocole `syncTime` / offset (Manager + app)
- [ ] UI Manager : action « Synchroniser les horloges »
- [ ] Appliquer l’offset à pénalités + départ + arrivée
- [ ] Tests multi-téléphones

### Phase E — Nettoyage & durcissement
- [ ] Isoler / retirer FFCanoe si plus nécessaire
- [ ] Clarifier SMS / CompetFFCK direct (option avancée vs retiré)
- [ ] MAJ spec `protocole-appareils-traps.md`
- [ ] Tests terrain compétition

---

## 9. Impacts TRAPSManager

| Besoin | Statut Manager |
|--------|----------------|
| Allowlist MAC/IP + 8081 register/heartbeat | Existe |
| `loadBibList` | Existe |
| Sync base de temps (commande + UI) | **À faire** |
| Hello avec port 8081 | Optionnel (sinon 8081 fixe) |
| Affichage / aide saisie MAC | Amélioration UX possible |

---

## 10. Décisions ouvertes

- [ ] Hello étendu vs 8081 fixe
- [ ] Format exact `syncTime` (broadcast, RTT, précision)
- [ ] Faut-il pousser `competitionMode` / `gateCount` depuis le Manager ? (config portes reste locale pour l’instant)
- [ ] Conservatisme SMS / CompetFFCK en mode dégradé sans Manager

---

## 11. Références

- Protocole appareils : `../trapsmanager/docs/protocole-appareils-traps.md`
- Architecture monorepo : `../memory-bank/01-architecture.md` (gitignorée localement Cursor)
- Build / signature : `README.md`
