#include "devicemanager.h"
#include "TCPServer/connectionhandler.h"
#include <QDebug>
#include <QJsonDocument>
#include <QDateTime>
#include <QTimer>

#define CLEANUP_INTERVAL 30000  // 30 secondes
#define DEVICE_TIMEOUT 120000   // 2 minutes

DeviceManager::DeviceManager(QObject *parent)
    : QObject(parent)
{
    _cleanupTimer = new QTimer(this);
    _cleanupTimer->setInterval(CLEANUP_INTERVAL);
    _cleanupTimer->setSingleShot(false);
    connect(_cleanupTimer, &QTimer::timeout, this, &DeviceManager::cleanupInactiveDevices);
    _cleanupTimer->start();
    
    qDebug() << "DeviceManager: Initialized";
}

DeviceManager::~DeviceManager()
{
    qDebug() << "DeviceManager: Destroyed";
}

void DeviceManager::registerDevice(ConnectionHandler* handler, const QString& deviceId, const QString& deviceName, const QString& ipAddress)
{
    if (!handler) {
        qWarning() << "DeviceManager: Cannot register device with null handler";
        return;
    }
    
    ConnectedDevice device;
    device.deviceId = deviceId;
    device.deviceName = deviceName;
    device.ipAddress = ipAddress;
    device.port = 0; // Sera mis à jour si disponible
    device.lastSeen = QDateTime::currentDateTime();
    device.connectedAt = QDateTime::currentDateTime();
    device.isActive = true;
    device.appVersion = "Unknown";
    device.deviceModel = "Unknown";
    
    _devices[handler] = device;
    _deviceIdToHandler[deviceId] = handler;
    
    logDeviceActivity(deviceId, "Connected");
    emit deviceConnected(deviceId, deviceName);
    emit deviceCountChanged(deviceCount());
    emit deviceListChanged();
    
    qDebug() << "DeviceManager: Device registered -" << deviceId << "(" << deviceName << ") from" << ipAddress;
}

void DeviceManager::unregisterDevice(ConnectionHandler* handler)
{
    if (!handler || !_devices.contains(handler)) {
        return;
    }
    
    ConnectedDevice device = _devices[handler];
    QString deviceId = device.deviceId;
    
    _devices.remove(handler);
    _deviceIdToHandler.remove(deviceId);
    
    logDeviceActivity(deviceId, "Disconnected");
    emit deviceDisconnected(deviceId);
    emit deviceCountChanged(deviceCount());
    emit deviceListChanged();
    
    qDebug() << "DeviceManager: Device unregistered -" << deviceId;
}

void DeviceManager::updateDeviceActivity(ConnectionHandler* handler)
{
    if (!handler || !_devices.contains(handler)) {
        return;
    }
    
    ConnectedDevice& device = _devices[handler];
    device.lastSeen = QDateTime::currentDateTime();
    device.isActive = true;
    
    emit deviceActivityUpdated(device.deviceId);
}

int DeviceManager::deviceCount() const
{
    return _devices.size();
}

QJsonArray DeviceManager::deviceList() const
{
    QJsonArray array;
    
    for (auto it = _devices.begin(); it != _devices.end(); ++it) {
        const ConnectedDevice& device = it.value();
        
        QJsonObject deviceObj;
        deviceObj["deviceId"] = device.deviceId;
        deviceObj["deviceName"] = device.deviceName;
        deviceObj["ipAddress"] = device.ipAddress;
        deviceObj["port"] = device.port;
        deviceObj["lastSeen"] = device.lastSeen.toString(Qt::ISODate);
        deviceObj["connectedAt"] = device.connectedAt.toString(Qt::ISODate);
        deviceObj["isActive"] = device.isActive;
        deviceObj["appVersion"] = device.appVersion;
        deviceObj["deviceModel"] = device.deviceModel;
        
        // Calculer le temps de connexion
        qint64 connectionTime = device.connectedAt.secsTo(QDateTime::currentDateTime());
        deviceObj["connectionTimeSeconds"] = connectionTime;
        
        // Calculer le temps depuis la dernière activité
        qint64 lastActivitySeconds = device.lastSeen.secsTo(QDateTime::currentDateTime());
        deviceObj["lastActivitySeconds"] = lastActivitySeconds;
        
        array.append(deviceObj);
    }
    
    return array;
}

