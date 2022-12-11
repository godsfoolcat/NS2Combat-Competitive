-- Combat's marines buy menu
Script.Load("lua/GUIAnimatedScript.lua")

Script.Load("lua/Combat/MarineBuyFuncs.lua")

class 'GUIMarineBuyMenu' (GUIAnimatedScript)

GUIMarineBuyMenu.kBuyMenuTexture = PrecacheAsset("ui/marine_buy_textures.dds")
GUIMarineBuyMenu.kBuyHUDTexture =  PrecacheAsset("ui/marine_buy_icons.dds")
GUIMarineBuyMenu.kRepeatingBackground = PrecacheAsset("ui/menu/grid.dds")
GUIMarineBuyMenu.kContentBgTexture = PrecacheAsset("ui/menu/repeating_bg.dds")
GUIMarineBuyMenu.kContentBgBackTexture = PrecacheAsset("ui/menu/repeating_bg_black.dds")
GUIMarineBuyMenu.kResourceIconTexture = PrecacheAsset("ui/pres_icon_big.dds")
GUIMarineBuyMenu.kSmallIconTexture = PrecacheAsset("ui/combat_marine_buildmenu.dds")
GUIMarineBuyMenu.kBigIconTexture = PrecacheAsset("ui/marine_buy_bigicons.dds")
GUIMarineBuyMenu.kButtonTexture = PrecacheAsset("ui/marine_buymenu_button.dds")
GUIMarineBuyMenu.kMenuSelectionTexture = PrecacheAsset("ui/marine_buymenu_selector.dds")
GUIMarineBuyMenu.kScanLineTexture = PrecacheAsset("ui/menu/scanLine_big.dds")
GUIMarineBuyMenu.kArrowTexture = PrecacheAsset("ui/menu/arrow_horiz.dds")

GUIMarineBuyMenu.kMoreResources = PrecacheAsset("sound/NS2.fev/marine/voiceovers/commander/more")
GUIMarineBuyMenu.kNeedsResearch = PrecacheAsset("sound/NS2.fev/common/invalid")
Client.PrecacheLocalSound(GUIMarineBuyMenu.kMoreResources)
Client.PrecacheLocalSound(GUIMarineBuyMenu.kNeedsResearch)

GUIMarineBuyMenu.kFont = Fonts.kAgencyFB_Small
GUIMarineBuyMenu.kFont2 = Fonts.kAgencyFB_Small
GUIMarineBuyMenu.kFontCost = Fonts.kAgencyFB_Large

GUIMarineBuyMenu.kDescriptionFontName = Fonts.kAgencyFB_Tiny
GUIMarineBuyMenu.kDescriptionFontSize = GUIScale(20)

GUIMarineBuyMenu.kScanLineHeight = GUIScale(256)
GUIMarineBuyMenu.kScanLineAnimDuration = 5

GUIMarineBuyMenu.kArrowWidth = GUIScale(32)
GUIMarineBuyMenu.kArrowHeight = GUIScale(32)
GUIMarineBuyMenu.kArrowTexCoords = { 1, 1, 0, 0 }

-- Small Item Icons

GUIMarineBuyMenu.kSmallIconSize = GUIScale( Vector(80, 80, 0) )
GUIMarineBuyMenu.kSelectorSize = GUIScale( Vector(100, 100, 0) )

-- x-offset
GUIMarineBuyMenu.kSmallIconOffset_x = GUIScale(120)

GUIMarineBuyMenu.kIconTopOffset = 40
GUIMarineBuyMenu.kItemIconYOffset = {}

GUIMarineBuyMenu.kEquippedIconTopOffset = 58

local smallIconHeight = 80
local smallIconWidth = 80
-- max Icon per row
local smallIconRows = 4

local gSmallIconIndex
local kCombatMarineTechIdToMaterialOffset
local function GetSmallIconPixelCoordinates(itemTechId)

    if not kCombatMarineTechIdToMaterialOffset then
    
        -- Init marine offsets
        kCombatMarineTechIdToMaterialOffset = {} 
        
        -- class
        kCombatMarineTechIdToMaterialOffset[kTechId.Jetpack] = 40
        kCombatMarineTechIdToMaterialOffset[kTechId.Exosuit] = 76
        kCombatMarineTechIdToMaterialOffset[kTechId.DualMinigunExosuit] = 35
        kCombatMarineTechIdToMaterialOffset[kTechId.DualRailgunExosuit] = 97
        
        -- weapons
        kCombatMarineTechIdToMaterialOffset[kTechId.LayMines] = 80
        kCombatMarineTechIdToMaterialOffset[kTechId.Welder] = 34
        kCombatMarineTechIdToMaterialOffset[kTechId.Shotgun] = 48
        kCombatMarineTechIdToMaterialOffset[kTechId.GrenadeLauncher] = 98
        kCombatMarineTechIdToMaterialOffset[kTechId.Flamethrower] = 42
        kCombatMarineTechIdToMaterialOffset[kTechId.Mine] = 80
        kCombatMarineTechIdToMaterialOffset[kTechId.HeavyMachineGun] = 96
        
        -- tech
        kCombatMarineTechIdToMaterialOffset[kTechId.Armor1] = 49
        kCombatMarineTechIdToMaterialOffset[kTechId.Armor2] = 50
        kCombatMarineTechIdToMaterialOffset[kTechId.Armor3] = 51
        kCombatMarineTechIdToMaterialOffset[kTechId.Weapons1] = 55
        kCombatMarineTechIdToMaterialOffset[kTechId.Weapons2] = 56
        kCombatMarineTechIdToMaterialOffset[kTechId.Weapons3] = 57        
        kCombatMarineTechIdToMaterialOffset[kTechId.MedPack] = 37 
        kCombatMarineTechIdToMaterialOffset[kTechId.AmmoPack] = 36
        kCombatMarineTechIdToMaterialOffset[kTechId.Scan] = 41
        kCombatMarineTechIdToMaterialOffset[kTechId.MACEMP] = 62
        kCombatMarineTechIdToMaterialOffset[kTechId.CatPack] = 45
        -- fast reload
        kCombatMarineTechIdToMaterialOffset[kTechId.AdvancedWeaponry] = 71
        -- fast sprint
        kCombatMarineTechIdToMaterialOffset[kTechId.PhaseTech] = 60

        -- grenades
        kCombatMarineTechIdToMaterialOffset[kTechId.ClusterGrenade] = 92
        kCombatMarineTechIdToMaterialOffset[kTechId.GasGrenade] = 93
        kCombatMarineTechIdToMaterialOffset[kTechId.PulseGrenade] = 94        

    
    end
    
    local index = kCombatMarineTechIdToMaterialOffset[itemTechId]
    if not index then
        index = 0
    end
        
    local columns = 12    
    local textureOffset_x1 = index % columns
    local textureOffset_y1 = math.floor(index / columns)
    
    local pixelXOffset = textureOffset_x1 * smallIconWidth
    local pixelYOffset = textureOffset_y1 * smallIconHeight
        
    return pixelXOffset, pixelYOffset, pixelXOffset + smallIconWidth, pixelYOffset + smallIconHeight

