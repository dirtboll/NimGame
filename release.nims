mode = ScriptMode.Verbose
exec """nim compile --define:release --opt:speed --cpu:ia64 -t:-m64 -l:-m64 --out:"bin/game.exe" main.nim"""
if existsFile "bin/test.exe": rmFile "bin/test.exe"