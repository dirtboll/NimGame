#TO-DO: multithread compatible
import 
    glm/noise,
    nimraylib_now/raylib,
    nimraylib_now/rlgl,
    heapqueue,
    sets,
    heapqueue,
    tables,
    oids

const 
    CHUNK_DIMENSION* = (x: 16, y: 256, z: 16)
    CHUNK_SIZE* = CHUNK_DIMENSION.x * CHUNK_DIMENSION.y * CHUNK_DIMENSION.z
    HEIGHT_MAP_SIZE* = CHUNK_DIMENSION.x * CHUNK_DIMENSION.z
    #CHUNK_ARRAY_SIZE = 16
    CHUNK_LOAD_DISTANCE* = (x: 8, y: 1, z: 8)

type 
    BlockID* = enum
        VOID = (-1, "t"),
        AIR = (0, "t"),
        STONE = (1, "s"),
        DIRT = (2, "s"),
        WOOD = (3, "s")

    Chunk* = ref object of RootObj
        pos*: tuple[x: int, y: int, z: int]
        blockArr*: array[CHUNK_SIZE, BlockID]
        heightMap*: array[HEIGHT_MAP_SIZE, float]

    World* = ref object of RootObj
        name*: string
        chunkQueue* : HeapQueue[tuple[x: int, y: int, z: int]]
        loadingChunk*: HashSet[tuple[x: int, y: int, z: int]]
        chunks*: Table[tuple[x: int, y: int, z: int], Chunk]
        generating*: bool
        loaderIds*: Table[Oid, tuple[x: int, y: int, z: int]] #TO-DO: pass ref coord

var 
    currentLoaderPos = (x: 0, y: 0, z: 0) # TO-DO: per-world dependant
    zoom* = 10
    heightMult* = 5
    offset* = (x: 0, y: 0, z: 0)

# ================================| Helper Functions |========================================

proc concat[I1, I2: static[int]; T](a: var array[I1, T], b: array[I2, T]): array[I1 + I2, T] =
    result[0..a.high] = a
    result[a.len..result.high] = b

proc mask[I1, I2: static[int]; T](a: var array[I1, T], b: array[I2, T], i: int) =
    for idx in i..a.high:
        if idx-i < b.len:
            a[i] = b[idx-i]

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

func map* ( num: float, 
          fromMin: float, 
          fromMax: float, 
          toMin: float, 
          toMax: float): float =
    return toMin+((toMax-toMin)*((num-fromMin)/(fromMax-fromMin)))

func idx* (x: int, y: int, z: int): int = 
    return x + z * CHUNK_DIMENSION.x + y * CHUNK_DIMENSION.x * CHUNK_DIMENSION.z

func idxH* (x: int, z: int): int =
    return idx(x, 0, z)

func toChunkPos* (x: float, y: float, z: float): tuple[x: int, y: int, z: int] =
    result.x = (x / CHUNK_DIMENSION.x.float).int
    result.y = (y / CHUNK_DIMENSION.y.float).int
    result.z = (z / CHUNK_DIMENSION.z.float).int

# ==================================| Chunk Handler |=======================================

proc createWorld* (name: string): World =
    new(result)
    result.name = name

proc registerUpdaterId* (world: var World, oid: var Oid, pX: float, pY: float, pZ: float) = 
    world.loaderIds[oid] = toChunkPos(pX, pY, pZ)

proc createWorld* (name: string, oid: var Oid, ppos: var tuple[x: float, y: float, z: float]): World =
    var world = createWorld(name)
    registerUpdaterId(world, oid, ppos.x, ppos.y, ppos.z)
    return world

proc genChunk* (cX: int, cY: int, cZ: int): Chunk =
    new result
    result.pos = (cX,cY,cZ)
    for z in 0..<CHUNK_DIMENSION[2]:
        for x in 0..<CHUNK_DIMENSION[0]:
            let height = ( simplex( vec2f( x.float + (cX*CHUNK_DIMENSION.x).float, 
                                           z.float + (cZ*CHUNK_DIMENSION.y).float ) / zoom.float) + 1) * heightMult.float
            result.heightMap[idxH(x,z)] = height
            for y in 0..<min(height.int, CHUNK_DIMENSION.y):
                result.blockArr[idx(x,y,z)] = STONE

