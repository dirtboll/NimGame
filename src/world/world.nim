import tables

const CHUNK_DIMENSION* = [16,256,16]
const CHUNK_SIZE = CHUNK_DIMENSION[0] * CHUNK_DIMENSION[1] * CHUNK_DIMENSION[2]
const CHUNK_ARRAY_SIZE = 16
const CHUNK_LOAD_DISTANCE = 5

var zoom* = 10
var heightMult* = 5
var offsetX* = 0
var offsetZ* = 0

var generating = true

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