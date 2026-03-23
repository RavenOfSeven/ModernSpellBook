local totalSpellIconFrames = 0
local totalSpellCategoryFrames = 0

-- Uses global MSB_NEW_KEYWORD from MSB_SpellData.lua
local NEW_KEYWORD = MSB_NEW_KEYWORD
local SPELL_ICON_SIZE = 28
local TOTAL_SPELL_SIZE = 40
local SPELL_HORIZONTAL_SPACING = 150
local VERTICAL_SPACING = 50
local SECOND_PAGE_OFFSET = 510
local HORIZONTAL_OFFSET = 40
local SPELL_INSET = 20

function ModernSpellBookFrame:CleanPages() -- Hides all spell and category frames.
    for i = 1, totalSpellIconFrames do
        local spellFrame = ModernSpellBookFrame["Spell".. i]
        spellFrame:Hide()
    end

    for i = 1, totalSpellCategoryFrames do
        local categoryFrame = ModernSpellBookFrame["Category".. i]
        categoryFrame:Hide()
    end
end

function ModernSpellBookFrame:GetOrCreateCategory(i)
    local categoryFrame = ModernSpellBookFrame["Category".. i]
    if categoryFrame ~= nil then -- Search if category exists already
        return categoryFrame
    end

    totalSpellCategoryFrames = totalSpellCategoryFrames +1
    ModernSpellBookFrame["Category".. i] = CreateFrame("Frame", nil, ModernSpellBookFrame)
    categoryFrame = ModernSpellBookFrame["Category".. i]
    categoryFrame:SetWidth(450)
    categoryFrame:SetHeight(20)
    -- Spec icon next to category name
    categoryFrame.specIconFrame = CreateFrame("Frame", nil, categoryFrame)
    categoryFrame.specIconFrame:SetWidth(22)
    categoryFrame.specIconFrame:SetHeight(22)
    categoryFrame.specIconFrame:SetPoint("TOPLEFT", categoryFrame, "TOPLEFT", 10, 1)
    categoryFrame.specIconFrame:SetBackdrop({
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 8,
        insets = { left = 1, right = 1, top = 1, bottom = 1 }
    })
    categoryFrame.specIconFrame:SetBackdropBorderColor(0.6, 0.6, 0.6, 1)

    categoryFrame.specIcon = categoryFrame.specIconFrame:CreateTexture(nil, "OVERLAY")
    categoryFrame.specIcon:SetWidth(18)
    categoryFrame.specIcon:SetHeight(18)
    categoryFrame.specIcon:SetPoint("CENTER", categoryFrame.specIconFrame, "CENTER", 0, 0)
    categoryFrame.specIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

    categoryFrame.text = categoryFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    categoryFrame.text:SetPoint("LEFT", categoryFrame.specIconFrame, "RIGHT", 5, 0)
    categoryFrame.text:SetTextColor(0, 0, 0)
    categoryFrame.text:SetShadowOffset(0, 0)
    categoryFrame.text:SetFont("Fonts\\FRIZQT__.TTF", 17)

    categoryFrame.lightBorder = categoryFrame:CreateTexture(nil, "OVERLAY")
    categoryFrame.lightBorder:SetWidth(500)
    categoryFrame.lightBorder:SetHeight(90)
    categoryFrame.lightBorder:SetPoint("TOPLEFT", categoryFrame, "TOPLEFT", -170, 35)
    categoryFrame.lightBorder:SetTexture("Interface\\Glues\\Models\\UI_Tauren\\gradientcircle")
    categoryFrame.lightBorder:SetBlendMode("ADD")
    categoryFrame.lightBorder:SetDrawLayer("OVERLAY", -2)
    categoryFrame.lightBorder:SetAlpha(0.15)

    categoryFrame.separator = categoryFrame:CreateTexture(nil, "OVERLAY")
    categoryFrame.separator:SetWidth(400)
    categoryFrame.separator:SetHeight(10)
    categoryFrame.separator:SetPoint("TOPLEFT", categoryFrame, "TOPLEFT", 0, -30)
    categoryFrame.separator:SetTexture("Interface\\AddOns\\ModernSpellBook\\Assets\\separator")

    function categoryFrame:Set(categoryName, currentPageRows, page)
        categoryFrame.text:SetText(categoryName)

        -- Look up spec icon from talent tabs or spell tabs
        local specIconFound = false
        for t = 1, GetNumTalentTabs() do
            local tabName, tabIcon = GetTalentTabInfo(t)
            if tabName == categoryName then
                categoryFrame.specIcon:SetTexture(tabIcon)
                specIconFound = true
                break
            end
        end
        if not specIconFound then
            -- Try spell tabs
            local numTabs = GetNumSpellTabs and GetNumSpellTabs() or 4
            for t = 1, numTabs do
                local tabName, tabIcon = GetSpellTabInfo(t)
                if tabName == categoryName and tabIcon then
                    categoryFrame.specIcon:SetTexture(tabIcon)
                    specIconFound = true
                    break
                end
            end
        end
        if not specIconFound then
            categoryFrame.specIconFrame:Hide()
            categoryFrame.text:SetPoint("LEFT", categoryFrame.specIconFrame, "LEFT", 0, 0)
        else
            categoryFrame.specIconFrame:Show()
            categoryFrame.text:SetPoint("LEFT", categoryFrame.specIconFrame, "RIGHT", 5, 0)
        end

        categoryFrame:SetPoint("TOPLEFT", ModernSpellBookFrame, "TOPLEFT", HORIZONTAL_OFFSET +SECOND_PAGE_OFFSET*(page -1), -80 +currentPageRows *-VERTICAL_SPACING -5)
        categoryFrame:Show()
    end

    return categoryFrame
