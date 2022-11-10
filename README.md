# RunLuaSourceContainer (shortened, RunLSC)
This is a simple Roblox Studio plugin for running LuaSourceContainer(s) (excluding CoreScript instances), I wrote this because I could not find a feature where you can select multiple scripts and click a button to simulate running them.

## Limitations
- ~~If loadstring is not available, then it will fall back to using Yueliang + FiOne for code execution, otherwise it will use Roblox’s provided loadstring.~~ No longer applicable if using any version newer than 1.2

## TODOs
- [x] Implement a way to load scripts and run them on the client natively (already found a way, just needs implementation)
- [x] Ability to run a script on the server while being on the client context and the way around
- [x] Settings manager
- [ ] Settings widget
- [ ] Built-in script executor for replacing command bar

## Credits
- [FiOne](https://github.com/Rerumu/FiOne) - Fall-back interpreter if Roblox's provided ``loadstring()`` is not available
- [Yueliang](https://web.archive.org/web/20201126191223/http://yueliang.luaforge.net/) - Fall-back bytecode compiler if Roblox's provided ``loadstring()`` is not available
- [Lucide](https://lucide.dev/)
- [Icon Picker Plugin](https://gitlab.com/koterahq/luciderblx/plugin)

## Acknowledgements
- Rerumu
- Authors of Yueliang
- Lucide community and contributors
- 7kayoh
