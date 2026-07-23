#ifndef FILECHOOSER_H
#define FILECHOOSER_H

#include <QObject>
#include <functional>

class FileChooser : public QObject
{
    Q_OBJECT
public:
    explicit FileChooser(const QString& title, QStringList nameFilters = QStringList(), bool saveMode = false);

    QString title() const { return _title; }
    QStringList nameFilters() const { return _nameFilters; }
    bool saveMode() const { return _saveMode; }
    void onSelectedFilePath(std::function<void(QString)> callback);

signals:

    void selectedFilePath(QString filePath);


private:

    QString _title;
    QStringList _nameFilters;
    bool _saveMode;

};

#endif // FILECHOOSER_H
