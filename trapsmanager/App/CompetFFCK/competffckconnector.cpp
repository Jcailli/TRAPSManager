#include "competffckconnector.h"
#include <QThread>
#include <QElapsedTimer>
#include <QJsonObject>
#include <QDebug>

CompetFFCKConnector::CompetFFCKConnector(QObject *parent) : QObject(parent),
    _socket(0),
    _connected(false)
{


}


void CompetFFCKConnector::connectToServer(const QString& host, int port) {
    qDebug() << "Connecting to " << host << ", port " << port;
    _socket = new QTcpSocket(this);
    connect(_socket, SIGNAL(error(QAbstractSocket::SocketError)), this, SLOT(errorHandler(QAbstractSocket::SocketError)));
    _socket->connectToHost(host, port);
    if (!_socket->waitForConnected(5000)) {
        qCritical() << "Cannot connect to CompetFFCK !";
        emit connectedToServer(false);
        emit error("Problème de connexion CompetFFCK", QString("Impossible de se connecter à CompetFFCK sur\n%0:%1").arg(host).arg(port));
        _socket->deleteLater();
        _socket = 0;
        return;
    }
    _connected = true;
    emit connectedToServer(true);

}

void CompetFFCKConnector::disconnectFromServer() {
    if (_connected) {
        _socket->close();
        _socket->deleteLater();
        _socket = 0;
        _connected = false;
    }
    emit connectedToServer(false);

}

void CompetFFCKConnector::errorHandler(QAbstractSocket::SocketError socketError) {
    qDebug() << "Handling socket error";
    qDebug() << _socket->errorString();
    emit error("Problème de connexion CompetFFCK", QString("%1 (%0)").arg(socketError).arg(_socket->errorString()));
    emit connectedToServer(false);
    _socket->close();
    _socket->deleteLater();
    _socket = 0;
    _connected = false;
}

void CompetFFCKConnector::sendPenalty(int bib, int gateId, int boat, int penalty) {

    if (!_connected || !_socket) {
        qWarning() << "Cannot send penalty because not connected to competFFCK";
        return;
    }

    if (boat < 1)
        boat = 1;

    QByteArray byteArray;
    byteArray.append("penalty ");
    byteArray.append(QString::number(bib).toLocal8Bit());
    byteArray.append(' ');
    byteArray.append(QString::number(gateId).toLocal8Bit());
    byteArray.append(' ');
    byteArray.append(QString::number(boat).toLocal8Bit());
    byteArray.append(' ');
    byteArray.append(QString::number(penalty).toLocal8Bit());
    byteArray.append('\r');

    qint64 num = _socket->write(byteArray);
    _socket->flush();
    if (num!=byteArray.size()) {
        qCritical() << "Disconnect. Error while sending penalty over the network. num=" << num;
        _socket->close();
        _socket->deleteLater();
        _socket = 0;
        _connected = false;
        emit connectedToServer(_connected);
        emit error("Problème de connexion CompetFFCK", "Impossible d'envoyer la pénalité à CompetFFCK");
        return;
    }
    emit penaltySent();
    // QThread::msleep(250); // Add this tempo if it is too fast for competFFCK

}

void CompetFFCKConnector::sendTime(int bib, int chrono) {
    if (!_connected || !_socket) {
        qWarning() << "Cannot send chrono because not connected to competFFCK";
        return;
    }

    QByteArray byteArray;
    byteArray.append("chrono ");
    byteArray.append(QString::number(bib).toLocal8Bit());
    byteArray.append(' ');
    byteArray.append(QString::number(chrono).toLocal8Bit());
    byteArray.append('\r');

    qint64 num = _socket->write(byteArray);
    _socket->flush();
    if (num!=byteArray.size()) {
        qCritical() << "Disconnect. Error while sending chrono over the network. num=" << num;
        _socket->close();
        _socket->deleteLater();
        _socket = 0;
        _connected = false;
        emit connectedToServer(_connected);
        emit error("Problème de connexion CompetFFCK", "Impossible d'envoyer le temps à CompetFFCK");
        return;
    }
    // QThread::msleep(250); // Add this tempo if it is too fast for competFFCK

}

void CompetFFCKConnector::requestBibList() {
    if (!_connected || !_socket) {
        emit error("Chargement dossards CompetFFCK", "Non connecté à CompetFFCK");
        return;
    }

    QByteArray request("list\r");
    qint64 num = _socket->write(request);
    _socket->flush();
    if (num != request.size()) {
        emit error("Chargement dossards CompetFFCK", "Impossible d'envoyer la demande de liste");
        return;
    }

    QJsonArray bibs;
    int gateCount = 0;
    QByteArray buffer;
    QElapsedTimer timer;
    timer.start();
    const int timeoutMs = 15000;

    while (timer.elapsed() < timeoutMs) {
        if (!_socket->isOpen()) {
            emit error("Chargement dossards CompetFFCK", "Connexion perdue pendant le chargement");
            return;
        }

        if (_socket->bytesAvailable() > 0 || _socket->waitForReadyRead(500)) {
            buffer.append(_socket->readAll());

            while (true) {
                int cr = buffer.indexOf('\r');
                int lf = buffer.indexOf('\n');
                int idx = -1;
                if (cr >= 0 && lf >= 0) idx = qMin(cr, lf);
                else if (cr >= 0) idx = cr;
                else if (lf >= 0) idx = lf;
                else break;

                QByteArray rawLine = buffer.left(idx);
                buffer.remove(0, idx + 1);
                QString line = QString::fromLocal8Bit(rawLine).trimmed();
                if (line.isEmpty()) continue;

                QStringList parts = line.split(' ', QString::SkipEmptyParts);
                if (parts.isEmpty()) continue;

                if (parts[0] == "list_end") {
                    qDebug() << "CompetFFCK bib list received:" << bibs.size()
                             << "gates:" << gateCount;
                    if (gateCount > 0)
                        emit gateCountReceived(gateCount);
                    emit bibListReceived(bibs);
                    return;
                }
                if (parts[0] == "list_error") {
                    QString detail = parts.size() > 1 ? parts.mid(1).join(' ') : "erreur inconnue";
                    emit error("Chargement dossards CompetFFCK",
                               QString("CompetFFCK n'a pas pu fournir la liste:\n%0").arg(detail));
                    return;
                }
                if (parts[0] == "gates" && parts.size() >= 2) {
                    bool ok = false;
                    int n = parts[1].toInt(&ok);
                    if (ok && n > 0)
                        gateCount = n;
                    continue;
                }
                if (parts[0] == "bib" && parts.size() >= 2) {
                    bool ok = false;
                    int bibNumber = parts[1].toInt(&ok);
                    if (!ok || bibNumber < 1) continue;

                    QJsonObject obj;
                    obj.insert("bib", bibNumber);
                    obj.insert("categ", parts.size() > 2 ? parts[2] : QString("-"));
                    obj.insert("schedule", parts.size() > 3 ? parts[3] : QString("-"));
                    bibs.append(obj);
                }
            }
        }
    }

    emit error("Chargement dossards CompetFFCK",
               "Délai dépassé en attendant la liste.\nVérifiez que la fenêtre de gestion CompetFFCK est ouverte\net que traps.lua est à jour (commande list).");
}