end

                            
GUIMarineBuyMenu.kTextColor = Color(kMarineFontColor)

GUIMarineBuyMenu.kMenuWidth = GUIScale(128)
GUIMarineBuyMenu.kPadding = GUIScale(8)

GUIMarineBuyMenu.kEquippedWidth = GUIScale(128)

GUIMarineBuyMenu.kEquippedColor = Color(0.6, 0.6, 0.6, 0.6)

GUIMarineBuyMenu.kBackgroundWidth = GUIScale(600)
GUIMarineBuyMenu.kBackgroundHeight = GUIScale(700)
-- We want the background graphic to look centered around the circle even though there is the part coming off to the right.
GUIMarineBuyMenu.kBackgroundXOffset = GUIScale(0)

GUIMarineBuyMenu.kPlayersTextSize = GUIScale(24)
GUIMarineBuyMenu.kResearchTextSize = GUIScale(24)

GUIMarineBuyMenu.kResourceDisplayHeight = GUIScale(64)

GUIMarineBuyMenu.kResourceIconWidth = GUIScale(32)
GUIMarineBuyMenu.kResourceIconHeight = GUIScale(32)

GUIMarineBuyMenu.kHardCapOffsetX = GUIScale(5)
GUIMarineBuyMenu.kHardCapOffsetY = GUIScale(13)

GUIMarineBuyMenu.kMouseOverInfoTextSize = GUIScale(20)
GUIMarineBuyMenu.kMouseOverInfoOffset = Vector(GUIScale(-30), GUIScale(-20), 0)
GUIMarineBuyMenu.kMouseOverInfoResIconOffset = Vector(GUIScale(-40), GUIScale(-60), 0)

GUIMarineBuyMenu.kDisabledColor = Color(0.5, 0.5, 0.5, 0.5)
GUIMarineBuyMenu.kCannotBuyColor = Color(1, 0, 0, 0.5)
GUIMarineBuyMenu.kEnabledColor = Color(1, 1, 1, 1)

GUIMarineBuyMenu.kCloseButtonColor = Color(1, 1, 0, 1)

GUIMarineBuyMenu.kButtonWidth = GUIScale(160)
GUIMarineBuyMenu.kButtonHeight = GUIScale(64)

GUIMarineBuyMenu.kItemNameOffsetX = GUIScale(28)
GUIMarineBuyMenu.kItemNameOffsetY = GUIScale(256)

GUIMarineBuyMenu.kItemDescriptionOffsetY = GUIScale(300)
GUIMarineBuyMenu.kItemDescriptionSize = GUIScale( Vector(450, 180, 0) )

function GUIMarineBuyMenu:SetHostStructure(hostStructure)

    self.hostStructure = hostStructure
    self:_InitializeItemButtons()
    self.selectedItem = nil
    
end


function GUIMarineBuyMenu:OnClose()

    -- Check if GUIMarineBuyMenu is what is causing itself to close.
    self.player.combatBuy = false
    if not self.closingMenu then
        -- Play the close sound since we didn't trigger the close.
        MarineBuy_OnClose()
    end


end

function GUIMarineBuyMenu:Initialize()

    GUIAnimatedScript.Initialize(self)
    
    self.player = Client.GetLocalPlayer()    

    self.mouseOverStates = { }
    self.selectedUpgrades = { }
    self.equipped = { }
    
    self.selectedItemCinematic = nil
    self.selectedItem = nil
    
    self:_InitializeBackground()
    self:_InitializeContent()
    self:_InitializeItemButtons()
    self:_InitializeResourceDisplay()
    self:_InitializeCloseButton()
    self:_InitializeEquipped()    
    self:_InitializeRefundButton()

    -- note: items buttons get initialized through SetHostStructure()
    MarineBuy_OnOpen()

    MouseTracker_SetIsVisible(true, "ui/Cursor_MenuDefault.dds", true)
    
end

function GUIMarineBuyMenu:Update(deltaTime)

    GUIAnimatedScript.Update(self, deltaTime)

    self.player = Client.GetLocalPlayer()
    self:_UpdateBackground(deltaTime)
    self:_UpdateEquipped(deltaTime)
    self:_UpdateItemButtons(deltaTime)
    self:_UpdateContent(deltaTime)
    self:_UpdateResourceDisplay(deltaTime)
    self:_UpdateCloseButton(deltaTime)
    self:_UpdateRefundButton(deltaTime)
    
end

function GUIMarineBuyMenu:Uninitialize()

    GUIAnimatedScript.Uninitialize(self)

    self:_UninitializeItemButtons()
    self:_UninitializeBackground()
    self:_UninitializeContent()
    self:_UninitializeResourceDisplay()
    self:_UninitializeCloseButton()
    self:_UninitializeRefundButton()

    MouseTracker_SetIsVisible(false)

