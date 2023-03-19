Class = require 'class'
push = require 'push'


WINDOW_WIDTH = 1280
WINDOW_HEIGHT = 720

VIRTUAL_WIDTH = 1280
VIRTUAL_HEIGHT = 720

--[[
    Runs when the game first starts up, only once; used to initialize the game.
]]
function love.load()
    
    -- set love's default filter to "nearest-neighbor", which essentially
    -- means there will be no filtering of pixels (blurriness), which is
    -- important for a nice crisp, 2D look
    love.graphics.setDefaultFilter('nearest', 'nearest')

    -- set the title of our application window
    love.window.setTitle('Ostrog')

    -- "seed" the RNG so that calls to random are always random
    -- use the current time, since that will vary on startup every time
    math.randomseed(os.time())

    -- initialize our nice-looking text fonts
    resourceFont = love.graphics.newFont('Kramola.ttf', 20)
    largeFont = love.graphics.newFont('Kramola.ttf', 26)
    titleFont = love.graphics.newFont('Kramola.ttf', 36)
    megaFont = love.graphics.newFont('Kramola.ttf', 120)
    love.graphics.setFont(largeFont)

    -- initialize window with virtual resolution
    push:setupScreen(VIRTUAL_WIDTH, VIRTUAL_HEIGHT, WINDOW_WIDTH, WINDOW_HEIGHT, {
        fullscreen = false,
        resizable = false,
        vsync = true
    })

    -- set up our sound effects; later, we can just index this table and
    -- call each entry's `play` method
    sounds = {
        ['miss'] = love.audio.newSource('sounds/missclick.wav', 'static'),
        ['enter'] = love.audio.newSource('sounds/drum.wav', 'static'),
        ['wolf'] = love.audio.newSource('sounds/wolf.wav', 'static'),
        ['tartar'] = love.audio.newSource('sounds/new_chatter.wav', 'static'),
        ['lightning'] = love.audio.newSource('sounds/lightning.wav', 'static'),
        ['victory'] = love.audio.newSource('sounds/cossack_song_edited.wav', 'static'),
    }


    -- define the background image and icons
    background = love.graphics.newImage('images/ostrog_background_3.jpg')
    foodIcon = love.graphics.newImage('images/food_top.png')
    woodIcon = love.graphics.newImage('images/wood_center.png')
    clothIcon = love.graphics.newImage('images/cloth_left.png')
    button_plus = love.graphics.newImage('images/button_plusss.jpg')
    button_minus = love.graphics.newImage('images/button_minusss.jpg')
    button_empty = love.graphics.newImage('images/checkbox_empty_x.jpg')
    button_checked = love.graphics.newImage('images/checkbox_full_x.jpg')
    button_continue = love.graphics.newImage('images/button_continue_190.jpg')
    button_newgame = love.graphics.newImage('images/button_newgame_190.jpg')

    -- Set game to inital state
    intializeGame()
end


--[[
    Keyboard handling, called by LÖVE2D each frame; 
    passes in the key we pressed so we can access.
]]
function love.keypressed(key)

    -- escape exits the game
    if key == 'escape' then
        love.event.quit()
    
    -- enter will transition to the next appropriate game state
    elseif key == 'enter' or key == 'return' then
        if gameState == 'start' then
            gameState = 'play'
            sounds['enter']:play()
        
        elseif gameState == 'play' and worker_pool == 0 then
            if building == 1 then
                gameState = 'construction'
                builders = 1
                sounds['enter']:play()
            else
                gameState = 'result'
                result()
                sounds['enter']:play()
            end

        -- The player needs to assign each worker before they can progress
        elseif  gameState == 'play' and worker_pool > 0 then
            sounds['miss']:play()

        elseif gameState == 'construction' and builders == 0 then
            constructionEnd()
            result()
            sounds['enter']:play()
            
        elseif gameState == 'result' then
            resDisplayReset()
            result()
            sounds['enter']:play()

        elseif gameState == 'event' then
            gameState = 'refresh'
            refresh()
            sounds['enter']:play()

        elseif gameState == 'refresh' then
            gameState = 'play'
            sounds['enter']:play()
        
        -- will restart the game after winning/losing
        elseif gameState == 'starvation' then
            intializeGame()
            sounds['enter']:play()

        -- will restart the game after winning/losing
        elseif gameState == 'end' then
            intializeGame()
            sounds['enter']:play()
        end
    end
end


-- When the mouse is clicked, checks to see if located on button
-- If so, button activates accordingly
function love.mousepressed(x ,y ,button)
    if button == 1 then
        if gameState == 'start' then
            gameState = 'play'
            sounds['enter']:play()
        else
            for k, v in pairs (buttons) do
                if x > v[1] and x < (v[1] + v[3]) and y > v[2] and y < (v[2] + v[4]) then
                    buttonClicked(k)
                end
            end
        end
	end
end


-- Specify what happens when each button is clicked
function buttonClicked(k)

-- Continue button
    if k == 'con' and gameState ~= 'start' and gameState ~= 'starvation' and gameState ~= 'end' then
        love.keypressed('enter')
    end

