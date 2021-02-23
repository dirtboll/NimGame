import os, strformat

requires "nim >= 1.4.2"
requires "nimraylib_now"
requires "nim-glm"

const 
    USAGE = "Usage: nims script.nim [test,release]"

    NIM_COMPILER  = "nim "
    TEST_PARAM    = "--d:test --gc:arc --verbosity:2"
    RELEASE_PARAM = "--define:release --opt:speed --cpu:ia64 -t:-m64 -l:-m64"
    MAIN          = "src/main.nim"

var 
    CMD = NIM_COMPILER
    OUT_FILE = ".exe"

if paramCount() < 3:
    echo USAGE
    quit()
elif paramStr(3) == "test":
    CMD &= TEST_PARAM
    OUT_FILE = "bin/test" & OUT_FILE
elif paramStr(3) == "release":
    CMD &= RELEASE_PARAM
    OUT_FILE = "bin/game" & OUT_FILE
else:
    echo USAGE
    quit()

mode = ScriptMode.Verbose
echo fmt"""{CMD} --out:"{OUT_FILE}" c {MAIN}"""
exec fmt"""{CMD} --out:"{OUT_FILE}" c {MAIN}"""