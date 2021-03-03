# --------------------------------------------------------------------------------------
# World
# --------------------------------------------------------------------------------------
import tables,
       glm/vec,
       glm/noise,
       nimraylib_now/raylib

const CHUNK_DIMENSION* = [16,256,16]
const CHUNK_SIZE = CHUNK_DIMENSION[0] * CHUNK_DIMENSION[1] * CHUNK_DIMENSION[2]
const CHUNK_ARRAY_SIZE = 16
const CHUNK_LOAD_DISTANCE = 5

var zoom* = 10
var heightMult* = 5
var offsetX* = 0
var offsetZ* = 0

var generating = true

proc map(num: float32, fromMin: float32, fromMax: float32, toMin: float32, toMax: float32): float32 =
    return toMin+((toMax-toMin)*((num-fromMin)/(fromMax-fromMin)))

proc idx(x: int, y: int, z: int): int = 
    return x + z * CHUNK_DIMENSION[0] + y * CHUNK_DIMENSION[2] * CHUNK_DIMENSION[0]

type BlockID* = enum
    VOID = -1,
    AIR = 0,
    STONE,
    DIRT,
    WOOD

type Chunk* = object
    id*: string
    blockArr*: array[CHUNK_SIZE, BlockID]
    heightMap*: array[CHUNK_DIMENSION[0], array[CHUNK_DIMENSION[2], float32]]

type World* = object
    name*: string
    chunks*: Table[string, Chunk]
    loadedIds*: Table[int, array[3, int]]

proc createWorld* (name: string): World =
    return World(name: name)

proc genChunk (x: int, y: int, z: int): Chunk =
    for z in 0..<CHUNK_DIMENSION[2]:
        for x in 0..<CHUNK_DIMENSION[0]:
            let height = (simplex(vec2f(x.float32, z.float32) / zoom.float32) + 1) * heightMult.float32
            result.heightMap[x][z] = height
            for y in 0..<height.int:
                result.blockArr[idx(x,y,z)] = STONE

proc getBlock* (world: var World, x: int, y: int, z: int): BlockID =
    var cX = (x / CHUNK_DIMENSION[0]).int
    var cY = (y / CHUNK_DIMENSION[1]).int
    var cZ = (z / CHUNK_DIMENSION[2]).int
    var cStr = $cX & $cY & $cZ
    if world.chunks.hasKey(cStr):
        var bX = (x mod CHUNK_DIMENSION[0]).int
        var bY = (y mod CHUNK_DIMENSION[1]).int
        var bZ = (z mod CHUNK_DIMENSION[2]).int
        return world.chunks[cStr].blockArr[idx(bX, bY, bZ)]
    return VOID

proc updateChunk* (chunkX: int, chunkY: int, chunkZ: int, updaterId: int, world: var World): bool =
    if world.loadedIds.hasKey(updaterId):
        var coord = world.loadedIds.getOrDefault(updaterId)
        if coord[0] == chunkX and coord[1] == chunkY and coord[2] == chunkZ:
            return false
    world.loadedIds[updaterId] = [chunkX, chunkY, chunkZ]

    for x in 0..<CHUNK_LOAD_DISTANCE:
        for y in 0..<1:
            for z in 0..<CHUNK_LOAD_DISTANCE:
                var cStr = $x & '0' & $z
                if world.chunks.hasKey(cStr):
                    continue
                world.chunks[cStr] = genChunk(x + (chunkX * CHUNK_DIMENSION[0]), y + (chunkY * CHUNK_DIMENSION[1]), z + (chunkZ * CHUNK_DIMENSION[2]))
    
    return true

proc getChunkModel* (chunkX: int, chunkY: int, chunkZ: int, updaterId: int, world: var World): Model =
    
    discard