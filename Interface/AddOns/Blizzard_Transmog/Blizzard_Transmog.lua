local addon, ns = ...

local mainTransmogFrameTitle = "Transmogrify"

local sex = UnitSex("player")
local _, raceFileName = UnitRace("player")
local _, classFileName = UnitClass("player")

local previewSetupVersion = "classic"

local armorSlots = {"Head", "Shoulder", "Chest", "Wrist", "Hands", "Waist", "Legs", "Feet"}
local backSlot = "Back"
local miscellaneousSlots = {"Tabard", "Shirt"}
local mainHandSlot = "Main Hand"
local offHandSlot = "Off-hand"
local rangedSlot = "Ranged"

-- For hiding hair/beard
local chestSlots = {"Chest", "Tabard", "Shirt"}

-- Used in look saving/sending. Chenging wil breack compatibility.
local slotOrder = { "Head", "Shoulder", "Back", "Chest", "Shirt", "Tabard", "Wrist", "Hands", "Waist", "Legs", "Feet", "Main Hand", "Off-hand", "Ranged",}

local slotTextures = {
	["Head"] =      "Interface\\Paperdoll\\ui-paperdoll-slot-head",
	["Shoulder"] =  "Interface\\Paperdoll\\ui-paperdoll-slot-shoulder",
	["Back"] =      "Interface\\Paperdoll\\ui-paperdoll-slot-chest",
	["Chest"] =     "Interface\\Paperdoll\\ui-paperdoll-slot-chest",
	["Shirt"] =     "Interface\\Paperdoll\\ui-paperdoll-slot-shirt",
	["Tabard"] =    "Interface\\Paperdoll\\ui-paperdoll-slot-tabard",
	["Wrist"] =     "Interface\\Paperdoll\\ui-paperdoll-slot-wrists",
	["Hands"] =     "Interface\\Paperdoll\\ui-paperdoll-slot-hands",
	["Waist"] =     "Interface\\Paperdoll\\ui-paperdoll-slot-waist",
	["Legs"] =      "Interface\\Paperdoll\\ui-paperdoll-slot-legs",
	["Feet"] =      "Interface\\Paperdoll\\ui-paperdoll-slot-feet",
	["Main Hand"] = "Interface\\Paperdoll\\ui-paperdoll-slot-mainhand",
	["Off-hand"] =  "Interface\\Paperdoll\\ui-paperdoll-slot-secondaryhand",
	["Ranged"] =    "Interface\\Paperdoll\\ui-paperdoll-slot-ranged",
}

local slotSubclasses = {--[[
	["slot1"] = {subclass1, subclass2, ...},
	["slot2"] = {subclass1, subclass2, ...},
	["slot2"] = {subclass1, subclass2, ...},
	...]]
}

do
	for i, slot in ipairs(armorSlots) do slotSubclasses[slot] = {"Cloth", "Leather", "Mail", "Plate"} end
	for i, slot in ipairs(miscellaneousSlots) do slotSubclasses[slot] = {"Miscellaneous", } end
	slotSubclasses[backSlot] = {"Cloth", }
	slotSubclasses[mainHandSlot] = {
		"1H Axe", "1H Mace", "1H Sword", "1H Dagger", "1H Fist",
		"MH Axe", "MH Mace", "MH Sword", "MH Dagger", "MH Fist",
		"2H Axe", "2H Mace", "2H Sword", "Polearm", "Staff" }
	slotSubclasses[offHandSlot] = { "OH Axe", "OH Mace", "OH Sword", "OH Dagger", "OH Fist", "Shield", "Held in Off-hand"}
	slotSubclasses[rangedSlot] = {"Bow", "Crossbow", "Gun", "Wand", "Thrown"}
end

local defaultSlot = "Head"

local defaultArmorSubclass = {
	["MAGE"] = "Cloth",
	["PRIEST"] = "Cloth",
	["WARLOCK"] = "Cloth",
	["DRUID"] = "Leather",
	["ROGUE"] = "Leather",
	["HUNTER"] = "Mail",
	["SHAMAN"] = "Mail",
	["PALADIN"] = "Plate",
	["WARRIOR"] = "Plate",
	["DEATHKNIGHT"] = "Plate"
}


local defaultSettings = {
	dressingRoomBackgroundColor = {0.6, 0.6, 0.6, 1},
	dressingRoomBackgroundTexture = {
		[GetRealmName()] = {
			[GetUnitName("player")] = classFileName == "DEATHKNIGHT" and classFileName or raceFileName,
		},
	},
	previewSetup = "classic", -- possible values are "classic" and "modern",
	showTransmogButton = true,
	showShortcutsInTooltip = true,
	hideHairOnCloakPreview = false,
	hideHairBeardOnChestPreview = false,
	useServerTimeInReceivedAppearances = false,
	announceAppearanceReceiving = true,
	ignoreUIScaling = false,
}

local function GetSettings()
	local function copyTable(tableFrom)
		local result = {}
		for k, v in pairs(tableFrom) do
			if type(v) == "table" then
				result[k] = copyTable(v)
			else
				result[k] = v
			end
		end
		return result
	end

	if _G["TransmogSettings"] == nil then
		_G["TransmogSettings"] = copyTable(defaultSettings)
	else
		for k, v in pairs(defaultSettings) do
			if _G["TransmogSettings"][k] == nil then
				_G["TransmogSettings"][k] = type(v) == "table" and copyTable(v) or v
			end
		end
		if _G["TransmogSettings"].dressingRoomBackgroundTexture[GetRealmName()] == nil then
			_G["TransmogSettings"].dressingRoomBackgroundTexture[GetRealmName()] = {}
		end
		if _G["TransmogSettings"].dressingRoomBackgroundTexture[GetRealmName()][GetUnitName("player")] == nil then
			_G["TransmogSettings"].dressingRoomBackgroundTexture[GetRealmName()][GetUnitName("player")] = defaultSettings.dressingRoomBackgroundTexture[GetRealmName()][GetUnitName("player")]
		end
	end

	return _G["TransmogSettings"]
end


local function arrayHasValue(array, value)
	for i, v in ipairs(array) do
		if v == value then
			return true
		end
	end
	return false
end


local dressingRoomBorderBackdrop = { -- For a frame above DressingRoom
	bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
	edgeFile = "Interface\\AddOns\\Blizzard_Transmog\\images\\mirror-border",
	tile = false, tileSize = 16, edgeSize = 32,
	insets = { left = 4, right = 4, top = 4, bottom = 4 }
}


