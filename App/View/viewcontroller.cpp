#include "viewcontroller.h"
#include <QQmlEngine>
#include <QDebug>
#include <QSettings>
#include <QDateTime>
#include "global.h"

ViewController::ViewController(const QStringList& hostList, int requestedTcpPort) : QObject(),
    _fontSize(18),
    _dialogBoxOpened(false),
    _fileChooserOpened(false),
    _hostList(hostList),
    _requestedTcpPort(requestedTcpPort),
    _runningTcpPort(0),
    _gateCount(25),
    _competitionMode(0),
    _kayakCrossPostCount(5),
    _kayakCrossPostTypes(QStringList())

{
    QQmlEngine::setObjectOwnership(this, QQmlEngine::CppOwnership);
    QSettings settings;
    _folder = settings.value("folder").toString();
    _showChrono = settings.value("showChrono").toBool();
    _fontSize = settings.value("fontSize", QVariant(17)).toInt();
    qDebug() << "fontSize:" << _fontSize;
    _appWindowWidth = settings.value("appWindowWidth", QVariant(800)).toInt();
    qDebug() << "appWindowWidth:" << _appWindowWidth;
    _appWindowHeight = settings.value("appWindowHeight", QVariant(600)).toInt();
    qDebug() << "appWindowHeight:" << _appWindowHeight;
    _gateCount = settings.value("gateCount", QVariant(25)).toInt();
    qDebug() << "gateCount:" << _gateCount;
    _competitionMode = settings.value("competitionMode", QVariant(0)).toInt(); // 0 = Individuel, 1 = Patrouille, 2 = Kayak Cross
    qDebug() << "competitionMode:" << _competitionMode;
    _kayakCrossPostCount = settings.value("kayakCrossPostCount", QVariant(5)).toInt();
    qDebug() << "kayakCrossPostCount:" << _kayakCrossPostCount;
    _kayakCrossPostTypes = settings.value("kayakCrossPostTypes", QVariant(QStringList())).toStringList();
    qDebug() << "kayakCrossPostTypes:" << _kayakCrossPostTypes;

}

void ViewController::setBibCount(int bibCount) {
    _bibCount = bibCount;
    emit bibCountChanged(_bibCount);
}

void ViewController::setGateCount(int gateCount) {
    // Validation selon le règlement : entre 18 et 25 portes
    if (gateCount < 18) gateCount = 18;
    if (gateCount > 25) gateCount = 25;
    
    if (_gateCount != gateCount) {
        _gateCount = gateCount;
        QSettings settings;
        settings.setValue("gateCount", _gateCount);
        emit gateCountChanged(_gateCount);
        qDebug() << "Gate count changed to:" << _gateCount;
    }
}

void ViewController::incFontSize(int step) {
    _fontSize += step;
    if (_fontSize<8) _fontSize = 9;
    if (_fontSize>50) _fontSize = 50;
    qDebug() << "Font size: " << _fontSize;
    QSettings settings;
    settings.setValue("fontSize", _fontSize);
    emit fontSizeChanged(_fontSize);
}

void ViewController::setAppWindowWidth(int width) {
    _appWindowWidth = width;
    QSettings settings;
    settings.setValue("appWindowWidth", _appWindowWidth);
}

void ViewController::setAppWindowHeight(int height) {
    _appWindowHeight = height;
    QSettings settings;
    settings.setValue("appWindowHeight", _appWindowHeight);
}

void ViewController::setFolder(const QString& folder) {
    qDebug() << "New folder for FileDialog: " << folder;
    _folder = folder;
    QSettings settings;
    settings.setValue("folder", _folder);
}

void ViewController::setShowChrono(bool showChrono) {
    _showChrono = showChrono;
    QSettings settings;
    settings.setValue("showChrono", _showChrono);
}


void ViewController::setStatusText(const QString &statusText) {
    _statusText = statusText;
    emit statusTextChanged(statusText);
}

