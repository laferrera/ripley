--          ▓▓▓▓▓▓  ▓▓▓▓▓▓ 
--         ▓▓▓ ▓▓▓ ▓▓▓▓▓ ▓▓
--         ▓▓  ▓▓▓▓▓ ▓▓  ▓▓
--         ▓▓▓▓  ▓▓  ▓▓▓▓▓ 
--                ▓        
--            ▓▓▓▓▓▓▓▓     
--         ▓▓▓▓▓    ▓▓▓▓▓▓▓
--           ▓▓▓▓▓▓▓▓▓▓    
-- 
-- DVD - screensaver
-- 0.1 @laferrera
-- llllllll.co/t/TBD

-- >> k1: exit
-- >> e1: change mode
-- mode 1 / screensaver
-- >> k2: generate random sequence A
-- >> k3: generate random sequence B
-- >> e1: volume
-- >> e2: move X
-- >> e3: move Y
-- mode 2 / scales


engine.name = 'PolyPerc'

hs = include('lib/halfsecond')

MusicUtil = require "musicutil"
viewport = { width = 128, height = 64 }
focus = { x = 10, y = 10 }
alt = false
running = true

function build_scale()
  notes = MusicUtil.generate_scale_of_length(params:get("root_note"), params:get("scale_mode"), 32)
end

notes_off_metro = metro.init()

function all_notes_off()
  -- engine.noteOffAll()

  -- engine.noteOff(noteNumber)
  -- if (params:get("out") == 2 or params:get("out") == 3) then
  --   for _, a in pairs(active_notes) do
  --     midi_device:note_off(a, nil, midi_channel)
  --   end
  -- end
  -- active_notes = {}
end

function generate_random_sequence(sqns)
  for i = 1, #sqns.notes do
    sqns.data[i] = math.random(1, 32)
  end
end

function init() ------------------------------ init() is automatically called by norns
  message = "DVD Menu" ----------------- set our initial message
  screen_dirty = true ------------------------ ensure we only redraw when something changes
  -- redraw_clock_id = clock.run(redraw_clock) -- create a "redraw_clock" and note the id

  for i = 1, #MusicUtil.SCALES do
    table.insert(scale_names, string.lower(MusicUtil.SCALES[i].name))
  end

  init_params()
  build_scale()
  hs.init()
  step_clock_id = clock.run(step)
  notes_off_metro.event = all_notes_off
end

function init_params()
    params:add_separator("DVD")
    params:add{type = "number", id = "step_div", name = "step division", min = 1, max = 32, default = 16}
    params:add{type = "option", id = "note_length", name = "note length",
      options = {"25%", "50%", "75%", "100%"},
      default = 4}
    params:add{type = "number", id = "root_note", name = "root note",
      min = 0, max = 127, default = 60, formatter = function(param) return MusicUtil.note_num_to_name(param:get(), true) end,
      action = function() build_scale() end}
    params:add{type = "option", id = "scale_mode", name = "scale mode",
      options = scale_names, default = 5,
      action = function() build_scale() end}
    if engine.name == "MollyThePoly" then
      MollyThePoly.add_params()
    end
    
end

function enc(e, d) --------------- enc() is automatically called by norns
  if mode == 1 then
    if e == 1 then turn(e, d) end -- turn encoder 1
    if e == 2 then turn(e, d) 
      -- change focus.x in bounds
      focus.x = math.max(0,math.min((focus.x + d), viewport_right_edge))
    end -- 
    if e == 3 then turn(e, d) 
      -- change focus.y in bounds
      focus.y = math.max(0,math.min((focus.y + d), viewport_bottom_edge))
    end 
  end -- end mode 1
  screen_dirty = true ------------ something changed
end

function turn(e, d) ----------------------------- an encoder has turned
  message = "encoder " .. e .. ", delta " .. d -- build a message
end

function key(k, z) ------------------ key() is automatically called by norns
  if z == 0 then return end --------- do nothing when you release a key
  if k == 2 then press_down(2) end -- but press_down(2)
  if k == 3 then press_down(3) end -- and press_down(3)
  screen_dirty = true --------------- something changed
end

function press_down(i) ---------- a key has been pressed
  message = "press down " .. i -- build a message
  if mode_names[mode] == "SCREENSAVER" then
    if i == 2 then generate_random_sequence(one) end
    if i == 3 then generate_random_sequence(two) end
  end

end


function step()
  while true do
    clock.sync(1/params:get("step_div"))
    sequence_step()
    if g then
        grid_redraw()
      end
    if screen_dirty then ---- only if something changed
      redraw() -------------- redraw space
      screen_dirty = false -- and everything is clean again
    end
  end