mainTransmogFrame = CreateFrame("Frame", addon, UIParent)
-- "Hurry up! You must hack the main frame!"
-- <hackerman noises>
table.insert(UISpecialFrames, mainTransmogFrame:GetName())
do 
	mainTransmogFrame:SetWidth(1045)
	mainTransmogFrame:SetHeight(505)
	mainTransmogFrame:SetPoint("CENTER")
	mainTransmogFrame:Hide()
	mainTransmogFrame:EnableMouse(true)
	mainTransmogFrame:SetScript("OnShow", function() PlaySound("igCharacterInfoOpen") end)
	mainTransmogFrame:SetScript("OnHide", function() PlaySound("igCharacterInfoClose") end)

	local title = mainTransmogFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	title:SetPoint("TOP", 0, -9)
	title:SetText(mainTransmogFrameTitle)

	local titleBg = mainTransmogFrame:CreateTexture(nil, "BACKGROUND")
	titleBg:SetTexture("Interface\\PaperDollInfoFrame\\UI-GearManager-Title-Background")
	titleBg:SetPoint("TOPLEFT", 10, -7)
	titleBg:SetPoint("BOTTOMRIGHT", mainTransmogFrame, "TOPRIGHT", -28, -24)

	local menuBg = mainTransmogFrame:CreateTexture(nil, "BACKGROUND")
	menuBg:SetTexture("Interface\\WorldStateFrame\\WorldStateFinalScoreFrame-TopBackground")
	menuBg:SetTexCoord(0, 1, 0, 0.8125) 
	menuBg:SetPoint("TOPLEFT", 10, -26)
	menuBg:SetPoint("RIGHT", -6, 0)
	menuBg:SetHeight(48)
	menuBg:SetVertexColor(0.5, 0.5, 0.5)

	local frameBg = mainTransmogFrame:CreateTexture(nil, "BACKGROUND")
	frameBg:SetTexture("Interface\\WorldStateFrame\\WorldStateFinalScoreFrame-TopBackground")
	frameBg:SetTexCoord(0, 0.5, 0, 0.8125) 
	frameBg:SetPoint("TOPLEFT", menuBg, "BOTTOMLEFT")
	frameBg:SetPoint("TOPRIGHT", menuBg, "BOTTOMRIGHT")
	frameBg:SetPoint("BOTTOM", 0, 5)
	frameBg:SetVertexColor(0.25, 0.25, 0.25)
	
	local topLeft = mainTransmogFrame:CreateTexture(nil, "BORDER")
	topLeft:SetTexture("Interface\\PaperDollInfoFrame\\UI-GearManager-Border")
	topLeft:SetTexCoord(0.5, 0.625, 0, 1)
	topLeft:SetWidth(64)
	topLeft:SetHeight(64)
	topLeft:SetPoint("TOPLEFT")
	
	local topRight = mainTransmogFrame:CreateTexture(nil, "BORDER")
	topRight:SetTexture("Interface\\PaperDollInfoFrame\\UI-GearManager-Border")
	topRight:SetTexCoord(0.625, 0.75, 0, 1)
	topRight:SetWidth(64)
	topRight:SetHeight(64)
	topRight:SetPoint("TOPRIGHT")
	
	local top = mainTransmogFrame:CreateTexture(nil, "BORDER")
	top:SetTexture("Interface\\PaperDollInfoFrame\\UI-GearManager-Border")
	top:SetTexCoord(0.25, 0.37, 0, 1)
	top:SetPoint("TOPLEFT", topLeft, "TOPRIGHT")
	top:SetPoint("TOPRIGHT", topRight, "TOPLEFT")

	local menuSeparatorLeft = mainTransmogFrame:CreateTexture(nil, "BORDER")
	menuSeparatorLeft:SetTexture("Interface\\PaperDollInfoFrame\\UI-GearManager-Border")
	menuSeparatorLeft:SetTexCoord(0.5, 0.5546875, 0.25, 0.53125)
	menuSeparatorLeft:SetPoint("TOPLEFT", topLeft, "BOTTOMLEFT")
	menuSeparatorLeft:SetWidth(28)
	menuSeparatorLeft:SetHeight(18)

	local menuSeparatorRight = mainTransmogFrame:CreateTexture(nil, "BORDER")
	menuSeparatorRight:SetTexture("Interface\\PaperDollInfoFrame\\UI-GearManager-Border")
	menuSeparatorRight:SetTexCoord(0.7109375, 0.75, 0.25, 0.53125)
	menuSeparatorRight:SetPoint("TOPRIGHT", topRight, "BOTTOMRIGHT")
	menuSeparatorRight:SetWidth(20)
	menuSeparatorRight:SetHeight(18)

	local menuSeparatorCenter = mainTransmogFrame:CreateTexture(nil, "BORDER")
	menuSeparatorCenter:SetTexture("Interface\\PaperDollInfoFrame\\UI-GearManager-Border")
	menuSeparatorCenter:SetTexCoord(0.564453125, 0.671875, 0.25, 0.53125)
	menuSeparatorCenter:SetPoint("TOPLEFT", menuSeparatorLeft, "TOPRIGHT")
	menuSeparatorCenter:SetPoint("BOTTOMRIGHT", menuSeparatorRight, "BOTTOMLEFT")

	local botLeft = mainTransmogFrame:CreateTexture(nil, "BORDER")
	botLeft:SetTexture("Interface\\PaperDollInfoFrame\\UI-GearManager-Border")
	botLeft:SetTexCoord(0.75, 0.875, 0, 1)
	botLeft:SetPoint("BOTTOMLEFT")
	botLeft:SetWidth(64)
	botLeft:SetHeight(64)

	local left = mainTransmogFrame:CreateTexture(nil, "BORDER")
	left:SetTexture("Interface\\PaperDollInfoFrame\\UI-GearManager-Border")
	left:SetTexCoord(0, 0.125, 0, 1)
	left:SetPoint("TOPLEFT", menuSeparatorLeft, "BOTTOMLEFT")
	left:SetPoint("BOTTOMRIGHT", botLeft, "TOPRIGHT")

	local botRight = mainTransmogFrame:CreateTexture(nil, "BORDER")
	botRight:SetTexture("Interface\\PaperDollInfoFrame\\UI-GearManager-Border")
	botRight:SetTexCoord(0.875, 1, 0, 1)
	botRight:SetPoint("BOTTOMRIGHT")
	botRight:SetWidth(64)
	botRight:SetHeight(64)

	local right = mainTransmogFrame:CreateTexture(nil, "BORDER")
	right:SetTexture("Interface\\PaperDollInfoFrame\\UI-GearManager-Border")
	right:SetTexCoord(0.125, 0.24, 0, 1)
	right:SetPoint("TOPRIGHT", menuSeparatorRight, "BOTTOMRIGHT", -1, 0)
	right:SetPoint("BOTTOMLEFT", botRight, "TOPLEFT", 4, 0)

	local bot = mainTransmogFrame:CreateTexture(nil, "BORDER")
	bot:SetTexture("Interface\\PaperDollInfoFrame\\UI-GearManager-Border")
	bot:SetTexCoord(0.38, 0.45, 0, 1)
	bot:SetPoint("BOTTOMLEFT", botLeft, "BOTTOMRIGHT")
	bot:SetPoint("TOPRIGHT", botRight, "TOPLEFT")

	local separatorV = mainTransmogFrame:CreateTexture(nil, "BORDER")
	separatorV:SetTexture("Interface\\PaperDollInfoFrame\\UI-GearManager-Border")
	separatorV:SetTexCoord(0.23046875, 0.236328125, 0, 1)
	separatorV:SetPoint("TOPLEFT", 410, -72)
	separatorV:SetPoint("BOTTOM", 0, 32)
	separatorV:SetWidth(3)
	separatorV:SetVertexColor(0.5, 0.5, 0.5)
	
	mainTransmogFrame.stats = CreateFrame("Frame", nil, mainTransmogFrame)
	local stats = mainTransmogFrame.stats
	stats:SetBackdrop({
		bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		tile = true, tileSize = 16, edgeSize = 16,
		insets = { left = 3, right = 3, top = 5, bottom = 3 }
	})
	stats:SetBackdropColor(0.12, 0.12, 0.12)
	stats:SetBackdropBorderColor(0.25, 0.25, 0.25)
	stats:SetPoint("BOTTOMLEFT", 410, 8)
	stats:SetPoint("BOTTOMRIGHT", -6, 8)
	stats:SetHeight(24)

	mainTransmogFrame.buttons = {}

	local close = CreateFrame("Button", nil, mainTransmogFrame, "UIPanelCloseButton")
	close:SetPoint("TOPRIGHT", 2, 1)
	close:SetScript("OnClick", function(self)
		self:GetParent():Hide()
	end)

	mainTransmogFrame.buttons.close = close
end


mainTransmogFrame.dressingRoom = ns.CreateDressingRoom(nil, mainTransmogFrame)

