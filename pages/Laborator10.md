# Laborator 10 - MongoDB

## TODO: de facut .md frumos atunci cand repeti pentru mongo

- un document e {}
- inserare chestii
```
db.students.insert(
{
    "student": 
        {
            "firstname": "Ion", 
            "lastname": "Popescu"
        },
    "an": 4,
    "grupa": "342C3",
    "materii": 
        [
            {"nume": "Comp", "an": 4}, 
    	    {"nume": "BD2" , "an": 4}, 
            {"nume": "SO2" , "an": 4}
        ],
    "cunostinte": ["SQL", "Java", "PL/SQL"]
}
)

var stud = {"student": { "firstname": "Andrei", "lastname": "Ionescu"}, "an": 4, "grupa": "341C4", "materii": [{"nume": "BD2", "an": 4}, {"nume": "IA", "an": 4},{"nume": "IAUT", "an": 4}], "cunostinte": ["C", "C++", "SQL"] }
 
db.students.insert(stud)
 
var studs = [
    {"student": { "firstname": "George", "lastname": "Popescu"}, "an": 4, "grupa": "341C2", "materii": [{"nume": "BD2", "an": 4}, {"nume": "IOCLA", "an": 2}], "cunostinte": ["Python", "SQL"]  },
    {"student": { "firstname": "Georgiana", "lastname": "Petrescu"}, "an": 4, "grupa": "341C2", "materii": [{"nume": "BD2", "an": 4}, {"nume": "SCAD", "an": 4}], "cunostinte": ["Python", "SQL"]  },
    {"student": { "firstname": "Valentina", "lastname": "Vasilescu"}, "an": 3, "grupa": "331CA", "materii": [{"nume": "BD", "an": 3}, {"nume": "RL", "an": 3}, {"nume": "APD", "an": 2}], "cunostinte": ["Java", "C++", "SQL"] },
    {"student": { "firstname": "Grigore", "lastname": "Ionescu"}, "an": 4, "grupa": "342C2", "materii": [{"nume": "BD2", "an": 4}, {"nume": "VLSI", "an": 4}, {"nume": "SRIC", "an": 4}, {"nume": "SO", "an": 3}], "cunostinte": ["C", "Python", "SQL", "Ruby"] },
    {"student": { "firstname": "Andrei", "lastname": "Popescu"}, "an": 3, "grupa": "332CA", "materii": [{"nume": "CN1", "an": 2}, {"nume": "CN2", "an": 2}, {"nume": "RL", "an": 3}], "cunostinte": ["C", "Python", "SQL", "Ruby"] },
    {"student": { "firstname": "Ana", "lastname": "Georgescu"}, "an": 4, "grupa": "342C5", "materii": [{"nume": "BD2", "an": 4}, {"nume": "UBD", "an": 4}, {"nume": "SRIC", "an": 4}, {"nume": "SO", "an": 3}], "cunostinte": ["C", "Python", "SQL", "Ruby"], "sef": true },
]
 
db.students.insert(studs)

var studs2 = [
    {"student": { "firstname": "Maria", "lastname": "Popescu"}, "an": 4, "grupa": "345C5", "materii": [{"nume": "BD2", "an": 4}, {"nume": "MPS", "an": 4}], "cunostinte": ["Java", "SQL"]  },
    {"student": { "firstname": "Alexandra", "lastname": "Pascu"}, "an": 4, "grupa": "341C4", "materii": [{"nume": "BD2", "an": 4}, {"nume": "SCAD", "an": 4}], "cunostinte": ["Python", "SQL"]  },
    {"student": { "firstname": "Claudia", "lastname": "Girnita"}, "an": 4, "grupa": "343C5", "materii": [{"nume": "BDD", "an": 4}, {"nume": "PP", "an": 2}, {"nume": "MPS", "an": 4}], "cunostinte": ["Java", "C", "SQL"] },
]

db.students.insert(studs2)
```

---

