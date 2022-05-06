# RunLuaSourceContainer (shortened, RunLSC)
This is a simple Roblox Studio plugin for running LuaSourceContainer(s) (excluding CoreScript instances), I wrote this because I could not find a feature where you can select multiple scripts and click a button to simulate running them.

## Limitations
- If loadstring is not available, then it will fall back to using Yueliang + FiOne for code execution, otherwise it will use Roblox’s provided loadstring.

## Credits
- FiOne - Fall-back interpreter if Roblox's provided ``loadstring()`` is not available
- Yueliang - Fall-back bytecode compiler if Roblox's provided ``loadstring()`` is not available

## Acknowledgements
- Rerumu
- Authors of Yueliang