do
	local dr = mainTransmogFrame.dressingRoom
	dr:SetPoint("TOPLEFT", 10, -74)
	dr:SetSize(400, 400)

	local border = CreateFrame("Frame", nil, dr)
	border:SetAllPoints()
	border:SetBackdrop(dressingRoomBorderBackdrop)
	border:SetBackdropColor(0, 0, 0, 0)

	dr.backgroundTextures = {}
	for s in ("human,nightelf,dwarf,gnome,draenei,orc,scourge,tauren,troll,bloodelf,deathknight,goblin,worgen"):gmatch("%w+") do
		dr.backgroundTextures[s] = dr:CreateTexture(nil, "BACKGROUND")
		dr.backgroundTextures[s]:SetTexture("Interface\\AddOns\\Blizzard_Transmog\\images\\"..s)
		dr.backgroundTextures[s]:SetAllPoints()
		dr.backgroundTextures[s]:Hide()
	end
	dr.backgroundTextures["color"] = dr:CreateTexture(nil, "BACKGROUND")
	dr.backgroundTextures["color"]:SetAllPoints()
	dr.backgroundTextures["color"]:SetTexture(1, 1, 1)
	dr.backgroundTextures["color"]:Hide()

	-- SetLight(enabled, omni, dirX, dirY, dirZ, ambIntensity, ambR, ambG, ambB, dirIntensity, dirR, dirG, dirB)
	local defaultLight = {1, 0, 0, 1, 0, 1, 0.7, 0.7, 0.7, 1, 0.8, 0.8, 0.64}
end

mainTransmogFrame.buttons.reset = CreateFrame("Button", "$parentButtonReset", mainTransmogFrame, "UIPanelButtonTemplate2")

do
	local btn = mainTransmogFrame.buttons.reset
	btn:SetPoint("TOPRIGHT", mainTransmogFrame.dressingRoom, "BOTTOMRIGHT")
	btn:SetPoint("BOTTOM", mainTransmogFrame.stats, "BOTTOM", 0, 1)
	btn:SetWidth(mainTransmogFrame.dressingRoom:GetWidth()/4)
	btn:SetText("Reset")
	btn:SetScript("OnClick", function()
		mainTransmogFrame.buttons.clearing = false
		mainTransmogFrame.dressingRoom:Reset()
		PlaySound("gsTitleOptionOK")
	end)
end

mainTransmogFrame.buttons.clear = CreateFrame("Button", "$parentButtonClear", mainTransmogFrame, "UIPanelButtonTemplate2")
mainTransmogFrame.buttons.clearing = false

do
	local btnClearTransmog = mainTransmogFrame.buttons.clear
	btnClearTransmog:SetPoint("CENTER", mainTransmogFrame.dressingRoom, "CENTER")
	btnClearTransmog:SetPoint("BOTTOM", mainTransmogFrame.stats, "BOTTOM", 0, 1)
	btnClearTransmog:SetWidth(mainTransmogFrame.dressingRoom:GetWidth()/4)
	btnClearTransmog:SetText("Clear")
	btnClearTransmog:SetScript("OnClick", function()
		mainTransmogFrame.buttons.clearing = true
		mainTransmogFrame.dressingRoom:Reset()
		PlaySound("gsTitleOptionOK")
	end)
end

mainTransmogFrame.buttons.applyTransmog = CreateFrame("Button", "$parentButtonTransmogApply", mainTransmogFrame, "UIPanelButtonTemplate2")

do
	local btn = mainTransmogFrame.buttons.applyTransmog
	btn:SetPoint("TOPLEFT", mainTransmogFrame.dressingRoom, "BOTTOMLEFT")
	btn:SetPoint("BOTTOM", mainTransmogFrame.stats, "BOTTOM", 0, 1)
	btn:SetWidth(mainTransmogFrame.dressingRoom:GetWidth()/4)
	btn:SetText("Apply")
	btn:SetScript("OnClick", function()
		mainTransmogFrame.dressingRoom:ApplyTransmog()
		PlaySound("gsTitleOptionOK")
	end)
end

---------------- TABS ----------------

local TAB_NAMES = {"Items", "Sets", "REMOVED"}

mainTransmogFrame.tabs = {}

