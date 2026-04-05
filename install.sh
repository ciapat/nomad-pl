#!/bin/bash

# ==========================================
# Instalator Polskiego Węzła Przetrwania (N.O.M.A.D. PL)
# ==========================================

echo "=========================================="
echo " Witaj w instalatorze Polskiego N.O.M.A.D."
echo "=========================================="
echo ""

# ------------------------------
# 0. SPRAWDZANIE I INSTALACJA DOCKERA
# ------------------------------
echo "[*] Sprawdzanie obecności Dockera..."
if ! command -v docker &> /dev/null; then
    echo "[!] Docker nie jest zainstalowany. Rozpoczynam automatyczną instalację..."
    curl -fsSL https://get.docker.com -o get-docker.sh
    sudo sh get-docker.sh
    sudo usermod -aG docker $USER
    rm get-docker.sh
    echo "[+] Docker i Docker Compose zostały zainstalowane pomyślnie!"
    DOCKER_INSTALLED_JUST_NOW=true
else
    echo "[+] Docker jest już zainstalowany. Lecimy dalej."
    DOCKER_INSTALLED_JUST_NOW=false
fi
echo ""

# ------------------------------
# 1. STRUKTURA KATALOGÓW
# ------------------------------
echo "[*] Tworzenie struktury katalogów..."
mkdir -p nomad-pl/data/zim
mkdir -p nomad-pl/data/maps
cd nomad-pl || exit

# ------------------------------
# 2. WYBÓR WIKIPEDII (KIWIX)
# ------------------------------
echo ""
echo "Wybierz wersję polskiej Wikipedii / bazy wiedzy (Kiwix):"
echo "1) Wersja ALL MAXI (Pełna wersja, ~20 GB)"
echo "2) Wersja ALL NOPIC (Wszystkie artykuły, bez zdjęć, ~6.5 GB)"
echo "3) Wersja TOP MAXI (50 000 artykułów ze zdjęciami (~2.6 GB)"
echo "4) Pomiń pobieranie"
read -p "Twój wybór (1-4): " wiki_choice

# ------------------------------
# 3. WYBÓR MAP (PROTOMAPS)
# ------------------------------
echo ""
echo "Wybierz moduł map offline:"
echo "1) Pobierz i wygeneruj mapę Polski, ~4 GB"
echo "2) Pomiń moduł map"
read -p "Twój wybór (1-2): " map_choice

if [ "$map_choice" == "1" ]; then
    echo "[*] Przygotowuję narzędzie do wycinania mapy..."

    # Ustalenie  wczorajszej daty
    MAP_DATE=$(date -d "yesterday" +%Y%m%d)
    DATE_FILE="$(pwd)/data/maps/polska_date.txt"
    MAP_FILE="$(pwd)/data/maps/polska.pmtiles"

    # Sprawdzanie daty w pliku txt
    if [ -f "$DATE_FILE" ] && grep -q "$MAP_DATE" "$DATE_FILE"; then
        echo "[+] Aktualna mapa z dnia $MAP_DATE już istnieje na dysku!"
        echo "[+] Pomijam ponowne pobieranie."
    else
        echo "[*] Brak najnowszej mapy. Szukam na serwerze pliku z dnia: $MAP_DATE"

        # Usuwanie starej mapy PRZED pobraniem nowej (żeby nie zapchać dysku)
        if [ -f "$MAP_FILE" ]; then
            echo "[*] Usuwanie starej wersji mapy, aby zwolnić miejsce na dysku..."
            rm -f "$MAP_FILE"
        fi

        # Wycinanie mapy z zapisem do stałej nazwy polska.pmtiles
        sudo docker run --rm -v $(pwd)/data/maps:/data protomaps/go-pmtiles extract https://build.protomaps.com/${MAP_DATE}.pmtiles /data/polska.pmtiles --bbox=14.0,48.9,24.2,54.9

        # Zmiana uprawnień
        sudo chown $USER:$USER "$MAP_FILE"

        # Zapisanie nowej daty do pliku txt (i zmiana uprawnień)
        echo "$MAP_DATE" > "$DATE_FILE"
        sudo chown $USER:$USER "$DATE_FILE"

        echo "[+] Nowa mapa Polski została pomyślnie wygenerowana!"
    fi
fi
# ------------------------------
# 4. GENEROWANIE DOCKER-COMPOSE
# ------------------------------
echo ""
echo "[*] Generowanie pliku konfiguracyjnego docker-compose.yml..."

