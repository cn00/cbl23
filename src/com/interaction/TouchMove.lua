
cc.exports.TouchMove = class("TouchMove")

function TouchMove:create( ... )
  local movelistener = cc.EventListenerTouchOneByOne:create()
  movelistener:setSwallowTouches(true)
  movelistener:registerScriptHandler(function (touch, event)
    local target = event:getCurrentTarget()
    local rect = target:getBoundingBox()
    if cc.rectContainsPoint(rect, touch:getLocation()) then
      target:setScale(target:getScaleX()*0.99)
      target:setGlobalZOrder(target:getGlobalZOrder()+10000)
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
  -- movelistener:retain() -- if no Node bind this listener then need retain it
  return movelistener
end