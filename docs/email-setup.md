# Email Alert Setup

## 1. Install Postfix

```bash
sudo apt install postfix mailutils libsasl2-modules -y
```

Select "Internet Site" when prompted.

## 2. Configure Gmail relay

Add to `/etc/postfix/main.cf`:

```
relayhost = [smtp.gmail.com]:587
smtp_tls_security_level = encrypt
smtp_sasl_auth_enable = yes
smtp_sasl_security_options = noanonymous
smtp_sasl_password_maps = hash:/etc/postfix/sasl_passwd
smtp_tls_CAfile = /etc/ssl/certs/ca-certificates.crt
```

## 3. Create credentials file

```bash
echo "[smtp.gmail.com]:587    your-email@gmail.com:your-app-password" | sudo tee /etc/postfix/sasl_passwd
sudo chmod 600 /etc/postfix/sasl_passwd
sudo postmap /etc/postfix/sasl_passwd
sudo systemctl restart postfix
```

## 4. Test

```bash
echo "Test" | mail -s "Test" your-email@gmail.com
```

## 5. Deploy integration script

```bash
sudo cp custom-email-alert.sh /var/ossec/integrations/
sudo chmod 750 /var/ossec/integrations/custom-email-alert.sh
sudo chown root:wazuh /var/ossec/integrations/custom-email-alert.sh
```