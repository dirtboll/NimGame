import nimraylib_now/raylib,
       nimraylib_now/raymath,
       glm,
       strformat,
       oids

import params,
       world

# --------------------------------------------------------------------------------------
# Entity
# --------------------------------------------------------------------------------------

type CameraMove = enum
    MOVE_FRONT = 0,
    MOVE_BACK,
    MOVE_RIGHT,
    MOVE_LEFT,
    MOVE_UP,
    MOVE_DOWN

const moveControl = [ params.KeyboardKey.KEY_W, 
                      params.KeyboardKey.KEY_S, 
                      params.KeyboardKey.KEY_D, 
                      params.KeyboardKey.KEY_A, 
                      params.KeyboardKey.KEY_SPACE, 
                      params.KeyboardKey.KEY_LEFT_SHIFT ]

type CameraMode = enum
    CUSTOM = 0, FREE, ORBITAL, FIRST_PERSON, THIRD_PERSON

type 
    Camera3D* = object
        position*: Vector3
        target*: Vector3
        targetDistance*: float32
        up*: Vector3
        fovy*: cfloat
        `type`*: cint
        #rotation*: ptr Vector2

    Camera* = Camera3D

type 
    # Entity* = ref object of RootObj
    #     world*: ref World
    #     position*: Vector3
    #     velocity*: Vector3
    #     oid*: Oid

    PlayerEntity* = object
        world*: ptr World
        position*: Vector3
        velocity*: Vector3
        oid*: Oid

        camera*: Camera
        cameraMode*: CameraMode
        headRotation*: Vector2
        rotation*: Vector2
        previousMousePos*: Vector2

proc createPlayer* (x: float32, y: float32, z: float32, targetX: float32, targetY: float32, targetZ: float32): PlayerEntity =
    result.camera = Camera()

    var pos = Vector3(x: x, y: y, z: z)
    result.camera.position = pos
    result.position = pos

    result.camera.target = Vector3(x: targetX, y: targetY, z: targetZ)
    result.camera.up = Vector3(x: 0.0f, y: 1.0f, z: 0.0f)
    result.camera.fovy = (60.0).cfloat
    result.camera.`type` = (0).cint

    let dx = result.camera.target.x - result.camera.position.x
    let dy = result.camera.target.y - result.camera.position.y
    let dz = result.camera.target.z - result.camera.position.z
    result.camera.targetDistance = sqrt(dx*dx + dy*dy + dz*dz)
    
    result.cameraMode = CameraMode.FIRST_PERSON
    result.oid = genOid()
    result.previousMousePos = getMousePosition()

proc createPlayer* (): PlayerEntity =
    return createPlayer(0.0,0.0,0.0,0.0,0.0,0.0)