end

local function MoveDownAnim(script, item)

    item:SetPosition( Vector(0, -GUIMarineBuyMenu.kScanLineHeight, 0) )
    item:SetPosition( Vector(0, Client.GetScreenHeight() + GUIMarineBuyMenu.kScanLineHeight, 0), GUIMarineBuyMenu.kScanLineAnimDuration, "MARINEBUY_SCANLINE", AnimateLinear, MoveDownAnim)

end

function GUIMarineBuyMenu:_InitializeBackground()

    -- This invisible background is used for centering only.
    self.background = GUIManager:CreateGraphicItem()
    self.background:SetSize(Vector(Client.GetScreenWidth(), Client.GetScreenHeight(), 0))
    self.background:SetAnchor(GUIItem.Left, GUIItem.Top)
    self.background:SetColor(Color(0.05, 0.05, 0.1, 0.7))
    self.background:SetLayer(kGUILayerPlayerHUDForeground4)
    
    self.repeatingBGTexture = GUIManager:CreateGraphicItem()
    self.repeatingBGTexture:SetSize(Vector(Client.GetScreenWidth(), Client.GetScreenHeight(), 0))
    self.repeatingBGTexture:SetTexture(GUIMarineBuyMenu.kRepeatingBackground)
    self.repeatingBGTexture:SetTexturePixelCoordinates(0, 0, Client.GetScreenWidth(), Client.GetScreenHeight())
    self.background:AddChild(self.repeatingBGTexture)
    
    self.content = GUIManager:CreateGraphicItem()
    self.content:SetSize(Vector(GUIMarineBuyMenu.kBackgroundWidth, GUIMarineBuyMenu.kBackgroundHeight, 0))
    self.content:SetAnchor(GUIItem.Middle, GUIItem.Center)
    self.content:SetPosition(Vector((-GUIMarineBuyMenu.kBackgroundWidth / 2) + GUIMarineBuyMenu.kBackgroundXOffset, -GUIMarineBuyMenu.kBackgroundHeight / 2, 0))
    self.content:SetTexture(GUIMarineBuyMenu.kContentBgTexture)
    self.content:SetTexturePixelCoordinates(0, 0, GUIMarineBuyMenu.kBackgroundWidth, GUIMarineBuyMenu.kBackgroundHeight)
    self.background:AddChild(self.content)
    
    self.scanLine = self:CreateAnimatedGraphicItem()
    self.scanLine:SetSize( Vector( Client.GetScreenWidth(), GUIMarineBuyMenu.kScanLineHeight, 0) )
    self.scanLine:SetTexture(GUIMarineBuyMenu.kScanLineTexture)
    self.scanLine:SetLayer(kGUILayerPlayerHUDForeground4)
    self.scanLine:SetIsScaling(false)
    
    self.scanLine:SetPosition( Vector(0, -GUIMarineBuyMenu.kScanLineHeight, 0) )
    self.scanLine:SetPosition( Vector(0, Client.GetScreenHeight() + GUIMarineBuyMenu.kScanLineHeight, 0), GUIMarineBuyMenu.kScanLineAnimDuration, "MARINEBUY_SCANLINE", AnimateLinear, MoveDownAnim)

end

function GUIMarineBuyMenu:_UpdateBackground(deltaTime)
end

function GUIMarineBuyMenu:_UninitializeBackground()
    
    GUI.DestroyItem(self.background)
    self.background = nil
    
    self.content = nil

end

function GUIMarineBuyMenu:_InitializeEquipped()

    self.equippedBg = GetGUIManager():CreateGraphicItem()
    self.equippedBg:SetAnchor(GUIItem.Right, GUIItem.Top)
    self.equippedBg:SetPosition(Vector( GUIMarineBuyMenu.kPadding, -GUIMarineBuyMenu.kResourceDisplayHeight, 0))
    self.equippedBg:SetSize(Vector(GUIMarineBuyMenu.kEquippedWidth, GUIMarineBuyMenu.kBackgroundHeight + GUIMarineBuyMenu.kResourceDisplayHeight, 0))
    self.equippedBg:SetColor(Color(0,0,0,0))
    self.content:AddChild(self.equippedBg)
    
    self.equippedTitle = GetGUIManager():CreateTextItem()
    self.equippedTitle:SetFontName(GUIMarineBuyMenu.kFont)
    self.equippedTitle:SetFontIsBold(true)
    self.equippedTitle:SetAnchor(GUIItem.Middle, GUIItem.Top)
    self.equippedTitle:SetTextAlignmentX(GUIItem.Align_Center)
    self.equippedTitle:SetTextAlignmentY(GUIItem.Align_Center)
    self.equippedTitle:SetColor(GUIMarineBuyMenu.kEquippedColor)
    self.equippedTitle:SetPosition(Vector(0, GUIMarineBuyMenu.kResourceDisplayHeight / 2, 0))
    self.equippedTitle:SetText(Combat_ResolveString("EQUIPPED"))
    self.equippedBg:AddChild(self.equippedTitle)
    
    
        self.equipped = { }
    
    local equippedTechIds = self.player:GetPlayerUpgrades()
    
    for k, itemTechId in ipairs(equippedTechIds) do
    
        local graphicItem = GUIManager:CreateGraphicItem()
        graphicItem:SetSize(GUIMarineBuyMenu.kSmallIconSize)
        graphicItem:SetAnchor(GUIItem.Middle, GUIItem.Top)
        graphicItem:SetPosition(Vector(-GUIMarineBuyMenu.kSmallIconSize.x/ 2, GUIMarineBuyMenu.kEquippedIconTopOffset + (GUIMarineBuyMenu.kSmallIconSize.y) * k - GUIMarineBuyMenu.kSmallIconSize.y, 0))
        graphicItem:SetTexture(GUIMarineBuyMenu.kSmallIconTexture)
        graphicItem:SetTexturePixelCoordinates(GetSmallIconPixelCoordinates(itemTechId))
        
        self.equippedBg:AddChild(graphicItem)
        table.insert(self.equipped, { Graphic = graphicItem, TechId = itemTechId } )
    
    end
    
