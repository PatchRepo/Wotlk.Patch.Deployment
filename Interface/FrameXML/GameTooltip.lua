-- The default tooltip border color
--TOOLTIP_DEFAULT_COLOR = { r = 0.5, g = 0.5, b = 0.5 };
TOOLTIP_DEFAULT_COLOR = { r = 1, g = 1, b = 1 };
TOOLTIP_DEFAULT_BACKGROUND_COLOR = { r = 0.09, g = 0.09, b = 0.19 };
DEFAULT_TOOLTIP_POSITION = -13;

function GameTooltip_UnitColor(unit)
	local r, g, b;
	if ( UnitPlayerControlled(unit) ) then
		if ( UnitCanAttack(unit, "player") ) then
			-- Hostile players are red
			if ( not UnitCanAttack("player", unit) ) then
				--[[
				r = 1.0;
				g = 0.5;
				b = 0.5;
				]]
				--[[
				r = 0.0;
				g = 0.0;
				b = 1.0;
				]]
				r = 1.0;
				g = 1.0;
				b = 1.0;
			else
				r = FACTION_BAR_COLORS[2].r;
				g = FACTION_BAR_COLORS[2].g;
				b = FACTION_BAR_COLORS[2].b;
			end
		elseif ( UnitCanAttack("player", unit) ) then
			-- Players we can attack but which are not hostile are yellow
			r = FACTION_BAR_COLORS[4].r;
			g = FACTION_BAR_COLORS[4].g;
			b = FACTION_BAR_COLORS[4].b;
		elseif ( UnitIsPVP(unit) ) then
			-- Players we can assist but are PvP flagged are green
			r = FACTION_BAR_COLORS[6].r;
			g = FACTION_BAR_COLORS[6].g;
			b = FACTION_BAR_COLORS[6].b;
		else
			-- All other players are blue (the usual state on the "blue" server)
			--[[
			r = 0.0;
			g = 0.0;
			b = 1.0;
			]]
			r = 1.0;
			g = 1.0;
			b = 1.0;
		end
	else
		local reaction = UnitReaction(unit, "player");
		if ( reaction ) then
			r = FACTION_BAR_COLORS[reaction].r;
			g = FACTION_BAR_COLORS[reaction].g;
			b = FACTION_BAR_COLORS[reaction].b;
		else
			--[[
			r = 0.0;
			g = 0.0;
			b = 1.0;
			]]
			r = 1.0;
			g = 1.0;
			b = 1.0;
		end
	end
	return r, g, b;
end

function GameTooltip_SetDefaultAnchor(tooltip, parent)		
	tooltip:SetOwner(parent, "ANCHOR_NONE");
	tooltip:SetPoint("BOTTOMRIGHT", "UIParent", "BOTTOMRIGHT", -CONTAINER_OFFSET_X - 13, CONTAINER_OFFSET_Y);
	tooltip.default = 1;
end

function ScaleEquipTooltipLine(stats, tooltip, name, localizedModName, statsIndex, scaleFactor, nonEquip, flatScaleAmount)
	if (flatScaleAmount == nil) then
		flatScaleAmount = 0;
	end

	if (stats[statsIndex]) then
		local statString = string.format(localizedModName, stats[statsIndex]);
		for i = 2, tooltip:NumLines() do
			if (nonEquip) then
				if (_G[name .. i]:GetText() == (statString)) then
					_G[name .. i]:SetText(string.format(localizedModName, math.ceil(stats[statsIndex] * scaleFactor + flatScaleAmount)));
				end
			else
				if (_G[name .. i]:GetText() == (ITEM_SPELL_TRIGGER_ONEQUIP .. " " .. statString)) then
					_G[name .. i]:SetText(ITEM_SPELL_TRIGGER_ONEQUIP .. " " .. string.format(localizedModName, math.ceil(stats[statsIndex] * scaleFactor + flatScaleAmount)));
				end
			end
		end
	end
end