do
	local tabs = {}

	local function tab_OnClick(self)
		local selectedTab = PanelTemplates_GetSelectedTab(self:GetParent())
		local tab = tabs[selectedTab]
		if tab ~= nil then
			tab:Hide()
		end
		PanelTemplates_SetTab(self:GetParent(), self:GetID())
		tabs[self:GetID()]:Show()
		PlaySound("gsTitleOptionOK")
	end

	for i = 1, #TAB_NAMES do
		mainTransmogFrame.buttons["tab"..i] = CreateFrame("Button", "$parentTab"..i, mainTransmogFrame, "OptionsFrameTabButtonTemplate")
		local btn = mainTransmogFrame.buttons["tab"..i]
		btn:SetText(TAB_NAMES[i])
		btn:SetID(i)
		btn:SetScale(1.5);

		if i == 1 then
			btn:SetPoint("BOTTOMLEFT", btn:GetParent(), "TOPLEFT", 400 / 1.5, -70 / 1.5)
		else
			btn:SetPoint("LEFT", _G[mainTransmogFrame:GetName().."Tab"..(i - 1)], "RIGHT", -15, 0)
		end
		btn:SetScript("OnClick", tab_OnClick)

		local frame = CreateFrame("Frame", "$parentTab"..i.."Content", mainTransmogFrame)
		frame:SetPoint("TOPLEFT", 410, -73)
		frame:SetPoint("BOTTOMRIGHT", -8, 28)
		frame:Hide()
		table.insert(tabs, frame)

		-- @HelloKitty: Hack to disable settings tab, kinda a pain to remove it entirely.
		if (TAB_NAMES[i] == "REMOVED") then
			btn:Hide();
		end
	end
	
	PanelTemplates_SetNumTabs(mainTransmogFrame, #TAB_NAMES)
	tab_OnClick(_G[mainTransmogFrame:GetName().."Tab1"])

	mainTransmogFrame.tabs.preview = tabs[1]
	mainTransmogFrame.tabs.appearances = tabs[2]
	mainTransmogFrame.tabs.settings = tabs[3]
end

---------------- SLOTS ----------------

mainTransmogFrame.slots = {}
mainTransmogFrame.selectedSlot = nil

local function slot_OnShiftLeftClick(self)
	if self.itemId ~= nil then
		-- @HelloKitty: Shiftclick linking ugly addon stuff removed
	end
end

local function getIndex(array, value)
	for i = 1, #array do
		if array[i] == value then
			return i    
		end
	end
	return nil
end

local function slot_OnControlLeftClick(self)
	if self.itemId ~= nil then
		-- @HelloKitty: I disabled WoWhead link stuff (too addon-y)
		-- ns.ShowWowheadURLDialog(self.itemId)
	end
end


local function slot_OnLeftClick(self)
	local selectedSlot = mainTransmogFrame.selectedSlot
	if selectedSlot ~= nil then
		selectedSlot:UnlockHighlight()
	end

	-- @HelloKitty: If we already load that slot let's do nothing
	if (selectedSlot == self) then
		return
	end

	mainTransmogFrame.selectedSlot = self
	mainTransmogFrame.tabs.preview.subclassMenu:Update(self.slotName)
	--[[ ReTryOn weapon so the model displays
	the weapon of the clicked (selected) slot. ]]
	if self.itemId ~= nil and getIndex({mainHandSlot, offHandSlot, rangedSlot}, self.slotName) then
		mainTransmogFrame.dressingRoom:TryOn(self.itemId)
	end
	self:LockHighlight()
end

local function slot_OnRightClick(self)
	self:RemoveItem()
end

local function slot_OnClick(self, button)
	if button == "LeftButton" then
		if IsShiftKeyDown() then
			slot_OnShiftLeftClick(self)
		elseif IsControlKeyDown() then
			slot_OnControlLeftClick(self)
		else
			slot_OnLeftClick(self)
		end
		PlaySound("gsTitleOptionOK")
	elseif button == "RightButton" then
		slot_OnRightClick(self)
	end
end

local function slot_GetUnderlyingEquippedItemId(self)
	local characterSlotName = self.slotName
	if characterSlotName == mainHandSlot then characterSlotName = "MainHand" end
	if characterSlotName == offHandSlot then characterSlotName = "SecondaryHand" end
	if characterSlotName == rangedSlot then characterSlotName = "Ranged" end
	if characterSlotName == backSlot then characterSlotName = "Back" end
	local slotId = GetInventorySlotInfo(characterSlotName.."Slot")
	local itemId = GetInventoryItemID("player", slotId)
	local name, link, _, _, _, _, _, _, _, texture = GetItemInfo(itemId ~= nil and itemId or 0)
	if name ~= nil then
		return itemId;
	else
		return 0;
	end
end

local function slot_OnEnter(self)
	GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
	if self.itemId == nil then
		GameTooltip:AddLine(self.slotName)
	else
		local name, link = GetItemInfo(self.itemId)
		GameTooltip:ClearLines();
		GameTooltip:AddLine(name);
		if GetSettings().showShortcutsInTooltip then
			if (slot_GetUnderlyingEquippedItemId(self) ~= self.itemId) then
				GameTooltip:AddLine("|cff00ff00Right Click:|r Remove the appearance.");
			else
				GameTooltip:AddLine("|cff00ff00This item is equipped|r");
			end
		end
	end
	GameTooltip:Show();
end

local function slot_OnLeave(self)
	GameTooltip:Hide()
end

local function slot_HasOverrideEquipped(self)
	local characterSlotName = self.slotName
	if characterSlotName == mainHandSlot then characterSlotName = "MainHand" end
	if characterSlotName == offHandSlot then characterSlotName = "SecondaryHand" end
	if characterSlotName == rangedSlot then characterSlotName = "Ranged" end
	if characterSlotName == backSlot then characterSlotName = "Back" end
	local slotId = GetNonTransmogForSlot(slotId)
	local itemId = GetInventoryItemID("player", slotId)
	local name, link, _, _, _, _, _, _, _, texture = GetItemInfo(itemId ~= nil and itemId or 0)
	if name ~= nil then
		return self.itemId ~= itemId;
	else
		return itemId ~= 0;
	end
end

local function slot_Reset(self, useBaseItem)
	local characterSlotName = self.slotName
	if characterSlotName == mainHandSlot then characterSlotName = "MainHand" end
	if characterSlotName == offHandSlot then characterSlotName = "SecondaryHand" end
	if characterSlotName == rangedSlot then characterSlotName = "Ranged" end
	if characterSlotName == backSlot then characterSlotName = "Back" end
	local slotId = GetInventorySlotInfo(characterSlotName.."Slot")

	if (mainTransmogFrame.buttons.clearing or useBaseItem) then
		itemId = GetNonTransmogForSlot(slotId);
	else
		-- @HelloKitty: We now load the actual current transmog slot ids
		itemId = GetTransmogForSlot(slotId);
	end


	-- If there is no overriden transmog item then use the default currently equipped item
	if (itemId == nil or itemId == 0 or itemId == 1) then
		itemId = GetInventoryItemID("player", slotId)
	end

	--local name, link, _, _, _, _, _, _, _, texture = GetItemInfo(itemId ~= nil and itemId or 0)
	if itemId ~= nil and itemId ~= 0 and itemId ~= 1 then
		self:SetItem(itemId)
	else
		self:RemoveItem()
	end
end

local function slot_RemoveItem(self)
	-- @HelloKitty: To prevent them from unequipping an appearance they are wearing by default
	-- we check what they have on (AKA check if they have an override)
	if slot_HasOverrideEquipped(self) and self.itemId ~= nil then

		-- @HelloKitty: We never fully remove a base item, use underlying ID if it has one
		local underlyingId = slot_GetUnderlyingEquippedItemId(self);
		if underlyingId ~= 0 then
			self:Reset(true);
			if (MouseIsOver(self)) then
				self:GetScript("OnEnter")(self)
			end
		else
			self.itemId = nil
			self.textures.empty:Show()
			self.textures.item:Hide()
			if (MouseIsOver(self)) then
				self:GetScript("OnEnter")(self)
			end
		end

		--[[ We cannot undress a specific slot
		of a DressUpModel in WotLK. Instead,
		we're undressing the whole model and
		dressing it up again without the slot. ]]
		mainTransmogFrame.dressingRoom:Undress()
		for _, slot in pairs(mainTransmogFrame.slots) do
			if slot.itemId ~= nil then
				mainTransmogFrame.dressingRoom:TryOn(slot.itemId)
			end
		end
	end
end

local function slot_SetItem(self, itemId)
	self.itemId = itemId
	ns.QueryItem(itemId, function(queriedItemId, success)
		if queriedItemId == self.itemId and success then
			local _, _, _, _, _, _, _, _, _, texture = GetItemInfo(queriedItemId)
			self.textures.empty:Hide()
			self.textures.item:SetTexture(texture)
			self.textures.item:Show()
			mainTransmogFrame.dressingRoom:TryOn(queriedItemId)
		end
	end)
end

--------- Slot building

do
	for slotName, texturePath in pairs(slotTextures) do
		local slot = CreateFrame("Button", "$parentSlot"..slotName, mainTransmogFrame, "ItemButtonTemplate")
		slot:RegisterForClicks("LeftButtonUp", "RightButtonUp")
		slot:SetFrameLevel(mainTransmogFrame.dressingRoom:GetFrameLevel() + 1)
		slot:SetScript("OnClick", slot_OnClick)
		slot:SetScript("OnEnter", slot_OnEnter)
		slot:SetScript("OnLeave", slot_OnLeave)
		slot.slotName = slotName
		mainTransmogFrame.slots[slotName] = slot
		slot.textures = {}
		slot.textures.empty = slot:CreateTexture(nil, "BACKGROUND")
		slot.textures.empty:SetTexture(texturePath)
		slot.textures.empty:SetAllPoints()
		slot.textures.item = slot:CreateTexture(nil, "BACKGROUND")
		slot.textures.item:SetAllPoints()
		slot.textures.item:Hide()
		slot.Reset = slot_Reset
		slot.SetItem = slot_SetItem
		slot.RemoveItem = slot_RemoveItem
	end

	local slots = mainTransmogFrame.slots
	slots["Head"]:SetPoint("TOPLEFT", mainTransmogFrame.dressingRoom, "TOPLEFT", 19, -19)
	slots["Shoulder"]:SetPoint("TOP", slots["Head"], "BOTTOM", 0, -4)
	slots["Back"]:SetPoint("TOP", slots["Shoulder"], "BOTTOM", 0, -4)
	slots["Chest"]:SetPoint("TOP", slots["Back"], "BOTTOM", 0, -4)
	slots["Shirt"]:SetPoint("TOP", slots["Chest"], "BOTTOM", 0, -36)
	slots["Tabard"]:SetPoint("TOP", slots["Shirt"], "BOTTOM", 0, -4)
	slots["Wrist"]:SetPoint("TOP", slots["Tabard"], "BOTTOM", 0, -36)

	slots["Hands"]:SetPoint("TOPRIGHT", mainTransmogFrame.dressingRoom, "TOPRIGHT", -19, -19)
	slots["Waist"]:SetPoint("TOP", slots["Hands"], "BOTTOM", 0, -4)
	slots["Legs"]:SetPoint("TOP", slots["Waist"], "BOTTOM", 0, -4)
	slots["Feet"]:SetPoint("TOP", slots["Legs"], "BOTTOM", 0, -4)

	slots["Off-hand"]:SetPoint("BOTTOM", mainTransmogFrame.dressingRoom, "BOTTOM", 0, 16)
	slots["Main Hand"]:SetPoint("RIGHT", slots["Off-hand"], "LEFT", -6, 0)
	slots["Ranged"]:SetPoint("LEFT", slots["Off-hand"], "RIGHT", 6, 0)
end

------- Tricks and hooks with slots and provided appearances. -------


local function btnReset_Hook()
	mainTransmogFrame.dressingRoom:Undress()
	for _, slot in pairs(mainTransmogFrame.slots) do
		if slot.slotName == rangedSlot and ("DRUIDSHAMANPALADINDEATHKNIGHT"):find(classFileName) then
			slot:RemoveItem()
		else
			slot:Reset()
		end
	end
end

local function tryOnFromSlots(dressUpModel)
	for _, slot in pairs(mainTransmogFrame.slots) do
		if slot.itemId ~= nil then
			dressUpModel:TryOn(slot.itemId)
		end
	end
end

--[[
	Have to reTryOn selected appearances since
	the model's reset each time it's shown.
]]
--[[
	After half a year I don't remeber anymore
	why I do it, but showing/hiding a DressUpModel
	breaks the model's positioning.
]]
local function dressingRoom_OnShow(self)
	self:Reset()
	self:Undress()
	tryOnFromSlots(self)
end

-- At first time it's shown.
mainTransmogFrame.slots[defaultSlot]:SetScript("OnShow", function(self)
	self:SetScript("OnShow", nil)
	mainTransmogFrame.buttons.reset:HookScript("OnClick", btnReset_Hook)
	mainTransmogFrame.buttons.clear:HookScript("OnClick", btnReset_Hook)
	mainTransmogFrame.dressingRoom:HookScript("OnShow", dressingRoom_OnShow)
	dressingRoom_OnShow(mainTransmogFrame.dressingRoom)
	btnReset_Hook()
	self:Click("LeftButton")
end)

---------------- PREVIEW TAB ----------------

mainTransmogFrame.tabs.preview.list = ns.CreatePreviewList(mainTransmogFrame.tabs.preview)
mainTransmogFrame.tabs.preview.slider = CreateFrame("Slider", "$parentSlider", mainTransmogFrame.tabs.preview, "UIPanelScrollBarTemplateLightBorder")

---------------- Slider

do
	local previewTab = mainTransmogFrame.tabs.preview
	local list = mainTransmogFrame.tabs.preview.list
	local slider = mainTransmogFrame.tabs.slider

	list:SetPoint("TOPLEFT")
	list:SetSize(601, 401)

	local label = list:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	label:SetPoint("TOP", list, "BOTTOM", 0, -5)
	label:SetJustifyH("CENTER")
	label:SetHeight(10)

	local slider = mainTransmogFrame.tabs.preview.slider
	slider:SetPoint("TOPRIGHT", -6, -21)
	slider:SetPoint("BOTTOMRIGHT", -6, 21)
	slider:EnableMouseWheel(true)
	slider:SetScript("OnMouseWheel", function(self, delta)
		self:SetValue(self:GetValue() - delta)
	end)
	slider:SetScript("OnMinMaxChanged", function(self, min, max)
		label:SetText(("Page: %s/%s"):format(self:GetValue(), max))
	end)
	
	slider.buttons = {}
	slider.buttons.up = _G[slider:GetName() .. "ScrollUpButton"]
	slider.buttons.down = _G[slider:GetName() .. "ScrollDownButton"]

	slider.buttons.up:SetScript("OnClick", function(self)
		slider:SetValue(slider:GetValue() - 1)
		PlaySound("gsTitleOptionOK")
	end)
	slider.buttons.down:SetScript("OnClick", function(self)
		slider:SetValue(slider:GetValue() + 1)
		PlaySound("gsTitleOptionOK")
	end)

	list:EnableMouseWheel(true)
	list:SetScript("OnMouseWheel", function(self, delta)
		slider:SetValue(slider:GetValue() - delta)
	end)

	slider:SetScript("OnValueChanged", function (self, value)
		local _, max = self:GetMinMaxValues()
		label:SetText(("Page: %s/%s"):format(value, max))
	end)

	slider:SetMinMaxValues(0, 0)
	slider:SetValueStep(1)
end

---------------- Preview list

do
	local previewTab = mainTransmogFrame.tabs.preview
	local list = previewTab.list
	local slider = previewTab.slider

	local slotSubclassPage = {} -- page per [slot][subclass] can be `nil`

	for slot, _ in pairs(mainTransmogFrame.slots) do
		slotSubclassPage[slot] = {}
	end

	local currSlot, currSubclass = defaultSlot, defaultArmorSubclass[classFileName]
	local records

	local hideHairItemId = 10289
	local hideHairBeardItemId = 29943

	ns.QueryItem(hideHairItemId)
	ns.QueryItem(hideHairBeardItemId)

	local function hairBeardControl(slot)
		if slot == backSlot and GetSettings().hideHairOnCloakPreview then
			list:TryOn(hideHairItemId)
		end
		if arrayHasValue(chestSlots, slot) and GetSettings().hideHairBeardOnChestPreview then
			list:TryOn(hideHairBeardItemId)
		end
	end

	previewTab.Update = function(self, slot, subclass)
		slotSubclassPage[currSlot][currSubclass] = slider:GetValue() > 0 and slider:GetValue() or 1
		currSlot = slot
		currSubclass = subclass
		records = ns.GetSubclassRecords(slot, subclass)

		local itemIds = {}
		local selectedItemId

		-- @HelloKitty: This is critical for reindexing records used for mouseover and click model apply otherwise it will index based on if ALL were known like original addon
		local realIndex = 1;
		for i=1, #records do
			local id = records[i]

			-- @HelloKitty: Check if the appearance is known so we can skip it if not
			if (IsTransmogAppearanceKnown(id)) then
				table.insert(itemIds, id)

				-- @HelloKitty: This is critical for reindexing records used for mouseover and click model apply otherwise it will index based on if ALL were known like original addon
				records[realIndex] = id;
				realIndex = realIndex + 1;
				if selectedItemId == nil and mainTransmogFrame.slots[slot].itemId ~= nil and arrayHasValue({ id }, mainTransmogFrame.slots[slot].itemId) then
					selectedItemId = id
				end
			end
		end
		list:SetItems(itemIds)
		if selectedItemId ~= nil then
			list:SelectByItemId(selectedItemId)
		end

		local setup = ns.GetPreviewSetup(previewSetupVersion, raceFileName, sex, slot, subclass)
		list:SetupModel(setup.width, setup.height, setup.x, setup.y, setup.z, setup.facing, setup.sequence)

		list:TryOn(nil)
		local page = slotSubclassPage[slot][subclass] ~= nil and slotSubclassPage[slot][subclass] or 1
		local pageCount = list:GetPageCount()

		-- @HelloKitty: New case where no appearances collected to avoid errors
		if (pageCount == 0) then
			pageCount = 1;
		end

		--[[ SetMinMaxValues triggers "OnValueChanged"
		via changing current value if current value is
		not in range of current min/max values. ]]
		local _, sliderMax = slider:GetMinMaxValues()
		if page > sliderMax then
			slider:SetMinMaxValues(1, pageCount)
		end
		if slider:GetValue() ~= page then
			slider:SetValue(page)
		else
			list:SetPage(page)
			list:Update()
		end
		slider:SetMinMaxValues(1, pageCount)
		hairBeardControl(slot)
	end

	previewTab:SetScript("OnShow", function(self)
		self:Update(currSlot, currSubclass)
	end)

	slider:HookScript("OnValueChanged", function(self, value)
		list:SetPage(value)
		list:Update()
		hairBeardControl(currSlot)
	end)

	local selectedInRecord = {} -- { [first id in record] = index of selected id, ...}
	local enteredButton

	local tabDummy = CreateFrame("Button", addon.."PreviewListTabDummy", previewTab)

	list.onEnter = function(self)
		local recordIndex = self:GetParent().itemIndex
		local id = records[recordIndex];
		GameTooltip:Hide()
		GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT")
		GameTooltip:ClearLines()
		GameTooltip:AddLine("This appearance is provided by:", 1, 1, 1)
		GameTooltip:AddLine(" ")
		GameTooltip:AddLine(GetItemInfo(id));
		local selectedIndex = selectedInRecord[id] ~= nil and selectedInRecord[id] or 1
		if GetSettings().showShortcutsInTooltip then
			GameTooltip:AddLine("|n|cff00ff00Click:|r Try on the appearance.")
		end
		GameTooltip:Show()
		SetOverrideBindingClick(tabDummy, true, "TAB", tabDummy:GetName(), "RightButton")
		enteredButton = self
	end

	list.onLeave = function(self, ...)
		ClearOverrideBindings(tabDummy)
		GameTooltip:ClearLines()
		GameTooltip:Hide()
		enteredButton = nil
	end

	tabDummy:SetScript("OnClick", function(self)
		if enteredButton ~= nil then
			local recordIndex = enteredButton:GetParent().itemIndex
			local ids = records[recordIndex][1]
			if #ids > 1 then
				if selectedInRecord[ids[1]] == nil then
					selectedInRecord[ids[1]] = 2
				else
					selectedInRecord[ids[1]] = selectedInRecord[ids[1]] < #ids and selectedInRecord[ids[1]] + 1 or 1
				end
			end
			list.onEnter(enteredButton)
		end
	end)

	list.onItemClick = function(self, button)
		local recordIndex = self:GetParent().itemIndex
		local id = records[recordIndex]
		local selectedIndex = selectedInRecord[id] ~= nil and selectedInRecord[id] or 1
		local itemId = id
		if IsControlKeyDown() then
			ns.ShowWowheadURLDialog(itemId)
		else
			mainTransmogFrame.selectedSlot:SetItem(itemId)
		end
		list.onEnter(self)
	end
end

---------------- SBUCLASS FRAME ----------------

mainTransmogFrame.tabs.preview.subclassMenu = CreateFrame("Frame", "$parentSubclassMenu", mainTransmogFrame.tabs.preview, "UIDropDownMenuTemplate")

do
	local previewTab = mainTransmogFrame.tabs.preview
	local slots = mainTransmogFrame.slots
	local menu = mainTransmogFrame.tabs.preview.subclassMenu

	menu:SetPoint("TOPRIGHT", -120, 38)
	menu.initializers = {} -- init func per slot
	UIDropDownMenu_JustifyText(menu, "LEFT")

	local slotSelectedSubclass = {}

	for i, slot in ipairs(armorSlots) do slotSelectedSubclass[slot] = defaultArmorSubclass[classFileName] end
	for i, slot in ipairs(miscellaneousSlots) do slotSelectedSubclass[slot] = "Miscellaneous" end
	slotSelectedSubclass[backSlot] = slotSubclasses[backSlot][1] 
	slotSelectedSubclass[mainHandSlot] = slotSubclasses[mainHandSlot][1]
	slotSelectedSubclass[offHandSlot] = slotSubclasses[offHandSlot][1]
	slotSelectedSubclass[rangedSlot] = slotSubclasses[rangedSlot][1]

	local function menu_OnClick(self, slot, subclass)
		previewTab:Update(slot, subclass)
		slotSelectedSubclass[slot] = subclass
		UIDropDownMenu_SetText(mainTransmogFrame.tabs.preview.subclassMenu, subclass)
	end

	local initializer = {
		["slot"] = nil,

		["__call"] = function (self, frame)
			local info = UIDropDownMenu_CreateInfo()
			local slot = self.slot
			for i, subclass in ipairs(slotSubclasses[slot]) do
				info.text = subclass
				info.checked = subclass == UIDropDownMenu_GetText(frame)
				info.arg1 = slot
				info.arg2 = subclass
				info.func = menu_OnClick
				UIDropDownMenu_AddButton(info)
			end
		end,
	}
	setmetatable(initializer, initializer)

	menu.Update = function(self, slot)
		if #slotSubclasses[slot] > 1 then
			UIDropDownMenu_EnableDropDown(self)
		else
			UIDropDownMenu_DisableDropDown(self)
		end
		UIDropDownMenu_SetText(self, slotSelectedSubclass[slot])
		initializer.slot = slot
		previewTab:Update(slot, slotSelectedSubclass[slot])
		UIDropDownMenu_Initialize(self, initializer)
	end
end

---------------- APPEARANCES ----------------

mainTransmogFrame.tabs.appearances.saved = CreateFrame("Frame", "$parentSaved", mainTransmogFrame.tabs.appearances)

---------------- CHARACTER MENU BUTTON ----------------

do  --------- Preview Setup
	local settingsTab = mainTransmogFrame.tabs.settings

	settingsTab.previewSetupMenu = CreateFrame("Frame", "$parentPreviewSetupDropDownMenu", settingsTab, "UIDropDownMenuTemplate")
	
	local menu = settingsTab.previewSetupMenu

	local function menu_OnClick(self, mode)
		GetSettings().previewSetup = mode
		UIDropDownMenu_SetText(menu, mode)
		previewSetupVersion = mode
		if mainTransmogFrame.selectedSlot ~= nil then
			mainTransmogFrame.selectedSlot:Click("LeftButton")
		end
	end

	UIDropDownMenu_Initialize(menu, function(frame)
		local previewSetup = GetSettings().previewSetup
		local info = UIDropDownMenu_CreateInfo()
		info.text, info.checked, info.arg1, info.func = "classic", previewSetup == "classic", "classic", menu_OnClick
		UIDropDownMenu_AddButton(info)
		info.text, info.checked, info.arg1, info.func = "modern", previewSetup == "modern", "modern", menu_OnClick
		UIDropDownMenu_AddButton(info)
	end)

	local label = menu:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	label:SetPoint("TOPLEFT", settingsTab, "TOPLEFT", 16, -24)
	label:SetText("Used models:")

	local tipFrame = CreateFrame("Frame", addon.."PreviewSetupDropDownMenuTip", settingsTab)
	tipFrame:SetPoint("LEFT", label, "LEFT")
	tipFrame:SetPoint("RIGHT", menu:GetChildren(), "LEFT")
	tipFrame:SetHeight(menu:GetChildren():GetHeight())
	tipFrame:EnableMouse(true)
	tipFrame:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT")
		GameTooltip:ClearLines()
		GameTooltip:AddLine("Used models")
		GameTooltip:AddLine("There's a funmade modification for WotLK client that brings modern high quality character models from \"Warlords of Draenor\" expansion. Unfortunately, preview for the modern models has different setup. If your game client's using the modern models, choose \"modern\" in this popup menu and \"classic\" otherwise.", 1, 1, 1, 1, true)
		GameTooltip:Show()
	end)
	tipFrame:SetScript("OnLeave", function()
		GameTooltip:Hide()
	end)
	
	menu:SetPoint("TOPLEFT", label:GetWidth() + 10, -16)

	settingsTab.SetPreviewSetup = function(self, mode)
		menu_OnClick(nil, mode)
	end
