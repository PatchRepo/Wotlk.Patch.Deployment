MAX_GUILDBANK_SLOTS_PER_TAB = 98;
NUM_SLOTS_PER_GUILDBANK_GROUP = 14;
NUM_GUILDBANK_ICONS_SHOWN = 0;
NUM_GUILDBANK_ICONS_PER_ROW = 4;
NUM_GUILDBANK_ICON_ROWS = 4;
GUILDBANK_ICON_ROW_HEIGHT = 36;
NUM_GUILDBANK_COLUMNS = 7;
MAX_TRANSACTIONS_SHOWN = 21;
GUILDBANK_TRANSACTION_HEIGHT = 13;

UIPanelWindows["AccountItemBankFrame"] = { area = "doublewide", pushable = 0, width = 769 };

--REMOVE ME!
TABARDBACKGROUNDUPPER = "Textures\\GuildEmblems\\Background_%s_TU_U";
TABARDBACKGROUNDLOWER = "Textures\\GuildEmblems\\Background_%s_TL_U";
TABARDEMBLEMUPPER = "Textures\\GuildEmblems\\Emblem_%s_15_TU_U";
TABARDEMBLEMLOWER = "Textures\\GuildEmblems\\Emblem_%s_15_TL_U";
TABARDBORDERUPPER = "Textures\\GuildEmblems\\Border_%s_02_TU_U";
TABARDBORDERLOWER = "Textures\\GuildEmblems\\Border_%s_02_TL_U";
TABARDBACKGROUNDID = 1;
TABARDEMBLEMID = 1;
TABARDBORDERID = 1;

GUILD_BANK_LOG_TIME_PREPEND = "|cff009999   ";

local function GetAccountItemBankWithdrawMoney()
	return 0;
end

local function CanAccountItemBankRepair()
	return false;
end

local function CanWithdrawAccountItemBankMoney()
	return false;
end

local function GetAccountItemBankMoney()
	return 0;
end

local function GetNumAccountItemBankTabs()
	return 1;
end

-- name, icon, isViewable, canDeposit, numWithdrawals, remainingWithdrawals
local function GetAccountItemBankTabInfo(tabId)
	return "Account Bank", "interface/icons/mail_gmicon", true, false, 9999, 9999; 
end

local function SetCurrentAccountItemBankTab(id)
	return;
end

function GetCurrentAccountItemBankTab()
	return 1; 
end

local function QueryAccountItemBankTab(tabId)
	return;
end

function AccountItemBankFrame_ChangeBackground(id)
	if ( id > 50 ) then
		id = 1;
	elseif ( id < 0 ) then
		id = 50;
	end
	TABARDBACKGROUNDID = id;
	AccountItemBankFrame_UpdateEmblem();
end
function AccountItemBankFrame_ChangeEmblem(id)
	if ( id > 169 ) then
		id = 1;
	elseif ( id < 0 ) then
		id = 169;
	end
	TABARDEMBLEMID = id;
	AccountItemBankFrame_UpdateEmblem();
end
function AccountItemBankFrame_ChangeBorder(id)
	if ( id > 9 ) then
		id = 1;
	elseif ( id < 0 ) then
		id = 9;
	end
	TABARDBORDERID = id;
	AccountItemBankFrame_UpdateEmblem();
end

function AccountItemBankFrame_UpdateEmblem()
	local tabardBGID = TABARDBACKGROUNDID;
	if ( tabardBGID < 10 ) then
		tabardBGID = "0"..tabardBGID;
	end
	local tabardEmblemID = TABARDEMBLEMID;
	if ( tabardEmblemID < 10 ) then
		tabardEmblemID = "0"..tabardEmblemID;
	end
	local tabardBorderID = TABARDBORDERID;
	if ( tabardBorderID < 10 ) then
		tabardBorderID = "0"..tabardBorderID;
	end
	AccountItemBankEmblemBackgroundUL:SetTexture(format(TABARDBACKGROUNDUPPER, tabardBGID));
	AccountItemBankEmblemBackgroundUR:SetTexture(format(TABARDBACKGROUNDUPPER, tabardBGID));
	AccountItemBankEmblemBackgroundBL:SetTexture(format(TABARDBACKGROUNDLOWER, tabardBGID));
	AccountItemBankEmblemBackgroundBR:SetTexture(format(TABARDBACKGROUNDLOWER, tabardBGID));

	AccountItemBankEmblemUL:SetTexture(format(TABARDEMBLEMUPPER, tabardEmblemID));
	AccountItemBankEmblemUR:SetTexture(format(TABARDEMBLEMUPPER, tabardEmblemID));
	AccountItemBankEmblemBL:SetTexture(format(TABARDEMBLEMLOWER, tabardEmblemID));
	AccountItemBankEmblemBR:SetTexture(format(TABARDEMBLEMLOWER, tabardEmblemID));

	AccountItemBankEmblemBorderUL:SetTexture(format(TABARDBORDERUPPER, tabardBorderID));
	AccountItemBankEmblemBorderUR:SetTexture(format(TABARDBORDERUPPER, tabardBorderID));
	AccountItemBankEmblemBorderBL:SetTexture(format(TABARDBORDERLOWER, tabardBorderID));
	AccountItemBankEmblemBorderBR:SetTexture(format(TABARDBORDERLOWER, tabardBorderID));
