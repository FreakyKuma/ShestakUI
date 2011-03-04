local T, C, L = unpack(select(2, ...))
----------------------------------------------------------------------------------------
--	Based on oMirrorBars
----------------------------------------------------------------------------------------
if not C.unitframe.unit_castbar == true or not C.unitframe.enable == true then return end

local _, settings = ...

local _DEFAULTS = {
	width = 281,
	height = 16,
	texture = C.media.texture,

	position = {
		["BREATH"] = "TOP#UIParent#TOP#0#-96";
		["EXHAUSTION"] = "TOP#UIParent#TOP#0#-116";
		["FEIGNDEATH"] = "TOP#UIParent#TOP#0#-142";
	};

	colors = {
		EXHAUSTION = {1, 0.9, 0};
		BREATH = {0.31, 0.45, 0.63};
		DEATH = {1, 0.7, 0};
		FEIGNDEATH = {1, 0.7, 0};
	};
}

do
	settings = setmetatable(settings, {__index = _DEFAULTS})
	for k,v in next, settings do
		if(type(v) == "table") then
			settings[k] = setmetatable(settings[k], {__index = _DEFAULTS[k]})
		end
	end
end

local Spawn, PauseAll
do
	local barPool = {}

	local loadPosition = function(self)
		local pos = settings.position[self.type]
		local p1, frame, p2, x, y = strsplit("#", pos)

		return self:Point(p1, frame, p2, x, y)
	end

	local OnUpdate = function(self, elapsed)
		if(self.paused) then return end

		self:SetValue(GetMirrorTimerProgress(self.type) / 1e3)
	end

	local Start = function(self, value, maxvalue, scale, paused, text)
		if(paused > 0) then
			self.paused = 1
		elseif(self.paused) then
			self.paused = nil
		end

		self.text:SetText(text)

		self:SetMinMaxValues(0, maxvalue / 1e3)
		self:SetValue(value / 1e3)

		if(not self:IsShown()) then self:Show() end
	end

	function Spawn(type)
		if(barPool[type]) then return barPool[type] end
		local frame = CreateFrame("StatusBar", nil, UIParent)

		frame:SetScript("OnUpdate", OnUpdate)

		local r, g, b = unpack(settings.colors[type])

		local bg = frame:CreateTexture(nil, "BACKGROUND")
		bg:SetAllPoints(frame)
		bg:SetTexture(settings.texture)
		bg:SetVertexColor(r * 0.5, g * 0.5, b * 0.5)
		
		local border = CreateFrame("Frame", nil, frame)
		border:Point("TOPLEFT", frame, -2, 2)
		border:Point("BOTTOMRIGHT", frame, 2, -2)
		border:SetTemplate("Default")
		border:SetFrameLevel(0)

		local text = frame:CreateFontString(nil, "OVERLAY")
		text:SetFont(C.media.pixel_font, C.media.pixel_font_size, C.media.pixel_font_style)
		text:SetJustifyH("CENTER")
		text:SetShadowOffset(0, 0)
		text:SetTextColor(1, 1, 1)

		text:Point("LEFT", frame)
		text:Point("RIGHT", frame)
		text:Point("TOP", frame, 0, 1)
		text:Point("BOTTOM", frame)

		frame:Size(settings.width, settings.height)

		frame:SetStatusBarTexture(settings.texture)
		frame:SetStatusBarColor(r, g, b)

		frame.type = type
		frame.text = text

		frame.Start = Start
		frame.Stop = Stop

		loadPosition(frame)

		barPool[type] = frame
		return frame
	end

	function PauseAll(val)
		for _, bar in next, barPool do
			bar.paused = val
		end
	end
end

local frame = CreateFrame("Frame")
frame:SetScript("OnEvent", function(self, event, ...)
	return self[event](self, ...)
end)

function frame:ADDON_LOADED(addon)
	if(addon == "ShestakUI") then
		UIParent:UnregisterEvent("MIRROR_TIMER_START")

		self:UnregisterEvent("ADDON_LOADED")
		self.ADDON_LOADED = nil
	end
end
frame:RegisterEvent("ADDON_LOADED")

function frame:PLAYER_ENTERING_WORLD()
	for i=1, MIRRORTIMER_NUMTIMERS do
		local type, value, maxvalue, scale, paused, text = GetMirrorTimerInfo(i)
		if(type ~= "UNKNOWN") then
			Spawn(type):Start(value, maxvalue, scale, paused, text)
		end
	end
end
frame:RegisterEvent("PLAYER_ENTERING_WORLD")

function frame:MIRROR_TIMER_START(type, value, maxvalue, scale, paused, text)
	return Spawn(type):Start(value, maxvalue, scale, paused, text)
end
frame:RegisterEvent("MIRROR_TIMER_START")

function frame:MIRROR_TIMER_STOP(type)
	return Spawn(type):Hide()
end
frame:RegisterEvent("MIRROR_TIMER_STOP")

function frame:MIRROR_TIMER_PAUSE(duration)
	return PauseAll((duration > 0 and duration) or nil)
end
frame:RegisterEvent("MIRROR_TIMER_PAUSE")