end


do  --------- Character background
	local settingsTab = mainTransmogFrame.tabs.settings
	local textures = mainTransmogFrame.dressingRoom.backgroundTextures

	local colorButtonBackground = CreateFrame("Frame", "$parentBorderDressingRoomBackgroundColorPicker", settingsTab)
	colorButtonBackground:SetSize(24, 24)
	colorButtonBackground:SetBackdrop({bgFile = "Interface\\ChatFrame\\ChatFrameBackground"})
	colorButtonBackground:SetBackdropColor(0.15, 0.15, 0.15, 1)

	local colorButton = CreateFrame("Button", "$parentButton", colorButtonBackground)
	colorButton:SetPoint("TOPLEFT", 2, -2)
	colorButton:SetPoint("BOTTOMRIGHT", -2, 2)
	colorButton:RegisterForClicks("LeftButtonDown")
	
	colorButton:SetBackdrop({bgFile = "Interface\\ChatFrame\\ChatFrameBackground"})
	colorButton:SetBackdropColor(unpack(defaultSettings.dressingRoomBackgroundColor))

	local label = colorButtonBackground:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	label:SetPoint("TOPLEFT", settingsTab, "TOPLEFT", 16, -80)
	label:SetText("Character background:")

	colorButtonBackground:SetPoint("TOPRIGHT", label, "BOTTOMRIGHT", 0, -4)

	local function colorPicker_OnAccept()
		local r, g, b = ColorPickerFrame:GetColorRGB() 
		textures.color:SetTexture(r, g, b)
		colorButton:SetBackdropColor(r, g, b)
		GetSettings().dressingRoomBackgroundColor = {r, g, b}
	end

	local function colorPicker_OnCancel(previousValues)
		local settings = GetSettings()
		textures.color:SetTexture(unpack(previousValues))
		colorButton:SetBackdropColor(unpack(previousValues))
		GetSettings().dressingRoomBackgroundColor = {unpack(previousValues)}
	end

	colorButton:SetScript("OnClick", function(self)
		local r, g, b = unpack(GetSettings().dressingRoomBackgroundColor)
		ColorPickerFrame.previousValues = {r, g, b}
		ColorPickerFrame:SetColorRGB(r, g, b)
		ColorPickerFrame.func = colorPicker_OnAccept
		ColorPickerFrame.cancelFunc = colorPicker_OnCancel
		ColorPickerFrame:Hide()
		ColorPickerFrame:Show()
	end)

	local btnReset = CreateFrame("Button", "$parentResetButton", colorButtonBackground, "UIPanelButtonTemplate2")
	btnReset:SetPoint("TOPLEFT", label, "BOTTOMLEFT", 0, -6)
	btnReset:SetText("Reset Color")
	btnReset:SetWidth(100)
	btnReset:SetScript("OnClick", function(self)
		local r, g, b = unpack(defaultSettings.dressingRoomBackgroundColor)
		GetSettings().dressingRoomBackgroundColor = {r, g, b}
		textures.color:SetTexture(r, g, b)
		colorButton:SetBackdropColor(r, g, b)
		PlaySound("gsTitleOptionOK")
	end)

	settingsTab.backgroundMenu = CreateFrame("Frame", "$parentDropDownMenu", colorButtonBackground, "UIDropDownMenuTemplate")
	
	local menu = settingsTab.backgroundMenu
	local function getText(background)
		return  (background == "deathknight" and "Death Knight")
				or (background == "nightelf" and "Night Elf")
				or (background == "bloodelf" and "Blood Elf")
				or (background == "scourge" and "Forsaken")
				or background:gsub("^%l", string.upper)
	end

	local function menu_OnClick(self, background)
		GetSettings().dressingRoomBackgroundTexture[GetRealmName()][GetUnitName("player")] = background
		for _, tex in pairs(textures) do
			tex:Hide()
		end
		textures[background]:Show()
		UIDropDownMenu_SetText(menu, getText(background))
	end

	UIDropDownMenu_Initialize(menu, function()
		local currBackground = GetSettings().dressingRoomBackgroundTexture[GetRealmName()][GetUnitName("player")]:lower()
		local info = UIDropDownMenu_CreateInfo()
		for background in ("color,human,dwarf,nightelf,gnome,draenei,orc,scourge,tauren,troll,bloodelf,deathknight"):gmatch("%w+") do
			info.text = getText(background)
			info.checked = currBackground == background
			info.arg1 = background
			info.func = menu_OnClick
			UIDropDownMenu_AddButton(info)
		end
	end)

	settingsTab.SetCharacterBackground = function(self, background, r, g, b)
		menu_OnClick(nil, background:lower())
		colorButton:SetBackdropColor(r, g, b)
		textures.color:SetTexture(r, g, b)
	end
	
	menu:SetPoint("LEFT", label, "RIGHT")
	UIDropDownMenu_SetWidth(menu, 100)
