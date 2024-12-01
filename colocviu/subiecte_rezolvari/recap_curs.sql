/*
Select P.ProductName--, Count(*) NumSales
FROM Products P
INNER JOIN Order_Details OD ON P.ProductId = OD.ProductId
Group by P.ProductId, P.ProductName
Order by Count(*) desc
Fetch first 1 row only
*/
-- 1. care este cel mai popular produs? (apare in cat mai multe comenzi)
-- 2. care sunt produsele care in general sunt vandute sau in cantitati mari sau impreuna cu un alt produs din categoria lor? (1p)
-- (cantitate mare = din toare cantit posibile vandute din order_details) sa fie in top 10% (daca cantitea vanduta e 1000, sa fim in 900+) (2p)
-- 3. care este produsul care are cele mai mari sanse sa apara in urmatoarea comanda:
--  - avem stoc suficient relativ la comenzile care s-au dat (facem mediana cantitatii din comenzi si vedem daca avem in stoc) (stocul e in products, order_details vedem)
--  - este unul din cele mai bine vandute produse (vedem cea mai mare cantitate de prod vanduste si vedem dk e in top 10) (3o)
--  - are un pret atractiv (pretul este in jurul mediei, cu o abatere de 25%)
-- 2. care sunt produsele care in general sunt vandute sau in cantitati mari
--    sau impreuna cu un alt produs din categoria lor? (1p)
-- (cantitate mare = din toare cantit posibile vandute din order_details) sa fie in top 10% (daca cantitea vanduta e 1000, sa fim in 900+) (2p)
DECLARE
  numar_minim_vanzari INT;
BEGIN
  SELECT 0.9 * Max(quantity) OurThreshold
  INTO   numar_minim_vanzari
  FROM   order_details;
  FOR variable IN
                   (
                   SELECT DISTINCT productname
                   FROM            (WITH order_product AS
                                   (
                                                   SELECT DISTINCT p.productname ,
                                                                   P.categoryid ,
                                                                   od.orderid ,
                                                                   P.productid
                                                   FROM            order_details od
                                                   inner join      products P
                                                   ON              P.productid = OD.productid )
                   SELECT DISTINCT p1.productname
                   FROM            order_product p1
                   inner join      order_product p2
                   ON              p1.orderid = p2.orderid
                   WHERE           p1.productid <> p2.productid
                   AND             p1.categoryid = p2.categoryid
                   UNION
                   SELECT DISTINCT p.productname
                   FROM            order_details od
                   inner join      products P
                   ON              P.productid = OD.productid
                   WHERE           od.quantity >= numar_minim_vanzari))
  LOOP
    dbms_output.Put_line(variable.productname);
  END LOOP;
END;
/
-- 3. care este produsul care are cele mai mari sanse sa apara in urmatoarea comanda:
--  - avem stoc suficient relativ la comenzile care s-au dat (facem mediana cantitatii din comenzi si vedem daca avem in stoc) (stocul e in products, order_details vedem)
--  - este unul din cele mai bine vandute produse (vedem cea mai mare cantitate de prod vanduste si vedem dk e in top 10) (3o)
--  - are un pret atractiv (pretul este in jurul mediei, cu o abatere de 25%)
SELECT productname
FROM   products
WHERE  productid IN
       (
              SELECT p.productid
              FROM   products p
              WHERE  p.unitsinstock <
                     (
                            SELECT Median(od.quantity)
                            FROM   order_details od
                            WHERE  od.productid = p.productid))
AND    productid IN
                     (
                     SELECT DISTINCT productid
                     FROM            order_details
                     ORDER BY        quantity DESC
                     fetch first 10 ROWS ONLY)
AND    productid IN
       (
              SELECT p.productid
              FROM   products p
              WHERE  p.unitprice BETWEEN .75 *
                     (
                            SELECT avg(od.unitprice)
                            FROM   order_details od
                            WHERE  od.productid = p.productid)
              AND    1.25 *
                     (
                            SELECT avg(od.unitprice)
                            FROM   order_details od
                            WHERE  od.productid = p.productid) );
