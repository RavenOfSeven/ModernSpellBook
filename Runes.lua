local FINGER_RUNES = {
    [132849] = {["spellID"] = 442893, ["name"] = "Arcane Specialization"},
    [132394] = {["spellID"] = 442876, ["name"] = "Axe Specialization"},
    [135641] = {["spellID"] = 442887, ["name"] = "Dagger Specialization"},
    [134952] = {["spellID"] = 459312, ["name"] = "Defense Specialization"},
    [132116] = {["spellID"] = 453622, ["name"] = "Feral Combat Specialization"},
    [132847] = {["spellID"] = 442894, ["name"] = "Fire Specialization"},
    [133832] = {["spellID"] = 442890, ["name"] = "Fist Weapon Specialization"},
    [132852] = {["spellID"] = 442895, ["name"] = "Frost Specialization"},
    [237537] = {["spellID"] = 442898, ["name"] = "Holy Specialization"},
    [133038] = {["spellID"] = 442881, ["name"] = "Mace Specialization"},
    [132848] = {["spellID"] = 442896, ["name"] = "Nature Specialization"},
    [135145] = {["spellID"] = 442892, ["name"] = "Pole Weapon Specialization"},
    [135490] = {["spellID"] = 442891, ["name"] = "Ranged Weapon Specialization"},
    [132851] = {["spellID"] = 442897, ["name"] = "Shadow Specialization"},
    [132223] = {["spellID"] = 442813, ["name"] = "Sword Specialization"},
    [132218] = {["spellID"] = 468759, ["name"] = "Tank Specialization"},
    -- TODO: Of course, two of these share an icon.. so the method breaks down... We must use a different property from within the rune data itself, but those arent very well documented..
    [135913] = {["spellID"] = 468762, ["name"] = "Meditation Specialization"},
    [135913] = {["spellID"] = 468758, ["name"] = "Healing Specialization"},
    -- Key here is itemEnchantmentID
    [7639] = {["spellID"] = 468762, ["name"] = "Meditation Specialization"},
    [7638] = {["spellID"] = 468758, ["name"] = "Healing Specialization"},
}
function ModernSpellBookFrame:GetEquipedRunes()
    -- Reset the filters to read all runes.
    C_Engraving.ClearExclusiveCategoryFilter()
    C_Engraving.EnableEquippedFilter(false)

    local equipmentCategories = C_Engraving.GetRuneCategories(true, true)
    if #equipmentCategories == 0 then return nil end

    local runeDictionary = {}
    for i = 1, #equipmentCategories do
        local equipmentCategoryID = equipmentCategories[i]
        local slotName = C_Item.GetItemInventorySlotInfo(equipmentCategoryID)

        local runes = C_Engraving.GetRunesForCategory(equipmentCategoryID, true)
        for k = 1, #runes do
            runeDictionary[runes[k].name] = {slotName = slotName, spellID = runes[k].learnedAbilitySpellIDs[1]}

            -- Finger runes don't save their learnedAbilitySpellIDs properly, so we have to hardcode them...
            if slotName == FINGER0SLOT then
                -- We must only show the runes that have been equipped on the character.
                runeDictionary[runes[k].name]["iconTexture"] = runes[k].iconTexture
                if runes[k].iconTexture == 135913 then
                    runeDictionary[runes[k].name]["spellID"] = FINGER_RUNES[runes[k].itemEnchantmentID]["spellID"]
                else
                    runeDictionary[runes[k].name]["spellID"] = FINGER_RUNES[runes[k].iconTexture]["spellID"]
                end
                local isEquipped = C_Engraving.IsRuneEquipped(runes[k].skillLineAbilityID)
                runeDictionary[runes[k].name]["isEquipped"] = isEquipped
            end
        end
    end

    return runeDictionary
end
