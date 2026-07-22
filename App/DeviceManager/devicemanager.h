#ifndef DEVICEMANAGER_H
#define DEVICEMANAGER_H

#include <QObject>
#include <QTimer>
#include <QHash>
#include <QString>
#include <QDateTime>
#include <QJsonObject>
#include <QJsonArray>

class ConnectionHandler;

struct ConnectedDevice {
    QString deviceId;
    QString deviceName;
    QString ipAddress;
    int port;
    QDateTime lastSeen;
    QDateTime connectedAt;
    bool isActive;
    QString appVersion;
    QString deviceModel;
    
    ConnectedDevice() : port(0), isActive(false) {}
};

class DeviceManager : public QObject
{
    Q_OBJECT
    
    Q_PROPERTY(int deviceCount READ deviceCount NOTIFY deviceCountChanged)
    Q_PROPERTY(QJsonArray deviceList READ deviceList NOTIFY deviceListChanged)
    
public:
    explicit DeviceManager(QObject *parent = nullptr);
    ~DeviceManager();
    
    // Gestion des appareils
    void registerDevice(ConnectionHandler* handler, const QString& deviceId, const QString& deviceName, const QString& ipAddress);
    void unregisterDevice(ConnectionHandler* handler);
    void updateDeviceActivity(ConnectionHandler* handler);
    
    // Propriétés QML
    int deviceCount() const;
    QJsonArray deviceList() const;
    
    // Commandes de diffusion
    Q_INVOKABLE void broadcastLoadBibList();
    Q_INVOKABLE void broadcastReloadData();
    Q_INVOKABLE void broadcastClearPenalties();
    Q_INVOKABLE void broadcastClearTimes();
    Q_INVOKABLE void broadcastCustomCommand(const QString& command, const QJsonObject& parameters = QJsonObject());
    
    // Gestion individuelle
    Q_INVOKABLE void sendCommandToDevice(const QString& deviceId, const QString& command, const QJsonObject& parameters = QJsonObject());
    Q_INVOKABLE void disconnectDevice(const QString& deviceId);
    
    // Statut
    Q_INVOKABLE bool isDeviceConnected(const QString& deviceId) const;
    Q_INVOKABLE QString getDeviceStatus(const QString& deviceId) const;
    
signals:
    void deviceCountChanged(int count);
    void deviceListChanged();
    void deviceConnected(const QString& deviceId, const QString& deviceName);
    void deviceDisconnected(const QString& deviceId);
    void deviceActivityUpdated(const QString& deviceId);
    void broadcastCommandSent(const QString& command, int deviceCount);
    void commandSentToDevice(const QString& deviceId, const QString& command);
    
private slots:
    void cleanupInactiveDevices();
    void updateDeviceLastSeen(ConnectionHandler* handler);
    
private:
    QHash<ConnectionHandler*, ConnectedDevice> _devices;
    QHash<QString, ConnectionHandler*> _deviceIdToHandler;
    QTimer* _cleanupTimer;
    
    void sendCommandToHandler(ConnectionHandler* handler, const QString& command, const QJsonObject& parameters = QJsonObject());
    QJsonObject createCommandJson(const QString& command, const QJsonObject& parameters = QJsonObject());
    void logDeviceActivity(const QString& deviceId, const QString& action);
};

#endif // DEVICEMANAGER_H