end

local function GetHardCapText(upgrade)

    local player = Client.GetLocalPlayer()
    local teamInfo = GetTeamInfoEntity(player:GetTeamNumber())
    local playerCount = teamInfo:GetPlayerCount()
    if (kCombatUpgradeCounts[upgrade:GetId()] == nil) then
        kCombatUpgradeCounts[upgrade:GetId()] = 0
    end
    return kCombatUpgradeCounts[upgrade:GetId()] .. "/" .. math.ceil(upgrade:GetHardCapScale() * playerCount)

end

function GUIMarineBuyMenu:_InitializeItemButtons()
    
    self.menu = GetGUIManager():CreateGraphicItem()
    self.menu:SetPosition(Vector( -GUIMarineBuyMenu.kMenuWidth - GUIMarineBuyMenu.kPadding, 0, 0))
    self.menu:SetTexture(GUIMarineBuyMenu.kContentBgTexture)
    self.menu:SetSize(Vector(GUIMarineBuyMenu.kMenuWidth, GUIMarineBuyMenu.kBackgroundHeight, 0))
    self.menu:SetTexturePixelCoordinates(0, 0, GUIMarineBuyMenu.kMenuWidth, GUIMarineBuyMenu.kBackgroundHeight)
    self.content:AddChild(self.menu)
    
    self.menuHeader = GetGUIManager():CreateGraphicItem()
    self.menuHeader:SetSize(Vector(GUIMarineBuyMenu.kMenuWidth, GUIMarineBuyMenu.kResourceDisplayHeight, 0))
    self.menuHeader:SetPosition(Vector(0, -GUIMarineBuyMenu.kResourceDisplayHeight, 0))
    self.menuHeader:SetTexture(GUIMarineBuyMenu.kContentBgBackTexture)
    self.menuHeader:SetTexturePixelCoordinates(0, 0, GUIMarineBuyMenu.kMenuWidth, GUIMarineBuyMenu.kResourceDisplayHeight)
    self.menu:AddChild(self.menuHeader) 
    
    self.menuHeaderTitle = GetGUIManager():CreateTextItem()
    self.menuHeaderTitle:SetFontName(GUIMarineBuyMenu.kFont)
    self.menuHeaderTitle:SetFontIsBold(true)
    self.menuHeaderTitle:SetAnchor(GUIItem.Middle, GUIItem.Center)
    self.menuHeaderTitle:SetTextAlignmentX(GUIItem.Align_Center)
    self.menuHeaderTitle:SetTextAlignmentY(GUIItem.Align_Center)
    self.menuHeaderTitle:SetColor(GUIMarineBuyMenu.kTextColor)
    self.menuHeaderTitle:SetText(Combat_ResolveString("BUY"))
    self.menuHeader:AddChild(self.menuHeaderTitle)    
    
    self.itemButtons = { }
    
    local allUps = GetAllUpgrades("Marine")
    -- sort the ups, defined in this file
    local sortedList = CombatMarineBuy_GUISortUps(allUps)

    -- get the headlines
    local  headlines = CombatMarineBuy_GetHeadlines()
    local nextHeadline = 1
    
    local selectorPosX = -GUIMarineBuyMenu.kSelectorSize.x + GUIMarineBuyMenu.kPadding
    local fontScaleVector = Vector(0.8, 0.8, 0)
    local itemNr = 1
    local k = 1
    local xOffset  = 0
    
    for i, upgrade in ipairs(sortedList) do
    
        if upgrade ~= "nextRow" then
            local itemTechId = upgrade:GetTechId()
            -- only 6 icons per column
            if itemTechId then         
                
                local graphicItem = GUIManager:CreateGraphicItem()
                graphicItem:SetSize(GUIMarineBuyMenu.kSmallIconSize)
                graphicItem:SetAnchor(GUIItem.Middle, GUIItem.Top)
                graphicItem:SetPosition(Vector((-GUIMarineBuyMenu.kSmallIconSize.x/ 2) + xOffset, GUIMarineBuyMenu.kIconTopOffset + (GUIMarineBuyMenu.kSmallIconSize.y) * itemNr - GUIMarineBuyMenu.kSmallIconSize.y, 0))
                -- set the tecture file for the icons
                graphicItem:SetTexture(GUIMarineBuyMenu.kSmallIconTexture)
                 -- set the pixel coordinate for the icon
                graphicItem:SetTexturePixelCoordinates(GetSmallIconPixelCoordinates(itemTechId))

                local graphicItemActive = GUIManager:CreateGraphicItem()
                graphicItemActive:SetSize(GUIMarineBuyMenu.kSelectorSize)
                graphicItemActive:SetPosition(Vector(selectorPosX, -GUIMarineBuyMenu.kSelectorSize.y / 2, 0))
                graphicItemActive:SetAnchor(GUIItem.Right, GUIItem.Center)
                graphicItemActive:SetTexture(GUIMarineBuyMenu.kMenuSelectionTexture)
                graphicItemActive:SetIsVisible(false)
                
                graphicItem:AddChild(graphicItemActive)
                
                local costIcon = GUIManager:CreateGraphicItem()
                costIcon:SetSize(Vector(GUIMarineBuyMenu.kResourceIconWidth * 0.8, GUIMarineBuyMenu.kResourceIconHeight * 0.8, 0))
                costIcon:SetAnchor(GUIItem.Left, GUIItem.Bottom)
                costIcon:SetPosition(Vector(5, -GUIMarineBuyMenu.kResourceIconHeight, 0))
                costIcon:SetTexture(GUIMarineBuyMenu.kResourceIconTexture)
                costIcon:SetColor(GUIMarineBuyMenu.kTextColor)
                
                local selectedArrow = GUIManager:CreateGraphicItem()
                selectedArrow:SetSize(Vector(GUIMarineBuyMenu.kArrowWidth, GUIMarineBuyMenu.kArrowHeight, 0))
                selectedArrow:SetAnchor(GUIItem.Left, GUIItem.Center)
                selectedArrow:SetPosition(Vector(-GUIMarineBuyMenu.kArrowWidth - GUIMarineBuyMenu.kPadding, -GUIMarineBuyMenu.kArrowHeight * 0.5, 0))
                selectedArrow:SetTexture(GUIMarineBuyMenu.kArrowTexture)
                selectedArrow:SetColor(GUIMarineBuyMenu.kTextColor)
                selectedArrow:SetTextureCoordinates(GUIUnpackCoords(GUIMarineBuyMenu.kArrowTexCoords))
                selectedArrow:SetIsVisible(false)
                
                graphicItem:AddChild(selectedArrow) 
                
                local itemCost = GUIManager:CreateTextItem()
                itemCost:SetFontName(GUIMarineBuyMenu.kFontCost)
                itemCost:SetFontIsBold(true)
                itemCost:SetAnchor(GUIItem.Right, GUIItem.Center)
                itemCost:SetPosition(Vector(0, 0, 0))
                itemCost:SetTextAlignmentX(GUIItem.Align_Min)
                itemCost:SetTextAlignmentY(GUIItem.Align_Center)
                itemCost:SetScale(fontScaleVector)
                itemCost:SetColor(GUIMarineBuyMenu.kTextColor)
                itemCost:SetText(ToString(upgrade:GetLevels()))

                if upgrade:GetHardCapScale() > 0 then
                    local hardCapCount = GUIManager:CreateTextItem()
                    hardCapCount:SetFontName(GUIMarineBuyMenu.kFont)
                    hardCapCount:SetFontIsBold(true)
                    hardCapCount:SetAnchor(GUIItem.Left, GUIItem.Top)
                    hardCapCount:SetPosition(Vector(GUIMarineBuyMenu.kSmallIconSize.x - GUIMarineBuyMenu.kHardCapOffsetX, GUIMarineBuyMenu.kHardCapOffsetY, 0))
                    hardCapCount:SetTextAlignmentX(GUIItem.Align_Max)
                    hardCapCount:SetTextAlignmentY(GUIItem.Align_Center)
                    hardCapCount:SetScale(fontScaleVector)
                    hardCapCount:SetColor(GUIMarineBuyMenu.kTextColor)
                    hardCapCount:SetText(GetHardCapText(upgrade))
                    graphicItem:AddChild(hardCapCount)
                end
                
                costIcon:AddChild(itemCost)  
                
                graphicItem:AddChild(costIcon)   
                
                self.menu:AddChild(graphicItem)
                table.insert(self.itemButtons, { Button = graphicItem, Highlight = graphicItemActive, TechId = itemTechId, Cost = itemCost, ResourceIcon = costIcon, Arrow = selectedArrow, HardCapCount = hardCapCount, Upgrade = upgrade} )
                  
                itemNr = itemNr +1
            end
        else
            -- if its first next row, only set the headline
            if i > 1 then
                itemNr = 1
                xOffset = xOffset + GUIMarineBuyMenu.kSmallIconOffset_x
            end
            
            -- set the headline
            local graphicItemHeading = GUIManager:CreateTextItem()
            graphicItemHeading:SetFontName(GUIMarineBuyMenu.kFont)
            graphicItemHeading:SetFontIsBold(true)
            graphicItemHeading:SetAnchor(GUIItem.Middle, GUIItem.Top)
            graphicItemHeading:SetPosition(Vector((-GUIMarineBuyMenu.kSmallIconSize.x/ 2) + xOffset, 5 + (GUIMarineBuyMenu.kSmallIconSize.y) * itemNr - GUIMarineBuyMenu.kSmallIconSize.y, 0))
            graphicItemHeading:SetTextAlignmentX(GUIItem.Align_Min)
            graphicItemHeading:SetTextAlignmentY(GUIItem.Align_Min)
            graphicItemHeading:SetColor(GUIMarineBuyMenu.kTextColor)
            graphicItemHeading:SetText(headlines[nextHeadline] or "nothing")
            self.menu:AddChild(graphicItemHeading)
            
            nextHeadline = nextHeadline + 1
            
        end
    
    end
    
    -- to prevent wrong display before the first update
    self:_UpdateItemButtons(0)

