import os
import random
import string
import urllib.request
import json

BREVO_API_KEY = os.getenv("BREVO_API_KEY")

def generate_otp(length=6) -> str:
    return ''.join(random.choices(string.digits, k=length))

def send_email_via_brevo(to_email: str, subject: str, html_content: str):
    if not BREVO_API_KEY:
        print(f"[EMAIL] ⚠️  BREVO_API_KEY not set — email NOT sent to {to_email} (subject: '{subject}')")
        return

    url = "https://api.brevo.com/v3/smtp/email"
    headers = {
        "accept": "application/json",
        "api-key": BREVO_API_KEY,
        "content-type": "application/json"
    }
    payload = {
        "sender": {"name": "Task Manager", "email": "contact@abhinav-yadav.me"},
        "to": [{"email": to_email}],
        "subject": subject,
        "htmlContent": html_content
    }

    req = urllib.request.Request(url, data=json.dumps(payload).encode('utf-8'), headers=headers, method='POST')
    try:
        response = urllib.request.urlopen(req)
        print(f"[EMAIL] ✅  Email sent successfully to {to_email} (subject: '{subject}') — status: {response.status}")
    except urllib.error.HTTPError as e:
        error_body = e.read().decode()
        print(f"[EMAIL] ❌  Brevo HTTP error sending to {to_email}: {e.code} — {error_body}")
    except Exception as e:
        print(f"[EMAIL] ❌  Failed to send email to {to_email}: {e}")