end


function AccountItemBankFrame_OnLoad(self)
	NUM_GUILDBANK_ICONS_SHOWN = NUM_GUILDBANK_ICONS_PER_ROW * NUM_GUILDBANK_ICON_ROWS;

	-- Where events used to be registered

	-- Set the button id's
	local index, column, button;
	for i=1, MAX_GUILDBANK_SLOTS_PER_TAB do
		index = mod(i, NUM_SLOTS_PER_GUILDBANK_GROUP);
		if ( index == 0 ) then
			index = NUM_SLOTS_PER_GUILDBANK_GROUP;
		end
		column = ceil((i-0.5)/NUM_SLOTS_PER_GUILDBANK_GROUP);
		button = _G["AccountItemBankColumn"..column.."Button"..index];
		button:SetID(i);
	end
	AccountItemBankFrame.mode = "bank";
	AccountItemBankFrame.numTabs = 4;
	AccountItemBankFrame_UpdateTabs();
	AccountItemBankFrame_UpdateTabard();

	-- Hide a bunch of Guild Bank stuff
	AccountItemBankFrameTab1:Hide();
	AccountItemBankFrameTab2:Hide();
	AccountItemBankFrameTab3:Hide();
	AccountItemBankFrameTab4:Hide();
	AccountItemBankFrameDepositButton:Hide();
	AccountItemBankFrameWithdrawButton:Hide();
	AccountItemBankEmblemFrame:Hide();

	AccountItemBankLimitLabel:Hide();
	AccountItemBankTabLimitBackground:Hide();
	AccountItemBankTabLimitBackgroundLeft:Hide();
	AccountItemBankTabLimitBackgroundRight:Hide();
end

function AccountItemBankFrame_OnEvent(self, event, ...)
	if ( not AccountItemBankFrame:IsVisible() ) then
		return;
	end

	-- Where events used to be handled
end

function AccountItemBankFrame_SelectAvailableTab()
	--If the selected tab is notViewable then select the next available one
	if ( IsTabViewable(GetCurrentAccountItemBankTab()) ) then
		AccountItemBankFrame_UpdateTabs();
		AccountItemBankFrame_Update();
	else
		if ( AccountItemBankFrame.nextAvailableTab ) then
			AccountItemBankTab_OnClick(_G["AccountItemBankTab" .. AccountItemBankFrame.nextAvailableTab], "LeftButton", AccountItemBankFrame.nextAvailableTab);
		else
			AccountItemBankFrame_UpdateTabs();
			AccountItemBankFrame_Update();
		end
	end
end

function AccountItemBankFrame_OnUpdate()

end

function AccountItemBankFrame_OnShow()
	AccountItemBankFrameTab_OnClick(AccountItemBankFrameTab1, 1);
	AccountItemBankFrame_UpdateTabard();
	AccountItemBankFrame_SelectAvailableTab();
	PlaySound("GuildVaultOpen");
end