void ViewController::openDialogBox(DialogBox* data) {
    if (_dialogBoxOpened) {
        qDebug() << "Something went wrong: a dialog box is already opened. Overwrite.";
    }
    _dialogBoxOpened = true;
    emit popup(_dialogBox = data);
}

void ViewController::dialogRejected() {
    if (!_dialogBoxOpened) {
        qDebug() << "Something went wrong: a dialog box should be opened. abort";
        return;
    }
    emit _dialogBox->rejected();
    _dialogBoxOpened = false;
}

void ViewController::dialogAccepted() {
    if (!_dialogBoxOpened) {
        qDebug() << "Something went wrong: a dialog box should be opened. abort";
        return;
    }
    emit _dialogBox->accepted();
    _dialogBoxOpened = false;
}

void ViewController::dialogButtonClicked(int index) {
    if (!_dialogBoxOpened) {
        qDebug() << "Something went wrong: a dialog box should be opened. abort";
        return;
    }
    emit _dialogBox->buttonClicked(index);
    _dialogBoxOpened = false;
}

void ViewController::openFileChooser(FileChooser *data) {
    if (_fileChooserOpened) {
        qDebug() << "Something went wrong: a file chooser is already opened. reject.";
        emit _fileChooser->selectedFilePath("");
        return;
    }
    _fileChooserOpened = true;
    _fileChooser = data;
    emit popFileChooser(_fileChooser->title(), _fileChooser->nameFilters(), _fileChooser->saveMode());

}

void ViewController::selectedFilePath(QString filePath) {
    if (!_fileChooserOpened) {
        qDebug() << "Something went wrong: a file chooser should be opened. abort";
        return;
    }
    emit _fileChooser->selectedFilePath(filePath);
    _fileChooserOpened = false;
}

void ViewController::about() {

    emit checknewVersion(true);
    emit openSoftwareUpdate();

}

void ViewController::loadPCE() {
    DialogBox* dialogBox = new DialogBox("Remplacer la liste ou ajouter des dossards ?",
                                         "Voulez-vous remplacer complètement la liste de dossards actuelle ou bien y ajouter des dossards supplémentaires ?",
                                         DIALOGBOX_QUESTION, QStringList() << "Remplacer" << "Ajouter" << "Annuler");

    dialogBox->onButtonClicked([this, dialogBox](int index) {
        if (index==2) return;
        FileChooser* fileChooser = new FileChooser("Fichier de course PCE", QStringList() << "Fichiers PCE (*.pce)" << "Tous les fichiers (*)");
        fileChooser->onSelectedFilePath([this, fileChooser, index](QString filePath) {
            qDebug() << "Selected file path: " << filePath;
            fileChooser->deleteLater();
            requestPCE(filePath, index==0); // reset (replace) if first button clicked (remplacer)
        });
        openFileChooser(fileChooser);
        dialogBox->deleteLater();
    });

    openDialogBox(dialogBox);
}

void ViewController::loadTXT() {
    DialogBox* dialogBox = new DialogBox("Remplacer la liste ou ajouter des dossards ?",
                                         "Voulez-vous remplacer complètement la liste de dossards actuelle ou bien y ajouter des dossards supplémentaires ?",
                                         DIALOGBOX_QUESTION, QStringList() << "Remplacer" << "Ajouter" << "Annuler");

    dialogBox->onButtonClicked([this, dialogBox](int index) {
        if (index==2) return;
        FileChooser* fileChooser = new FileChooser("Fichier CSV");
        fileChooser->onSelectedFilePath([this, fileChooser, index](QString filePath) {
            qDebug() << "Selected file path: " << filePath;
            fileChooser->deleteLater();
            requestTXT(filePath, index==0); // reset (replace) if first button clicked (remplacer)
        });
        openFileChooser(fileChooser);
        dialogBox->deleteLater();
    });

    openDialogBox(dialogBox);
}

