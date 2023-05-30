function getUrl()
    local filePath = ".cchttp-last-url.txt"
    local output = ""
    
    if not fs.exists(filePath) then
        return nil
    end

    local fileLineReader = io.lines(filePath,"*l")
    for v in fileLineReader do
        output= v;
    end
    return output
end

local url = getUrl() or "http://localhost:8000"

local args = {...}

if args[1] == nil then
    error("no argument supplied")
end

if not fs.exists(args[1]) then
    error("file does not exist "..args[1])
end

local fileName = args[1]

--local data = io.lines(fileName)


local lineReader = io.lines(fileName,"*l");
local data = lineReader()
for value in lineReader do
    if value ~=nil then
        data = data.."\n"..value
    end 
end
local jsonHeader = { ["Content-Type"] = "application/json"};
local postUrl = url.."/file/upload?filePath="..fileName
local result =  http.post(postUrl,data,{ ["content-Type"] = "text/plain"});