function AccountItemBankFrame_Update()
	--Figure out which mode you're in and which tab is selected
	if ( AccountItemBankFrame.mode == "bank" ) then
		-- Determine whether its the buy tab or not
		AccountItemBankFrameLog:Hide();
		AccountItemBankInfo:Hide();	
		local tab = GetCurrentAccountItemBankTab();
		if ( AccountItemBankFrame.noViewableTabs ) then
			AccountItemBankFrame_HideColumns();
			AccountItemBankFrameBuyInfo:Hide();
			AccountItemBankErrorMessage:SetText(NO_VIEWABLE_GUILDBANK_TABS);
			AccountItemBankErrorMessage:Show();
		elseif ( tab > GetNumAccountItemBankTabs() ) then
			if ( IsGuildLeader() ) then
				--Show buy screen
				AccountItemBankFrame_HideColumns();
				AccountItemBankFrameBuyInfo:Show();
				AccountItemBankErrorMessage:Hide();
			else
				AccountItemBankFrame_HideColumns();
				AccountItemBankFrameBuyInfo:Hide();
				AccountItemBankErrorMessage:SetText(NO_GUILDBANK_TABS);
				AccountItemBankErrorMessage:Show();
			end
		else
			local _, _, _, canDeposit, numWithdrawals = GetAccountItemBankTabInfo(tab);
			if ( not canDeposit and numWithdrawals == 0 ) then
				AccountItemBankFrame_DesaturateColumns(1);
			else
				AccountItemBankFrame_DesaturateColumns(nil);
			end
			AccountItemBankFrame_ShowColumns()
			AccountItemBankFrameBuyInfo:Hide();
			AccountItemBankErrorMessage:Hide();
		end

		-- Update the tab items		
		local button, index, column;
		local texture, itemCount, locked;
		for i=1, MAX_GUILDBANK_SLOTS_PER_TAB do
			index = mod(i, NUM_SLOTS_PER_GUILDBANK_GROUP);
			if ( index == 0 ) then
				index = NUM_SLOTS_PER_GUILDBANK_GROUP;
			end
			column = ceil((i-0.5)/NUM_SLOTS_PER_GUILDBANK_GROUP);
			button = _G["AccountItemBankColumn"..column.."Button"..index];
			button:SetID(i);
			texture, itemCount, locked, _ = GetAccountItemBankItemInfo(tab, i);
			SetItemButtonTexture(button, texture);
			SetItemButtonCount(button, itemCount);
			SetItemButtonDesaturated(button, locked, 0.5, 0.5, 0.5);
		end
		-- MoneyFrame_Update("GuildBankMoneyFrame", 0);
		if ( CanWithdrawAccountItemBankMoney() ) then
			AccountItemBankFrameWithdrawButton:Enable();
		else
			AccountItemBankFrameWithdrawButton:Disable();
		end
	elseif ( AccountItemBankFrame.mode == "log" or AccountItemBankFrame.mode == "moneylog" ) then
		AccountItemBankFrame_HideColumns();
		AccountItemBankFrameBuyInfo:Hide();
		AccountItemBankInfo:Hide();	
		if ( AccountItemBankFrame.noViewableTabs and AccountItemBankFrame.mode == "log" ) then
			AccountItemBankErrorMessage:SetText(NO_VIEWABLE_GUILDBANK_LOGS);
			AccountItemBankErrorMessage:Show();
			AccountItemBankFrameLog:Hide();
		else
			AccountItemBankErrorMessage:Hide();
			AccountItemBankFrameLog:Show();
		end
	elseif ( AccountItemBankFrame.mode == "tabinfo" ) then
		AccountItemBankFrame_HideColumns();
		AccountItemBankErrorMessage:Hide();
		AccountItemBankFrameBuyInfo:Hide();
		AccountItemBankFrameLog:Hide();
		AccountItemBankInfo:Show();
	end
	--Update remaining money
	AccountItemBankFrame_UpdateWithdrawMoney();
end

function AccountItemBankFrameTab_OnClick(tab, id, doNotUpdate)
	PanelTemplates_SetTab(AccountItemBankFrame, id);
	if ( id == 1 ) then
		--Bank
		AccountItemBankFrame.mode = "bank";
		if ( not doNotUpdate ) then
			QueryAccountItemBankTab(GetCurrentAccountItemBankTab());
		end
	elseif ( id == 2 ) then
		--Log
		AccountItemBankMessageFrame:Clear();
		AccountItemBankTransactionsScrollFrame:Hide();
		AccountItemBankFrame.mode = "log";
		if ( not doNotUpdate ) then
			QueryAccountItemBankLog(GetCurrentAccountItemBankTab());
		end
		AccountItemBankTransactionsScrollFrameScrollBar:SetValue(0);
	elseif ( id == 3 ) then
		--Money log
		AccountItemBankMessageFrame:Clear();
		AccountItemBankTransactionsScrollFrame:Hide();
		AccountItemBankFrame.mode = "moneylog";
		if ( not doNotUpdate ) then
			QueryAccountItemBankLog(MAX_GUILDBANK_TABS + 1);
		end
		AccountItemBankTransactionsScrollFrameScrollBar:SetValue(0);
	else
		--Tab Info
		AccountItemBankFrame.mode = "tabinfo";
		if ( not doNotUpdate ) then
			QueryAccountItemBankText(GetCurrentAccountItemBankTab());
		end
	end
	--Call this to gray out tabs or activate them
	AccountItemBankFrame_UpdateTabs();
	if ( not doNotUpdate ) then
		AccountItemBankFrame_Update();
	end
	PlaySound("igCharacterInfoTab");