void ViewController::clearPenalties() {
    DialogBox* dialogBox = new DialogBox("Effacer toutes les pénalités ?",
                                         "Notez que les pénalités ne seront effacées que de TRAPSManager, pas des systèmes tiers tels que CompetFFCK.",
                                         DIALOGBOX_QUESTION,
                                         DIALOGBOX_YES | DIALOGBOX_NO);
    dialogBox->onAccepted([this, dialogBox](){
        dialogBox->deleteLater();
        emit this->requestPenaltyClear();
    });
    dialogBox->onRejected([dialogBox](){
        dialogBox->deleteLater();
    });

    openDialogBox(dialogBox);

}

void ViewController::clearChronos() {
    DialogBox* dialogBox = new DialogBox("Effacer toutes les données chronos ?",
                                         "Notez que les chronos ne seront effacés que de TRAPSManager, pas des systèmes tiers tels que CompetFFCK.",
                                         DIALOGBOX_QUESTION,
                                         DIALOGBOX_YES | DIALOGBOX_NO);
    dialogBox->onAccepted([this, dialogBox](){
        dialogBox->deleteLater();
        emit this->requestChronoClear();
    });
    dialogBox->onRejected([dialogBox](){
        dialogBox->deleteLater();
    });

    openDialogBox(dialogBox);

}

void ViewController::printError(const QString &title, const QString &message) {
    DialogBox* dialogBox = new DialogBox(title, message, DIALOGBOX_ALERT, DIALOGBOX_OK);
    dialogBox->onAccepted([dialogBox](){
        dialogBox->deleteLater();
    });

    openDialogBox(dialogBox);
}

void ViewController::broadcastError() {
    DialogBox* dialogBox = new DialogBox("Problème réseau - TRAPS Manager doit redémarrer",
                                         "TRAPS Manager ne parvient plus à se faire connaitre sur le réseau (problème de broadcast).\nL'application va se fermer, veuillez la redémarrer.\nAucune donnée ne sera perdue pendant le temps de redémarrage.",
                                         DIALOGBOX_ALERT, DIALOGBOX_OK);
    dialogBox->onAccepted([this, dialogBox](){
        dialogBox->deleteLater();
        emit this->quit();
    });

    openDialogBox(dialogBox);
}

void ViewController::setTcpPort(int tcpPort) {
    _runningTcpPort = tcpPort;
    refreshStatusText();
}

void ViewController::viewReady() {
    if (_hostList.count()==1) {  // only one network on this machine
        _selectedHost = _hostList.value(0);
        qDebug() << "Requesting TCP server on: " << _selectedHost << ":"<< _requestedTcpPort;
        emit selectedAddress(_selectedHost);
        emit requestTcpServer(_selectedHost, _requestedTcpPort);
    }
    else if (_hostList.count()==0) {
        qDebug() << "No network, Abort";
        DialogBox* dialogBox = new DialogBox("Aucun réseau disponible",
                                             "Cette machine n'est connectée à aucun réseau. Les terminaux TRAPS envoient leur données par le réseau, il faut donc connecter cette machine au réseau par câble ou par wifi.\nVous devez redémarrer l'application.",
                                             DIALOGBOX_ALERT, DIALOGBOX_OK);
        dialogBox->onAccepted([this, dialogBox](){
            dialogBox->deleteLater();
            refreshStatusText();
            //emit this->quit();
        });

        openDialogBox(dialogBox);

    }
    else {
        qDebug() << "There are multiple ip addresses on this machine. We need to select one.";
        DialogBox* dialogBox = new DialogBox("Plusieurs réseaux disponibles",
                                             "Cette machine a des adresses sur plusieurs réseaux.\nQuelle est l'adresse correspondant au réseau des terminaux TRAPS ?",
                                             DIALOGBOX_QUESTION, _hostList);

        dialogBox->onButtonClicked([this, dialogBox](int index) {
            dialogBox->deleteLater();
            _selectedHost = _hostList.value(index);
            qDebug() << "Selected ip address: " << _selectedHost;
            qDebug() << "Requesting TCP server on: " << _selectedHost << ":"<< _requestedTcpPort;
            emit this->selectedAddress(_selectedHost);
            emit this->requestTcpServer(_selectedHost, _requestedTcpPort);

        });
        openDialogBox(dialogBox);
    }
    emit checknewVersion(false);
}

