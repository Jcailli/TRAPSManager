#include "patrol.h"
#include <QDebug>
#include <QJsonObject>
#include <QJsonArray>
#include <QDateTime>

Patrol::Patrol(int patrolNumber) :
    _patrolNumber(patrolNumber),
    _locked(false)
{
    buildPatrolId();
}

void Patrol::buildPatrolId() {
    _patrolId = QString("Patrouille %0").arg(_patrolNumber);
}

void Patrol::addBib(Bib* bib) {
    if (_bibs.count() < 3 && bib) {
        _bibs.append(bib);
        qDebug() << "Added bib" << bib->id() << "to" << _patrolId;
    }
}

Bib* Patrol::bibAt(int index) const {
    if (index >= 0 && index < _bibs.count()) {
        return _bibs.at(index);
    }
    return nullptr;
}

qint64 Patrol::startTime() const {
    if (_bibs.isEmpty()) return 0;
    
    // Le temps de départ est celui du premier coureur
    qint64 earliestStart = -1;
    foreach (Bib* bib, _bibs) {
        if (bib && bib->startTime() > 0) {
            if (earliestStart == -1 || bib->startTime() < earliestStart) {
                earliestStart = bib->startTime();
            }
        }
    }
    return earliestStart;
}

qint64 Patrol::finishTime() const {
    if (_bibs.isEmpty()) return 0;
    
    // Le temps d'arrivée est celui du dernier coureur
    qint64 latestFinish = 0;
    foreach (Bib* bib, _bibs) {
        if (bib && bib->finishTime() > 0) {
            if (bib->finishTime() > latestFinish) {
                latestFinish = bib->finishTime();
            }
        }
    }
    return latestFinish;
}

qint64 Patrol::runningTime() const {
    qint64 start = startTime();
    qint64 finish = finishTime();
    
    if (start > 0 && finish > 0) {
        return finish - start;
    }
    return 0;
}

int Patrol::gapPenalty() const {
    return hasGapPenalty() ? 50 : 0;
}

bool Patrol::isComplete() const {
    return _bibs.count() == 3;
}

int Patrol::timeGap() const {
    if (_bibs.count() < 2) return 0;
    
    qint64 earliestFinish = -1;
    qint64 latestFinish = 0;
    
    foreach (Bib* bib, _bibs) {
        if (bib && bib->finishTime() > 0) {
            if (earliestFinish == -1 || bib->finishTime() < earliestFinish) {
                earliestFinish = bib->finishTime();
            }
            if (bib->finishTime() > latestFinish) {
                latestFinish = bib->finishTime();
            }
        }
    }
    
    if (earliestFinish > 0 && latestFinish > 0) {
        return (latestFinish - earliestFinish) / 1000; // Convertir en secondes
    }
    return 0;
}

bool Patrol::hasGapPenalty() const {
    return timeGap() > 15;
}

int Patrol::totalPenaltyAtGate(int gateId) const {
    int total = 0;
    foreach (Bib* bib, _bibs) {
        if (bib) {
            Penalty penalty = bib->penaltyAtGate(gateId);
            if (penalty.value() >= 0) {
                total += penalty.value();
            }
        }
    }
    return total;
}

QHash<int, int> Patrol::totalPenalties() const {
    QHash<int, int> totalPenalties;
    
    // Pour chaque porte, calculer la somme des pénalités
    for (int gate = 1; gate <= 25; gate++) { // Utiliser le nombre de portes configuré
        int total = totalPenaltyAtGate(gate);
        if (total > 0) {
            totalPenalties.insert(gate, total);
        }
    }
    
    return totalPenalties;
}

bool Patrol::locked() const {
    return _locked;
}

void Patrol::setLocked(bool locked) {
    _locked = locked;
}

QJsonObject Patrol::jsonObject() const {
    QJsonObject obj;
    obj.insert("patrolNumber", _patrolNumber);
    obj.insert("patrolId", _patrolId);
    obj.insert("locked", _locked);
    obj.insert("bibCount", _bibs.count());
    
    QJsonArray bibArray;
    foreach (Bib* bib, _bibs) {
        if (bib) {
            bibArray.append(bib->id());
        }
    }
    obj.insert("bibs", bibArray);
    
    return obj;
}