proc getBlock* (world: var World, x: float, y: float, z: float): BlockID =
    var cPos = toChunkPos(x,y,z)
    if world.chunks.hasKey(cPos):
        var bX = (x.int mod CHUNK_DIMENSION.x).int
        var bY = (y.int mod CHUNK_DIMENSION.y).int
        var bZ = (z.int mod CHUNK_DIMENSION.z).int
        return world.chunks[cPos].blockArr[idx(bX, bY, bZ)]
    return VOID

proc updateChunkQueue* (world: var World, updater: var Oid, pX: float, pY: float, pZ: float): bool =
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
proc processChunkQueue* (world: var World): bool =
    if world.chunkQueue.len == 0:
        return false
    var cCoord = world.chunkQueue.pop()

    # world.loadingChunk.incl(cCoord)
    world.chunks[cCoord] = genChunk(cCoord.x, cCoord.y, cCoord.z)
    # world.loadingChunk.excl(cCoord)

#TO-DO: process entities, use position pointer, use observer pattern
proc updateWorld* (world: var World, oid: var Oid, ppos: var tuple[x: float, y: float, z: float]) =
    var update = world.updateChunkQueue(oid, ppos.x, ppos.y, ppos.z)
    update = world.processChunkQueue()

# ==================================| Chunk Mesh Handler |=======================================

#[ 
    Taken from https://github.com/pietmichal/raycraft
    with modifications. 
 ]#

const textCoordRef = [
    # face 1
    0.5,  1.0,
    0.25, 1.0,
    0.25, 0.0,

    0.25, 0.0,
    0.5,  0.0,
    0.5,  1.0,

    # face 2
    0.25, 1.0,
    0.25, 0.0,
    0.5,  0.0,

    0.5,  0.0,
    0.5,  1.0,
    0.25, 1.0,

    # face 3 (top)
    0.0,  0.0,
    0.25, 0.0,
    0.25, 1.0,

    0.25, 1.0,
    0.0,  1.0,
    0.0,  0.0,

    # face 4 (bottom)
    0.0,  0.0,
    0.25, 0.0,
    0.25, 1.0,

    0.25, 1.0,
    0.0,  1.0,
    0.0,  0.0,

    # face 5
    0.25, 1.0,
    0.25, 0.0,
    0.5,  0.0,

    0.5,  0.0,
    0.5,  1.0,
    0.25, 1.0,

    # face 6
    0.5,  1.0,
    0.25, 1.0,
    0.25, 0.0,

    0.25, 0.0,
    0.5,  0.0,
    0.5,  1.0,
]

const normalRef = [
    # face 1
    0.0, 0.0, 1.0,
    0.0, 0.0, 1.0,
    0.0, 0.0, 1.0,

    0.0, 0.0, 1.0,
    0.0, 0.0, 1.0,
    0.0, 0.0, 1.0,

    # face 2
    0.0, 0.0, -1.0,
    0.0, 0.0, -1.0,
    0.0, 0.0, -1.0,

    0.0, 0.0, -1.0,
    0.0, 0.0, -1.0,
    0.0, 0.0, -1.0,

    # face 3
    0.0, 1.0, 0.0,
    0.0, 1.0, 0.0,
    0.0, 1.0, 0.0,

    0.0, 1.0, 0.0,
    0.0, 1.0, 0.0,
    0.0, 1.0, 0.0,

    # face 4
    0.0, -1.0, 0.0,
    0.0, -1.0, 0.0,
    0.0, -1.0, 0.0,

    0.0, -1.0, 0.0,
    0.0, -1.0, 0.0,
    0.0, -1.0, 0.0,

    # face 5
    1.0, 0.0, 0.0,
    1.0, 0.0, 0.0,
    1.0, 0.0, 0.0,

    1.0, 0.0, 0.0,
    1.0, 0.0, 0.0,
    1.0, 0.0, 0.0,

    # face 6
    -1.0, 0.0, 0.0,
    -1.0, 0.0, 0.0,
    -1.0, 0.0, 0.0,

    -1.0, 0.0, 0.0,
    -1.0, 0.0, 0.0,
    -1.0, 0.0, 0.0
]

