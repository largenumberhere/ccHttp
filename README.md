# A file server for use with computercraft
Easily fetch all your scripts on any computercraft computer quickly and effectively!
This is not the source code, but a copy of the program and its dependencies for convienient instalation
(only windows is supported)

## Quickstart guide:
1. On your windows pc, you should install:
 - Ngrock client (make sure it is installed, logged in, and availible from the command line) (required)
 - Vscode (optional)
2. Clone this folder from github onto your computer.
3. Launch it _ONE_ of 3 ways
- Open vscode inside of .\luaFiles . This is recommended for script writers who want to easily modify thier files and run the server all in one place.
After a a few secconds, a terminal should open.
I reccomend this vscocde extension for more convienient script writing https://marketplace.visualstudio.com/items?itemName=lemmmy.computercraft-extension-pack
OR
- double click on run
OR
- open powershell in the root folder and type `.\CcAspNet.exe`

The console will spil out some logs until it is ready. It will take a few secconds at least.rtant. 

4. Look for the line in the console output that looks *like* this       ```load the api with in cc lua with:       load(http.get('https://3457-119-18-1-211.ngrok-free.app/file/get_one?filePath=load.lua').readAll()) ('--verbose-logs,','--url=https://3457-119-18-1-211.ngrok-free.app') ```
It will be different every time you start it. Copy all the text from `load`... to ...`')`
5. Start a computercraft computer with an internet connection. type `lua` and hit enter. Then paste in the line you just copied. Hit enter again.
The computer will download all your files from inside of `.\luaFiles`. Now while the server is on, you can change any file inside of the luaFiles folder and type `load.lua` <Enter> to downlaod the latest version of the files.
6. To stop the server, click on the console and press control+C. This will stop the server gracefully. If you do not follow this step, you will need to fix it next time you run.
7. The next time you start the server you will have to repeat step 4 and 5

# Extra features
- Programs included:
-- You can upload files to the server with `push.lua fileName.lua` where fileName.lua is a file on your computercraft computer.
-- On your computer you can list remote files with `remoteList.lua` and local ones with `listLocal.lua`. listLocal is particularly useful because it hides all files that have been downlaoded from the server, so it's clear which are unique to this computer!
- folders are supported
- Concurrent file downlaods for extra speed!
- Logging is for `load.lua` is intentionally off by default. Any time you want to see logs, you will have to include `--verbose-logs` like so `load.lua --verbose-logs`. You will need to include it every time.

# Troubleshooting:
- If your console closes immediately after opening, you may have run into a common bug! This is due to the fact, this program doesn't really use ngrock as intended :(
SOLUTION: please sign into ngrock.com and go to https://dashboard.ngrok.com/tunnels/agents . Ensure no tunnel is already being used. If any are running click on the stop button. 
See ngrock documentation for more information about agents
- The included programs have only been tested with FTB infinity evolved, with craftos 1.75 and computercraft version 1.75. If you find any incompatibilities please feel free to open an issue. 
- Please report any issues to me
- A reminder that this has not been tested with linux. No asurences are made for compatability. Try at your own risk
