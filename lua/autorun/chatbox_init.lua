AddCSLuaFile()

if SERVER then
	include("chatbox/init.lua")
else
	include("chatbox/cl_init.lua")
end