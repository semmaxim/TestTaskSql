-- 1
create table Shops (
	Id int identity(1,1) not null,
	[Name] nvarchar(50) not null,
	constraint PK_Shops primary key (Id),
	constraint U_Shops_Name unique ([Name]))


create table Products (
	Id int identity(1,1) not null,
	[Name] nvarchar(50) not null,
	constraint PK_Products primary key (Id),
	constraint U_Products_Name unique ([Name]))

create table Buyers (
	Id int identity(1,1) not null,
	FIO nvarchar(100) not null,
	PhoneNumber nvarchar(12) not null,
	constraint PK_Buyers primary key (Id),
	constraint U_Buyers_FIO unique (FIO),
	constraint U_Buyers_PhoneNumber unique (PhoneNumber))

create table Rests (
	ProductId int not null,
	ShopId int not null,
	Quantity int not null,
	constraint PK_Rests_ProductId_ShopId primary key (ProductId, ShopId),
	constraint C_Rests_Quantity check (Quantity >= 0),
	constraint FK_Rests_ProductId_Products foreign key (ProductId) references Products(Id),
	constraint FK_Rests_ShopId_Shops foreign key (ShopId) references Shops(Id))

create table Documents (
	Id int not null,
	ProductId int not null,
	ShopId int not null,
	BuyerId int not null,
	PurchaseQty int not null,
	PurchaseDateTime datetime2 not null,
	constraint PK_Documents_Id_ProductId primary key (Id, ProductId),
	constraint C_Documents_PurchaseQty check (PurchaseQty >= 0),
	constraint U_ProductId_ShopId_BuyerId unique (ProductId, ShopId, BuyerId),
	constraint FK_Documents_ProductId_Products foreign key (ProductId) references Products(Id),
	constraint FK_Documents_ShopId_Shops foreign key (ShopId) references Shops(Id),
	constraint FK_Documents_BuyerId_Buyers foreign key (BuyerId) references Buyers(Id))

-- 2

; -- Магазины
with
IntSequence as (
	select 1 as Val
	union all
	select Val + 1 from IntSequence where Val < 50)
insert into Shops([Name])
select ShopNames.[Name] + N' No' + cast(IntSequence.Val as nvarchar(50))
from
	IntSequence
	cross join (values (N'Лента'), (N'Магнит')) as ShopNames([Name])

; -- Товары
with
ProductNames as (
	select [Name]
	from
		(values
			(N'Телефон'), (N'Холодильник'), (N'Часы'), (N'Телевизор'), (N'Микроволновка'),
			(N'Фотоаппарат'), (N'Наушники'), (N'Принтер'), (N'Пылесос'), (N'Утюг')) as S([Name])),
ProducerNames as (
	select [Name]
	from
		(values
			(N'Samsung'), (N'LG'), (N'BEKO'), (N'DEXP'), (N'Haier'), (N'Indesit'), (N'AEG'),
			(N'Bosch'), (N'Centek'), (N'Harper'), (N'Hitachi'), (N'Hyundai')) as S([Name])),
ColorNames as (
	select [Name]
	from
		(values
			(N'бежевый'), (N'белый'), (N'бордовый'), (N'голубой'), (N'жёлтый'), (N'зелёный'),
			(N'золотистый'), (N'красный'), (N'серебристый'), (N'серый'), (N'чёрный')) as S([Name]))
insert into Products([Name])
select top 1000
	T0.[Name] + N' ' + T1.[Name] + N' ' + T2.[Name]
from
	ProductNames T0
	cross join ProducerNames T1
	cross join ColorNames T2
order by newid()

; -- Покупатели
with
MaleLastNames as (
	select LastName
	from
		(values
			(N'Иванов'), (N'Кузнецов'), (N'Смирнов'), (N'Попов'), (N'Петров'), (N'Васильев'),
			(N'Магомедов'), (N'Алиев'), (N'Каримов'), (N'Волков')) as LastNames(LastName)),
FemaleLastNames as (select LastName = LastName + N'а' from MaleLastNames),
MaleFirstNames as (
	select FirstName
	from
		(values (N'Михаил'), (N'Александр'), (N'Артём'), (N'Матвей'), (N'Максим'))
			as FirstNames(FirstName)),
