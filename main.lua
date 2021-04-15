-- housekeeping stuff

display.setStatusBar(display.HiddenStatusBar)
system.activate("multitouch")
local centerX = display.contentCenterX
local centerY = display.contentCenterY

-- set up forward references

local spawnEnemy
local gameTitle
local scoreTxt
local score = 0
local highscoreTxt
local highscore
local streak = 0
local hitPlanet
local planet
local changeBg
local animateTitle
local speedBump = 0
local bgIndex = 0
local bgTimer
local titleTimer
local onScreenEnemies
local enemies
local gameOn = false
local resizeImage
local saveScore
local loadScore
local halfScreenHeight = display.contentHeight / 2
local halfScreenWidth = display.contentWidth / 2

-- preload audio

local sndKill = audio.loadSound("boing-1.wav")
local sndBlast = audio.loadSound("blast.mp3") -- audio file courtesy Mike Koenig
local sndLose = audio.loadSound("wahwahwah.mp3")

-- create play screen

local function createPlayScreen()
	bg1 = display.newImage("colorbar1.png")
	resizeImage(bg1)
	bg2 = display.newImage("colorbar2.png")
	resizeImage(bg2); bg2.isVisible = false;
	bg3 = display.newImage("colorbar3.png")
	resizeImage(bg3); bg3.isVisible = false;
	bg4 = display.newImage("colorbar4.png")
	resizeImage(bg4); bg4.isVisible = false;
	bg5 = display.newImage("colorbar5.png")
	resizeImage(bg5); bg5.isVisible = false;

	local highscoreFilename = "highscore.data"
	local loadedHighscore = loadScore(highscoreFilename)
	highscore = tonumber(loadedHighscore)

	local ballSheetAyyLol = graphics.newImageSheet("ballSprite.png", {width = 128, height = 128, numFrames = 6, sheetContentWidth = 768, sheetContentHeight = 128})
	local ballSequenceData = {name = "health", start = 1, count = 6, time = 100}
	planet = display.newSprite(ballSheetAyyLol, ballSequenceData)
	planet.x = centerX;
	planet.y = centerY * 2; -- starts off the screen.
	planet.alpha = 0
	-- 2000 miliseconds
	-- transitions current to new Y
	transition.to( background, { time = 1000, alpha = 1,  y = centerY, x = centerX } ) 
	local function showTitle()
		gameTitle = display.newImage("gametitle.png")
		gameTitle.x = centerX
		-- starts invisible with alpha 0 and 4 times its original size; in half a second time, becomes completely visible (alpha 1) and shrinks back to normal size.
		gameTitle.alpha = 0
		gameTitle:scale(4, 4)
		transition.to(gameTitle, {time = 500, alpha = 1, xScale = 1, yScale = 1})
		titleTimer = timer.performWithDelay(250, animateTitle, 0)
		enemies = display.newGroup()
		startGame()
	end
	-- positions planet on center of the screen.
	planet:scale(10,10)
	transition.to( planet, { time = 1000, alpha = 1, y = centerY, xScale = 1, yScale = 1, onComplete = showTitle } ) 

	scoreTxt = display.newText("Score: 0", 0, 0, "2Dumb", 22)
	scoreTxt.x = centerX
	scoreTxt.y = 10
	scoreTxt.alpha = 0
	highscoreTxt = display.newText("Highcore: " .. highscore, 0, 0, "2Dumb", 22)
	highscoreTxt.x = centerX
	highscoreTxt.y = scoreTxt.y + 22 + 10 -- score text y value, score text font size and an arbitrary value
	highscoreTxt.alpha = 0
end	

-- centers and grows image
function resizeImage(img)
	img.xScale = (2.4 * halfScreenWidth) / img.contentWidth
	img.yScale = (2.3 * halfScreenHeight) / img.contentHeight
	img.x = halfScreenWidth
	img.y = halfScreenHeight
end
-- game functions; most are referenced at the top of the file.

