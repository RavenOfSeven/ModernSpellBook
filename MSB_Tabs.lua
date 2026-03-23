--[[
	Tab button for the spellbook: class, general, pet, custom.
--]]

-- Tab colors
local disabledVertexColor = {0.5, 0.5, 0.5, 1}
local enabledVertexColor = {1, 1, 1, 1}
local normalFontColor = {1, 0.82, 0}
local highlightFontColor = {1, 1, 1}
local disabledFontColor = {0.5, 0.41, 0}

class "CTab"
{
	__init = function(self, parent, name, tabNumber, onClickCallback)
		self.tab_number = tabNumber
		self.name = name

		self.frame = CreateFrame("Button", "ModernSpellBookFrame_Tab".. tabNumber, parent)
		self.frame:SetNormalTexture("Interface\\Spellbook\\UI-SpellBook-Tab3-Selected")
		self.frame:SetHighlightTexture("Interface\\Spellbook\\UI-SpellBook-Tab1-Selected")

		local tabText = self.frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		tabText:SetPoint("CENTER", self.frame, "CENTER", 0, 0)
		self.frame:SetFontString(tabText)

		self:SetName(name)

		if (tabNumber == 1) then
			self.frame:SetNormalTexture("Interface\\Spellbook\\UI-SpellBook-Tab3-Selected")
			self.frame:GetNormalTexture():SetVertexColor(unpack(enabledVertexColor))
			self.frame:GetFontString():SetTextColor(unpack(normalFontColor))
		else
			self.frame:SetNormalTexture("Interface\\Spellbook\\UI-SpellBook-Tab-Unselected")
			self.frame:GetNormalTexture():SetVertexColor(unpack(disabledVertexColor))
			self.frame:GetFontString():SetTextColor(unpack(disabledFontColor))
		end

		-- Click handler
		local tab = self
		self.frame:SetScript("OnClick", function()
			onClickCallback(tab)
		end)

		self.frame:SetScript("OnEnter", function()
			tab.frame:GetFontString():SetTextColor(unpack(highlightFontColor))
		end)

		self.frame:SetScript("OnLeave", function()
			tab:SetDefaultFontColor()
		end)
	end;

	-- ========================= METHODS ===========================

	SetName = function(self, name)
		self.name = name
		self.frame:GetFontString():SetText(name)
		local tw = 60
		if (self.frame:GetFontString().GetStringWidth) then
			tw = self.frame:GetFontString():GetStringWidth()
		end
		self.frame:SetWidth(tw + 40)
		self.frame:SetHeight(55)
	end;

	UpdatePosition = function(self, isMainFrameMinimized, tabgroups)
		self.frame:ClearAllPoints()

		if (self.tab_number == 1) then
			if (isMainFrameMinimized) then
				self.frame:SetPoint("BOTTOMLEFT", ModernSpellBookFrame, "BOTTOMLEFT", 20, -41)
			else
				self.frame:SetPoint("TOPLEFT", ModernSpellBookFrame, "TOPLEFT", 50, -10)
			end
		else
			-- Find previous visible tab to anchor to
			local anchor = nil
			for j = self.tab_number - 1, 1, -1 do
				local prevTab = tabgroups[j]
				if (prevTab and prevTab:IsShown()) then
					anchor = prevTab
					break
				end
			end
			if (anchor) then
				self.frame:SetPoint("TOPLEFT", anchor.frame, "TOPRIGHT", -13, 0)
			else
				if (isMainFrameMinimized) then
					self.frame:SetPoint("BOTTOMLEFT", ModernSpellBookFrame, "BOTTOMLEFT", 20, -41)
				else
					self.frame:SetPoint("TOPLEFT", ModernSpellBookFrame, "TOPLEFT", 50, -10)
				end
			end
		end
	end;

	SetMinmaxPosition = function(self, isMainFrameMinimized, tabgroups)
		if (isMainFrameMinimized) then
			self.frame:GetFontString():SetPoint("CENTER", self.frame, "CENTER", 0, 2.5)
			self.frame:GetNormalTexture():SetTexCoord(0, 1, 0, 1)
			self.frame:GetHighlightTexture():SetTexCoord(0, 1, 0, 1)
		else
			self.frame:GetFontString():SetPoint("CENTER", self.frame, "CENTER", 0, -2.5)
			self.frame:GetNormalTexture():SetTexCoord(0, 1, 1, 0)
			self.frame:GetHighlightTexture():SetTexCoord(0, 1, 1, 0)
		end

