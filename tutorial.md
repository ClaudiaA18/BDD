# Tutorial cum sa rulezi oracle sql plus 19c direct din vscode

## Intro:

Cred ca mi au trebuit 2 semestre-ish sa-mi dau seama cum sa fac asta, sa pot rula direct oracle sql plus pe vscode

## Perequisites:

- oracle sql plus 19c
- vscode

## Note to self:

- nu-ti dezinstala oracle sql plus 19c de la bd1 pentru ca vei avea nevoie de el in continuare
- daca l-ai dezinstalat cum te-a dus pe tine capul... bafta!
- daca l-ai dezinstalat intr-un mod clean/smooth, cu ajutorul indianului de pe youtube, ai sanse sa-l reinstalezi fara probleme, altfel va trebui sa reinstalezi windows-ul sau sa ti faci vm cu windows (da vm cu windows pe windows, am patit =)) )

## Link-uri utile:

- TODO
- [vm-windows](https://developer.microsoft.com/en-us/windows/downloads/virtual-machines/)
- [tutorial bd1 instalare oracle sql plus]()
- [tutorial abd instalare oracle sql plus]()
- [Indian youtube ok ca sa dezinstalezi clean oracle sql plus]()

## ce am facut mai exact:

- instaleaza urmatoarele extensii pe vscode: (efectiv, asa le cauti; daca e, revin mai incolo cu link-uri la ele, acum nu am timp)
  - TODO ^
  - oracle developer tools for vscode sql and plsql (e de la oracle, pare legit)
  - oracle sql developer extension for vscode (asta e baza)
  - intellisense for the oracle developer (sa fie acolo)
  - language pl/sql (o fi ajutand cu ceva?)
  - prettier - code formatter (i tried)
    (mai jos acolo ai toate prostiile; da le am pe toate; asa face omul cand e in culmea disperarii)
  - pl/sql debug
  - sqltools
  - data workspace
  - sql bindings
  - sql database projects
    sincer, nu stiu daca le folosesc chiar pe toate cele amintite mai sus, dar sigur le folosesc pe aceasta:
  - oracle developer tools for vscode sql and plsql
  - oracle sql developer extension for vscode (asta e baza) (desi cred ca numai asta trebuia, parca vezi) (oricum extensiile astea par a fi independente una de alta, nu stiu de acestea 2 de la oracle)
- dupa ce le-ai instalat (macar pe cele 2, tbh, n-am incercat sa le dezinstalez pe restul, mi-e frica, las asa >u<) probabil o sa ti apara o fereastra/fila in vs code de walktrough  oracle sql developer extension for vscode
- urmeaza pasii de acolo
- mai intai va trebui sa-ti creezi o conexiune
- daca skip-uiesti pasii din walktrough (nu degeaba apare imediat ce instalezi extensia), nu-i nimic.

### Urmatorii pasi sunt la fel si in walktrough si oricand vrei sa-ti creezi o noua conexiune:

- o sa ti apara in bara laterala din stanga o baza de date cu un play button rotund in dreapta jos (aia e extensia buna).
- dai pe el, iti mai apare o bara laterala, hover pe connections -> + -> create connection
  (fara sa creezi o conexiune nu scapi, de fapt asta e tot ceea ce trebuie sa faci, asta e farmecul =))) )

## Ce si cum am completat mai exact:

- nume conexiune: text
- am selectat user info (nu proxy user, nici nu stiu ce-i aia =))) )
- authentication type: basic
- role: sysdba (sincer, acum reiau pasii uitandu-ma la fereastra de conexiune noua, care e aproximativ aceeasi de la walktrough) (cred ca merge si default, incearca asa >u< )
- username: abd1 (daca faci abd, daca nu, si ai de anul trecut, pune scott)
- password: abd1 (eu asa am userul, daca ai scott, pune tiger ;) )
- bifeaza save password (dar sa te asiguri ca e parola care trebuie)
- la sectiunea connection type, nu m-am dus la advanced, ci am ramas sa completez details
- hostname: localhost
- port: 1521 (e cel default, cred ca e deja completat, lasa-l asa)
- type: service name (cel deja completat, nu l-am selectat pe celalalt)
- service name: ORCL (cu majuscule, pls)
- mai intai test, ca sa nu ai surpriza ca nu se conecteaza, si o sa-ti apara feedback in partea de dreapta jos a ecranului (o a ti spuna in caz de ok ca e test passed sau ceva de genul).
- apoi, creezi un nou document (in walktriugh o sa ai open sql workseet), scrii asa de test o comanda (gen select * from employees;) si dai pe butonul verde de play din dreapta sus. o sa ti apara sa selectezi conexiunea i o sa vezi ca poti sa selectezi conexiunea create de tine si, apoi, dupa ce compileaza, o sa ti apara jos fereastra de terminal vscode, fila query result, rezultatul

Si asta e tot
pam pam pam
n-a fost asa de greu, asa-i?

TL;DR totusi, n-am incercat sa vad ce se intampla dupa ce inchid vscode sau dupa ce inchid si deschid calculatorul/sistemul/vm-ul.
revin cu update

Pace!
