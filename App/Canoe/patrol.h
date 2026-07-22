#ifndef PATROL_H
#define PATROL_H

#include "bib.h"
#include <QList>
#include <QString>

class Patrol
{
public:
    explicit Patrol(int patrolNumber);
    
    int patrolNumber() const { return _patrolNumber; }
    QString patrolId() const { return _patrolId; }
    
    // Gestion des coureurs (3 maximum)
    void addBib(Bib* bib);
    QList<Bib*> bibs() const { return _bibs; }
    Bib* bibAt(int index) const;
    int bibCount() const { return _bibs.count(); }
    
    // Gestion des temps de patrouille
    qint64 startTime() const; // Temps de départ du premier coureur
    qint64 finishTime() const; // Temps d'arrivée du troisième coureur
    qint64 runningTime() const; // Temps entre départ 1er et arrivée 3ème
    int gapPenalty() const; // Pénalité d'écart (50s si > 15s entre 1er et 3ème)
    
    // Calculs spécifiques aux patrouilles
    bool isComplete() const; // Patrouille complète (3 coureurs)
    int timeGap() const; // Écart en secondes entre 1er et 3ème
    bool hasGapPenalty() const; // Écart > 15 secondes
    
    // Pénalités par porte (somme des pénalités des 3 coureurs)
    int totalPenaltyAtGate(int gateId) const;
    QHash<int, int> totalPenalties() const;
    
    // Statut
    bool locked() const;
    void setLocked(bool locked);
    
    // JSON pour sauvegarde
    QJsonObject jsonObject() const;
    
private:
    int _patrolNumber;
    QString _patrolId;
    QList<Bib*> _bibs;
    bool _locked;
    
    void buildPatrolId();
};

#endif // PATROL_H