end


do  --------- Show/hide "DressMe" button
	local settingsTab = mainTransmogFrame.tabs.settings
	settingsTab.showTransmogButtonCheckBox = CreateFrame("CheckButton", "$parentshowTransmogButtonCheckBox", settingsTab, "ChatConfigCheckButtonTemplate")

	local checkbox = settingsTab.showTransmogButtonCheckBox
	checkbox:SetPoint("TOPLEFT", settingsTab, "TOPLEFT", 15, -150)
	checkbox:SetScript("OnClick", function(self)
		
	end)
	checkbox:HookScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT")
		GameTooltip:ClearLines()
		GameTooltip:AddLine("Show \"Transmog\" button")
		GameTooltip:AddLine("Show or hide \"Transmog\" button in the character window.", 1, 1, 1, 1, true)
		GameTooltip:AddLine("The addon can be still accessed via \"/transmog\" chat command.", 1, 1, 1, 1, true)
		GameTooltip:Show()
	end)
	checkbox:HookScript("OnLeave", function(self)
		GameTooltip:Hide()
	end)
	local label = checkbox:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	label:SetText("Show \"Transmog\" button")
	label:SetPoint("LEFT", checkbox, "RIGHT", 4, 2)
end


do  --------- Show shortcuts in tooltips
	local settingsTab = mainTransmogFrame.tabs.settings
	settingsTab.showShortcutsInTooltipCheckBox = CreateFrame("CheckButton", "$parentShowShortcutsInTooltipCheckBox", settingsTab, "ChatConfigCheckButtonTemplate")
	
	local checkbox = settingsTab.showShortcutsInTooltipCheckBox
	checkbox:SetPoint("TOP", settingsTab.showTransmogButtonCheckBox, "BOTTOM", 0, -10)
	checkbox:SetScript("OnClick", function(self)
		GetSettings().showShortcutsInTooltip = self:GetChecked() ~= nil
	end)
	local label = checkbox:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	label:SetText("Show shortcuts in tooltip")
	label:SetPoint("LEFT", checkbox, "RIGHT", 4, 2)