cat <<EOF > docker-compose.yml
services:
  kiwix:
    image: ghcr.io/kiwix/kiwix-serve
    container_name: nomad-wikipedia
    volumes:
      - ./data/zim:/data
    command: "*.zim"
    ports:
      - "8081:8080"
    restart: unless-stopped
EOF

#if [ "$map_choice" == "1" ]; then
cat <<EOF >> docker-compose.yml

  maps:
    image: protomaps/go-pmtiles
    container_name: nomad-maps
    volumes:
      - ./data/maps:/data
    command: serve --cors="*" /data
    ports:
      - "8082:8080"
    restart: unless-stopped
EOF
#fi

cat <<EOF >> docker-compose.yml

  portal:
    image: nginx:alpine
    container_name: nomad-portal
    volumes:
      - ./portal:/usr/share/nginx/html:ro
    ports:
      - "80:80"
    restart: unless-stopped
EOF

echo "[+] Plik docker-compose.yml wygenerowany pomyślnie."

# ------------------------------
# 5. POBIERANIE BAZY WIEDZY
# ------------------------------
echo ""
echo "[*] Rozpoczynam proces pobierania baz wiedzy (z limitem 5MB/s)..."
# Limit prędkości dodany, by chronić pendrive'y przed błędem I/O

case $wiki_choice in
    1)
        echo "Pobieranie Wikipedii ALL MAXI..."
        # Zmieniony link na działający symlink do najnowszej wersji mini
        wget --limit-rate=5m -c -P ./data/zim "https://download.kiwix.org/zim/wikipedia/wikipedia_pl_all_maxi_2026-02.zim"
        ;;
    2)
        echo "Pobieranie Wikipedii ALL NOPIC..."
        wget --limit-rate=5m -c -P ./data/zim "https://download.kiwix.org/zim/wikipedia/wikipedia_pl_all_nopic_2026-02.zim"
        ;;
    3)
        echo "Pobieranie Wikipedii TOP MAXI..."
        wget --limit-rate=5m -c -P ./data/zim "https://download.kiwix.org/zim/wikipedia/wikipedia_pl_top_maxi_2026-01.zim"
        ;;
    4)
        echo "Pominięto pobieranie Wikipedii."
        ;;
    *)
        echo "Nieznany wybór. Pomijam pobieranie."
        ;;
esac

echo "========================================"
echo " Ustawianie prywatnej sieci (Tryb AP)   "
echo "========================================"

# Usuwamy starą sieć, jeśli skrypt jest uruchamiany ponownie
sudo nmcli connection delete NOMAD_WIFI 2>/dev/null || true

echo "Konfiguruję własny punkt dostępowy Wi-Fi (NOMAD_WIFI)..."

# Tworzymy profil nowej sieci
sudo nmcli connection add type wifi ifname wlan0 con-name NOMAD_WIFI autoconnect yes ssid NOMAD_WIFI
sudo nmcli connection modify NOMAD_WIFI 802-11-wireless.mode ap 802-11-wireless.band bg ipv4.method shared
sudo nmcli connection modify NOMAD_WIFI wifi-sec.key-mgmt wpa-psk
sudo nmcli connection modify NOMAD_WIFI wifi-sec.psk "Nomad123"

echo "========================================"
echo " INSTALACJA ZAKOŃCZONA SUKCESEM!        "
echo "========================================"
echo "Baza wiedzy (Wikipedia) i Mapy są gotowe do działania."
echo ""
echo "Aby odciąć się od domowego routera i uruchomić własną sieć Wi-Fi,"
echo "wpisz teraz w terminalu:"
echo "sudo nmcli connection up NOMAD_WIFI"
echo ""
echo "UWAGA: Jeśli jesteś podłączony do Malinki przez Wi-Fi, po wpisaniu"
echo "tej komendy terminal natychmiast zamarznie! Połącz się wtedy z poziomu"
echo "telefonu lub komputera z nową siecią NOMAD_WIFI (hasło: Nomad123)"
echo "i wpisz w przeglądarce żelazny adres Twojego Węzła Przetrwania:"
echo "👉 http://10.42.0.1"
echo "========================================"

# ------------------------------
# 6. PODSUMOWANIE
# ------------------------------
echo ""
echo "================================================"
echo " Instalacja wstępna zakończona!"

echo " 1. Przejdź do folderu 'nomad-pl': cd nomad-pl"
echo " 2. Uruchom serwer komendą: docker compose up -d"
echo "================================================"
