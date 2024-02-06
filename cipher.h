#ifndef CIPHER_H
#define CIPHER_H

#include <QObject>
#include <QDebug>
#include <QFile>
#include <QDir>
#include <openssl/rsa.h>
#include <openssl/engine.h>
#include <openssl/pem.h>
#include <openssl/conf.h>
#include <openssl/evp.h>
#include <openssl/err.h>
#include <openssl/aes.h>
#include <openssl/rand.h>
#include "registry.h"

#include "loggingcategories.h"

// The PADDING parameter means RSA will pad your data for you
#define PADDING RSA_PKCS1_PADDING
#define KEYSIZE 32
#define IVSIZE 32
#define SALTSIZE 8

class Cipher : public QObject
{
    Q_OBJECT
public:
    explicit Cipher(QObject *parent = 0);
    ~Cipher();

    void generateRsaKeys(int rsaSize);

    RSA *getPublicKey(QByteArray &data);
    RSA *getPublicKey(QString filename);

    RSA *getPrivateKey(QByteArray &data);
    RSA *getPrivateKey(QString filename);

    QByteArray encryptRSA(RSA *key, QByteArray &data);
    QByteArray decryptRSA(RSA *key, QByteArray &data);

    QByteArray encryptAES(QByteArray passphrase, QByteArray &data);
    QByteArray decryptAES(QByteArray passphrase, QByteArray &data);

    QByteArray randomBytes(int size);

    void freeRSAKey(RSA *key);

    QByteArray readFile(QString filename);

signals:

private slots:
    void writeFile(QString filename, QByteArray &data);

private:
    QString appPath = QCoreApplication::applicationDirPath() + QDir::separator();
    QByteArray passphrase = Registry::getDeviceId();
};

#endif // CIPHER_H