# Ugly af.
proc getBlockFaces ( world: var World, x: float, y: float, z: float ): 
    tuple[num: int, verts: array[108, float], nomrals: array[108, float], #[TO-DO]# textCoords: array[72, float]] =
    
    var width = 1.0
    var height = 1.0
    var length = 1.0 
    var faces = [ $(world.getBlock(x, y, z+1)) == "t",
                  $(world.getBlock(x, y, z-1)) == "t",
                  $(world.getBlock(x, y+1, z)) == "t",
                  $(world.getBlock(x, y-1, z)) == "t",
                  $(world.getBlock(x+1, y, z)) == "t",
                  $(world.getBlock(x-2, y, z)) == "t", ]
    if faces[0]:
        result.verts.mask([        x,        y, z+width,
                            x+length,        y, z+width,
                            x+length, y+height, z+width,
                            
                            x+length, y+height, z+width, 
                                  x,  y+height, z+width,
                                  x,         y, z+width ], result.num*18 )
        for i in 0..18:
            result.nomrals[i+result.num*18] = normalRef[i+0*18]
        result.num += 1
    if faces[1]:
        result.verts.mask([        x,        y,        z,
                                   x, y+height,        z,
                            x+length, y+height,        z,
                            
                            x+length, y+height,        z, 
                            x+length,        y,        z,
                                  x,         y,        z ], result.num*18 )
        for i in 0..18:
            result.nomrals[i+result.num*18] = normalRef[i+1*18]
        result.num += 1
    if faces[2]:
        result.verts.mask([        x, y+height,        z,
                                   x, y+height, z+width,
                            x+length, y+height, z+width,
                            
                            x+length, y+height, z+width,
                            x+length, y+height,       z,
                                   x, y+height,       z ], result.num*18 )
        for i in 0..18:
            result.nomrals[i+result.num*18] = normalRef[i+2*18]
        result.num += 1
    if faces[3]:
        result.verts.mask([        x,        y,       z,
                            x+length,        y,       z,
                            x+length,        y, z+width,
                            
                            x+length,        y, z+width,
                                   x,        y, z+width,
                                   x,        y,       z ], result.num*18 )
        for i in 0..18:
            result.nomrals[i+result.num*18] = normalRef[i+3*18]
        result.num += 1
    if faces[4]:
        result.verts.mask([ x+length,        y,       z,
                            x+length, y+height,       z,
                            x+length, y+height, z+width,
                            
                            x+length, y+height, z+width,
                            x+length,        y, z+width,
                            x+length,        y,       z ], result.num*18 )
        for i in 0..18:
            result.nomrals[i+result.num*18] = normalRef[i+4*18]
        result.num += 1
    if faces[5]:
        result.verts.mask([        x,        y,       z,
                                   x,        y, z+width,
                                   x, y+height, z+width,
                            
                                   x, y+height, z+width,
                                   x, y+height,       z,
                                   x,        y,       z ], result.num*18 )
        for i in 0..18:
            result.nomrals[i+result.num*18] = normalRef[i+5*18]
        result.num += 1

proc getChunkModel* (world: var World, chunk: var Chunk): Model =
    echo "here0.1"
    var vertArrayTemp: ref array[108*CHUNK_SIZE, float]
    echo "here0.2"
    var normalArrayTemp: ref array[108*CHUNK_SIZE, float]
    echo "here0.3"
    var textArrayTemp: ref array[108*CHUNK_SIZE, float]
    echo "here0.4"
    var faceI = 0
    echo "Here1"
    for x in 0..<CHUNK_DIMENSION.x:
        for y in 0..<CHUNK_DIMENSION.y:
            for z in 0..<CHUNK_DIMENSION.z:
                var blockFaces = world.getBlockFaces(x.float,y.float,z.float)
                let faceId = faceI*18
                for id in 0..blockFaces.num*18:
                    vertArrayTemp[id+faceId] = blockFaces.verts[id]
                    normalArrayTemp[id+faceId] = blockFaces.nomrals[id]
                faceI += blockFaces.num
                dealloc(blockFaces.addr)
    echo "Here2"
    var mesh: Mesh
    mesh.vertices = cast[ptr cfloat](vertArrayTemp[0])
    mesh.normals = cast[ptr cfloat](normalArrayTemp[0])
    mesh.texcoords = cast[ptr cfloat](textArrayTemp[0])

    mesh.vertexCount = (faceI*18/3).cint # 18 coords / 3 axis
    mesh.triangleCount = (faceI*18/6).cint # ???

    loadMesh(addr mesh, false)

    result = loadModelFromMesh mesh