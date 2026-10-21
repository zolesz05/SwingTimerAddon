-- Moteve Swing - swing timer in the "arcane glass" style of the other Moteve addons.
--
-- WoW Forever gives addons no combat log, so the timer detects your melee swings from the
-- UNIT_COMBAT event of your target (physical hit, miss, dodge, parry, block on the mob you are
-- attacking). A hit only counts as your swing when your weapon could have swung by then, so
-- most hits from others are ignored. The bar always starts from the last real swing; it never
-- loops on its own. "On next swing" abilities (Heroic Strike, Cleave, Maul, Raptor Strike) and
-- Slam also resync it. Ranged (Auto Shot, wands, thrown) is exact: every shot is a spell cast.
local ADDON_NAME, ns = ...
local C = ns.C
local format, max, min, floor = string.format, math.max, math.min, math.floor

local WIDTH, MH_H, OH_H = 240, 4, 3

local DEFAULTS = {
    point = "CENTER", relPoint = "CENTER", x = 0, y = -180,
    scale = 1, locked = true, offhand = true, ranged = true, text = true,
}

-- abilities that replace the next melee swing (their cast succeeds when the swing lands)
local NEXT_SWING = {}
for _, id in ipairs({ 78, 284, 285, 1608, 11564, 11565, 11566, 11567, 25286,   -- Heroic Strike
                      845, 7369, 11608, 11609, 20569,                          -- Cleave
                      2973, 14260, 14261, 14262, 14263, 14264, 14265, 14266,   -- Raptor Strike
                      6807, 6808, 6809, 8972, 9745, 9880, 9881 }) do          -- Maul
    NEXT_SWING[id] = true
end
-- Slam: the swing timer restarts when the cast finishes
local RESET_SWING = { [1464] = true, [8820] = true, [11604] = true, [11605] = true }
-- ranged auto attacks: Auto Shot, Shoot (wand), Shoot Bow / Gun / Crossbow, Throw
local RANGED = { [75] = true, [5019] = true, [2480] = true, [7918] = true, [7919] = true, [2764] = true }

local secret = issecretvalue or function() return false end

---------------------------------------------------------------------------
-- State
---------------------------------------------------------------------------
local db
local attacking = false
local debug = false
local function Dbg(msg) if debug then print("|cffa88bffMoteve Swing|r " .. msg) end end
local mh = { last = 0, speed = 2 }
local oh = { last = 0, speed = 0 }
local rg = { last = 0, speed = 0, active = false }

local function Speeds()
    local ok, a, b = pcall(UnitAttackSpeed, "player")
    if ok and a and not secret(a) and a > 0 then
        mh.speed = a
        oh.speed = (b and not secret(b) and b > 0) and b or 0
    end
    local okR, r = pcall(UnitRangedDamage, "player")
    if okR and r and not secret(r) and r > 0 then rg.speed = r end
end

-- keep the progress of a running swing when the speed changes (haste, weapon swap)
local function Rescale(h, newSpeed)
    if not newSpeed or newSpeed <= 0 then return end
    local now = GetTime()
    if h.speed > 0 and now - h.last < h.speed then
        local f = (now - h.last) / h.speed
        h.last = now - f * newSpeed
    end
    h.speed = newSpeed
end

local function Swing(h, now)
    h.last = now or GetTime()
end

---------------------------------------------------------------------------
-- Display
---------------------------------------------------------------------------
local F = CreateFrame("Frame", "MoteveSwingFrame", UIParent)
F:SetSize(WIDTH, 24)
F:SetFrameStrata("MEDIUM")
F:SetMovable(true)
F:SetClampedToScreen(true)
F:Hide()

-- shown only while unlocked
local box = CreateFrame("Frame", nil, F)
box:SetPoint("TOPLEFT", -10, 22)
box:SetPoint("BOTTOMRIGHT", 10, -8)
ns.Glass(box, { radius = 10, alpha = 0.7, edge = 0.35 })
box.text = ns.Font(box, "bold", 10, C.sub)
box.text:SetPoint("TOPLEFT", 10, -6)
box.text:SetText("MOTEVE SWING  ·  húzd ide, majd /msw")
box:Hide()

