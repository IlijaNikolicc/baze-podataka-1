select *
from osoba

select *
from Zurka

select *
from Lokacija

select *
from Poseta

--Kreirati tabelu NevalidnePosete po ugledu na tabelu Posete.
create table NevalidnePosete
(
	osoba_id INT, 
	zurka_id INT,
	vremeDolaska DATETIME NOT NULL,
	vremeOdlaska DATETIME NOT NULL,
	primary key (osoba_id,zurka_id),
	foreign key (osoba_id) references Osoba(id),
	foreign key (zurka_id) references Zurka(id),
)

/*Postaviti triger na unos u tabelu Posete kojim se dozvoljava upis samo onih poseta koje su 
validne, dok se nevalidne posete upisuju u tabelu NevalidnePosete. Poseta se smatra 
validnom ukoliko osoba nije istovremeno prisutna na nekoj drugoj žurci unutar zadatog 
vremenskog okvira [vremeDolaska, vremeOdlaska]. Takođe, jedna osoba može samo 
jednom posetiti jednu žurku.*/

go
create trigger provera_poseta on Poseta
instead of insert
as
begin

	declare @osoba_id INT
	declare @zurka_id INT
	declare @vreme_dolaska DATETIME
	declare @vreme_odlaska DATETIME
	declare @broj_zurki INT

	declare kursorKrozPosete cursor for
	select osoba_id, zurka_id, vreme_dolaska, vreme_odlaska from inserted 
	
	open kursorKrozPosete
		
		fetch next from kursorKrozPosete into @osoba_id, @zurka_id, @vreme_dolaska, @vreme_odlaska

		while @@FETCH_STATUS = 0 --dokle god ima ono kupi iz kursora
		begin
			set @broj_zurki = 0
			
			select @broj_zurki = count(*)
			from Poseta
			where osoba_id = @osoba_id and zurka_id != @zurka_id 
			and ((@vreme_dolaska >= vreme_dolaska and vreme_odlaska <= @vreme_odlaska)
			or (@vreme_odlaska >= vreme_odlaska and @vreme_odlaska <= vreme_odlaska)
			or (@vreme_dolaska <= @vreme_dolaska and @vreme_odlaska >= vreme_odlaska))

			if(@broj_zurki > 0) --nevalidna
				begin
					insert into NevalidnePosete (osoba_id, zurka_id, vremeDolaska, vremeOdlaska)
					values(@osoba_id, @zurka_id, @vreme_dolaska, @vreme_odlaska)
				end
			else --validna
				begin
					insert into Poseta(osoba_id, zurka_id, vreme_dolaska, vreme_odlaska)
					values(@osoba_id, @zurka_id, @vreme_dolaska, @vreme_odlaska)
				end

			fetch next from kursorKrozPosete into @osoba_id, @zurka_id, @vreme_dolaska, @vreme_odlaska
		end
	close kursorKrozPosete

	deallocate kursorKrozPosete

end
go

--primer poziva

select *
from Poseta

select *
from NevalidnePosete

INSERT INTO Poseta (osoba_id, zurka_id, vreme_dolaska, vreme_odlaska)
VALUES (1, 2, '2023-05-10 15:00:00', '2023-05-10 22:00:00')


/*
Kreirati funkciju koja za prosleđeni id lokacije vraća tabelu koja sadrži spisak svih 
žurki koje su se na njoj održale (podrazumeva se da na jednoj lokaciji nije moguće 
istovremeno održavanje više od jedne žurke). Tabela treba da sadrzi nazive svih žurki i za 
svaku žurku je potrebno izračunati njenu zaradu. (nazivZurke, vremePocetka, vremeKraja, 
zarada) 
*/
go
create function zurke_i_zarada(@idLokacije int)
returns table
as
return

	select naziv as nazivZurke, vreme_pocetka as vremePocetka, vreme_zavrsetka as vremeKraja,
		(	
			select COUNT(*)
			from Poseta p
			where p.zurka_id = z.id) * z.cena_karte as zarada
		
	from Zurka z
	where @idLokacije = lokacija_id
go

select *
from zurke_i_zarada(1)

select *
from Poseta

select *
from Zurka

