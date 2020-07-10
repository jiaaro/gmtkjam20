local lg = love.graphics

function drawJoystickDebug()
  local joystick = _G.joystick
  local joysticks = _G.joysticks

  local buttonsdown = ""
  for i = 1, joystick:getButtonCount() do
    buttonsdown = buttonsdown .. string.format("Button %s: %s\n", i, joystick:isDown(i))
  end

  lg.print(buttonsdown, 300, 10)

  local vendorID, productID, productVersion = joystick:getDeviceInfo( )
  lg.print(string.format([[
    joysticks: %s
    isGamepad: %s
    axis count: %s
    button count: %s
    device info: %s, %s, %s

    left stick: %0.2f, %0.2f
    right stick: %0.2f, %0.2f
    triggers: %0.2f <--> %0.2f

    Buttons:
      X down: %s
      O down: %s
      [] down: %s
      ∆ down: %s

      up:    %s
      down:  %s
      left:  %s
      right: %s

      L1: %s
      R1: %s

      L3: %s
      R3: %s

      touchpad: %s
  ]],
      #joysticks,
      joystick:isGamepad(),
      joystick:getAxisCount(),
      joystick:getButtonCount(),
      vendorID, productID, productVersion,
      joystick:getGamepadAxis("leftx"), joystick:getGamepadAxis("lefty"),
      joystick:getGamepadAxis("rightx"), joystick:getGamepadAxis("righty"),
      joystick:getGamepadAxis("triggerleft"), joystick:getGamepadAxis("triggerright"),
      joystick:isDown(1), -- x
      joystick:isDown(2), -- circle
      joystick:isDown(3), -- square
      joystick:isDown(4), -- triangle
      joystick:isDown(12), -- up
      joystick:isDown(13), -- down
      joystick:isDown(14), -- left
      joystick:isDown(15), -- right

      joystick:isDown(10), -- L1
      joystick:isDown(11), -- R1

      joystick:isDown(8), -- L3
      joystick:isDown(9), -- R3
      joystick:isDown(16), -- touchpad pressed

      ""
  ), 0, 10)
end
