from nimraylib_now/raylib import Vector3
from oids import Oid
from ../world/world import World

type 
    Entity* = ref object of RootObj
        world*: ref World
        position*: ref Vector3
        velocity*: Vector3
        oid*: Oid