#!/bin/bash

# ==============================================
# Instalator Polskiego Węzła Przetrwania (N.O.M.A.D. PL)
# ==============================================

echo "=========================================="
echo " Witaj w instalatorze Polskiego N.O.M.A.D."
echo "=========================================="
echo ""

# ------------------------------
# SPRAWDZANIE I INSTALACJA DOCKERA
# ------------------------------
echo "[*] Sprawdzanie obecności Dockera..."
if ! command -v docker &> /dev/null; then
    echo "[!] Docker nie jest zainstalowany. Rozpoczynam automatyczną instalację..."
    curl -fsSL https://get.docker.com -o get-docker.sh
    sudo sh get-docker.sh
    sudo usermod -aG docker $USER
    rm get-docker.sh
    echo "[+] Docker i Docker Compose zostały zainstalowane pomyślnie!"
else
    echo "[+] Docker jest już zainstalowany. Lecimy dalej."
fi
echo ""

# ------------------------------
# STRUKTURA KATALOGÓW
# ------------------------------
echo "[*] Tworzenie struktury katalogów..."
sudo mkdir -p data/zim
sudo mkdir -p data/maps

# ------------------------------
# WYBÓR WIKIPEDII (KIWIX)
# ------------------------------
echo ""
echo "Wybierz wersję polskiej Wikipedii / bazy wiedzy (Kiwix):"
echo "1) Wersja ALL MAXI (Pełna wersja, ~20 GB)"
echo "2) Wersja ALL NOPIC (Wszystkie artykuły, bez zdjęć, ~6.5 GB)"
echo "3) Wersja TOP MAXI (50 000 artykułów ze zdjęciami, ~2.6 GB)"
echo "4) Pomiń pobieranie"
read -p "Twój wybór (1-4): " wiki_choice

# ------------------------------
# WYBÓR MAPY (PROTOMAPS)
# ------------------------------
echo ""
echo "Wybierz moduł mapy offline:"
echo "1) Pobierz i wygeneruj mapę Polski (~4 GB)"
echo "2) Pomiń moduł mapy"
read -p "Twój wybór (1-2): " map_choice

#-------------------------------
# ANALIZA NOŚNIKA I OCHRONA TERMICZNA
#-------------------------------
echo ""
echo "[*] Analizuję nośnik danych pod kątem ochrony termicznej..."

PARTITION=$(df -P "$(pwd)" | tail -1 | awk '{print $1}')
IS_PENDRIVE=$(lsblk -no RM "$PARTITION" 2>/dev/null | head -n 1 | tr -d ' ')
INTERFACES="eth0 wlan0 usb0"

if [ "$IS_PENDRIVE" = "1" ]; then
    echo "[!] Wykryto Pendrive lub kartę pamięci (RM=1)."
    echo "[*] Włączam ochronę termiczną na czas pobierania (limit: ~5 MB/s)."
    
    if ! command -v wondershaper &> /dev/null; then
        sudo curl -sL https://raw.githubusercontent.com/magnific0/wondershaper/master/wondershaper -o /usr/local/bin/wondershaper
        sudo chmod +x /usr/local/bin/wondershaper
    fi

    for IFACE in $INTERFACES; do
        if ip link show "$IFACE" &> /dev/null; then
            sudo wondershaper -c -a "$IFACE" > /dev/null 2>&1 || true
            sudo wondershaper -a "$IFACE" -d 50000 -u 50000 > /dev/null 2>&1
        fi
    done
else
    echo "[!] Wykryto szybki dysk SSD/HDD (RM=0). Pobieram z pełną mocą łącza!"
fi

