local _, ns = ...
ns.roleplayNumbers = {
    { key = "roleplayLogoutStart", label = "Minimum starting bar height", default = 0, low = 0, high = 50, suffix = "%" },
    { key = "roleplayLogoutMax", label = "Maximum bar height", default = 50, low = 0, high = 50, suffix = "%" },
    { key = "roleplayLogoutDuration1", label = "Stage 1 duration", default = 10, low = 0, high = 20, suffix = " s" },
    { key = "roleplayLogoutRate1", label = "Stage 1 growth per second", default = 2, low = 0, high = 50, suffix = "%" },
    { key = "roleplayLogoutDuration2", label = "Stage 2 duration", default = 6, low = 0, high = 20, suffix = " s" },
    { key = "roleplayLogoutRate2", label = "Stage 2 growth per second", default = 3, low = 0, high = 50, suffix = "%" },
    { key = "roleplayLogoutDuration3", label = "Stage 3 duration", default = 3, low = 0, high = 20, suffix = " s" },
    { key = "roleplayLogoutRate3", label = "Stage 3 growth per second", default = 4, low = 0, high = 50, suffix = "%" },
}
local loaded = false
local function LoadRuntime()
    if loaded then return end
    loaded = true
    local frame, walkHooked, emoteHooked, sitHooked, cancelHooked, popupHooked
    local snapshot, pose, activeSource, activeTarget
    local walkingMode, walkSuppressed, generation = nil, false, 0
    local logoutElapsed, logoutStartHeight
    local countdownFrames = {}
    local function KeepCountdown(dialog)
        if logoutElapsed == nil or not dialog or not dialog.SetIgnoreParentAlpha then return end
        if not countdownFrames[dialog] then
            countdownFrames[dialog] = { ignore = dialog.IsIgnoringParentAlpha and dialog:IsIgnoringParentAlpha() or false, alpha = dialog:GetAlpha() }
        end
        dialog:SetIgnoreParentAlpha(true); dialog:SetAlpha(1)
    end
    local function FindCountdown(which)
        local dialog
        if StaticPopup_FindVisible then dialog = StaticPopup_FindVisible(which) end
        if not dialog and StaticPopup_Visible then
            local name, frame = StaticPopup_Visible(which)
            dialog = frame or (type(name) == "string" and _G[name])
        end
        KeepCountdown(dialog)
    end
    local function RestoreCountdown()
        for dialog, original in pairs(countdownFrames) do
            dialog:SetIgnoreParentAlpha(original.ignore); dialog:SetAlpha(original.alpha)
        end
        countdownFrames = {}
    end

    local function Enabled() return ns.Advanced("roleplay") end
    function ns.TriggerAvailable() return type(ToggleRun) == "function" and type(hooksecurefunc) == "function" end
    function ns.PostureAvailable() return type(DoEmote) == "function" or (C_ChatInfo and type(C_ChatInfo.PerformEmote) == "function") end
    local function Action(target) return ns.actions[target == 8 and 4 or target + 1] end
    function ns.IsRoleplayActive() return snapshot ~= nil or logoutElapsed ~= nil end
    function ns.IsRoleplayLogoutActive() return logoutElapsed ~= nil end
    function ns.IsRoleplayEffectOwned(effect)
        if logoutElapsed ~= nil and effect == "letterbox" then return true end
        if not snapshot or activeTarget == nil then return false end
        if activeTarget <= 2 or activeTarget == 8 then return Action(activeTarget).effect == effect end
        for _, action in ipairs(ns.actions) do
            if action.effect == effect then return ns.IsActionEnabled(action) and ns.GetCombinedActions(activeTarget - 2)[action.binding] == true end
        end
        return false
    end
    function ns.GetWalkingMode() return walkingMode end
    function ns.GetTriggerTargetName(target)
        if target == -1 then return "No Lens" end
        if target <= 2 or target == 8 then return _G["BINDING_NAME_" .. Action(target).binding] end
        return "Combined Lens " .. (target - 2)
    end
    function ns.IsTriggerTargetAvailable(target)
        target = target or ns.db.triggerTarget
        if target == -1 then return false end
        if target <= 2 or target == 8 then return ns.IsActionEnabled(Action(target)) end
        return target - 2 <= ns.GetCombinedCount() and ns.HasCombinedActions(target - 2)
    end
    local function Notify()
        if ns.RefreshTriggerSettings then ns.RefreshTriggerSettings() end
        if ns.RefreshLensRuntime then ns.RefreshLensRuntime() end
    end
    local function EndScene()
        local previous = snapshot
        snapshot, activeSource, activeTarget = nil, nil, nil
        if previous then ns.RestoreLensState(previous) end
        Notify()
    end
    local function Reconcile()
        local source, target
        if Enabled() then
            if logoutElapsed ~= nil and ns.IsTriggerTargetAvailable(ns.db.roleplayLogoutTarget) then source, target = "GoOffline", ns.db.roleplayLogoutTarget
            elseif pose and ns.RoleplayActionEnabled(pose) then
                source, target = pose, ns.db["roleplay" .. pose .. "Target"]
            elseif ns.RoleplayActionEnabled("Walk") and walkingMode and not walkSuppressed then source, target = "Walk", ns.db.triggerTarget end
        end
        if not target or not ns.IsTriggerTargetAvailable(target) then EndScene(); return end
        if source == activeSource and target == activeTarget then return end
        if snapshot then ns.RestoreLensState(snapshot) else snapshot = ns.CaptureLensState() end
        activeSource, activeTarget = source, target
        ns.ActivateRoleplayTarget(target)
        Notify()
    end
    local function Speed()
        if not GetUnitSpeed then return end
        local ok, speed, run = pcall(GetUnitSpeed, "player")
        if not ok or (issecretvalue and (issecretvalue(speed) or issecretvalue(run))) then return end
        return tonumber(speed), tonumber(run)
    end
    local function OnGround()
        for _, fn in ipairs({ "IsFlying", "IsSwimming", "IsFalling", "IsMounted" }) do if _G[fn] and _G[fn]() then return false end end
        return not (UnitIsDeadOrGhost and UnitIsDeadOrGhost("player"))
    end
    local function SyncFromMovement()
        if walkingMode ~= nil or not Enabled() or not ns.RoleplayActionEnabled("Walk") then return end
        local speed, run = Speed()
        if not speed or speed <= 0 or not run or run <= 2.58 then return end
        if (IsFlying and IsFlying()) or (IsSwimming and IsSwimming()) or (IsFalling and IsFalling()) then return end
        if math.abs(speed - 2.5) < 0.08 or math.abs(speed - 1.25) < 0.04 then walkingMode = true
        elseif math.abs(speed - run) < 0.08 then walkingMode = false
        else return end
        Reconcile()
    end
    local function SyncSoon()
        if walkingMode ~= nil or not ns.RoleplayActionEnabled("Walk") or not ns.IsTriggerTargetAvailable() then return end
        generation = generation + 1
        local token = generation
        if C_Timer and C_Timer.After then
            for _, delay in ipairs({ 0.1, 0.3, 0.6 }) do
                C_Timer.After(delay, function() if token == generation and Enabled() then SyncFromMovement() end end)
            end
        else SyncFromMovement() end
    end
    function ns.SyncWalkingMode(enabled)
        walkingMode, walkSuppressed = enabled == true, false
        generation = generation + 1
        Reconcile()
    end
    local function Emote(token)
        if not Enabled() or (issecretvalue and issecretvalue(token)) then return end
        token = tostring(token or ""):upper()
        if token == "STAND" then pose = nil; Reconcile(); return end
        local kind = token == "SIT" and "Sit" or (token == "LAYDOWN" or token == "SLEEP") and "Lay" or token == "LEAN" and "Lean"
        if not kind or not ns.RoleplayActionEnabled(kind) or Speed() ~= 0 or not OnGround() then return end
        pose = kind
        Reconcile()
    end
    local function StopLogout()
        local active = logoutElapsed ~= nil
        logoutElapsed = nil
        RestoreCountdown()
        if frame then frame:SetScript("OnUpdate", nil) end
        if active then Reconcile() end
        if ns.logoutBarHeight then ns.SetLogoutBarHeight(nil, true) end
        Notify()
    end
    local function StartLogout()
        if not Enabled() or not ns.RoleplayActionEnabled("Logout") or not ns.IsEffectEnabled("letterbox") then return end
        logoutElapsed = 0
        ns.PrepareLogoutUI()
        Reconcile()
        FindCountdown("CAMP"); FindCountdown("QUIT")
        logoutStartHeight = math.min(ns.db.roleplayLogoutMax, math.max(ns.GetLetterboxCurrentHeight(), ns.db.roleplayLogoutStart))
        ns.SetLogoutBarHeight(logoutStartHeight)
        frame:SetScript("OnUpdate", function(self, elapsed)
            logoutElapsed = math.min(20, logoutElapsed + elapsed)
            local remaining, growth = logoutElapsed, 0
            for stage = 1, 3 do
                local duration = ns.db["roleplayLogoutDuration" .. stage]
                growth = growth + math.min(remaining, duration) * ns.db["roleplayLogoutRate" .. stage]
                remaining = math.max(0, remaining - duration)
            end
            ns.SetLogoutBarHeight(math.min(ns.db.roleplayLogoutMax, logoutStartHeight + growth))
            if logoutElapsed == 20 then self:SetScript("OnUpdate", nil) end
        end)
        Notify()
    end
    function ns.CancelRoleplay()
        snapshot, pose, activeSource, activeTarget = nil, nil, nil, nil
        walkSuppressed = walkingMode == true
        generation = generation + 1
        StopLogout()
    end
    function ns.StopRoleplay()
        local suppressed = walkSuppressed
        EndScene()
        ns.CancelRoleplay()
        walkSuppressed = suppressed
        if frame then frame:UnregisterAllEvents() end
    end
    function ns.UpdateTrigger()
        if not Enabled() then ns.StopRoleplay(); return end
        local walk = ns.RoleplayActionEnabled("Walk") and ns.IsTriggerTargetAvailable()
        local stay = false
        for _, kind in ipairs({ "Sit", "Lay", "Lean" }) do
            if ns.RoleplayActionEnabled(kind) and ns.IsTriggerTargetAvailable(ns.db["roleplay" .. kind .. "Target"]) then stay = true end
        end
        local logout = ns.RoleplayActionEnabled("Logout") and ns.IsEffectEnabled("letterbox")
        if not walk and not stay and not logout then ns.StopRoleplay(); return end
        if not frame then
            frame = CreateFrame("Frame", "RetCinemaRoleplayEvents")
            frame:SetScript("OnEvent", function(_, event)
                if not Enabled() then return end
                if event == "PLAYER_CAMPING" or event == "PLAYER_QUITING" then StartLogout()
                elseif event == "LOGOUT_CANCEL" then StopLogout()
                elseif event == "PLAYER_ENTERING_WORLD" then walkingMode = nil; SyncFromMovement(); SyncSoon()
                elseif event == "PLAYER_STARTED_MOVING" then pose = nil; Reconcile(); SyncSoon()
                elseif event == "PLAYER_DEAD" then pose = nil; Reconcile() end
            end)
        end
        frame:UnregisterAllEvents()
        if walk or stay then frame:RegisterEvent("PLAYER_STARTED_MOVING"); frame:RegisterEvent("PLAYER_DEAD") end
        if walk then frame:RegisterEvent("PLAYER_ENTERING_WORLD") end
        if logout then
            for _, event in ipairs({ "PLAYER_CAMPING", "PLAYER_QUITING", "LOGOUT_CANCEL" }) do frame:RegisterEvent(event) end
        else StopLogout() end
        if logout and not cancelHooked and type(CancelLogout) == "function" and hooksecurefunc then
            hooksecurefunc("CancelLogout", function() if logoutElapsed ~= nil then StopLogout() end end)
            cancelHooked = true
        end
        if logout and not popupHooked and type(StaticPopup_Show) == "function" and hooksecurefunc then
            hooksecurefunc("StaticPopup_Show", function(which)
                if logoutElapsed ~= nil and (which == "CAMP" or which == "QUIT") then FindCountdown(which) end
            end)
            popupHooked = true
        end
        if walk and not walkHooked and ns.TriggerAvailable() then
            hooksecurefunc("ToggleRun", function()
                if not Enabled() or not ns.RoleplayActionEnabled("Walk") then walkingMode = nil; return end
                walkSuppressed = false
                if walkingMode ~= nil then walkingMode = not walkingMode; Reconcile() else SyncSoon() end
            end)
            walkHooked = true
        end
        if stay and not emoteHooked and hooksecurefunc then
            if C_ChatInfo and type(C_ChatInfo.PerformEmote) == "function" then hooksecurefunc(C_ChatInfo, "PerformEmote", Emote); emoteHooked = true
            elseif type(DoEmote) == "function" then hooksecurefunc("DoEmote", Emote); emoteHooked = true end
        end
        if ns.RoleplayActionEnabled("Sit") and stay and not sitHooked and type(SitStandOrDescendStart) == "function" and hooksecurefunc then
            hooksecurefunc("SitStandOrDescendStart", function()
                if not Enabled() or not ns.RoleplayActionEnabled("Sit") then return end
                if pose == "Sit" then pose = nil; Reconcile() else Emote("SIT") end
            end)
            sitHooked = true
        end
        SyncFromMovement()
        Reconcile()
    end
    local function ValidTarget(value) return type(value) == "number" and value % 1 == 0 and value >= 0 and value <= 8 end
    function ns.SetTrigger(enabled, target)
        target = target == nil and ns.db.triggerTarget or tonumber(target)
        if not ValidTarget(target) or (enabled and (not ns.RoleplayActionVisible("Walk") or not ns.TriggerAvailable())) then return false end
        ns.db.triggerTarget, ns.db.triggerEnabled, walkSuppressed = target, enabled == true, false
        ns.UpdateTrigger(); Notify()
        return true
    end
    function ns.SetRoleplayTarget(kind, value)
        if kind ~= "Sit" and kind ~= "Lay" and kind ~= "Lean" and kind ~= "Logout" then return false end
        if not (kind == "Logout" and value == -1) and not ValidTarget(value) then return false end
        ns.db["roleplay" .. kind .. "Target"] = value
        ns.UpdateTrigger(); Notify()
        return true
    end
    function ns.SetRoleplayOption(key, value)
        if key ~= "roleplaySit" and key ~= "roleplayLay" and key ~= "roleplayLean" and key ~= "roleplayLogout" then return false end
        if value and not ns.RoleplayActionVisible(key:sub(9)) then return false end
        ns.db[key] = value == true
        if pose and not ns.db["roleplay" .. pose] then pose = nil end
        ns.UpdateTrigger(); Notify()
        return true
    end
    function ns.SetRoleplayNumber(key, value)
        value = tonumber(value)
        for _, spec in ipairs(ns.roleplayNumbers) do
            if key == spec.key then
                if not value or value ~= value or value < spec.low or value > spec.high then return false end
                ns.db[key] = value
                return true
            end
        end
        return false
    end

end
-- Keep the runtime, hooks and frames uninitialized until LiteRP is enabled.
function ns.IsRoleplayActive() return false end
function ns.IsRoleplayLogoutActive() return false end
function ns.IsRoleplayEffectOwned() return false end
function ns.CancelRoleplay() end
function ns.StopRoleplay() end
function ns.UpdateTrigger()
    if not ns.Advanced("roleplay") then return end
    LoadRuntime()
    ns.UpdateTrigger()
end