void ViewController::configureGateCount() {
    DialogBox* dialogBox = new DialogBox("Configurer le nombre de portes",
                                         "Sélectionnez le nombre de portes selon le règlement (18-25) :",
                                         DIALOGBOX_QUESTION, 
                                         QStringList() << "18" << "19" << "20" << "21" << "22" << "23" << "24" << "25");
    
    dialogBox->onButtonClicked([this, dialogBox](int index) {
        int selectedGateCount = 18 + index; // 18 + index donne 18, 19, 20, etc.
        setGateCount(selectedGateCount);
        toast(QString("Nombre de portes configuré à %0").arg(selectedGateCount), 3000);
        dialogBox->deleteLater();
    });
    
    openDialogBox(dialogBox);
}

void ViewController::exportAllData() {
    // Suggérer un nom de fichier par défaut avec timestamp
    QString defaultName = QString("export_competition_%0.csv")
                          .arg(QDateTime::currentDateTime().toString("yyyy-MM-dd_hh-mm-ss"));
    
    FileChooser* fileChooser = new FileChooser("Exporter toutes les données", 
                                               QStringList() << "Fichiers CSV (*.csv)" << "Tous les fichiers (*)",
                                               true); // Mode enregistrement
    fileChooser->onSelectedFilePath([this, fileChooser](QString filePath) {
        qDebug() << "Selected export file path: " << filePath;
        fileChooser->deleteLater();
        emit requestExportAllData(filePath);
    });
    
    openFileChooser(fileChooser);
}

void ViewController::setCompetitionMode(int mode) {
    if (mode < 0) mode = 0;
    if (mode > 2) mode = 2; // 0 = Individuel, 1 = Patrouille, 2 = Kayak Cross
    
    if (_competitionMode != mode) {
        _competitionMode = mode;
        QSettings settings;
        settings.setValue("competitionMode", _competitionMode);
        emit competitionModeChanged(_competitionMode);
        qDebug() << "Competition mode changed to:" << _competitionMode;
    }
}

void ViewController::configureCompetitionMode() {
    DialogBox* dialogBox = new DialogBox("Configurer le mode de compétition",
                                          "Sélectionnez le mode de compétition :",
                                          DIALOGBOX_QUESTION,
                                          QStringList() << "Individuel" << "Patrouille" << "Kayak Cross (Time Trial)");
    dialogBox->onButtonClicked([this, dialogBox](int index) {
        setCompetitionMode(index);
        QString modeText;
        switch(index) {
            case 0: modeText = "Individuel"; break;
            case 1: modeText = "Patrouille"; break;
            case 2: modeText = "Kayak Cross (Time Trial)"; break;
        }
        toast(QString("Mode de compétition configuré : %0").arg(modeText), 3000);
        dialogBox->deleteLater();
    });
    
    openDialogBox(dialogBox);
}

void ViewController::setKayakCrossPostCount(int postCount) {
    // Validation : entre 1 et 9 postes
    if (postCount < 1) postCount = 1;
    if (postCount > 9) postCount = 9;
    
    if (_kayakCrossPostCount != postCount) {
        _kayakCrossPostCount = postCount;
        QSettings settings;
        settings.setValue("kayakCrossPostCount", _kayakCrossPostCount);
        emit kayakCrossPostCountChanged(_kayakCrossPostCount);
    }
}

