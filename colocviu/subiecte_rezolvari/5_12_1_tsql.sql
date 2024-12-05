/*
5_12_1c
NR1
Dorim sa imbunatatim experienta platformei noastre
asa ca dorim sa aflam urmatoarele statistici 
pentru fiecare tara (Orders.ShipCountry):
- Cate comenzi au fost livrate in acelasi oras
(ca si comanda) in ultimul an (ultimul an in care 
s-au facut comenzi) = 1p
- Rata de intarziere a unei comenzi din aceeasi
regiune vs din afara regiunii, calculata ca si 
procent (ex “30% vs 60%”); o comanda se considera
intarziata daca Required Date - ShippedDate >= 3
(zile; daca o comanda nu este inca trimisa folositi
diferenta maxima) = 2p
- Pentru fiecare angajat (Numele complet al angajatului)
din tara, Categoria de produse dominanta 
(categoria din care s-a vandut cel mai mult ca si
suma de bani pentru acel angajat), din ultimii 2 ani
in care a facut vanzari acea tara = 3p
- Furnizorii(Suppliers. CompanyName) care au
redistribuitori; se considera un redistribuitor
un client care se afla in partea de sus a distributiei
cantitatii (pentru o categorie de produse, este
suficient sa fie in una) si in acea distributie
valoarea mediei este minim 1.5 din mediana
(mediana nu se va calcula folosind functia MEDIAN
din oracle); este suficient sa existe un singur
redistribuitor in oricare categorie ca sa afisam
furnizorul = 4p
- Afisare si precizari extra:
- Daca cumva nu sunt, deloc, astfel de informatii
(categorii, produse, etc) afisati 66 39
- Vom afisa pentru fiecare tara aceste informatii,
pe un singur rand
Exemplu afisare:
Nume Tara, NumarComenziRapide,Ratalntarziere,
Favorite, Redistribuitori RO,15,"50% vs 240%"
"Alex: IT, George: Dezinformare”,”Apple"
*/