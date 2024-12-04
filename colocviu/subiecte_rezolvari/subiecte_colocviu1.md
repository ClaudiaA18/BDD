# Subiecte Colocviu 1

## marti 20

### NR 1

Analiza performanței pe furnizori. Pentru fiecare furnizor (CompanyName), afișați:

1. (1p) Care este produsul cel mai vândut
2. ⁠(2p) Dacă furnizorul este "relevant" sau "marginal": Un furnizor este "relevant" dacă valoarea totală a produselor (OrderDetails.Quantity * OrderDetails.UnitPrice) livrate depășește media globală a vânzărilor pe furnizori.
3. ⁠(2p) Produsul cel mai bine vândut (ProductName) pentru fiecare furnizor, dar doar dacă produsul a fost comandat în cel puțin 20 locații distincte (ShipCity).
4. ⁠(2p) Dacă furnizorul a livrat produse către cel puțin 5 categorii distincte (CategoryID) (da sau nu).
5. ⁠(3p) care este cel mai popular produs de la furnizor, cumpărat de clienții noi in mai multe tari

---

### NR 2

Pentru fiecare tara afișați:

1.⁠ ⁠(1p)Categoria cu cele mai mari vânzări(CategoryName).
2.⁠ ⁠(2p)Daca este tara target afișați “target”, altfel afișați “normal” ( o tara este target daca valoarea totală a comenzilor OrderDetails.Quantity * OrderDetails.UnitPrice) depășește media valorii comenzilor pe toate țările)
3.⁠ ⁠(2p)Furnizorii care au livrat produse discontinue (Products.Discontinued = 1) din cel puțin 2 categorii diferite.
4.⁠ ⁠(2p)Daca valoarea totală a comenzilor depășește cu cel puțin 20% valoarea medie globală a comenzilor. ( “da” sau “nu”)
5.⁠ ⁠(3p)Cea mai profitabila locație de livrare (ShipCity orasul care a produs cel mai mulți bani, dar ia in considerare doar orașele in care au fost cel puțin 20 de livrări). O locație este profitabila doar daca are concurenta ( in tara respectivă exista cel puțin 2 orașe in care se fac livrări)

---

## miercuri 18

### NR 1.

Pentru fiecare supplier vrem sa aflam:

1. Orașul cu cele mai multe comenzi (1p)
2. Cea mai veche comanda (OrderID & data) (1p)
3. Produsele (ProductName) cu pretul peste media preturilor tuturor produselor din baza de date. (2p)
4. Daca furnizorul (supplier-ul) a livrat produse in cel putin 10 regiuni distincte. Afisati "Da" sau "Nu".(2p)
5. Categoria de produse (CategoryName) care este cea mai vanduta (Quantity * UnitPrice) in peste 50 % din tari si cel mai vandut produs asociat acestei categorii (3p)
   Afisati rezultatele sub forma unui singur tabel. (1p)

---

### NR 2.

Pentru fiecare produs vrem sa aflam:

In cate regiuni diferite a fost vandut? (1p)

Cea mai scumpa comanda plasata (OrderID & pret) (1p)

Daca face parte dintr-o "categorie top". O "categorie top "are vanzari de peste 15k (UnitPrice * Quantity) in ultima luna in cel putin 17 regiuni. Afisati numele categoriei sau "Nu". (2p)

Care este cea mai profitabilă locație (ShipCity) pentru acest produs? (2p)

Daca este cel mai vandut (Quantity) produs dintre cele livrate de cei mai bine cotati livratori. Cei mai bine cotati livratori, livreaza in peste 85% din tari. Afisati "Da" sau "Nu". (3p)
Afisati rezultatele sub forma unui singur tabel. (1p)

## Marti 2 dec 18

Pentru fiecare angajat, afiseaza:

- (0.75p) ultimul ciclu de studii absolvit, astfel:
  - daca "BA", "BS" sau "BSC se regasesc pe Employees.Notes, se va afisa "Licenta"
  - daca "MA", "MBA" se regasesc pe Employees.Notes, se va afisa "Master
  - daca "Ph.D" se regaseste pe Employees.Notes, se va afisa "Doctorat"
  - altfel, va afisa "Lipsa informatii"
- (0.25p) daca regaseste mai mult de o diploma, o vom afisa doar pe cea superioara.
  ex. Daca regasim si "BA" si "MA", vom afisa doar "Master"
- (2p) care este cel mai mare discount in bani acordat pe o comanda (pretul unei comenzi se calculeaza ca Order_Details.UnitPrice * Order_Details.Quantity, dupa care aplica se discountul; ATENTIE: relatia dintre Orders si Order_Details este "one to many")
- (3p) diferenta absoluta maxima dintre numarul total de produse. (Order_Details.Quantity) ale aceluiasi supplier vandute intr-o luna vs luna precededenta in care a mai fost vandut (ex. in iunie 1988 au fost vandute 50 de produse ale supplier 1, in iulie 1988 au fost vandute 60 de produse ale supplier 1, deci diferenta este de 10 produse; in august 1988 nu au fost vandute produse ale supplier 1, iar in septembrie 1988 au fost vandute doar 5 produse ale supplier 1, deci diferenta este 55 produse; diferenta maxima este 55). Data la care sunt vandute comenzile este Orders.ShippedDate.
- (4p) bonusul de performanta, care se calculeaza astfel:
  - (1p) daca angajatul a vandut macar 3 produse care se afla in "stoc suficient. (Products.UnitsInStock > media valorilor Products.UnitsInStock pentru toate produsele aflate in colaborare activa (Products.Discontinued = 0)) primeste cate 60 RON per produs;
  - (1p) daca angajatul are nivelul ierarhic 2 (are macar un manager in subordine, care la randul lui are angajati in subordine; managerii apa, coloana Ernployees.ReportsTo) primeste 1000 RON;
    -(1.5p) daca este in top 30% angajati de acelasi gen "rapizi. (clasifi.re pe gen (Mr./Mrs.) in functie de valoarea medie a duratei de livrare (numarul de zilei dintre Orders.ShippedDate si Orders.OrderDate) primeste 1100 RON;
  - altfel, nu primeste;
  - (1p) Afisati rezultatele sub forma unui singur tabel.
