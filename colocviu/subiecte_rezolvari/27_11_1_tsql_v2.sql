-- 27_11_1_v2e
-- NR 1.
-- Pentru fiecare supplier vrem sa aflam:
-- 1. Orașul cu cele mai multe comenzi (1p)
-- 2. Cea mai veche comanda (OrderID & data) (1p)
-- 3. Produsele (ProductName) cu pretul peste media preturilor tuturor produselor din baza de date. (2p)
-- 4. Daca furnizorul (supplier-ul) a livrat produse in cel putin 10 regiuni distincte. Afisati "Da" sau "Nu".(2p)
-- 5. Categoria de produse (CategoryName) care este cea mai vanduta (Quantity * UnitPrice) 
--in peste 50 % din tari si cel mai vandut produs asociat acestei categorii (3p)
-- Afisati rezultatele sub forma unui singur tabel. (1p)
create or replace procedure p1
AS
BEGIN
    CREATE TABLE #Final(
        Ex INT,
        Descriere NVARCHAR(200),
        Rezultat NVARCHAR(200)
    )
    CREATE TABLE #Ex1(
        Oras NVARCHAR(15),
        NrComenzi INT
    )
    CREATE TABLE #Ex2(
        OrderID INT,
        [Data] DATE
    )
    CREATE TABLE #Ex3(
        ProductName NVARCHAR(40)
    )
    CREATE TABLE #Ex4(
        CompanyName NVARCHAR(40),
        Orders INT,
        [Status] NVARCHAR(2)
    )
    CREATE TABLE #Ex5(
        CategoryName NVARCHAR(15),
        SumaCategorie INT,
        ProductName NVARCHAR(40),
        CelMaiVAndutProdus INT
    )

    --ex1
    --1. Orașul cu cele mai multe comenzi (1p)
    INSERT INTO #Ex1(Oras, NrComenzi)
    SELECT ShipCity AS Oras, Count(OrderID) AS NrComenzi
    FROM Orders
    GROUP BY ShipCity

    select * from #Ex1
    order by NrComenzi desc

    --ex2
    -- 2. Cea mai veche comanda (OrderID & data) (1p)
    INSERT INTO #Ex2(OrderID, [Data])
    SELECT OrderID, OrderDate AS [Data]
    FROM Orders 

    select * from #Ex2
    order by [Data]

    --ex3
    -- 3. Produsele (ProductName) cu pretul peste media preturilor tuturor produselor din baza de date. (2p)
    INSERT INTO #Ex3
    select ProductName
    from products
    where dbo.Miercuri_Ex3(ProductID) = 1

    select * from #Ex3

    --ex4
    -- 4. Daca furnizorul (supplier-ul) a livrat produse in cel putin 10 regiuni distincte. Afisati "Da" sau "Nu".(2p)
    INSERT INTO #Ex4
    select max(s.CompanyName) as CompanyName, 
           dbo.Miercuri_Ex4(s.SupplierID) as Orders,
           iif((dbo.Miercuri_Ex4(s.SupplierID)) >= 10,'DA', 'NU')
    from Products p
    left join Suppliers s on s.supplierid = p.supplierid
    group by s.SupplierID

    select * from #Ex4

    --ex5
    --de unde pot sa aflu daca este cea mai vanduta categorie, o iau din produs????????????????????????

    --spre ca e bine nu sunt sigura
    -- 5. Categoria de produse (CategoryName) care este cea mai vanduta (Quantity * UnitPrice) 
    --in peste 50 % din tari si cel mai vandut produs asociat acestei categorii (3p)
    INSERT INTO #Ex5
    select c.CategoryName AS CategoryName, dbo.Miercuri_Ex5(c.CategoryID) AS SumaCategorie,
            max(p.productname) as productname,
            dbo.Miercuri_Ex5__3(c.CategoryID) AS CelMaiVAndutProdus
    from categories c
    left join products p on p.categoryid = c.categoryid
    where (dbo.Miercuri_Ex5__2(c.CategoryID)) 
                        >= 
                        (0.5 * (SELECT COUNT(DISTINCT ShipCountry) FROM Orders))
    and p.ReorderLevel = dbo.Miercuri_Ex5__3(c.CategoryID)
    group by c.CategoryID, c.CategoryName


    INSERT INTO #Final( Ex, Descriere, Rezultat)
    SELECT '1' AS Ex, (N'Orașul cu cele mai multe comenzi') AS Descriere,
        (SELECT TOP 1 Oras FROM #Ex1
         order by NrComenzi desc) AS Rezultat

    INSERT INTO #Final( Ex, Descriere, Rezultat)
    SELECT '2' AS Ex, (N'Cea mai veche comanda') AS Descriere,
        (SELECT TOP 1 [Data] FROM #Ex2
         order by [Data]) AS Rezultat

    INSERT INTO #Final(Ex, Descriere, Rezultat)
    SELECT '3' AS Ex, 
        N'Produsele cu pretul peste media preturilor tuturor produselor' AS Descriere,
        ProductName AS Rezultat
    FROM #Ex3;

    INSERT INTO #Final(Ex, Descriere, Rezultat)
    SELECT '4' AS Ex,
        N'Daca furnizorul a livrat produse in cel putin 10 regiuni distincte' AS Descriere,
        ([Status] + '-' + CompanyName) AS Rezultat
    from #Ex4;

    INSERT INTO #Final(Ex, Descriere, Rezultat)
    SELECT '5' AS Ex,
        N'Categoria + produsul cele mai vandute în peste 50 % din tari' AS Descriere,
        (CategoryName + '-' + ProductName) AS Rezultat
    from #Ex5;

    
    SELECT * FROM #Final
