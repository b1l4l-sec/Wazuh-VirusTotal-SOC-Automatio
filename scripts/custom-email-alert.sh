#!/bin/bash
# custom-email-alert.sh - Professional SOC Email Alerts

ALERT_FILE=$1

# Extract alert details
RULE_ID=$(cat "$ALERT_FILE" | jq -r '.rule.id // "N/A"')
RULE_LEVEL=$(cat "$ALERT_FILE" | jq -r '.rule.level // "N/A"')
RULE_DESC=$(cat "$ALERT_FILE" | jq -r '.rule.description // "N/A"')
AGENT_NAME=$(cat "$ALERT_FILE" | jq -r '.agent.name // "N/A"')
AGENT_IP=$(cat "$ALERT_FILE" | jq -r '.agent.ip // "N/A"')
TIMESTAMP=$(cat "$ALERT_FILE" | jq -r '.timestamp // "N/A"')
FILE_PATH=$(cat "$ALERT_FILE" | jq -r '.data.virustotal.source.file // .syscheck.path // "N/A"')
VT_POSITIVES=$(cat "$ALERT_FILE" | jq -r '.data.virustotal.positives // "N/A"')
VT_TOTAL=$(cat "$ALERT_FILE" | jq -r '.data.virustotal.total // "N/A"')
VT_PERMALINK=$(cat "$ALERT_FILE" | jq -r '.data.virustotal.permalink // "N/A"')
VT_MD5=$(cat "$ALERT_FILE" | jq -r '.data.virustotal.source.md5 // "N/A"')
VT_SHA1=$(cat "$ALERT_FILE" | jq -r '.data.virustotal.source.sha1 // "N/A"')
VT_MALICIOUS=$(cat "$ALERT_FILE" | jq -r '.data.virustotal.malicious // "N/A"')
VT_SCAN_DATE=$(cat "$ALERT_FILE" | jq -r '.data.virustotal.scan_date // "N/A"')
GROUPS=$(cat "$ALERT_FILE" | jq -r '.rule.groups // [] | join(", ")' 2>/dev/null)

# Determine severity
if [ "$RULE_LEVEL" -ge 12 ] 2>/dev/null; then
    SEVERITY="Critical"
    SEV_COLOR="#c0392b"
    SEV_BG="#fdf0ef"
elif [ "$RULE_LEVEL" -ge 10 ] 2>/dev/null; then
    SEVERITY="High"
    SEV_COLOR="#e67e22"
    SEV_BG="#fef5ec"
elif [ "$RULE_LEVEL" -ge 7 ] 2>/dev/null; then
    SEVERITY="Medium"
    SEV_COLOR="#f39c12"
    SEV_BG="#fef9ec"
else
    SEVERITY="Low"
    SEV_COLOR="#27ae60"
    SEV_BG="#eefbf3"
fi

# Malicious status
if [ "$VT_MALICIOUS" = "1" ]; then
    MAL_TEXT="Confirmed Malicious"
    MAL_COLOR="#c0392b"
else
    MAL_TEXT="Not Malicious"
    MAL_COLOR="#27ae60"
fi