end

function AccountItemBankFrame_UpdateTabBuyingInfo()
	local tabCost = GetAccountItemBankTabCost();
	local numTabs = GetNumAccountItemBankTabs();
	AccountItemBankFrameBuyInfoNumTabsPurchasedText:SetText(format(NUM_GUILDBANK_TABS_PURCHASED, numTabs, MAX_GUILDBANK_TABS));
	if ( not tabCost ) then
		--You've bought all the tabs
		AccountItemBankTab_OnClick(AccountItemBankTab1, "LeftButton", 1);
	else
		if( GetMoney() >= tabCost or (GetMoney() + GetAccountItemBankMoney()) >= tabCost ) then
			SetMoneyFrameColor("AccountItemBankFrameTabCostMoneyFrame", "white");
			AccountItemBankFramePurchaseButton:Enable();
		else
			SetMoneyFrameColor("AccountItemBankFrameTabCostMoneyFrame", "red");
			AccountItemBankFramePurchaseButton:Disable();
		end
		AccountItemBankTab_OnClick(_G["AccountItemBankTab" .. numTabs+1], "LeftButton", numTabs+1);
		MoneyFrame_Update("AccountItemBankFrameTabCostMoneyFrame", tabCost);
	end
end

function AccountItemBankFrame_UpdateTabs()
	local tab, iconTexture, tabButton;
	local name, icon, isViewable, canDeposit, numWithdrawals, remainingWithdrawals;
	local numTabs = GetNumAccountItemBankTabs();
	local currentTab = GetCurrentAccountItemBankTab();
	local tabToBuyIndex = numTabs+1;
	local unviewableCount = 0;
	local disableAll = nil;
	local updateAgain = nil;
	local isLocked, titleText;
	local withdrawalText, withdrawalStackCount;
	-- Disable and gray out all tabs if in the moneyLog since the tab is irrelevant
	if ( AccountItemBankFrame.mode == "moneylog" ) then
		disableAll = 1;
	end
	for i=1, MAX_GUILDBANK_TABS do
		tab = _G["AccountItemBankTab"..i];
		tabButton = _G["AccountItemBankTab"..i.."Button"];
		name, icon, isViewable, canDeposit, numWithdrawals, remainingWithdrawals = GetAccountItemBankTabInfo(i);
		iconTexture = _G["AccountItemBankTab"..i.."ButtonIconTexture"];
		if ( not name or name == "" ) then
			name = format(GUILDBANK_TAB_NUMBER, i);
		end
		if ( i >= tabToBuyIndex ) then
			tab:Hide();
		else
			iconTexture:SetTexture(icon);
			tab:Show();
			if ( isViewable ) then
				tabButton.tooltip = name;
				if ( i == currentTab ) then
					if ( disableAll ) then
						tabButton:SetChecked(nil);
					else
						tabButton:SetChecked(1);
						tabButton:Enable();
					end
					withdrawalText = name;
					titleText =  name;
				else
					tabButton:SetChecked(nil);
					tabButton:Enable();
				end
				if ( disableAll ) then
					tabButton:Disable();
					SetDesaturation(iconTexture, 1);
				else
					SetDesaturation(iconTexture, nil);
				end
			else
				unviewableCount = unviewableCount+1;
				tabButton:Disable();
				SetDesaturation(iconTexture, 1);
				tabButton:SetChecked(nil);
			end
			
		end
		if ( unviewableCount == numTabs and not IsGuildLeader() ) then
			--Can't view any tabs so hide everything
			AccountItemBankFrame.noViewableTabs = 1;
		else
			AccountItemBankFrame.noViewableTabs = nil;
		end
		if ( updateAgain ) then
			AccountItemBankFrame_UpdateTabs();
		end
	end

	-- Set Title
	if ( AccountItemBankFrame.mode == "moneylog" ) then
		titleText = GUILD_BANK_MONEY_LOG;
		withdrawalText = nil;
	elseif ( AccountItemBankFrame.mode == "log" ) then
		if ( titleText ) then
			titleText = format(GUILDBANK_LOG_TITLE_FORMAT, titleText);	
		end
	elseif ( AccountItemBankFrame.mode == "tabinfo" ) then
		withdrawalText = nil;
		if ( titleText ) then
			titleText = format(GUILDBANK_INFO_TITLE_FORMAT, titleText);
		end
	end
	--Get selected tab info
	name, icon, isViewable, canDeposit, numWithdrawals, remainingWithdrawals = GetAccountItemBankTabInfo(currentTab);
	if ( titleText and (AccountItemBankFrame.mode ~= "moneylog" and titleText ~= BUY_GUILDBANK_TAB) ) then
		local access;
		if ( not canDeposit and numWithdrawals == 0 ) then
			access = RED_FONT_COLOR_CODE.."("..GUILDBANK_TAB_LOCKED..")"..FONT_COLOR_CODE_CLOSE;
		elseif ( not canDeposit ) then
			access = RED_FONT_COLOR_CODE.."("..GUILDBANK_TAB_WITHDRAW_ONLY..")"..FONT_COLOR_CODE_CLOSE;
		elseif ( numWithdrawals == 0 ) then
			access = RED_FONT_COLOR_CODE.."("..GUILDBANK_TAB_DEPOSIT_ONLY..")"..FONT_COLOR_CODE_CLOSE;
		else
			access = GREEN_FONT_COLOR_CODE.."("..GUILDBANK_TAB_FULL_ACCESS..")"..FONT_COLOR_CODE_CLOSE;
		end
		titleText = titleText.."  "..access;
	end
	if ( titleText ) then
		AccountItemBankTabTitle:SetText(titleText);
		AccountItemBankTabTitleBackground:SetWidth(AccountItemBankTabTitle:GetWidth()+20);

		AccountItemBankTabTitle:Show();
		AccountItemBankTabTitleBackground:Show();
		AccountItemBankTabTitleBackgroundLeft:Show();
		AccountItemBankTabTitleBackgroundRight:Show();
	else
		AccountItemBankTabTitle:Hide();
		AccountItemBankTabTitleBackground:Hide();
		AccountItemBankTabTitleBackgroundLeft:Hide();
		AccountItemBankTabTitleBackgroundRight:Hide();
	end
	if ( withdrawalText ) then
		local stackString;
		if ( remainingWithdrawals > 0 ) then
			stackString = format(STACKS, remainingWithdrawals);
		elseif ( remainingWithdrawals == 0 ) then
			stackString = NONE;
		else
			stackString = UNLIMITED;
		end
		AccountItemBankLimitLabel:SetText(format(GUILDBANK_REMAINING_MONEY, withdrawalText, stackString));
		AccountItemBankTabLimitBackground:SetWidth(AccountItemBankLimitLabel:GetWidth()+20);
		--If the tab name is too long then reanchor the withdraw box so it's not longer centered
		if ( AccountItemBankLimitLabel:GetWidth() > 298 ) then
			AccountItemBankTabLimitBackground:ClearAllPoints();
			AccountItemBankTabLimitBackground:SetPoint("RIGHT", AccountItemBankFrameWithdrawButton, "LEFT", -14, -1);
		else
			AccountItemBankTabLimitBackground:ClearAllPoints();
			AccountItemBankTabLimitBackground:SetPoint("TOP", "AccountItemBankFrame", "TOP", 6, -388);
		end

		-- AccountItemBankLimitLabel:Show();
		-- AccountItemBankTabLimitBackground:Show();
		-- AccountItemBankTabLimitBackgroundLeft:Show();
		-- AccountItemBankTabLimitBackgroundRight:Show();
	else
		AccountItemBankLimitLabel:Hide();
		AccountItemBankTabLimitBackground:Hide();
		AccountItemBankTabLimitBackgroundLeft:Hide();
		AccountItemBankTabLimitBackgroundRight:Hide();
	end