		self:UpdatePosition(isMainFrameMinimized, tabgroups)
	end;

	SetDefaultFontColor = function(self)
		if (ModernSpellBookFrame.selectedTab == self.tab_number) then
			self.frame:GetFontString():SetTextColor(unpack(normalFontColor))
		else
			self.frame:GetFontString():SetTextColor(unpack(disabledFontColor))
		end
	end;

	UpdateAsPetTab = function(self)
		local petType = UnitCreatureType("pet")
		if (petType) then
			self:SetName(petType)
			self.frame:Show()
		else
			self.frame:Hide()
			if (ModernSpellBookFrame.selectedTab == self.tab_number) then
				ModernSpellBookFrame.selectedTab = 1
				ModernSpellBookFrame.Tabgroups[1].frame:Click()
				ModernSpellBookFrame.Tabgroups[1].frame:GetFontString():SetTextColor(unpack(normalFontColor))
			end
		end

		ModernSpellBookFrame:PositionAllTabs()
	end;

	-- ======================== VISUAL STATE =======================

	SetSelected = function(self)
		self.frame:SetNormalTexture("Interface\\Spellbook\\UI-SpellBook-Tab3-Selected")
		self.frame:GetNormalTexture():SetVertexColor(unpack(enabledVertexColor))
	end;

	SetDeselected = function(self)
		self.frame:SetNormalTexture("Interface\\Spellbook\\UI-SpellBook-Tab-Unselected")
		self.frame:GetNormalTexture():SetVertexColor(unpack(disabledVertexColor))
		self.frame:GetFontString():SetTextColor(unpack(disabledFontColor))
	end;

	-- ====================== DELEGATION ===========================

	Hide = function(self)
		self.frame:Hide()
	end;

	Show = function(self)
		self.frame:Show()
	end;

	IsShown = function(self)
		return self.frame:IsShown()
	end;

	Enable = function(self)
		self.frame:Enable()
	end;

	Disable = function(self)
		self.frame:Disable()
	end;

	GetRight = function(self)
		return self.frame:GetRight()
	end;

	GetNormalTexture = function(self)
		return self.frame:GetNormalTexture()
	end;

	GetFontString = function(self)
		return self.frame:GetFontString()
	end;
}

-- ============================================================
-- Tab management (stays on ModernSpellBookFrame for now)
-- ============================================================

ModernSpellBookFrame.Tabgroups = {}

function ModernSpellBookFrame:NewTab(name)
	local tabNumber = table.getn(ModernSpellBookFrame.Tabgroups) + 1

	local tab = CTab(ModernSpellBookFrame, name, tabNumber, function(clickedTab)
		local wasPreviousSelectionDifferent = ModernSpellBookFrame.selectedTab ~= clickedTab.tab_number
		if (not wasPreviousSelectionDifferent) then return end

		PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
		ModernSpellBookFrame.selectedTab = clickedTab.tab_number
		ModernSpellBook_DB.lastTab = clickedTab.tab_number

		clickedTab:SetSelected()

		for _, other_tab in ipairs(ModernSpellBookFrame.Tabgroups) do
			if (other_tab ~= clickedTab) then
				other_tab:SetDeselected()
			end
		end

		ModernSpellBookFrame.currentPage = 1
		ModernSpellBook_DB.lastPage = 1
		ModernSpellBookFrame.previousPage:Disable()
		ModernSpellBookFrame:DrawPage()
	end)

	table.insert(ModernSpellBookFrame.Tabgroups, tab)
	return tab
end

function ModernSpellBookFrame:GetFinalVisibleTab()
	local finalVisibleTab = 1
	for i = 1, table.getn(ModernSpellBookFrame.Tabgroups) do
		if (ModernSpellBookFrame.Tabgroups[i]:IsShown()) then
			finalVisibleTab = i
		end
	end
	return ModernSpellBookFrame.Tabgroups[finalVisibleTab]
end

local leftButtons = {"ShowPassiveSpellsCheckBox", "ShowAllSpellRanksCheckbox", "ModernSpellBookFrameSearchBar"}
function ModernSpellBookFrame:GetRightmostLeftButton()
	local finalVisibleButton = _G[leftButtons[1]]

	for _, item in ipairs(leftButtons) do
		local button = _G[item]
		if (button == nil or not button:IsShown()) then
			return finalVisibleButton
		end
		finalVisibleButton = button
	end

	return ShowPassiveSpellsCheckBox