-- Buttons for assigning/unassigning workers to the tasks
    if k == 'fp' and gameState == 'play' then
        if worker_pool > 0 then
            foraging = foraging + 1
            worker_pool = worker_pool - 1
            sounds['enter']:play()
        else
            sounds['miss']:play()
        end
    end

    if k == 'fm' and gameState == 'play' then
        if foraging > 0 then
            foraging = foraging - 1
            worker_pool = worker_pool + 1
            sounds['enter']:play()
        else
            sounds['miss']:play()
        end
    end

    if k == 'hp' and gameState == 'play' then
        if worker_pool > 0 then
            hunting = hunting + 1
            worker_pool = worker_pool - 1
            sounds['enter']:play()
        else
            sounds['miss']:play()
        end
    end

    if k == 'hm' and gameState == 'play' then
        if hunting > 0 then
            hunting = hunting - 1
            worker_pool = worker_pool + 1
            sounds['enter']:play()
        else
            sounds['miss']:play()
        end
    end

    if k == 'wp' and gameState == 'play' then
        if worker_pool > 0 then
            wood_cutting = wood_cutting + 1
            worker_pool = worker_pool - 1
            sounds['enter']:play()
        else
            sounds['miss']:play()
        end
    end

    if k == 'wm' and gameState == 'play' then
        if wood_cutting > 0 then
            wood_cutting = wood_cutting - 1
            worker_pool = worker_pool + 1
            sounds['enter']:play()
        else
            sounds['miss']:play()
        end
    end

    if k == 'bp' and gameState == 'play' then
        if worker_pool > 0 and building < 1 then
            building = building + 1
            worker_pool = worker_pool - 1
            sounds['enter']:play()
        else
            sounds['miss']:play()
        end
    end

    if k == 'bm' and gameState == 'play' then
        if building > 0 then
            building = building - 1
            worker_pool = worker_pool + 1
            sounds['enter']:play()
        else
            sounds['miss']:play()
        end
    end

    if k == 'ap' and gameState == 'play' then
        if worker_pool > 0 and farming < buildings.cleared_land[1] then
            farming = farming + 1
            worker_pool = worker_pool - 1
            sounds['enter']:play()
        else
            sounds['miss']:play()
        end
    end

    if k == 'am' and gameState == 'play' then
        if farming > 0 then
            farming = farming - 1
            worker_pool = worker_pool + 1
            sounds['enter']:play()
        else
            sounds['miss']:play()
        end
    end

-- Buttons for constructing buildings, making sure that only 1 is ever built
    if k == 'grn' and gameState == 'construction' then
        if buildings.granary[1] == false and wood >= buildings.granary[2] then
            sounds['enter']:play()
            resetSelection()
            grn_selected = true
            if builders > 0 then
                builders = builders - 1
                grn = 1
            else
                resetConstruction()
                grn = 1
            end
        else
            sounds['miss']:play()
        end
    end

    if k == 'chp' and gameState == 'construction' then
        if buildings.chapel[1] == false and wood >= buildings.chapel[2] then
            sounds['enter']:play()
            resetSelection()
            chp_selected = true
            if builders > 0 then
                builders = builders - 1
                chp = 1
            else
                resetConstruction()
                chp = 1
            end
        else
            sounds['miss']:play()
        end
    end

    if k == 'pal' and gameState == 'construction' then
        if buildings.palisade[1] == false and wood >= buildings.palisade[2] then
            sounds['enter']:play()
            resetSelection()
            pal_selected = true
            if builders > 0 then
                builders = builders - 1
                pal = 1
            else
                resetConstruction()
                pal = 1
            end
        else
            sounds['miss']:play()
        end
    end

    if k == 'pst' and gameState == 'construction' then
        if buildings.trading_post[1] == false and wood >= buildings.trading_post[2] then
            sounds['enter']:play()
            resetSelection()
            pst_selected = true
            if builders > 0 then
                builders = builders - 1
                pst = 1
            else
                resetConstruction()
                pst = 1
            end
        else
            sounds['miss']:play()
        end
    end

    if k == 'tan' and gameState == 'construction' then
        if buildings.tannery[1] == false and wood >= buildings.tannery[2] then
            sounds['enter']:play()
            resetSelection()
            tan_selected = true
            if builders > 0 then
                builders = builders - 1
                tan = 1
            else
                resetConstruction()
                tan = 1
            end
        else
            sounds['miss']:play()
        end
    end

    if k == 'clr' and gameState == 'construction' then
        sounds['enter']:play()
        resetSelection()
        clr_selected = true
        if builders > 0 then
            builders = builders - 1
            clr = 1
        else
            resetConstruction()
            clr = 1
        end
    end
end