end

function AccountItemBankTab_OnClick(self, mouseButton, currentTab)
	if ( AccountItemBankInfo:IsShown() ) then
		AccountItemBankInfoSaveButton:Click();
	end
	if ( not currentTab ) then
		currentTab = self:GetParent():GetID();
	end
	SetCurrentAccountItemBankTab(currentTab);
	AccountItemBankFrame_UpdateTabs();
	if ( IsGuildLeader() and mouseButton == "RightButton" and currentTab ~= (GetNumAccountItemBankTabs() + 1) ) then
		--Show the popup if it's a right click
		AccountItemBankPopupFrame:Show();
		AccountItemBankPopupFrame_Update(currentTab);
	end
	AccountItemBankFrame_Update();
	if ( AccountItemBankFrameLog:IsShown() ) then
		if ( AccountItemBankFrame.mode == "log" ) then
			QueryAccountItemBankTab(currentTab);	--Need this to get the number of withdrawals left for this tab
			QueryAccountItemBankLog(currentTab);
			AccountItemBankFrame_UpdateLog();
		else
			QueryAccountItemBankLog(MAX_GUILDBANK_TABS+1);
			AccountItemBankFrame_UpdateMoneyLog();
		end
	elseif ( AccountItemBankInfo:IsShown() ) then
		QueryAccountItemBankText(currentTab);
	else
		QueryAccountItemBankTab(currentTab);
	end
