--[[----------------------------------------------------------------------------

  Script Name:
  "Performance"

  Description:
  Adds functionality (to the previous script) to measure the timing performance.

  How to Run:
  To show this sample script, set it as main (right-click -> "Set as main")
  before running the app. Then start by running the app (F5) or debugging (F7+F10).
  Set a breakpoint on the first row inside the main function to debug step-by-step.
  See the results in the image viewer on the DevicePage.

  More Information:
  See the first script "Description".

------------------------------------------------------------------------------]]

--Start of Global Scope---------------------------------------------------------

local camera = Image.Provider.Camera.create()

local config = Image.Provider.Camera.V2DConfig.create()
config:setBurstLength(0) -- Continuous acquisition
config:setFrameRate(5) -- Hz
config:setShutterTime(600) -- us
config:setGainFactor(1.2)

camera:setConfig(config)

-- Set up recording to MicroSD card
local pngFormatter = Image.Format.PNG.create()
local recording = false -- Set to 'true' to activate recording to MicroSD card
local imCounter = 1 -- Initialize counter for the file name suffix

-- Set up viewer and graphical overlays
local viewer = View.create()

local textDeco = View.TextDecoration.create()
textDeco:setSize(50)

local decoPass = View.ShapeDecoration.create()
decoPass:setLineColor(0, 230, 0) -- Green for "Pass"
decoPass:setLineWidth(5)

local decoFail = View.ShapeDecoration.create()
decoFail:setLineColor(230, 0, 0) -- Red for "Fail"
decoFail:setLineWidth(5)

-- Set up result LED
local passFailLED = LED.create('RESULT_LED')

-- Initiate HALCON procedure
local avgInt = Halcon.create()
avgInt:loadProcedure('resources/AverageIntensity.hdvp')

local timerX = DateTime.getTimestamp() -- System clock at end of initializing global scope

--End of Global Scope-----------------------------------------------------------

--Start of Function and Event Scope---------------------------------------------

local function main()
  camera:enable()
  camera:start()
end
Script.register('Engine.OnStarted', main)

---@param im Image
---@param metaData SensorData
local function grabImage(im, metaData)
  -- System clock in ms at time of image grab
  local tic1 = DateTime.getTimestamp()

  -- Intensity measurement region
  local w, h = im:getSize()
  local rectCenter = Point.create(w / 2, h / 2)
  local rect = Shape.createRectangle(rectCenter, 400, 300, 0)

  -- Intensity measurement
  avgInt:setImage('Image', im)
  avgInt:setRegion('ROI', rect)
  local result = avgInt:execute()
  local average = result:getDouble('Mean')
  print('Average intensity = ' .. math.floor(average))

  -- Image processing time
  local toc1 = DateTime.getTimestamp()
  local processingTime = math.abs(toc1 - tic1)
  print('Image processing time = ' .. math.floor(processingTime) .. ' ms')

  -- Result overlay
  viewer:clear()
  local imgID = viewer:addImage(im)
  textDeco:setPosition(rectCenter:getX() - 190, rectCenter:getY() - 155)
  local threshold = 150
  if average <= threshold then
    passFailLED:setColor('red')
    passFailLED:activate()
    textDeco:setColor(230, 0, 0)
    viewer:addText(tostring(average), textDeco, nil, imgID)
    viewer:addShape(rect, decoFail, nil, imgID)
  else
    passFailLED:setColor('green')
    passFailLED:activate()
    viewer:addText(tostring(average), textDeco, nil, imgID)
    textDeco:setColor(0, 230, 0)
    viewer:addShape(rect, decoPass, nil, imgID)
  end
  viewer:present()

  -- Record images to MicroSD card
  if recording == true then
    local pngBuffer = Image.Format.PNG.encode(pngFormatter, im)
    local imageFile = File.open('/sdcard/0/image_' .. imCounter .. '.png', 'wb')
    imCounter = imCounter + 1
    imageFile:write(pngBuffer)
    imageFile:close()
  end

  -- Visualization time (and recording, if enabled)
  local toc2 = DateTime.getTimestamp()
  local visualizationTime = math.abs(toc2 - tic1)
  print('Visualization time = ' .. math.floor(visualizationTime) .. ' ms')

  -- Cycle time
  local timerY = DateTime.getTimestamp()
  local cycleTime = math.abs(timerY - timerX)
  timerX = timerY
  print(
    'Cycle time = ' ..
    cycleTime .. ' ms (' .. math.floor(1000 / cycleTime * 10) / 10 .. ' Hz)'
  )
  print('---------------------------')
end
camera:register('OnNewImage', grabImage)

--End of Function and Event Scope--------------------------------------------------
