function love.load(arg)
  love.window.setMode(900, 700)
  love.graphics.setBackgroundColor(0, 102, 255)

  world = love.physics.newWorld(0, 400, false)
  world:setCallbacks(beginContact, endContact, preSolve, postSolve)

  blip_sound = love.audio.newSource('sounds/blip.wav', 'static')
  nature_music = love.audio.newSource('sounds/nature.ogg', 'static')

  nature_music:play()

  sprites = {}
  sprites.coin_sheet = love.graphics.newImage('sprites/coin_sheet.png')
  sprites.player_jump = love.graphics.newImage('sprites/player_jump.png')
  sprites.player_stand = love.graphics.newImage('sprites/player_stand.png')

  require('player')
  require('coin')
  require('show')
  anim8 = require('anim8/anim8')
  sti = require('tiles/sti')
  cameraFile = require('camera/camera')

  camera = cameraFile()
  gameState = 1
  myFont = love.graphics.newFont(30)
  timer = 0

  platforms = {}

  saveData = {}
  saveData.bestTime = 999

  fileInfo = love.filesystem.getInfo('data.lua')
  if fileInfo == nil then
    local data = love.filesystem.load('data.lua')
    data()
  end

  gameMap = sti('maps/plaformerGameMap.lua')

  for i,object in ipairs(gameMap.layers['Platforms'].objects) do
    spawnPlatform(object.x, object.y, object.width, object.height)
  end

  for i,coin in ipairs(gameMap.layers['Coins'].objects) do
    spawnCoin(coin.x, coin.y)
  end
end

function love.update(dt)
  world:update(dt)
  playerUpdate(dt)
  gameMap:update(dt)
  coinUpdate(dt)

  camera:lookAt(player.body:getX(), player.body:getY(), love.graphics.getHeight())

  for i,c in ipairs(coins) do
    c.animation:update(dt)
  end

  if gameState == 2 then
    timer = timer + dt
  end

  if #coins == 0 and gameState == 2 then
    gameState = 1
    player.body:setPosition(400, 100)

    if #coins == 0 then
      for i,coin in ipairs(gameMap.layers['Coins'].objects) do
        spawnCoin(coin.x, coin.y)
      end
    end

    if timer < saveData.bestTime then
      saveData.bestTime = math.floor(timer)
      love.filesystem.write('data.lua', table.show(saveData, "saveData"))
    end

    nature_music:seek(0)
    nature_music:play()
  end
end

function love.draw()
  camera:attach()

  gameMap:drawLayer(gameMap.layers['Tile Layer 1'])

  love.graphics.draw(player.sprite, player.body:getX(), player.body:getY(),
        nil, player.direction, 1, sprites.player_stand:getWidth() / 2, sprites.player_stand:getHeight() / 2)

  for i,c in ipairs(coins) do
    c.animation:draw(sprites.coin_sheet, c.x, c.y, nil, nil, nil, 20.5, 21)
  end

  camera:detach()

  if gameState == 1 then
    love.graphics.setFont(myFont)
    love.graphics.printf("Press any key to begin!", 0, 50, love.graphics:getWidth(), "center")
    love.graphics.printf("Best time: " .. saveData.bestTime, 0, 150, love.graphics:getWidth(), "center")
  end

  love.graphics.print("Time: " .. math.floor(timer), 10, 660)
end

function love.keypressed(key, scancode, isrepeat)
  if key == "up" and player.grounded == true then
    player.body:applyLinearImpulse(0, -2500)
  end

  if gameState == 1 then
    gameState = 2
    timer = 0
  end
end

function spawnPlatform (x, y, width, height)
  local platform = {}
  platform.body = love.physics.newBody(world, x, y, "static")
  platform.shape = love.physics.newRectangleShape(width / 2, height / 2, width, height)
  platform.fixture = love.physics.newFixture(platform.body, platform.shape)
  platform.width = width
  platform.height = height

  table.insert(platforms, platform)
end

function beginContact(a, b, coll)
  player.grounded = true
end

function endContact(a, b, coll)
  player.grounded = false
end

function distanceBetween (x1, y1, x2, y2)
  return math.sqrt((y2 - y1)^2 + (x2 - x1)^2)
end