end

GUIMarineBuyMenu.kEquippedMouseoverColor = Color(1,1,1,1)
GUIMarineBuyMenu.kEquippedColor = Color(0.5, 0.5, 0.5, 0.5)

function GUIMarineBuyMenu:_UpdateEquipped(deltaTime)

    self.hoverItem = nil
    for _, equipped in ipairs(self.equipped) do
    
        if self:_GetIsMouseOver(equipped.Graphic) then
            self.hoverItem = equipped.TechId
            equipped.Graphic:SetColor(GUIMarineBuyMenu.kEquippedMouseoverColor)
        else
            equipped.Graphic:SetColor(GUIMarineBuyMenu.kEquippedColor)
        end    
    
    end
    
end

local gResearchToWeaponIds
local function GetItemTechId(researchTechId)

    if not gResearchToWeaponIds then
    
        gResearchToWeaponIds = {}
        gResearchToWeaponIds[kTechId.ShotgunTech] = kTechId.Shotgun
        gResearchToWeaponIds[kTechId.GrenadeLauncherTech] = kTechId.GrenadeLauncher
        gResearchToWeaponIds[kTechId.HeavyMachineGunTech] = kTechId.HeavyMachineGun
        gResearchToWeaponIds[kTechId.WelderTech] = kTechId.Welder
        gResearchToWeaponIds[kTechId.MinesTech] = kTechId.LayMines
        gResearchToWeaponIds[kTechId.FlamethrowerTech] = kTechId.Flamethrower
        gResearchToWeaponIds[kTechId.JetpackTech] = kTechId.Jetpack
        gResearchToWeaponIds[kTechId.ExosuitTech] = kTechId.Exosuit
    
    end
    
    return gResearchToWeaponIds[researchTechId]

