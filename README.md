# RunLuaSourceContainer (shortened, RunLSC)
This is a simple Roblox Studio plugin for running LuaSourceContainer(s) (excluding CoreScript instances), I wrote this because I could not find a feature where you can select multiple scripts and click a button to simulate running them.

## Limitations
- ~~If loadstring is not available, then it will fall back to using Yueliang + FiOne for code execution, otherwise it will use Roblox’s provided loadstring.~~ No longer applicable if using any version newer than 1.2

## TODOs
- [x] Implement a way to load scripts and run them on the client natively (already found a way, just needs implementation)
- [x] Ability to run a script on the server while being on the client context and the way around
- [ ] Settings manager and ui
- [ ] Built-in script executor for replacing command bar?

## Credits
- FiOne - Fall-back interpreter if Roblox's provided ``loadstring()`` is not available
- Yueliang - Fall-back bytecode compiler if Roblox's provided ``loadstring()`` is not available

## Acknowledgements
- Rerumu
- Authors of Yueliang