## De la capat
```
use faculty

switched to db faculty

db["students"].find({"student.firstname":"Alexandra"})

{
  _id: ObjectId('673f181628e82b51de65303c'),
  student: {
    firstname: 'Alexandra',
    lastname: 'Pascu'
  },
  an: 4,
  grupa: '341C4',
  materii: [
    {
      nume: 'BD2',
      an: 4
    },
    {
      nume: 'SCAD',
      an: 4
    }
  ],
  cunostinte: [
    'Python',
    'SQL'
  ]
}
```

---

## Adaugare date dintr-un tabel
```
mongoimport --host=hostname --port=27017 --db=BD2 --collection=documents --type=json --file=data_dump.json
mongoimport --host=hostname --port=27017 --db=BD --collection=documents2 --columnsHaveTypes --fields="name.string(),birthdate.date(2006-01-02),contacted.boolean(),followerCount.int32(),thumbnail.binary(base64)" --type=csv --file=data_dump.csv
```
- cel mai bine, acestea le faci din GUI

---

## "select"
- sintaxa
```
db.collection.find(query, projection)
```
```
db.students.find()
db.students.find().limit(3)
db.students.findOne()
```
- Dacă se dorește sortarea rezultatelor după valoare unui anumit câmp se folosește sort({label_1: order, label_2: order,…, label_n:order}) unde order este 1 pentru ascendent și -1 pentru descendent.
```
db.students.find().sort({"grupa": 1})
```
- Dacă se dorește afișarea într-un mod citibil în consolă se folosește `pretty()`
```
db.students.find().pretty()
```
- `pretty`, `limit` și `sort` se pot folosi împreună
```
db.students.find().sort({"student.firstname": 1}).limit(3).pretty() -> 
```

---

## Filtrarea cererilor
- Pentru a filtra rezultatele se folosește parametru query.
- Pentru comparație avem:
	- `:` - egalitate
	- `$ne` - diferit de (not equal)
	- `$gt` - mai mare
	- `$gte` - mai mare sau egal
	- `$lt` - mai mic
	- `$lte` - mai mic sau egal
	- `$in` - căutare într-o listă
	- `$all` - căutare cu egalitate pe toate elementele dintr-o listă

```
db.students.find({"student.firstname": "Ion"})
db.students.find({an: {$gte: 4}})
db.students.find({"materii.nume": {$in: ['SCAD', 'IA']} })
db.students.find({"cunostinte": {$all: [/^J/, /^C/ ]}})
db.students.find({"grupa": /^341/ })
```
- opartori logici:
	- `$or` - sau logic
	- `$and` - și logic
	- `$not` - negare logic
```
db.students.find({$or:  [{"student.lastname": "Ionescu"}, {"cunostinte": /^C/}]})
db.students.find({$and: [{"student.lastname": "Ionescu"}, {"cunostinte": /^C/}]})
```

## Operatori utili pentru vectori
- `$size` pentru a verifica dimensiune
- 0, 1, 2,… pentru poziționare (indexare vectorilor începe de la 0)
```
db.students.find({"materii.0.nume": "BD2"})
db.students.find({"cunostinte.2": "SQL"})
db.students.find({"cunostinte": {$size: 2}})
```
- Pentru a verifica existența unui câmp se folosește $exists
```
db.students.find({"sef": true})
db.students.find({"sef": {$exists: true}})
db.students.find({"sef": false})
db.students.find({"sef": {$exists: false}})
```

---

