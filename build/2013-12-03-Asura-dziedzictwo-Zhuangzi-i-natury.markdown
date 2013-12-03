# Pobudki kierujące twórcą
Filozofia Asury, jako dystrybucji linuxa, jest punktem centralnym 
dla samej siebie. Asura istnieje jedynie z uwagi na nią.
Przez mój podziw dla naturalnych procesów, będzie starała 
się emulować niektóre. Jako niespełniony twórca hobbistycznego
OS'a, kernel oraz gentoo będzie w użyciu jako swoista abstrakcja
która dostarcza już dość wyabstrahowany i zdefiniowany proces czy plik.

# Budowa dystrybucji wraz z kernelem wraz z Gentoo
Postanowiłem, że tworzenie postępować będzie z ustaloną mapą 
budowy projektu: przystępny skrypt do budowy gentoo, z uwzględnieniem
kilku przygotowanych ustawień dla fazy kompilacji jądra i instalacji
pierwszych paczek, które będę ułożone w grupy, wraz z wieloma testami
dla sieci, generowaniem konfiguracji, zmiennych środowiskowych czy
kluczy użytkownika (SSH, PGP, etc.) będą pierwszym punktem do 
realizacji. Poniżej drobna prezentacja struktury pakietów z paczkami:
```shell
pack_gfx()
{
	pack_de () {
		install_gnome ()
		{
			...
			select GNOME in "${gnome[@]}"; do
				case "$REPLY" in
					1) ... ;;
					2) ... ;;
					*) ... ;;
				esac
			done
			...
		}
		...
	}
}
```
Pliki fazy budowy są podzielone na standardowe funkcje do
wywoływania powiadomień, wywoływania funkcji użycia pliku
z wykorzystaniem `source` etc., dokładną fazę budowy/instalacji,
w której wszystkie wyłowania komend powszechnych podczas instalacji
gentoo i kompilacji kernela są odseparowane i ułożone w 
funkcjach, które później są inicjowane w głównej funkcji.