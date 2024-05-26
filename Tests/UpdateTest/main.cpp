#include <QCoreApplication>
#include <QDebug>
#include <QProcess>
#include <QTimer>
#include "httpjsonclient.h"
#include "jsonnetworkmanager.h".h"
#include "jsonnetworkreply.h"
#include <QJsonObject>

void todo() {
    exit(0);
}

int main(int argc, char *argv[])
{
    QCoreApplication a(argc, argv);
    qDebug() << "Let's RUN !";

//    QProcess* process = new QProcess();
//    process->start("/Applications/TRAPSManager.app");

//    QTimer::singleShot(5000, todo);

//    HttpJsonClient jsonClient;

//    QObject::connect(&jsonClient, &HttpJsonClient::error, [](int errorCode, QString errorString){
//        qDebug() << "Error " << errorCode << ": " << errorString;
//    });

//    QObject::connect(&jsonClient, &HttpJsonClient::result, [](QJsonDocument jsonDoc){
//        qDebug() << "Json doc: " << jsonDoc.toJson(QJsonDocument::Compact);
//    });

//    jsonClient.getRequest(QUrl("http://www.traps-ck.com/update/trapsmanager.json"));

    JsonNetworkManager networkManager;
    networkManager.getJson(QUrl("http://www.traps-ck.com/update/trapsmanager.json"))
    ->onResult([](QJsonDocument jsonDoc) {
       QJsonObject obj = jsonDoc.object();
       qDebug() << "Version: " << obj.value("version").toString();
       qDebug() << "What's new: " << obj.value("whatsnew").toString();
       qDebug() << "Seconds since epoch: " << obj.value("elapsedSecondsSinceEpoch").toInt();
    })
    ->onError([](int code, QString str) {
        qWarning() << "Error " << code << ":" << str;
    });


    return a.exec();
}
