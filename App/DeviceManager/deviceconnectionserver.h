#ifndef DEVICECONNECTIONSERVER_H
#define DEVICECONNECTIONSERVER_H

#include <QObject>
#include <QTcpServer>
#include <QTcpSocket>
#include <QTimer>
#include <QJsonObject>
#include <QJsonDocument>
#include <QJsonArray>
#include <QHash>
#include <QDateTime>
#include <QVariantList>
#include "deviceallowlist.h"

struct DeviceConnection {
    QString deviceId;
    QString deviceName;
    QString version;
    QString mac;
    QString ipAddress;
    QStringList capabilities;
    QTcpSocket* socket;
    QDateTime lastHeartbeat;
    QDateTime connectedSince;
    bool isActive;
};

class DeviceConnectionServer : public QObject
{
    Q_OBJECT
    Q_PROPERTY(int connectedDeviceCount READ connectedDeviceCount NOTIFY connectedDeviceCountChanged)
    Q_PROPERTY(int activeDeviceCount READ activeDeviceCount NOTIFY connectedDeviceCountChanged)
    Q_PROPERTY(bool listening READ isListening NOTIFY listeningChanged)
    Q_PROPERTY(int serverPort READ serverPort NOTIFY listeningChanged)
    Q_PROPERTY(QVariantList connectedDevices READ connectedDevices NOTIFY connectedDevicesChanged)
    Q_PROPERTY(DeviceAllowlist* allowlist READ allowlist CONSTANT)

public:
    explicit DeviceConnectionServer(QObject *parent = nullptr);
    ~DeviceConnectionServer();

    bool startServer(int port = 8081);
    void stopServer();
    bool isListening() const;
    int serverPort() const;
    int connectedDeviceCount() const;
    int activeDeviceCount() const;
    QVariantList connectedDevices() const;
    DeviceAllowlist* allowlist() const;

public slots:
    void sendCommandToDevice(const QString &deviceId, const QString &command, const QJsonObject &parameters = QJsonObject());
    void broadcastCommand(const QString &command, const QJsonObject &parameters = QJsonObject());
    void broadcastBibList(const QJsonArray &bibs);
    void sendBibListToDevice(const QString &deviceId, const QJsonArray &bibs);
    void disconnectDevice(const QString &deviceId);

signals:
    void deviceConnected(const QString &deviceId, const QString &deviceName);
    void deviceDisconnected(const QString &deviceId, const QString &deviceName);
    void deviceRejected(const QString &identifier, const QString &reason);
    void deviceHeartbeat(const QString &deviceId);
    void commandReceived(const QString &deviceId, const QString &command, const QJsonObject &parameters);
    void connectedDeviceCountChanged();
    void connectedDevicesChanged();
    void listeningChanged();
    void toast(QString text, int delay);

private slots:
    void onNewConnection();
    void onSocketReadyRead();
    void onSocketDisconnected();
    void onHeartbeatTimeout();

private:
    QTcpServer* _tcpServer;
    QHash<QString, DeviceConnection> _connections;
    QHash<QTcpSocket*, QString> _socketToDeviceId;
    QHash<QTcpSocket*, QByteArray> _socketBuffers;
    QTimer* _heartbeatTimer;
    QVariantList _connectedDevicesList;
    int _serverPort;
    DeviceAllowlist* _allowlist;

    void processMessage(QTcpSocket* socket, const QJsonObject &message);
    void handleRegister(QTcpSocket* socket, const QJsonObject &json);
    void sendMessage(QTcpSocket* socket, const QJsonObject &message);
    void sendMessage(const QString &deviceId, const QJsonObject &message);
    void updateConnectedDevicesList();
    void rejectSocket(QTcpSocket* socket, const QString &identifier, const QString &reason);
    QString connectionStatus(const DeviceConnection &connection) const;
};

#endif // DEVICECONNECTIONSERVER_H