# Build HTML email
EMAIL_BODY=$(cat <<EOF
Content-Type: text/html; charset="UTF-8"
Subject: Security Alert — ${SEVERITY} — Rule ${RULE_ID} on ${AGENT_NAME}
From: Wazuh SOC <YOUR_EMAIL@gmail.com>
To: YOUR_EMAIL@gmail.com

<!DOCTYPE html>
<html>
<head><meta charset="UTF-8"></head>
<body style="margin:0;padding:0;background-color:#f4f4f7;font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,Helvetica,Arial,sans-serif;">

<table width="100%" cellpadding="0" cellspacing="0" style="background-color:#f4f4f7;padding:30px 0;">
<tr><td align="center">
<table width="580" cellpadding="0" cellspacing="0" style="background-color:#ffffff;border-radius:6px;overflow:hidden;box-shadow:0 1px 3px rgba(0,0,0,0.08);">

<!-- Top bar -->
<tr><td style="background-color:${SEV_COLOR};height:4px;font-size:0;line-height:0;">&nbsp;</td></tr>

<!-- Header -->
<tr>
<td style="padding:28px 32px 20px 32px;border-bottom:1px solid #eaeaea;">
<table width="100%" cellpadding="0" cellspacing="0">
<tr>
<td><span style="font-size:18px;font-weight:600;color:#1a1a1a;">Security Incident Report</span></td>
<td align="right"><span style="display:inline-block;padding:4px 12px;border-radius:3px;font-size:12px;font-weight:600;color:#ffffff;background-color:${SEV_COLOR};">${SEVERITY} — Level ${RULE_LEVEL}</span></td>
</tr>
</table>
</td>
</tr>

<!-- Summary -->
<tr>
<td style="padding:24px 32px 0 32px;">
<p style="margin:0 0 4px 0;font-size:11px;text-transform:uppercase;letter-spacing:0.5px;color:#999;">Description</p>
<p style="margin:0;font-size:15px;color:#1a1a1a;line-height:1.5;">${RULE_DESC}</p>
</td>
</tr>

<!-- Details Table -->
<tr>
<td style="padding:24px 32px 0 32px;">
<p style="margin:0 0 12px 0;font-size:11px;text-transform:uppercase;letter-spacing:0.5px;color:#999;">Alert Details</p>
<table width="100%" cellpadding="0" cellspacing="0" style="border:1px solid #eaeaea;border-radius:4px;">
<tr>
<td style="padding:10px 14px;font-size:13px;color:#666;background-color:#fafafa;border-bottom:1px solid #eaeaea;width:140px;">Rule ID</td>
<td style="padding:10px 14px;font-size:13px;color:#1a1a1a;border-bottom:1px solid #eaeaea;font-family:monospace;">${RULE_ID}</td>
</tr>
<tr>
<td style="padding:10px 14px;font-size:13px;color:#666;background-color:#fafafa;border-bottom:1px solid #eaeaea;">Timestamp</td>
<td style="padding:10px 14px;font-size:13px;color:#1a1a1a;border-bottom:1px solid #eaeaea;">${TIMESTAMP}</td>
</tr>
<tr>
<td style="padding:10px 14px;font-size:13px;color:#666;background-color:#fafafa;border-bottom:1px solid #eaeaea;">Agent</td>
<td style="padding:10px 14px;font-size:13px;color:#1a1a1a;border-bottom:1px solid #eaeaea;">${AGENT_NAME} (${AGENT_IP})</td>
</tr>
<tr>
<td style="padding:10px 14px;font-size:13px;color:#666;background-color:#fafafa;">Groups</td>
<td style="padding:10px 14px;font-size:13px;color:#1a1a1a;">${GROUPS}</td>
</tr>
</table>
</td>
</tr>

$(if [ "$VT_POSITIVES" != "N/A" ]; then
cat <<VTBLOCK
<!-- Threat Analysis -->
<tr>
<td style="padding:24px 32px 0 32px;">
<p style="margin:0 0 12px 0;font-size:11px;text-transform:uppercase;letter-spacing:0.5px;color:#999;">Threat Analysis</p>
<table width="100%" cellpadding="0" cellspacing="0" style="border:1px solid #eaeaea;border-radius:4px;">
<tr>
<td style="padding:10px 14px;font-size:13px;color:#666;background-color:#fafafa;border-bottom:1px solid #eaeaea;width:140px;">File</td>
<td style="padding:10px 14px;font-size:13px;color:#1a1a1a;border-bottom:1px solid #eaeaea;word-break:break-all;">${FILE_PATH}</td>
</tr>
<tr>
<td style="padding:10px 14px;font-size:13px;color:#666;background-color:#fafafa;border-bottom:1px solid #eaeaea;">Verdict</td>
<td style="padding:10px 14px;font-size:13px;border-bottom:1px solid #eaeaea;"><span style="color:${MAL_COLOR};font-weight:600;">${MAL_TEXT}</span></td>
</tr>
<tr>
<td style="padding:10px 14px;font-size:13px;color:#666;background-color:#fafafa;border-bottom:1px solid #eaeaea;">Detection</td>
<td style="padding:10px 14px;font-size:13px;color:#c0392b;border-bottom:1px solid #eaeaea;font-weight:600;">${VT_POSITIVES} / ${VT_TOTAL} engines</td>
</tr>
<tr>
<td style="padding:10px 14px;font-size:13px;color:#666;background-color:#fafafa;border-bottom:1px solid #eaeaea;">Scan Date</td>
<td style="padding:10px 14px;font-size:13px;color:#1a1a1a;border-bottom:1px solid #eaeaea;">${VT_SCAN_DATE}</td>
</tr>
<tr>
<td style="padding:10px 14px;font-size:13px;color:#666;background-color:#fafafa;border-bottom:1px solid #eaeaea;">MD5</td>
<td style="padding:10px 14px;font-size:12px;color:#1a1a1a;border-bottom:1px solid #eaeaea;font-family:monospace;">${VT_MD5}</td>
</tr>
<tr>
<td style="padding:10px 14px;font-size:13px;color:#666;background-color:#fafafa;border-bottom:1px solid #eaeaea;">SHA-1</td>
<td style="padding:10px 14px;font-size:12px;color:#1a1a1a;border-bottom:1px solid #eaeaea;font-family:monospace;">${VT_SHA1}</td>
</tr>
<tr>
<td style="padding:10px 14px;font-size:13px;color:#666;background-color:#fafafa;">Full Report</td>
<td style="padding:10px 14px;font-size:13px;"><a href="${VT_PERMALINK}" style="color:#2563eb;text-decoration:none;">View on VirusTotal &rarr;</a></td>
</tr>
</table>
</td>
</tr>
VTBLOCK
fi)

<!-- Response Action -->
<tr>
<td style="padding:24px 32px 0 32px;">
<table width="100%" cellpadding="0" cellspacing="0" style="background-color:#eefbf3;border:1px solid #b8e6cc;border-radius:4px;">
<tr>
<td style="padding:12px 16px;font-size:13px;color:#1e7e46;">
<strong>Response Action:</strong> File has been automatically quarantined by active response.
</td>
</tr>
</table>
</td>
</tr>

<!-- Footer -->
<tr>
<td style="padding:28px 32px;border-top:1px solid #eaeaea;margin-top:24px;">
<p style="margin:0;font-size:11px;color:#999;line-height:1.6;">
This is an automated alert from Wazuh SIEM. Do not reply.<br>
Wazuh Security Operations Center
</p>
</td>
</tr>

</table>
</td></tr>
</table>

</body>
</html>
EOF
)

echo "$EMAIL_BODY" | /usr/sbin/sendmail -t

exit 0
