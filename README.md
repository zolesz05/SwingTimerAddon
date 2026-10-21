# Moteve Swing

**Moteve Swing** egy World of Warcraft swing timer a WoW Forever klienshez. Vékony, fénylő sávokon mutatja a főkéz, az off-hand és a távolsági automatikus támadások időzítését, a többi Moteve addonhoz illő „arkán üveg” stílusban.

**Aktuális verzió: 0.2.1**

[Legfrissebb addon letöltése (ZIP)](downloads/MoteveSwing.zip?raw=true)

A `downloads` mappában csak a legfrissebb telepíthető `MoteveSwing.zip` szerepel. Frissítéskor ugyanaz a letöltési link használható.

## Telepítés

1. Töltsd le és csomagold ki a fenti ZIP-et.
2. Másold a `MoteveSwing` mappát a játék `Interface/AddOns/` könyvtárába.
3. A karakterválasztón engedélyezd a **Moteve Swing** addont, majd lépj be.
4. Írd be: `/msw`, húzd a megjelenő üvegdobozt a kívánt helyre, majd újra `/msw` a rögzítéshez.

```text
Interface/
└── AddOns/
    └── MoteveSwing/
        ├── MoteveSwing.toc
        ├── Swing.lua
        ├── Theme.lua
        ├── Fonts/
        └── Textures/
```

A mappanevet tartsd meg: a `MoteveSwing.toc` közvetlenül a `MoteveSwing` mappában legyen. Ha egy új addon még nem jelenik meg a listában, indítsd újra a klienst. Meglévő addon frissítése után `/reload` használható. A `WTF` könyvtárban vannak a mentett beállítások; azt tartsd meg.

## Mit mutat?

| Sáv | Megjelenés és szerep |
| --- | --- |
| Főkéz | Cián–lila fénylő csík, a végén fénypont; ütéskor rövid felvillanás |
| Off-hand | Vékonyabb lila sáv a főkéz alatt, két fegyvernél |
| Távolsági | Arany sáv az Auto Shot, wand és dobás időzítéséhez |

A számok a fegyver sebességét és a következő támadásig hátralévő időt mutatják. A sávok automatikus támadás / lövés közben jelennek meg, utána elhalványulnak. A számok, az off-hand és a távolsági sáv külön kapcsolhatók.

## Mozgatás és méret

A `/msw` vált a rögzített és mozgatható állapot között. Feloldva egy nagyobb üvegdoboz segíti a megfogást; a sávok húzása is működik. A pozíció rögzítéskor mentődik.

A méret **50–200%** között állítható. Például `/msw scale 0.85` a normál méret 85%-át állítja be.

## Parancsok

| Parancs | Művelet |
| --- | --- |
| `/msw` | Mozgatás be- és kikapcsolása |
| `/msw unlock` vagy `/msw move` | Mozgatás feloldása |
| `/msw lock` | Pozíció rögzítése |
| `/msw scale 0.85` | Méret beállítása; tartomány: 0.5–2 |
| `/msw offhand` | Off-hand sáv kapcsolása |
| `/msw ranged` | Távolsági sáv kapcsolása |
| `/msw text` | Számok megjelenítésének kapcsolása |
| `/msw debug` | Észlelt ütések és mért idők chatbe írásának kapcsolása |
| `/msw reset` | Az ablak pozíciójának alaphelyzetbe állítása |

A `/moteveswing` a `/msw` alternatívája. A beállítások a `MoteveSwingDB` változóban maradnak meg.

## Ütésérzékelés és korlátok

A közelharci timer a célpont sebződési eseményei és a fegyver sebessége alapján szinkronizál. Egy lehetséges találatot akkor fogad el saját ütésként, ha a swing-idő legalább 75%-a eltelt. Fizikai találat, miss, dodge, parry és block eseményeket is figyelembe vesz.

A csík az észlelt ütéstől indul; magától nem kezd új ciklust. Ha a fegyver már ütésre kész, a megtelt sáv „lélegzik” a következő észlelt ütésig. A Heroic Strike, Cleave, Maul, Raptor Strike és Slam is újraszinkronizálhatja.

Ha többen támadják ugyanazt a célpontot, egy másik játékos találata eltolhatja a közelharci időzítést. A `/msw debug` segít megnézni, milyen eseményeket érzékelt. A távolsági timer a lövések külön játékeseményeit használja.

## Kompatibilitás és ellenőrzés

A célkliens **WoW Forever**, a TOC Interface-értéke **16001**. Más WoW-verziókkal való működés nincs igazolva.

A csomag a jelenleg telepített **0.2.1-es verzió** változatlan másolata. Feltöltés előtt a fájlok azonosságát, a Lua-szintaxist és a ZIP tartalmát ellenőriztük. A tényleges harci időzítést és megjelenítést a feltöltéskor nem teszteltük újra.

## Hibajelentés és források

Hibát az [Issues oldalon](https://github.com/zolesz05/SwingTimerAddon/issues) jelezhetsz. Add meg a kliens és az addon verzióját, a karakter kasztját, a használt fegyvereket és azok sebességét, valamint a reprodukálás lépéseit. A `/msw debug` kimenete segíthet.

- [Teljes addonforrás](MoteveSwing/)
- [Részletes használati leírás](MoteveSwing/README.txt)
- Barlow és Marcellus betűtípusok: SIL Open Font License, a licencfájlok a `MoteveSwing/Fonts/` könyvtárban találhatók.

## Csomag frissítése

A repository gyökeréből:

```sh
python tools/package_addon.py
```

A csomagoló ellenőrzi a TOC bejegyzéseit és a ZIP tartalmát, lecseréli a `downloads/MoteveSwing.zip` fájlt, és eltávolítja a korábbi verziószámos addoncsomagokat ebből a mappából. A forrást, a ZIP-et és a README-t együtt kell feltölteni.
