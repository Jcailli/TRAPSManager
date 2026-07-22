#include "deviceallowlist.h"
#include <QSettings>
#include <QUuid>
#include <QDebug>

DeviceAllowlist::DeviceAllowlist(QObject *parent) : QObject(parent)
{
    load();
}

QVariantList DeviceAllowlist::devices() const
{
    QVariantList list;
    for (const AllowedDevice &device : _devices)
        list.append(toVariantMap(device));
    return list;
}

int DeviceAllowlist::count() const
{
    return _devices.count();
}

bool DeviceAllowlist::addDevice(const QString &name, const QString &mac,
                                const QString &ip, const QString &deviceId)
{
    const QString normMac = normalizeMac(mac);
    const QString normIp = normalizeIp(ip);
    const QString trimmedDeviceId = deviceId.trimmed();

    if (normMac.isEmpty() && normIp.isEmpty() && trimmedDeviceId.isEmpty()) {
        qWarning() << "DeviceAllowlist: at least mac, ip or deviceId is required";
        return false;
    }

    AllowedDevice device;
    device.entryId = QUuid::createUuid().toString().remove('{').remove('}');
    device.name = name.trimmed().isEmpty() ? QStringLiteral("Appareil") : name.trimmed();
    device.mac = normMac;
    device.ip = normIp;
    device.deviceId = trimmedDeviceId;
    device.enabled = true;

    _devices.append(device);
    save();
    emit devicesChanged();
    return true;
}

bool DeviceAllowlist::updateDevice(const QString &entryId, const QString &name,
                                   const QString &mac, const QString &ip,
                                   const QString &deviceId)
{
    const int idx = indexOfEntry(entryId);
    if (idx < 0)
        return false;

    const QString normMac = normalizeMac(mac);
    const QString normIp = normalizeIp(ip);
    const QString trimmedDeviceId = deviceId.trimmed();

    if (normMac.isEmpty() && normIp.isEmpty() && trimmedDeviceId.isEmpty())
        return false;

    AllowedDevice &device = _devices[idx];
    device.name = name.trimmed().isEmpty() ? device.name : name.trimmed();
    device.mac = normMac;
    device.ip = normIp;
    device.deviceId = trimmedDeviceId;
    save();
    emit devicesChanged();
    return true;
}

bool DeviceAllowlist::removeDevice(const QString &entryId)
{
    const int idx = indexOfEntry(entryId);
    if (idx < 0)
        return false;

    _devices.removeAt(idx);
    save();
    emit devicesChanged();
    return true;
}

void DeviceAllowlist::setDeviceEnabled(const QString &entryId, bool enabled)
{
    const int idx = indexOfEntry(entryId);
    if (idx < 0)
        return;

    _devices[idx].enabled = enabled;
    save();
    emit devicesChanged();
}

void DeviceAllowlist::clear()
{
    _devices.clear();
    save();
    emit devicesChanged();
}

bool DeviceAllowlist::isAuthorized(const QString &mac, const QString &ip, const QString &deviceId) const
{
    // Liste vide = personne n'est autorisé (garde-fou strict)
    if (_devices.isEmpty())
        return false;

    const QString normMac = normalizeMac(mac);
    const QString normIp = normalizeIp(ip);
    const QString trimmedDeviceId = deviceId.trimmed();

    for (const AllowedDevice &device : _devices) {
        if (!device.enabled)
            continue;

        if (!device.mac.isEmpty() && !normMac.isEmpty() && device.mac == normMac)
            return true;
        if (!device.ip.isEmpty() && !normIp.isEmpty() && device.ip == normIp)
            return true;
        if (!device.deviceId.isEmpty() && !trimmedDeviceId.isEmpty()
                && device.deviceId.compare(trimmedDeviceId, Qt::CaseInsensitive) == 0)
            return true;
    }
    return false;
}

QString DeviceAllowlist::normalizeMac(const QString &mac)
{
    QString out;
    for (const QChar &ch : mac.trimmed()) {
        if (ch.isLetterOrNumber())
            out.append(ch.toUpper());
    }
    // Accepte 12 hex (48-bit) ; ignore formats invalides
    if (out.length() != 12)
        return QString();
    for (const QChar &ch : out) {
        if (!ch.isDigit() && (ch < QLatin1Char('A') || ch > QLatin1Char('F')))
            return QString();
    }
    // Format canonique AA:BB:CC:DD:EE:FF
    return QString("%1:%2:%3:%4:%5:%6")
            .arg(out.mid(0, 2))
            .arg(out.mid(2, 2))
            .arg(out.mid(4, 2))
            .arg(out.mid(6, 2))
            .arg(out.mid(8, 2))
            .arg(out.mid(10, 2));
}

QString DeviceAllowlist::normalizeIp(const QString &ip)
{
    QString cleaned = ip.trimmed();
    // IPv4 mappée IPv6 : ::ffff:192.168.1.10
    if (cleaned.startsWith(QLatin1String("::ffff:"), Qt::CaseInsensitive))
        cleaned = cleaned.mid(7);
    return cleaned;
}

void DeviceAllowlist::load()
{
    _devices.clear();
    QSettings settings;
    const int size = settings.beginReadArray("deviceAllowlist");
    for (int i = 0; i < size; ++i) {
        settings.setArrayIndex(i);
        AllowedDevice device;
        device.entryId = settings.value("entryId").toString();
        if (device.entryId.isEmpty())
            device.entryId = QUuid::createUuid().toString().remove('{').remove('}');
        device.name = settings.value("name", "Appareil").toString();
        device.mac = normalizeMac(settings.value("mac").toString());
        device.ip = normalizeIp(settings.value("ip").toString());
        device.deviceId = settings.value("deviceId").toString().trimmed();
        device.enabled = settings.value("enabled", true).toBool();
        if (!device.mac.isEmpty() || !device.ip.isEmpty() || !device.deviceId.isEmpty())
            _devices.append(device);
    }
    settings.endArray();
}

void DeviceAllowlist::save() const
{
    QSettings settings;
    settings.remove("deviceAllowlist");
    settings.beginWriteArray("deviceAllowlist", _devices.size());
    for (int i = 0; i < _devices.size(); ++i) {
        settings.setArrayIndex(i);
        const AllowedDevice &device = _devices.at(i);
        settings.setValue("entryId", device.entryId);
        settings.setValue("name", device.name);
        settings.setValue("mac", device.mac);
        settings.setValue("ip", device.ip);
        settings.setValue("deviceId", device.deviceId);
        settings.setValue("enabled", device.enabled);
    }
    settings.endArray();
}

int DeviceAllowlist::indexOfEntry(const QString &entryId) const
{
    for (int i = 0; i < _devices.size(); ++i) {
        if (_devices.at(i).entryId == entryId)
            return i;
    }
    return -1;
}

QVariantMap DeviceAllowlist::toVariantMap(const AllowedDevice &device) const
{
    QVariantMap map;
    map.insert("entryId", device.entryId);
    map.insert("name", device.name);
    map.insert("mac", device.mac);
    map.insert("ip", device.ip);
    map.insert("deviceId", device.deviceId);
    map.insert("enabled", device.enabled);
    return map;
}