end

-- ============================================================
-- Set() helper functions (extracted from the monolithic Set())
-- ============================================================

local function SetClickHandler(spellFrame, spellInfo)
    spellFrame:SetScript("OnClick", function()
        if spellInfo.isUnlearned then return end
        if spellInfo.isPassive then return end
        if InCombatLockdown() then return end
        if spellInfo.isPetSpell then
            if spellInfo.castName then
                CastPetAction(spellInfo.castName)
                C_Timer.After(0.2, function()
                    if spellInfo.castName == nil then
                        UIErrorsFrame:AddMessage("ModernSpellBook: Warning - Pet spell ".. spellInfo.spellName.. " cannot be cast outside the pet action bar. Please drag the spell there.", 1.0, 0.1, 0.1, 1.0)
                        PlaySound("igQuestFailed")
                        return
                    end
                    local name, texture = GetPetActionInfo(spellInfo.castName)
                    spellFrame.icon:SetTexture(texture)
                end)
            else
                UIErrorsFrame:AddMessage("ModernSpellBook: Warning - Pet spell ".. spellInfo.spellName.. " cannot be cast outside the pet action bar. Please drag the spell there.", 1.0, 0.1, 0.1, 1.0)
                PlaySound("igQuestFailed")
            end
        else
            CastSpellByName(spellInfo.castName)
        end
    end)
end

local function SetTextContent(spellFrame, spellInfo)
    spellFrame.text:SetFont("Fonts\\FRIZQT__.TTF", ModernSpellBook_DB and ModernSpellBook_DB.fontSize or 11.5)
    spellFrame.icon:SetTexture(spellInfo.spellIcon)
    spellFrame.text:SetText(spellInfo.spellName)
    if spellInfo.isUnlearned and spellInfo.levelReq and spellInfo.levelReq > 0 then
        local rankText = spellInfo.spellRank or ""
        if rankText ~= "" then
            spellFrame.subText:SetText(rankText .. " (Lvl " .. spellInfo.levelReq .. ")")
        else
            spellFrame.subText:SetText("Lvl " .. spellInfo.levelReq)
        end
    else
        spellFrame.subText:SetText(spellInfo.spellRank)
    end
    spellFrame.spellID = spellInfo.spellID
    spellFrame.bookType = spellInfo.bookType
end

