
require "com.interaction.TouchMove"

local MainScene = class("MainScene", cc.load("mvc").ViewBase)

local sqlite3 = require("sqlite3")
local sq3 = sqlite3
-- local i = 0
-- for k,v in pairs(getmetatable(sqlite3)) do
--   print(i, k,v)
--   i = i+1
-- end

local db = sq3.open("test.sqlite3")

local errno, errmsg = db:exec([[
  CREATE TABLE `nodes` (
    `id`  INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT UNIQUE,
    `uid` INTEGER UNIQUE,
    `rotation_x`  NUMERIC,
    `rotation_y`  NUMERIC,
    `rotationZ_x` NUMERIC,
    `rotationZ_y` NUMERIC,
    `scale_x` NUMERIC,
    `scale_y` NUMERIC,
    `scale_z` NUMERIC,
    `position_x`  NUMERIC,
    `position_y`  NUMERIC,
    `position_z`  NUMERIC,
    `skew_x`  NUMERIC,
    `skew_y`  NUMERIC,
    `local_z` NUMERIC,
    `global_z`  INTEGER,
    `parent`  INTEGER,
    `tag` INTEGER,
    `name`  TEXT,
    `description`  TEXT,
    `visible` INTEGER,
    `displayOpacity`  INTEGER,
    `realOpacity` INTEGER
  );
]])
print("warning", errno, errmsg)

function MainScene.testMenuOnclick(tag, sender)
  local menu = cc.Menu:create()
    :move(display.center_top.x, display.center_top.y-30)
    -- :addTo(cc.Director:getInstance():getRunningScene())
    :addTo(sender.root)
  menu:setAnchorPoint(cc.p(0,0))

  print(getmetatable(sender.root))

  cc.MenuItemFont:setFontSize(26)
  local  item1 = cc.MenuItemFont:create("SQLITE-----999")
  item1:registerScriptTapHandler(MainScene.testMenuOnclick)
  item1:setAnchorPoint(cc.p(0,0))
  item1.root=sender.root
  menu:addChild(item1)

  menu:alignItemsVerticallyWithPadding(10)
  menu:alignItemsVertically() -- default = 5

  -- assert( db:exec ("CREATE TABLE test (col1, col2, col3)"))
  assert( db:exec ([[ 
    CREATE TABLE `test` (
      `id`   INTEGER PRIMARY KEY AUTOINCREMENT UNIQUE,
      `col1` TEXT,
      `col2` TEXT,
      `col3` TEXT
    );
  ]]))
  db:exec ("CREATE UNIQUE INDEX u_index_1 ON test (col1)")

  db:exec ("INSERT INTO test (col1,col2,col3) VALUES (11, 2, 1)", function ( ctx, ncols, values, names )
    print(" ------ exec INSERT INTO test (col1,col2,col3) callback", ctx, ncols, values, names)
    return sqlite3.OK
  end)

  db:exec ("INSERT INTO test (col1,col2,col3) VALUES (12, 3, 4)" )
  db:exec ("INSERT INTO test (col1,col2,col3) VALUES (13, 3, 6)" )
  db:exec ("INSERT INTO test (col1,col2,col3) VALUES (14, 3, 8)" )
  db:exec ("INSERT INTO test (col1,col2,col3) VALUES (15, 3, 10)")

  -- (fun_name, argc, func)
  db:create_function("my_sum2", 3, function(ctx, a, b, c)
    ctx:result_number( a + b * c )
  end)

  print("1: db:exec db_exec_callback with userdata, column, number, record {v, ...} and column names {k, ...} table")
  db:exec ("SELECT *, my_sum2(col1, col2, col3) FROM test", function ( udata, ncols, values, names )
    print(type(udata), udata, ncols, values, names) -- values names are reused tables
    return sqlite3.OK
  end, db)

  db:create_function("my_sum", 2, function(ctx, a, b)
    ctx:result_number( a + b )
  end)
  print("2: db:rows db_next_packed_row return {idx, v, ...} table")
  for row in db:rows("SELECT *, my_sum(col1, col2) FROM test") do
    print(row)
  end
  print("3: db:nrows db_next_named_row return {k=v, ...} table")
  for row in db:nrows("SELECT *, my_sum(col1, col2) FROM test") do
    print(row)
  end
  print("4: db:urows db_next_row return v ...")
  for c1, c2, c3, c4, c5 in db:urows("SELECT *, my_sum(col1, col2) FROM test") do
    print(c1, c2, c3, c4, c5)
  end
end

