# Platforma za privatne casove

Projekat iz predmeta Razvoj multiplatformskih aplikacija

## Članovi tima

| Ime i prezime | Broj indeksa | GitHub |
|---|---|---|
| Dimitrije Stepanovic | 97/24 SI | dxmv |
| Ilija Pavlovic | 66/24 SI | bgilija |

## Opis sistema

Platforma povezuje profesore i nastavnike koji drže privatne časove sa učenicima i studentima kojima treba pomoć iz nekog predmeta ili priprema za prijemni ispit. Profesor objavljuje oglase. Svaki oglas pokriva jedan predmet ili oblast i ima opis, nivo i cenu časa, a u okviru njega profesor nudi slobodne termine. Jedan profesor može imati više oglasa, a termini iz svih njegovih oglasa dele isti kalendar.

Učenik pregleda profil profesora (osnovni podaci, obrazovanje, radno iskustvo, oglasi sa cenama i recenzije), bira termin i šalje zahtev za čas uz kratku poruku o tome šta mu je potrebno. Posle održanog časa učenik može da ostavi recenziju. Administrator proverava podatke koje profesor navodi, diplomu i LinkedIn profil, i profesoru čiji su podaci potvrđeni dodeljuje oznaku verifikovanog profesora.

Glavni pojam sistema je čas; zahtev učenika, beleška sa časa i recenzija vezuju se za njegov zapis.

## Ispunjenost zahteva

**1. Uloge.** Sistem ima četiri uloge sa različitim ovlašćenjima: posetilac (pregleda javne profile i oglase), učenik (zakazuje časove i ostavlja recenzije), profesor (objavljuje oglase i termine, potvrđuje zahteve i beleži održane časove) i administrator (verifikuje profesore i moderiše recenzije).

**2. Stanja.** Čas prolazi kroz stanja: na čekanju, potvrđen, održan i otkazan, uz sporedna stanja odbijen i neodržan (učenik se nije pojavio). Profil profesora ima zaseban tok verifikacije: neverifikovan, na proveri, verifikovan ili odbijen.

**3. Pravila.** Učenik može imati najviše tri zahteva na čekanju, čas se otkazuje najkasnije 24 sata pre početka, a recenziju može ostaviti samo učenik čiji je čas kod tog profesora označen kao održan, i to jednu po času. O terminu odlučuje server: više učenika može zatražiti isti termin, ali kada profesor potvrdi jedan zahtev, ostali se automatski odbijaju, a ako učenik povuče zahtev u istom trenutku kada ga profesor potvrđuje, server odlučuje koja izmena važi.

**4. Rad bez mreže.** Profesor koji drži čas uživo, kod učenika ili u čitaonici, na kraju časa i bez mreže označava čas kao održan i upisuje kratku belešku o pređenom gradivu. Učenik bez mreže može da otkaže čas ili napiše recenziju, a izmene se šalju serveru po povratku mreže.

**5. Posao za osoblje.** Administrator radi sa redom zahteva za verifikaciju, u kome uporedo pregleda priloženu diplomu, LinkedIn profil i podatke koje je profesor uneo. Radi i sa pregledom svih profesora, oglasa i prijavljenih recenzija za moderaciju, što zahteva veći ekran.

**6. Javni sadržaj.** Bez prijave su dostupni profili profesora i stranice oglasa sa opisom, cenom i recenzijama, kao i pregled oglasa po predmetu i gradu. Stranica oglasa, na primer „matematika za prijemni, Beograd", upravo je ono što ljudi traže preko pretraživača kada im treba profesor.

## Server

Server je Dart aplikacija na Relic-u u `apps/server`, nad PostgreSQL bazom. Šema se pravi iz migracija u `apps/server/migrations` (dbmate), a pri prvom pokretanju nad praznom bazom server upisuje demo podatke. Lozinke se čuvaju samo kao Argon2id heš.