local function SetTextPosition(spellFrame, spellInfo)
    local nameHeight = 13
    if spellFrame.text.GetStringHeight then
        nameHeight = spellFrame.text:GetStringHeight()
    elseif spellFrame.text.GetHeight then
        nameHeight = spellFrame.text:GetHeight()
    end
    local subHeight = 0
    local hasSubText = (spellInfo.spellRank and spellInfo.spellRank ~= "")
        or (spellInfo.isUnlearned and spellInfo.levelReq and spellInfo.levelReq > 0)
    if hasSubText then
        subHeight = 11
    end
    local totalHeight = nameHeight + subHeight
    local yOffset = (SPELL_ICON_SIZE - totalHeight) / 2
    spellFrame.textGroup:ClearAllPoints()
    spellFrame.textGroup:SetPoint("TOPLEFT", spellFrame, "TOPLEFT", 36, -yOffset)
end

local function SetHighlights(spellFrame, spellInfo, isNew)
    local hl = ModernSpellBook_DB.highlights
    -- Learned spell glow/badge
    if isNew and not spellInfo.isPassive then
        if hl and hl.learnedGlow then
            spellFrame.newGlowFrame:ClearAllPoints()
            spellFrame.newGlowFrame:SetPoint("CENTER", spellFrame.icon, "CENTER", 0.5, 0)
            spellFrame.newGlowFrame:Show()
        else
            spellFrame.newGlowFrame:Hide()
        end
        if hl and hl.learnedBadge then
            spellFrame.newSpellBadge:Show()
        else
            spellFrame.newSpellBadge:Hide()
        end
    else
        spellFrame.newGlowFrame:Hide()
        spellFrame.newSpellBadge:Hide()
    end

    -- Available-to-learn glow/badge
    if spellInfo.isUnlearned and not spellInfo.isTalent and spellInfo.levelReq then
        local playerLevel = UnitLevel("player")
        local availKey = spellInfo.spellName .. (spellInfo.spellRank or "")
        local alreadySeen = ModernSpellBook_DB.seenAvailable and ModernSpellBook_DB.seenAvailable[availKey]
        if spellInfo.levelReq <= playerLevel and not alreadySeen and not spellInfo.talentBlocked then
            if hl and hl.availableGlow then
                spellFrame.availableGlowFrame:ClearAllPoints()
                spellFrame.availableGlowFrame:SetWidth(60)
                spellFrame.availableGlowFrame:SetHeight(60)
                spellFrame.availableGlowFrame:SetPoint("CENTER", spellFrame.icon, "CENTER", 0, 0)
                spellFrame.availableGlowFrame:Show()
            else
                spellFrame.availableGlowFrame:Hide()
            end
            if hl and hl.availableBadge then
                spellFrame.newBadge:Show()
            else
                spellFrame.newBadge:Hide()
            end
        else
            spellFrame.availableGlowFrame:Hide()
            spellFrame.newBadge:Hide()
        end
    else
        spellFrame.availableGlowFrame:Hide()
        spellFrame.newBadge:Hide()
    end
end

local function SetChatLinkHandler(spellFrame, spellInfo)
    spellFrame:SetScript("OnMouseDown", function()
        local button = arg1
        local isChatLink = IsModifiedClick and IsModifiedClick("CHATLINK") or IsShiftKeyDown()
        if isChatLink then
            if MacroFrameText and MacroFrameText.HasFocus and MacroFrameText:HasFocus() then
                if spellInfo.isPassive then return end
                if spellInfo.spellRank == "" then
                    ChatEdit_InsertLink(spellInfo.spellName)
                elseif spellInfo.spellRank ~= "" then
                    ChatEdit_InsertLink(spellInfo.spellName.. "(".. spellInfo.spellRank.. ")")
                end
            elseif spellInfo.isTalent then
                local chatlink = GetTalentLink(spellInfo.talentGrid[1], spellInfo.talentGrid[2])
                if chatlink then
                    ChatEdit_InsertLink(chatlink)
                else
                    ChatEdit_InsertLink(spellInfo.spellName)
                end
            else
                local spellLink = "|cff71d5ff|Hspell:".. spellInfo.spellID .. "|h[".. spellInfo.spellName .."]|h|r"
                ChatEdit_InsertLink(spellLink)
            end
        end
        return;
    end)
end

