if !SERVER then

targetname = ""
local targetkills = 0
local civkills = 0

local alive
local traitor

local revealed = false

--for painting
local x = 270
local y = ScrH() - 130

local w = 250
local h = 120

local function ReceiveTarget(um)
	targetname = um:ReadString()
end
usermessage.Hook( "hitman_newtarget", ReceiveTarget )

local function NoTarget(um)
    targetname = nil
end
usermessage.Hook( "hitman_notarget", NoTarget )

local function DisplayHitlistHUD()
	if targetname ~= nil and alive and traitor then
		--basic box
        draw.RoundedBox(8, x, y, w, h, Color(0, 0, 10, 200))
		draw.RoundedBox(8, x, y, w, 30, Color(200, 25, 25, 200))
		
		--Didn't mind using BadKings ShadowedText. For some reason stuff doesn't properly import. Got to clean up the bloody code at some point anyway.
		-- 26th June 2015: Still haven't, should get my lazy ass to do it some day
		
		--Target announcer
		draw.SimpleText(targetname, "TraitorState", x + 12, y+2, Color(0, 0, 0, 255))
        draw.SimpleText(targetname, "TraitorState", x + 10, y, Color(255, 255, 255, 255))
		--Stats
        draw.SimpleText("Killed Targets: " .. targetkills, "HealthAmmo", x + 12, y +42, Color(0, 0, 0, 255))
		draw.SimpleText("Killed Targets: " .. targetkills, "HealthAmmo", x + 10, y +40, Color(255, 255, 255, 255))
		
		draw.SimpleText("Killed Civilians: " .. civkills, "HealthAmmo", x + 12, y + 62, Color(0, 0, 0, 255))
        draw.SimpleText("Killed Civilians: " .. civkills, "HealthAmmo", x + 10, y + 60, Color(255, 255, 255, 255))
    end
end
hook.Add("HUDPaint", "DisplayHitlistHUD", DisplayHitlistHUD);
--Fetch stats
local function SetTargetKills(um)
    targetkills = um:ReadShort()
end
usermessage.Hook( "hitman_killed_targets", SetTargetKills )

local function SetCivKills(um)
    civkills = um:ReadShort()
end
usermessage.Hook( "hitman_killed_civs", SetCivKills )
--Fetch condition, so the Display can work properly
local function SetAlive(um)
    alive = um:ReadBool()
end
usermessage.Hook( "hitman_alive", SetAlive )

local function SetTraitor(um)
    traitor = um:ReadBool()
	if traitor then YouAreTraitor() end
	revealed = false
end
usermessage.Hook( "hitman_hitman", SetTraitor )

function YouAreTraitor()
    chat.AddText(Color(255, 0, 0), "You are a hitman, hired by a mysterious employer who wants a range of people dead. Avoid killing anyone other than the target or your employer will be ... unsatisfied.")
end

local function Disappointed(um)
    local punishment = um:ReadShort()
	if punishment == 2 then
	    chat.AddText(Color(255, 0, 0), "Your employer is very disappointed of your work and decided to activate the killswitch")
	elseif punishment == 1 and !revealed then
	    chat.AddText(Color(255, 0, 0), "As a result of breaking the contract with your employer he decided to blow your cover with an anonymous phone call.")
		revealed = true
	end
end
usermessage.Hook( "hitman_disappointed", Disappointed )

local function RevealHitman(um)
    nick = um:ReadString()
	chat.AddText(Color(0, 255, 0), "You receive a phonecall from an unknown number. As you accept the call you hear an old man saying: \"", Color(255, 0, 0), nick, Color(0, 255, 0), " is a hired killer! Kill him before he has the chance to murder someone innocent!\" ")
end
usermessage.Hook( "hitman_reveal", RevealHitman )

local function ReceiveRadarScan()
   local num_targets = net.ReadUInt(8)
   local hitmanscan = net.ReadBit() == 1

   if hitmanscan then
      RADAR.duration = 1
   else
      RADAR.duration = 30
   end
   
   RADAR.targets = {}
   for i=1, num_targets do
      local r = net.ReadUInt(2)

      local pos = Vector()
      pos.x = net.ReadInt(32)
      pos.y = net.ReadInt(32)
      pos.z = net.ReadInt(32)

      table.insert(RADAR.targets, {role=r, pos=pos})
   end

   RADAR.enable = true
   RADAR.endtime = CurTime() + RADAR.duration

   timer.Create("radartimeout", RADAR.duration + 1, 1,
                function() RADAR:Timeout() end)
end
net.Receive("TTT_Radar_Hitman", ReceiveRadarScan)

end