-- A table holding the coordinates of onscreen items (e.g. buttons)
coords = {
    
-- Continue button
    con = {VIRTUAL_WIDTH / 2 - 95, VIRTUAL_HEIGHT - 90, 190, 50},

-- Resource displays
    -- resource label
    resourceLab = {580, 20},

    -- food display
    foodLab = {VIRTUAL_WIDTH / 2 - 150, 68},
    foodCount = {VIRTUAL_WIDTH / 2 - 100, 70},

    -- wood display
    woodLab = {VIRTUAL_WIDTH / 2 - 45, 60},
    woodCount = {VIRTUAL_WIDTH / 2 + 5, 70},

    -- cloth display
    clothLab = {VIRTUAL_WIDTH / 2 + 60, 63},
    clothCount = {VIRTUAL_WIDTH / 2 + 100, 70},

-- Task buttons
    -- foraging controls
    fl = {40, 115},
    fp = {40, 140, 30, 30},
    fm = {80, 140, 30, 30},
    fc = {125, 145},

    -- hunting controls
    hl = {40, 195},
    hp = {40, 220, 30, 30},
    hm = {80, 220, 30, 30},
    hc = {125, 225},

    -- wood cutting controls
    wl = {40, 275},
    wp = {40, 300, 30, 30},
    wm = {80, 300, 30, 30},
    wc = {125, 305},

    --building controls
    bl = {40, 355},
    bp = {40, 380, 30, 30},
    bm = {80, 380, 30, 30},
    bc = {125, 385},

    --farming controls
    al = {40, 435},
    ap = {40, 460, 30, 30},
    am = {80, 460, 30, 30},
    ac = {125, 465},

-- Worker pool
    workerLab = {40, 45},
    workerCount = {250, 45},

-- Week tracker
    weekLab = {VIRTUAL_WIDTH - 170, 45},
    weekCount = {VIRTUAL_WIDTH - 100, 45},
    seasonLab = {VIRTUAL_WIDTH - 300, 45},

-- Construction title
    constructionLab = {380, 200},

-- Construction buttons
    grn = {380, 250, 40, 40},
    chp = {380, 310, 40, 40},
    pal = {380, 370, 40, 40},
    pst = {380, 430, 40, 40},
    tan = {380, 490, 40, 40},
    clr = {380, 550, 40, 40},
}


-- A table of buttons to use for click registration
buttons = {
    -- task buttons
    fp = coords.fp,
    fm = coords.fm,
    hp = coords.hp,
    hm = coords.hm,
    wp = coords.wp,
    wm = coords.wm,
    bp = coords.bp,
    bm = coords.bm,
    ap = coords.ap,
    am = coords.am,
    -- construction buttons
    grn = coords.grn,
    chp = coords.chp,
    pal = coords.pal,
    pst = coords.pst,
    tan = coords.tan,
    clr = coords.clr,
    -- continue button
    con = coords.con,
}


