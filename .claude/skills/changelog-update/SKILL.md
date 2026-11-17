---
name: changelog-update
description: >
  Aktualizace CHANGELOG.md v projektu Home Control. Zjistí změny od posledního zápisu
  do changelogu (commity i necommitnuté změny), navrhne novou verzi, zeptá se uživatele,
  na jakou verzi povýšit, zapíše novou sekci se stručným seznamem změn a povýší číslo
  verze i v README.md, config/initializers/home_control.rb, .env.example a BUILD.md. Použij, když
  uživatel řekne „aktualizuj changelog“, „povyš verzi“, „nová verze“, „release notes“
  nebo zavolá /changelog-update.
allowed-tools: Bash(git log:*), Bash(git show:*), Bash(git diff:*), Bash(git status:*), Bash(git grep:*), Bash(grep:*), Bash(date:*)
---

# Changelog update

Cíl: do `CHANGELOG.md` přidat novou sekci verze se stručným seznamem změn od posledního
zápisu, včetně necommitnutých změn, a povýšit číslo verze ve všech souborech, kde je
uvedené. Nic necommituj.

## 1. Výchozí stav

1. Přečti začátek `CHANGELOG.md`. Aktuální verze je první nadpis ve tvaru
   `## Home Control X.Y.Z (YYYY-MM-DD)`. (Starší sekce mají i tvar `X.Y` a datum `YYYY-MM`;
   nová sekce má vždy `X.Y.Z` a plné datum.)
2. Najdi poslední commit, který měnil changelog, a jeho čas:
   ```
   git log -1 --format='%H %cI' -- CHANGELOG.md
   ```
   Dál ho označuji `BASE` a jeho čas `BASE_TIME`.

## 2. Sběr změn

### Commity od posledního zápisu

```
git log --no-merges --since="BASE_TIME" --format='%h %cI %s' BASE..HEAD
```

Filtr `--since` je nutný: větve mergnuté až po posledním zápisu do changelogu přinášejí
i starší commity, které už v changelogu popsané jsou (např. commity `v3.5.x`).
Pokud nějaký commit přesto popisuje změnu, která v changelogu už je (zpráva `vX.Y.Z`
pro existující verzi nebo stejné téma v posledních sekcích), vynech ho.

Jako souhrn **nepoužívej** `git diff BASE..HEAD`. Kvůli merge může obsahovat stovky souborů
už popsaných změn. Pro každý commit si udělej `git show --stat <sha>`, a když zpráva
nestačí k pochopení změny, podívej se do diffu konkrétních souborů (`git show <sha> -- <soubor>`).

### Necommitnuté změny

```
git status --porcelain
git diff HEAD --stat
git diff HEAD
```

- Nové soubory (`??`) přečti, pokud jsou relevantní (ne logy, tmp, build výstupy,
  ne nastavení AI nástrojů v `.claude/`, `.cursor/`, `.agents/`).
- U `Gemfile.lock` vytáhni jen podstatné změny verzí (Rails, Puma, hlavní gemy), ne celý seznam.
- Verzi Ruby ber z `.ruby-version`.

Pokud nejsou žádné nové commity ani necommitnuté změny, řekni to uživateli a skonči.

## 3. Návrh položek

Drž styl existujícího changelogu:

- Anglicky.
- Každá položka na jednom řádku ve tvaru `  * ` (dvě mezery, hvězdička, mezera).
- Stručně, z pohledu uživatele nebo provozovatele aplikace. Typické formulace:
  `Added …`, `Fixed …`, `Bugfix: …`, `Ruby upgraded to 3.4.10`, `Rails updated to 7.2`,
  `Dockerfile: …`.
- Obvykle 2–8 položek. Související drobnosti slouč do jedné položky.
- Vynech šum: merge commity, překlepy, čistě testové úpravy (pokud nejde o velkou změnu
  testů), formátování, samotný CHANGELOG, povýšení čísla verze.
- U upgradů uveď komponentu a novou verzi.
- Pokud změna vyžaduje ruční krok při aktualizaci (úprava `docker-compose.yml`, nová ENV
  proměnná, ruční migrace dat, nová verze firmware), napiš to jako samostatnou položku
  s konkrétním návodem (vzor: sekce 3.4.1).

## 4. Návrh verze

Vycházej z aktuální verze `X.Y.Z`:

- **patch** `X.Y.(Z+1)`: bugfixy, úpravy UI, aktualizace gemů, patch upgrade Ruby,
  drobná vylepšení. Projekt sem dává i menší nové funkce (např. 3.5.1 chart widgets).
