from nimraylib_now/raylib import Vector3
from oids import Oid

type 
    Entity* = ref object of RootObj
        position*: ref Vector3
        velocity*: Vector3
        oid*: Oid