end

function AccountItemBankFrame_HideColumns()
	if ( not AccountItemBankColumn1:IsShown() ) then
		return;
	end
	for i=1, NUM_GUILDBANK_COLUMNS do
		_G["AccountItemBankColumn"..i]:Hide();
	end
end

function AccountItemBankFrame_ShowColumns()
	if ( AccountItemBankColumn1:IsShown() ) then
		return;
	end
	for i=1, NUM_GUILDBANK_COLUMNS do
		_G["AccountItemBankColumn"..i]:Show();
	end
end

function AccountItemBankFrame_DesaturateColumns(isDesaturated)
	for i=1, NUM_GUILDBANK_COLUMNS do
		SetDesaturation(_G["AccountItemBankColumn"..i.."Background"], isDesaturated);
	end
end

function AccountItemBankItemButton_OnLoad(self)
	self:RegisterForClicks("LeftButtonUp", "RightButtonUp");
	self:RegisterForDrag("LeftButton");
	self.SplitStack = function(button, split)
		SplitAccountItemBankItem(GetCurrentAccountItemBankTab(), button:GetID(), split);
	end
	self.UpdateTooltip = AccountItemBankItemButton_OnEnter;
end

function AccountItemBankItemButton_OnEnter(self)
	GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
	texture, itemCount, locked, itemId = GetAccountItemBankItemInfo(GetCurrentAccountItemBankTab(), self:GetID());

	if (itemId ~= nil and itemId ~= 0) then
		GameTooltip:SetHyperlink("\124cff9d9d9d\124Hitem:" .. itemId .. "::::::::60:::::\124h[Martin Fury]\124h\124r");
	end
end

function AccountItemBankFrame_UpdateLog()
	local tab = GetCurrentAccountItemBankTab();
	local numTransactions = GetNumAccountItemBankTransactions(tab);
	local type, name, itemLink, count, tab1, tab2, year, month, day, hour;
	
	local msg;
	AccountItemBankMessageFrame:Clear();
	for i=1, numTransactions, 1 do
		type, name, itemLink, count, tab1, tab2, year, month, day, hour = GetAccountItemBankTransaction(tab, i);
		if ( not name ) then
			name = UNKNOWN;
		end
		name = NORMAL_FONT_COLOR_CODE..name..FONT_COLOR_CODE_CLOSE;
		if ( type == "deposit" ) then
			msg = format(GUILDBANK_DEPOSIT_FORMAT, name, itemLink);
			if ( count > 1 ) then
				msg = msg..format(GUILDBANK_LOG_QUANTITY, count);
			end
		elseif ( type == "withdraw" ) then
			msg = format(GUILDBANK_WITHDRAW_FORMAT, name, itemLink);
			if ( count > 1 ) then
				msg = msg..format(GUILDBANK_LOG_QUANTITY, count);
			end
		elseif ( type == "move" ) then
			msg = format(GUILDBANK_MOVE_FORMAT, name, itemLink, count, GetAccountItemBankTabInfo(tab1), GetAccountItemBankTabInfo(tab2));
		end
		if ( msg ) then
			AccountItemBankMessageFrame:AddMessage( msg..GUILD_BANK_LOG_TIME_PREPEND..format(GUILD_BANK_LOG_TIME, RecentTimeDate(year, month, day, hour)) );
		end
	end
	FauxScrollFrame_Update(AccountItemBankTransactionsScrollFrame, numTransactions, MAX_TRANSACTIONS_SHOWN, GUILDBANK_TRANSACTION_HEIGHT );
end

