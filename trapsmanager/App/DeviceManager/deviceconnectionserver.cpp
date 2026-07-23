#include "deviceconnectionserver.h"
#include <QDebug>
#include <QJsonParseError>
#include <QHostAddress>

#define HEARTBEAT_INTERVAL 10000 // 10 seconds check
#define HEARTBEAT_TIMEOUT 45000  // 45 seconds without heartbeat = lost
#define IDLE_THRESHOLD 20000     // 20 seconds = idle (orange)

DeviceConnectionServer::DeviceConnectionServer(QObject *parent) : QObject(parent)
{
    _tcpServer = new QTcpServer(this);
    _heartbeatTimer = new QTimer(this);
    _allowlist = new DeviceAllowlist(this);
    _serverPort = 8081;

    connect(_tcpServer, &QTcpServer::newConnection, this, &DeviceConnectionServer::onNewConnection);
    connect(_heartbeatTimer, &QTimer::timeout, this, &DeviceConnectionServer::onHeartbeatTimeout);

    _heartbeatTimer->start(HEARTBEAT_INTERVAL);
    qDebug() << "DeviceConnectionServer initialized";
}

DeviceConnectionServer::~DeviceConnectionServer()
{
    stopServer();
}

bool DeviceConnectionServer::startServer(int port)
{
    _serverPort = port;

    if (_tcpServer->isListening()) {
        if (_tcpServer->serverPort() == static_cast<quint16>(_serverPort))
            return true;
        _tcpServer->close();
    }

    if (!_tcpServer->listen(QHostAddress::Any, _serverPort)) {
        qCritical() << "Failed to start device connection server on port" << _serverPort
                     << ":" << _tcpServer->errorString();
        emit listeningChanged();
        return false;
    }

    qInfo() << "Device connection server started on port" << _serverPort;
    emit listeningChanged();
    return true;
}

void DeviceConnectionServer::stopServer()
{
    if (_tcpServer->isListening()) {
        _tcpServer->close();
        qInfo() << "Device connection server stopped";
    }

    for (auto it = _connections.begin(); it != _connections.end(); ++it) {
        if (it.value().socket)
            it.value().socket->disconnectFromHost();
    }
    _connections.clear();
    _socketToDeviceId.clear();
    _socketBuffers.clear();
    updateConnectedDevicesList();
    emit listeningChanged();
}

bool DeviceConnectionServer::isListening() const
{
    return _tcpServer && _tcpServer->isListening();
}

int DeviceConnectionServer::serverPort() const
{
    return _serverPort;
}

int DeviceConnectionServer::connectedDeviceCount() const
{
    return _connections.count();
}

int DeviceConnectionServer::activeDeviceCount() const
{
    int count = 0;
    for (auto it = _connections.constBegin(); it != _connections.constEnd(); ++it) {
        if (connectionStatus(it.value()) == QLatin1String("Active"))
            ++count;
    }
    return count;
}

QVariantList DeviceConnectionServer::connectedDevices() const
{
    return _connectedDevicesList;
}

DeviceAllowlist* DeviceConnectionServer::allowlist() const
{
    return _allowlist;
}

void DeviceConnectionServer::sendCommandToDevice(const QString &deviceId, const QString &command, const QJsonObject &parameters)
{
    if (!_connections.contains(deviceId)) {
        qWarning() << "Device not found:" << deviceId;
        return;
    }

    QJsonObject message;
    message["type"] = "command";
    message["command"] = command;
    message["parameters"] = parameters;
    message["timestamp"] = QDateTime::currentMSecsSinceEpoch();
    sendMessage(deviceId, message);
}

void DeviceConnectionServer::broadcastCommand(const QString &command, const QJsonObject &parameters)
{
    QJsonObject message;
    message["type"] = "command";
    message["command"] = command;
    message["parameters"] = parameters;
    message["timestamp"] = QDateTime::currentMSecsSinceEpoch();

    for (auto it = _connections.begin(); it != _connections.end(); ++it)
        sendMessage(it.key(), message);

    emit toast(QString("Commande « %1 » envoyée à %2 appareil(s)")
               .arg(command).arg(_connections.count()), 3000);
}

void DeviceConnectionServer::broadcastBibList(const QJsonArray &bibs)
{
    QJsonObject parameters;
    parameters["bibs"] = bibs;
    parameters["count"] = bibs.size();

    QJsonObject message;
    message["type"] = "command";
    message["command"] = "loadBibList";
    message["parameters"] = parameters;
    message["timestamp"] = QDateTime::currentMSecsSinceEpoch();

    for (auto it = _connections.begin(); it != _connections.end(); ++it)
        sendMessage(it.key(), message);

    emit toast(QString("Liste de %1 dossards envoyée à %2 appareil(s)")
               .arg(bibs.size()).arg(_connections.count()), 4000);
}

void DeviceConnectionServer::sendBibListToDevice(const QString &deviceId, const QJsonArray &bibs)
{
    QJsonObject parameters;
    parameters["bibs"] = bibs;
    parameters["count"] = bibs.size();
    sendCommandToDevice(deviceId, "loadBibList", parameters);
}