function GameTooltip_OnSetItem(self)
	-- Recommended by: https://authors.curseforge.com/forums/world-of-warcraft/general-chat/need-help/216579-working-with-gametooltips-tooltip-scanning
	local name = self:GetName() .. "TextLeft";
	local item, link = self:GetItem();

	-- @HelloKitty: Transmog embed appearance warning if not collectd
	if (item and link and IsVisualAppearanceForItemKnown) then
		local id = string.match(link, "Hitem:([0-9]+)")
		if (IsVisualAppearanceForItemKnown(id) == false) then
			self:AddLine("You haven't collected this appearance", 170 / 255, 171 / 255, 254 / 255);
		end
	end

	for i = 2, self:NumLines() do
		if ((_G[name .. i]:GetText()) == string.format(ITEM_CREATED_BY, "Server")) then
			-- Realm First item text feature
			_G[name .. i]:SetText("\"The very first of its kind. When claimed, no other\n had yet to exist within the realm of Azeroth.\"");
			_G[name .. i]:SetTextColor(255 / 255, 209 / 255, 0 / 255);
		end
	end
	
	if (HasItemScalingDataInLink(link)) then
		ClearScalingTooltipTrackingCache();

		local scaleDataValue = GetItemScalingDataFromLink(link);
		local scaledType = GetScaledItemTypeFromItemLink(link);

		-- Can't always trust regex link, sometimes https://wotlkdb.com/?item=10410
		-- Fang will have stuff in the link?? No idea why
		if (scaleDataValue == 0 and scaledType == 0) then
			return;
		end
		
		-- We must know what stats the item has so we can iterate and search the tooltip for the line and replace it
		local stats = GetItemStats(link);
		local itemName, itemLink, itemRarity, itemLevel = GetItemInfo(link);
		local scaleDataValue = GetItemScalingDataFromLink(link);
		local itemId = GetItemIdFromItemLink(link);
		
		local foundHeroicLine = false;
		for i = 2, self:NumLines() do
			if (_G[name .. i]) then
				if (_G[name .. i]:GetText() == (string.format(ITEM_LEVEL, itemLevel)) and _G[name .. i]:GetStringWidth() ~= 0) then -- @HelloKitty: Unsure why but sometimes 0 pixel wide strings exist and thus throw no font error due to addons
					_G[name .. i]:SetText(string.format(ITEM_LEVEL, itemLevel + scaleDataValue)); 	
				else
					if (_G[name .. i]:GetText() == ITEM_HEROIC and scaledType > 0) then
						-- We embed this check in here for 1 loop perf we
						-- at try to set the "MODE". The best case is that we actually have a HEROIC tag already and we can replace it
						foundHeroicLine = true;
						local scaledLine = GetScaledItemTypeText(scaledType, link);
						_G[name .. i]:SetText(scaledLine);
					else
						-- TODO: This isn't locale independent checking for set ITEM_SET_BONUS
						-- We have some issues with certain stats that are spells that the WoW client won't consider in GetItemStats
						-- Therefore the complex scaling of tooltips is handled in native code
						if (not string.find(_G[name .. i]:GetText(), "Set: ") and _G[name .. i]:GetStringWidth() ~= 0) then -- @HelloKitty: Must check for empty lines due to addons
							-- Sometimes set bonuses will have stats in them, skip
							local newLine, scaled = ItemScaleTooltipLine(_G[name .. i]:GetText(), scaleDataValue, itemLevel, itemId);
							if (scaled) then
								_G[name .. i]:SetText(newLine);
							end
						end
					end
				end
			end
		end
		
		if (foundHeroicLine or scaledType == 0) then
			return;
		end
		
		-- Worse case we have to sorta share a line by borrowing it and appending in a funky way.
		for i = 1, self:NumLines() do
			if (_G[name .. i] and _G[name .. i]:GetText() == itemName) then
				local origText = _G[name .. i + 1]:GetText();
				if (origText) then
					local r, g, b = _G[name .. i + 1]:GetTextColor();
					-- Sometimes the line is a specific color and if we use embeded colors then the original text color won't work, we must embed a color for the original text too
					local hr = string.format("%.2x", r * 255);
					local hg = string.format("%.2x", g * 255);
					local hb = string.format("%.2x", b * 255);
					local scaledLine = GetScaledItemTypeText(scaledType, link);
					_G[name .. i + 1]:SetText("|cff00FF00" .. scaledLine .. "|cffFFFFFF" .. "\r" .. "|cFF" .. hr .. hg .. hb .. origText .. "|cffFFFFFF", r, g, b, true);
					_G[name .. i + 1]:GetFontObject():SetJustifyH("LEFT"); -- Without this compare tooltips center justify the two hacked lines above
				end
				return;
			end
		end
	end
