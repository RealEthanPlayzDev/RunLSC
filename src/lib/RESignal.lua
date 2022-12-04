--[[
File name: RESignal.luau
Author: RadiatedExodus (RealEthanPlayzDev/ItzEthanPlayz_YT)
Created at: February 17, 2022
Version: 2.0.0

A signal implementation in Luau
--]]

local SignalBehavior = {
	NewThread = "SignalBehavior.NewThread";
	Deferred = "SignalBehavior.Deferred";
	Synced = "SignalBehavior.Synced";
}

table.freeze(SignalBehavior)

local SignalBehaviorHandler = {
	[SignalBehavior.NewThread] = function(callback: (...any) -> (...any), ... : any)
		task.spawn(callback, ...)
	end;
	[SignalBehavior.Deferred] = function(callback: (...any) -> (...any), ... : any)
		task.defer(callback, ...)
	end;
	[SignalBehavior.Synced] = function(callback: (...any) -> (...any), ... : any)
		local Ret = {pcall(callback, ...)}
		local Success = table.remove(Ret, 1)
		if not Success then
			task.spawn(error, Ret[1])
		end
	end;
}

local RESignalConnection = {}
RESignalConnection.__index = RESignalConnection
RESignalConnection.__tostring = function() return "RESignalConnection" end
RESignalConnection.__metatable = "This metatable is locked"

function RESignalConnection:Disconnect()
	if not self.Connected then return end
	self.Connected = false
	self.__RESignal.__ConnectedConnections[self] = nil
	return
end

local function constructor_RESignalConnection(resignal, f: (...any) -> ())
	local Connection = setmetatable({
		Connected = true;
		__Function = f;
		__RESignal = resignal;
	}, RESignalConnection)
	resignal.__ConnectedConnections[Connection] = true
	return Connection
end

local RESignal = {}
RESignal.__index = RESignal
RESignal.__tostring = function() return "RESignal" end
RESignal.__metatable = "This metatable is locked"

function RESignal:Fire(... : any)
	assert(typeof(SignalBehaviorHandler[self.__SignalBehavior]) == "function", "invalid SignalBehavior")
	for connection, connected in pairs(self.__ConnectedConnections) do
		if not connected then continue end
		SignalBehaviorHandler[self.__SignalBehavior](connection.__Function, ...)
	end
	return
end

function RESignal:Connect(f: (...any) -> ())
	assert(not self.__Destroyed, "signal destroyed")
	return constructor_RESignalConnection(self, f)
end

function RESignal:ConnectOnce(f: (...any) -> ())
	assert(not self.__Destroyed, "signal destroyed")
	local Connection; Connection = self:Connect(function(...)
		Connection:Disconnect()
		return f(...)
	end)
	return Connection
end

function RESignal:Wait()
	assert(not self.__Destroyed, "signal destroyed")
	local CurrentThread = coroutine.running()
	self:ConnectOnce(function(...)
		coroutine.resume(CurrentThread, ...)
	end)
	return coroutine.yield()
end

function RESignal:DisconnectAll()
	for connection, connected in pairs(self.__ConnectedConnections) do
		if not connected then continue end
		connection:Disconnect()
	end
	return
end

function RESignal:SetSignalBehavior(signalbehavior)
	self.__SignalBehavior = SignalBehavior
	return
end

function RESignal:Destroy()
	if self.__Destroyed then return end
	self.__Destroyed = true
	self:DisconnectAll()
	return
end

local function constructor_RESignal(signalbehavior)
	return setmetatable({
		__Destroyed = false;
		__ConnectedConnections = {};
		__SignalBehavior = if signalbehavior then signalbehavior else SignalBehavior.NewThread;
	}, RESignal)
end
return setmetatable({new = constructor_RESignal, SignalBehavior = SignalBehavior}, {__call = function(_, ...) return constructor_RESignal(...) end})