--[[
    Called after update by LÖVE2D, used to draw anything to the screen, 
    updated or otherwise.
]]
function love.draw()

    push:apply('start')

    -- Displays the background image
    if gameState == 'start' then
        for i = 0, VIRTUAL_WIDTH / background:getWidth() do
            for u = 0, VIRTUAL_HEIGHT / background:getHeight() do
                love.graphics.draw(background, i * background:getWidth(), u * background:getHeight())
            end
        end
    end

    -- Draws a continue button, present during most game states
    if gameState ~= 'start' and gameState ~= 'starvation' and gameState ~= 'end' then
        love.graphics.draw(button_continue, coords.con[1], coords.con[2])
    end
  
    -- Displays worker task buttons
    if gameState == 'play' or gameState == 'result' or gameState == 'event' or gameState == 'refresh' then
        
        love.graphics.setFont(largeFont)
        
        -- Buttons and counts for the tasks
        love.graphics.draw(button_plus, coords.fp[1], coords.fp[2])
        love.graphics.draw(button_minus, coords.fm[1], coords.fm[2])
        love.graphics.print(tostring(foraging), coords.fc[1], coords.fc[2])

        love.graphics.draw(button_plus, coords.hp[1], coords.hp[2])
        love.graphics.draw(button_minus, coords.hm[1], coords.hm[2])
        love.graphics.print(tostring(hunting), coords.hc[1], coords.hc[2])

        love.graphics.draw(button_plus, coords.wp[1], coords.wp[2])
        love.graphics.draw(button_minus, coords.wm[1], coords.wm[2])
        love.graphics.print(tostring(wood_cutting),  coords.wc[1], coords.wc[2])

        love.graphics.draw(button_plus, coords.bp[1], coords.bp[2])
        love.graphics.draw(button_minus, coords.bm[1], coords.bm[2])
        love.graphics.print(tostring(building),  coords.bc[1], coords.bc[2])

        love.graphics.draw(button_plus, coords.ap[1], coords.ap[2])
        love.graphics.draw(button_minus, coords.am[1], coords.am[2])
        love.graphics.print(tostring(farming),  coords.ac[1], coords.ac[2])

        -- Displays land clearance number
        love.graphics.print(tostring(buildings.cleared_land[1]), coords.ac[1], coords.al[2] + 180)
    
        -- Labels for task buttons
        love.graphics.setFont(resourceFont)
        love.graphics.print('Forage', coords.fl[1], coords.fl[2])
        love.graphics.print('Hunt', coords.hl[1], coords.hl[2])
        love.graphics.print('Cut wood', coords.wl[1], coords.wl[2])
        love.graphics.print('Build', coords.bl[1], coords.bl[2])
        love.graphics.print('Farm', coords.al[1], coords.al[2])
        
        -- Reminder of amount of cleared land for farming
        love.graphics.print('Land', coords.al[1], coords.al[2] + 170)
        love.graphics.print('cleared', coords.al[1], coords.al[2] + 200)
    end

    
    -- Displays resources and other information at the top of the screen
    if gameState == 'play' or gameState == 'result' or gameState == 'construction' or
    gameState == 'event' or gameState == 'refresh' then

        -- Resource icons at the top of the screen
        love.graphics.draw(foodIcon, coords.foodLab[1], coords.foodLab[2])
        love.graphics.draw(woodIcon, coords.woodLab[1], coords.woodLab[2])
        love.graphics.draw(clothIcon, coords.clothLab[1], coords.clothLab[2])
        
        -- Large font text items at the top of the screen
        love.graphics.setFont(largeFont)
        love.graphics.print('Available workers', coords.workerLab[1], coords.workerLab[2])
        love.graphics.print('Week', coords.weekLab[1], coords.weekLab[2])
        love.graphics.print('Resources', coords.resourceLab[1], coords.resourceLab[2])

        displayResources()
    end

    -- Displays result messages for each work party after tasks have been confirmed
    if gameState == 'result' and displayRes == true then
        love.graphics.setFont(largeFont)
        
        if fRes == 1 then
            love.graphics.printf('Wolves howl nearby, my lord. The men hesistate to stray from the Ostrog', 0, VIRTUAL_HEIGHT / 2 - 50, VIRTUAL_WIDTH, 'center')
            love.graphics.printf('No resources gained', 0, VIRTUAL_HEIGHT / 2, VIRTUAL_WIDTH, 'center')
        elseif fRes == 2 then
            love.graphics.printf('We found nothing but twigs and mushrooms', 0, VIRTUAL_HEIGHT / 2 - 50, VIRTUAL_WIDTH, 'center')
            love.graphics.printf('+ 1 food, + 1 wood', 0, VIRTUAL_HEIGHT / 2, VIRTUAL_WIDTH, 'center')
        elseif fRes == 3 then
            love.graphics.printf('We have found a patch of berries', 0, VIRTUAL_HEIGHT / 2 - 50, VIRTUAL_WIDTH, 'center')
            love.graphics.printf('+ 3 food', 0, VIRTUAL_HEIGHT / 2, VIRTUAL_WIDTH, 'center')
        elseif fRes == 4 then
            love.graphics.printf('These forests and hills hold rich treasures, if you know where to look', 0, VIRTUAL_HEIGHT / 2 - 50, VIRTUAL_WIDTH, 'center')
            love.graphics.printf('+ 2 food, + 2 wood', 0, VIRTUAL_HEIGHT / 2, VIRTUAL_WIDTH, 'center')
        elseif fRes == 5 then
            love.graphics.printf('We found the remnants of an abandoned caravan', 0, VIRTUAL_HEIGHT / 2 - 50, VIRTUAL_WIDTH, 'center')
            love.graphics.printf('+ 4 food, + 3 wood', 0, VIRTUAL_HEIGHT / 2, VIRTUAL_WIDTH, 'center')

        elseif hRes == 1 then
            love.graphics.printf('Not a single creature stirs in the forest, my lord', 0, VIRTUAL_HEIGHT / 2 - 50, VIRTUAL_WIDTH, 'center')
            love.graphics.printf('No resources gained', 0, VIRTUAL_HEIGHT / 2, VIRTUAL_WIDTH, 'center')
        elseif hRes == 2 then
            love.graphics.printf('We found nothing but squirrels', 0, VIRTUAL_HEIGHT / 2 - 50, VIRTUAL_WIDTH, 'center')
            love.graphics.printf('+ 1 food', 0, VIRTUAL_HEIGHT / 2, VIRTUAL_WIDTH, 'center')
        elseif hRes == 3 then
            love.graphics.printf('Our dogs sniffed out a den of rabbits', 0, VIRTUAL_HEIGHT / 2 - 50, VIRTUAL_WIDTH, 'center')
            if buildings.tannery[1] == true then
                love.graphics.printf('+ 2 food, + 1 cloth', 0, VIRTUAL_HEIGHT / 2, VIRTUAL_WIDTH, 'center')
            else
                love.graphics.printf('+ 2 food', 0, VIRTUAL_HEIGHT / 2, VIRTUAL_WIDTH, 'center')
            end
        elseif hRes == 4 then
            love.graphics.printf('God has smiled upon us. Deer are plentiful here', 0, VIRTUAL_HEIGHT / 2 - 50, VIRTUAL_WIDTH, 'center')
            if buildings.tannery[1] == true then
                love.graphics.printf('+ 3 food, + 2 cloth', 0, VIRTUAL_HEIGHT / 2, VIRTUAL_WIDTH, 'center')
            else
                love.graphics.printf('+ 3 food', 0, VIRTUAL_HEIGHT / 2, VIRTUAL_WIDTH, 'center')
            end
        elseif hRes == 5 then
            love.graphics.printf('We slew a great bear. Its growl shook the very mountains', 0, VIRTUAL_HEIGHT / 2 - 50, VIRTUAL_WIDTH, 'center')
            if buildings.tannery[1] == true then
                love.graphics.printf('+ 5 food, + 3 cloth', 0, VIRTUAL_HEIGHT / 2, VIRTUAL_WIDTH, 'center')
            else
                love.graphics.printf('+ 5 food', 0, VIRTUAL_HEIGHT / 2, VIRTUAL_WIDTH, 'center')
            end

        elseif wRes == 1 then
            love.graphics.printf('Too much rain has left nothing but damp logs', 0, VIRTUAL_HEIGHT / 2 - 50, VIRTUAL_WIDTH, 'center')
            love.graphics.printf('No resources gained', 0, VIRTUAL_HEIGHT / 2, VIRTUAL_WIDTH, 'center')
        elseif wRes == 2 then
            love.graphics.printf('The men cut nothing but saplings', 0, VIRTUAL_HEIGHT / 2 - 50, VIRTUAL_WIDTH, 'center')
            love.graphics.printf('+ 1 wood', 0, VIRTUAL_HEIGHT / 2, VIRTUAL_WIDTH, 'center')
        elseif wRes == 3 then
            love.graphics.printf('A hard day of work has yielded much lumber', 0, VIRTUAL_HEIGHT / 2 - 50, VIRTUAL_WIDTH, 'center')
            love.graphics.printf('+ 3 wood', 0, VIRTUAL_HEIGHT / 2, VIRTUAL_WIDTH, 'center')
        elseif wRes == 4 then
            love.graphics.printf('The trees are thick, my lord. Their roots grow deep', 0, VIRTUAL_HEIGHT / 2 - 50, VIRTUAL_WIDTH, 'center')
            love.graphics.printf('+ 5 wood', 0, VIRTUAL_HEIGHT / 2, VIRTUAL_WIDTH, 'center')
        elseif wRes == 5 then
            love.graphics.printf('Our axes need sharpening. Where is the blacksmith?', 0, VIRTUAL_HEIGHT / 2 - 50, VIRTUAL_WIDTH, 'center')
            love.graphics.printf('+ 7 wood', 0, VIRTUAL_HEIGHT / 2, VIRTUAL_WIDTH, 'center')

        elseif aRes == 1 then
            love.graphics.printf('The crops are sorely infected', 0, VIRTUAL_HEIGHT / 2 - 50, VIRTUAL_WIDTH, 'center')
            love.graphics.printf('No resources gained', 0, VIRTUAL_HEIGHT / 2, VIRTUAL_WIDTH, 'center')
        elseif aRes == 2 then
            love.graphics.printf('We dug up a great turnip, my lord', 0, VIRTUAL_HEIGHT / 2 - 50, VIRTUAL_WIDTH, 'center')
            love.graphics.printf('+ 3 food', 0, VIRTUAL_HEIGHT / 2, VIRTUAL_WIDTH, 'center')
        elseif aRes == 3 then
            love.graphics.printf('The rye has been harvested. Now time for kvass!', 0, VIRTUAL_HEIGHT / 2 - 50, VIRTUAL_WIDTH, 'center')
            love.graphics.printf('+ 6 food', 0, VIRTUAL_HEIGHT / 2, VIRTUAL_WIDTH, 'center')
        elseif aRes == 4 then
            love.graphics.printf('The oxen and men strained to get the harvest in', 0, VIRTUAL_HEIGHT / 2 - 50, VIRTUAL_WIDTH, 'center')
            love.graphics.printf('+ 9 food', 0, VIRTUAL_HEIGHT / 2, VIRTUAL_WIDTH, 'center')
        elseif aRes == 5 then
            love.graphics.printf('The soil is rich and black. Our harvest was plentiful', 0, VIRTUAL_HEIGHT / 2 - 50, VIRTUAL_WIDTH, 'center')
            love.graphics.printf('+ 11 food', 0, VIRTUAL_HEIGHT / 2, VIRTUAL_WIDTH, 'center')
        end
    end 


    -- Building display during the construction phase
    if gameState == 'construction' then

        -- Building title
        love.graphics.setFont(titleFont)
        love.graphics.print('Choose a building to construct', coords.constructionLab[1], coords.constructionLab[2])

        -- Buttons and text for each building
        love.graphics.setFont(largeFont)
        if grn_selected == true then
            love.graphics.draw(button_checked, coords.grn[1], coords.grn[2])
        else
            love.graphics.draw(button_empty, coords.grn[1], coords.grn[2])
        end
        love.graphics.print('Granary (10)', coords.grn[1] + 60, coords.grn[2] + 8)
        if buildings.granary[1] == true then
            love.graphics.print('Built', coords.grn[1] + 320, coords.grn[2] + 8)
        end

        if chp_selected == true then
            love.graphics.draw(button_checked, coords.chp[1], coords.chp[2])
        else
            love.graphics.draw(button_empty, coords.chp[1], coords.chp[2])
        end
        love.graphics.print('Chapel (20)', coords.chp[1] + 60, coords.chp[2] + 8)
        if buildings.chapel[1] == true then
            love.graphics.print('Built', coords.chp[1] + 320, coords.chp[2] + 8)
        end

        if pal_selected == true then
            love.graphics.draw(button_checked, coords.pal[1], coords.pal[2])
        else
            love.graphics.draw(button_empty, coords.pal[1], coords.pal[2])
        end
        love.graphics.print('Palisade (5)', coords.pal[1] + 60, coords.pal[2] + 8)
        if buildings.palisade[1] == true then
            love.graphics.print('Built', coords.pal[1] + 320, coords.pal[2] + 8)
        end

        if pst_selected == true then
            love.graphics.draw(button_checked, coords.pst[1], coords.pst[2])
        else
            love.graphics.draw(button_empty, coords.pst[1], coords.pst[2])
        end
        love.graphics.print('Trading post (10)', coords.pst[1] + 60, coords.pst[2] + 8)
        if buildings.trading_post[1] == true then
            love.graphics.print('Built', coords.pst[1] + 320, coords.pst[2] + 8)
        end
        
        if tan_selected == true then
            love.graphics.draw(button_checked, coords.tan[1], coords.tan[2])
        else
            love.graphics.draw(button_empty, coords.tan[1], coords.tan[2])
        end
        love.graphics.print('Tannery (15)', coords.tan[1] + 60, coords.tan[2] + 8)
        if buildings.tannery[1] == true then
            love.graphics.print('Built', coords.tan[1] + 320, coords.tan[2] + 8)
        end

        if clr_selected == true then
            love.graphics.draw(button_checked, coords.clr[1], coords.clr[2])
        else
            love.graphics.draw(button_empty, coords.clr[1], coords.clr[2])
        end
        love.graphics.print('Clear land', coords.clr[1] + 60, coords.clr[2] + 8)
    end
    
    -- Displays messages/results of events
    if gameState == 'event' then
        if wolves == true then
            love.graphics.setFont(titleFont)
            love.graphics.printf('Wolves attack our livestock!', 0, VIRTUAL_HEIGHT / 2 - 50, VIRTUAL_WIDTH, 'center')
            love.graphics.setFont(largeFont)
            love.graphics.printf('- ' .. tostring(wolfattack) .. ' food', 0, VIRTUAL_HEIGHT / 2, VIRTUAL_WIDTH, 'center')
        elseif tartars == true then
            love.graphics.setFont(titleFont)
            love.graphics.printf('Local Tartars wish to join our settlement', 0, VIRTUAL_HEIGHT / 2 - 50, VIRTUAL_WIDTH, 'center')
            love.graphics.setFont(largeFont)
            love.graphics.printf('+ 1 population', 0, VIRTUAL_HEIGHT / 2, VIRTUAL_WIDTH, 'center')
        elseif noEvent == true then
            love.graphics.setFont(titleFont)
            love.graphics.printf('The hills are silent', 0, VIRTUAL_HEIGHT / 2 - 50, VIRTUAL_WIDTH, 'center')
            love.graphics.setFont(largeFont)
            love.graphics.printf('Nothing unusual happens', 0, VIRTUAL_HEIGHT / 2, VIRTUAL_WIDTH, 'center')
        end
    end


    -- Displays title messages during various game states
    if gameState == 'start' then
        love.graphics.setFont(megaFont)
        love.graphics.printf('Ostrog', 0, VIRTUAL_HEIGHT / 2 - 120, VIRTUAL_WIDTH, 'center')
        love.graphics.setFont(titleFont)
        love.graphics.setColor( 0, 0, 0)
        love.graphics.rectangle('fill', VIRTUAL_WIDTH / 2 - 96, VIRTUAL_HEIGHT / 2 + 89, 192, 52)
        love.graphics.setColor( 1, 1, 1)
        love.graphics.draw(button_newgame, VIRTUAL_WIDTH / 2 - 95, VIRTUAL_HEIGHT / 2 + 90)
    elseif gameState == 'end' then
        victoryCheck()
        if victory == true then
            calculateScore()
            victorySound()
            love.graphics.setFont(titleFont)
            love.graphics.printf('Victory! You will last the winter', 0, VIRTUAL_HEIGHT / 2 - 60, VIRTUAL_WIDTH, 'center')
            love.graphics.setFont(largeFont)
            love.graphics.printf('Score: ' .. tostring(score), 0, VIRTUAL_HEIGHT / 2, VIRTUAL_WIDTH, 'center')
            love.graphics.printf('Press enter to start a new game', 0, VIRTUAL_HEIGHT / 2 + 50, VIRTUAL_WIDTH, 'center')
        else
            defeatSound()
            love.graphics.setFont(titleFont)
            love.graphics.printf('The winter has come', 0, VIRTUAL_HEIGHT / 2 - 100, VIRTUAL_WIDTH, 'center')
            love.graphics.setFont(largeFont)
            love.graphics.printf('You have not gathered enough supplies and must flee back to Russia', 0, VIRTUAL_HEIGHT / 2 - 40, VIRTUAL_WIDTH, 'center')
            love.graphics.printf('Press enter to try again', 0, VIRTUAL_HEIGHT / 2 + 50, VIRTUAL_WIDTH, 'center')
            
        end
    elseif gameState == 'starvation' then
        love.graphics.setFont(titleFont)
        love.graphics.printf('You died of starvation', 0, VIRTUAL_HEIGHT / 2 - 50, VIRTUAL_WIDTH, 'center')
        love.graphics.setFont(largeFont)
        love.graphics.printf('Press enter to start a new game', 0, VIRTUAL_HEIGHT / 2 - 10, VIRTUAL_WIDTH, 'center')
    end

    push:apply('end')
