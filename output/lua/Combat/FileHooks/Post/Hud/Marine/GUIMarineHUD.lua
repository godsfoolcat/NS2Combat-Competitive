GUIMarineHUD.kUpgradePos = Vector(-GUIMarineHUD.kUpgradeSize.x - 16, -80, 0)

local kTextOffsetX = -120
local kTextOffsetY = 0

local function CreateNewTextItem(self)
    local useColor = kIconColors[kMarineTeamType]
    
    local textItem = self:CreateAnimatedTextItem()
    textItem:SetFontName(GUIMarineHUD.kTextFontName)
    textItem:SetTextAlignmentX(GUIItem.Align_Max)
    textItem:SetTextAlignmentY(GUIItem.Align_Center)
    textItem:SetAnchor(GUIItem.Right, GUIItem.Center)
    textItem:SetLayer(kGUILayerPlayerHUDForeground2)
    textItem:SetColor(useColor)
    textItem:SetFontIsBold(true)
    textItem:SetIsVisible(false)
    return textItem
end

local oldInitialize = GUIMarineHUD.Initialize
function GUIMarineHUD:Initialize()
    local oldReset = self.Reset
    self.Reset = function() end
    
    oldInitialize(self)
    local useColor = kIconColors[kMarineTeamType]
    
    
    self.scanStatus = GetGUIManager():CreateGraphicItem()
    self.scanStatus:SetTexture(GUIMarineHUD.kUpgradesTexture)
    self.scanStatus:SetAnchor(GUIItem.Right, GUIItem.Center)
    self.scanStatus:SetTexturePixelCoordinates(GUIUnpackCoords(GetTextureCoordinatesForIcon(kTechId.Scan)))
    self.scanStatus:SetColor(useColor)
    self.background:AddChild(self.scanStatus)
    
    self.scanText = CreateNewTextItem(self)
    self.scanText:AddAsChildTo(self.scanStatus)
    
    
    self.resupplyStatus = GetGUIManager():CreateGraphicItem()
    self.resupplyStatus:SetTexture(GUIMarineHUD.kUpgradesTexture)
    self.resupplyStatus:SetAnchor(GUIItem.Right, GUIItem.Center)
    self.resupplyStatus:SetTexturePixelCoordinates(GUIUnpackCoords(GetTextureCoordinatesForIcon(kTechId.MedPack)))
    self.resupplyStatus:SetColor(useColor)
    self.background:AddChild(self.resupplyStatus)
    
    self.resupplyText = CreateNewTextItem(self)
    self.resupplyText:AddAsChildTo(self.resupplyStatus)
    
    
    self.catpackStatus = GetGUIManager():CreateGraphicItem()
    self.catpackStatus:SetTexture(GUIMarineHUD.kUpgradesTexture)
    self.catpackStatus:SetAnchor(GUIItem.Right, GUIItem.Center)
    self.catpackStatus:SetTexturePixelCoordinates(GUIUnpackCoords(GetTextureCoordinatesForIcon(kTechId.CatPack)))
    self.catpackStatus:SetColor(useColor)
    self.background:AddChild(self.catpackStatus)
    
    self.catpackText = CreateNewTextItem(self)
    self.catpackText:AddAsChildTo(self.catpackStatus)
    
    self.teamResText:SetIsVisible(false)
    
    self.Reset = oldReset
    self:Reset()

end