local function Bar(parent, height, c1, c2, glowC)
    local b = CreateFrame("Frame", nil, parent)
    b:SetSize(WIDTH, height)
    b.track = b:CreateTexture(nil, "BACKGROUND")
    b.track:SetAllPoints()
    b.track:SetTexture(ns.WHITE)
    b.track:SetVertexColor(1, 1, 1, 0.1)
    b.shade = b:CreateTexture(nil, "BACKGROUND", nil, -1)
    b.shade:SetPoint("TOPLEFT", -1, 1); b.shade:SetPoint("BOTTOMRIGHT", 1, -1)
    b.shade:SetTexture(ns.WHITE)
    b.shade:SetVertexColor(0, 0, 0, 0.45)
    b.glow = ns.Img(b, "glow", "ARTWORK", 0, glowC, 0.5)
    b.glow:SetBlendMode("ADD")
    b.fill = b:CreateTexture(nil, "ARTWORK", nil, 1)
    b.fill:SetPoint("TOPLEFT"); b.fill:SetPoint("BOTTOMLEFT")
    ns.Grad(b.fill, "HORIZONTAL", c1, 1, c2, 1)
    b.glow:SetPoint("TOPLEFT", b.fill, "TOPLEFT", -4, 5)
    b.glow:SetPoint("BOTTOMRIGHT", b.fill, "BOTTOMRIGHT", 4, -5)
    -- spark at the leading edge
    b.spark = ns.Img(b, "glow", "OVERLAY", 1, { 1, 1, 1 }, 0.9)
    b.spark:SetBlendMode("ADD")
    b.spark:SetSize(height * 4, height * 4)
    b.spark:SetPoint("CENTER", b.fill, "RIGHT", 0, 0)
    -- flash when the swing is ready
    b.flash = ns.Img(b, "glow", "OVERLAY", 2, c2, 0)
    b.flash:SetBlendMode("ADD")
    b.flash:SetPoint("TOPLEFT", -8, 8); b.flash:SetPoint("BOTTOMRIGHT", 8, -8)
    b.flashA = 0
    function b:Set(p)
        p = max(0, min(1, p))
        local w = WIDTH * p
        if w < 0.5 then self.fill:Hide(); self.glow:Hide(); self.spark:Hide()
        else self.fill:Show(); self.glow:Show(); self.fill:SetWidth(w); self.spark:SetShown(p < 1) end
    end
    return b
end

local MH = Bar(F, MH_H, C.cyan, C.violet, C.violet)
MH:SetPoint("TOP", 0, 0)
local OH = Bar(F, OH_H, C.violet, C.violetPale, C.violet)
OH:SetPoint("TOP", MH, "BOTTOM", 0, -5)
local RG = Bar(F, MH_H, C.gold, C.goldSoft, C.gold)
RG:SetPoint("TOP", MH, "BOTTOM", 0, -5)

local mhText = ns.Font(F, "bold", 11, C.text, "RIGHT")
mhText:SetPoint("BOTTOMRIGHT", MH, "TOPRIGHT", 0, 4)
local mhLabel = ns.Font(F, "body", 10, C.muted, "LEFT")
mhLabel:SetPoint("BOTTOMLEFT", MH, "TOPLEFT", 0, 4)
local rgText = ns.Font(F, "bold", 11, C.gold, "RIGHT")
rgText:SetPoint("TOPRIGHT", RG, "BOTTOMRIGHT", 0, -3)

local alpha = 0
local function Flash(b) b.flashA = 0.9 end
local pulseT = 0

local function UpdateBar(b, h, now, show)
    if not show or h.speed <= 0 then b:Hide() return nil end
    b:Show()
    local p = (now - h.last) / h.speed
    b:Set(p)
    return max(0, h.last + h.speed - now)
end