## Proiectia
- "select" anumite chestii => `projection`
- daca vrei filtrare => se pun acolade fara nimic in ele pentru query: `db.students.find({}, {"student.firstname": 1})`
- projection întoarce doar câmpurile specificate și *_id* => ca sa scapi de el: "_id": 0
```
db.students.find({}, {"_id": 0, "student.firstname": 1})
```
## Modificarea datelor
- Pentru a modifica datele se poate folosi una din comenzile:
*update*
```
db.collection.update(<query>, <update>, <options>)
```
```
DeprecationWarning: Collection.update() is deprecated. Use updateOne, updateMany, or bulkWrite.
{
  acknowledged: true,
  insertedId: null,
  matchedCount: 1,
  modifiedCount: 1,
  upsertedCount: 0
}
```
- Pentru a seta o valoare se folosește $set care suprascrie valoarea pentru câmp. 
- modificare...vector => $push. (ca la C++)
- adaugare mai multe valori ++ $each.
```
db.students.update({an: 4, "student.firstname": "Grigore"}, {$push: {"cunostinte": "C"}}) 
```
- ^
aici modifici o singura chestie mica intr-un vector din chestia mare
```
db.students.update({an: 4, "student.firstname": "Grigore"}, {$push: {"cunostinte":{$each: ["Python", "SQL", "Ruby"]}}}) 
```
- ^ aici modifici o singura chestie mica gen adaugi mai multe chestii mici intr-un vector din chestia mare
```
db.students.update({"student.firstname": "George"}, {$set: {"grupa": "342C1"}}) 
```
- ^ aici modifici o chestie din chestia mare, chestia mica nu e vector
```
db.students.update({an: 4, "student.firstname": "Grigore"}, {$set: {cunostinte: ["C++"]}})
```
- modificarea valorii unui element dintr-o listă sau a unui câmp dintr-un *document* imbricat => `$`
```
db.students.update({"student.firstname": "Grigore", "cunostinte": "C"}, {$set: {"cunostinte.$": "Java"}})
db.students.update({"student.firstname": "Grigore", "materii.nume": "SRIC"}, {$set: {"materii.$.nume": "SPG"}})
db.students.update({"student.firstname": "Grigore", "materii.nume": "SPG"}, {$set: {"materii.$.nume": "SRIC", "materii.$.an":4}})
```

**Exercitiul 6:**

> Să se selecteze primele 4 rezultate ale unei cereri care întoarce toți studenții ordonați descrescător după nume.
```
db.students.find().sort({"student.firstname": -1}).limit(4)
```

**Exercitiul 8:**

> Să se selecteze toți studenții din anul 4 care au restanțe și știu limbajele de programare C și SQL.

- le iei pe bucatele
- mai intai pui un filtru peste materii
```
db.students.find({"materii": 1})

db.students.find({$in})

db.students.find({$and: [{$and: [{an: {: 4}}, ]])

db.students.find({$and: [{"materii.an": {$lte: 3} }, {"cunostinte":{$in: ['C', 'SQL']}}]}, {"_id": 0, "student.firstname": 1}) 
```
**Exercitiul 9:**

> Să se selecteze studenții care nu sunt șefi și au cunoștințe de “Python” pe a doua poziție din vectorul de cunoștințe. Afișați doar numele, prenumele și vectorul de cunoștințe.
```
db.students.find(
    {
        $and: [
            {$or: [{"sef": false}, {"sef": {$exists: false}} ]}, 
            {"cunostinte.1": "Python"}
        ]
    },
    {
        "_id": 0, 
        "student.firstname": 1,
        "student.lastname": 1,
        "cunostinte": 1
    }
)
```
**Exercitiul 10:**

> Să se adauge la toți studenți de anul 3 materiile EGC și LFA (nume si an) folosind o singură comandă.
```
// TODO
```
**Exercitiul 11:**

> Să se șteargă doar un student care are materia BD2.
```
//TODO
```
**Exercitiul 12: - BONUS**

> Sa gasim studentii care au repetat macar e 2 ori o materie: 
```
db.students.find({"_id":0, "student.firstname":1, )

db.students.find({
    $or: [
        {
            $and: [
                { an: 4 },
                {
                    $or: [
                        { "materii.an": 1 }, 
                        { "materii.an": 2 } 
                    ]
                }
            ]
        },
        {
            $and: [
                { an: 3 }, 
                { "materii.an": 1 } 
            ]
        }
    ]
}).pretty()
``` 
