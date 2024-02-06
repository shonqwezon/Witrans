#include "cipher.h"

Cipher::Cipher(QObject *parent) : QObject(parent) {
    ERR_load_CRYPTO_strings();
    OpenSSL_add_all_algorithms();
    if(!(QFileInfo::exists(appPath + "public.pem") && QFileInfo::exists(appPath + "private.pem"))) {
        qCritical(logCipher()) << "Public or privte key doesn't exist";
        generateRsaKeys(4096);
    }
}

Cipher::~Cipher() {
    EVP_cleanup();
    ERR_free_strings();
}

void Cipher::generateRsaKeys(int rsaSize) {
    unsigned char* password = (unsigned char*)passphrase.constData();

    RSA* rsa = RSA_new();
    BIGNUM* bn = BN_new();
    BN_set_word(bn, RSA_F4);
    RSA_generate_key_ex(rsa, rsaSize, bn, NULL);

    BIO* privKeyBuff = BIO_new(BIO_s_mem());
    BIO* pubKeyBuff = BIO_new(BIO_s_mem());
    PEM_write_bio_RSAPrivateKey(privKeyBuff, rsa, EVP_aes_256_cbc(), password, static_cast<int>(passphrase.length()), NULL, NULL);
    PEM_write_bio_RSA_PUBKEY(pubKeyBuff, rsa);

    char* privKeyData;
    char* pubKeyData;
    long privKeySize = BIO_get_mem_data(privKeyBuff, &privKeyData);
    long pubKeySize = BIO_get_mem_data(pubKeyBuff, &pubKeyData);

    QByteArray privKey = QByteArray(privKeyData, privKeySize);
    QByteArray pubKey = QByteArray(pubKeyData, pubKeySize);

    BIO_free_all(privKeyBuff);
    BIO_free_all(pubKeyBuff);
    BN_free(bn);
    RSA_free(rsa);

    writeFile("private.pem", privKey);
    writeFile("public.pem", pubKey);
}

RSA *Cipher::getPublicKey(QByteArray &data) {
    const char* publicKeyStr = data.constData();
    BIO* bio = BIO_new_mem_buf((void*)publicKeyStr, -1);
    BIO_set_flags(bio, BIO_FLAGS_BASE64_NO_NL);

    RSA* rsaPubKey = PEM_read_bio_RSA_PUBKEY(bio, NULL, NULL, NULL);
    if(!rsaPubKey) {
        qCritical(logCipher()) << "Could not load public key" << ERR_error_string(ERR_get_error(),NULL);
    }

    BIO_free(bio);
    return rsaPubKey;
}

RSA *Cipher::getPublicKey(QString filename) {
    QByteArray data = readFile(filename);
    return getPublicKey(data);
}

RSA *Cipher::getPrivateKey(QByteArray &data) {
    unsigned char* password = (unsigned char*)passphrase.constData();

    const char* privateKeyStr = data.constData();
    BIO* bio = BIO_new_mem_buf((void*)privateKeyStr, -1);
    BIO_set_flags(bio, BIO_FLAGS_BASE64_NO_NL);

    RSA* rsaPrivKey = PEM_read_bio_RSAPrivateKey(bio, NULL, NULL, password);
    if(!rsaPrivKey) {
        qCritical(logCipher()) << "Could not load private key" << ERR_error_string(ERR_get_error(), NULL);
    }

    BIO_free(bio);
    return rsaPrivKey;
}

RSA *Cipher::getPrivateKey(QString filename) {
    QByteArray data = readFile(filename);
    return getPrivateKey(data);
}

QByteArray Cipher::encryptRSA(RSA *key, QByteArray &data) {
    QByteArray buffer;
    int dataSize = data.length();
    const unsigned char* str = (const unsigned char*)data.constData();

    int rsaLen = RSA_size(key);

    unsigned char* ed = (unsigned char*)malloc(rsaLen);

    int resultLen = RSA_public_encrypt(dataSize, str, ed, key, PADDING);

    if(resultLen == -1) {
        qCritical(logCipher()) << "Could not encrypt: " << ERR_error_string(ERR_get_error(),NULL);
        return buffer;
    }

    buffer = QByteArray(reinterpret_cast<char*>(ed), resultLen);
    free(ed);

    return buffer;
}

QByteArray Cipher::decryptRSA(RSA *key, QByteArray &data) {
    QByteArray buffer;
    const unsigned char* encryptedData = (const unsigned char*)data.constData();

    int rsaLen = RSA_size(key);

    unsigned char* ed = (unsigned char*)malloc(rsaLen);

    int resultLen = RSA_private_decrypt(rsaLen, encryptedData, ed, key, PADDING);

    if(resultLen == -1) {
        qCritical(logCipher()) << "Could not decrypt: " << ERR_error_string(ERR_get_error(),NULL);
        return buffer;
    }

    buffer = QByteArray(reinterpret_cast<char*>(ed), resultLen);
    free(ed);

    return buffer;
}