- **Ista pravila.** Pre svakog upisa server izvršava isti kod iz paketa `domain` i `use_cases` kao i aplikacije. Da termin ima najviše jedan potvrđen čas, i koja izmena važi kada se povlačenje zahteva i potvrda dese u istom trenutku, odlučuje baza: jedinstveni indeks i uslovni UPDATE.
- **Ugovor.** Paket `api_contract` sadrži oblik poruka i kodove grešaka, `api_mapping` prevodi domen u poruke i nazad, a `api_client` je zajednički klijent obe aplikacije. Greška stiže kao kod sa podacima, a tekst poruke sastavlja aplikacija.
- **Prijava.** Sesija je JWT token. U pregledaču se čuva u HttpOnly kolačiću, a na telefonu i desktopu u sigurnom skladištu iza `TokenStore` porta. Ističe posle `SESSION_TTL_MINUTES` minuta. Uloge i vlasništvo proverava `AccessPolicy` iz paketa `domain`, i na serveru i u obe aplikacije; tuđ čas server vraća kao 404.
- **Spoljni servis.** Email preko Resend-a, iza `Mailer` porta, poziva samo server. Šalje se kada učenik zatraži čas i kada profesor zahtev potvrdi (tada i učenicima čiji su zahtevi automatski odbijeni) ili odbije. Bez ključa (`RESEND_API_KEY` prazan) server email samo upisuje u svoj log. Sa ključem sav email ide na `MAIL_TO`, jer Resend-ov probni pošiljalac isporučuje samo na adresu sa kojom je nalog otvoren.
- Rad bez mreže (zahtev 4) nije deo KT2.

## Pokretanje

Potrebni su Docker (sa Compose-om) i Flutter (stable).

**1. Server i baza.** Iz korena repozitorijuma, jednom:

    cp .env.example .env

Zatim jednom komandom baza, migracije i server:

    docker compose up -d

Provera: `docker compose ps -a` (servis `migrate` je završio sa `Exited (0)`, a `db` i `server` rade) i

    curl localhost:8080/health

koji vraća `ok`.

Ispočetka, sa svežim demo podacima:

    docker compose down -v
    docker compose up -d

Vremena časova u demo podacima računaju se od trenutka upisa, pa bazu treba osvežiti pred demo.

Pregled baze u Adminer-u, po potrebi: `docker compose --profile tools up -d adminer`, pa http://localhost:8082.

**2. Aplikacije.** Zavisnosti se preuzimaju jednom, iz korena repozitorijuma:

    flutter pub get

Mobilna aplikacija (Android emulator, koji server vidi na `10.0.2.2:8080`):

    cd apps/mobile
    flutter run

Na pravom telefonu treba dodati adresu računara, na primer `--dart-define=SERVER_URL=http://192.168.1.10:8080`.

Backoffice na desktopu:

    cd apps/backoffice
    flutter run -d windows

Za Windows je potreban Visual Studio 2022 sa „Desktop development with C++“, a za `-d macos` Xcode.

Backoffice u pregledaču (port 8081 je adresa dozvoljena u `CORS_ORIGINS`):

    cd apps/backoffice
    flutter run -d chrome --web-port 8081

Obe aplikacije mogu da se pokrenu i bez servera, nad demo podacima iz KT1: `--dart-define=FAKE_DATA=true`.

## Demo nalozi

Lozinka svih naloga je `DEMO_PASSWORD` iz `.env` (`casovi-demo` u `.env.example`).

| Prijava | Korisnik | Uloga | Aplikacija |
|---|---|---|---|
| `ucenik1` | Ana Marković | učenik | mobilna |
| `ucenik2` | Nikola Petrović | učenik | mobilna |
| `profesor1` | Milica Jovanović | profesor | backoffice |
| `admin1` | Jovana Ilić | administrator | backoffice |

## Testovi

Testovi se pokreću iz foldera paketa: `dart test` u `domain`, `use_cases`, `blocs`, `api_contract`, `api_mapping` i `api_client`, a `flutter test` u `ui` i u obe aplikacije.

Testovi servera sa oznakom `db` traže bazu. Prvo `docker compose up -d db`, pa u `apps/server`:

    dart test

Bez baze, kao u CI-ju: `dart test -x db`.

