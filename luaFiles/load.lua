local args = {...}

--looks for an argument with that start and gives the rest of the argument or nil
--getArgumentValue({"a=22","b=4"},"b=") => 4
local function getArgumentValue(argsTable,startsWith)
    for _,v in pairs(argsTable) do
        if string.sub(v,1,#startsWith) == startsWith then
            return string.sub(v,#startsWith+1)
        end
    end
end

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
local url = getArgumentValue(args,"--url=") or getUrl()
local ccHttpVersion = tryGetAllhttpLines(url.."/version") or "unknown"

if ccHttpVersion == "2.1" then
    --save the url
    print(url)
    local file =  fs.open(".cchttp-last-url.txt","w")
    print(file)
    file.writeLine(url)
    file.flush();
    file.close();
    print(file)

    --returns the directory structure as a string and the fileName as a string 
    local function splitRelativePath(relativePath)
        local lastSlashPattern = "\\[^\\]*$"
        local lastSlashPosition = string.find(relativePath,lastSlashPattern)
        local directoriesEndPosition = lastSlashPosition-1
        local fileEndPosition = lastSlashPosition +1

        local directoryStructure = string.sub(relativePath,0,directoriesEndPosition)
        local fileName = string.sub(relativePath,fileEndPosition)

        return directoryStructure,fileName
    end

    local function removePrecedingBackslash(relativePath)
        local character1 =  string.sub(relativePath,1,1)
        --print(character1)
        local value = ""

        if character1 == "\\" then
            value = string.sub(relativePath,2,#relativePath)
        else
            value = relativePath
        end
        --print(value)
        return value
    end


    --version 2.1

    local verboseLogs = false;

    local function printIfVerbose(message)
        if verboseLogs == true then
            print(message)
        elseif verboseLogs == false then
        else
            error("verboseLogs is not a boolean")
        end
    end

    --todo: change new tableContains method so multiple args can be passed in any order
    if getArgumentValue(args,"--verbose-logs") ~= nil then
        verboseLogs = true
    end

    -- if args[1] == "--verbose-logs" then
    --     verboseLogs = true
    -- end

    printIfVerbose("version "..ccHttpVersion.." of api detected")

    printIfVerbose("fetching files list")
    local paths = http.get(url.."/files/list_all")
    if paths == nil then
        error("failed to fetch file listing")
    end

    local pathsTable = {}
    while true do
        local line = paths.readLine()
        if line == nil then
            break;
        end
        table.insert(pathsTable,line)
    end
    if #pathsTable == 0 then
        error("no files entries")
    end
    printIfVerbose(tostring(#pathsTable).." files found")

    for _,fileRelativePath in pairs(pathsTable) do
        local directoryStructure, fileName = splitRelativePath(fileRelativePath)
        
        --if file isn't already there
        if not fs.exists(fileRelativePath) then
            --make the folder structure if it does not exist
            if not fs.exists(directoryStructure) then
                fs.makeDir(directoryStructure)
                printIfVerbose("directory created "..tostring(directoryStructure))
            end

            --make the file if it does not exist
            if not fs.exists(fileRelativePath) then
                local file = fs.open(fileRelativePath,"w");
                file.close();
                printIfVerbose("file created "..tostring(fileRelativePath))
            end
        end
        
        printIfVerbose(fileRelativePath)
        local fileRequest =  http.get(url.."/file/get_one?filePath="..removePrecedingBackslash(fileRelativePath))
        local fileLines = fileRequest.readAll()
        local file = fs.open(fileRelativePath,"w")
        file.write(fileLines)
        file.close();
        printIfVerbose("file saved as "..fileRelativePath)
    end

    printIfVerbose("done.")

    --check server version
    --send list of local paths and thier versions
        --recieve files that need updating and parse them

elseif ccHttpVersion == "2.2" then
    --save the url
    --print(url)
    local file =  fs.open(".cchttp-last-url.txt","w")
    --print(file)
    file.writeLine(url)
    file.flush();
    file.close();
    --print(file)

    local function makeConcurrentRequests(requestUrls)
        assert(type(requestUrls) == "table")

        if #requestUrls == 0 then
            return {}
        end
        
        local response_data = {}
        local requests_total = #requestUrls
        local requests_count = 0
        for i,v in pairs(requestUrls) do
            table.insert(response_data,
                {
                    ["url"]= requestUrls[i],
                    ["response"] = "none",
                    ["handle"] = "none"
                }
            )
        end
        
        for i,v in pairs(response_data) do
            http.request(v.url);
        end
        


        while true do
            local eventData = {os.pullEvent()}
            local eventName = eventData[1]
    
    
            if (eventName == "http_success" or eventName == "http_failure") then
                --print("http event!")
                local eventUrl = eventData[2];
                
                local urlFound = false;
                for i,v in pairs(response_data) do
                    if (v.url == eventUrl) then
                        response_data[i].response = eventName
                        response_data[i].handle = eventData[3]
                        urlFound = true
                    end
                end
    
                if urlFound == true then
                    requests_count = requests_count+1
                end
    
                if requests_count == requests_total then
                    break
                end
            end
        end
    
        return response_data
    end
    
    local function assertNoHttpFailuresOrErrors(conccurentHttpResponseDatas)
        for i,v in pairs(conccurentHttpResponseDatas) do
            local url = v.url;
            local response = v.response;
            local handle = v.handle;
    
            --check for http failures
            assert(response~="http_failure")
            
            --ensure all values are as expected
            assert(url~="none")
            assert(response~="none")
            assert(handle~="none")
    
            assert(url~=nil)
            assert(response~=nil)
            assert(handle~=nil)
        end
    end

    local function seperateFileNameAndTimePair(fileNameAndTimePair)
        local characterItterator = fileNameAndTimePair:gmatch(".");
        local fileName = ""
        local time = ""
        local fileNameFinished = false
        for c in characterItterator do
            if c == "," then
                fileNameFinished = true
            else
                if not fileNameFinished then
                    fileName = fileName..c
                elseif fileNameFinished then
                    time = time..c
                end
            end
        end

        return fileName,time
    end

    local function removePrecedingBackslash(relativePath)
        local character1 =  string.sub(relativePath,1,1)
        --print(character1)
        local value = ""

        if character1 == "\\" then
            value = string.sub(relativePath,2,#relativePath)
        else
            value = relativePath
        end
        --print(value)
        return value
    end

    local verboseLogs = false;
    if getArgumentValue(args,"--verbose-logs") ~= nil then
        verboseLogs = true
    end

    local function printIfVerbose(message)
        if verboseLogs == true then
            print(message)
        elseif verboseLogs == false then
        else
            error("verboseLogs is not a boolean")
        end
    end

    local datesFilePath = ".cchttp-last-dates.txt"

    local currentDatePairs = {}
    if fs.exists(datesFilePath) then
        if(os.version() == "1.8") then
        
        else
        
        end

         local currentDates = io.lines(datesFilePath,"*l")
        for pair in currentDates do
            local file,time = seperateFileNameAndTimePair(pair)
            -- print(file)
            -- print(time)
            -- sleep(1)
            if fs.exists(file) == true then
                table.insert(currentDatePairs,{["file"]=file,["time"]=time})
            end
        end
    end


--
    local function splitRelativePath(relativePath)
        assert(relativePath~=nil)
        local lastSlashPattern = "\\[^\\]*$"
        local lastSlashPosition = string.find(relativePath,lastSlashPattern)
        if lastSlashPosition == nil then -- there was no slashes
            return "/",relativePath
        end
        local directoriesEndPosition = lastSlashPosition-1
        local fileEndPosition = lastSlashPosition +1

        local directoryStructure = string.sub(relativePath,0,directoriesEndPosition)
        local fileName = string.sub(relativePath,fileEndPosition)

        return directoryStructure,fileName
    end

    
    local newDatePairsResponse = http.get(url.."/files/lastModifiedTimestamps")
    if newDatePairsResponse == nil then
        error("failed to fetch new timestamps")
    end

    local newDatePairs = {}
    while true do
        local line = newDatePairsResponse.readLine();
        if line == nil then
            break
        end
        table.insert(newDatePairs,line)
    end

    local filesToUpdate = {}
    for _,line in pairs(newDatePairs) do
        local newFileName,newTime = seperateFileNameAndTimePair(line)
        assert(newFileName~=nil)
        assert(newTime~=nil)

        local fileAlreadyUpToDate = false
        for _,currentPair in pairs(currentDatePairs) do
            local currentFileName = currentPair.file
            assert(currentFileName ~=nil)
            local currentTime = currentPair.time
            assert(currentTime~=nil)

            if currentTime == newTime and currentFileName == newFileName then
                fileAlreadyUpToDate = true
                break;
            end

        end
        if fileAlreadyUpToDate == false then
            table.insert(filesToUpdate,newFileName)
        end
    end

    --prepare the path
    for _,fileRelativePath in pairs(filesToUpdate) do
        local directoryStructure, fileName = splitRelativePath(fileRelativePath)
        
        --if file isn't already there
        if not fs.exists(fileRelativePath) then
            --make the folder structure if it does not exist
            if not fs.exists(directoryStructure) then
                fs.makeDir(directoryStructure)
                printIfVerbose("directory created "..tostring(directoryStructure))
            end

            --make the file if it does not exist
            if not fs.exists(fileRelativePath) then
                local file = fs.open(fileRelativePath,"w");
                file.close();
                printIfVerbose("file created "..tostring(fileRelativePath))
            end
        end
    end

    --prepare the request strings
    local fileUrls = {}
    for _,fileRelativePath in pairs(filesToUpdate) do
        printIfVerbose("prepating to download "..removePrecedingBackslash(fileRelativePath))
        table.insert(fileUrls, url.."/file/get_one?filePath="..removePrecedingBackslash(fileRelativePath))
    end

    --send the requests
    local responses = makeConcurrentRequests(fileUrls);
    assertNoHttpFailuresOrErrors(responses)
    
    --record them
    for _, responseData in pairs(responses) do
        local url = responseData.url;
        local response = responseData.response;
        local handle = responseData.handle;

        -- print(url)
        -- print(responseData)
        -- for i,v in pairs(responseData.handle) do
        --     print(i..":"..tostring(v))
        -- end

        --remove the url before filePath=...
        local _, pathEnd = string.find(url,"?filePath=")
        local filePath = "/"..string.sub(url,pathEnd+1);
        --print("filePath: '"..filePath.."'")

        --write it to the file with the name
        --printIfVerbose(filePath)
        local fileLines = handle.readAll()
        file = fs.open(filePath, "w")
        file.write(fileLines)
        file.close();
        printIfVerbose("file saved as "..filePath)

    end

    --- update local file at the end
    local file = fs.open(datesFilePath,"w")
    for _,v in pairs(newDatePairs) do
        file.writeLine(v);
    end
    file.close();

elseif ccHttpVersion == "3.1" then
    --- --- --- 3.1 --- --- --- 
    error("very unfinished")
    os.loadAPI("Json/jsonAPI")
    local response = http.get(url.."/files/all")
    local responseLines = response.readAll()
    print("end")
    --local data =  decode(response);
    local data = jsonAPI.decode(responseLines)
    print(data)
    --print(textutils.serialise(response.readAll()))
    

    --- --- --- end 3.1 --- ---
elseif ccHttpVersion == "unknown" then
    error("unable to fetch version. No OK response was given from the url="..url)
else
    error("unsupported api version is running :"..tostring(ccHttpVersion))
end