- **minor** `X.(Y+1).0`: větší nové funkce (nový typ widgetu nebo zařízení), upgrade Rails
  nebo nové hlavní verze Ruby, výměna frontend stacku, změny vyžadující ruční krok
  při aktualizaci.
- **major** `(X+1).0.0`: nekompatibilní změny (data, firmware, způsob nasazení).

Když váháš, vyber nižší stupeň.

## 5. Dotaz na uživatele

Zeptej se **jednou** otázkou s výběrem z možností a počkej na odpověď:

- Claude Code: nástroj `AskUserQuestion` (header `Verze`).
- Cursor: nástroj pro dotazy na uživatele (ask questions), pokud je k dispozici.
  Jinak polož otázku v chatu s očíslovanými možnostmi a skonči odpověď, dokud uživatel
  neodpoví.

Otázka: „Na jakou verzi povýšit? Aktuální je X.Y.Z.“

- 1. možnost: navržená verze s „(Recommended)“. K ní jedna věta, proč tento stupeň.
- 2. a 3. možnost: zbylé stupně (patch/minor/major).
- 4. možnost: `Doplnit do X.Y.Z`: položky se přidají do stávající poslední sekce
  (pro případ, že aktuální verze ještě nebyla vydaná).
- Vlastní číslo verze: v Claude Code přes automatickou možnost „Other“, v chatu volným textem.

Uživatel musí vidět, co přesně se zapíše:

- `AskUserQuestion`: ke každé možnosti dej do `preview` celou výslednou sekci přesně tak,
  jak bude zapsaná (nadpis s dnešním datem a odrážky; u možností se liší jen číslo verze,
  u `Doplnit do X.Y.Z` celá stávající sekce s doplněnými položkami).
- Nástroj bez náhledu nebo dotaz v chatu: před otázku napiš navrženou sekci jako blok kódu.

Po odpovědi:

- Pokud uživatel v odpovědi nebo v poznámce k volbě (annotations) upravil položky,
  použij jeho znění.
- Vlastní verze musí být vyšší než aktuální. Pokud není, upozorni na to a zeptej se znovu.
- Při volbě `Doplnit do X.Y.Z` se číslo verze nemění a datum v nadpisu sekce zůstává.

## 6. Zápis

1. Dnešní datum zjisti pomocí `date +%F`.
2. Novou sekci vlož do `CHANGELOG.md` hned nad první nadpis `## Home Control` (pod navigační
   řádek s odkazy). Mezi sekcemi nech jeden prázdný řádek:
   ```
   ## Home Control X.Y.Z (YYYY-MM-DD)
     * First change
     * Second change

   ## Home Control <předchozí verze> (...)
   ```
3. **Vždy** (kromě volby `Doplnit do X.Y.Z`) povyš číslo verze i v dalších souborech,
   uživatele se na to neptej. Starou verzi nahraď novou v:
   - `README.md`: první řádek `# Home Control X.Y.Z`. README se v minulosti zapomínalo
     aktualizovat, takže tam může být i starší verze než ta předchozí. Nadpis nastav
     na novou verzi bez ohledu na to, jaké číslo v něm je.
   - `config/initializers/home_control.rb`: `version: "X.Y.Z"`
   - `.env.example`: `HOME_CONTROL_VERSION=X.Y.Z`
   - `BUILD.md`: tag `robertcigan/home_control:X.Y.Z` v příkazu `docker buildx build`

   `docker-compose.yml` bere tag image z `${HOME_CONTROL_VERSION}`, tam se nic nemění.

   Nesahej na `Gemfile.lock` (gemy můžou mít shodné číslo verze, např. `sprockets-rails`)
   ani na `docs/APP_BEHAVIOR.md` (generovaný dokument s vlastním datem), pokud o to
   uživatel výslovně nepožádá.
4. Ověř, že stará verze aplikace nikde nezůstala:
   ```
   git grep -nF "<stará verze>" -- . ':!Gemfile.lock' ':!CHANGELOG.md' ':!docs/APP_BEHAVIOR.md'
   ```
   Zkontroluj zvlášť i nadpis README (grep na starou verzi ho nenajde, pokud v něm byla
   ještě starší verze):
   ```
   grep -n -m1 "^# Home Control" README.md
   ```
   Pokud najdeš další místo, kde jde o verzi Home Control (ne o verzi gemu nebo JS
   knihovny se shodným číslem), uprav ho taky a uveď ho ve výstupu.
5. Necommituj.

## 7. Výstup

Krátce shrň: zapsanou sekci (jako blok kódu) a seznam upravených souborů.