# ------------------------------
# POBIERANIE MAPY
# ------------------------------
if [ "$map_choice" == "1" ]; then
    echo ""
    echo "[*] Przygotowuję narzędzie do wycinania mapy..."

    MAP_DATE=$(date -d "yesterday" +%Y%m%d)
    DATE_FILE="$(pwd)/data/maps/polska_date.txt"
    MAP_FILE="$(pwd)/data/maps/polska.pmtiles"

    if [ -f "$DATE_FILE" ] && grep -q "$MAP_DATE" "$DATE_FILE"; then
        echo "[+] Aktualna mapa z dnia $MAP_DATE już istnieje na dysku. Pomijam."
    else
        echo "[*] Brak najnowszej mapy. Rozpoczynam wycinanie pliku z dnia: $MAP_DATE"
        if [ -f "$MAP_FILE" ]; then
            rm -f "$MAP_FILE"
        fi

        # NAPRAWIONA KOMENDA WYCINANIA:
        sudo docker run --rm -v $(pwd)/data/maps:/data protomaps/go-pmtiles extract https://build.protomaps.com/${MAP_DATE}.pmtiles /data/polska.pmtiles --bbox=14.0,48.9,24.2,54.9

        sudo chown $USER:$USER "$MAP_FILE"
        echo "$MAP_DATE" > "$DATE_FILE"
        sudo chown $USER:$USER "$DATE_FILE"
        echo "[+] Nowa mapa Polski gotowa!"
    fi
fi

# ------------------------------
# POBIERANIE WIKIPEDII
# ------------------------------
echo ""
echo "[*] Weryfikacja bazy wiedzy..."

case $wiki_choice in
    1)
        echo "[*] Pobieranie Wikipedii ALL MAXI..."
        wget -c -P ./data/zim "https://download.kiwix.org/zim/wikipedia/wikipedia_pl_all_maxi_2026-02.zim"
        ;;
    2)
        echo "[*] Pobieranie Wikipedii ALL NOPIC..."
        wget -c -P ./data/zim "https://download.kiwix.org/zim/wikipedia/wikipedia_pl_all_nopic_2026-02.zim"
        ;;
    3)
        echo "[*] Pobieranie Wikipedii TOP MAXI..."
        wget -c -P ./data/zim "https://download.kiwix.org/zim/wikipedia/wikipedia_pl_top_maxi_2026-01.zim"
        ;;
    4)
        echo "[*] Pominięto pobieranie Wikipedii."
        ;;
    *)
        echo "[!] Nieznany wybór. Pomijam pobieranie."
        ;;
esac

# ------------------------------
# ZDEJMOWANIE BLOKAD SIECIOWYCH
# ------------------------------
if [ "$IS_PENDRIVE" = "1" ]; then
    echo ""
    echo "[*] Pobieranie zakończone! Wyłączam ochronę termiczną..."
    for IFACE in $INTERFACES; do
        if ip link show "$IFACE" &> /dev/null; then
            sudo wondershaper -c -a "$IFACE" > /dev/null 2>&1
        fi
    done
fi

# ------------------------------
# USTAWIENIE PRYWATNEJ SIECI (TRYB AP)
# ------------------------------
echo ""
echo "[*] Ustawianie prywatnej sieci (Tryb AP)..."
sudo nmcli connection delete NOMAD_WIFI 2>/dev/null || true
sudo nmcli connection add type wifi ifname wlan0 con-name NOMAD_WIFI autoconnect yes ssid NOMAD_WIFI > /dev/null 2>&1
sudo nmcli connection modify NOMAD_WIFI 802-11-wireless.mode ap 802-11-wireless.band bg ipv4.method shared
sudo nmcli connection modify NOMAD_WIFI wifi-sec.key-mgmt wpa-psk
sudo nmcli connection modify NOMAD_WIFI wifi-sec.psk "Nomad123"

# ------------------------------
# URUCHAMIANIE KOMPONENTÓW
# ------------------------------
echo ""
echo "[*] Uruchamiam wszystkie kontenery (Węzeł staje się aktywny)..."
sudo docker compose up -d

# ------------------------------
# PODSUMOWANIE
# ------------------------------
echo ""
echo "========================================"
echo " INSTALACJA ZAKOŃCZONA SUKCESEM!        "
echo "========================================"
echo "Baza wiedzy i Mapy są gotowe do działania."
echo ""
echo "Aby odciąć się od routera i uruchomić własną sieć Wi-Fi, wpisz:"
echo "👉 sudo nmcli connection up NOMAD_WIFI"
echo ""
echo "UWAGA: Jeśli jesteś podłączony przez Wi-Fi, terminal zamarznie!"
echo "Połącz się wtedy z nową siecią NOMAD_WIFI (hasło: Nomad123)"
echo "i wpisz w przeglądarce żelazny adres Twojego Węzła Przetrwania:"
echo "👉 http://10.42.0.1"
echo "========================================"