void ViewController::setKayakCrossPostTypes(QStringList postTypes) {
    // Validation des contraintes pour Kayak Cross Time Trial
    int esquimautageCount = postTypes.count("Esquimautage");
    int porteRemonteeCount = postTypes.count("Porte remontée");
    int porteDescendueCount = postTypes.count("Porte descendue");
    
    // Validation : 0 ou 1 esquimautage (pas obligatoire)
    if (esquimautageCount > 1) {
        toast("Erreur : Il ne peut y avoir qu'1 seul esquimautage maximum", 5000);
        return;
    }
    
    // Validation : 4-6 portes descendues
    if (porteDescendueCount < 4 || porteDescendueCount > 6) {
        toast("Erreur : Il doit y avoir entre 4 et 6 portes descendues", 5000);
        return;
    }
    
    // Validation : 0-2 portes remontées
    if (porteRemonteeCount > 2) {
        toast("Erreur : Il ne peut y avoir que 0 à 2 portes remontées", 5000);
        return;
    }
    
    // Validation : total entre 4 et 9 postes
    int totalPosts = postTypes.count();
    if (totalPosts < 4 || totalPosts > 9) {
        toast("Erreur : Le total doit être entre 4 et 9 postes", 5000);
        return;
    }
    
    // L'esquimautage peut être placé n'importe où dans le parcours
    
    if (_kayakCrossPostTypes != postTypes) {
        _kayakCrossPostTypes = postTypes;
        QSettings settings;
        settings.setValue("kayakCrossPostTypes", _kayakCrossPostTypes);
        emit kayakCrossPostTypesChanged(_kayakCrossPostTypes);
        
        // Mettre à jour le nombre de postes automatiquement
        setKayakCrossPostCount(totalPosts);
        
        // Message de confirmation
        QString configText = QString("Configuration Kayak Cross appliquée : %0 postes")
                            .arg(totalPosts);
        toast(configText, 2000);
    }
}

void ViewController::configureKayakCrossPosts() {
    DialogBox* dialogBox = new DialogBox("Configurer les postes Kayak Cross",
                                          "Sélectionnez le type de configuration :",
                                          DIALOGBOX_QUESTION,
                                          QStringList() << "Configuration simple (nombre de postes)" 
                                                       << "Configuration avancée (types de postes)");
    dialogBox->onButtonClicked([this, dialogBox](int index) {
        if (index == 0) {
            // Configuration simple - nombre de postes
            configureKayakCrossPostCount();
        } else {
            // Configuration avancée - types de postes
            configureKayakCrossPostTypes();
        }
        dialogBox->deleteLater();
    });
    
    openDialogBox(dialogBox);
}

void ViewController::configureKayakCrossPostCount() {
    DialogBox* dialogBox = new DialogBox("Configurer le nombre de postes",
                                          "Sélectionnez le nombre de postes (4-9) :",
                                          DIALOGBOX_QUESTION,
                                          QStringList() << "4" << "5" << "6" << "7" << "8" << "9");
    dialogBox->onButtonClicked([this, dialogBox](int index) {
        int postCount = index + 4; // 4-9 postes
        setKayakCrossPostCount(postCount);
        toast(QString("Nombre de postes configuré : %0").arg(postCount), 3000);
        dialogBox->deleteLater();
    });
    
    openDialogBox(dialogBox);
}

void ViewController::configureKayakCrossPostTypes() {
    DialogBox* dialogBox = new DialogBox("Configurer les types de postes",
                                          "Configuration des postes Kayak Cross Time Trial :\n\n"
                                          "• 4-6 Portes descendues (obligatoires)\n"
                                          "• 0-2 Portes remontées (optionnelles)\n"
                                          "• 1 Esquimautage (obligatoire)\n\n"
                                          "Total : 5-9 postes",
                                          DIALOGBOX_QUESTION,
                                          QStringList() << "Configuration automatique (5 postes minimum)"
                                                       << "Configuration manuelle (types détaillés)");
    dialogBox->onButtonClicked([this, dialogBox](int index) {
        if (index == 0) {
            // Configuration automatique - 5 postes minimum
            configureKayakCrossAuto();
        } else {
            // Configuration manuelle - types détaillés
            configureKayakCrossManual();
        }
        dialogBox->deleteLater();
    });
    
    openDialogBox(dialogBox);
}

