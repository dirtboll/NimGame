import nimraylib_now/raylib,
       nimraylib_now/raymath,
       glm,
       strformat,
       oids

# --------------------------------------------------------------------------------------
# Game Settings - from raylib
# --------------------------------------------------------------------------------------

# from raylib
# Keyboard keys (US keyboard layout)
# NOTE: Use GetKeyPressed() to allow redefining
# required keys for alternative layouts
type KeyboardKey = enum 
    KEY_SPACE           = 32, 
    KEY_APOSTROPHE      = 39,
    KEY_COMMA           = 44,
    KEY_MINUS           = 45,
    KEY_PERIOD          = 46,
    KEY_SLASH           = 47,
    KEY_ZERO            = 48,
    KEY_ONE             = 49,
    KEY_TWO             = 50,
    KEY_THREE           = 51,
    KEY_FOUR            = 52,
    KEY_FIVE            = 53,
    KEY_SIX             = 54,
    KEY_SEVEN           = 55,
    KEY_EIGHT           = 56,
    KEY_NINE            = 57,
    KEY_SEMICOLON       = 59,
    KEY_EQUAL           = 61,
    KEY_A               = 65,
    KEY_B               = 66,
    KEY_C               = 67,
    KEY_D               = 68,
    KEY_E               = 69,
    KEY_F               = 70,
    KEY_G               = 71,
    KEY_H               = 72,
    KEY_I               = 73,
    KEY_J               = 74,
    KEY_K               = 75,
    KEY_L               = 76,
    KEY_M               = 77,
    KEY_N               = 78,
    KEY_O               = 79,
    KEY_P               = 80,
    KEY_Q               = 81,
    KEY_R               = 82,
    KEY_S               = 83,
    KEY_T               = 84,
    KEY_U               = 85,
    KEY_V               = 86,
    KEY_W               = 87,
    KEY_X               = 88,
    KEY_Y               = 89,
    KEY_Z               = 90,
    KEY_LEFT_BRACKET    = 91,
    KEY_BACKSLASH       = 92,
    KEY_RIGHT_BRACKET   = 93,
    KEY_GRAVE           = 96,
    KEY_ESCAPE          = 256,
    KEY_ENTER           = 257,
    KEY_TAB             = 258,
    KEY_BACKSPACE       = 259,
    KEY_INSERT          = 260,
    KEY_DELETE          = 261,
    KEY_RIGHT           = 262,
    KEY_LEFT            = 263,
    KEY_DOWN            = 264,
    KEY_UP              = 265,
    KEY_PAGE_UP         = 266,
    KEY_PAGE_DOWN       = 267,
    KEY_HOME            = 268,
    KEY_END             = 269,
    KEY_CAPS_LOCK       = 280,
    KEY_SCROLL_LOCK     = 281,
    KEY_NUM_LOCK        = 282,
    KEY_PRINT_SCREEN    = 283,
    KEY_PAUSE           = 284,
    KEY_F1              = 290,
    KEY_F2              = 291,
    KEY_F3              = 292,
    KEY_F4              = 293,
    KEY_F5              = 294,
    KEY_F6              = 295,
    KEY_F7              = 296,
    KEY_F8              = 297,
    KEY_F9              = 298,
    KEY_F10             = 299,
    KEY_F11             = 300,
    KEY_F12             = 301,
    KEY_KP_0            = 320,
    KEY_KP_1            = 321,
    KEY_KP_2            = 322,
    KEY_KP_3            = 323,
    KEY_KP_4            = 324,
    KEY_KP_5            = 325,
    KEY_KP_6            = 326,
    KEY_KP_7            = 327,
    KEY_KP_8            = 328,
    KEY_KP_9            = 329,
    KEY_KP_DECIMAL      = 330,
    KEY_KP_DIVIDE       = 331,
    KEY_KP_MULTIPLY     = 332,
    KEY_KP_SUBTRACT     = 333,
    KEY_KP_ADD          = 334,
    KEY_KP_ENTER        = 335,
    KEY_KP_EQUAL        = 336
    KEY_LEFT_SHIFT      = 340,
    KEY_LEFT_CONTROL    = 341,
    KEY_LEFT_ALT        = 342,
    KEY_LEFT_SUPER      = 343,
    KEY_RIGHT_SHIFT     = 344,
    KEY_RIGHT_CONTROL   = 345,
    KEY_RIGHT_ALT       = 346,
    KEY_RIGHT_SUPER     = 347,
    KEY_KB_MENU         = 348,