local function SetTooltipHandler(spellFrame, spellInfo, lookupString, isNew)
    spellFrame:SetScript("OnEnter", function()
        spellFrame.checkedGlow:SetAlpha(spellFrame.checkedGlow.checkedAlpha)

        -- Dismiss available-to-learn glow and badge on hover
        if spellFrame.availableGlowFrame:IsShown() then
            spellFrame.availableGlowFrame:Hide()
            spellFrame.newBadge:Hide()
            if not ModernSpellBook_DB.seenAvailable then
                ModernSpellBook_DB.seenAvailable = {}
            end
            local availKey = spellInfo.spellName .. (spellInfo.spellRank or "")
            ModernSpellBook_DB.seenAvailable[availKey] = true
        end

        if isNew then
            ModernSpellBook_DB.knownSpells[lookupString] = string.gsub(ModernSpellBook_DB.knownSpells[lookupString], NEW_KEYWORD, "")
            isNew = false
        end
        spellFrame.newGlowFrame:Hide()
        spellFrame.newSpellBadge:Hide()

        GameTooltip:SetOwner(spellFrame, "ANCHOR_RIGHT")
        if spellInfo.isUnlearned then
            local shownFullTooltip = false
            if spellInfo.isTalent and spellInfo.talentGrid and GameTooltip.SetTalent then
                pcall(function()
                    GameTooltip:SetTalent(spellInfo.talentGrid[1], spellInfo.talentGrid[2])
                    shownFullTooltip = true
                end)
            end
            if not shownFullTooltip then
                local rankText = spellInfo.spellRank or ""
                if rankText ~= "" then
                    GameTooltip:SetText(spellInfo.spellName .. " - " .. rankText, 1, 1, 1)
                else
                    GameTooltip:SetText(spellInfo.spellName, 1, 1, 1)
                end
                if spellInfo.description then
                    GameTooltip:AddLine(spellInfo.description, 1, 0.82, 0, true)
                end
            end
            if spellInfo.levelReq and spellInfo.levelReq > 0 then
                GameTooltip:AddLine("Requires Level " .. spellInfo.levelReq, 1, 0.2, 0.2)
            end
            if spellInfo.isTalent then
                GameTooltip:AddLine("Requires talent point.", 1, 0.82, 0)
            else
                GameTooltip:AddLine("Visit a class trainer to learn.", 1, 0.82, 0)
            end
        elseif not spellInfo.isTalent then
            if spellInfo.bookType then
                GameTooltip:SetSpell(spellInfo.spellID, spellInfo.bookType)
            else
                GameTooltip:SetSpellByID(spellInfo.spellID)
            end
        else
            if GameTooltip.SetTalent then
                GameTooltip:SetTalent(spellInfo.talentGrid[1], spellInfo.talentGrid[2])
            else
                local talentLink = GetTalentLink(spellInfo.talentGrid[1], spellInfo.talentGrid[2])
                if talentLink then
                    GameTooltip:SetHyperlink(talentLink)
                else
                    GameTooltip:SetText(spellInfo.spellName)
                end
            end
        end
        GameTooltip:Show()
    end)
end

local function SetCooldownAndDrag(spellFrame, spellInfo)
    if not spellInfo.isPassive and not spellInfo.isUnlearned then
        spellFrame:SetMovable(true)
        spellFrame:SetScript("OnDragStart", function()
            if InCombatLockdown() then return end
            if spellInfo.isPetSpell then
                PickupSpell(spellInfo.spellID, BOOKTYPE_PET)
            else
                PickupSpell(spellInfo.spellID, BOOKTYPE_SPELL)
            end
        end)
        spellFrame:SetScript("OnUpdate", function()
            local start, duration, enable
            if spellInfo.bookType then
                start, duration, enable = GetSpellCooldown(spellInfo.spellID, spellInfo.bookType)
            else
                start, duration, enable = GetSpellCooldown(spellInfo.spellName)
            end
            if start and spellFrame.cooldown then
                local cdFunc = CooldownFrame_SetTimer or CooldownFrame_Set
                if cdFunc then cdFunc(spellFrame.cooldown, start, duration, enable) end
            end
        end)
    else
        if spellFrame.cooldown then spellFrame.cooldown:Hide() end
        spellFrame:SetMovable(false)
        spellFrame:SetScript("OnUpdate", nil)
        spellFrame:SetScript("OnDragStart", nil)
    end
