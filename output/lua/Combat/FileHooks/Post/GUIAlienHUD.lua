
--local originalAlienUpdate = GUIAlienHUD.Update
--function GUIAlienHUD:Update(deltaTime)
--    originalAlienUpdate(self, deltaTime)
--   -- self.resourceDisplay.rtCount:SetIsVisible(false)
--	self.resourceDisplay.pResDescription:SetText("Upgrade Points")
--
--	--self.teamResText:SetIsVisible(false)
--
--end

local originalAlienInitialize = GUIAlienHUD.Initialize
function GUIAlienHUD:Initialize()
	originalAlienInitialize(self)
	
	self.teamResText:SetIsVisible(false)

end
local originalAlienReset= GUIAlienHUD.Reset
function GUIAlienHUD:Reset()
	originalAlienReset(self)

	self.teamResText:SetIsVisible(false)
end 