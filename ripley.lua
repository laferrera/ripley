--  
--   ////\\\\
--   ////\\\\  TUTORIAL
--   ////\\\\  PART 9
--   \\\\////
--   \\\\////  GRID
--   \\\\////
--

-- engine.name = "Sines"
engine.name = 'PolyPerc'
MusicUtil = require "musicutil"

local g
local viewport = { width = 128, height = 64, frame = 0 }
local focus = { x = 1, y = 1, brightness = 15 }
local scale_names = {}
local notes
-- TODO: should these be locals?
currentGrid = {}
prevGrid = {}
rowCount = 8
columnCount = 16
-- dampening = 5/8
dampening = 15/16
-- dampening = 31/32
-- Main



function init()
  connect()
  -- Inits
  for i = 1, #MusicUtil.SCALES do
    table.insert(scale_names, string.lower(MusicUtil.SCALES[i].name))
  end
  
  -- notes_off_metro.event = all_notes_off
  -- Render Style
  screen.level(15)
  screen.aa(0)
  screen.line_width(1)
  -- Render
  for i=1,columnCount do
    currentGrid[i] = {}     -- create a new row
    prevGrid[i] = {}
      for j=1,rowCount do
        currentGrid[i][j] = 0
        prevGrid[i][j] = 0
      end
    end
  init_params()
  build_scale()

  if engine.name == "Sines" then
    init_sines()
  end
  step_clock_id = clock.run(step)
  update()    
end

function build_scale()
  notes = MusicUtil.generate_scale_of_length(params:get("root_note"), params:get("scale_mode"), 16)
  local num_to_add = 16 - #notes
  for i = 1, num_to_add do
    table.insert(notes, notes[16 - num_to_add])
  end
end

function init_params()
  params:add_separator("ripley")
  params:add{type = "number", id = "step_div", name = "step division", min = 1, max = 32, default = 8}

  params:add{type = "option", id = "note_length", name = "note length",
    options = {"25%", "50%", "75%", "100%"},
    default = 4}
  
  params:add{type = "option", id = "scale_mode", name = "scale mode",
    options = scale_names, default = 5,
    action = function() build_scale() end}
  params:add{type = "number", id = "root_note", name = "root note",
    min = 0, max = 127, default = 60, formatter = function(param) return MusicUtil.note_num_to_name(param:get(), true) end,
    action = function() build_scale() end}
  params:add{type = "number", id = "probability", name = "probability",
    min = 0, max = 100, default = 100}
  
  params:add_group("synth",6)
  cs_AMP = controlspec.new(0,1,'lin',0,0.5,'')
  params:add{type="control",id="amp",controlspec=cs_AMP,
    action=function(x) engine.amp(x) end}

  cs_PW = controlspec.new(0,100,'lin',0,50,'%')
  params:add{type="control",id="pw",controlspec=cs_PW,
    action=function(x) engine.pw(x/100) end}

  cs_REL = controlspec.new(0.1,3.2,'lin',0,1.2,'s')
  params:add{type="control",id="release",controlspec=cs_REL,
    action=function(x) engine.release(x) end}

  cs_CUT = controlspec.new(50,5000,'exp',0,800,'hz')
  params:add{type="control",id="cutoff",controlspec=cs_CUT,
    action=function(x) engine.cutoff(x) end}

  cs_GAIN = controlspec.new(0,4,'lin',0,1,'')
  params:add{type="control",id="gain",controlspec=cs_GAIN,
    action=function(x) engine.gain(x) end}
  
  cs_PAN = controlspec.new(-1,1, 'lin',0,0,'')
  params:add{type="control",id="pan",controlspec=cs_PAN,
    action=function(x) engine.pan(x) end}
end

function init_sines()
  for i=1, columnCount do
    engine.env_bias(i, 1)
    engine.hz(i, 110 * i)
    engine.hz_lag(i, 0.005)
    engine.amp_slew(i,0)
  end
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
  if z == 1 then
    focus.x = x
    focus.y = y
    -- print("we are triggering a note: " .. note_num .. " at freq: " .. freq)
    print("xy: " .. x ..",".. y)
    currentGrid[x][y] = 16
    prevGrid[x][y] = 16
    update_grid_leds()
    update()
  end
end

function update_grid_leds()
  for i=1,columnCount do
    for j=1,rowCount do
      g:led(i,j, math.floor(currentGrid[i][j]))
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
  for i=1,columnCount do
      for j=1,rowCount do
        local left = 0
        local right = 0
        local top = 0
        local bottom = 0

        if i-1 >= 1 then
          left = prevGrid[i-1][j]
        else
          left = prevGrid[i+1][j]
        end

        if i+1 <= columnCount then
          right = prevGrid[i+1][j]
        else
          right = prevGrid[i-1][j]
        end
        
        if j+1 <=  rowCount then
          top = prevGrid[i][j+1]
        else
          top = prevGrid[i][j-1]
        end

        if j-1 >= 1 then
          bottom = prevGrid[i][j-1]
        else
          bottom = prevGrid[i][j+1]
        end



        newVal = (left + right + top + bottom) / 2 - currentGrid[i][j]
        if newVal > 0 then
          -- print("new val:" .. newVal)
          -- currentGrid[i][j] = math.floor(newVal * dampening)
          currentGrid[i][j] = newVal * dampening
        elseif newVal < 0 then
          -- print("new val:" .. newVal)
          currentGrid[i][j] = 0
        end
        -- currentGrid[i][j] = math.floor(newVal * dampening)
      end
    end
    temp = prevGrid
    prevGrid = currentGrid
    currentGrid = temp
end

function play_poly_perc()
  for i=1,columnCount do
    for j=1,rowCount do
      if currentGrid[i][j] > 2 then
        local freq = MusicUtil.note_num_to_freq(i*2 + params:get("root_note"))
        engine.amp(currentGrid[i][j] / 32)
        engine.hz(freq) 
      end
    end
  end
end

function update_sine_vols() 
    for i=1,columnCount do
      -- print("vol: "... currentGrid[i][2])
      -- vol = currentGrid[i][2]/16
      engine.vol(i, currentGrid[i][1]/16)
      for j=1,rowCount do
      end
    end
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
    if engine.name == "Sines" then
      update_sine_vols()
    elseif engine.name == "PolyPerc" then
      play_poly_perc()
    end
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
  -- if focus.x == x and focus.y == y then
    screen.stroke()
    pixBright = 1 + (math.floor(currentGrid[x][y]/2)) 
    screen.level(pixBright)
  -- end
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

function cleanup() --------------- cleanup() is automatically called on script close
  clock.cancel(step_clock_id) -- melt our clock vie the id we noted
end