--1. Koliko je svake godine odigrano utakmica. (godina, broj_odigranih_utakmica)

select *
from sezona

select *
from utakmice


select s.godina, COUNT(*) as broj_odigranih_utakmica 
from sezona s join utakmice u
on s.id=u.id_sezone
group by s.godina


--2. Igrač koji je sklopio ugovor na najduži period. (id_igraca, period_u_danima)select *, DATEDIFF(DAY,datum1,datum2) as period_u_danimafrom ugovoriselect u1.id_igraca, DATEDIFF(DAY,u1.datum1,u1.datum2) as period_u_danimafrom ugovori u1 left join ugovori u2on DATEDIFF(DAY,u1.datum1,u1.datum2) < DATEDIFF(DAY,u2.datum1,u2.datum2)where u2.id is nullgocreate view trajanje_ugovora asselect id_igraca, DATEDIFF(day,datum1,datum2) as period_u_danimafrom ugovorigoselect *from trajanje_ugovorawhere period_u_danima = (							select max(period_u_danima)							from trajanje_ugovora						)--3. Za svakog igrača koliko je postigao ukupno golova računajući i autogolove (ugnježdeni).
(ime, broj_golova) - nije dozvoljeno koristiti join mehanizam

select i.ime, (select count(*)
			from golovi g
			where i.id = g.id_igraca) as broj_golova
from igraci i


--4. Spisak fudbalera koji su odigrali više od 3 utakmice u nekoj od sezona. (godina,
id_igraca, broj_utakmica)


go
create view domacin_gost_godina as
select u.id_domacina,u.id_gosta,s.godina
from utakmice u join sezona s
on u.id_sezone=s.id
go


select d.godina,u.id_igraca, count(*) as broj_utakmica
from ugovori u join domacin_gost_godina d
on (u.id_tima=d.id_domacina or u.id_tima=d.id_gosta)
and d.godina between DATEPART(YEAR,u.datum1) and DATEPART(YEAR,u.datum2)
group by d.godina,u.id_igraca
having count(*)>3



--5. Rezultat svake utakmice. (id_utakmice, nazivTimaDomacina, nazivTimaGosta,
--rezultat) - rezultat treba da bude u formatu “brojGolovaDomacina:brojGolovaGosta”
go
create view utakmice_sa_nazivom_tima as
select u.id, u.id_domacina, u.id_gosta, t1.naziv as nazivTimaDomacina, t2.naziv as nazivTimaGosta
from utakmice u join timovi t1
on u.id_domacina=t1.id
join timovi t2
on u.id_gosta=t2.id
go

select u.id as id_utakmice, u.nazivTimaDomacina, u.nazivTimaGosta,
						concat(
						(select count(*)
						from golovi g
						where g.id_utakmice=id_utakmice and 
						g.id_tima=u.id_domacina),
						':',
						(select count(*)
						from golovi g
						where g.id_utakmice=id_utakmice and 
						g.id_tima=u.id_gosta)) as rezultat
from utakmice_sa_nazivom_tima u 



--6. Igrač sa najviše postignutih autogolova. 
--(id_igraca, ime, broj_autogolova)

go
create view utakmice_godina as
select u.id, u.id_domacina, u.id_gosta, s.godina
from utakmice u join sezona s
on u.id_sezone = s.id
go


go
create view utakmica_igrac_tim as
select ug.id, u.id_igraca, u.id_tima 
from ugovori u join utakmice_godina ug
on (u.id_tima = ug.id_domacina or u.id_tima = ug.id_gosta) 
and ug.godina between DATEPART(YEAR,u.datum1) and DATEPART(YEAR,u.datum2)
go

go
create view igrac_autogolovi as
select u.id_igraca, count(*) as broj_autogolova
from utakmica_igrac_tim u join golovi g
on u.id=g.id_utakmice and u.id_igraca=g.id_igraca
and u.id_tima != g.id_tima
group by u.id_igraca
go

select b.id_igraca, i.ime, b.broj_autogolova
from igraci i join igrac_autogolovi b
on i.id = b.id_igraca
where b.broj_autogolova = (select max(broj_autogolova)
						from igrac_autogolovi)



	
