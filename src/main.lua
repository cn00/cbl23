require "config"

cc.FileUtils:getInstance():setPopupNotify(false)

function objdump(obj, breakline)
    local getIndent, quoteStr, wrapKey, wrapVal, dumpObj
    getIndent = function(level)
        if breakline == nil or breakline == true then
            return string.rep("\t", level)
        else
            return ""
        end
    end
    quoteStr = function(str)
        return '"' .. string.gsub(str, '"', '\"') .. '"'
    end
    wrapKey = function(val)
        if type(val) == "number" then
            if breakline ~= false then
                return "[" .. val .. "] = "
            else
                return ""
            end
        elseif type(val) == "string" then
            return "[" .. quoteStr(val) .. "] = "
        else
            return "[" .. tostring(val) .. "] = "
        end
    end
    wrapVal = function(val, level)
        if type(val) == "table" then
            return dumpObj(val, level)
        elseif type(val) == "number" then
            return val
        elseif type(val) == "string" then
            return quoteStr(val)
        else
            return tostring(val)
        end
    end
    dumpObj = function(obj, level)
        if type(obj) ~= "table" then
            return wrapVal(obj)
        end
        level = level + 1
        local tokens = {}
        tokens[#tokens + 1] = "{"
        for k, v in pairs(obj) do
            tokens[#tokens + 1] = getIndent(level) .. wrapKey(k) .. wrapVal(v, level) .. ","
        end
        tokens[#tokens + 1] = getIndent(level - 1) .. "}"
        if breakline == nil or breakline == true then
            return table.concat(tokens, "\n")
        else
            return table.concat(tokens, " ")
        end
    end
    return dumpObj(obj, 0)
end

_G.gprint=_G.print
local function localprint( ... )
    local args = {...}
    if #args > 1 or (type(args[1]) ~= "string" and type(args[1]) ~= "number") then
        gprint(objdump(args, false))
    else
        gprint(args[1])
    end
end

_G.print=function( ... )
    if DEBUG > 1 then
        localprint( ... )
    end
end
function cnlog( ... )
    if DEBUG > 0 then
        localprint( ... )
    end
end

print("searching paths:")
for k,v in pairs(cc.FileUtils:getInstance():getSearchPaths()) do
	print(k,v)
end

HU = require "luahotupdate"
--please replace the second parameter with you src path
HU.Init("hotupdatelist", {"F:\\23\\clua\\src"}) 

require "cocos.init"

local function main()
    collectgarbage("collect")
    -- avoid memory leak
    collectgarbage("setpause", 100)
    collectgarbage("setstepmul", 5000)                                             

    require("app.MyApp"):create():run()
end

local status, msg = xpcall(main, __G__TRACKBACK__)
if not status then
    print(msg)
end
