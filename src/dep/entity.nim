import nimraylib_now/raylib,
       nimraylib_now/raymath,
       glm,
       math,
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

converter toCamera3D(camera: var Camera3D): raylib.Camera3D = 
    result.position = camera.position
    result.target = camera.target
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
        world*: ptr World
        position*: Vector3
        velocity*: Vector3
        oid*: Oid

        camera*: Camera
        cameraMode*: CameraMode
        headRotation*: Vector2
        rotation*: Vector2
        previousMousePos*: Vector2

proc playerRotToTarget(pos: Vector3, rot: Vector2, dist: float32): Vector3 =
    var translation = translate(0, 0, (dist/CAMERA_FREE_PANNING_DIVIDER));
    var rotation = rotateXYZ(Vector3(x: PI*2 - rot.y, y: PI*2 - rot.x, z: 0.0f));
    var transform = multiply(translation, rotation);

    result.x = pos.x - transform.m12
    result.y = pos.y - transform.m13
    result.z = pos.z - transform.m14

proc createPlayer* (pos: Vector3, rotRad: Vector2): PlayerEntity =
    result.position = pos
    result.headRotation = rotRad

    result.camera = Camera()
    result.camera.position = pos
    result.camera.up = Vector3(x: 0.0f, y: 1.0f, z: 0.0f)
    result.camera.fovy = (70.0).cfloat
    result.camera.`type` = (1).cint

    let dx = result.camera.target.x - result.camera.position.x
    let dy = result.camera.target.y - result.camera.position.y
    let dz = result.camera.target.z - result.camera.position.z
    result.camera.targetDistance = sqrt(dx*dx + dy*dy + dz*dz)
    
    result.cameraMode = CameraMode.FIRST_PERSON
    result.oid = genOid()
    result.previousMousePos = getMousePosition()

proc createPlayer* (): PlayerEntity =
    return createPlayer(Vector3(), Vector2(x:0.0,y:0.75))

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

            player.camera.target = playerRotToTarget(player.camera.position, player.headRotation, player.camera.targetDistance)

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