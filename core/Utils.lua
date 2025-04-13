local _, goldAccountBalance = ...

local L = goldAccountBalance.localization

function goldAccountBalance:PrintDebug(msg)
    if self.options["debug"] then
        local notfound = true

        for i = 1, NUM_CHAT_WINDOWS do 
            local name, _, _, _, _, _, shown, locked, docked, uni = GetChatWindowInfo(i)

            if name == "Debug" and docked ~= nil then
                _G['ChatFrame' .. i]:AddMessage(WrapTextInColorCode("Gold Account Balance (Debug): ", "ffFF8040") .. msg)
                notfound = false
                break
            end
        end

        if notfound then
            DEFAULT_CHAT_FRAME:AddMessage(WrapTextInColorCode("Gold Account Balance (Debug): ", "ffFF8040")  .. msg)
        end
	end
end