end

function RegisterNewPrimaryStatTooltipScalingEntry(statString)
	RegisterNewTooltipScalingEntry("+" .. "%d" .. " " .. statString, 0, true);
end

function GameTooltip_OnLoad(self)
	self.updateTooltip = TOOLTIP_UPDATE_TIME;
	self:SetBackdropBorderColor(TOOLTIP_DEFAULT_COLOR.r, TOOLTIP_DEFAULT_COLOR.g, TOOLTIP_DEFAULT_COLOR.b);
	self:SetBackdropColor(TOOLTIP_DEFAULT_BACKGROUND_COLOR.r, TOOLTIP_DEFAULT_BACKGROUND_COLOR.g, TOOLTIP_DEFAULT_BACKGROUND_COLOR.b);
	self.statusBar2 = _G[self:GetName().."StatusBar2"];
	self.statusBar2Text = _G[self:GetName().."StatusBar2Text"];
	
	if (self:HasScript('OnTooltipSetItem')) then
		self:HookScript('OnTooltipSetItem', GameTooltip_OnSetItem);
	end
	
	if (IsTooltipScalingEntryRegistrationComplete()) then
		return;
	end
	
	-- One time setup for scaling data
	-- Second arg is scaling type
	RegisterNewTooltipScalingEntry(ITEM_SPELL_TRIGGER_ONEQUIP .. " " .. ITEM_MOD_BLOCK_VALUE, 0);
	RegisterNewTooltipScalingEntry(ITEM_SPELL_TRIGGER_ONEQUIP .. " " .. ITEM_MOD_SPELL_POWER, 1);
	RegisterNewTooltipScalingEntry(ITEM_SPELL_TRIGGER_ONEQUIP .. " " .. ITEM_MOD_SPELL_PENETRATION, 0);
	RegisterNewTooltipScalingEntry(ITEM_SPELL_TRIGGER_ONEQUIP .. " " .. ITEM_MOD_RANGED_ATTACK_POWER, 1);
	RegisterNewTooltipScalingEntry(ITEM_SPELL_TRIGGER_ONEQUIP .. " " .. ITEM_MOD_ARMOR_PENETRATION_RATING:gsub(strlower(UNIT_YOU_DEST_POSSESSIVE) .. " ", ""), 0);
	RegisterNewTooltipScalingEntry(ITEM_SPELL_TRIGGER_ONEQUIP .. " " .. ITEM_MOD_BLOCK_RATING, 0);
	RegisterNewTooltipScalingEntry(ITEM_SPELL_TRIGGER_ONEQUIP .. " " .. ITEM_MOD_CRIT_RATING, 0);
	RegisterNewTooltipScalingEntry(ITEM_SPELL_TRIGGER_ONEQUIP .. " " .. ITEM_MOD_DEFENSE_SKILL_RATING, 0);
	RegisterNewTooltipScalingEntry(ITEM_SPELL_TRIGGER_ONEQUIP .. " " .. ITEM_MOD_EXPERTISE_RATING, 0);
	RegisterNewTooltipScalingEntry(ITEM_SPELL_TRIGGER_ONEQUIP .. " " .. ITEM_MOD_HASTE_RATING, 0);
	RegisterNewTooltipScalingEntry(ITEM_SPELL_TRIGGER_ONEQUIP .. " " .. ITEM_MOD_HIT_RATING, 0);
	RegisterNewTooltipScalingEntry(ITEM_SPELL_TRIGGER_ONEQUIP .. " " .. ITEM_MOD_MANA_REGENERATION, 0, true);
	RegisterNewTooltipScalingEntry(ITEM_SPELL_TRIGGER_ONEQUIP .. " " .. ITEM_MOD_DODGE_RATING, 0);
	RegisterNewTooltipScalingEntry(ITEM_SPELL_TRIGGER_ONEQUIP .. " " .. ITEM_MOD_PARRY_RATING, 0);
	RegisterNewTooltipScalingEntry(ITEM_SPELL_TRIGGER_ONEQUIP .. " " .. ITEM_MOD_ATTACK_POWER, 0);
	RegisterNewTooltipScalingEntry(DPS_TEMPLATE, 3, true);
	RegisterNewTooltipScalingEntry(DAMAGE_TEMPLATE, 3, true);
	
	-- Primary stats because GetItemStats is SO unreliable
	RegisterNewPrimaryStatTooltipScalingEntry(ITEM_MOD_INTELLECT_SHORT);
	RegisterNewPrimaryStatTooltipScalingEntry(ITEM_MOD_STAMINA_SHORT);
	RegisterNewPrimaryStatTooltipScalingEntry(ITEM_MOD_AGILITY_SHORT);
	RegisterNewPrimaryStatTooltipScalingEntry(ITEM_MOD_STRENGTH_SHORT);
	RegisterNewPrimaryStatTooltipScalingEntry(ITEM_MOD_SPIRIT_SHORT);
	
	-- Armor and def stuff
	RegisterNewTooltipScalingEntry(ARMOR_TEMPLATE, 2);
	RegisterNewTooltipScalingEntry(SHIELD_BLOCK_TEMPLATE, 2, true);
	RegisterNewTooltipScalingEntry(ITEM_MOD_RESILIENCE_RATING, 1);
	
	SetTooltipScalingEntryRegistrationComplete();