FemaleFirstNames as (
	select FirstName
	from
		(values (N'София'), (N'Ева'), (N'Анна'), (N'Мария'), (N'Виктория'))
			as FirstNames(FirstName)),
MalePatronymics as (
	select Patronymic
	from
		(values
			(N'Михайлович'), (N'Александрович'), (N'Артёмович'),
			(N'Матвеевич'), (N'Максимович')) as Patronymics(Patronymic)),
FemalePatronymics as (
	select Patronymic
	from
		(values
			(N'Михайловна'), (N'Александровна'), (N'Артёмовна'),
			(N'Матвеевна'), (N'Максимовна')) as Patronymics(Patronymic)),
BuyerCombinations as (
	select FIO = T0.LastName + N' ' + T1.FirstName + N' ' + T2.Patronymic
	from
		MaleLastNames T0
		cross join MaleFirstNames T1
		cross join MalePatronymics T2
	union all
	select FIO = T0.LastName + N' ' + T1.FirstName + N' ' + T2.Patronymic
	from
		FemaleLastNames T0
		cross join FemaleFirstNames T1
		cross join FemalePatronymics T2),
BuyersWithRandoms as (
	select top 100
		FIO,
		-- Сразу сгенерировать полное 10-и значное число этим способом нельзя, по-этому генерируем два 5-и значных.
		R1 = cast(abs(checksum(newid()) % 100000) as nvarchar(12)),
		R2 = cast(abs(checksum(newid()) % 100000) as nvarchar(12))
	from
		BuyerCombinations
	order by newid())
insert into Buyers(FIO, PhoneNumber)
select
	FIO,
	N'+7' + replicate(N'0', 5 - len(R1)) + R1 + replicate(N'0', 5 - len(R2)) + R2
from BuyersWithRandoms

; -- Остатки товара
with
ProductPositionsAmountPerShop as (
	select
		ShopId = Id,
		ProductPositionsAmount = 150 + abs(checksum(newid()) % 151)
	from Shops),
ProductPositionNumberPerShop as (
	select
		ShopId = Shops.Id,
		ProductId = Products.Id,
		ProductPositionNumber = row_number() over (partition by Shops.Id order by newid())
	from
		Shops
		cross join Products)
insert into Rests(ProductId, ShopId, Quantity)
select
	T1.ProductId,
	T0.ShopId,
	1000 + abs(checksum(newid()) % 1001)
from
	-- сделать подзапросом с всегда выполнимым условием нужно для принудительной материализации ProductPositionsAmountPerShop до осуществления "join ProductPositionNumberPerShop"
	(select * from ProductPositionsAmountPerShop S0 where ProductPositionsAmount > -1) T0
	join ProductPositionNumberPerShop T1 on T1.ShopId = T0.ShopId
where
	T1.ProductPositionNumber <= T0.ProductPositionsAmount

; -- Документы продаж
with
ProductsAmountPerShop as ( -- сколько у нас всего наименований товаров в каждом магазине
	select
		ShopId,
		ProductsAmount = count(*)
	from Rests
	group by ShopId),
BuyAmounts as ( -- сколько наименований товаров должен купить каждый продавец в каждом магазине
	select
		T0.ShopId,
		BuyerId = T1.Id,
		BuyAmount = floor(abs(T0.ProductsAmount * 0.03) + abs(checksum(newid()) % (T0.ProductsAmount * 0.04))) -- от 3% до 7%
	from
		ProductsAmountPerShop T0
		cross join Buyers T1),
NumberedRests as ( -- нумеруем наличные наименования товаров в каждом магазине в случайном порядке
	select
		*,
		Number = row_number() over (partition by ShopId order by newid())
	from Rests)
insert into Documents (Id, ProductId, ShopId, BuyerId, PurchaseQty, PurchaseDateTime)
select
	row_number() over (partition by T0.ProductId order by T0.ShopId, T1.BuyerId),
	T0.ProductId,
	T0.ShopId,
	T1.BuyerId,
	PurchaseQuantity = 1 + abs(checksum(newid()) % 10),
	dateadd(
		second,
		row_number() over (partition by T0.ProductId order by T0.ShopId, T1.BuyerId),
		'2020-01-02')