const MOUSE_SENSITIVITY                                 = 0.003f
const CAMERA_FIRST_PERSON_STEP_TRIGONOMETRIC_DIVIDER    = 8.0f
const CAMERA_FIRST_PERSON_WAVING_DIVIDER                = 200.0f
const CAMERA_FIRST_PERSON_MIN_CLAMP                     = 89.0f
const CAMERA_FIRST_PERSON_MAX_CLAMP                     = -89.0f
const CAMERA_FREE_PANNING_DIVIDER                       = 5.1f
const DEG2RAD                                           = (PI/180.0f)
const PLAYER_MOVEMENT_SENSITIVITY                       = 20.0f


# --------------------------------------------------------------------------------------
# World
# --------------------------------------------------------------------------------------

type World* = object
    name:string

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

const moveControl = [ KeyboardKey.KEY_W, 
                      KeyboardKey.KEY_S, 
                      KeyboardKey.KEY_D, 
                      KeyboardKey.KEY_A, 
                      KeyboardKey.KEY_SPACE, 
                      KeyboardKey.KEY_LEFT_SHIFT ]

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

proc toRayCamera3D(camera: Camera3D): raylib.Camera3D = 
    result = cast[raylib.Camera3D](camera)
    result.up = camera.up
    result.fovy = camera.fovy
    result.`type` = camera.`type`

type 
    # Entity* = ref object of RootObj
    #     world*: ref World
    #     position*: Vector3
    #     velocity*: Vector3
    #     oid*: Oid

    PlayerEntity* = object
        world*: ref World
        position*: Vector3
        velocity*: Vector3
        oid*: Oid

        camera*: Camera
        cameraMode*: CameraMode
        headRotation*: Vector2
        rotation*: Vector2
        previousMousePos*: Vector2

proc createPlayer* (): PlayerEntity =
    result.camera = Camera()
    #     position: Vector3(x: 4.0f, y: 2.0f, z: 4.0f),
    #     target: Vector3(x: 0.0f, y: 1.8f, z: 0.0f),
    #     up: Vector3(x: 0.0f, y: 1.0f, z: 0.0f),
    #     fovy: 60.0f,
    #     `type`: 0
    # ) 
    var pos = Vector3(x: 4.0f, y: 2.0f, z: 4.0f)
    result.camera.position = pos
    result.camera.target = Vector3(x: 0.0f, y: 1.8f, z: 0.0f)
    result.camera.up = Vector3(x: 0.0f, y: 1.0f, z: 0.0f)
    result.camera.fovy = (60.0).cfloat
    result.camera.`type` = (0).cint

    let dx = result.camera.target.x - result.camera.position.x
    let dy = result.camera.target.y - result.camera.position.y
    let dz = result.camera.target.z - result.camera.position.z
    result.camera.targetDistance = sqrt(dx*dx + dy*dy + dz*dz)

    result.position = pos
    result.cameraMode = CameraMode.FIRST_PERSON
    result.oid = Oid()

