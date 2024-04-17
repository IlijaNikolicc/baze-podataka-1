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
