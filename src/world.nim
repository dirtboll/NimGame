# --------------------------------------------------------------------------------------
# World
# --------------------------------------------------------------------------------------
import tables,
       glm/vec,
       glm/noise

const CHUNK_DIMENSION* = [64,256,64]
const CHUNK_SIZE = CHUNK_DIMENSION[0] * CHUNK_DIMENSION[1] * CHUNK_DIMENSION[2]
#const CHUNK_ARRAY_SIZE = 16

var zoom* = 10
var heightMult* = 5
var offsetX* = 0
var offsetZ* = 0

type BlockID* = enum
    AIR = 0,
    STONE,
    DIRT,
    WOOD

type Chunk* = object
    blockArr*: array[CHUNK_SIZE, BlockID]
    id*: string

    heightMap*: array[CHUNK_DIMENSION[0], array[CHUNK_DIMENSION[2], float32]]

type World* = object
    name*: string
    chunks*: Table[system.string, ptr Chunk]

proc createWorld* (name: string): World =
    return World(name: name)

proc map(num: float32, fromMin: float32, fromMax: float32, toMin: float32, toMax: float32): float32 =
    return toMin+((toMax-toMin)*((num-fromMin)/(fromMax-fromMin)))

proc idx(x: int, y: int, z: int): int = 
    return x + z * CHUNK_DIMENSION[0] + y * CHUNK_DIMENSION[2] * CHUNK_DIMENSION[0]
    
proc generateChunk* (chunk: var Chunk) =
    for z in 0..<CHUNK_DIMENSION[2]:
        for x in 0..<CHUNK_DIMENSION[0]:
            let height = (simplex(vec2f(x.float32 + offsetX.float32, z.float32 + offsetZ.float32) / zoom.float32) + 1) * heightMult.float32
            chunk.heightMap[x][z] = height
            for y in 0..<height.int:
                chunk.blockArr[idx(x,y,z)] = STONE

proc getBlock* (chunk: var Chunk, x: int, y: int, z: int): BlockID =
    return chunk.blockArr[idx(x,y,z)]