F:SetScript("OnUpdate", function(self, elapsed)
    local now = GetTime()
    -- melee: while auto-attacking, swings repeat at weapon speed
    local unlocked = not db.locked
    local meleeActive = attacking or (now - mh.last < mh.speed)
    local rangedActive = db.ranged and (rg.active or (now - rg.last < rg.speed))
    if unlocked and not meleeActive and not rangedActive then
        -- demo while positioning
        mh.last = now - ((now % mh.speed))
        meleeActive = true
    end

    local target = (meleeActive or rangedActive) and 1 or 0
    alpha = alpha + (target - alpha) * min(1, elapsed * 8)
    self:SetAlpha(alpha)
    if alpha < 0.02 and target == 0 then self:Hide() return end

    local left = UpdateBar(MH, mh, now, meleeActive)
    UpdateBar(OH, oh, now, meleeActive and db.offhand and oh.speed > 0)
    RG:ClearAllPoints()
    if OH:IsShown() then RG:SetPoint("TOP", OH, "BOTTOM", 0, -5) else RG:SetPoint("TOP", MH, "BOTTOM", 0, -5) end
    local rleft = UpdateBar(RG, rg, now, rangedActive)

    if db.text and left then
        mhText:SetText(format("%.1f", left)); mhText:Show()
        mhLabel:SetText(format("%.2f s", mh.speed)); mhLabel:Show()
    else
        mhText:Hide(); mhLabel:Hide()
    end
    if db.text and rleft then rgText:SetText(format("%.1f", rleft)); rgText:Show() else rgText:Hide() end

    -- weapon ready, waiting for the next swing: soft breathing glow on the full bar
    pulseT = pulseT + elapsed
    if attacking and left == 0 then MH.glow:SetAlpha(0.35 + 0.35 * math.abs(math.sin(pulseT * 4))) else MH.glow:SetAlpha(1) end
    for _, b in ipairs({ MH, OH, RG }) do
        if b.flashA > 0 then
            b.flashA = max(0, b.flashA - elapsed * 3)
            b.flash:SetAlpha(b.flashA)
        end
    end
end)

local function Wake() F:Show() end

---------------------------------------------------------------------------
-- Events
---------------------------------------------------------------------------
local ev = CreateFrame("Frame")
local function Reg(e) pcall(ev.RegisterEvent, ev, e) end
Reg("ADDON_LOADED")
Reg("PLAYER_ENTER_COMBAT")
Reg("PLAYER_LEAVE_COMBAT")
Reg("UNIT_ATTACK_SPEED")
Reg("UNIT_INVENTORY_CHANGED")
Reg("START_AUTOREPEAT_SPELL")
Reg("STOP_AUTOREPEAT_SPELL")
Reg("PLAYER_REGEN_ENABLED")
pcall(ev.RegisterUnitEvent, ev, "UNIT_COMBAT", "target")
pcall(ev.RegisterUnitEvent, ev, "UNIT_SPELLCAST_SUCCEEDED", "player")

local MELEE_ACTION = { WOUND = true, MISS = true, DODGE = true, PARRY = true, BLOCK = true,
    DEFLECT = true, ABSORB = true, IMMUNE = true, EVADE = true, RESIST = true }

ev:SetScript("OnEvent", function(_, e, a1, a2, a3, ...)
    if e == "ADDON_LOADED" then
        if a1 ~= ADDON_NAME then return end
        MoteveSwingDB = MoteveSwingDB or {}
        for k, v in pairs(DEFAULTS) do if MoteveSwingDB[k] == nil then MoteveSwingDB[k] = v end end
        db = MoteveSwingDB
        F:ClearAllPoints()
        F:SetPoint(db.point, UIParent, db.relPoint, db.x, db.y)
        F:SetScale(db.scale)
        F:EnableMouse(not db.locked)
        box:EnableMouse(not db.locked)
        box:SetShown(not db.locked)
        if not db.locked then F:Show() end
        Speeds()
        return
    end
    if not db then return end
    local now = GetTime()
    if e == "PLAYER_ENTER_COMBAT" then
        -- auto attack switched on: the first swing is immediate if the weapon is ready
        -- auto attack switched on; the bar waits for the first real hit
        attacking = true
        Speeds()
        Wake()
    elseif e == "PLAYER_LEAVE_COMBAT" then
        attacking = false
    elseif e == "UNIT_ATTACK_SPEED" or e == "UNIT_INVENTORY_CHANGED" then
        if a1 and a1 ~= "player" then return end
        local ok, a, b = pcall(UnitAttackSpeed, "player")
        if ok and a and not secret(a) and a > 0 then
            Rescale(mh, a)
            if b and not secret(b) and b > 0 then Rescale(oh, b) else oh.speed = 0 end
        end
        local okR, r = pcall(UnitRangedDamage, "player")
        if okR and r and not secret(r) and r > 0 then Rescale(rg, r) end
    elseif e == "START_AUTOREPEAT_SPELL" then
        rg.active = true
        Speeds()
        Wake()
    elseif e == "STOP_AUTOREPEAT_SPELL" then
        rg.active = false
    elseif e == "UNIT_SPELLCAST_SUCCEEDED" then
        local spellID = a3
        if a1 ~= "player" or not spellID or secret(spellID) then return end
        if NEXT_SWING[spellID] or RESET_SWING[spellID] then
            -- the swing just happened (or restarted): resync the main hand
            Speeds()
            Swing(mh, now); Flash(MH)
            Wake()
        elseif RANGED[spellID] then
            Speeds()
            Swing(rg, now); Flash(RG)
            Wake()
        end
    elseif e == "UNIT_COMBAT" then
        if a1 ~= "target" or not attacking then return end
        local action, school = a2, select(2, ...)
        if not secret(action) and action then
            if not MELEE_ACTION[action] then return end
            -- a damaging hit must be physical; misses, dodges, parries carry no school
            if action == "WOUND" and school and not secret(school) and school ~= 1 then return end
        end
        -- which hand could have swung by now? (>= 75% of its swing time since its last swing)
        local pm = (now - mh.last) / mh.speed
        local po = (oh.speed > 0) and (now - oh.last) / oh.speed or -1
        local hand, p, bar = mh, pm, MH
        -- the hand that is further into its swing gets the hit; when both are ready, the main hand
        if po > pm and pm < 1 then hand, p, bar = oh, po, OH end
        if p < 0.75 then Dbg(format("nem a tiéd (%.0f%%)", p * 100)) return end
        Dbg(hand.last == 0 and ((hand == mh and "MH" or "OH") .. " első ütés")
            or format("%s ütés  %.2f s", hand == mh and "MH" or "OH", now - hand.last))
        Swing(hand, now); Flash(bar)
        Wake()
    elseif e == "PLAYER_REGEN_ENABLED" then
        if not attacking then rg.active = false end
    end
end)

