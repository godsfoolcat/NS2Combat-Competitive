
local kBackgroundColor = Color(0.0, 0.0, 0.0, 0.5)
local kChatTextPadding = 12
local cutoffAmount = Client.GetOptionInteger("chat-wrap", 25)
local kBackgroundTimeStartFade = 1.5


-- needed by shine because it's bad at recursing
local kOffset = debug.getupvaluex(GUIChat.Update, "kOffset")

debug.setupvaluex( GUIChat.AddMessage, "cutoffAmount", cutoffAmount, true)

local oldUpdate = GUIChat.Update
function GUIChat:Update(deltaTime)
	oldUpdate(self, deltaTime)
	
	-- need a reference here so shine can get this value
	kOffset = kOffset
	
    for i, message in ipairs(self.messages) do
		if message["Time"] then
			local fadeAmount = Clamp(kBackgroundTimeStartFade - message["Time"] / kBackgroundTimeStartFade, 0, 1)
			local currentColor = message["Background"]:GetColor()
			currentColor.a = fadeAmount * kBackgroundColor.a
			message["Background"]:SetColor(currentColor)
		end
	end
end

local oldAddMessage = GUIChat.AddMessage
function GUIChat:AddMessage(playerColor, playerName, messageColor, messageText, isCommander, isRookie)
	oldAddMessage(self, playerColor, playerName, messageColor, messageText, isCommander, isRookie)
	
	if self.messages and #self.messages > 0 then
		local insertMessage = self.messages[#self.messages]
		if insertMessage then
			local cutoff = Client.GetScreenWidth() * (cutoffAmount/100)
			local size = insertMessage["Background"]:GetSize()
			insertMessage["Background"]:SetSize(Vector(cutoff + GUIScale(kChatTextPadding), size.y, 0))
			insertMessage["Background"]:SetColor(kBackgroundColor)
		end
	end
	
end