end

local function SetIconStyle(spellFrame, spellInfo)
    if spellInfo.isPassive then
        if SetPortraitToTexture then
            SetPortraitToTexture(spellFrame.icon, spellInfo.spellIcon)
        else
            spellFrame.icon:SetTexCoord(0.04, 0.96, 0.04, 0.96)
        end
        spellFrame.icon:SetVertexColor(1, 1, 1)
        spellFrame.tile:SetTexture("")
        spellFrame.tile:SetAlpha(0)
        spellFrame.fancyFrame:Hide()
        spellFrame.roundBorderFrame:Show()
        spellFrame.checkedGlow.checkedAlpha = 0
    else
        spellFrame.icon:SetTexture(spellInfo.spellIcon)
        spellFrame.icon:SetTexCoord(0.04, 0.96, 0.04, 0.96)
        spellFrame.icon:SetVertexColor(1, 1, 1)
        spellFrame.tile:SetAlpha(1)
        spellFrame.tile:SetWidth(SPELL_ICON_SIZE + 22)
        spellFrame.tile:SetHeight(SPELL_ICON_SIZE + 22)
        spellFrame.tile:SetPoint("TOPLEFT", spellFrame, "TOPLEFT", -3, 3)
        spellFrame.tile:SetTexture("Interface\\Spellbook\\UI-Spellbook-SpellBackground")
        spellFrame.tile:SetVertexColor(1, 1, 1, 1)
        spellFrame.roundBorderFrame:Hide()
        spellFrame.border:SetTexture("Interface\\AddOns\\ModernSpellBook\\Assets\\spellbook-frame")
        spellFrame.border:SetDrawLayer("OVERLAY", 1)
        spellFrame.border:SetVertexColor(1, 1, 1)
        spellFrame.checkedGlow.checkedAlpha = 0.5
    end
    spellFrame.icon.isPassive = spellInfo.isPassive
end

local function SetFancyFrame(spellFrame, spellInfo)
    if not spellFrame.fancyFrame then return end
    local showFrame = true
    if ModernSpellBook_DB and ModernSpellBook_DB.iconFrame then
        local isOtherTab = ModernSpellBookFrame.selectedTab and ModernSpellBookFrame.selectedTab > 2
        if spellInfo.isUnlearned then
            showFrame = ModernSpellBook_DB.iconFrame.unlearned
        elseif spellInfo.isPassive then
            showFrame = false -- passives use round border
        elseif isOtherTab then
            showFrame = ModernSpellBook_DB.iconFrame.other
        else
            showFrame = ModernSpellBook_DB.iconFrame.spells
        end
    end
    if showFrame then
        spellFrame.fancyFrame:Show()
    else
        spellFrame.fancyFrame:Hide()
    end
end

local function SetLearnedState(spellFrame, spellInfo)
    if spellInfo.isUnlearned then
        if spellFrame.icon.SetDesaturated then
            spellFrame.icon:SetDesaturated(true)
        else
            spellFrame.icon:SetVertexColor(0.4, 0.4, 0.4)
        end
        spellFrame.icon:SetAlpha(0.5)
        MSB_TextStyleInstance:ApplyToSpell(spellFrame.text, spellFrame.subText, spellFrame.lightBorder, "unlearned")
        if spellFrame.fancyFrame then
            local showUnlearnedFrame = ModernSpellBook_DB and ModernSpellBook_DB.iconFrame and ModernSpellBook_DB.iconFrame.unlearned
            if not showUnlearnedFrame then
                spellFrame.fancyFrame:Hide()
            else
                if spellFrame.border and spellFrame.border.SetDesaturated then
                    spellFrame.border:SetDesaturated(true)
                end
                spellFrame.border:SetAlpha(0.5)
            end
        end
        spellFrame.tile:SetAlpha(0.5)
        spellFrame.checkedGlow.checkedAlpha = 0
        spellFrame:SetMovable(false)
        spellFrame:SetScript("OnDragStart", nil)
        spellFrame:SetScript("OnUpdate", nil)
    else
        if spellFrame.icon.SetDesaturated then
            spellFrame.icon:SetDesaturated(false)
        end
        if spellFrame.border and spellFrame.border.SetDesaturated then
            spellFrame.border:SetDesaturated(false)
        end
        if spellFrame.border then spellFrame.border:SetAlpha(1) end
        spellFrame.icon:SetAlpha(1)
        spellFrame.tile:SetAlpha(1)
        MSB_TextStyleInstance:ApplyToSpell(spellFrame.text, spellFrame.subText, spellFrame.lightBorder, "normal")
    end