end

function redraw_clock() ----- a clock that draws space
  while true do ------------- "while true do" means "do this forever"
    clock.sleep(1/15) ------- pause for a fifteenth of a second (aka 15fps)
    step()
    screen_dirty = true
    if g then
        grid_redraw()
      end
    if screen_dirty then ---- only if something changed
      redraw() -------------- redraw space
      screen_dirty = false -- and everything is clean again
    end
  end
end

function redraw() -------------- redraw() is automatically called by norns
  screen.clear() --------------- clear space
  screen.aa(1) ----------------- enable anti-aliasing
  if mode_names[mode] == "SCREENSAVER" then
    draw_dvd_icon()
  elseif mode_names[mode] == "SCALES" then
    screen.level(1)
    screen.move(0,30)
    screen.text(snd_names[snd_sel])
    screen.level(15)
    screen.move(0,40)
    screen.text(params:string(snd_params[snd_sel]))
    screen.level(1)
    screen.move(0,50)
    screen.text(snd_names[snd_sel+1])
    screen.level(15)
    screen.move(0,60)
    screen.text(params:string(snd_params[snd_sel+1]))
  end
  screen.update() -------------- update space
end

function draw_dvd_icon()
-- 0111111001111110
-- 1110111011111011
-- 1100111110110011
-- 1111001100111110
-- 0000000100000000
-- 0001111111100000
-- 1111100001111111
-- 0011111111110000
  for row_index, row in ipairs(dvd_icon_table) do
    for column_index, cell in ipairs(row) do
      if cell == 1 then
        screen.pixel(focus.x + column_index,focus.y + row_index)
        
        screen.level(dvd_icon_fill_level)
        screen.fill(0,0,0)
      else
        screen.pixel(focus.x + column_index,focus.y + row_index)
        screen.level(0)
        screen.fill(0,0,0)
      end
    end
  end
  screen.stroke()
end

function grid_redraw()
  local grid_h = g.rows
  g:all(0)
  local grid_x = math.floor((focus.x + #dvd_icon_table[1]) / 8) + 1
  local grid_y = math.floor((focus.y + #dvd_icon_table) / 8) + 1
  g:led(grid_x, grid_y, 15)
  g:refresh()
  -- g:led(1, 1, 15);g:refresh();
end




function stop()
  running = false
  all_notes_off()
end

function start()
  running = true
end

function reset()
  one.pos = 1
  two.pos = 1
end

function clock.transport.start()
  start()
end

function clock.transport.stop()
  stop()
end

function clock.transport.reset()
  reset()
end

function r() ----------------------------- execute r() in the repl to quickly rerun this script
  norns.script.load(norns.state.script) -- https://github.com/monome/norns/blob/main/lua/core/state.lua
end

function cleanup() --------------- cleanup() is automatically called on script close
  clock.cancel(step_clock_id) -- melt our clock vie the id we noted
end

function sequence_step()
  
  local trigger_note = false
  focus.x = focus.x + movement_vector.x
  focus.y = focus.y + movement_vector.y
  if ((focus.x > viewport_right_edge) or (focus.x < 0)) then
    movement_vector.x = -movement_vector.x
    trigger_note = true
  end
  if ((focus.y > viewport_bottom_edge) or (focus.y < 0)) then
    movement_vector.y = -movement_vector.y
    trigger_note = true
  end

  screen_dirty = true

  if trigger_note then

    dvd_icon_fill_level = math.random(13) + 2
    one.pos = one.pos + 1
    if one.pos > #one.data then 
      one.pos = 1 
      two.pos = two.pos + 1
      if two.pos > #two.data then
        two.pos = 1
      end
    end

    -- we subtract one note one.data+two.data so we actual can hit the root note
    -- if they are both in first position
    local note_num = notes[one.data[one.pos]+two.data[two.pos]-1]
    local freq = MusicUtil.note_num_to_freq(note_num)
    print("we are triggering a note: " .. note_num .. " at freq: " .. freq)
    
    if engine.name == "MollyThePoly" then
      engine.noteOn(note_num, freq, 1)
    else
      engine.hz(freq)
    end
  
    crow.output[1].volts = (note_num-60)/12
    crow.output[2].action = "{to(8,0.15),to(0,1)}"
    crow.output[2].execute()

    osc.send(dest,"/note_trigger",{note_num, freq})
    notes_off_metro:start((60 / params:get("clock_tempo") / params:get("step_div")) * params:get("note_length") * 0.25, 1)
  end
end