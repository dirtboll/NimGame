import
    math, strformat,
    nimraylib_now/raylib,
    entity/player,
    world/world,
    tables

# Init window
initWindow getScreenWidth(), getScreenHeight(), "NimGame Demo"

# Reset mosue position
setMousePosition((getScreenWidth()/2).cint, (getScreenHeight()/2).cint)
disableCursor()
#setTargetFPS 60

# TO-DO: create player and world
var 
    pPos = (x: 4.0, y: 2.0, z: 4.0)
    pRot = (x: degToRad(0.0),y: degToRad(0.0))
    playerEntity = createPlayer(pPos, pRot)
    pWorld = createWorld("overworld", playerEntity.oid, pPos.x, pPos.y, pPos.z)

# FPS Calc
var lastFrameTime:float = 0
var lastTime:float

while not windowShouldClose():
    beginDrawing()
    clearBackground Raywhite

    # TO-DO: Update player and world
    playerEntity.updatePlayer()

    beginMode3D playerEntity.camera

    # TO-DO: draw chunk models

    endMode3D()

    # TO-DO: draw stats
    drawText "First person camera default controls:", 20, 20, 10, Black
    drawText "- Move with keys: W, A, S, D, Space, LShift", 40, 40, 10, Darkgray
    drawText "- Mouse move to look around", 40, 60, 10, Darkgray

    lastTime += getFrameTime()
    if lastTime >= 0.1: 
      lastFrameTime = getFrameTime()
      lastTime = 0
    drawText fmt"- FPS: {(int) 1/lastFrameTime}", 40, 80, 10, Darkgray

    drawText fmt"- Location: {playerEntity.position[]}", 40, 100, 10, Darkgray

    

    endDrawing()

closeWindow()