void DeviceManager::broadcastLoadBibList()
{
    QJsonObject parameters;
    parameters["forceReload"] = true;
    
    int sentCount = 0;
    for (auto it = _devices.begin(); it != _devices.end(); ++it) {
        ConnectionHandler* handler = it.key();
        if (handler) {
            sendCommandToHandler(handler, "loadBibList", parameters);
            sentCount++;
        }
    }
    
    logDeviceActivity("BROADCAST", "Load Bib List");
    emit broadcastCommandSent("loadBibList", sentCount);
    qDebug() << "DeviceManager: Broadcast loadBibList to" << sentCount << "devices";
}

void DeviceManager::broadcastReloadData()
{
    QJsonObject parameters;
    parameters["reloadAll"] = true;
    
    int sentCount = 0;
    for (auto it = _devices.begin(); it != _devices.end(); ++it) {
        ConnectionHandler* handler = it.key();
        if (handler) {
            sendCommandToHandler(handler, "reloadData", parameters);
            sentCount++;
        }
    }
    
    logDeviceActivity("BROADCAST", "Reload Data");
    emit broadcastCommandSent("reloadData", sentCount);
    qDebug() << "DeviceManager: Broadcast reloadData to" << sentCount << "devices";
}

void DeviceManager::broadcastClearPenalties()
{
    QJsonObject parameters;
    parameters["clearAll"] = true;
    
    int sentCount = 0;
    for (auto it = _devices.begin(); it != _devices.end(); ++it) {
        ConnectionHandler* handler = it.key();
        if (handler) {
            sendCommandToHandler(handler, "clearPenalties", parameters);
            sentCount++;
        }
    }
    
    logDeviceActivity("BROADCAST", "Clear Penalties");
    emit broadcastCommandSent("clearPenalties", sentCount);
    qDebug() << "DeviceManager: Broadcast clearPenalties to" << sentCount << "devices";
}

void DeviceManager::broadcastClearTimes()
{
    QJsonObject parameters;
    parameters["clearAll"] = true;
    
    int sentCount = 0;
    for (auto it = _devices.begin(); it != _devices.end(); ++it) {
        ConnectionHandler* handler = it.key();
        if (handler) {
            sendCommandToHandler(handler, "clearTimes", parameters);
            sentCount++;
        }
    }
    
    logDeviceActivity("BROADCAST", "Clear Times");
    emit broadcastCommandSent("clearTimes", sentCount);
    qDebug() << "DeviceManager: Broadcast clearTimes to" << sentCount << "devices";
}

void DeviceManager::broadcastCustomCommand(const QString& command, const QJsonObject& parameters)
{
    int sentCount = 0;
    for (auto it = _devices.begin(); it != _devices.end(); ++it) {
        ConnectionHandler* handler = it.key();
        if (handler) {
            sendCommandToHandler(handler, command, parameters);
            sentCount++;
        }
    }
    
    logDeviceActivity("BROADCAST", "Custom Command: " + command);
    emit broadcastCommandSent(command, sentCount);
    qDebug() << "DeviceManager: Broadcast custom command" << command << "to" << sentCount << "devices";
}

void DeviceManager::sendCommandToDevice(const QString& deviceId, const QString& command, const QJsonObject& parameters)
{
    if (!_deviceIdToHandler.contains(deviceId)) {
        qWarning() << "DeviceManager: Device not found:" << deviceId;
        return;
    }
    
    ConnectionHandler* handler = _deviceIdToHandler[deviceId];
    if (handler) {
        sendCommandToHandler(handler, command, parameters);
        logDeviceActivity(deviceId, "Command: " + command);
        emit commandSentToDevice(deviceId, command);
        qDebug() << "DeviceManager: Sent command" << command << "to device" << deviceId;
    }
}