end


--[[
    Prints the resources and other numerical information to the screen
]]
function displayResources()
    love.graphics.setFont(largeFont)
    love.graphics.print(tostring(food), coords.foodCount[1], coords.foodCount[2])
    love.graphics.print(tostring(wood), coords.woodCount[1], coords.woodCount[2])
    love.graphics.print(tostring(cloth), coords.clothCount[1], coords.clothCount[2])
    
    love.graphics.setFont(largeFont)
    love.graphics.print(tostring(worker_pool), coords.workerCount[1], coords.workerCount[2])
    love.graphics.print(tostring(week), coords.weekCount[1], coords.weekCount[2])
    love.graphics.print(tostring(season), coords.seasonLab[1], coords.seasonLab[2])

end


--[[
    Resets all the resources, etc. when game is started
]]
function intializeGame()
    
    -- Set the intitial resources
    food = 20
    wood = 0
    cloth = 0
    
    -- Set the week to 1
    week = 1
    season = 'Spring'
    
    -- Set the population to 4 and each task to 0
    population = 4
    worker_pool = population
    foraging = 0
    hunting = 0
    wood_cutting = 0
    building = 0
    farming = 0

    -- Set all the task results to 0 and make sure the display tag is off
    displayRes = false
    fRes = 0
    hRes = 0
    wRes = 0
    aRes = 0

    -- Reset all the buildings
    buildings.granary[1] = false
    buildings.chapel[1] = false
    buildings.palisade[1] = false
    buildings.trading_post[1] = false
    buildings.tannery[1] = false
    buildings.cleared_land[1] = 0

    -- Return the game state to start, set victory check to false, and score to 0
    gameState = 'start'
    victory = false
    score = 0

    -- Turn off all of the events
    wolves = false
    wolfattack = 0
    tartars = false
    noEvent = false

    -- Start the game music
    music = love.audio.newSource('sounds/folk_music_edited.mp3', 'stream')
    music:setLooping(true)
    music:setVolume(0.07)
    music:play()
    defeatSoundTrigger = true
    victorySoundTrigger = true 
