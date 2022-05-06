--[[
File name: ClientRunner.client.lua
Author: RadiatedExodus (ItzEthanPlayz_YT/RealEthanPlayzDev)
Created at: May 6, 2022

The client context runner for RunLSC
--]]

if game:GetService("RunService"):IsEdit() then return end
require(script.Parent.RunLSC_Plugin)(plugin)