local oldReset = GUIMarineHUD.Reset
function GUIMarineHUD:Reset()
    oldReset(self)
    
    self.weaponLevel:SetPosition(Vector(GUIMarineHUD.kUpgradePos.x, GUIMarineHUD.kUpgradePos.y + GUIMarineHUD.kUpgradeSize.y, 0) * self.scale)
    
    self.scanStatus:SetPosition(Vector(GUIMarineHUD.kUpgradePos.x, GUIMarineHUD.kUpgradePos.y + GUIMarineHUD.kUpgradeSize.y * 2, 0) * self.scale)
    self.scanStatus:SetSize(GUIMarineHUD.kUpgradeSize * self.scale)
    self.scanStatus:SetIsVisible(false)    
    
    self.scanText:SetUniformScale(self.scale)
    self.scanText:SetScale(GetScaledVector())
    self.scanText:SetPosition(Vector( kTextOffsetX, kTextOffsetY, 0) )
    GUIMakeFontScale(self.scanText)
    self.scanText:SetIsVisible(false)   
    
    
    self.resupplyStatus:SetPosition(Vector(GUIMarineHUD.kUpgradePos.x, GUIMarineHUD.kUpgradePos.y + GUIMarineHUD.kUpgradeSize.y * 3, 0) * self.scale)
    self.resupplyStatus:SetSize(GUIMarineHUD.kUpgradeSize * self.scale)
    self.resupplyStatus:SetIsVisible(false)    
    
    self.resupplyText:SetUniformScale(self.scale)
    self.resupplyText:SetScale(GetScaledVector())
    self.resupplyText:SetPosition(Vector(kTextOffsetX,kTextOffsetY, 0))
    GUIMakeFontScale(self.resupplyText)
    self.resupplyText:SetIsVisible(false)   
    
    self.catpackStatus:SetPosition(Vector(GUIMarineHUD.kUpgradePos.x, GUIMarineHUD.kUpgradePos.y + GUIMarineHUD.kUpgradeSize.y * 4, 0) * self.scale)
    self.catpackStatus:SetSize(GUIMarineHUD.kUpgradeSize * self.scale)
    self.catpackStatus:SetIsVisible(false)   
    
    self.catpackText:SetUniformScale(self.scale)
    self.catpackText:SetScale(GetScaledVector())
    self.catpackText:SetPosition(Vector(kTextOffsetX, kTextOffsetY, 0))
    GUIMakeFontScale(self.catpackText)
    self.catpackText:SetIsVisible(false)   
    
end
    
    
local oldUpdate = GUIMarineHUD.Update
function GUIMarineHUD:Update(deltaTime)
    oldUpdate(self, deltaTime)
    -- Display a COMBAT MODE instead of commander name...
    self.commanderName:DestroyAnimation("COMM_TEXT_WRITE")
    self.commanderName:SetText("COMBAT MODE")
    self.commanderName:SetColor(GUIMarineHUD.kActiveCommanderColor)
    
    self.teamResText:SetIsVisible(false)
    
    if self.scanStatus then
        self.scanStatus:SetIsVisible(PlayerUI_GetHasScan())
        self.scanText:SetIsVisible(PlayerUI_GetHasScan())
        self.scanText:SetText(tostring(PlayerUI_GetNextScanIn()))
    end
    if self.resupplyStatus then
        self.resupplyStatus:SetIsVisible(PlayerUI_GetHasResupply())
        self.resupplyText:SetIsVisible(PlayerUI_GetHasResupply())
		local nextIn = PlayerUI_GetNextResupplyIn()
        self.resupplyText:SetText(tostring(nextIn))
		
		local resupplied = nextIn and nextIn > kResupplyTimer
		-- has used on-demand resupply
		if resupplied ~= self._improvedResupplied then
			if resupplied then
				self.resupplyText:SetColor(Color(1,0,0))
				self.resupplyStatus:SetColor(Color(1,0,0))
			else
				self.resupplyText:SetColor(kIconColors[kMarineTeamType])
				self.resupplyStatus:SetColor(kIconColors[kMarineTeamType])
			end
		end
		self._improvedResupplied = resupplied
		
    end
    if self.catpackStatus then
        self.catpackStatus:SetIsVisible(PlayerUI_GetHasCatPack())
        self.catpackText:SetIsVisible(PlayerUI_GetHasCatPack())
        local nextCatPack = PlayerUI_GetNextCatpackIn()
        if nextCatPack <= 0 then
            nextCatPack = "READY"
        end
        self.catpackText:SetText(tostring(nextCatPack))
    end
end


local oldUninitialize = GUIMarineHUD.Uninitialize
function GUIMarineHUD:Uninitialize()
    oldUninitialize(self)
    
    self.scanStatus = nil
    self.scanText = nil
    self.resupplyStatus = nil
    self.resupplyText = nil
    self.catpackStatus = nil
    self.catpackText = nil
    
end

