/*
5_12_2m
NR2
Dorim sa imbunatatim experienta platformei noastre,
asa ca dorim sa aflam urmatoarele statistici
pentru fiecare tara (Orders. ShipCountry):
- Cati clienti au dat macar o comanda pentru o alta
adresa decat a lor, in ultimul an (ultimul an in care
s-au facut comenzi) = 1p
- Care sunt top 3 curieri (Shippers.CompanyName) cu
livrari rapide; o livrare este rapida daca comanda
a fost livrata in cel mult 2 zile daca se livreaza
in alt oras fata de cel din care a plecat comanda,
3 zile daca este aceasi regiune, altfel 5 = 2p
- Daca top 3 cei mai ocupati angajati (angajatii care
au comenzi cu cele mai multe iteme "Order Details".
Quantity) in ultimul an sunt manageri sau nu "Da/Nu".
Un angajat este manager daca id-ul lui apare si in
coloana "Reports To❞ = 3p
- Top 3 categorii cu continuitate (exista minim un
client care comanda din aceasta categorie in luni
consecutive, se permit 3 luni care lipsesc, dar nu
2 consecutive in care sa lipseasca din comenzi) din
punct de vedere al numarului de unitati vandute,
pentru ultimii 2 ani = 4p
- Afisare si precizari extra:
- Daca cumva nu sunt, deloc, astfel de informatii
(categorii, produse, etc) afisati
- Daca cumva nu sunt 3, afisati cate sunt,
separate prin ";"
- Vom afisa pentru fiecare tara aceste informatii,
pe un singur rand
- Exemplu afisare:
- Nume Tara, NumarClientiComandaAltundeva Top3Curieri,
Top3Angajati, Top3 CategoriiContinue
- Romania, 100,"Cargus;Fan;SameDay","Da; Nu”,
*/