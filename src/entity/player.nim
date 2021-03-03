import
    entity,

    oids, 
    math,
    nimraylib_now/raylib,
    nimraylib_now/raymath

const DEG2RAD*                                           = (PI/180.0f)
const MOUSE_SENSITIVITY*                                 = 0.003f
const CAMERA_FIRST_PERSON_STEP_TRIGONOMETRIC_DIVIDER*    = 8.0f
const CAMERA_FIRST_PERSON_WAVING_DIVIDER*                = 200.0f
const CAMERA_FIRST_PERSON_MIN_CLAMP*                     = 89.0f
const CAMERA_FIRST_PERSON_MAX_CLAMP*                     = -89.0f
const CAMERA_FIRST_PERSON_MIN_CLAMP_RAD*                 = 89.0f * DEG2RAD
const CAMERA_FIRST_PERSON_MAX_CLAMP_RAD*                 = -89.0f * DEG2RAD
const CAMERA_FREE_PANNING_DIVIDER*                       = 5.1f
const PLAYER_MOVEMENT_SENSITIVITY*                       = 10.0f

type CameraControl = enum
    MOVE_FRONT = 0,
    MOVE_BACK,
    MOVE_RIGHT,
    MOVE_LEFT,
    MOVE_UP,
    MOVE_DOWN
const MOVE_CONTROL = [ KeyboardKey.W,
                       KeyboardKey.S,
                       KeyboardKey.D,
                       KeyboardKey.A,
                       KeyboardKey.SPACE,
                       KeyboardKey.LEFT_SHIFT ]

type 
    Camera* = ref object of RootObj
        position*: ref Vector3 
        target*: Vector3
        targetDistance*: float32
        up*: Vector3
        fovy*: cfloat
        `type`*: cint

    PlayerEntity* = ref object of Entity
        camera*: Camera
        cameraMode*: CameraMode
        headRotation*: Vector2
        rotation*: Vector2
        previousMousePos*: Vector2

converter toCamera3D* (camera: var Camera): raylib.Camera3D = 
    result.position = camera.position[]
    result.target = camera.target
    result.up = camera.up
    result.fovy = camera.fovy
    result.`type` = camera.`type`

converter toRefVector3* (v: Vector3): ref Vector3 = 
    new(result)
    result[] = v

proc playerRotToTarget(pos: var Vector3, rot: var Vector2, dist: float32): Vector3 =
    var translation = translate(0, 0, (dist/CAMERA_FREE_PANNING_DIVIDER))
    var rotation = rotateXYZ(Vector3(x: PI*2 - rot.y, y: PI*2 - rot.x, z: 0.0f))
    var transform = multiply(translation, rotation)

    result.x = pos.x - transform.m12
    result.y = pos.y - transform.m13
    result.z = pos.z - transform.m14

# TO-DO: Call super constructor
proc createPlayer* (pos: Vector3, rotRad: Vector2): PlayerEntity =
    new(result)
    result.position = pos
    result.headRotation = rotRad

    new(result.camera)
    result.camera.position = result.position
    result.camera.up = Vector3(x: 0.0f, y: 1.0f, z: 0.0f)
    result.camera.fovy = (60.0).cfloat
    result.camera.`type` = PERSPECTIVE

    var dx = result.camera.target.x - result.camera.position.x
    var dy = result.camera.target.y - result.camera.position.y
    var dz = result.camera.target.z - result.camera.position.z
    result.camera.targetDistance = sqrt(dx*dx + dy*dy + dz*dz)
    
    result.cameraMode = CameraMode.FIRST_PERSON
    result.oid = genOid()
    result.previousMousePos = getMousePosition()

proc updatePlayer* (player: var PlayerEntity) = 
    var direction = [ isKeyDown(MOVE_CONTROL[MOVE_FRONT.int].cint),
                      isKeyDown(MOVE_CONTROL[MOVE_BACK.int].cint),
                      isKeyDown(MOVE_CONTROL[MOVE_RIGHT.int].cint),
                      isKeyDown(MOVE_CONTROL[MOVE_LEFT.int].cint),
                      isKeyDown(MOVE_CONTROL[MOVE_UP.int].cint),
                      isKeyDown(MOVE_CONTROL[MOVE_DOWN.int].cint) ]

    var mouseDelta = subtract(getMousePosition(), player.previousMousePos)
    player.previousMousePos = getMousePosition()

    case player.cameraMode:
        of CameraMode.FIRST_PERSON:
            # Player Head rotation calcuation
            player.headRotation.x += mouseDelta.x * -MOUSE_SENSITIVITY
            player.headRotation.y += mouseDelta.y * -MOUSE_SENSITIVITY

            # Angle clamp
            if player.headRotation.y > CAMERA_FIRST_PERSON_MIN_CLAMP_RAD:
                player.headRotation.y = CAMERA_FIRST_PERSON_MIN_CLAMP_RAD
            elif player.headRotation.y < CAMERA_FIRST_PERSON_MAX_CLAMP_RAD: 
                player.headRotation.y = CAMERA_FIRST_PERSON_MAX_CLAMP_RAD

            # Calculate Player position
            player.position.x += ( sin(player.headRotation.x) * direction[MOVE_BACK.int].float32 - 
                                   sin(player.headRotation.x) * direction[MOVE_FRONT.int].float32 -
                                   cos(player.headRotation.x) * direction[MOVE_LEFT.int].float32  +
                                   cos(player.headRotation.x) * direction[MOVE_RIGHT.int].float32) / PLAYER_MOVEMENT_SENSITIVITY;

            player.position.y += ( sin(player.headRotation.y) * direction[MOVE_FRONT.int].float32 -
                                   sin(player.headRotation.y) * direction[MOVE_BACK.int].float32 +
                                   1.0f * direction[MOVE_UP.cint].float32 - 1.0f * direction[MOVE_DOWN.cint].float32) / PLAYER_MOVEMENT_SENSITIVITY;

            player.position.z += ( cos(player.headRotation.x) * direction[MOVE_BACK.int].float32 -
                                   cos(player.headRotation.x) * direction[MOVE_FRONT.int].float32 +
                                   sin(player.headRotation.x) * direction[MOVE_LEFT.int].float32 -
                                   sin(player.headRotation.x) * direction[MOVE_RIGHT.int].float32) / PLAYER_MOVEMENT_SENSITIVITY;

            player.camera.target = playerRotToTarget(player.camera.position[], player.headRotation, player.camera.targetDistance)

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