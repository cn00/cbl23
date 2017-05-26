
cc.FileUtils:getInstance():setPopupNotify(false)

require "config"
require "cocos.init"

print("searching paths:")
for k,v in pairs(cc.FileUtils:getInstance():getSearchPaths()) do
	print(k,v)
end

local function main()
    require("app.MyApp"):create():run()
end

local status, msg = xpcall(main, __G__TRACKBACK__)
if not status then
    print(msg)
end
