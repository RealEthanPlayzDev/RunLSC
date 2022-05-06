--[[
File name: LoadstringHelper.lua
Author: RadiatedExodus (ItzEthanPlayz_YT/RealEthanPlayzDev)
Created at: May 6, 2022

A loadstring helper that uses either Roblox's provided loadstring if available,
or Yueliang (compiler) + FiOne (interpreter) for running lua(u) code
--]]

local FiOne, Yueliang = require(script:WaitForChild("FiOne")), require(script:WaitForChild("Yueliang"))
local LoadstringEnabled = ({pcall(loadstring, "local a = 1")})[1]
return function(src: string, chunkname: string?, env: {[string]: any}?): ((...any) -> (...any))
    if LoadstringEnabled then
        --// Compiling
        local CompileResult = loadstring(src, chunkname)

        --// Setting environment
        if typeof(env) == "table" then
            setfenv(CompileResult, env)
        end

        --// Return result
        return CompileResult
    else
        --// Environment preparation
        if typeof(env) ~= "table" then
            env = getfenv(1)
            env.script = nil
        end

        --// Compiling
        local CompileSuccess, CompileResult = pcall(function()
            return FiOne.wrap_state(FiOne.bc_to_state(Yueliang(src, chunkname or "loadstring")), env)
        end)

        --// Return result
        return function(...)
            assert(CompileSuccess, CompileResult)
            return CompileResult(...)
        end
    end
end