proc updatePlayer* (player: ptr PlayerEntity) = 
    var direction = [ isKeyDown(moveControl[MOVE_FRONT.cint].cint),
                      isKeyDown(moveControl[MOVE_BACK.cint].cint),
                      isKeyDown(moveControl[MOVE_RIGHT.cint].cint),
                      isKeyDown(moveControl[MOVE_LEFT.cint].cint),
                      isKeyDown(moveControl[MOVE_UP.cint].cint),
                      isKeyDown(moveControl[MOVE_DOWN.cint].cint) ]

    var mouseDelta = subtract(getMousePosition(), player.previousMousePos)
    player.previousMousePos = getMousePosition()

    case player.cameraMode:
        of CameraMode.FIRST_PERSON:
            # Player Head rotation calcuation
            player.headRotation.x += mouseDelta.x * -MOUSE_SENSITIVITY
            player.headRotation.y += mouseDelta.y * -MOUSE_SENSITIVITY

            # Angle clamp
            if player.headRotation.y > CAMERA_FIRST_PERSON_MIN_CLAMP*DEG2RAD:
                player.headRotation.y = CAMERA_FIRST_PERSON_MIN_CLAMP*DEG2RAD
            elif player.headRotation.y < CAMERA_FIRST_PERSON_MAX_CLAMP*DEG2RAD: 
                player.headRotation.y = CAMERA_FIRST_PERSON_MAX_CLAMP*DEG2RAD;

            # Calculate Player position
            player.position.x += ( sin(player.headRotation.x) * direction[MOVE_BACK.cint].float32 - 
                                   sin(player.headRotation.x) * direction[MOVE_FRONT.cint].float32 -
                                   cos(player.headRotation.x) * direction[MOVE_LEFT.cint].float32  +
                                   cos(player.headRotation.x) * direction[MOVE_RIGHT.cint].float32) / PLAYER_MOVEMENT_SENSITIVITY;

            player.position.y += ( sin(player.headRotation.y) * direction[MOVE_FRONT.cint].float32 -
                                   sin(player.headRotation.y) * direction[MOVE_BACK.cint].float32 +
                                   1.0f * direction[MOVE_UP.cint].float32 - 1.0f * direction[MOVE_DOWN.cint].float32) / PLAYER_MOVEMENT_SENSITIVITY;

            player.position.z += ( cos(player.headRotation.x) * direction[MOVE_BACK.cint].float32 -
                                   cos(player.headRotation.x) * direction[MOVE_FRONT.cint].float32 +
                                   sin(player.headRotation.x) * direction[MOVE_LEFT.cint].float32 -
                                   sin(player.headRotation.x) * direction[MOVE_RIGHT.cint].float32) / PLAYER_MOVEMENT_SENSITIVITY;

            player.camera.position = player.position

            # Recalculate camera target considering translation and rotation
            var translation = translate(0, 0, (player.camera.targetDistance/CAMERA_FREE_PANNING_DIVIDER));
            var rotation = rotateXYZ(Vector3(x: PI*2 - player.headRotation.y, y: PI*2 - player.headRotation.x, z: 0.0f));
            var transform = multiply(translation, rotation);

            player.camera.target.x = player.camera.position.x - transform.m12
            player.camera.target.y = player.camera.position.y - transform.m13
            player.camera.target.z = player.camera.position.z - transform.m14

        of CameraMode.THIRD_PERSON:
            discard
        of CameraMode.ORBITAL:
            discard
        of CameraMode.FREE:
            discard
        of CameraMode.CUSTOM:
            discard

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
# Utils
# --------------------------------------------------------------------------------------

converter toCamera3D(camera: var Camera3D): raylib.Camera3D = 
    result.position = camera.position
    result.target = camera.target
    result.up = camera.up
    result.fovy = camera.fovy
    result.`type` = camera.`type`

# --------------------------------------------------------------------------------------
# Main Game
# --------------------------------------------------------------------------------------

const MaxColumns = 20

# Initialization
const screenWidth = 1366
const screenHeight = 760

initWindow screenWidth, screenHeight, "raylib [core] example - 3d camera first person"

var playerEntity = createPlayer(30.0, 32.0, -14.0, -32.0, 2.0, -32.0)
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
            drawCube Vector3(x: x.cfloat, y: height/2, z: z.cfloat), 1.0, height, 1.0, Gray
            drawCubeWires Vector3(x: x.cfloat, y: height/2, z: z.cfloat), 1.0, height, 1.0, Black

    drawCube playerEntity.camera.target, 0.1, 0.1, 0.1, Black

    endMode3D()

    drawRectangle 10, 10, 380, 90, fade(Skyblue, 0.5)
    drawRectangleLines 10, 10, 380, 90, Blue

    drawText "First person camera default controls:", 20, 20, 10, Black
    drawText "- Move with keys: W, A, S, D, Space, LShift, J, K, N, M, Arrows", 40, 40, 10, Darkgray
    drawText "- Mouse move to look around", 40, 60, 10, Darkgray
    drawText fmt"- Pos {playerEntity.position.repr}", 40, 110, 10, Darkgray
    drawText fmt"- Target pos: {playerEntity.camera.target.repr}", 40, 130, 10, Darkgray

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