function spawnEnemy()
	--local enemypics = {"beetleship.png","octopus.png", "rocketship.png"}
	--local enemypics = {"enemy1.png","enemy2.png", "enemy3.png"}
	--local enemy = display.newImage(enemypics[math.random (#enemypics)])
	local function createEnemy()
		local enemy = display.newImage("enemy" .. math.random(1, 5) .. ".png")
		-- when ship is tapped, run shipSmash function on it
		enemy:addEventListener ( "touch", shipSmash )
		local offsetX
		local offsetY
		if math.random(2) == 1 then
			enemy.x = math.random ( -100, -10 )
			--offsetX = enemy.x * -1
			offsetX = -50
		else
			enemy.x = math.random ( (halfScreenHeight * 2) + 10, (halfScreenWidth * 2) + 100 )
			--offsetX = enemy.x - (halfScreenHeight * 2)
			offsetX = 50
			enemy.xScale = -1
		end
		enemy.y = math.random (halfScreenHeight * 2)
		if enemy.y < halfScreenHeight then
			offsetY = -50
		else
			offsetY = 50
		end
		enemy.trans = transition.to ( enemy, { x = centerX + offsetX, y = centerY + offsetY, rotation = math.random(360, 1080), time = math.random(2500 - speedBump, 4500 - speedBump), onComplete = hitPlanet, tag = "enemyTransition"} )
		enemies:insert(enemy)
		onScreenEnemies = onScreenEnemies + 1
	end

	if (onScreenEnemies < 2) then
		createEnemy()
		createEnemy()
		createEnemy()
		if speedBump < 2400 then
			speedBump = speedBump + 25
		end
	end
end


function startGame()
	--[[local text = display.newText( "Tap here to start. Protect the planet!", 0.5, 0.5, "2Dumb", 23 )
	text.x = centerX
	text.y = (halfScreenHeight * 2) - 30
	--text:setFillColor(0, 0, 0)]]
	local playBtn = display.newImage("playBtn.png")
	playBtn.x = centerX
	playBtn.y = (halfScreenHeight * 2) - 40
	-- function gets called twice, 'gameOn' makes sure that critical, variable-resetting stuff only get called once
	local function goAway(event)
		display.remove(event.target)
		if gameOn == false then
			timer.cancel(titleTimer)
			gameOn = true
			planet:setFrame(1)
			display.remove(event.target)
			playBtn = nil
			display.remove(gameTitle)
			enemies = display.newGroup()
			onScreenEnemies = 0
			spawnEnemy()
			scoreTxt.alpha = 1
			scoreTxt.text = "Score: 0"
			score = 0
			highscoreTxt.alpha = 0 -- makes highscore txt go away
			planet.numHits = 5
			planet.alpha = 1
			speedBump = 0
			bgTimer = timer.performWithDelay(500, changeBg, 0)
		end
	end
	playBtn:addEventListener ( "tap", goAway )
end

local function animateBall()
	local function reAnimateBall()
		transition.to (planet, { time = 100, xScale = 1, yScale = 1})
	end
	transition.to (planet, { time = 100, xScale = 1.3, yScale = 1.3, onComplete = reAnimateBall})
end

local function planetDamage()
	planet.numHits = planet.numHits - 1
	planet:setFrame(5 - (planet.numHits - 1))
	--planet.alpha = planet.numHits / 5
	if planet.numHits < 1 then
		onScreenEnemies = 0
		timer.performWithDelay (500, startGame)
		audio.play(sndLose)
		timer.cancel(bgTimer)
		transition.cancel("enemyTransition") -- cancels all enemy transitions
		enemies:removeSelf()
		gameOn = false
		if score > highscore then
			local highscoreFilename = "highscore.data"
			saveScore(highscoreFilename, score)
			highscore = score
			highscoreTxt.text = "NEEEEEW Highscore: " .. highscore
		else
			highscoreTxt.text = "Highscore: " .. highscore
		end
		highscoreTxt.alpha = 1
	else
		local function goAway(obj)
			planet.xScale = 1
			planet.yScale = 1
		end
		animateBall()
	end
end


function hitPlanet(obj)
	display.remove( obj )
	streak = 0
	if gameOn == true then
		planetDamage()
		onScreenEnemies = onScreenEnemies - 1
		audio.play(sndBlast)
		if planet.numHits > 1 then
			spawnEnemy()
		end
	end
end


function shipSmash(event)
	-- only on tap, should not trigger anything if touch is cancelled or moving
	if (event.phase == "began") then
		local obj = event.target -- the enemy being tapped
		enemies:remove(obj)
		display.remove( obj )
		audio.play(sndKill)
		transition.cancel ( event.target.trans )
		score = score + 28 + streak
		streak = streak + 2
		scoreTxt.text = "Score: " .. score
		onScreenEnemies = onScreenEnemies - 1
		spawnEnemy()
	end
	return true
end

function changeBg()
	if bgIndex == 0 then
		bg1.isVisible = false;
		bg2.isVisible = true;
	elseif bgIndex == 1 then
		bg2.isVisible = false;
		bg3.isVisible = true;
	elseif bgIndex == 2 then
		bg3.isVisible = false;
		bg4.isVisible = true;
	elseif bgIndex == 3 then
		bg4.isVisible = false;
		bg5.isVisible = true;
	elseif bgIndex == 4 then
		bg5.isVisible = false;
		bg1.isVisible = true;
	end
	bgIndex = (bgIndex + 1) % 5;
end

function animateTitle()
	local function animate2()
		transition.to(gameTitle, {time = 125, xScale = 0.7, yScale = 0.7})
	end
	local function animate1()
		transition.to(gameTitle, {time = 125, xScale = 1.5, yScale = 1.5, onComplete = animate2})
	end
	animate1()
end

function saveScore(strFilename, strValue)
	-- will save specified value to specified file
    local theFile = strFilename
    local theValue = strValue
    local path = system.pathForFile( theFile, system.DocumentsDirectory )
    -- io.open opens a file at path. returns nil if no file found
    local file = io.open( path, "w+" )
    if file then
      -- write game score to the text file
      file:write( theValue )
      io.close( file )
	end
end

function loadScore(strFilename)
	-- will load specified file, or create new file if it doesn't exist
    local theFile = strFilename
    local path = system.pathForFile( theFile, system.DocumentsDirectory )
    -- io.open opens a file at path. returns nil if no file found
    local file = io.open( path, "r" )
      if file then
      -- read all contents of file into a string
        local contents = file:read( "*a" )
        io.close( file )
        return contents
      else
        -- create file b/c it doesn't exist yet
        file = io.open( path, "w" )
        file:write( "0" )
        io.close( file )
        return "0"
    end
end

createPlayScreen()