end


-- Resets the buttons, increments the week, checks victory conditions, etc.
-- used during each refresh phase
function refresh()
    
    -- Subtract food consumed by the Ostrog
    food = food - (2 * population)

    -- Check to see if granary is built, if not, enforce food cap
    if buildings.granary[1] == false then
        if food > 30 then
            food = 30
        end
    end
    
    -- Check for starvation
    if food < 0 then
        gameState = 'starvation'
        music:stop()
    else
        -- Increment the weeks by 1 and check for end game
        week = week + 1
        if week > 8 and week <= 18 then
            season = 'Summer'
        elseif week > 18 then
            season = 'Autumn'
        end

        if week + (math.random(4) - 1) > 27 then
            gameState = 'end'
            music:stop()
        else
            -- Reset the worker pool and the tasks
            worker_pool = population
            foraging = 0
            hunting = 0
            wood_cutting = 0
            building = 0
            farming = 0

            -- Reset the event mechanics
            wolves = false
            wolfattack = 0
            tartars = false
            noEvent = false

            -- Set game state back to play
            gameState = 'play'
        end
    end  
end


-- Calculate the results for each worker and trigger a display
function result()

    result_count = foraging + hunting + wood_cutting + farming

    if result_count == 0 then
        gameState = 'event'
        sounds['enter']:play()
        calculateEvent()
    end

    if foraging > 0 then
        foraging = foraging - 1
        fRes = math.random(5)
        
        if fRes == 1 then
            food = food
            displayRes = true
        elseif fRes == 2 then
            food = food + 1
            wood = wood + 1
            displayRes = true
        elseif fRes == 3 then
            food = food + 3
            displayRes = true
        elseif fRes == 4 then
            food = food + 2
            wood = wood + 2
            displayRes = true
        elseif fRes == 5 then
            food = food + 4
            wood = wood + 3
            displayRes = true
        end
    
    -- Note: player must create a tannery to get cloth from hunting
    elseif hunting > 0 then
        hunting = hunting - 1
        hRes = math.random(5)
        
        if hRes == 1 then
            food = food
            displayRes = true
        elseif hRes == 2 then
            food = food + 1
            displayRes = true
        elseif hRes == 3 then
            food = food + 2
            displayRes = true
            if buildings.tannery[1] == true then
                cloth = cloth + 1
            end
        elseif hRes == 4 then
            food = food + 3
            displayRes = true
            if buildings.tannery[1] == true then
                cloth = cloth + 2
            end
        elseif hRes == 5 then
            food = food + 5
            displayRes = true
            if buildings.tannery[1] == true then
                cloth = cloth + 3
            end
        end

    elseif wood_cutting > 0 then
        wood_cutting = wood_cutting - 1
        wRes = math.random(5)
        
        if wRes == 1 then
            wood = wood
            displayRes = true
        elseif wRes == 2 then
            wood = wood + 1
            displayRes = true
        elseif wRes == 3 then
            wood = wood + 3
            displayRes = true
        elseif wRes == 4 then
            wood = wood + 5
            displayRes = true
        elseif wRes == 5 then
            wood = wood + 7
            displayRes = true
        end
    
    elseif farming > 0 then
        farming = farming - 1
        aRes = math.random(5)
        
        if aRes == 1 then
            food = food + 0
            displayRes = true
        elseif aRes == 2 then
            food = food + 3
            displayRes = true
        elseif aRes == 3 then
            food = food + 6
            displayRes = true
        elseif aRes == 4 then
            food = food + 9
            displayRes = true
        elseif aRes == 5 then
            food = food + 11
            displayRes = true
        end
    end