end

function ModernSpellBookFrame:PositionAllTabs()
	if (ModernSpellBook_DB.isMinimized) then
		for _, tab in ipairs(ModernSpellBookFrame.Tabgroups) do
			tab:UpdatePosition(false, ModernSpellBookFrame.Tabgroups)
		end

		local lastTab = ModernSpellBookFrame:GetFinalVisibleTab()
		local left = lastTab:GetRight()
		local right = ModernSpellBookFrame:GetRightmostLeftButton():GetLeft()

		for _, tab in ipairs(ModernSpellBookFrame.Tabgroups) do
			tab:SetMinmaxPosition(left and right and left > right, ModernSpellBookFrame.Tabgroups)
		end
	else
		for _, tab in ipairs(ModernSpellBookFrame.Tabgroups) do
			tab:SetMinmaxPosition(false, ModernSpellBookFrame.Tabgroups)
		end
	end
end

-- ============================================================
-- Combat lockout
-- ============================================================

ModernSpellBookFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
ModernSpellBookFrame:RegisterEvent("PLAYER_REGEN_ENABLED")

ModernSpellBookFrame.PLAYER_REGEN_DISABLED = function(self)
	if (ModernSpellBookFrame.isFirstLoad) then return end
	local selected_tab = ModernSpellBookFrame.Tabgroups[ModernSpellBookFrame.selectedTab]
	for _, tab in ipairs(ModernSpellBookFrame.Tabgroups) do
		tab:Disable()
		if (tab ~= selected_tab) then
			if (tab:GetNormalTexture().SetDesaturated) then
				tab:GetNormalTexture():SetDesaturated(true)
			end
			tab:GetFontString():SetTextColor(0.5, 0.5, 0.5)
		end
	end
	if (ShowAllSpellRanksCheckbox and ShowAllSpellRanksCheckbox.Disable) then
		ShowAllSpellRanksCheckbox:Disable()
	end
	if (ShowAllSpellRanksCheckboxText and ShowAllSpellRanksCheckboxText.SetTextColor) then
		ShowAllSpellRanksCheckboxText:SetTextColor(0.5, 0.5, 0.5)
	end
	ModernSpellBookFrame.ShowPassiveSpellsCheckBox:Disable()
	ModernSpellBookFrame.ShowPassiveSpellsCheckBox.text:SetTextColor(0.5, 0.5, 0.5)
	ModernSpellBookFrame.nextPage:Disable()
	ModernSpellBookFrame.previousPage:Disable()
	if (ModernSpellBookFrame.searchBar.Disable) then
		ModernSpellBookFrame.searchBar:Disable()
	end
end

ModernSpellBookFrame.PLAYER_REGEN_ENABLED = function(self)
	if (ModernSpellBookFrame.isFirstLoad) then return end

	for _, tab in ipairs(ModernSpellBookFrame.Tabgroups) do
		tab:Enable()
		if (tab:GetNormalTexture().SetDesaturated) then
			tab:GetNormalTexture():SetDesaturated(false)
		end
		tab:SetDefaultFontColor()
	end
	if (ShowAllSpellRanksCheckbox and ShowAllSpellRanksCheckbox.Enable) then
		ShowAllSpellRanksCheckbox:Enable()
	end
	if (ShowAllSpellRanksCheckboxText and ShowAllSpellRanksCheckboxText.SetTextColor) then
		ShowAllSpellRanksCheckboxText:SetTextColor(1, 0.82, 0)
	end
	ModernSpellBookFrame.ShowPassiveSpellsCheckBox:Enable()
	ModernSpellBookFrame.ShowPassiveSpellsCheckBox.text:SetTextColor(1, 0.82, 0)
	if (ModernSpellBookFrame.searchBar.Enable) then
		ModernSpellBookFrame.searchBar:Enable()
	end

	local currentPage = ModernSpellBookFrame.currentPage
	if (currentPage <= 1) then
		ModernSpellBookFrame.previousPage:Disable()
	else
		ModernSpellBookFrame.previousPage:Enable()
	end
	if (currentPage >= ModernSpellBookFrame.maxPages) then
		ModernSpellBookFrame.nextPage:Disable()
	else
		ModernSpellBookFrame.nextPage:Enable()
	end
end