function AccountItemBankFrame_UpdateMoneyLog()
	local numTransactions = GetNumAccountItemBankMoneyTransactions();
	local type, name, amount, year, month, day, hour;
	local msg;
	local money;
	AccountItemBankMessageFrame:Clear();
	for i=1, numTransactions, 1 do
		type, name, amount, year, month, day, hour = GetAccountItemBankMoneyTransaction(i);
		if ( not name ) then
			name = UNKNOWN;
		end
		name = NORMAL_FONT_COLOR_CODE..name..FONT_COLOR_CODE_CLOSE;
		money = GetDenominationsFromCopper(amount);
		if ( type == "deposit" ) then
			msg = format(GUILDBANK_DEPOSIT_MONEY_FORMAT, name, money);
		elseif ( type == "withdraw" ) then
			msg = format(GUILDBANK_WITHDRAW_MONEY_FORMAT, name, money);
		elseif ( type == "repair" ) then
			msg = format(GUILDBANK_REPAIR_MONEY_FORMAT, name, money);
		elseif ( type == "withdrawForTab" ) then
			msg = format(GUILDBANK_WITHDRAWFORTAB_MONEY_FORMAT, name, money);
		elseif ( type == "buyTab" ) then
			msg = format(GUILDBANK_BUYTAB_MONEY_FORMAT, name, money);
		end
		AccountItemBankMessageFrame:AddMessage(msg..GUILD_BANK_LOG_TIME_PREPEND..format(GUILD_BANK_LOG_TIME, RecentTimeDate(year, month, day, hour)));
	end
	FauxScrollFrame_Update(AccountItemBankTransactionsScrollFrame, numTransactions, MAX_TRANSACTIONS_SHOWN, GUILDBANK_TRANSACTION_HEIGHT );
end

function AccountItemBankLogScroll()
	local offset = FauxScrollFrame_GetOffset(AccountItemBankTransactionsScrollFrame);
	local numTransactions = 0;
	if ( AccountItemBankFrame.mode == "log" ) then
		numTransactions = GetNumAccountItemBankTransactions(GetCurrentAccountItemBankTab());
	elseif ( AccountItemBankFrame.mode == "moneylog" ) then
		numTransactions = GetNumAccountItemBankMoneyTransactions();
	end
	AccountItemBankMessageFrame:SetScrollOffset(offset);
	FauxScrollFrame_Update(AccountItemBankTransactionsScrollFrame, numTransactions, MAX_TRANSACTIONS_SHOWN, GUILDBANK_TRANSACTION_HEIGHT );
end

function IsTabViewable(tab)
	AccountItemBankFrame.nextAvailableTab = nil;
	local view = false;
	for i=1, MAX_GUILDBANK_TABS do
		local _, _, isViewable = GetAccountItemBankTabInfo(i);
		if ( isViewable ) then
			if ( not AccountItemBankFrame.nextAvailableTab ) then
				AccountItemBankFrame.nextAvailableTab = i;
			end
			if ( i == tab ) then
				view = true;
			end
		end
	end
	return view;
end

function AccountItemBankFrame_UpdateWithdrawMoney()
	local withdrawLimit = GetAccountItemBankWithdrawMoney();
	if ( withdrawLimit >= 0 ) then
		local amount;
		if ( (not CanAccountItemBankRepair() and not CanWithdrawAccountItemBankMoney()) or (CanAccountItemBankRepair() and not CanWithdrawAccountItemBankMoney()) ) then
			amount = 0;
		else
			amount = GetAccountItemBankMoney();
		end
		withdrawLimit = min(withdrawLimit, amount);
		-- MoneyFrame_Update("GuildWithdrawMoneyFrame", 0);
		AccountItemBankMoneyUnlimitedLabel:Hide();
	else
		AccountItemBankMoneyUnlimitedLabel:Show();
	end
end

function AccountItemBankFrame_UpdateTabard()
	--Set the tabard images
	local tabardBackgroundUpper, tabardBackgroundLower, tabardEmblemUpper, tabardEmblemLower, tabardBorderUpper, tabardBorderLower = GetGuildTabardFileNames();
	if ( not tabardEmblemUpper ) then
		tabardBackgroundUpper = "Textures\\GuildEmblems\\Background_49_TU_U";
		tabardBackgroundLower = "Textures\\GuildEmblems\\Background_49_TL_U";
	end
	AccountItemBankEmblemBackgroundUL:SetTexture(tabardBackgroundUpper);
	AccountItemBankEmblemBackgroundUR:SetTexture(tabardBackgroundUpper);
	AccountItemBankEmblemBackgroundBL:SetTexture(tabardBackgroundLower);
	AccountItemBankEmblemBackgroundBR:SetTexture(tabardBackgroundLower);

	AccountItemBankEmblemUL:SetTexture(tabardEmblemUpper);
	AccountItemBankEmblemUR:SetTexture(tabardEmblemUpper);
	AccountItemBankEmblemBL:SetTexture(tabardEmblemLower);
	AccountItemBankEmblemBR:SetTexture(tabardEmblemLower);

	AccountItemBankEmblemBorderUL:SetTexture(tabardBorderUpper);
	AccountItemBankEmblemBorderUR:SetTexture(tabardBorderUpper);
	AccountItemBankEmblemBorderBL:SetTexture(tabardBorderLower);
	AccountItemBankEmblemBorderBR:SetTexture(tabardBorderLower);
