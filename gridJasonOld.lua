--  
--   ////\\\\
--   ////\\\\  TUTORIAL
--   ////\\\\  PART 9
--   \\\\////
--   \\\\////  GRID
--   \\\\////
--

local g
local viewport = { width = 128, height = 64, frame = 0 }
local focus = { x = 1, y = 1, brightness = 15 }

-- TODO: should these be locals?
currentGrid = {}
prevGrid = {}
rowCount = 8
columnCount = 16
dampening = 1/16
-- Main

function init()
  connect()
  -- Render Style
  screen.level(15)
  screen.aa(0)
  screen.line_width(1)
  -- Render
  for i=1,rowCount do
    currentGrid[i] = {}     -- create a new row
    prevGrid[i] = {}
      for j=1,columnCount do
        currentGrid[i][j] = 0
        prevGrid[i][j] = 0
      end
    end
  init_params()
  step_clock_id = clock.run(step)
  update()    
end

function init_params()
    params:add_separator("ripley")
    params:add{type = "number", id = "step_div", name = "step division", min = 1, max = 32, default = 4}
    
end

function connect()
  g = grid.connect()
  g.key = on_grid_key
  g.add = on_grid_add
  g.remove = on_grid_remove
end

function is_connected()
  return g.device ~= nil
end

function on_grid_key(x,y,z)
  if z == 0 then
    focus.x = x
    focus.y = y
    -- print("we are triggering a note: " .. note_num .. " at freq: " .. freq)
    print("xy: " .. x ..",".. y)
    currentGrid[x][y] = 16
    prevGrid[x][y] = 16
    -- ripple()
    update_grid_leds()
    update()
  end
end

function update_grid_leds()
  for i=1,rowCount do
    for j=1,columnCount do
      g:led(i,j, currentGrid[i][j])
    end
  end
  g:refresh()  
end

function on_grid_add(g)
  print('on_add')
end

function on_grid_remove(g)
  print('on_remove')
end

function update()
  redraw()
end



function ripple()
  for i=1,rowCount do
      for j=1,columnCount do
        local left = 0
        local right = 0
        local top = 0
        local bottom = 0

        if i-1 > 0 then
          left = prevGrid[i-1][j]
        else
          left = prevGrid[i+1][j]
        end

        if i+1 < rowCount then
          right = prevGrid[i+1][j]
        else
          right = prevGrid[i-1][j]
        end
        
        if j+1 < columnCount then
          top = prevGrid[i][j+1]
        else
          top = prevGrid[i][j-1]
        end

        if j-1 > 0 then
          bottom = prevGrid[i][j-1]
        else
          bottom = prevGrid[i][j+1]
        end



        newVal = (left + right + top + bottom) / 4 - currentGrid[i][j]
        if newVal > 0 then
          print("new val:" .. newVal)
          currentGrid[i][j] = math.floor(newVal * dampening)
        elseif newVal < 0 then
          print("new val:" .. newVal)
          currentGrid[i][j] = 0
        end
        currentGrid[i][j] = math.floor(newVal * dampening)
      end
    end
    temp = prevGrid
    prevGrid = currentGrid
    currentGrid = temp
end

-- Interactions

function key(id,state)
  if id == 2 and state == 1 then
  --   focus.brightness = 15
  step()
  elseif id == 3 and state == 1 then
  --   focus.brightness = 5
  end
  update()
end

function enc(id,delta)
  if id == 2 then
    focus.x = clamp(focus.x + delta, 1, 16)
  elseif id == 3 then
    focus.y = clamp(focus.y + delta, 1, 8)
  end
  update()
end

-- Clock
function step()
  while true do
    clock.sync(1/params:get("step_div"))
    ripple();
    if g then
        update_grid_leds()
    end
    redraw()

    -- if screen_dirty then ---- only if something changed
    --   redraw() -------------- redraw space
    --   screen_dirty = false -- and everything is clean again
    -- end
  end
end

-- Render

function draw_frame()
  screen.level(15)
  screen.rect(1, 1, viewport.width-1, viewport.height-1)
  screen.stroke()
end

function draw_pixel(x,y)
  if focus.x == x and focus.y == y then
    screen.stroke()
    screen.level(15)
  end
  screen.pixel((x*offset.spacing) + offset.x, (y*offset.spacing) + offset.y)
  if focus.x == x and focus.y == y then
    screen.stroke()
    screen.level(1)
  end
end

function draw_grid()
  if is_connected() ~= true then return end
  screen.level(1)
  offset = { x = 30, y = 13, spacing = 4 }
  for x=1,16,1 do 
    for y=1,8,1 do 
      draw_pixel(x,y)
    end
  end
  screen.stroke()
end

function draw_label()
  screen.level(15)
  local line_height = 8
  screen.move(5,viewport.height - (line_height * 1))
  if is_connected() ~= true then
    screen.text('Grid is not connected.')
  else
    screen.text(focus.x..','..focus.y)
  end
  screen.stroke()
end

function redraw()
  screen.clear()
  draw_frame()
  draw_grid()
  draw_label()
  screen.stroke()
  screen.update()
end

-- Utils

function clamp(val,min,max)
  return val < min and min or val > max and max or val
end