local ctrl_pressed = false
local alt_pressed = false
function MainScene:onCreate()
  local dispatcher = cc.Director:getInstance():getEventDispatcher()
  print("dispatcher:", dispatcher)

  -- 键盘
  local keyboardListener = cc.EventListenerKeyboard:create()
  self.keyboardListener = keyboardListener
  keyboardListener:registerScriptHandler( function ( keyCode, event )
    print("key pressed", keyCode, event)
    if keyCode == cc.KeyCode.KEY_J then

    elseif keyCode == cc.KeyCode.KEY_ALT then
      alt_pressed = true
    elseif keyCode == cc.KeyCode.KEY_CTRL then
      ctrl_pressed = true
    elseif keyCode == cc.KeyCode.KEY_S then
      if ctrl_pressed == true then
        print("self:save ...")
        self:save()
      end
    end
  end, cc.Handler.EVENT_KEYBOARD_PRESSED )
  keyboardListener:registerScriptHandler( function ( keyCode, event )
    print("key released", keyCode, getmetatable(event))
    if keyCode == cc.KeyCode.KEY_R then
      Hotfix.hotfix_module("app.views.MainScene")
      -- HU.Update()
    elseif keyCode == cc.KeyCode.KEY_ALT then
      alt_pressed = false
    elseif keyCode == cc.KeyCode.KEY_CTRL then
      ctrl_pressed = false
    end
  end, cc.Handler.EVENT_KEYBOARD_RELEASED )
  dispatcher:addEventListenerWithSceneGraphPriority(keyboardListener, self)

  -- 拖拽
  local movelistener = TouchMove:create()

  local menu = cc.Menu:create()
    :move(display.center)
    :addTo(self)
  menu:setAnchorPoint(cc.p(0,0))

  cc.MenuItemFont:setFontSize(16)
  local item1 = cc.MenuItemFont:create("SQLITE3")
  item1.root=self
  item1:registerScriptTapHandler(MainScene.testMenuOnclick)
  item1:setAnchorPoint(cc.p(0,0))
  dispatcher:addEventListenerWithSceneGraphPriority(movelistener, item1)
  menu:addChild(item1)
  -- menu:alignItemsVerticallyWithPadding(10)
  menu:alignItemsVertically() -- default = 5

  -- add HelloWorld label
  local label = cc.Label:createWithSystemFont("Hello World", "Arial", 20)
    :move(display.cx, display.top-20)
    :addTo(self)
  dispatcher:addEventListenerWithSceneGraphPriority(movelistener:clone(), label)

  -- 文件拖放
  local dropListener = cc.EventListenerCustom:create("APP.EVENT.DROP", function ( event )
    print(event)
    local filePath = event:getUserDataStr()
    filePath = string.gsub(filePath, "\\", "/")
    label:setString(filePath)
    print(filePath)
    local postfix = string.gsub(filePath,"^.*%.", "")
    local switch = {
      lua = function (  ) 
        local luarequirename = string.gsub(filePath,"^.*src/(.*)%.lua", "%1")
        luarequirename = string.gsub(luarequirename,"/", ".")
        print("luarequirename", luarequirename)
        if package.loaded[luarequirename] ~= nil then
          print("need reload .", luarequirename)
          package.loaded[luarequirename] = nil
          collectgarbage("collect")
        end
        require(luarequirename)
      end,
      png = function (  )
        local sprite = display.newSprite(filePath)
          :move(display.center)
          :addTo(self)
        dispatcher:addEventListenerWithSceneGraphPriority(movelistener:clone(), sprite)

        -- batch img?
        local twidth = 200
        local cellheight = 50
        local tableView = nil
        local plist = string.gsub(filePath, "...$", "plist")
        if cc.FileUtils:getInstance():isFileExist(plist) then
          print("plist ...")
          cc.SpriteFrameCache:getInstance():addSpriteFrames(plist)
          -- frames metadata
          local frames = cc.FileUtils:getInstance():getValueMapFromFile(plist)["frames"]
          print(frames)
          local frameList = {}
          for k, v in pairs(frames) do 
            table.insert(frameList, {key=k, value=v})
          end
          sprite:setSpriteFrame(frameList[1].key)

          print("frameList length:", #frameList)
          tableView = cc.TableView:create(cc.size(twidth, display.height - 20))
          tableView:setPosition(cc.p(display.width - twidth, 0))
          tableView:setAnchorPoint(cc.p(0, 0))
          tableView:setVerticalFillOrder(cc.TABLEVIEW_FILL_TOPDOWN)
          tableView:setDirection(cc.SCROLLVIEW_DIRECTION_VERTICAL)
          self:addChild(tableView)

          tableView:setDelegate()
          tableView:registerScriptHandler(function ( view, cell )
            cell:setScale(cell:getScaleX()*.99)
          end, cc.TABLECELL_HIGH_LIGHT)

          tableView:registerScriptHandler(function ( view, cell )
            cell:setScale(cell:getScaleX()/.99)
          end, cc.TABLECELL_UNHIGH_LIGHT)

          tableView:registerScriptHandler(function ( view, cell )
            local idx = cell:getIdx()
            print("cell touched: ", idx)
            sprite:setSpriteFrame( frameList[idx+1].key )
          end, cc.TABLECELL_TOUCHED)

          tableView:registerScriptHandler(function ( view, idx )
            return twidth, cellheight
          end, cc.TABLECELL_SIZE_FOR_INDEX)

          -- cell content
          tableView:registerScriptHandler(function ( view, idx )
            local cell = view:dequeueCell()
            if cell == nil then -- create
              cell = cc.TableViewCell:create()
              cell.icon = display.newSprite("#"..frameList[idx+1].key)
                -- :move(display.center)
                -- :scaleTo({scale=0.2})
                :align(cc.p(0,0), 0, 0)
                :addTo(cell)
              cell.icon:setScale(50/cell.icon:getContentSize().height)

              cell.name = cc.Label:createWithSystemFont(frameList[idx+1].key, "Arial", 10)
                :align(cc.p(0,0), 50, 0)
                :addTo(cell)

              cell.idx = cc.Label:createWithSystemFont(tostring(idx+1), "Arial", 30)
                :align(cc.p(0,0), 0, 0)
                :addTo(cell)
            else -- update
              cell.icon:setSpriteFrame(frameList[idx+1].key)
              cell.icon:setScale(50/cell.icon:getContentSize().height)
              cell.name:setString(frameList[idx+1].key)
              cell.idx:setString(tostring(idx+1))
            end
            return cell
          end, cc.TABLE_CELL_AT_INDEX)

          tableView:registerScriptHandler(function ( view )
            return #frameList
          end, cc.NUMBER_OF_CELLS_IN_TABLEVIEW)
          tableView:reloadData()
        end -- cc.FileUtils:getInstance():isFileExist(plist)

        local menu = cc.Menu:create()
          :move(display.right_top.x-twidth, display.right_top.y-20)
          :addTo(self)
        menu:setAnchorPoint(cc.p(0,0))

        cc.MenuItemFont:setFontSize(16)
        local  item1 = cc.MenuItemFont:create("CLOSE")
        item1:registerScriptTapHandler(function (sender)
            print("png CLOSE menuCallback")
            if tableView ~= nil then 
              tableView:removeFromParent() 
            end
            sprite:removeFromParent()
            menu:removeFromParent()
        end)
        item1:setAnchorPoint(cc.p(0,0))
        menu:addChild(item1)
      end, -- png
      json = function (  )
        local atlas = string.gsub(filePath, "....$", "atlas")
        print(filePath.." | "..atlas)
        local spine = sp.SkeletonAnimation:create(filePath, atlas, 1)
          :move(display.center_bottom)
          :addTo(self)
        -- spine:setTimeScale( 2 )
        spine:setScale(0.5)
        -- spine:setAnimation( 0, "walk", true )
        dispatcher:addEventListenerWithSceneGraphPriority(movelistener:clone(), spine)

        local animationList = spine:getAllAnimationNames()
        print("animation List length:", #animationList)
        local twidth = 150
        local cellheight = 80
        local tableView = cc.TableView:create(cc.size(twidth, display.height - 20))
        tableView:setPosition(cc.p(display.width - twidth, 0))
        tableView:setAnchorPoint(cc.p(0, 0))
        tableView:setVerticalFillOrder(cc.TABLEVIEW_FILL_TOPDOWN)
        tableView:setDirection(cc.SCROLLVIEW_DIRECTION_VERTICAL)
        self:addChild(tableView)

        tableView:setDelegate()
        tableView:registerScriptHandler(function ( view, cell )
          cell:setScale(cell:getScaleX()*.99)
        end, cc.TABLECELL_HIGH_LIGHT)

        tableView:registerScriptHandler(function ( view, cell )
          cell:setScale(cell:getScaleX()/.99)
        end, cc.TABLECELL_UNHIGH_LIGHT)

        tableView:registerScriptHandler(function ( view, cell )
          local idx = cell:getIdx()
          print("cell touched: ", idx)
          spine:setAnimation(0, animationList[idx+1], true)
        end, cc.TABLECELL_TOUCHED)

        tableView:registerScriptHandler(function ( view, idx )
          return twidth, cellheight
        end, cc.TABLECELL_SIZE_FOR_INDEX)

        -- cell content
        tableView:registerScriptHandler(function ( view, idx )
          local cell = view:dequeueCell()
          if cell == nil then -- create
            cell = cc.TableViewCell:create()
            cell.spine = sp.SkeletonAnimation:create(filePath, atlas, 1)
              -- :move(display.center_bottom)
              :align(cc.p(0,0), cellheight/2, 0)
              :addTo(cell)
            -- cell.spine:setScale(cellheight/cell.spine:getContentSize().height)
            cell.spine:setScale(0.3)
            cell.spine:setAnimation(0, animationList[idx+1], true)

            cell.name = cc.Label:createWithSystemFont(animationList[idx+1], "Arial", 10)
              :align(cc.p(0,0), cellheight, 0)
              :addTo(cell)

            cell.idx = cc.Label:createWithSystemFont(tostring(idx+1), "Arial", 30)
              :align(cc.p(0,0), 0, 0)
              :addTo(cell)
          else -- update
            cell.spine:setAnimation(0, animationList[idx+1], true)
            -- cell.spine:setScale(cellheight/cell.spine:getContentSize().height)
            cell.spine:setScale(0.3)
            cell.name:setString(animationList[idx+1])
            cell.idx:setString(tostring(idx+1))
          end
          return cell
        end, cc.TABLE_CELL_AT_INDEX)

        tableView:registerScriptHandler(function ( view )
          return #animationList
        end, cc.NUMBER_OF_CELLS_IN_TABLEVIEW)
        tableView:reloadData()

        local menu = cc.Menu:create()
          :move(display.right_top.x-twidth, display.right_top.y-20)
          :addTo(self)
        menu:setAnchorPoint(cc.p(0,0))

        cc.MenuItemFont:setFontSize(16)
        local  item1 = cc.MenuItemFont:create("CLOSE")
        item1:registerScriptTapHandler(function (sender)
            print("png CLOSE menuCallback")
            tableView:removeFromParent()
            spine:removeFromParent()
            menu:removeFromParent()
        end)
        item1:setAnchorPoint(cc.p(0,0))
        menu:addChild(item1)
      end -- json
    }
    switch.jpg=switch.png
    switch.skel=switch.json

    local case=switch[postfix]
    if case then 
      case(filePath)
    end
  end)
  dispatcher:addEventListenerWithFixedPriority(dropListener, 1)

  print("MainScene:onCreate", dispatcher, movelistener, keyboardListener, menu, label)
end

function MainScene:saveNode( node )
  -- node propertys
  -- local nodeId = node:getUID()
  -- assert(db:exec ( 
  --   "UPDATE `nodes` "
  --   .. " col1=" .. 13
  --   .. ",col2=" .. 14
  --   .. ",col3=" .. 15
  --   .. " WHERE id = " .. nodeId 
  -- ))
  local sqlcmd = 
    "REPLACE INTO `nodes` ("
    -- .." `id`"
    -- ..",`uid`"
    -- ..",`rotation_x`"
    -- ..",`rotation_y`"
    .." `rotationZ_x`"
    -- ..",`rotationZ_y`"
    ..",`scale_x`"
    ..",`scale_y`"
    ..",`scale_z`"
    ..",`position_x`"
    ..",`position_y`"
    ..",`position_z`"
    ..",`skew_x`"
    ..",`skew_y`"
    ..",`local_z`"
    ..",`global_z`"
    -- ..",`parent`"
    ..",`tag`"
    ..",`name`"
    ..",`description`"
    ..",`visible`"
    ..",`displayOpacity`"
    ..",`realOpacity`"
    ..") VALUES ("
    -- .. "," .. node:getID()
    -- .. "," .. node:getUID()
    -- `rotation_x`  ..",".. node:getRotation()
    -- `rotation_y`  ..",".. node:getRotation()
    .." ".. node:getRotation()
    -- `rotationZ_y` NUMERIC,
    ..",".. node:getScaleX()
    ..",".. node:getScaleY()
    ..",".. node:getScaleZ()
    ..",".. node:getPositionX()
    ..",".. node:getPositionY()
    ..",".. node:getPositionZ()
    ..",".. node:getSkewX()
    ..",".. node:getSkewY()
    ..",".. node:getLocalZOrder()
    ..",".. node:getGlobalZOrder()
    -- ..",".. node:getParent():getUID()
    ..",".. node:getTag()
    -- ..",'".. string.gsub(node:getDescription(), "\"", "\\\"").."'"
    ..",'".. node:getName().."'"
    ..",'".. node:getDescription().."'"
    ..",'".. tostring(node:isVisible()).."'"
    ..",".. node:getDisplayedOpacity()
    ..",".. node:getOpacity()
    .. ");"
  local errno = assert(db:exec ( sqlcmd ) == sqlite3.OK)
  print("sqlcmd", db, errno, sqlcmd)

  -- children
  for k,v in pairs(node:getChildren()) do
    self:saveNode(v)
  end
end

function MainScene:save(  )
  self:saveNode(self)
end

function MainScene:onExit( ... )
  print("MainScene:onExit")
  assert(db:close())
end

return MainScene
