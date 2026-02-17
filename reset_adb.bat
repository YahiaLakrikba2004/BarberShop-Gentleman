@echo off
echo ==========================================
echo      RESET ADB E CONTROLLO XIAOMI
echo ==========================================
echo.
echo 1. Chiudo server ADB bloccati...
"C:\Users\lakri\AppData\Local\Android\Sdk\platform-tools\adb.exe" kill-server

echo 2. Riavvio ADB...
"C:\Users\lakri\AppData\Local\Android\Sdk\platform-tools\adb.exe" start-server

echo 3. LISTA DISPOSITIVI CONNESSI:
echo ------------------------------------------
"C:\Users\lakri\AppData\Local\Android\Sdk\platform-tools\adb.exe" devices
echo ------------------------------------------
echo.
echo SE LA LISTA E' VUOTA:
echo   - Controlla che il tablet sia SBLOCCATO.
echo   - Tira giu la tendina: E' ancora su "Trasferimento File"? (Spesso torna su Ricarica da solo).
echo   - Se vedi "unauthorized", guarda il tablet e premi OK sul popup.
echo.
pause
