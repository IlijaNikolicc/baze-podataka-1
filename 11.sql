select *
from Prijave

create procedure unos_nove_prijave(@brojIndeksa int, @godinaUpisa int, @sifraPredmeta int, @sifraNastavnika int)
as
begin
	insert into Prijave (Indeks, Upisan, Spred, Snast, Datump)
	values (@brojIndeksa, @godinaUpisa, @sifraPredmeta, @sifraNastavnika, getdate())
end

exec unos_nove_prijave 2, 2002, 1, 2


alter procedure vise_povratnih(@prva int output, @druga int output, @treca int)
as
begin
	set @prva = @prva - 2
	set @druga = @treca + 2
end

declare @izlaz_prva int = 5
declare @izlaz_druga int

exec vise_povratnih @prva = @izlaz_prva output, @druga = @izlaz_druga output, @treca = 5

select @izlaz_prva, @izlaz_druga

create procedure prosek_nepolozenih_ispita(@brojIndeksa int, @godinaUpisa int, @prosek decimal(6, 2) output, @brojNepolozenih int output)
as
begin
	select @prosek = avg(Ocena*1.0)
	from Prijave
	where Indeks = @brojIndeksa and Upisan = @godinaUpisa and Ocena > 5

	select @brojNepolozenih = count(*)
	from Studenti s join Planst p
	on s.Ssmer = p.Ssmer
	left join Prijave pr
	on s.Indeks = pr.Indeks and s.Upisan = pr.Upisan and pr.Ocena > 5 and p.Spred = pr.Spred
	where pr.Indeks is null and s.Indeks = @brojIndeksa and s.Upisan = @godinaUpisa
end

select *
from Studenti

select *
from Planst

select *
from Prijave


declare @prosecna_ocena decimal(6, 2)
declare @broj_nepolozenih int

exec prosek_nepolozenih_ispita @brojIndeksa = 2, @godinaUpisa = 2002,
@prosek = @prosecna_ocena output, @brojNepolozenih = @broj_nepolozenih output

select 2 as 'indeks', 2002 as 'upisan', @prosecna_ocena as 'prosek', @broj_nepolozenih as 'broj nepolozenih'


create procedure polozen_ispit(@indeks int, @upisan int, @spred int, @snast int, @ocena int)
as
begin
	if exists
	(
		select *
		from Prijave
		where Ocena is null and Indeks = @indeks and Upisan = @upisan
		and Spred = @spred and Snast = @snast
	)
	begin
		update Prijave
		set Ocena = @ocena, Datump = getdate()
		where Ocena is null and Indeks = @indeks and Upisan = @upisan
		and Spred = @spred and Snast = @snast
	end
	else
	begin
		insert into Prijave(Indeks, Upisan, Spred, Snast, Ocena, Datump)
		values (@indeks, @upisan, @spred, @snast, @ocena, getdate())
	end
end

select *
from Prijave
where Ocena is null and Indeks = 8 and Upisan = 2003 and Spred = 1 and Snast = 1

insert into Prijave (Indeks, Upisan, Spred, Snast, Ocena, Datump)
values (8, 2003, 1, 1, null, getdate())

exec polozen_ispit 8, 2003, 1, 1, 10

select *
from Prijave
where Indeks = 8 and Upisan = 2003 and Spred = 1 and Snast = 1


create trigger provera_godine_upisa on Studenti
after insert
as
begin
	if exists
	(
		select *
		from inserted
		where Upisan > datepart(year, getdate())
	)
	begin
		raiserror('Ta skolska godina jos nije pocela', -1, -1)
	end
end

insert into Studenti (Indeks, Upisan, Imes, Mesto, Datr, Ssmer)
values (9, 2024, 'Nenad', 'Beograd', getdate(), 1),
		(10, 2023, 'Nenad', 'Beograd', getdate(), 1),
		(9, 2027, 'Nenad', 'Beograd', getdate(), 1);

select *
from Studenti

alter trigger provera_godine_upisa on Studenti
instead of insert
as
begin
	if exists
	(
		select *
		from inserted
		where Upisan > datepart(year, getdate())
	)
	begin
		raiserror('Ta skolska godina jos nije pocela', -1, -1)
	end
	else
	begin
		insert into Studenti
		select *
		from inserted
	end
end

insert into Studenti (Indeks, Upisan, Imes, Mesto, Datr, Ssmer)
values (100, 2024, 'Nenad', 'Beograd', getdate(), 1),
		(100, 2023, 'Nenad', 'Beograd', getdate(), 1),
		(100, 2027, 'Nenad', 'Beograd', getdate(), 1);

select *
from Studenti

create table ponistene_ocene
(
	Spred int null,
	Indeks int null,
	Upisan int null,
	Snast int null,
	Datump datetime not null,
	Ocena int not null
)

select *
from ponistene_ocene

create trigger arhiva_ponistenih on Prijave
after delete
as
begin
	insert into ponistene_ocene
	select *
	from deleted
end

delete from Prijave
where Indeks = 1 and Upisan = 2000

select *
from Prijave

select *
from ponistene_ocene

select Indeks, Upisan, Spred, Ocena
from Prijave

declare @indeks int
declare @upisan int
declare @spred int
declare @ocena int

declare kursorKrozPrijave cursor for
select Indeks, Upisan, Spred, Ocena from Prijave

open kursorKrozPrijave

fetch next from kursorKrozPrijave into @indeks, @upisan, @spred, @ocena

while @@fetch_status = 0
begin

	print concat(@indeks, ' ', @upisan, ' ', @spred, ' ', @ocena)

	fetch next from kursorKrozPrijave into @indeks, @upisan, @spred, @ocena
end

close kursorKrozPrijave
deallocate kursorKrozPrijave