proc updatePlayer* (player: ptr PlayerEntity) = 
    var swingCounter = 0

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
            # player.position.x += ( sin(player.rotation.x) * cast[float]direction[MOVE_BACK.cint]  -
            #                        sin(player.rotation.x) * direction[MOVE_FRONT.cint] -
            #                        cos(player.rotation.x) * direction[MOVE_LEFT.cint]  +
            #                        cos(player.rotation.x) * direction[MOVE_RIGHT.cint]) / PLAYER_MOVEMENT_SENSITIVITY;
            # Camera rotation calcuation
            player.headRotation.x += mouseDelta.x * -MOUSE_SENSITIVITY
            player.headRotation.y += mouseDelta.y * -MOUSE_SENSITIVITY

            # Angle clamp
            if player.headRotation.y > CAMERA_FIRST_PERSON_MIN_CLAMP*DEG2RAD:
                player.headRotation.y = CAMERA_FIRST_PERSON_MIN_CLAMP*DEG2RAD
            elif player.headRotation.y < CAMERA_FIRST_PERSON_MAX_CLAMP*DEG2RAD: 
                player.headRotation.y = CAMERA_FIRST_PERSON_MAX_CLAMP*DEG2RAD;

            player.camera.position = player.position

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

            # Recalculate camera target considering translation and rotation
            var translation = translate(0, 0, (player.camera.targetDistance/CAMERA_FREE_PANNING_DIVIDER));
            var rotation = rotateXYZ(Vector3(x: PI*2 - player.headRotation.y, y: PI*2 - player.headRotation.x, z: 0.0f));
            var transform = multiply(translation, rotation);

            player.camera.target.x = player.camera.position.x - transform.m12
            player.camera.target.y = player.camera.position.y - transform.m13
            player.camera.target.z = player.camera.position.z - transform.m14

            for i in 0..5: 
                if direction[i]: 
                    swingCounter += 1

            player.camera.up.x = sin(swingCounter.float32 / (CAMERA_FIRST_PERSON_STEP_TRIGONOMETRIC_DIVIDER*2)) / CAMERA_FIRST_PERSON_WAVING_DIVIDER;
            player.camera.up.z = -sin(swingCounter.float32 / (CAMERA_FIRST_PERSON_STEP_TRIGONOMETRIC_DIVIDER*2)) / CAMERA_FIRST_PERSON_WAVING_DIVIDER;
            
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
# Main Game
# --------------------------------------------------------------------------------------

const MaxColumns = 20

# Initialization
const screenWidth = 800
const screenHeight = 450

initWindow screenWidth, screenHeight, "raylib [core] example - 3d camera first person"

var playerEntity = createPlayer()
setCameraMode(cast[raylib.Camera](playerEntity.camera), 0)

#  Generates some random columns
var 
    heights: array[0..MAX_COLUMNS, float]
    positions: array[0..MAX_COLUMNS, Vector3]
    colors: array[0..MAX_COLUMNS, Color]

for i in 0..<MaxColumns:
    heights[i] = getRandomValue(1, 12).float
    positions[i] = Vector3(x: getRandomValue(-15, 15).float, y: heights[i]/2, z: getRandomValue(-15, 15).float)
    colors[i] = Color(r: getRandomValue(20, 255).uint8, g: getRandomValue(10, 55).uint8, b: 30, a: 255)

setTargetFPS 144                         
# --------------------------------------------------------------------------------------

var lastFrameTime:float = 0
var lastTime:float

disableCursor()


#  Main game loop
while not windowShouldClose():              #  Detect window close button or ESC key
    playerEntity.addr.updatePlayer()

    beginDrawing()

    clearBackground RayWhite

    beginMode3D playerEntity.camera.toRayCamera3D

    drawPlane Vector3(x: 0.0f, y: 0.0f, z: 0.0f), Vector2(x: 32.0f, y: 32.0f), LIGHTGRAY #  Draw ground
    drawCube Vector3(x: -16.0f, y: 2.5f, z: 0.0f), 1.0f, 5.0f, 32.0f, BLUE               #  Draw a blue wall
    drawCube Vector3(x: 16.0f, y: 2.5f, z: 0.0f), 1.0f, 5.0f, 32.0f, LIME                #  Draw a green wall
    drawCube Vector3(x: 0.0f, y: 2.5f, z: 16.0f), 32.0f, 5.0f, 1.0f, GOLD                #  Draw a yellow wall

    #  Draw some cubes around
    for i in 0..<MaxColumns:
        drawCube positions[i], 2.0, heights[i], 2.0, colors[i]
        drawCubeWires positions[i], 2.0, heights[i], 2.0, Maroon

    #drawCube playerEntity.camera.target, 0.1, 0.1, 0.1, Black

    endMode3D()

    drawRectangle 10, 10, 290, 90, fade(Skyblue, 0.5)
    drawRectangleLines 10, 10, 290, 90, Blue

    drawText "First person camera default controls:", 20, 20, 10, Black
    drawText "- Move with keys: W, A, S, D, Space, LShift", 40, 40, 10, Darkgray
    drawText "- Mouse move to look around", 40, 60, 10, Darkgray

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

