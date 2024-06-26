select *
from Nastavnici

select *
from Angazovanje


select *
from Nastavnici n
where not exists (
				select *
				from Angazovanje a
				where n.Snast = a.Snast
			)


select *
from Angazovanje a1
where exists ( 
				select *
				from Angazovanje a2
				where a1.Snast != a2.Snast and a1.Spred = a2.Spred
			  )

--Spisak studenata koji imaju bar jedan polozen ispit

select Indeks, Upisan, Imes
from Studenti
where exists ( 
				select *
				from Prijave
				where Studenti.Indeks = Prijave.Indeks
				and Studenti.Upisan = Prijave.Upisan
				and Prijave.Ocena > 5
)

--Spisak studenata koji imaju prosek veci od 7.5

select Indeks, Upisan, avg(ocena * 1.0) as prosek
from Prijave p1
where Ocena > 5
group by Indeks, Upisan
having AVG(ocena * 1.0) > 7.5

select Indeks, Upisan, Imes
from Studenti s
where exists ( 
				select Indeks, Upisan, avg(ocena * 1.0) as prosek
				from Prijave p1
				where Ocena > 5 and s.Indeks = p1.Indeks and s.Upisan = p1.Upisan 
				group by Indeks, Upisan
				having AVG(ocena * 1.0) > 7.5
				)

--Spisak studenata koji ima barem jednog druga (iz istog grada i ista godina upisa)

select * 
from Studenti s1
where exists  ( 
				select *
				from Studenti s2
				where s1.Indeks != s2.Indeks and s1.Upisan = s2.Upisan and s1.Mesto = s2.Mesto
				)


-- izlistati imena nastavnika i sifre predmeta koje predaju.

select * 
from Nastavnici n left join Angazovanje a
on n.Snast = a.Snast

select * 
from Nastavnici n right join Angazovanje a
on n.Snast = a.Snast


select * 
from Nastavnici n full join Angazovanje a
on n.Snast = a.Snast

--Izlistati imena nastavnika i sifre predmeta koje predaju (u skupu trebaju da se nadju i nastavnici koji nisu angazovani)

select * 
from Nastavnici n left join Angazovanje a
on n.Snast = a.Snast

--Spisak nastavnika koji nisu angazovani.

select * 
from Nastavnici n left join Angazovanje a
on n.Snast = a.Snast
where a.Snast is null

--Spisak nastavnika i predmeta (samo sifre) koji dele predmet sa jos nekim

select *
from Angazovanje a1 inner join Angazovanje a2
on a1.Snast != a2.Snast and a1.Spred = a2.Spred

--Izlistati imena nastavnika i NAZIVE predmeta koje predaju

select n.Imen, p.NAZIVP
from Nastavnici n inner join Angazovanje a1
on n.Snast = a1.Snast
join PREDMETI p
on a1.Spred = p.SPRED

--Spisak brucosa koji imaju druga na fakultetu (iz istog mesta i ista godina upisa)

select max(Upisan)
from Studenti

select *
from Studenti s1 inner join Studenti s2
on s1.Indeks != s2.Indeks and s1.Upisan = s2.Upisan and s1.Mesto = s2.Mesto
where s1.Upisan in (
						select max(Upisan)
						from Studenti 
					)

--Spisak studenata (indeks, upisan, ime studenta) koji imaju bar jedan polozen ispit

select distinct s.Indeks, s.Upisan, s.Imes
from Studenti s join Prijave p 
on s.Indeks = p.Indeks and s.Upisan = p.Upisan
where Ocena > 5

--Spisak studenata koji imaju prosek veci od 7.5


select s.Indeks, s.Upisan, s.Imes, AVG(p.Ocena * 1.0) as 'prosecna ocena'
from Studenti s join Prijave p 
on s.Indeks = p.Indeks and s.Upisan = p.Upisan
where Ocena > 5
group by s.Indeks, s.Upisan, s.Imes
having AVG(p.Ocena * 1.0) > 7.5

--Maksimalna ocena za svaki predmet

select p1.SPRED, p1.NAZIVP, max(Ocena) as 'najvisa ocena'
from PREDMETI p1 join Prijave p2
on p1.SPRED = p2.Spred 
group by p1.SPRED, p1.NAZIVP     