Moteve Swing 0.2.1 - WoW Forever (Interface 16001)
Swing timer "Arkán üveg" stílusban, mint a többi Moteve addon.

TELEPÍTÉS
  A "MoteveSwing" mappát másold a WoW Forever Interface\AddOns mappájába, majd /reload.
  Elhelyezés: /msw -> fogd meg az üveg-dobozt és húzd a helyére -> /msw

MIT MUTAT
  - Fő kéz: vékony cián-lila izzó csík, a végén fénypont; fölötte balra a fegyver sebessége,
    jobbra a következő ütésig hátralévő idő. Ütéskor rövid felvillanás.
  - Off-hand (két fegyvernél): vékonyabb lila csík alatta.
  - Távolsági (Auto Shot, wand, dobás): arany csík.
  - Csak auto-attack / auto shot közben látszik, utána elhalványul.

PARANCSOK (/msw)
  (üres) | unlock | lock   mozgatás be / ki
  scale 0.5-2          méret
  offhand              off-hand csík be / ki
  ranged               távolsági csík be / ki
  text                 számok be / ki
  debug                észlelt ütések kiírása a chatbe
  reset                alaphelyzet

HOGYAN ÉRZÉKELI AZ ÜTÉSEKET?
  WoW Foreveren az addonok nem látják a combat logot. A timer ezért a célpontod sebződési
  eseményeiből (fizikai találat, miss, dodge, parry, block) ismeri fel a saját ütéseidet:
  egy találat akkor számít a te ütésednek, ha a fegyvered addigra már üthetett (a swing-idő
  legalább 75%-a eltelt). A csík mindig a legutóbbi valódi ütéstől indul, magától nem pörög:
  ha ütésre kész a fegyver, a teli csík lassan "lélegzik", amíg meg nem jön a következő ütés.
  Heroic Strike, Cleave, Maul, Raptor Strike és Slam is újraszinkronizál.
  Korlát: ha többen ütik ugyanazt a mobot, egy-egy idegen találat ritkán elcsúsztathatja.
  Ellenőrzés: /msw debug - minden észlelt ütést kiír a chatbe a mért idővel.
  A távolsági timer pontos: minden lövés külön esemény a játékban.
  Betűtípus: Barlow (SIL Open Font License, a Fonts mappában a licenccel).