QByteArray Cipher::encryptAES(QByteArray passphrase, QByteArray &data) {
    QByteArray msalt = randomBytes(SALTSIZE);
    int rounds = 1;
    unsigned char key[KEYSIZE];
    unsigned char iv[IVSIZE];

    const unsigned char* salt = (const unsigned char*)msalt.constData();
    const unsigned char* password = (const unsigned char*)passphrase.constData();

    int i = EVP_BytesToKey(EVP_aes_256_cbc(), EVP_sha1(), salt, password, passphrase.length(), rounds, key, iv);

    if(i != KEYSIZE) {
        qCritical(logCipher()) << "EVP_BytesToKey() error: " << ERR_error_string(ERR_get_error(), NULL);
        return QByteArray();
    }

    EVP_CIPHER_CTX *en = EVP_CIPHER_CTX_new();
    EVP_CIPHER_CTX_reset(en);

    if(!EVP_EncryptInit_ex(en, EVP_aes_256_cbc(), NULL, key, iv)) {
        qCritical(logCipher()) << "EVP_EncryptInit_ex() failed " << ERR_error_string(ERR_get_error(), NULL);
        return QByteArray();
    }

    char *input = data.data();
    int len = data.size();

    int c_len = len + AES_BLOCK_SIZE;
    int f_len = 0;
    unsigned char *ciphertext = (unsigned char*)malloc(c_len);

    if(!EVP_EncryptUpdate(en, ciphertext, &c_len, (unsigned char *)input, len)) {
        qCritical(logCipher()) << "EVP_EncryptUpdate() failed " << ERR_error_string(ERR_get_error(), NULL);
        return QByteArray();
    }

    if(!EVP_EncryptFinal(en, ciphertext+c_len, &f_len)) {
        qCritical(logCipher()) << "EVP_EncryptFinal_ex() failed "  << ERR_error_string(ERR_get_error(), NULL);
        return QByteArray();
    }

    len = c_len + f_len;

    EVP_CIPHER_CTX_free(en);

    //ciphertext

    QByteArray encrypted = QByteArray(reinterpret_cast<char*>(ciphertext), len);
    QByteArray finished;
    finished.append("Salted__");
    finished.append(msalt);
    finished.append(encrypted);

    free(ciphertext);

    return finished;
}

QByteArray Cipher::decryptAES(QByteArray passphrase, QByteArray &data) {
    QByteArray msalt;
    if(QString(data.mid(0,8)) == "Salted__") {
        msalt = data.mid(8,8);
        data = data.mid(16);
    }
    else {
        qWarning(logCipher()) << "Could not load salt from data!";
        msalt = randomBytes(SALTSIZE);
    }

    int rounds = 1;
    unsigned char key[KEYSIZE];
    unsigned char iv[IVSIZE];
    const unsigned char* salt = (const unsigned char*)msalt.constData();
    const unsigned char* password = (const unsigned char*)passphrase.data();

    int i = EVP_BytesToKey(EVP_aes_256_cbc(), EVP_sha1(), salt, password, passphrase.length(), rounds, key, iv);

    if(i != KEYSIZE) {
        qCritical(logCipher()) << "EVP_BytesToKey() error: " << ERR_error_string(ERR_get_error(), NULL);
        return QByteArray();
    }

    EVP_CIPHER_CTX *de = EVP_CIPHER_CTX_new();
    EVP_CIPHER_CTX_reset(de);

    if(!EVP_DecryptInit_ex(de, EVP_aes_256_cbc(), NULL, key, iv)) {
        qCritical(logCipher()) << "EVP_DecryptInit_ex() failed" << ERR_error_string(ERR_get_error(), NULL);
        return QByteArray();
    }

    char *input = data.data();
    int len = data.size();

    int p_len = len;
    int f_len = 0;
    unsigned char *plaintext = (unsigned char *)malloc(p_len + AES_BLOCK_SIZE);

    if(!EVP_DecryptUpdate(de, plaintext, &p_len, (unsigned char *)input, len)) {
        qCritical(logCipher()) << "EVP_DecryptUpdate() failed " <<  ERR_error_string(ERR_get_error(), NULL);
        return QByteArray();
    }

    if(!EVP_DecryptFinal_ex(de, plaintext+p_len, &f_len)) {
        qCritical(logCipher()) << "EVP_DecryptFinal_ex() failed " <<  ERR_error_string(ERR_get_error(), NULL);
        return QByteArray();
    }

    len = p_len + f_len;

    EVP_CIPHER_CTX_free(de);

    QByteArray decrypted = QByteArray(reinterpret_cast<char*>(plaintext), len);
    free(plaintext);

    return decrypted;
}

QByteArray Cipher::randomBytes(int size) {
    unsigned char arr[size];
    RAND_bytes(arr, size);

    QByteArray buffer = QByteArray(reinterpret_cast<char*>(arr), size);
    return buffer;
}

void Cipher::freeRSAKey(RSA *key) {
    if(key != nullptr) {
qDebug(logCipher()) << "Free rsa key" << key;
        try {
            RSA_free(key);
qDebug(logCipher()) << "Free rsa key successful";
        }  catch (...) {
qDebug(logCipher()) << "Some error in" << Q_FUNC_INFO;
        }
    }
    else {
qDebug(logCipher()) << "Free rsa key is NULL";
    }
}

QByteArray Cipher::readFile(QString filename) {
    QByteArray data;
    QFile file(appPath + filename);
    if(!file.open(QFile::ReadOnly)) {
        qCritical(logCipher()) << "Could not read file" << file.errorString();
        return data;
    }

    data = file.readAll();
    file.close();
    return data;
}

void Cipher::writeFile(QString filename, QByteArray &data) {
    QFile file(appPath + filename);
    if(file.exists()) {
        qCritical(logCipher()) << "File of keys exists" << filename;
        file.remove();
    }
    if(!file.open(QFile::WriteOnly)) {
        qCritical(logCipher()) << "Could not open file" << file.errorString();
        return;
    }

    file.write(data);
    file.close();
}