void DeviceConnectionServer::disconnectDevice(const QString &deviceId)
{
    if (!_connections.contains(deviceId))
        return;

    DeviceConnection &connection = _connections[deviceId];
    if (connection.socket)
        connection.socket->disconnectFromHost();
}

void DeviceConnectionServer::onNewConnection()
{
    while (_tcpServer->hasPendingConnections()) {
        QTcpSocket* socket = _tcpServer->nextPendingConnection();
        qInfo() << "New device socket from"
                << DeviceAllowlist::normalizeIp(socket->peerAddress().toString())
                << ":" << socket->peerPort();

        connect(socket, &QTcpSocket::readyRead, this, &DeviceConnectionServer::onSocketReadyRead);
        connect(socket, &QTcpSocket::disconnected, this, &DeviceConnectionServer::onSocketDisconnected);
        _socketBuffers[socket] = QByteArray();
    }
}

void DeviceConnectionServer::onSocketReadyRead()
{
    QTcpSocket* socket = qobject_cast<QTcpSocket*>(sender());
    if (!socket)
        return;

    _socketBuffers[socket].append(socket->readAll());

    while (true) {
        int nl = _socketBuffers[socket].indexOf('\n');
        if (nl < 0)
            break;

        QByteArray line = _socketBuffers[socket].left(nl).trimmed();
        _socketBuffers[socket].remove(0, nl + 1);
        if (line.isEmpty())
            continue;

        QJsonParseError error;
        QJsonDocument doc = QJsonDocument::fromJson(line, &error);
        if (error.error != QJsonParseError::NoError || !doc.isObject()) {
            qWarning() << "JSON parse error:" << error.errorString() << line;
            continue;
        }
        processMessage(socket, doc.object());
    }
}

void DeviceConnectionServer::processMessage(QTcpSocket* socket, const QJsonObject &message)
{
    const QString messageType = message.value("type").toString();

    if (messageType == "register") {
        handleRegister(socket, message);
        return;
    }

    const QString deviceId = _socketToDeviceId.value(socket);
    if (deviceId.isEmpty()) {
        // Première chose attendue : register
        rejectSocket(socket, DeviceAllowlist::normalizeIp(socket->peerAddress().toString()),
                     "register_required");
        return;
    }

    if (!_connections.contains(deviceId))
        return;

    if (messageType == "heartbeat") {
        _connections[deviceId].lastHeartbeat = QDateTime::currentDateTime();
        _connections[deviceId].isActive = true;
        emit deviceHeartbeat(deviceId);
        updateConnectedDevicesList();

        QJsonObject pong;
        pong["type"] = "heartbeat_ack";
        pong["serverTime"] = QDateTime::currentMSecsSinceEpoch();
        sendMessage(socket, pong);
        return;
    }

    if (messageType == "command_response") {
        emit commandReceived(deviceId,
                             message.value("command").toString(),
                             message.value("parameters").toObject());
    }
}

void DeviceConnectionServer::handleRegister(QTcpSocket* socket, const QJsonObject &json)
{
    QString deviceId = json.value("deviceId").toString().trimmed();
    QString deviceName = json.value("deviceName").toString().trimmed();
    QString version = json.value("version").toString().trimmed();
    QString mac = DeviceAllowlist::normalizeMac(json.value("mac").toString());
    QString ip = DeviceAllowlist::normalizeIp(socket->peerAddress().toString());

    // IP optionnelle aussi dans le JSON
    if (!json.value("ip").toString().isEmpty())
        ip = DeviceAllowlist::normalizeIp(json.value("ip").toString());

    if (deviceId.isEmpty())
        deviceId = mac.isEmpty() ? ip : mac;
    if (deviceName.isEmpty())
        deviceName = deviceId;

    QStringList capabilities;
    const QJsonArray capsArray = json.value("capabilities").toArray();
    for (const QJsonValue &cap : capsArray)
        capabilities << cap.toString();

    const QString identifier = !mac.isEmpty() ? mac : (!ip.isEmpty() ? ip : deviceId);

    if (!_allowlist->isAuthorized(mac, ip, deviceId)) {
        rejectSocket(socket, identifier, "not_authorized");
        return;
    }

    // Remplace une éventuelle ancienne session du même deviceId
    if (_connections.contains(deviceId)) {
        QTcpSocket* oldSocket = _connections[deviceId].socket;
        if (oldSocket && oldSocket != socket) {
            _socketToDeviceId.remove(oldSocket);
            _socketBuffers.remove(oldSocket);
            oldSocket->disconnectFromHost();
        }
    }

    DeviceConnection connection;
    connection.deviceId = deviceId;
    connection.deviceName = deviceName;
    connection.version = version;
    connection.mac = mac;
    connection.ipAddress = ip;
    connection.capabilities = capabilities;
    connection.socket = socket;
    connection.lastHeartbeat = QDateTime::currentDateTime();
    connection.connectedSince = QDateTime::currentDateTime();
    connection.isActive = true;

    _connections[deviceId] = connection;
    _socketToDeviceId[socket] = deviceId;

    QJsonObject response;
    response["type"] = "registered";
    response["deviceId"] = deviceId;
    response["serverTime"] = QDateTime::currentMSecsSinceEpoch();
    sendMessage(socket, response);

    qInfo() << "Device authorized:" << deviceId << deviceName << mac << ip;
    emit deviceConnected(deviceId, deviceName);
    emit toast(QString("Appareil connecté : %1").arg(deviceName), 3000);
    updateConnectedDevicesList();
}

