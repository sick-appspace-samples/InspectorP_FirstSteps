--[[----------------------------------------------------------------------------

  Script Name:
  "LiveImage"

  Description:
  Set up the camera to take live images continuously.

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
config:setBurstLength(0)    -- Continuous acquisition
config:setFrameRate(5)      -- Hz
config:setShutterTime(600)  -- us
config:setGainFactor(1.2)

camera:setConfig(config)

-- Set up viewer
local viewer = View.create()

--End of Global Scope-----------------------------------------------------------

--Start of Function and Event Scope---------------------------------------------

local function main()
  camera:enable()
  camera:start()
end
Script.register("Engine.OnStarted", main)

local function grabImage(im, metaData)
  viewer:clear()
  viewer:addImage(im)
  viewer:present()
  print(metaData:toString())
end
camera:register("OnNewImage", grabImage)

--End of Function and Event Scope--------------------------------------------------