end

function GameTooltip_OnTooltipAddMoney(self, cost, maxcost)
	if( not maxcost ) then --We just have 1 price to display
		SetTooltipMoney(self, cost, nil, string.format("%s:", SELL_PRICE));
	else
		self:AddLine(string.format("%s:", SELL_PRICE), 1.0, 1.0, 1.0);
		local indent = string.rep(" ",4)
		SetTooltipMoney(self, cost, nil, string.format("%s%s:", indent, MINIMUM));
		SetTooltipMoney(self, maxcost, nil, string.format("%s%s:", indent, MAXIMUM));
	end
end

function SetTooltipMoney(frame, money, type, prefixText, suffixText)
	frame:AddLine(" ", 1.0, 1.0, 1.0);
	local numLines = frame:NumLines();
	if ( not frame.numMoneyFrames ) then
		frame.numMoneyFrames = 0;
	end
	if ( not frame.shownMoneyFrames ) then
		frame.shownMoneyFrames = 0;
	end
	local name = frame:GetName().."MoneyFrame"..frame.shownMoneyFrames+1;
	local moneyFrame = _G[name];
	if ( not moneyFrame ) then
		frame.numMoneyFrames = frame.numMoneyFrames+1;
		moneyFrame = CreateFrame("Frame", name, frame, "TooltipMoneyFrameTemplate");
		name = moneyFrame:GetName();
		MoneyFrame_SetType(moneyFrame, "STATIC");
	end
	_G[name.."PrefixText"]:SetText(prefixText);
	_G[name.."SuffixText"]:SetText(suffixText);
	if ( type ) then
		MoneyFrame_SetType(moneyFrame, type);
	end
	--We still have this variable offset because many AddOns use this function. The money by itself will be unaligned if we do not use this.
	local xOffset;
	if ( prefixText ) then
		xOffset = 4;
	else
		xOffset = 0;
	end
	moneyFrame:SetPoint("LEFT", frame:GetName().."TextLeft"..numLines, "LEFT", xOffset, 0);
	moneyFrame:Show();
	if ( not frame.shownMoneyFrames ) then
		frame.shownMoneyFrames = 1;
	else
		frame.shownMoneyFrames = frame.shownMoneyFrames+1;
	end
	MoneyFrame_Update(moneyFrame:GetName(), money);
	local moneyFrameWidth = moneyFrame:GetWidth();
	if ( frame:GetMinimumWidth() < moneyFrameWidth ) then
		frame:SetMinimumWidth(moneyFrameWidth);
	end
	frame.hasMoney = 1;
end

function GameTooltip_ClearMoney(self)
	if ( not self.shownMoneyFrames ) then
		return;
	end
	
	local moneyFrame;
	for i=1, self.shownMoneyFrames do
		moneyFrame = _G[self:GetName().."MoneyFrame"..i];
		if(moneyFrame) then
			moneyFrame:Hide();
			MoneyFrame_SetType(moneyFrame, "STATIC");
		end
	end
	self.shownMoneyFrames = nil;
