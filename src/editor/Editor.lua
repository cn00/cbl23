
local Editor = class("Editor", cc.load("mvc").ViewBase)

local sq3 = sqlite3
local targetObj = nil

function Editor:onCreate()
  local dispatcher = cc.Director:getInstance():getEventDispatcher()

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
    print("key released", keyCode, event:getmetadata())
    if keyCode == cc.KeyCode.KEY_R then
      HU.Update("MainScene")
      -- HU.Update()
    elseif keyCode == cc.KeyCode.KEY_ALT then
      alt_pressed = false
    elseif keyCode == cc.KeyCode.KEY_CTRL then
      ctrl_pressed = false
    end
  end, cc.Handler.EVENT_KEYBOARD_RELEASED )
  dispatcher:addEventListenerWithSceneGraphPriority(keyboardListener, self)

  local menu = cc.Menu:create()
    :move(display.center)
    :addTo(self)
  menu:setAnchorPoint(cc.p(0,0))


  cc.MenuItemFont:setFontSize(16)
  local item1 = cc.MenuItemFont:create("SQLITE3")
  item1.self=self
  item1:registerScriptTapHandler(testMenuOnclick)
  item1:setAnchorPoint(cc.p(0,0))
  menu:addChild(item1)
  -- menu:alignItemsVerticallyWithPadding(10)
  menu:alignItemsVertically() -- default = 5

  -- 拖拽
  local movelistener = cc.EventListenerTouchOneByOne:create()
  movelistener:setSwallowTouches(true)
  movelistener:registerScriptHandler(function (touch, event)
      local target = event:getCurrentTarget()
      local rect = target:getBoundingBox()
      if cc.rectContainsPoint(rect, touch:getLocation()) then
        target:setScale(target:getScaleX()*0.99)
        target:setGlobalZOrder(target:getGlobalZOrder()+10000)
        targetObj = target
        return true
      else
        return false
      end
  end,cc.Handler.EVENT_TOUCH_BEGAN )
  movelistener:registerScriptHandler(function (touch, event)
      local target = event:getCurrentTarget()
      local posX,posY = target:getPosition()
      local delta = touch:getDelta()
      target:setPosition(cc.p(posX + delta.x, posY + delta.y))
  end,cc.Handler.EVENT_TOUCH_MOVED )
  movelistener:registerScriptHandler(function (touch, event)
      local target = event:getCurrentTarget()
      target:setScale(target:getScaleX()/0.99)
      target:setGlobalZOrder(target:getGlobalZOrder()-10000)
  end,cc.Handler.EVENT_TOUCH_ENDED )

  -- add HelloWorld label
  local label = cc.Label:createWithSystemFont("Hello World", "Arial", 20)
    :move(display.cx, display.top-20)
    :addTo(self)
  dispatcher:addEventListenerWithSceneGraphPriority(movelistener, label)

  -- 文件拖放
  local dropListener = cc.EventListenerCustom:create("APP.EVENT.DROP", function ( event )
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
          local frameList = {}
          for k, v in pairs(frames) do 
            table.insert(frameList, {key=k, value=v})
          end

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
end

return MainScene