void DeviceManager::disconnectDevice(const QString& deviceId)
{
    if (!_deviceIdToHandler.contains(deviceId)) {
        qWarning() << "DeviceManager: Device not found for disconnect:" << deviceId;
        return;
    }
    
    ConnectionHandler* handler = _deviceIdToHandler[deviceId];
    if (handler) {
        // Envoyer une commande de déconnexion avant de fermer
        sendCommandToHandler(handler, "disconnect", QJsonObject());
        
        // Marquer comme inactif
        if (_devices.contains(handler)) {
            _devices[handler].isActive = false;
        }
        
        logDeviceActivity(deviceId, "Force Disconnect");
        qDebug() << "DeviceManager: Force disconnect device" << deviceId;
    }
}

bool DeviceManager::isDeviceConnected(const QString& deviceId) const
{
    return _deviceIdToHandler.contains(deviceId) && _devices.contains(_deviceIdToHandler[deviceId]);
}

QString DeviceManager::getDeviceStatus(const QString& deviceId) const
{
    if (!_deviceIdToHandler.contains(deviceId)) {
        return "Not Connected";
    }
    
    ConnectionHandler* handler = _deviceIdToHandler[deviceId];
    if (!_devices.contains(handler)) {
        return "Unknown";
    }
    
    const ConnectedDevice& device = _devices[handler];
    if (!device.isActive) {
        return "Inactive";
    }
    
    qint64 lastActivitySeconds = device.lastSeen.secsTo(QDateTime::currentDateTime());
    if (lastActivitySeconds > 60) {
        return "Idle";
    }
    
    return "Active";
}

void DeviceManager::cleanupInactiveDevices()
{
    QDateTime now = QDateTime::currentDateTime();
    QList<ConnectionHandler*> toRemove;
    
    for (auto it = _devices.begin(); it != _devices.end(); ++it) {
        ConnectionHandler* handler = it.key();
        const ConnectedDevice& device = it.value();
        
        qint64 inactiveTime = device.lastSeen.secsTo(now);
        if (inactiveTime > DEVICE_TIMEOUT) {
            toRemove.append(handler);
        }
    }
    
    for (ConnectionHandler* handler : toRemove) {
        unregisterDevice(handler);
    }
    
    if (!toRemove.isEmpty()) {
        qDebug() << "DeviceManager: Cleaned up" << toRemove.size() << "inactive devices";
    }
}

void DeviceManager::updateDeviceLastSeen(ConnectionHandler* handler)
{
    updateDeviceActivity(handler);
}

void DeviceManager::sendCommandToHandler(ConnectionHandler* handler, const QString& command, const QJsonObject& parameters)
{
    if (!handler) {
        return;
    }
    
    QJsonObject commandJson = createCommandJson(command, parameters);
    QJsonDocument doc(commandJson);
    QByteArray data = doc.toJson(QJsonDocument::Compact);
    data.append('\x04'); // EOT
    
    // TODO: Implémenter l'envoi de commandes via ConnectionHandler
    // Pour l'instant, on log la commande
    qDebug() << "DeviceManager: Would send command to handler:" << command << "with data:" << data;
}

QJsonObject DeviceManager::createCommandJson(const QString& command, const QJsonObject& parameters)
{
    QJsonObject json;
    json["command"] = command;
    json["timestamp"] = QDateTime::currentDateTime().toMSecsSinceEpoch();
    json["parameters"] = parameters;
    return json;
}

void DeviceManager::logDeviceActivity(const QString& deviceId, const QString& action)
{
    qDebug() << "DeviceManager: [" << deviceId << "]" << action;
}