void DeviceConnectionServer::rejectSocket(QTcpSocket* socket, const QString &identifier, const QString &reason)
{
    QJsonObject response;
    response["type"] = "rejected";
    response["reason"] = reason;
    response["message"] = QStringLiteral("Appareil non autorisé. Ajoutez-le dans TRAPSManager (MAC/IP).");
    sendMessage(socket, response);

    qWarning() << "Device rejected:" << identifier << reason;
    emit deviceRejected(identifier, reason);
    emit toast(QString("Connexion refusée : %1").arg(identifier), 4000);

    socket->disconnectFromHost();
}

void DeviceConnectionServer::onSocketDisconnected()
{
    QTcpSocket* socket = qobject_cast<QTcpSocket*>(sender());
    if (!socket)
        return;

    const QString deviceId = _socketToDeviceId.value(socket);
    QString deviceName = deviceId;
    if (!deviceId.isEmpty() && _connections.contains(deviceId)) {
        deviceName = _connections[deviceId].deviceName;
        _connections.remove(deviceId);
        emit deviceDisconnected(deviceId, deviceName);
        emit toast(QString("Appareil déconnecté : %1").arg(deviceName), 3000);
        updateConnectedDevicesList();
    }

    _socketToDeviceId.remove(socket);
    _socketBuffers.remove(socket);
    socket->deleteLater();
}

void DeviceConnectionServer::onHeartbeatTimeout()
{
    const QDateTime now = QDateTime::currentDateTime();
    QStringList devicesToRemove;

    for (auto it = _connections.begin(); it != _connections.end(); ++it) {
        const qint64 elapsed = it.value().lastHeartbeat.msecsTo(now);
        if (elapsed > HEARTBEAT_TIMEOUT)
            devicesToRemove << it.key();
    }

    for (const QString &deviceId : devicesToRemove) {
        if (!_connections.contains(deviceId))
            continue;
        DeviceConnection connection = _connections[deviceId];
        qWarning() << "Device heartbeat timeout:" << deviceId;
        if (connection.socket)
            connection.socket->disconnectFromHost();
        else {
            _connections.remove(deviceId);
            emit deviceDisconnected(deviceId, connection.deviceName);
            emit toast(QString("Liaison perdue : %1").arg(connection.deviceName), 4000);
        }
    }

    // Rafraîchir les statuts Active/Idle même sans déconnexion
    updateConnectedDevicesList();
}

void DeviceConnectionServer::sendMessage(QTcpSocket* socket, const QJsonObject &message)
{
    if (!socket || socket->state() != QAbstractSocket::ConnectedState)
        return;

    const QByteArray data = QJsonDocument(message).toJson(QJsonDocument::Compact) + '\n';
    socket->write(data);
}

void DeviceConnectionServer::sendMessage(const QString &deviceId, const QJsonObject &message)
{
    if (!_connections.contains(deviceId))
        return;
    sendMessage(_connections[deviceId].socket, message);
}

QString DeviceConnectionServer::connectionStatus(const DeviceConnection &connection) const
{
    const qint64 elapsed = connection.lastHeartbeat.msecsTo(QDateTime::currentDateTime());
    if (elapsed > HEARTBEAT_TIMEOUT)
        return QStringLiteral("Lost");
    if (elapsed > IDLE_THRESHOLD)
        return QStringLiteral("Idle");
    return QStringLiteral("Active");
}

void DeviceConnectionServer::updateConnectedDevicesList()
{
    _connectedDevicesList.clear();

    for (auto it = _connections.constBegin(); it != _connections.constEnd(); ++it) {
        const DeviceConnection &connection = it.value();
        QVariantMap deviceObject;
        deviceObject["deviceId"] = connection.deviceId;
        deviceObject["deviceName"] = connection.deviceName;
        deviceObject["version"] = connection.version;
        deviceObject["mac"] = connection.mac;
        deviceObject["ipAddress"] = connection.ipAddress;
        deviceObject["port"] = connection.socket ? connection.socket->peerPort() : 0;
        deviceObject["capabilities"] = connection.capabilities;
        deviceObject["lastHeartbeat"] = connection.lastHeartbeat.toString(Qt::ISODate);
        deviceObject["connectedSince"] = connection.connectedSince.toString(Qt::ISODate);
        deviceObject["isActive"] = connectionStatus(connection) != QLatin1String("Lost");
        deviceObject["status"] = connectionStatus(connection);
        _connectedDevicesList.append(deviceObject);
    }

    emit connectedDevicesChanged();
    emit connectedDeviceCountChanged();
}
