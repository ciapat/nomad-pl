# N.O.M.A.D. PL - Polski Węzeł Przetrwania 🏕️📡

**N.O.M.A.D.** (Network of Offline Maps and Data) to system klasy *off-grid*, zaprojektowany do działania w sytuacjach kryzysowych, na wyprawach survivalowych lub w miejscach pozbawionych dostępu do globalnego internetu.

Projekt przekształca komputer Raspberry Pi (lub inny sprzęt z systemem Linux) w **samowystarczalny, przenośny serwer wiedzy**, który nadaje własną sieć Wi-Fi i udostępnia zasoby ratunkowe, mapy i encyklopedie każdemu w pobliżu.

---

## ✨ Główne funkcje systemu

* 📡 **Tryb Access Point (Własne Wi-Fi)** - Malinka automatycznie odcina się od routera i tworzy własną, otwartą sieć ratunkową `NOMAD_WIFI`.
* 🗺️ **Mapy Offline (Protomaps)** - System w locie pobiera, wycina i kompresuje wektorową mapę Polski, ładującą się błyskawicznie na każdym urządzeniu.
* 📚 **Baza Wiedzy (Kiwix)** - Dostęp do pełnej polskiej Wikipedii, poradników medycznych i survivalowych – wszystko zrzucane na dysk.
* 🛡️ **Inteligentna ochrona termiczna** - Skrypt sam wykrywa, czy używasz metalowego pendrive'a czy dysku SSD. Jeśli wykryje pendrive'a, nakłada inteligentny kaganiec na kartę sieciową (`wondershaper`), zapobiegając przegrzaniu nośnika podczas zapisywania gigabajtów danych.
* 🐳 **Architektura Dockerowa** - Wszystko jest konteneryzowane, bezpieczne i gotowe do uruchomienia jednym skryptem.

---

## 🛠️ Wymagania sprzętowe

1. **Raspberry Pi** (Zalecane RPi 3/4/5) lub dowolny minikomputer z kartą Wi-Fi.
2. **System operacyjny:** Oparty na Debianie (np. Raspberry Pi OS / Debian Trixie).
3. **Nośnik danych:** Karta SD, Pendrive (min. 32GB) lub Dysk SSD podłączony po USB.

---

## 🚀 Instalacja

Budowa Węzła Przetrwania została sprowadzona do absolutnego minimum. Skrypt konfiguracyjny automatyzuje cały proces.

1. Sklonuj to repozytorium na swoje urządzenie:
   ```bash
   git clone https://github.com/ciapat/nomad-pl.git
   cd nomad-pl

2. Uruchom inteligentny instalator:
   ```bash
   sudo bash install.sh

3. Postępuj zgodnie z instrukcjami na ekranie. Skrypt zapyta Cię, jaką wersję Wikipedii pobrać i czy wygenerować najnowszą mapę topograficzną Polski.

## 🏕️ Uruchomienie Węzła (Tryb Terenowy)
Gdy instalator pobierze wszystkie dane, jesteś gotowy do przejścia w tryb off-grid.

Wpisz w terminalu:

    sudo nmcli connection up NOMAD_WIFI
      
(Uwaga: W tym momencie terminal zamarznie, jeśli byłeś połączony przez Wi-Fi – urządzenie właśnie odcięło się od internetu).

Jak z tego korzystać?
Podłącz urządzenie do powerbanka.

Na dowolnym telefonie lub laptopie wyszukaj sieć Wi-Fi o nazwie NOMAD_WIFI i połącz się z nią (Hasło: Nomad123).

Otwórz przeglądarkę i wpisz żelazny adres Węzła:
👉 http://10.42.0.1

Zobaczysz Panel Dowodzenia z dostępem do map offline i bazy wiedzy Kiwix.

## 🧠 Rozwiązywanie problemów (FAQ)
Q: Mój pendrive robi się gorący podczas instalacji.
A: Spokojnie. Skrypt automatycznie wykrywa pendrive'y i dławi prędkość pobierania do 5 MB/s na wszystkich interfejsach sieciowych, aby zapobiec przepaleniu kości pamięci.

Q: Jak zaktualizować dane, skoro system nie ma internetu?
A: Podepnij Węzeł kablem (Ethernet) do domowego routera. System będzie jednocześnie udostępniał sieć NOMAD_WIFI i miał dostęp do świata po kablu, co pozwoli na pobranie nowych modułów.

Q: Chcę, aby sieć była otwarta (bez hasła) dla każdego.
A: W pliku install.sh znajdź sekcję odpowiadającą za tryb AP i usuń dwie linijki z wifi-sec. Pamiętaj jednak, że zbyt duża liczba podłączonych na raz osób może wydrenować powerbanka!

Stworzone z pasją do niezależności i dzielenia się wiedzą. Bądź gotów na wszystko!
