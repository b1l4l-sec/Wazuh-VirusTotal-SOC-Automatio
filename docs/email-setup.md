# Email Alert Setup

Step-by-step guide to configure professional HTML email alerts through Gmail SMTP.

---

## 1. Create Gmail App Password

1. Go to [Google Account Security](https://myaccount.google.com/security)
2. Enable **2-Step Verification** if not already enabled
3. Search for **App Passwords**
4. Select **Mail** and **Other (Custom name)** → type `Wazuh`
5. Generate and save the 16-character password

---

## 2. Install Postfix

```bash
sudo apt update
sudo apt install postfix mailutils libsasl2-modules -y
```

Select **Internet Site** when prompted.

---

## 3. Configure Gmail Relay

Add to the bottom of `/etc/postfix/main.cf`:

```
relayhost = [smtp.gmail.com]:587
smtp_tls_security_level = encrypt
smtp_sasl_auth_enable = yes
smtp_sasl_security_options = noanonymous
smtp_sasl_password_maps = hash:/etc/postfix/sasl_passwd
smtp_tls_CAfile = /etc/ssl/certs/ca-certificates.crt
```

If there is an existing empty `relayhost =` line, comment it out with `#`.

---

## 4. Create Credentials File

```bash
echo "[smtp.gmail.com]:587    your-email@gmail.com:your-app-password" | sudo tee /etc/postfix/sasl_passwd
sudo chmod 600 /etc/postfix/sasl_passwd
sudo postmap /etc/postfix/sasl_passwd
sudo systemctl restart postfix
```

Replace `your-email@gmail.com` with your Gmail address and `your-app-password` with the 16-character app password (no spaces).

---

## 5. Test Email Delivery

```bash
echo "Test email from Wazuh SOC" | mail -s "Wazuh Test" your-email@gmail.com
```

Check your inbox and spam folder. Verify delivery with:

```bash
sudo journalctl -u postfix --no-pager | tail -20
```

Look for `status=sent` in the output.

---

## 6. Deploy Integration Script

```bash
sudo cp custom-email-alert.sh /var/ossec/integrations/
sudo chmod 750 /var/ossec/integrations/custom-email-alert.sh
sudo chown root:wazuh /var/ossec/integrations/custom-email-alert.sh
```

---

## 7. Add Integration to ossec.conf

Add inside the `<ossec_config>` block on the manager:

```xml
<integration>
  <name>custom-email-alert.sh</name>
  <rule_id>100201</rule_id>
  <alert_format>json</alert_format>
</integration>
```

---

## 8. Restart Wazuh Manager

```bash
sudo systemctl restart wazuh-manager
```

---

## Troubleshooting

| Issue | Solution |
|-------|----------|
| `smtp_use_tls` warning | Replace `smtp_use_tls = yes` with `smtp_tls_security_level = encrypt` |
| Duplicate `smtp_tls_security_level` warning | Comment out the duplicate line in the middle of `main.cf` |
| No `/var/log/mail.log` on Kali | Use `sudo journalctl -u postfix` instead |
| Mail queue not empty | Check `sudo mailq` and review credentials in `sasl_passwd` |
| Gmail blocks sign-in | Ensure you are using an App Password, not your regular password |