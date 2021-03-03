import nimraylib_now/raylib,
       nimraylib_now/raymath,
       glm,
       math,
       strformat,
       oids

import params,
       world,
       entity

# --------------------------------------------------------------------------------------
# Utils
# --------------------------------------------------------------------------------------

proc mapRange(val: float64, fromMin: float64, fromMax: float64, toMin: float64, toMax: float64): float64 =
    return toMin+((toMax-toMin)/(fromMax-fromMin))*(val-fromMin)



# --------------------------------------------------------------------------------------
# Physics
# --------------------------------------------------------------------------------------

# type AABB* = ref object of RootObj 
#     entity: ref Entity
#     position: ref Vector3
#     extend: array[2, ref Vector3] #min-max

# type CollisionResult* = ref object of RootObj
#     collided: bool
#     deep: Vector3
#     objects: array[2, ref AABB]

# proc testCollide* (obj1: ref AABB, obj2: ref AABB): ref CollisionResult = 
#     result.objects = [obj1, obj2]

#     let dist1 = subtract(obj2.extend[0][], obj1.extend[1][])
#     let dist2 = subtract(obj1.extend[0][], obj2.extend[1][])
#     result.deep = max(dist1, dist2)

#     var maxDist = max(result.deep.x, result.deep.y)
#     maxDist = max(maxDist, result.deep.z)
#     result.collided = maxDist < 0

# --------------------------------------------------------------------------------------
# Main Game
# --------------------------------------------------------------------------------------

# const MaxColumns = 20

# Initialization
const screenWidth = 1366
const screenHeight = 760

initWindow screenWidth, screenHeight, "raylib [core] example - 3d camera first person"

setMousePosition((getScreenWidth()/2).cint, (getScreenHeight()/2).cint)
var playerEntity = createPlayer(Vector3(x:32.0,y:80.0,z:32.0),Vector2(x: degToRad(180.0),y: degToRad(-90.0)))

var chunk = Chunk()
generateChunk(chunk)
#  Generates some random columns
# var 
#     heights: array[0..MAX_COLUMNS, float]
#     positions: array[0..MAX_COLUMNS, Vector3]
#     colors: array[0..MAX_COLUMNS, Color]

# for i in 0..<MaxColumns:
#     heights[i] = getRandomValue(1, 12).float
#     positions[i] = Vector3(x: getRandomValue(-15, 15).float, y: heights[i]/2, z: getRandomValue(-15, 15).float)
#     colors[i] = Color(r: getRandomValue(20, 255).uint8, g: getRandomValue(10, 55).uint8, b: 30, a: 255)

setTargetFPS 60                         
# --------------------------------------------------------------------------------------

var lastFrameTime:float = 0
var lastTime:float

disableCursor()

#  Main game loop
while not windowShouldClose():              #  Detect window close button or ESC key
    playerEntity.addr.updatePlayer()

    var chunkChanged = false
    if isKeyDown(params.KeyboardKey.KEY_LEFT.cint):
        world.offsetX -= 1
        chunkChanged = true
    if isKeyDown(params.KeyboardKey.KEY_RIGHT.cint):
        world.offsetX += 1
        chunkChanged = true
    if isKeyDown(params.KeyboardKey.KEY_UP.cint):
        world.offsetZ -= 1
        chunkChanged = true
    if isKeyDown(params.KeyboardKey.KEY_DOWN.cint):
        world.offsetZ += 1
        chunkChanged = true
    if isKeyPressed(params.KeyboardKey.KEY_J.cint):
        world.zoom -= 1
        chunkChanged = true
    if isKeyPressed(params.KeyboardKey.KEY_K.cint):
        world.zoom += 1
        chunkChanged = true
    if isKeyPressed(params.KeyboardKey.KEY_N.cint):
        world.heightMult -= 1
        chunkChanged = true
    if isKeyPressed(params.KeyboardKey.KEY_M.cint):
        world.heightMult += 1
        chunkChanged = true

    if chunkChanged:
        generateChunk(chunk)

    beginDrawing()

    clearBackground RayWhite

    beginMode3D playerEntity.camera

    # drawPlane Vector3(x: 0.0f, y: 0.0f, z: 0.0f), Vector2(x: 32.0f, y: 32.0f), LIGHTGRAY #  Draw ground
    # drawCube Vector3(x: -16.0f, y: 2.5f, z: 0.0f), 1.0f, 5.0f, 32.0f, BLUE               #  Draw a blue wall
    # drawCube Vector3(x: 16.0f, y: 2.5f, z: 0.0f), 1.0f, 5.0f, 32.0f, LIME                #  Draw a green wall
    # drawCube Vector3(x: 0.0f, y: 2.5f, z: 16.0f), 32.0f, 5.0f, 1.0f, GOLD                #  Draw a yellow wall

    # #  Draw some cubes around
    # for i in 0..<MaxColumns:
    #     drawCube positions[i], 2.0, heights[i], 2.0, colors[i]
    #     drawCubeWires positions[i], 2.0, heights[i], 2.0, Maroon

    for z in 0..<CHUNK_DIMENSION[2]:
        for x in 0..<CHUNK_DIMENSION[0]:
            let height = chunk.heightMap[x][z]
            let rgb = mapRange(height, 0.0, 10.0, 0.0, 255.0)
            drawCube Vector3(x: x.cfloat/2, y: height/2, z: z.cfloat/2), 0.5, height, 0.5, raylib.Color(r: rgb.uint8, g: rgb.uint8, b: rgb.uint8, a: 255.uint8)
            #drawCubeWires Vector3(x: x.cfloat, y: height/2, z: z.cfloat), 1.0, height, 1.0, Black

    drawCube playerEntity.camera.target, 0.1, 0.1, 0.1, Black

    endMode3D()

    drawRectangle 10, 10, 380, 90, fade(Skyblue, 0.5)
    drawRectangleLines 10, 10, 380, 90, Blue

    drawText "First person camera default controls:", 20, 20, 10, Black
    drawText "- Move with keys: W, A, S, D, Space, LShift, J, K, N, M, Arrows", 40, 40, 10, Darkgray
    drawText "- Mouse move to look around", 40, 60, 10, Darkgray
    drawText fmt"- Pos {playerEntity.position.repr}", 40, 110, 10, Darkgray
    #drawText fmt"- Rot: {maxHeight}", 40, 130, 10, Darkgray

    lastTime += getFrameTime()
    if lastTime >= 0.1: 
      lastFrameTime = getFrameTime()
      lastTime = 0
    
    drawText fmt"- FPS: {(int) 1/lastFrameTime}", 40, 80, 10, Darkgray

    endDrawing()
    # ----------------------------------------------------------------------------------

#  De-Initialization
# --------------------------------------------------------------------------------------
closeWindow()         #  Close window and OpenGL context
# --------------------------------------------------------------------------------------

