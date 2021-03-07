#TO-DO: multithread compatible
import 
    sets,
    tables,
    heapqueue,
    oids,
    glm/noise

const 
    CHUNK_DIMENSION* = (x: 16, y: 256, z: 16)
    CHUNK_SIZE = CHUNK_DIMENSION.x * CHUNK_DIMENSION.y * CHUNK_DIMENSION.z
    HEIGHT_MAP_SIZE = CHUNK_DIMENSION.x * CHUNK_DIMENSION.z
    #CHUNK_ARRAY_SIZE = 16
    CHUNK_LOAD_DISTANCE = (x: 8, y: 1, z: 8)

type 
    BlockID* = enum
        VOID = -1,
        AIR = 0,
        STONE,
        DIRT,
        WOOD

    Chunk* = ref object of RootObj
        pos*: tuple[x: int, y: int, z: int]
        blockArr*: array[CHUNK_SIZE, BlockID]
        heightMap*: array[HEIGHT_MAP_SIZE, float32]

    World* = ref object of RootObj
        name*: string
        chunkQueue* : HeapQueue[tuple[x: int, y: int, z: int]]
        loadingChunk*: HashSet[tuple[x: int, y: int, z: int]]
        chunks*: Table[tuple[x: int, y: int, z: int], ref Chunk]
        generating*: bool
        loaderIds*: Table[Oid, tuple[x: int, y: int, z: int]] #TO-DO: pass ref coord

var 
    currentLoaderPos = (x: 0, y: 0, z: 0) # TO-DO: per-world dependant
    zoom* = 10
    heightMult* = 5
    offset* = (x: 0, y: 0, z: 0)

# ================================| Helper Functions |========================================

# TO-DO: SIMD & per-world dependant
proc `<`(a, b: var tuple[x: int, y: int, z: int]): bool =
    var 
        aX = a.x - currentLoaderPos.x
        aY = a.y - currentLoaderPos.y
        aZ = a.z - currentLoaderPos.z
        bX = b.x - currentLoaderPos.x
        bY = b.y - currentLoaderPos.y
        bZ = b.z - currentLoaderPos.z
    return (aX*aX + aY*aY + aZ*aZ) < (bX*bX + bY*bY + bZ*bZ)

func map* ( num: float32, 
          fromMin: float32, 
          fromMax: float32, 
          toMin: float32, 
          toMax: float32): float32 =
    return toMin+((toMax-toMin)*((num-fromMin)/(fromMax-fromMin)))

func idx* (x: int, y: int, z: int): int = 
    return x + z * CHUNK_DIMENSION.x + y * CHUNK_DIMENSION.x * CHUNK_DIMENSION.z

func idxH* (x: int, z: int): int =
    return idx(x, 0, z)

func toChunkPos* (x: float32, y: float32, z: float32): tuple[x: int, y: int, z: int] =
    result.x = (x / CHUNK_DIMENSION.x.float32).int
    result.y = (y / CHUNK_DIMENSION.y.float32).int
    result.z = (z / CHUNK_DIMENSION.z.float32).int

# ==================================| Logic Handler |=======================================

proc createWorld* (name: string): World =
    new(result)
    result.name = name

proc registerUpdaterId* (world: var World, oid: var Oid, pX: float32, pY: float32, pZ: float32) = 
    world.loaderIds[oid] = toChunkPos(pX, pY, pZ)

proc createWorld* (name: string, oid: var Oid, pX: float32, pY: float32, pZ: float32): World =
    var world = createWorld(name)
    registerUpdaterId(world, oid, pX, pY, pZ)
    return world

proc genChunk (cX: int, cY: int, cZ: int): ref Chunk =
    new(result)
    result.pos = (cX,cY,cZ)
    for z in 0..<CHUNK_DIMENSION[2]:
        for x in 0..<CHUNK_DIMENSION[0]:
            let height = ( simplex( vec2f( x.float32 + (cX*CHUNK_DIMENSION.x).float32, 
                                           z.float32 + (cZ*CHUNK_DIMENSION.y).float32 ) / zoom.float32) + 1) * heightMult.float32
            result.heightMap[idxH(x,z)] = height
            for y in 0..<height.int:
                result.blockArr[idx(x,y,z)] = STONE

proc getBlock* (world: var World, x: float32, y: float32, z: float32): BlockID =
    var cPos = toChunkPos(x,y,z)
    if world.chunks.hasKey(cPos):
        var bX = (x.int mod CHUNK_DIMENSION.x).int
        var bY = (y.int mod CHUNK_DIMENSION.y).int
        var bZ = (z.int mod CHUNK_DIMENSION.z).int
        return world.chunks[cPos].blockArr[idx(bX, bY, bZ)]
    return VOID

proc updateChunkQueue (world: var World, updater: var Oid, pX: float32, pY: float32, pZ: float32): bool =
    var cPos = toChunkPos(pX,pY,pZ)
    if world.loaderIds.hasKey(updater):
        var coord = world.loaderIds.getOrDefault(updater)
        if coord == cPos:
            return false
    world.loaderIds[updater] = cPos
    world.generating = false # TO-DO: pause chunk gen

    var chunkQueue = newSeq[tuple[x: int, y: int, z: int]]()
    for cX in 0..<CHUNK_LOAD_DISTANCE.x:
        for cY in 0..<CHUNK_LOAD_DISTANCE.y:
            for cZ in 0..<CHUNK_LOAD_DISTANCE.z:
                var lCPos = (x: cX+cPos.x, y: cY+cPos.y, z: cZ+cPos.z)
                if world.chunks.hasKey(lCPos):
                    continue
                chunkQueue.add(lCPos)
    
    dealloc(world.chunkQueue.addr)
    world.chunkQueue = chunkQueue.toHeapQueue()

    world.generating = true

# TO-DO: update chunk on multiple players
proc processChunkQueue (world: var World): bool =
    if world.chunkQueue.len == 0:
        return false
    var cCoord = world.chunkQueue.pop()

    # world.loadingChunk.incl(cCoord)
    world.chunks[cCoord] = genChunk(cCoord.x, cCoord.y, cCoord.z)
    # world.loadingChunk.excl(cCoord)

#TO-DO: process entities here
proc updateWorld* (world: var World, oid: var Oid, pX: float32, pY: float32, pZ: float32) =
    var update = world.updateChunkQueue(oid, pX, pY, pZ)
    update = world.processChunkQueue()

# ================================| Model Handler |==========================================