END;
GO

if 2= 3
BEGIN

exec dbo.MiercuriNr1

END



create or alter function dbo.Miercuri_Ex3(@ProductID INT)
RETURNS BIT
as begin 
    declare @rezultat bit
    SELECT @rezultat = IIF(
        p.UnitPrice > ((
            SELECT SUM(p2.UnitPrice)
            FROM Products p2
        ) / NULLIF(
            (SELECT COUNT(distinct p2.ProductID) FROM Products p2), 0
        )), 
        1, 
        0
    )
    FROM Products p
    WHERE p.ProductID = @ProductID;

    return @rezultat;
end
go


create or alter function dbo.Miercuri_Ex4(@ID int)
RETURNS INT
AS
BEGIN
    DECLARE @rezultat INT
    select @rezultat = count(distinct o.ShipRegion)
    from Products p
    left join [Order Details] od ON od.ProductID = p.ProductID
    left join Orders o on o.OrderID = od.OrderID 
    where p.SupplierID = @ID

    return @rezultat;
END
GO


create or alter function dbo.Miercuri_Ex5(@CategoryID int)
returns INT AS
BEGIN
    declare @rezultat INT
    select @rezultat = SUM(od.UnitPrice * od.Quantity)
    from Products p
    left join [Order Details] od on p.ProductID = od.ProductID
    WHERE p.CategoryID = @CategoryID
    group by p.CategoryID
    RETURN @rezultat;
END
GO


create or alter function dbo.Miercuri_Ex5__2(@ID int)
RETURNS INT
AS
BEGIN
    DECLARE @rezultat INT
    select @rezultat = count(distinct o.ShipCountry)
    from Categories c
    left join Products p on c.CategoryID = p.CategoryID
    left join [Order Details] od ON od.ProductID = p.ProductID
    left join Orders o on o.OrderID = od.OrderID 
    where c.CategoryID = @ID

    return @rezultat;
END
GO

create or alter function dbo.Miercuri_Ex5__3(@ID int)
RETURNS INT 
AS
BEGIN
    declare @rezultat INT
    select @rezultat = MAX(ReorderLevel)
    from Products
    WHERE CategoryID = @ID

    RETURN @rezultat;
END
GO