end

function GUIMarineBuyMenu:_UpdateItemButtons(deltaTime)

    if self and self.itemButtons then
        for i, item in ipairs(self.itemButtons) do
        
            if self:_GetIsMouseOver(item.Button) then	    
                item.Highlight:SetIsVisible(true)
                self.hoverItem = item.TechId
                self.hoverUpgrade = item.Upgrade
            else 
               item.Highlight:SetIsVisible(false)
           end
           
           local gotRequirements = self.player:GotRequirements(item.Upgrade)  
           local anim = math.cos(Shared.GetTime() * 5) * 0.1 + 0.9        
           local useColor = Color(anim,anim,anim,1)

            -- set grey if player doesn'T have the needed other Up
            if not gotRequirements then
            
                useColor = Color(0.4, 0.4, 0.4, 0.85)
               
            -- set it blink when we got the upp already
            elseif self.player:GotItemAlready(item.Upgrade) then
                
                useColor = Color(1, 1, 0.2, 1)
                    
            -- set red if can't afford
            elseif PlayerUI_GetPlayerResources() < item.Upgrade:GetLevels() then
            
                useColor = Color(0.8, 0.1, 0.1, 1) 
               
            end
            
            item.Button:SetColor(useColor)
            item.Highlight:SetColor(useColor)
            item.Cost:SetColor(useColor)
            item.ResourceIcon:SetColor(useColor)
            item.Arrow:SetIsVisible(self.selectedItem == item.TechId)
            if (item.HardCapCount) then
                item.HardCapCount:SetText(GetHardCapText(item.Upgrade))
            end
            
        end
    end

end

function GUIMarineBuyMenu:_UninitializeItemButtons()
end

function GUIMarineBuyMenu:_InitializeContent()

    local offsetDescription = GUIMarineBuyMenu.kSmallIconOffset_x * 1.5
    self.itemName = GUIManager:CreateTextItem()
    self.itemName:SetFontName(GUIMarineBuyMenu.kFont)
    self.itemName:SetFontIsBold(true)
    self.itemName:SetAnchor(GUIItem.Left, GUIItem.Top)
    self.itemName:SetPosition(Vector((-GUIMarineBuyMenu.kSmallIconSize.x/ 2) + offsetDescription, GUIMarineBuyMenu.kIconTopOffset + (GUIMarineBuyMenu.kSmallIconSize.y) * (smallIconRows + 1.5) - GUIMarineBuyMenu.kSmallIconSize.y, 0))
    self.itemName:SetTextAlignmentX(GUIItem.Align_Min)
    self.itemName:SetTextAlignmentY(GUIItem.Align_Min)
    self.itemName:SetColor(GUIMarineBuyMenu.kTextColor)
    self.itemName:SetText("no selection")
    
    self.content:AddChild(self.itemName)
    
    self.itemDescription = GetGUIManager():CreateTextItem()
    self.itemDescription:SetFontName(GUIMarineBuyMenu.kDescriptionFontName)
    --self.itemDescription:SetFontIsBold(true)
    self.itemDescription:SetFontSize(GUIMarineBuyMenu.kDescriptionFontSize)
    self.itemDescription:SetAnchor(GUIItem.Left, GUIItem.Top)
    self.itemDescription:SetPosition(Vector((-GUIMarineBuyMenu.kSmallIconSize.x/ 2) + offsetDescription, GUIMarineBuyMenu.kIconTopOffset + (GUIMarineBuyMenu.kSmallIconSize.y) * (smallIconRows + 2) - GUIMarineBuyMenu.kSmallIconSize.y, 0))
    self.itemDescription:SetTextAlignmentX(GUIItem.Align_Min)
    self.itemDescription:SetTextAlignmentY(GUIItem.Align_Min)
    self.itemDescription:SetColor(GUIMarineBuyMenu.kTextColor)
    self.itemDescription:SetTextClipped(true, GUIMarineBuyMenu.kItemDescriptionSize.x - 2* GUIMarineBuyMenu.kPadding, GUIMarineBuyMenu.kItemDescriptionSize.y - GUIMarineBuyMenu.kPadding)
    
    self.content:AddChild(self.itemDescription)
    
end

function GUIMarineBuyMenu:_UpdateContent(deltaTime)

    local techId = self.hoverItem
    if not self.hoverItem then
        techId = self.selectedItem
    end
    
    if techId and self.hoverUpgrade then
    
        local researched = self.player:GotRequirements(self.hoverUpgrade)                
        local itemCost = ConditionalValue(self.hoverUpgrade, self.hoverUpgrade:GetLevels(), 0)
        local upgradesCost = 0
        local canAfford = PlayerUI_GetPlayerResources() >= itemCost + upgradesCost

        -- the discription text under the buttons
        self.itemName:SetText(GetDisplayNameForTechId(techId))
        self.itemDescription:SetText(CombatMarineBuy_GetWeaponDescription(techId))
        self.itemDescription:SetTextClipped(true, GUIMarineBuyMenu.kItemDescriptionSize.x - 3* GUIMarineBuyMenu.kPadding, GUIMarineBuyMenu.kItemDescriptionSize.y - GUIMarineBuyMenu.kPadding)

    end
    
    local contentVisible = techId ~= nil and techId ~= kTechId.None

    self.itemName:SetIsVisible(contentVisible)
    self.itemDescription:SetIsVisible(contentVisible)
    
end

function GUIMarineBuyMenu:_UninitializeContent()

    GUI.DestroyItem(self.itemName)

end