end


do  --------- Hide hair on cloak preview
	local settingsTab = mainTransmogFrame.tabs.settings
	settingsTab.hideHairOnCloakPreviewCheckBox = CreateFrame("CheckButton", "$parentHideHairOnCloakPreviewCheckBox", settingsTab, "ChatConfigCheckButtonTemplate")

	local checkbox = settingsTab.hideHairOnCloakPreviewCheckBox
	checkbox:SetPoint("LEFT", settingsTab.showTransmogButtonCheckBox, "RIGHT", 250, 0)
	checkbox:SetScript("OnClick", function(self)
		GetSettings().hideHairOnCloakPreview = self:GetChecked() ~= nil
	end)
	local label = checkbox:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	label:SetText("Hide hair on cloak preview")
	label:SetPoint("LEFT", checkbox, "RIGHT", 4, 2)
end


do  --------- Hide hair and beard on chest preview
	local settingsTab = mainTransmogFrame.tabs.settings
	settingsTab.hideHairBeardOnChestPreviewCheckBox = CreateFrame("CheckButton", "$parentHideHairBeardOnChestPreviewCheckBox", settingsTab, "ChatConfigCheckButtonTemplate")
	
	local checkbox = settingsTab.hideHairBeardOnChestPreviewCheckBox
	checkbox:SetPoint("TOP", settingsTab.hideHairOnCloakPreviewCheckBox, "BOTTOM", 0, -10)
	checkbox:SetScript("OnClick", function(self)
		GetSettings().hideHairBeardOnChestPreview = self:GetChecked() ~= nil
	end)
	local label = checkbox:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	label:SetText("Hide hair and beard on chest,\nshirt, and tabard previews")
	label:SetJustifyH("LEFT")
	label:SetPoint("LEFT", checkbox, "RIGHT", 4, 2)
