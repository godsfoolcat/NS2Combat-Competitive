--________________________________
--
--   	NS2 Combat Mod
--	Made by JimWest and MCMLXXXIV, 2012
--
--________________________________

-- combat_Player.lua

-- Load the Upgrade functions too...
Script.Load("lua/Combat/Player_Upgrades.lua")

-- Open buy menu for exos and marines. Alien class overwrites this method so we are fine.
function Player:Buy()

    -- Don't allow display in the ready room, or as phantom
    if self:GetIsLocalPlayer() and not HelpScreen_GetHelpScreen():GetIsBeingDisplayed() then

        -- The Embryo cannot use the buy menu in any case.
        if self:GetTeamNumber() ~= 0 and not self:isa("Embryo") then

            if not self.buyMenu then

                self.buyMenu = GetGUIManager():CreateGUIScript("GUIMarineBuyMenu")

            else
                self:CloseMenu()
            end

        end

    end
end

-- check for Fast Reload
function Player:GotFastReload()

    return self.hasFastReload or false

end

-- check for Fast Sprint
function Player:GotFastSprint()

    return self.hasFastSprint or false

end

function Player:GetIsUsingPrimaryWeapon()
    local activeWeapon = self:GetActiveWeapon()
    if activeWeapon then
        -- only give focus when primary attacking, every weapon has itsn own attribute so its a bit dirty, but it works
        -- there is a primaryAttacking on every weapon, but only on bite its getting true
        if (activeWeapon.primaryAttacking == true or activeWeapon.firingPrimary == true or activeWeapon.attacking == true or activeWeapon.attackButtonPressed == true) then
            local hudSlot = activeWeapon.GetHUDSlot()                
            if hudSlot == 1 then
                return true
            end 
        end              
    end
    return false
end

local oldGetCanTakeDamageOverride = Player.GetCanTakeDamageOverride
function Player:GetCanTakeDamageOverride()
    local canTakeDamage = oldGetCanTakeDamageOverride(self)

    return canTakeDamage and not self.gotSpawnProtect

end

if Server then
    function Player:SetRespawnTime(time)
        self.nextRespawnTime = time
        Server.SendNetworkMessage(Server.GetOwner(self), "SetNextRespawnTime", { time = time }, true)
    end

    function Player:GetNextRespawnTime()
        return self.nextRespawnTime or 0
    end
end

-- combat is an arcade mode, so "rookie" status doesn't apply
function Player:GetIsRookie()
    return false -- self.isRookie
end