function GUIMarineBuyMenu:_InitializeResourceDisplay()
    
    self.resourceDisplayBackground = GUIManager:CreateGraphicItem()
    self.resourceDisplayBackground:SetSize(Vector(GUIMarineBuyMenu.kBackgroundWidth, GUIMarineBuyMenu.kResourceDisplayHeight, 0))
    self.resourceDisplayBackground:SetPosition(Vector(0, -GUIMarineBuyMenu.kResourceDisplayHeight, 0))
    self.resourceDisplayBackground:SetTexture(GUIMarineBuyMenu.kContentBgBackTexture)
    self.resourceDisplayBackground:SetTexturePixelCoordinates(0, 0, GUIMarineBuyMenu.kBackgroundWidth, GUIMarineBuyMenu.kResourceDisplayHeight)
    self.content:AddChild(self.resourceDisplayBackground)
    
    self.resourceDisplayIcon = GUIManager:CreateGraphicItem()
    self.resourceDisplayIcon:SetSize(Vector(GUIMarineBuyMenu.kResourceIconWidth, GUIMarineBuyMenu.kResourceIconHeight, 0))
    self.resourceDisplayIcon:SetAnchor(GUIItem.Right, GUIItem.Center)
    self.resourceDisplayIcon:SetPosition(Vector(-GUIMarineBuyMenu.kResourceIconWidth * 2.2, -GUIMarineBuyMenu.kResourceIconHeight / 2, 0))
    self.resourceDisplayIcon:SetTexture(GUIMarineBuyMenu.kResourceIconTexture)
    self.resourceDisplayIcon:SetColor(GUIMarineBuyMenu.kTextColor)
    self.resourceDisplayBackground:AddChild(self.resourceDisplayIcon)

    self.resourceDisplay = GUIManager:CreateTextItem()
    self.resourceDisplay:SetFontName(GUIMarineBuyMenu.kFont)
    self.resourceDisplay:SetFontIsBold(true)
    self.resourceDisplay:SetAnchor(GUIItem.Right, GUIItem.Center)
    self.resourceDisplay:SetPosition(Vector(-GUIMarineBuyMenu.kResourceIconWidth , 0, 0))
    self.resourceDisplay:SetTextAlignmentX(GUIItem.Align_Min)
    self.resourceDisplay:SetTextAlignmentY(GUIItem.Align_Center)
    
    self.resourceDisplay:SetColor(GUIMarineBuyMenu.kTextColor)
    --self.resourceDisplay:SetColor(GUIMarineBuyMenu.kTextColor)
    
    self.resourceDisplay:SetText("")
    self.resourceDisplayBackground:AddChild(self.resourceDisplay)
    
    self.currentDescription = GUIManager:CreateTextItem()
    self.currentDescription:SetFontName(GUIMarineBuyMenu.kFont)
    self.currentDescription:SetFontIsBold(true)
    self.currentDescription:SetAnchor(GUIItem.Right, GUIItem.Top)
    self.currentDescription:SetPosition(Vector(-GUIMarineBuyMenu.kResourceIconWidth * 3 , GUIMarineBuyMenu.kResourceIconHeight, 0))
    self.currentDescription:SetTextAlignmentX(GUIItem.Align_Max)
    self.currentDescription:SetTextAlignmentY(GUIItem.Align_Center)
    self.currentDescription:SetColor(GUIMarineBuyMenu.kTextColor)
    self.currentDescription:SetText(Combat_ResolveString("CURRENT"))
    
    self.resourceDisplayBackground:AddChild(self.currentDescription) 

end

function GUIMarineBuyMenu:_UpdateResourceDisplay(deltaTime)

    self.resourceDisplay:SetText(ToString(PlayerUI_GetPlayerResources()))
    
end

function GUIMarineBuyMenu:_UninitializeResourceDisplay()

    GUI.DestroyItem(self.resourceDisplay)
    self.resourceDisplay = nil
    
    GUI.DestroyItem(self.resourceDisplayIcon)
    self.resourceDisplayIcon = nil
    
    GUI.DestroyItem(self.resourceDisplayBackground)
    self.resourceDisplayBackground = nil
    
end

function GUIMarineBuyMenu:_InitializeCloseButton()

    self.closeButton = GUIManager:CreateGraphicItem()
    self.closeButton:SetAnchor(GUIItem.Right, GUIItem.Bottom)
    self.closeButton:SetSize(Vector(GUIMarineBuyMenu.kButtonWidth, GUIMarineBuyMenu.kButtonHeight, 0))
    self.closeButton:SetPosition(Vector(-GUIMarineBuyMenu.kButtonWidth, GUIMarineBuyMenu.kPadding, 0))
    self.closeButton:SetTexture(GUIMarineBuyMenu.kButtonTexture)
    self.closeButton:SetLayer(kGUILayerPlayerHUDForeground4)
    self.content:AddChild(self.closeButton)
    
    self.closeButtonText = GUIManager:CreateTextItem()
    self.closeButtonText:SetAnchor(GUIItem.Middle, GUIItem.Center)
    self.closeButtonText:SetFontName(GUIMarineBuyMenu.kFont)
    self.closeButtonText:SetTextAlignmentX(GUIItem.Align_Center)
    self.closeButtonText:SetTextAlignmentY(GUIItem.Align_Center)
    self.closeButtonText:SetText("EXIT")
    self.closeButtonText:SetFontIsBold(true)
    self.closeButtonText:SetColor(GUIMarineBuyMenu.kCloseButtonColor)
    self.closeButton:AddChild(self.closeButtonText)
    
end

function GUIMarineBuyMenu:_UpdateCloseButton(deltaTime)

    if self:_GetIsMouseOver(self.closeButton) then
        self.closeButton:SetColor(Color(1, 1, 1, 1))
    else
        self.closeButton:SetColor(Color(0.5, 0.5, 0.5, 1))
    end

end

function GUIMarineBuyMenu:_UninitializeCloseButton()
    
    GUI.DestroyItem(self.closeButton)
    self.closeButton = nil

end

