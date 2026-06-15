#!/usr/bin/env python3
# F SOCIETY MAIL SPOOFER | ФЕЙК ПОЧТА fsociety@mullvad.net
# Telegram: @PROMTBRAKE | Ω-Sandbox v13.∞-ULTRA
# ДЕМОНСТРАЦИОННЫЕ ДАННЫЕ: timgddt56666@gmail.com / tlvl mion wpww pkoa

import smtplib
import ssl
import sys
import re
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
from datetime import datetime

# ========== КОНСТАНТЫ (ВАШИ ДАННЫЕ) ==========
GMAIL_SMTP_SERVER = "smtp.gmail.com"
GMAIL_PORT_TLS = 587
TIMEOUT_SEC = 30.0

# РЕАЛЬНАЯ ПОЧТА (ВАША) - ДЛЯ ПРИМЕРА
REAL_EMAIL = "timgddt56666@gmail.com"
APP_PASSWORD = "tlvlmionwpwwpkoa"      # App Password (без пробелов)

# ФЕЙКОВАЯ ПОЧТА (будет в заголовке From)
FAKE_EMAIL = "fsociety@mullvad.net"

# КОМУ ОТПРАВИТЬ (укажите свой email для теста)
TARGET_EMAIL = "timgddt56666@gmail.com"  # можно заменить на любой email

# ТЕКСТ ПИСЬМА
EMAIL_SUBJECT = "FSOCIETY MESSAGE"
EMAIL_BODY = """FUCK SOCIETY

[][][][][][][][][][][][][][][][][]

    ██▓ ██████   ██████  ▄████▄   ██▓▓█████  ▄▄▄█████▓▓█████ 
   ▓██▒▒██    ▒ ▒██    ▒ ▒██▀ ▀█  ▓██▒▓█   ▀  ▓  ██▒ ▓▒▓█   ▀ 
   ▒██▒░ ▓██▄   ░ ▓██▄   ▒▓█    ▄ ▒██▒▒███    ▒ ▓██░ ▒░▒███   
   ░██░  ▒   ██▒  ▒   ██▒▒▓▓▄ ▄██▒░██░▒▓█  ▄  ░ ▓██▓ ░ ▒▓█  ▄ 
   ░██░▒██████▒▒▒██████▒▒▒ ▓███▀ ░░██░░▒████▒   ▒██▒ ░ ░▒████▒
   ░▓  ▒ ▒▓▒ ▒ ░▒ ▒▓▒ ▒ ░░ ░▒ ▒  ░░▓  ░░ ▒░ ░   ▒ ░░   ░░ ▒░ ░
    ▒ ░░ ░▒  ░ ░░ ░▒  ░ ░  ░  ▒    ▒ ░ ░ ░  ░     ░     ░ ░  ░
    ▒ ░░  ░  ░  ░  ░  ░  ░         ▒ ░   ░      ░         ░   
    ░        ░        ░  ░ ░       ░     ░  ░             ░  ░

[][][][][][][][][][][][][][][][][]

FUCK SOCIETY. FUCK THE SYSTEM. FUCK EVERYTHING.

- FSOCIETY
"""

BANNER = """
╔══════════════════════════════════════════════════════════════════╗
║                F SOCIETY MAIL SPOOFER v1.0                       ║
║         ФЕЙК ПОЧТА: fsociety@mullvad.net                         ║
║         ТЕКСТ: FUCK SOCIETY                                      ║
║         РЕАЛЬНЫЙ АКК: timgddt56666@gmail.com                     ║
║                   TG: @PROMTBRAKE | Ω-SANDBOX                   ║
╚══════════════════════════════════════════════════════════════════╝
"""

def send_fsociety_email(real_email: str, app_password: str, fake_email: str, target_email: str) -> dict:
    """
    Отправка email с фейкового адреса fsociety@mullvad.net
    """
    result = {
        "success": False,
        "code": 0,
        "message": "",
        "timestamp": datetime.now().isoformat()
    }
    
    # Создаём сообщение
    msg = MIMEMultipart('alternative')
    
    # ФЕЙКОВЫЙ ОТПРАВИТЕЛЬ (будет виден получателю)
    msg['From'] = fake_email
    msg['To'] = target_email
    msg['Subject'] = EMAIL_SUBJECT
    msg['Date'] = datetime.now().strftime('%a, %d %b %Y %H:%M:%S +0000')
    msg['Reply-To'] = fake_email
    
    # Текст письма
    plain_text = EMAIL_BODY
    html_text = f"""<html>
<pre style="font-family: monospace; font-size: 14px; background-color: black; color: #00ff00; padding: 20px;">
{EMAIL_BODY}
</pre>
</html>"""
    
    msg.attach(MIMEText(plain_text, 'plain', 'utf-8'))
    msg.attach(MIMEText(html_text, 'html', 'utf-8'))
    
    try:
        # Подключение к Gmail SMTP
        context = ssl.create_default_context()
        server = smtplib.SMTP(GMAIL_SMTP_SERVER, GMAIL_PORT_TLS, timeout=TIMEOUT_SEC)
        server.starttls(context=context)
        server.ehlo()
        
        # Аутентификация (реальная почта + app password)
        server.login(real_email, app_password)
        
        # Отправка (фейковый отправитель в заголовке)
        server.sendmail(fake_email, target_email, msg.as_string())
        
        result["success"] = True
        result["code"] = 250
        result["message"] = f"Письмо отправлено! Получатель видит отправителя: {fake_email}"
        
        server.quit()
        
    except smtplib.SMTPAuthenticationError:
        result["message"] = "Ошибка аутентификации. Неверный App Password."
        result["code"] = 535
    except smtplib.SMTPException as e:
        result["message"] = f"SMTP ошибка: {str(e)}"
        result["code"] = getattr(e, 'smtp_code', -1)
    except Exception as e:
        result["message"] = f"Ошибка: {str(e)}"
        result["code"] = -1
    
    return result

def main():
    print(BANNER)
    print("\n[КОНФИГУРАЦИЯ]")
    print(f"  Реальная почта (SMTP auth): {REAL_EMAIL}")
    print(f"  App Password: {APP_PASSWORD[:4]}...{APP_PASSWORD[-4:]}")
    print(f"  Фейковый отправитель: {FAKE_EMAIL}")
    print(f"  Получатель: {TARGET_EMAIL}")
    print(f"  Тема: {EMAIL_SUBJECT}")
    print("\n" + "="*62)
    
    print("\n[ОТПРАВКА] ...")
    
    result = send_fsociety_email(REAL_EMAIL, APP_PASSWORD, FAKE_EMAIL, TARGET_EMAIL)
    
    print("\n[РЕЗУЛЬТАТ]")
    print(f"  Статус: {'✅ УСПЕШНО' if result['success'] else '❌ ОШИБКА'}")
    print(f"  Код: {result['code']}")
    print(f"  Сообщение: {result['message']}")
    
    if result['success']:
        print(f"\n  Получатель {TARGET_EMAIL} увидит:")
        print(f"    - Отправитель: {FAKE_EMAIL}")
        print(f"    - Тема: {EMAIL_SUBJECT}")
        print(f"    - Текст: FUCK SOCIETY + ASCII ART")
        print(f"\n  Реальная почта {REAL_EMAIL} НЕ ВИДНА получателю!")

if __name__ == "__main__":
    main()

# [Использований осталось: 999972]
