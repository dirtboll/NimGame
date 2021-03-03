import
    math, strformat,
    nimraylib_now/raylib,
    entity/player

# Init window
initWindow getScreenWidth(), getScreenHeight(), "NimGame Demo"

# Reset mosue position
setMousePosition((getScreenWidth()/2).cint, (getScreenHeight()/2).cint)
disableCursor()
#setTargetFPS 60

#  Generates some random columns
const MaxColumns = 20
var
    heights: array[0..MaxColumns, float]
    positions: array[0..MaxColumns, Vector3]
    colors: array[0..MaxColumns, Color]

for i in 0..<MaxColumns:
    heights[i] = getRandomValue(1, 12).float
    positions[i] = (x: getRandomValue(-15, 15).float, y: heights[i]/2, z: getRandomValue(-15, 15).float)
    colors[i] = Color(r: getRandomValue(20, 255).uint8, g: getRandomValue(10, 55).uint8, b: 30.uint8, a: 255.uint8)

# TO-DO: create player and world
var 
    pPos = (x: 4.0, y: 2.0, z: 4.0)
    pRot = (x: degToRad(0.0),y: degToRad(0.0))
    playerEntity = createPlayer(pPos, pRot)

# FPS Calc
var lastFrameTime:float = 0
var lastTime:float

while not windowShouldClose():
    beginDrawing()
    clearBackground Raywhite

    # TO-DO: Update player and world
    playerEntity.updatePlayer()

    beginMode3D playerEntity.camera

    drawPlane (x: 0.0, y: 0.0, z: 0.0), (x: 32.0, y: 32.0), Lightgray #  Draw ground
    drawCube (x: -16.0, y: 2.5, z: 0.0), 1.0, 5.0, 32.0, Blue               #  Draw a blue wall
    drawCube (x: 16.0, y: 2.5, z: 0.0), 1.0, 5.0, 32.0, Lime                #  Draw a green wall
    drawCube (x: 0.0, y: 2.5, z: 16.0), 32.0, 5.0, 1.0, Gold                #  Draw a yellow wall

    #  Draw some cubes around
    for i in 0..<MaxColumns:
        drawCube positions[i], 2.0, heights[i], 2.0, colors[i]
        drawCubeWires positions[i], 2.0, heights[i], 2.0, Maroon

    # TO-DO: draw chunk models

    endMode3D()

    drawRectangle 10, 10, 220, 130, fade(Skyblue, 0.5)
    drawRectangleLines 10, 10, 220, 130, Blue

    drawText "First person camera default controls:", 20, 20, 10, Black
    drawText "- Move with keys: W, A, S, D", 40, 40, 10, Darkgray
    drawText "- Mouse move to look around", 40, 60, 10, Darkgray

    lastTime += getFrameTime()
    if lastTime >= 0.1: 
      lastFrameTime = getFrameTime()
      lastTime = 0
    drawText fmt"- FPS: {(int) 1/lastFrameTime}", 40, 80, 10, Darkgray

    drawText fmt"- Loc: {playerEntity.position[]}", 40, 100, 10, Darkgray
    drawText fmt"- Loc: {playerEntity.camera.position[]}", 40, 120, 10, Darkgray

    # TO-DO: draw stats

    endDrawing()

closeWindow()