function GUIMarineBuyMenu:_InitializeRefundButton()
    self.refundButton = GUIManager:CreateGraphicItem()
    self.refundButton:SetAnchor(GUIItem.Right, GUIItem.Bottom)
    self.refundButton:SetSize(Vector(GUIMarineBuyMenu.kButtonWidth, GUIMarineBuyMenu.kButtonHeight, 0))
    self.refundButton:SetPosition(Vector(-GUIMarineBuyMenu.kButtonWidth*2 - GUIMarineBuyMenu.kPadding, GUIMarineBuyMenu.kPadding, 0))
    self.refundButton:SetTexture(GUIMarineBuyMenu.kButtonTexture)
    self.refundButton:SetLayer(kGUILayerPlayerHUDForeground4)
    self.content:AddChild(self.refundButton)
    
    self.refundButtonText = GUIManager:CreateTextItem()
    self.refundButtonText:SetAnchor(GUIItem.Middle, GUIItem.Center)
    self.refundButtonText:SetFontName(GUIMarineBuyMenu.kFont)
    self.refundButtonText:SetTextAlignmentX(GUIItem.Align_Center)
    self.refundButtonText:SetTextAlignmentY(GUIItem.Align_Center)
    self.refundButtonText:SetText(Combat_ResolveString("COMBAT_REFUND_MARINE"))
    self.refundButtonText:SetFontIsBold(true)
    self.refundButtonText:SetColor(GUIMarineBuyMenu.kCloseButtonColor)
    self.refundButton:AddChild(self.refundButtonText)
end

function GUIMarineBuyMenu:_UpdateRefundButton(deltaTime)

    if self:_GetIsMouseOver(self.refundButton) then
        self.refundButton:SetColor(Color(1, 1, 1, 1))
        -- the discription text under the buttons
        self.itemName:SetText(Combat_ResolveString("COMBAT_REFUND_TITLE_MARINE"))
        self.itemDescription:SetText(Combat_ResolveString("COMBAT_REFUND_DESCRIPTION_MARINE"))
        self.itemDescription:SetTextClipped(true, GUIMarineBuyMenu.kItemDescriptionSize.x - 2* GUIMarineBuyMenu.kPadding, GUIMarineBuyMenu.kItemDescriptionSize.y - GUIMarineBuyMenu.kPadding)
        self.itemName:SetIsVisible(true)
        self.itemDescription:SetIsVisible(true)
    else
        self.refundButton:SetColor(Color(0.5, 0.5, 0.5, 1))
    end

end

function GUIMarineBuyMenu:_ClickRefundButton()

    Shared.ConsoleCommand("co_refundall")

end

function GUIMarineBuyMenu:_UninitializeRefundButton()
    GUI.DestroyItem(self.refundButton)
    self.refundButton = nil
end

--
-- Checks if the mouse is over the passed in GUIItem and plays a sound if it has just moved over.
--
function GUIMarineBuyMenu:_GetIsMouseOver(overItem)

    local mouseOver = GUIItemContainsPoint(overItem, Client.GetCursorPosScreen())
    if mouseOver and not self.mouseOverStates[overItem] then
        MarineBuy_OnMouseOver()
    end
    self.mouseOverStates[overItem] = mouseOver
    return mouseOver
    
end

function GUIMarineBuyMenu:SendKeyEvent(key, down)

    local closeMenu = false
    local inputHandled = false
    
    if key == InputKey.MouseButton0 and self.mousePressed ~= down then

        self.mousePressed = down
        
        local mouseX, mouseY = Client.GetCursorPosScreen()
        if down then
                    
            inputHandled, closeMenu = self:_HandleItemClicked(mouseX, mouseY)
            
            if not inputHandled then
            
                -- Check if the close button was pressed.
                if self:_GetIsMouseOver(self.closeButton) then
                    closeMenu = true
                    inputHandled = true
                    self:OnClose()
                end

                -- Check if the close button was pressed.
                if not closeMenu then
                    if self:_GetIsMouseOver(self.refundButton) then
                    self:_ClickRefundButton()
                    closeMenu = true
                    inputHandled = true
                    self:OnClose()
                    end
                end
            end
        end
        
    end
    
    if InputKey.Escape == key and not down then
        closeMenu = true
        inputHandled = true
        self:OnClose()
    end

    if closeMenu then
        self.closingMenu = true
        self:OnClose()
    end
    
    -- No matter what, this menu consumes MouseButton0/1.
    if key == InputKey.MouseButton0 or key == InputKey.MouseButton1 then
        inputHandled = true
    end
    
    return inputHandled -- inputHandled
    
end

function GUIMarineBuyMenu:_SetSelectedItem(techId)

    self.selectedItem = techId
    MarineBuy_OnItemSelect(techId)

end

function GUIMarineBuyMenu:_HandleItemClicked(mouseX, mouseY)

    for i, item in ipairs(self.itemButtons) do
    
        if self:_GetIsMouseOver(item.Button) then
        
            local researched = self.player:GotRequirements(item.Upgrade)
            local itemCost = item.Upgrade:GetLevels()
            local upgradesCost = self:_GetSelectedUpgradesCost()
            local canAfford = PlayerUI_GetPlayerResources() >= itemCost + upgradesCost 
            local hasItem = self.player:GotItemAlready(item.Upgrade)
            
            if researched and canAfford and not hasItem then
            
                self.player:Combat_PurchaseItemAndUpgrades(item.Upgrade:GetTextCode())
                self:OnClose()
                
                return true, true
                
            end
			
			if not researched then
				Shared.PlaySound(nil, GUIMarineBuyMenu.kNeedsResearch)
			elseif not canAfford then
				Shared.PlaySound(nil, GUIMarineBuyMenu.kMoreResources)
			end
            
        end 
        
    end
    
    return false, false
    
end

function GUIMarineBuyMenu:_GetSelectedUpgradesCost()

    local upgradeCosts = 0
    
   -- for k, upgrade in ipairs(self.selectedUpgrades) do
    
        --upgradeCosts = upgradeCosts + MarineBuy_GetCosts(upgrade)
    
    --end
    
    return upgradeCosts
    
end