---------------------------------------------------------------------------
-- Moving and settings
---------------------------------------------------------------------------
-- The glass box shown while unlocked is the drag handle (it is bigger than the thin bars,
-- so it is easy to grab); dragging the bars themselves works too.
local function StartMove() if not db.locked then F:StartMoving() end end
local function StopMove()
    F:StopMovingOrSizing()
    local p, _, rp, x, y = F:GetPoint()
    db.point, db.relPoint, db.x, db.y = p, rp, x, y
end
for _, fr in ipairs({ F, box }) do
    fr:RegisterForDrag("LeftButton")
    fr:SetScript("OnDragStart", StartMove)
    fr:SetScript("OnDragStop", StopMove)
end
box:SetFrameLevel(F:GetFrameLevel() + 10)

local function SetLocked(v)
    db.locked = v
    if v then StopMove() end
    F:EnableMouse(not v)
    box:EnableMouse(not v)
    box:SetShown(not v)
    if not v then F:Show() end
end

local function Print(msg) print("|cffa88bffMoteve Swing|r: " .. msg) end

SLASH_MOTEVESWING1, SLASH_MOTEVESWING2 = "/msw", "/moteveswing"
SlashCmdList.MOTEVESWING = function(input)
    local cmd, arg = (input or ""):lower():match("^(%S*)%s*(.-)$")
    if cmd == "" then
        -- plain /msw switches between moving and locked
        if db.locked then SetLocked(false); Print("húzd a helyére az üveg-dobozt, majd újra /msw")
        else SetLocked(true); Print("rögzítve") end
    elseif cmd == "unlock" or cmd == "move" then
        SetLocked(false); Print("húzd a helyére az üveg-dobozt, majd /msw lock")
    elseif cmd == "lock" then
        SetLocked(true); Print("rögzítve")
    elseif cmd == "scale" and tonumber(arg) then
        db.scale = max(0.5, min(2, tonumber(arg))); F:SetScale(db.scale)
    elseif cmd == "offhand" then
        db.offhand = not db.offhand; Print("off-hand: " .. (db.offhand and "be" or "ki"))
    elseif cmd == "ranged" then
        db.ranged = not db.ranged; Print("távolsági: " .. (db.ranged and "be" or "ki"))
    elseif cmd == "text" then
        db.text = not db.text; Print("számok: " .. (db.text and "be" or "ki"))
    elseif cmd == "debug" then
        debug = not debug; Print("debug: " .. (debug and "be (minden észlelt ütést kiír)" or "ki"))
    elseif cmd == "reset" then
        db.point, db.relPoint, db.x, db.y = "CENTER", "CENTER", 0, -180
        F:ClearAllPoints(); F:SetPoint(db.point, UIParent, db.relPoint, db.x, db.y)
    else
        Print("/msw (mozgatás be/ki) | unlock | lock | scale 0.5-2 | offhand | ranged | text | debug | reset")
    end
end