/*
Kreirati funkciju koja za prosleđeni id lokacije i vremenski period [odDatuma, 
doDatuma] vraća 1 ukoliko je prihod žurki koje su se hronološki održavale u datom periodu 
rastao, a u suprotnom vraća -1. U obzir se uzimaju žurke koje su i počele i završile se u 
vremenskom okviru [odDatuma, doDatuma].
*/
go
create function hronoloske_zarade(@idLokacije int, @odDatuma datetime, @doDatuma datetime)
returns @table table
(
	nazivZurke varchar(255) not null,
	vremePocetka datetime not null,
	vremeKraja datetime not null,
	zarada float not null,
	brojVecih int not null
)
as
begin
	insert into @table
	select nazivZurke, vremePocetka, vremeKraja, zarada,
	(	select COUNT(*) 
		from zurke_i_zarada(@idLokacije) z2
		where z2.vremePocetka >= @odDatuma and z2.vremeKraja <= @doDatuma
		and z2.zarada > z1.zarada
		and z2.vremePocetka <= z1.vremePocetka
	) as brojVecih
	from zurke_i_zarada(@idLokacije) z1
	where vremePocetka >= @odDatuma and vremeKraja <= @doDatuma
	return
end
go

create function rezultat(@idLokacije int, @odDatuma datetime, @doDatuma datetime)
returns int
as
begin
	declare @brojVecih int

	select @brojVecih = SUM(brojVecih)
	from hronoloske_zarade(@idLokacije, @odDatuma, @doDatuma)

	if(@brojVecih > 0)
		return -1
	return 1
end

select *
from zurke_i_zarada(1)
order by vremePocetka

select *
from hronoloske_zarade(1, '2023-05-10 17:00:00', '2023-06-13 23:00:0')


select dbo.rezultat(1, '2023-05-10 17:00:00', '2023-06-13 23:00:0')

--Kreirati tabelu RastZarade koja sadrži kolone idLokacije, nazivLokacije, 
--datumOd, datumDo i postaviti odgovarajuće strane ključeve ukoliko si potrebni. 

create table RastZarade
(
	idLokacije int not null primary key foreign key references Lokacija(id),
	nazivLokacije varchar(255) not null,
	datumOd datetime not null,
	datumDo datetime not null,
)

/*
Definisati stornu proceduru koja će popuniti tabelu RastZarade tako da unese samo one 
lokacije kod kojih je prihod uvek rastao sa svakom novom žurkom koja se održala na toj 
lokaciji. Ukoliko lokacija već postoji u tabeli RastZarade, potrebno je ažurirati vrednosti u 
tabeli. Storna procedura ima i jedan izlazni parametar koji predstavlja broj lokacija koje 
zadovoljavaju prethodno definisani uslov.

ovako radimo! \/
za svaku lokaciju pamtimo prvi datum kad je bila zurka, i poslednji datum do kad je rasla zarada
*/

go
create procedure popuni_rast_zarade(@brojLokacija int output)
as
begin
	set @brojLokacija = 0

	declare @idZurke int
	declare @naziv varchar(255)
	declare @vremePocetka datetime
	declare @vremeZavrsetka datetime
	declare @idLokacije int
	declare @minDatum datetime


	declare kursorKrozZurke cursor for
	select id, naziv, vreme_pocetka, vreme_zavrsetka, lokacija_id from Zurka

	open kursorKrozZurke
		fetch next from kursorKrozZurke into @idZurke, @naziv, @vremePocetka, @vremeZavrsetka, @idLokacije

		while @@FETCH_STATUS = 0
		begin
			
			select @minDatum = min(vreme_pocetka)
			from Zurka
			where lokacija_id = @idLokacije

			if(dbo.rezultat(@idLokacije,@minDatum,@vremeZavrsetka) = 1)
			begin
				if exists(select * from RastZarade where idLokacije = @idLokacije)
				begin
					update RastZarade
					set	datumDo = @vremeZavrsetka
					where idLokacije = @idLokacije	
				end
				else
				begin
					insert into RastZarade(idLokacije, nazivLokacije, datumOd, datumDo)
					values (@idLokacije, @naziv, @vremePocetka, @vremeZavrsetka)

					set @brojLokacija = @brojLokacija + 1
				end
			end
			fetch next from kursorKrozZurke into @idZurke, @naziv, @vremePocetka, @vremeZavrsetka, @idLokacije
		end

	close kursorKrozZurke
	deallocate kursorKrozZurke
end
go

declare @broj_lokacija int

exec popuni_rast_zarade @brojLokacija = @broj_lokacija output

select @broj_lokacija
select *
from RastZarade