from
	NumberedRests T0
	join (select * from BuyAmounts where BuyAmount > -1) T1 on T1.ShopId = T0.ShopId
where
	T0.Number <= T1.BuyAmount

merge Rests as T0
using (
	select
		ShopId,
		ProductId,
		PurchaseQuantity = count(*)
	from Documents
	group by
		ShopId,
		ProductId
	) as T1(ShopId, ProductId, PurchaseQuantity) on T1.ShopId = T0.ShopId and T1.ProductId = T0.ProductId
when matched then update set T0.Quantity = T0.Quantity - T1.PurchaseQuantity;

-- 3
select
	N'Наименование магазина' = T1.[Name],
	N'Наименование товара' = T2.[Name],
	N'Количество на остатке' = T0.Quantity
from
	Rests T0
	join Shops T1 on T0.ShopId = T1.Id
	join Products T2 on T0.ProductId = T2.Id
order by
	T1.[Name],
	T2.[Name]

-- 4
;with
LastDocumentsPerProductAndShop as (
	select
		ProductId,
		ShopId,
		MaxPurchaseDateTime = max(PurchaseDateTime)
	from Documents
	group by
		ProductId,
		ShopId)
select
	N'Наименование товара' = T1.[Name],
	N'Наименование магазина' = T2.[Name],
	N'Дата и время покупки' = T0.MaxPurchaseDateTime
from
	LastDocumentsPerProductAndShop T0
	join Products T1 on T0.ProductId = T1.Id
	join Shops T2 on T0.ShopId = T2.Id
order by
	T1.[Name],
	T2.[Name]

-- 5
;with
PurchaseQuantityPerBuyer as (
	select
		BuyerId,
		TotalQuantity = sum(PurchaseQty)
	from Documents
	group by BuyerId)
select
	N'ФИО покупателя' = T1.FIO,
	N'Телефон покупателя' = T1.PhoneNumber,
	N'Количество купленного товара' = T0.TotalQuantity
from
	PurchaseQuantityPerBuyer T0
	join Buyers T1 on T1.Id = T0.BuyerId
order by
	T1.FIO,
	T1.PhoneNumber

-- 6
;with
TotalRestOnAllShopsPerProduct as (
	select
		ProductId,
		TotalQuantity = sum(Quantity)
	from Rests
	group by ProductId)
select
	N'Наименование товара' = T0.[Name],
	N'Кол-во (общее по всем магазинам) на остатке' = T1.TotalQuantity
from
	Products T0
	join TotalRestOnAllShopsPerProduct T1 on T1.ProductId = T0.Id
	left join Documents T2 on T2.ProductId = T0.Id
where
	T2.Id is null
order by
	T0.[Name]

-- 7
;with
TotalPurchased as (
	select
		ProductId,
		ShopId,
		TotalPurchaseQty = sum(PurchaseQty)
	from Documents
	group by
		ProductId,
		ShopId
),
ProductSalesDynamic as (
	select
		ProductId,
		ShopId,
		PurchaseQty,
		PurchaseDateTime,
		TotalSales = sum(PurchaseQty) over (
			partition by ProductId, ShopId
			order by PurchaseDateTime
			range between unbounded preceding and current row)
	from Documents)
select
	N'Наименование магазина' = T3.[Name],
	N'Наименование товара' = T4.[Name],
	N'Дата и время покупки' = T0.PurchaseDateTime,
	N'Количество на остатке до покупки' = T2.Quantity + T1.TotalPurchaseQty - T0.TotalSales + T0.PurchaseQty,
	N'Количество купленного товара' = T0.PurchaseQty,
	N'Количество на остатке после покупки' = T2.Quantity + T1.TotalPurchaseQty - T0.TotalSales
from
	ProductSalesDynamic T0
	join TotalPurchased T1 on T1.ProductId = T0.ProductId and T1.ShopId = T0.ShopId
	join Rests T2 on T2.ProductId = T0.ProductId and T2.ShopId = T0.ShopId
	join Shops T3 on T0.ShopId = T3.Id
	join Products T4 on T0.ProductId = T4.Id
order by
	T3.[Name],
	T4.[Name],
	T0.PurchaseDateTime
