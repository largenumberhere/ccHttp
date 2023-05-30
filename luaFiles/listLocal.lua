--todo:make program that lists files availible
--local url = http://localhost:8000

local function getUrl()
    local lines = io.lines(".cchttp-last-url.txt","*l")
    -- if #lines ~= 1 then
    --     error("unexpected urls count")
    -- end
    local urlLine = ""
    for line in lines do
        urlLine = line;
        break;
    end

    return urlLine;
end

local function tryGetAllhttpLines(url)
    local reply =  http.get(url)
    if reply ~= nil then
        return reply.readAll()
    end

    return nil
end

--check server version
local url = getUrl()
local ccHttpVversion = tryGetAllhttpLines(url.."/version") or "unknown"

local function replaceBacckSlashesWithForward(aString)
    local output =  string.gsub(aString, "\\","/")
    return output;
end

local function isPathInSubdirectory(subdirectoryPath, path)
    -- print(path)
    -- print(subdirectoryPath)
    local path2 = string.sub(path,1,#subdirectoryPath);
    local subdirectoryPath2 = string.sub(subdirectoryPath,1,#subdirectoryPath)

    local isSubDirectory =  path2==subdirectoryPath2
    return isSubDirectory
end

-- local function getSubDirectoryOrFileRelativeTo(basePath,path)
--     local pathEnd = string.sub(path,#basePath)
--     local pathEndSlashPos = string.find(pathEnd,"/")
--     if pathEndSlashPos == nil then
--         return pathEnd
--     else
--         local directSubDirectoryOrFile =  string.sub(pathEnd,1,pathEndSlashPos)
--         return directSubDirectoryOrFile
--     end
-- end

-- --works
-- local function containsForwardSlashes(aString) 
--     local foundPos = string.find(aString,"/")
--     print(foundPos)
--     --error("aa")

--     if foundPos == nil then
--         return false
--     end
--     return true
-- end

local function fetchRemoteFilePathsCorrected()
    --fetch remote files
    local filePaths =  http.get(url.."/files/list_all")
    local remoteFilePathsCorrected = {}
    while true do
        local remoteFilePath = filePaths.readLine();
        if remoteFilePath == nil then
            break;
        end
        local remoteFilePathCorrected = replaceBacckSlashesWithForward(remoteFilePath)
        table.insert(remoteFilePathsCorrected,remoteFilePathCorrected)
    end
    return remoteFilePathsCorrected
end

local function getRemoteFilePathsForPath(basePath,remoteFilePathsCorrected)
    local fileAndFoldersInBasePathDirectory = {}
    for _, remoteFilePathCorrected in pairs(remoteFilePathsCorrected) do
        if(isPathInSubdirectory(basePath,remoteFilePathCorrected)) then
            table.insert(fileAndFoldersInBasePathDirectory,remoteFilePathCorrected)
        end
    end

    return fileAndFoldersInBasePathDirectory
end

local function isPathInAnySubdirectory(pathLookingFor, pathsToLookIn)
    for _, path in pairs(pathsToLookIn) do
        if isPathInSubdirectory(pathLookingFor,path) then
            return true
        end
    end

    return false
end

if ccHttpVversion == "2.2" then
    local currentOsDirectory = "/"..shell.dir();
    local localFilesAndFolderInDirectory = fs.list(currentOsDirectory)
    local remoteFilePathsInSubdirectory = getRemoteFilePathsForPath(currentOsDirectory,fetchRemoteFilePathsCorrected())
    
    local localOnly = {}
    for _,localDirectoryShortName in pairs(localFilesAndFolderInDirectory) do
        local localDirectoryLongName =  "/"..shell.resolve(localDirectoryShortName)
        if not (isPathInAnySubdirectory(localDirectoryLongName,remoteFilePathsInSubdirectory)) then
            table.insert(localOnly,localDirectoryShortName)
        end
    end

    local nonHiddenLocal = {}
    for _, localFilePath in pairs(localOnly) do
        local potentialDotCharater = string.sub(localFilePath,1,1)
        if potentialDotCharater ~= "." then
            table.insert(nonHiddenLocal,localFilePath)
        end
    end


    print(textutils.tabulate(nonHiddenLocal))

else
    error("unsupported version")
end