end


do  --------- Use server time in received appearances
	local settingsTab = mainTransmogFrame.tabs.settings
	settingsTab.useServerTimeInReceivedAppearancesCheckBox = CreateFrame("CheckButton", "$parentUseServerTimeInReceivedAppearancesCheckBox", settingsTab, "ChatConfigCheckButtonTemplate")
	
	local checkbox = settingsTab.useServerTimeInReceivedAppearancesCheckBox
	checkbox:SetPoint("TOP", settingsTab.showShortcutsInTooltipCheckBox, "BOTTOM", 0, -30)
	checkbox:SetScript("OnClick", function(self)
		GetSettings().useServerTimeInReceivedAppearances = self:GetChecked() ~= nil
	end)
	local label = checkbox:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	label:SetText("Use Server Time in \"Received\nAppearences\" list")
	label:SetJustifyH("LEFT")
	label:SetPoint("LEFT", checkbox, "RIGHT", 4, 2)
end


do  --------- Announce appearance receiving
	local settingsTab = mainTransmogFrame.tabs.settings
	settingsTab.announceAppearanceReceivingCheckBox = CreateFrame("CheckButton", "$parentAnnounceAppearanceReceivingCheckBox", settingsTab, "ChatConfigCheckButtonTemplate")
	
	local checkbox = settingsTab.announceAppearanceReceivingCheckBox
	checkbox:SetPoint("TOP", settingsTab.useServerTimeInReceivedAppearancesCheckBox, "BOTTOM", 0, -10)
	checkbox:SetScript("OnClick", function(self)
		GetSettings().announceAppearanceReceiving = self:GetChecked() ~= nil
	end)
	local label = checkbox:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	label:SetText("Announce in the chat if an appearance\nhas been received from another player")
	label:SetJustifyH("LEFT")
	label:SetPoint("LEFT", checkbox, "RIGHT", 4, 2)
end


do  --------- Ignore UI sclaing
	local settingsTab = mainTransmogFrame.tabs.settings
	settingsTab.ignoreUIScalingCheckBox = CreateFrame("CheckButton", "$parentIgnoreUIScalingCheckBox", settingsTab, "ChatConfigCheckButtonTemplate")
	
	local checkbox = settingsTab.ignoreUIScalingCheckBox
	checkbox:SetPoint("TOP", settingsTab.announceAppearanceReceivingCheckBox, "BOTTOM", 0, -30)
	checkbox:SetScript("OnClick", function(self)
		GetSettings().ignoreUIScaling = self:GetChecked() ~= nil
		if self:GetChecked() then
			mainTransmogFrame:SetParent(nil)
			mainTransmogFrame:SetScale(0.9)
		else
			mainTransmogFrame:SetParent(UIParent)
			mainTransmogFrame:SetScale(1)
		end
		if mainTransmogFrame:IsVisible() then
			-- only to update the main dressing room
			mainTransmogFrame:Hide()
			mainTransmogFrame:Show()
		end
	end)
	local origingSetChecked = checkbox.SetChecked
	checkbox.SetChecked = function(self, enable)
		origingSetChecked(self, enable)
		checkbox:GetScript("OnClick")(self)
	end
	checkbox:HookScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT")
		GameTooltip:ClearLines()
		GameTooltip:AddLine("Ignore UI scaling")
		GameTooltip:AddLine("The game's 3D rendering can break correct displaying of previews with too small values of UI scaling in video settings. Set this checkbox to ignore UI scaling.", 1, 1, 1, 1, true)
		GameTooltip:Show()
	end)
	checkbox:HookScript("OnLeave", function(self)
		GameTooltip:Hide()
	end)
	local label = checkbox:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	label:SetText("Ignore UI scaling")
	label:SetPoint("LEFT", checkbox, "RIGHT", 4, 2)
end



do  --------- Apply settings on addon loaded
	local settingsTab = mainTransmogFrame.tabs.settings

	local function applySettings(settings)
		-- Dressing room background color
		settingsTab:SetCharacterBackground(settings.dressingRoomBackgroundTexture[GetRealmName()][GetUnitName("player")], unpack(settings.dressingRoomBackgroundColor))
		-- Preview setup popup menu
		settingsTab:SetPreviewSetup(settings.previewSetup)
		-- Show/hide "DressMe" button
		settingsTab.showTransmogButtonCheckBox:SetChecked(settings.showTransmogButton)
		if settings.showTransmogButton then
		end
		-- Show shortcuts in tooltip
		settingsTab.showShortcutsInTooltipCheckBox:SetChecked(settings.showShortcutsInTooltip)
		-- Hide hair on cloak preview
		settingsTab.hideHairOnCloakPreviewCheckBox:SetChecked(settings.hideHairOnCloakPreview)
		-- Hide hair and beard on chest preview
		settingsTab.hideHairBeardOnChestPreviewCheckBox:SetChecked(settings.hideHairBeardOnChestPreview)
		-- Use server time in Received Appearences list
		settingsTab.useServerTimeInReceivedAppearancesCheckBox:SetChecked(settings.useServerTimeInReceivedAppearances)
		-- Announce appearance receiving
		settingsTab.announceAppearanceReceivingCheckBox:SetChecked(settings.announceAppearanceReceiving)
		-- Ignore UI scaling
		settingsTab.ignoreUIScalingCheckBox:SetChecked(settings.ignoreUIScaling)
	end

	settingsTab:RegisterEvent("ADDON_LOADED")
	settingsTab:SetScript("OnEvent", function(self, event, addonName)
		if addonName == addon then
			if event == "ADDON_LOADED" then
				applySettings(GetSettings())
			end
		end
	end)
end

function Transmog_DisplayCollectedAppearance(itemId)
	if (GetItemInfo(itemId)) then
		DEFAULT_CHAT_FRAME:AddMessage("[" .. GetItemInfo(itemId) .. "] has been added to your appearance collection.", 1.0, 1.0, 0, 5);
	else
		-- Some cases where the actual item name cannot be known because it hasn't been queried yet
		DEFAULT_CHAT_FRAME:AddMessage("A new appearance has been added to your appearance collection.", 1.0, 1.0, 0, 5);
	end
end

---------------- CHAT COMMANDS ----------------

SLASH_TRANSMOG1 = "/transmog"

SlashCmdList["TRANSMOG"] = function(msg)
	if msg == "" then
		if mainTransmogFrame:IsShown() then mainTransmogFrame:Hide() else mainTransmogFrame:Show() end
	elseif msg == "debug" then
		if mainTransmogFrame.dressingRoom:IsDebugInfoShown() then mainTransmogFrame.dressingRoom:HideDebugInfo() else mainTransmogFrame.dressingRoom:ShowDebugInfo() end
	end
end