end

function AccountItemBankFrame_UpdateTabInfo(tab)
	local text = GetAccountItemBankText(tab);
	if ( text ) then
		AccountItemBankTabInfoEditBox.text = text;
		AccountItemBankTabInfoEditBox:SetText(text);
	else
		AccountItemBankTabInfoEditBox:SetText("");
	end
end

--Popup functions
function AccountItemBankPopupFrame_Update(tab)
	local numAccountItemBankIcons = GetNumMacroItemIcons();
	local AccountItemBankPopupIcon, AccountItemBankPopupButton;
	local AccountItemBankPopupOffset = FauxScrollFrame_GetOffset(AccountItemBankPopupScrollFrame);
	local index;
	
	local _, tabTexture  = GetAccountItemBankTabInfo(GetCurrentAccountItemBankTab());
	
	-- Icon list
	local texture;
	for i=1, NUM_GUILDBANK_ICONS_SHOWN do
		AccountItemBankPopupIcon = _G["AccountItemBankPopupButton"..i.."Icon"];
		AccountItemBankPopupButton = _G["AccountItemBankPopupButton"..i];
		index = (AccountItemBankPopupOffset * NUM_GUILDBANK_ICONS_PER_ROW) + i;
		texture = GetMacroItemIconInfo(index);
		if ( index <= numAccountItemBankIcons ) then
			AccountItemBankPopupIcon:SetTexture(texture);
			AccountItemBankPopupButton:Show();
		else
			AccountItemBankPopupIcon:SetTexture("");
			AccountItemBankPopupButton:Hide();
		end
		if ( AccountItemBankPopupFrame.selectedIcon ) then
			if ( index == AccountItemBankPopupFrame.selectedIcon ) then
				AccountItemBankPopupButton:SetChecked(1);
			else
				AccountItemBankPopupButton:SetChecked(nil);
			end
		elseif ( tabTexture == texture ) then
			AccountItemBankPopupButton:SetChecked(1);
			AccountItemBankPopupFrame.selectedIcon = index;
		else
			AccountItemBankPopupButton:SetChecked(nil);
		end
	end
	--Only do this if the player hasn't clicked on an icon or the icon is not visible
	if ( not AccountItemBankPopupFrame.selectedIcon ) then
		for i=1, numAccountItemBankIcons do
			texture = GetMacroItemIconInfo(i);
			if ( tabTexture == texture ) then
				AccountItemBankPopupFrame.selectedIcon = i;
				break;
			end
		end
	end
	
	-- Scrollbar stuff
	FauxScrollFrame_Update(AccountItemBankPopupScrollFrame, ceil(numAccountItemBankIcons / NUM_GUILDBANK_ICONS_PER_ROW) , NUM_GUILDBANK_ICON_ROWS, GUILDBANK_ICON_ROW_HEIGHT );
end

function AccountItemBankPopupFrame_OnShow(self)
	HideParentPanel();
	local name = GetAccountItemBankTabInfo(GetCurrentAccountItemBankTab());
	if ( not name or name == "" ) then
		name = format(GUILDBANK_TAB_NUMBER, GetCurrentAccountItemBankTab());
	end
	AccountItemBankPopupEditBox:SetText(name);
	AccountItemBankPopupFrame.selectedIcon = nil;
end

function AccountItemBankPopupButton_OnClick(self, button)
	local offset = FauxScrollFrame_GetOffset(AccountItemBankPopupScrollFrame);
	local index = (offset * NUM_GUILDBANK_ICONS_PER_ROW)+self:GetID();
	AccountItemBankPopupFrame.selectedIcon = index;
	AccountItemBankPopupFrame_Update(GetCurrentAccountItemBankTab());
end

function AccountItemBankPopupOkayButton_OnClick(self)
	local name = AccountItemBankPopupEditBox:GetText();
	local tab = GetCurrentAccountItemBankTab();
	if ( not name or name == "" ) then
		name = format(GUILDBANK_TAB_NUMBER, tab);
	end
	SetAccountItemBankTabInfo(tab, name, AccountItemBankPopupFrame.selectedIcon);
	AccountItemBankPopupFrame:Hide();
end

function AccountItemBankPopupFrame_CancelEdit()
	AccountItemBankPopupFrame:Hide();
end

