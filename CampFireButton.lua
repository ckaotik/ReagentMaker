local addonName, A = ...

local CAMPFIRE_ID = 818
local COOKING_ID = 2550
local btn
local cookingName
local CooldownFrame_SetTimer = CooldownFrame_SetTimer
local GetSpellCooldown = GetSpellCooldown

-- The cooldown info is not directly obtainable
local function WaitCooldown(self)
	local start, duration, enable = GetSpellCooldown(CAMPFIRE_ID)
	if start>0 then
		CooldownFrame_SetTimer(btn.cooldown,GetSpellCooldown(CAMPFIRE_ID))
		self:SetScript("OnUpdate",nil)
	end
end

-- Create button
function A.InitialiseCampFireBtn()
	if not GetTradeSkillLine() or InCombatLockdown() then return end

	-- Create the frame
	btn = CreateFrame("Button", nil, TradeSkillFrame, "SecureActionButtonTemplate")
	btn:SetNormalTexture(select(3,GetSpellInfo(CAMPFIRE_ID)))
	btn:SetHighlightTexture("Interface\\BUTTONS\\ButtonHilight-Square")
	btn:SetSize(24,24)
	btn:SetPoint("BOTTOMRIGHT",TradeSkillFrame,"BOTTOMRIGHT",-10,179)

	-- Set the action
	btn:SetAttribute("type", "spell")
	btn:SetAttribute("spell", CAMPFIRE_ID)

	-- Set the tooltip
	btn:SetScript("OnEnter",function(self)
		GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT")
		GameTooltip:SetSpellByID(CAMPFIRE_ID)
		GameTooltip:Show()
	end)
	btn:SetScript("OnLeave",function() GameTooltip:Hide(); end)

	-- Add cooldown
	btn.cooldown = CreateFrame("Cooldown",nil,btn)
	btn.cooldown:SetAllPoints(btn)

	-- Check if recipe failed due to lack of campfire
	local campfireName = GetSpellInfo(CAMPFIRE_ID)
	local errorMsg
	btn:SetScript("OnEvent",function(self,event,arg1,arg2)
		if not errorMsg or errorMsg==LOCKED_WITH_ITEM then
			local i = GetTradeSkillSelectionIndex()
			if i and i>01 then
				errorMsg = LOCKED_WITH_ITEM:format(GetTradeSkillTools(GetTradeSkillSelectionIndex()))
			end
		end
		if event == "UNIT_SPELLCAST_SUCCEEDED" then
			if arg1 == "player" and arg2 == campfireName then
				self:SetScript("OnUpdate",WaitCooldown)
				--CooldownFrame_SetTimer(self.cooldown,GetSpellCooldown(CAMPFIRE_ID))
			end
		elseif arg1 == errorMsg and GetSpellCooldown(CAMPFIRE_ID)==0 then
			-- Flash the button if the user tried to cook something without fire
			self.cooldown:SetCooldown(0,0)
		end
	end)
end

-- Hide button
function A.HideCampFireBtn()
	if btn then
		btn:Hide()
		btn:UnregisterAllEvents()
	end
end

-- Show button if applicable
function A.ManageCampFireBtn()
	-- Display only if the tradeskill is Cooking
	if not cookingName then cookingName = GetSpellInfo(COOKING_ID) end
	if GetTradeSkillLine() ~= cookingName then
		if btn then btn:Hide(); btn:UnregisterAllEvents() end
	else
		-- create button if necessary
		if not btn then
			A.InitialiseCampFireBtn()
		end
		-- It may not have been created
		if not btn then return end
		btn:Show()
		btn:RegisterEvent("UI_ERROR_MESSAGE")
		btn:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
		CooldownFrame_SetTimer(btn.cooldown,GetSpellCooldown(CAMPFIRE_ID))
	end
end
