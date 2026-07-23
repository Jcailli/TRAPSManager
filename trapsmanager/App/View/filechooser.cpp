#include "filechooser.h"

FileChooser::FileChooser(const QString &title, QStringList nameFilters, bool saveMode) : QObject(),
    _title(title),
    _nameFilters(nameFilters),
    _saveMode(saveMode)
{

}

void FileChooser::onSelectedFilePath(std::function<void(QString)> callback) {
    QObject::connect(this, &FileChooser::selectedFilePath, callback);
}