end

-- Table of buildings
-- First value is bool whether built or not, second is cost in wood
buildings = {
    granary = {false, 10},
    chapel = {false, 20},
    palisade = {false, 5},
    trading_post = {false, 10},
    tannery = {false, 15},
    -- cleared land can be built multiple times, allowing for more farming
    cleared_land = {0,0}
}

-- Construct whichever building the player chooses, subtracting its cost in wood
function constructionEnd()

    resetSelection()

    if grn == 1 then
        buildings.granary[1] = true
        wood = wood - buildings.granary[2]
    elseif chp == 1 then
        buildings.chapel[1] = true
        wood = wood - buildings.chapel[2]
    elseif pal == 1 then
        buildings.palisade[1] = true
        wood = wood - buildings.palisade[2]
    elseif pst == 1 then
        buildings.trading_post[1] = true
        wood = wood - buildings.trading_post[2]
    elseif tan == 1 then
        buildings.tannery[1] = true
        wood = wood - buildings.tannery[2]
    elseif clr == 1 then
        buildings.cleared_land[1] = buildings.cleared_land[1] + 1
    end

    resetConstruction()

    gameState = 'result'
end

-- Reset the construction values to zero
function resetConstruction()
    grn = 0
    chp = 0
    pal = 0
    pst = 0
    tan = 0
    clr = 0