void ViewController::configureKayakCrossAuto() {
    // Configuration automatique : 4 descendues (minimum)
    QStringList autoConfig;
    for (int i = 0; i < 4; i++) {
        autoConfig << "Porte descendue";
    }
    
    setKayakCrossPostTypes(autoConfig);
    setKayakCrossPostCount(4);
    toast("Configuration automatique : 4 portes descendues (minimum)", 3000);
}

void ViewController::configureKayakCrossManual() {
    // Configuration manuelle - interface pour sélectionner les types
    DialogBox* dialogBox = new DialogBox("Configuration manuelle des postes",
                                          "Sélectionnez le nombre de portes descendues (4-6) :",
                                          DIALOGBOX_QUESTION,
                                          QStringList() << "4 portes descendues" 
                                                       << "5 portes descendues" 
                                                       << "6 portes descendues");
    dialogBox->onButtonClicked([this, dialogBox](int index) {
        int descendues = index + 4; // 4-6
        configureKayakCrossRemontees(descendues);
        dialogBox->deleteLater();
    });
    
    openDialogBox(dialogBox);
}

void ViewController::configureKayakCrossRemontees(int descendues) {
    DialogBox* dialogBox = new DialogBox("Configuration des portes remontées",
                                          QString("Vous avez %0 portes descendues.\n\n"
                                                 "Sélectionnez le nombre de portes remontées (0-2) :").arg(descendues),
                                          DIALOGBOX_QUESTION,
                                          QStringList() << "0 porte remontée" 
                                                       << "1 porte remontée" 
                                                       << "2 portes remontées");
    dialogBox->onButtonClicked([this, dialogBox, descendues](int index) {
        int remontees = index; // 0-2
        configureKayakCrossFinal(descendues, remontees);
        dialogBox->deleteLater();
    });
    
    openDialogBox(dialogBox);
}

void ViewController::configureKayakCrossFinal(int descendues, int remontees) {
    // Construction de la configuration finale
    QStringList finalConfig;
    
    // Ajouter les portes descendues
    for (int i = 0; i < descendues; i++) {
        finalConfig << "Porte descendue";
    }
    
    // Ajouter les portes remontées
    for (int i = 0; i < remontees; i++) {
        finalConfig << "Porte remontée";
    }
    
    // Valider et appliquer la configuration
    int totalPosts = descendues + remontees; // Pas d'esquimautage obligatoire
    
    if (totalPosts < 4 || totalPosts > 9) {
        toast("Erreur : Configuration invalide (total doit être entre 4 et 9)", 5000);
        return;
    }
    
    setKayakCrossPostTypes(finalConfig);
    setKayakCrossPostCount(totalPosts);
    
    QString configText = QString("Configuration : %0 descendues, %1 remontées")
                        .arg(descendues).arg(remontees);
    toast(configText, 3000);
}

void ViewController::openKayakCrossPostConfig() {
    // Cette méthode sera utilisée pour ouvrir le dialog de configuration avancée
    // depuis l'interface QML
    configureKayakCrossPostTypes();
}

void ViewController::tcpServerStarFailure() {

    DialogBox* dialogBox = new DialogBox("Erreur fatale de démarrage du serveur",
                                         QString("TRAPS Manager n'arrive pas à démarrer son serveur sur\n%0:%1\nUne autre application utilise sans doute ce même port.\nL'application va se fermer.").arg(_selectedHost).arg(_requestedTcpPort),
                                         DIALOGBOX_ALERT, DIALOGBOX_OK);
    dialogBox->onAccepted([this, dialogBox](){
        dialogBox->deleteLater();
        emit this->quit();
    });

    openDialogBox(dialogBox);

}

void ViewController::refreshStatusText() {
    if (_hostList.count()==0) _statusText = "Aucun réseau disponible. Redémarrez l'application.";
    else _statusText = QString("En écoute des TRAPS sur %1:%2").arg(_selectedHost).arg(_runningTcpPort);
    emit statusTextChanged(_statusText);
}
