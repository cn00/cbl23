-- package.path=package.path..";src\\?.lua"
print("begin main.lua", package.path)
local i=0;for k,v in pairs(_G)do print(i,k,tostring(v)) i=i+1 end

require ("config")
print("main.lua config")

cc.FileUtils:getInstance():setPopupNotify(false)

function objdump(obj, breakline)
    local getIndent, quoteStr, wrapKey, wrapVal, dumpObj, resetObj
    getIndent = function(level)
        if breakline == nil or breakline == true then
            if level > 0 then
                return string.rep("|   ", level-1).."|---"
            else
                return ""
            end
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
    resetObj = function ( lobj )
        for k, v in pairs(lobj) do
            if type(v) == "table" and v.dumped ~= nil then
                -- _G.gprint("reset:"..tostring(v))
                v.dumped = nil
                resetObj(v)
            end
        end
    end
    dumpObj = function(lobj, level)
        if type(lobj) ~= "table" then
            return wrapVal(lobj)
        end

        level = level + 1
        for k, v in pairs(lobj) do
            if type(v) == "table" then
                if v.dumped ~= true then
                    v.dumped = true
                    _G.gprint( getIndent(level) .. wrapKey(k) .. "{"  .. tostring(v))
                    dumpObj(v, level)
                else
                    _G.gprint( getIndent(level) .. wrapKey(k) .. "nested " .. tostring(v))
                end
            elseif k ~= "dumped" then
                _G.gprint( getIndent(level) .. wrapKey(k) .. wrapVal(v, level) .. "," )
            end
        end
        _G.gprint( getIndent(level - 1) .. "}," )
        return ""
    end
    _G.gprint( getIndent(0) .. "{")
    local ret = dumpObj(obj, 0)
    resetObj(obj)
    return ret
end

_G.gprint=_G.print
local function localprint( ... )
    local args = {...}
    if #args > 1 or (type(args[1]) ~= "string" and type(args[1]) ~= "number") then
        gprint(objdump(args, true))
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

function warning( condition, msg )
    if not condition then
        __G__TRACKBACK__(msg)
    end
end

Hotfix = require "hotfix"

print("main.lua hotupdatelist")

require ("cocos.init")
print("main.lua cocos.init")

local function main()
    print("main.lua main()")

    collectgarbage("collect")
    -- avoid memory leak
    collectgarbage("setpause", 100)
    collectgarbage("setstepmul", 5000)                                             

    require("app.MyApp"):create():run()
end

print("main.lua end")
local status, msg = xpcall(main, __G__TRACKBACK__)
if not status then
    print(msg)
end
