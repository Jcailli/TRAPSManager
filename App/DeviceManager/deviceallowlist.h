#ifndef DEVICEALLOWLIST_H
#define DEVICEALLOWLIST_H

#include <QObject>
#include <QVariantList>
#include <QVariantMap>
#include <QString>
#include <QList>

struct AllowedDevice {
    QString entryId;
    QString name;
    QString mac;
    QString ip;
    QString deviceId;
    bool enabled;

    AllowedDevice() : enabled(true) {}
};

class DeviceAllowlist : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QVariantList devices READ devices NOTIFY devicesChanged)
    Q_PROPERTY(int count READ count NOTIFY devicesChanged)

public:
    explicit DeviceAllowlist(QObject *parent = nullptr);

    QVariantList devices() const;
    int count() const;

    Q_INVOKABLE bool addDevice(const QString &name, const QString &mac,
                               const QString &ip = QString(),
                               const QString &deviceId = QString());
    Q_INVOKABLE bool updateDevice(const QString &entryId, const QString &name,
                                  const QString &mac, const QString &ip,
                                  const QString &deviceId);
    Q_INVOKABLE bool removeDevice(const QString &entryId);
    Q_INVOKABLE void setDeviceEnabled(const QString &entryId, bool enabled);
    Q_INVOKABLE void clear();

    // true si au moins un critère non vide correspond à une entrée active
    bool isAuthorized(const QString &mac, const QString &ip, const QString &deviceId) const;

    static QString normalizeMac(const QString &mac);
    static QString normalizeIp(const QString &ip);

signals:
    void devicesChanged();

private:
    QList<AllowedDevice> _devices;

    void load();
    void save() const;
    int indexOfEntry(const QString &entryId) const;
    QVariantMap toVariantMap(const AllowedDevice &device) const;
};

#endif // DEVICEALLOWLIST_H
