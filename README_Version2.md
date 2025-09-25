# Projekt SQL pro Datovou Akademii Engeto  
*(kurz od 12. 8. 2025)*

**Zpracovala:** Katarína Petrželová  
**E-mail:** kat.borovska@gmail.com

---

## Komentář k vytvoření primární tabulky s mzdami a cenami

Do primární tabulky jsem doplnila nový sloupec `typ`, abych pro další výpočty odlišila **mzdy a ceny**.  
Místo kódů pro průmyslová odvětví a kategorie jsem použila **názvy**, napojením vedlejších tabulek.  
U hodnot je použita agregační funkce `AVG`. Věřím, že to není proti zadání a ulehčí to práci při řešení jednotlivých výzkumných otázek.

### Poznatky při zkoumání dat:
- Ceny potravin byly sledovány v letech **2006–2018**, mzdy v letech **2000–2021**
- Počet oborů sledovaný u mezd byl ve všech letech stejný, u potravin byla v roce 2011 přidána nová kategorie *(Víno bílé)*
- Frekvence záznamů o cenách byla vyšší v prvních letech (týdně), poté došlo ke snížení počtu záznamů v roce
- Ceny u specifické kategorie **Kapr** byly sledovány jen v prosinci – v období Vánoc, kdy naopak chybí záznamy u jiných kategorií
- Další omezení viz komentáře k jednotlivým otázkám

---

## Výzkumná otázka č. 1

**Rostou v průběhu let mzdy ve všech odvětvích, nebo v některých klesají?**

### Způsoby řešení:
- **Varianta A** – procentní nárůst mezi mzdou v prvním a posledním sledovaném období  
    - Použita dvě CTE (první a poslední období)
    - Ve výsledku jsou i původní hodnoty pro kontrolu
    - Exportováno do grafu

- **Varianta B** – průměr procentních růstů mezi jednotlivými roky  
    - Výpočet ročních přírůstků
    - CTE pomocí JOIN se stejnou tabulkou posunutou o rok
    - Alternativa s `LAG()` (použita v otázce č. 5)

> **Odpověď:** Obě varianty dávají podobný výsledek – **mzdy v průběhu let rostou**.  
> Nejpomalejší růst: *Těžba a dobývání, Ostatní činnosti, Doprava a skladování*  
> Nejrychlejší růst: *Zdravotní a soc. péče, Výroba a rozvod elektřiny, Vzdělávání, IT a komunikace*

---

## Výzkumná otázka č. 2

**Kolik je možné si koupit litrů mléka a kilogramů chleba za první a poslední srovnatelné období?**

- Ceny mají kratší časové pokrytí než mzdy
- Výpočty omezeny na roky dostupné pro obě datové sady
- Dvě varianty: jedna s CTE, druhá bez

> **Odpověď:** V roce 2018 je ve všech odvětvích možné koupit **více litrů mléka za mzdu než dříve**

---

## Výzkumná otázka č. 3

**Která kategorie potravin zdražuje nejpomaleji? (nejnižší meziroční nárůst)**

- CTE se spojením tabulky se stejnou tabulkou posunutou o rok
- Alternativa s `LAG()` (použita jinde)
- Ověření pomocí kontingenční tabulky a grafu

> **Odpověď:**  
> - Záporné přírůstky: *Cukr krystal, rajská jablka*  
> - Nejnižší kladné přírůstky: *Banány, vepřová pečeně*  
> Výpovědní hodnota omezena kvalitou a strukturou dat (např. Kapr jen v prosinci)

---

## Výzkumná otázka č. 4

**Existuje rok, kdy byl nárůst cen výrazně vyšší než růst mezd? (více než 10 %)**

- JOIN a CTE s výpočtem přírůstků
- Výpočet rozdílu mezi přírůstky cen a mezd

> **Odpověď:** Ne, v žádném roce ceny **nerostly o více než 10 % více** než mzdy.  
> V roce **2009** ceny **výrazněji klesly**, zatímco mzdy mírně rostly → rozdíl 9,5 %.  
> Problém: používám **prostý průměr**, vhodnější by byl **vážený průměr** – ale chybí váhová data (počty zaměstnanců, spotřební koš apod.)

---

## Výzkumná otázka č. 5

**Má výška HDP vliv na změny ve mzdách a cenách potravin?**

- Použita doplňková tabulka s HDP, GINI a populací evropských států  
    *(získáno z tabulky `economies` a `countries` pomocí vnořeného SELECTu)*
- Některá data chybí (zejména GINI)
- Porovnání provedeno pouze pro **Českou republiku**
- HDP přepočteno na **obyvatele**
- Výpočty pomocí `LAG()` a CTE

> **Odpověď:**  
> - V roce **2009** ceny i HDP **výrazně klesly**, mzdy méně  
> - V roce **2010** podobný přírůstek u všech tří ukazatelů  
> - Do r. 2012 HDP klesalo, ale ceny a mzdy rostly  
> - Trend se v r. 2012 otočil  
> - Po roce 2010: HDP a ceny jdou **opačným směrem**  
> - Celkový trend **rostoucí**, až na krizi 2008–2009