end

-- Reset display showing the task results
function resDisplayReset()
    displayRes = false
    fRes = 0
    hRes = 0
    wRes = 0
    aRes = 0
end

-- Function to check if victory condtions are met
function victoryCheck()
    if food >= (12 * population) and wood >= (12 * population) and cloth >= (3 * population) then
        victory = true
    end
end

-- Function to calculate score
function calculateScore()
    score = food + wood + (2 * cloth)
    if buildings.chapel[1] == true then
        score = score + 40
    end
    if buildings.trading_post[1] == true then
        score = score + 15
    end
end

-- Function to calculate events at the end of every turn
function calculateEvent()
    eventDie = math.random(12)
    if buildings.palisade[1] == false and (eventDie == 1 or eventDie == 2) then
        wolves = true
        wolfattack = math.random(4) + math.random(5)
        food = food - wolfattack
        sounds['wolf']:play()
    elseif eventDie == 3 or eventDie == 4 then
        wolves = true
        wolfattack = math.random(4) + math.random(5)
        food = food - wolfattack
        sounds['wolf']:play()
    elseif eventDie == 12 then
        tartars = true
        population = population + 1
        sounds['tartar']:play()
    else
        noEvent = true
    end
end

-- Little function that plays the defeat sound at game end
function defeatSound()
    if defeatSoundTrigger == true then
        sounds['lightning']:play()
    end
    defeatSoundTrigger = false
end

-- Little function that plays the victory sound at game end
function victorySound()
    if victorySoundTrigger == true then
        sounds['wolf']:stop()
        sounds['tartar']:stop()
        sounds['victory']:play()
        sounds['victory']:setVolume(0.5)
    end
    victorySoundTrigger = false
end

-- Function to deselect previous check mark when selecting a building
function resetSelection()
    grn_selected = false
    chp_selected = false
    pal_selected = false
    pst_selected = false
    tan_selected = false
    clr_selected = false
end