end

function GameTooltip_ClearStatusBars(self)
	if ( not self.shownStatusBars ) then
		return;
	end
	local statusBar;
	for i=1, self.shownStatusBars do
		statusBar = _G[self:GetName().."StatusBar"..i];
		if ( statusBar ) then
			statusBar:Hide();
		end
	end
	self.shownStatusBars = 0;
end

function GameTooltip_OnHide(self)
	self:SetBackdropBorderColor(TOOLTIP_DEFAULT_COLOR.r, TOOLTIP_DEFAULT_COLOR.g, TOOLTIP_DEFAULT_COLOR.b);
	self:SetBackdropColor(TOOLTIP_DEFAULT_BACKGROUND_COLOR.r, TOOLTIP_DEFAULT_BACKGROUND_COLOR.g, TOOLTIP_DEFAULT_BACKGROUND_COLOR.b);
	self.default = nil;
	GameTooltip_ClearMoney(self);
	GameTooltip_ClearStatusBars(self);
	if ( self.shoppingTooltips ) then
		for _, frame in pairs(self.shoppingTooltips) do
			frame:Hide();
		end
	end
	self.comparing = false;
end

function GameTooltip_OnUpdate(self, elapsed)
	-- Only update every TOOLTIP_UPDATE_TIME seconds
	self.updateTooltip = self.updateTooltip - elapsed;
	if ( self.updateTooltip > 0 ) then
		return;
	end
	self.updateTooltip = TOOLTIP_UPDATE_TIME;

	local owner = self:GetOwner();
	if ( owner and owner.UpdateTooltip ) then
		owner:UpdateTooltip();
	end
end

function GameTooltip_AddNewbieTip(frame, normalText, r, g, b, newbieText, noNormalText)
	if ( SHOW_NEWBIE_TIPS == "1" ) then
		GameTooltip_SetDefaultAnchor(GameTooltip, frame);
		if ( normalText ) then
			GameTooltip:SetText(normalText, r, g, b);
			GameTooltip:AddLine(newbieText, NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, 1);
		else
			GameTooltip:SetText(newbieText, r, g, b, 1, 1);
		end
		GameTooltip:Show();
	else
		if ( not noNormalText ) then
			GameTooltip:SetOwner(frame, "ANCHOR_RIGHT");
			GameTooltip:SetText(normalText, r, g, b);
		end
	end
end