end

-- ============================================================

function ModernSpellBookFrame:GetOrCreateSpellFrame(i)
    local spellFrame = ModernSpellBookFrame["Spell".. i]
    if spellFrame ~= nil then
        return spellFrame
    end
    totalSpellIconFrames = totalSpellIconFrames +1
    -- Use regular Button instead of SecureActionButtonTemplate (doesn't exist in vanilla)
    ModernSpellBookFrame["Spell".. i] = CreateFrame("Button", "ModernSpellBookSpell"..i, ModernSpellBookFrame)
    spellFrame = ModernSpellBookFrame["Spell".. i]
    spellFrame:SetWidth(SPELL_ICON_SIZE)
    spellFrame:SetHeight(SPELL_ICON_SIZE)
    spellFrame:RegisterForClicks("LeftButtonUp", "RightButtonUp")

    spellFrame:SetScript("OnLeave", function()
        GameTooltip:Hide()
        spellFrame.checkedGlow:SetAlpha(0)
    end)

    spellFrame:SetMovable(true)
    spellFrame:RegisterForDrag("LeftButton")

    -- Text container - vertically centered on the icon
    spellFrame.textGroup = CreateFrame("Frame", nil, spellFrame)
    spellFrame.textGroup:SetWidth(98)
    spellFrame.textGroup:SetHeight(SPELL_ICON_SIZE)
    spellFrame.textGroup:SetPoint("LEFT", spellFrame, "LEFT", 36, 0)

    spellFrame.text = spellFrame.textGroup:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    spellFrame.text:SetPoint("TOPLEFT", spellFrame.textGroup, "TOPLEFT", 0, 0)
    if spellFrame.text.SetWordWrap then spellFrame.text:SetWordWrap(true) end
    spellFrame.text:SetWidth(98)
    spellFrame.text:SetJustifyH("LEFT")
    spellFrame.text:SetFont("Fonts\\FRIZQT__.TTF", ModernSpellBook_DB and ModernSpellBook_DB.fontSize or 11.5)
    if spellFrame.text.SetJustifyV then spellFrame.text:SetJustifyV("TOP") end

    -- Light border behind text area
    spellFrame.lightBorder = spellFrame:CreateTexture(nil, "ARTWORK")
    spellFrame.lightBorder:SetWidth(170)
    spellFrame.lightBorder:SetHeight(TOTAL_SPELL_SIZE)
    spellFrame.lightBorder:SetPoint("LEFT", spellFrame, "CENTER", 0, 0)
    spellFrame.lightBorder:SetTexture("Interface\\AddOns\\ModernSpellBook\\Assets\\spellbook-trail")
    spellFrame.lightBorder:SetAlpha(1)

    -- === SpellIcon container ===
    -- New spell glow (on top of everything)
    spellFrame.newGlowFrame, spellFrame.newGlow = MSB_CreateGlow(spellFrame, 60, nil, 15)

    -- "New" badge for newly learned spells
    spellFrame.newSpellBadge = MSB_CreateBadge(spellFrame, "New", {1, 0.878, 0.078, 0.7}, {1, 0.9, 0.1, 0.8}, 12)
    spellFrame.newSpellBadge:SetPoint("BOTTOM", spellFrame, "TOP", 0, 2)

    -- Layer 2: Tile/socket background
    spellFrame.tile = spellFrame:CreateTexture(nil, "ARTWORK")
    spellFrame.tile:SetWidth(SPELL_ICON_SIZE + 22)
    spellFrame.tile:SetHeight(SPELL_ICON_SIZE + 22)
    spellFrame.tile:SetPoint("CENTER", spellFrame, "CENTER", 0, 0)
    spellFrame.tile:SetTexture("Interface\\Spellbook\\UI-Spellbook-SpellBackground")

    -- Layer 3: The spell icon
    spellFrame.icon = spellFrame:CreateTexture(nil, "OVERLAY")
    spellFrame.icon:SetWidth(SPELL_ICON_SIZE)
    spellFrame.icon:SetHeight(SPELL_ICON_SIZE)
    spellFrame.icon:SetPoint("CENTER", spellFrame, "CENTER", 0, 0)
    spellFrame.icon:SetTexCoord(0.04, 0.96, 0.04, 0.96)

    -- Layer 4: Fancy frame overlay (in front of icon)
    spellFrame.fancyFrame = CreateFrame("Frame", nil, spellFrame)
    spellFrame.fancyFrame:SetWidth(60)
    spellFrame.fancyFrame:SetHeight(60)
    spellFrame.fancyFrame:SetPoint("CENTER", spellFrame, "CENTER", 0, 0)
    spellFrame.fancyFrame:SetFrameLevel(spellFrame:GetFrameLevel() + 3)
    spellFrame.fancyFrameTex = spellFrame.fancyFrame:CreateTexture(nil, "OVERLAY")
    spellFrame.fancyFrameTex:SetAllPoints(spellFrame.fancyFrame)
    spellFrame.fancyFrameTex:SetTexture("Interface\\AddOns\\ModernSpellBook\\Assets\\spellbook-frame")

    -- Keep old border reference for passive/active logic
    spellFrame.border = spellFrame.fancyFrameTex

    -- Round border for passive spells (hidden by default)
    spellFrame.roundBorderFrame = CreateFrame("Frame", nil, spellFrame)
    spellFrame.roundBorderFrame:SetWidth(56)
    spellFrame.roundBorderFrame:SetHeight(56)
    spellFrame.roundBorderFrame:SetPoint("CENTER", spellFrame.icon, "CENTER", 0, 0)
    spellFrame.roundBorderFrame:SetFrameLevel(spellFrame:GetFrameLevel() + 3)
    spellFrame.roundBorder = spellFrame.roundBorderFrame:CreateTexture(nil, "OVERLAY")
    spellFrame.roundBorder:SetAllPoints(spellFrame.roundBorderFrame)
    spellFrame.roundBorder:SetTexture("Interface\\AddOns\\ModernSpellBook\\Assets\\bluemenu-ring")
    spellFrame.roundBorderFrame:Hide()

    -- Layer 5: Hover highlight
    spellFrame.checkedGlowFrame, spellFrame.checkedGlow = MSB_CreateGlow(spellFrame, SPELL_ICON_SIZE, nil, 4, "Interface\\Buttons\\CheckButtonHilight")
    spellFrame.checkedGlowFrame:SetPoint("CENTER", spellFrame.icon, "CENTER", 0, 0)
    spellFrame.checkedGlowFrame:Show()
    spellFrame.checkedGlow:SetAlpha(0)
    spellFrame.checkedGlow.checkedAlpha = 0.5

    -- Layer 6: Cooldown (separate frame, on top)
    local cdType = COOLDOWN_FRAME_TYPE or "Model"
    local cdOk, cdFrame = pcall(CreateFrame, cdType, nil, spellFrame, "CooldownFrameTemplate")
    if not cdOk then
        cdOk, cdFrame = pcall(CreateFrame, "Cooldown", nil, spellFrame, "CooldownFrameTemplate")
    end
    if cdOk and cdFrame then
        spellFrame.cooldown = cdFrame
        spellFrame.cooldown:SetPoint("TOPLEFT", spellFrame.icon, "TOPLEFT", 0, 0)
        spellFrame.cooldown:SetPoint("BOTTOMRIGHT", spellFrame.icon, "BOTTOMRIGHT", 0, 0)
        if spellFrame.cooldown.SetDrawEdge then
            spellFrame.cooldown:SetDrawEdge(false)
        end
    else
        spellFrame.cooldown = nil
    end

    -- Rank/passive text inside the text group
    spellFrame.subText = spellFrame.textGroup:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    spellFrame.subText:SetPoint("TOPLEFT", spellFrame.text, "BOTTOMLEFT", 0, -1)
    spellFrame.subText:SetFont("Fonts\\FRIZQT__.TTF", 9.5)

    -- Apply initial text style (colors, shadows, blend mode)
    MSB_TextStyleInstance:ApplyToSpell(spellFrame.text, spellFrame.subText, spellFrame.lightBorder, "normal")
    spellFrame.subText:SetJustifyH("LEFT")
    if spellFrame.subText.SetWordWrap then spellFrame.subText:SetWordWrap(true) end
    spellFrame.subText:SetWidth(80)
    spellFrame.subText:SetHeight(10)

    -- Use a child frame so the glow always renders on top of the icon
    spellFrame.activeLightFrame = CreateFrame("Frame", nil, spellFrame)
    spellFrame.activeLightFrame:SetWidth(SPELL_ICON_SIZE + 2)
    spellFrame.activeLightFrame:SetHeight(SPELL_ICON_SIZE + 2)
    spellFrame.activeLightFrame:SetPoint("CENTER", spellFrame.icon, "CENTER", 0, 0)
    spellFrame.activeLightFrame:SetFrameLevel(spellFrame:GetFrameLevel() + 5)

    spellFrame.activeLight = spellFrame.activeLightFrame:CreateTexture(nil, "OVERLAY")
    spellFrame.activeLight:SetWidth(SPELL_ICON_SIZE + 2)
    spellFrame.activeLight:SetHeight(SPELL_ICON_SIZE + 2)
    spellFrame.activeLight:SetAllPoints(spellFrame.activeLightFrame)
    spellFrame.activeLight:SetTexture("Interface\\Buttons\\CheckButtonHilight")
    spellFrame.activeLight:SetBlendMode("ADD")
    spellFrame.activeLight:SetAlpha(0)

    -- Glow for unlearned spells that are now available to learn (tinted light blue)
    spellFrame.availableGlowFrame, spellFrame.availableGlow = MSB_CreateGlow(spellFrame, 60, {0.204, 0.765, 0.922}, 8)

    -- "Train" badge for available-to-learn spells
    spellFrame.newBadge = MSB_CreateBadge(spellFrame, "Train", {0, 0.8, 0, 0.4}, {0.1, 0.8, 0.1, 0.8}, 7)
    spellFrame.newBadge:SetPoint("BOTTOM", spellFrame.icon, "TOP", 0, 2)

    spellFrame.icon.isPassive = false

    function spellFrame:SetStance(isActive)
        spellFrame.activeLight:SetAlpha(isActive and 1 or 0)
    end

    function spellFrame:Set(spellInfo, currentPageRows, page, grid_x)
        SetClickHandler(spellFrame, spellInfo)
        SetTextContent(spellFrame, spellInfo)

        -- Stance detection
        local stanceState = false
        if spellInfo.stanceIndex ~= nil then
            local _, _, isActive = GetShapeshiftFormInfo(spellInfo.stanceIndex)
            stanceState = isActive
            ModernSpellBookFrame.stanceButtons[spellInfo.spellName] = spellFrame
        end
        spellFrame:SetStance(stanceState)

        SetTextPosition(spellFrame, spellInfo)

        -- Lookup for new spell detection
        local lookupString = spellInfo.spellName.. spellInfo.spellRank
        local knownSpell = ModernSpellBook_DB.knownSpells[lookupString]
        local isNew = knownSpell and string.find(knownSpell, NEW_KEYWORD) ~= nil

        SetHighlights(spellFrame, spellInfo, isNew)

        -- Position on page
        spellFrame:SetPoint("TOPLEFT", ModernSpellBookFrame, "TOPLEFT", HORIZONTAL_OFFSET +SPELL_INSET +SECOND_PAGE_OFFSET*(page -1) +grid_x *SPELL_HORIZONTAL_SPACING, -80 +currentPageRows *-VERTICAL_SPACING)

        SetChatLinkHandler(spellFrame, spellInfo)
        SetTooltipHandler(spellFrame, spellInfo, lookupString, isNew)
        SetCooldownAndDrag(spellFrame, spellInfo)

        spellFrame:Show()

        SetFancyFrame(spellFrame, spellInfo)
        SetIconStyle(spellFrame, spellInfo)
        SetLearnedState(spellFrame, spellInfo)
    end

    return spellFrame
end
