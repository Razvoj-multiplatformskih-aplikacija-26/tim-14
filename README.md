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