function GameTooltip_ShowCompareItem(self, shift)
	if ( not self ) then
		self = GameTooltip;
	end
	local item, link = self:GetItem();
	if ( not link ) then
		return;
	end
	
	local shoppingTooltip1, shoppingTooltip2, shoppingTooltip3 = unpack(self.shoppingTooltips);

	local item1 = nil;
	local item2 = nil;
	local item3 = nil;
	local side = "left";
	if ( shoppingTooltip1:SetHyperlinkCompareItem(link, 1, shift, self) ) then
		item1 = true;
	end
	if ( shoppingTooltip2:SetHyperlinkCompareItem(link, 2, shift, self) ) then
		item2 = true;
	end
	if ( shoppingTooltip3:SetHyperlinkCompareItem(link, 3, shift, self) ) then
		item3 = true;
	end

	-- find correct side
	local rightDist = 0;
	local leftPos = self:GetLeft();
	local rightPos = self:GetRight();
	if ( not rightPos ) then
		rightPos = 0;
	end
	if ( not leftPos ) then
		leftPos = 0;
	end

	rightDist = GetScreenWidth() - rightPos;

	if (leftPos and (rightDist < leftPos)) then
		side = "left";
	else
		side = "right";
	end

	-- see if we should slide the tooltip
	if ( self:GetAnchorType() and self:GetAnchorType() ~= "ANCHOR_PRESERVE" ) then
		local totalWidth = 0;
		if ( item1  ) then
			totalWidth = totalWidth + shoppingTooltip1:GetWidth();
		end
		if ( item2  ) then
			totalWidth = totalWidth + shoppingTooltip2:GetWidth();
		end
		if ( item3  ) then
			totalWidth = totalWidth + shoppingTooltip3:GetWidth();
		end

		if ( (side == "left") and (totalWidth > leftPos) ) then
			self:SetAnchorType(self:GetAnchorType(), (totalWidth - leftPos), 0);
		elseif ( (side == "right") and (rightPos + totalWidth) >  GetScreenWidth() ) then
			self:SetAnchorType(self:GetAnchorType(), -((rightPos + totalWidth) - GetScreenWidth()), 0);
		end
	end

	-- anchor the compare tooltips
	if ( item3 ) then
		shoppingTooltip3:SetOwner(self, "ANCHOR_NONE");
		shoppingTooltip3:ClearAllPoints();
		if ( side and side == "left" ) then
			shoppingTooltip3:SetPoint("TOPRIGHT", self, "TOPLEFT", 0, -10);
		else
			shoppingTooltip3:SetPoint("TOPLEFT", self, "TOPRIGHT", 0, -10);
		end
		shoppingTooltip3:SetHyperlinkCompareItem(link, 3, shift, self);
		shoppingTooltip3:Show();
	end
	
	if ( item1 ) then
		if( item3 ) then
			shoppingTooltip1:SetOwner(shoppingTooltip3, "ANCHOR_NONE");
		else
			shoppingTooltip1:SetOwner(self, "ANCHOR_NONE");
		end
		shoppingTooltip1:ClearAllPoints();
		if ( side and side == "left" ) then
			if( item3 ) then
				shoppingTooltip1:SetPoint("TOPRIGHT", shoppingTooltip3, "TOPLEFT", 0, 0);
			else
				shoppingTooltip1:SetPoint("TOPRIGHT", self, "TOPLEFT", 0, -10);
			end
		else
			if( item3 ) then
				shoppingTooltip1:SetPoint("TOPLEFT", shoppingTooltip3, "TOPRIGHT", 0, 0);
			else
				shoppingTooltip1:SetPoint("TOPLEFT", self, "TOPRIGHT", 0, -10);
			end
		end
		shoppingTooltip1:SetHyperlinkCompareItem(link, 1, shift, self);
		shoppingTooltip1:Show();

		if ( item2 ) then
			shoppingTooltip2:SetOwner(shoppingTooltip1, "ANCHOR_NONE");
			shoppingTooltip2:ClearAllPoints();
			if ( side and side == "left" ) then
				shoppingTooltip2:SetPoint("TOPRIGHT", shoppingTooltip1, "TOPLEFT", 0, 0);
			else
				shoppingTooltip2:SetPoint("TOPLEFT", shoppingTooltip1, "TOPRIGHT", 0, 0);
			end
			shoppingTooltip2:SetHyperlinkCompareItem(link, 2, shift, self);
			shoppingTooltip2:Show();
		end
	end
end

function GameTooltip_ShowStatusBar(self, min, max, value, text)
	self:AddLine(" ", 1.0, 1.0, 1.0);
	local numLines = self:NumLines();
	if ( not self.numStatusBars ) then
		self.numStatusBars = 0;
	end
	if ( not self.shownStatusBars ) then
		self.shownStatusBars = 0;
	end
	local index = self.shownStatusBars+1;
	local name = self:GetName().."StatusBar"..index;
	local statusBar = _G[name];
	if ( not statusBar ) then
		self.numStatusBars = self.numStatusBars+1;
		statusBar = CreateFrame("StatusBar", name, self, "TooltipStatusBarTemplate");
	end
	if ( not text ) then
		text = "";
	end
	_G[name.."Text"]:SetText(text);
	statusBar:SetMinMaxValues(min, max);
	statusBar:SetValue(value);
	statusBar:Show();
	statusBar:SetPoint("LEFT", self:GetName().."TextLeft"..numLines, "LEFT", 0, -2);
	statusBar:SetPoint("RIGHT", self, "RIGHT", -9, 0);
	statusBar:Show();
	self.shownStatusBars = index;
	self:SetMinimumWidth(140);
end

function GameTooltip_Hide()
	-- Used for XML OnLeave handlers
	GameTooltip:Hide();
end

function GameTooltip_HideResetCursor()
	GameTooltip:Hide();
	ResetCursor();
end
