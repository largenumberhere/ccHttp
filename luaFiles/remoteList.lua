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

--check server version
local url = getUrl()
local ccHttpVversion = http.get(url.."/version").readAll() or "unknown"

if ccHttpVversion == "2.2" then
    local filePaths =  http.get(url.."/files/list_all")
    textutils.pagedPrint(filePaths.readAll())
    -- while true do
    --     local filePath = filePaths.readLine();
    --     if filePath == nil then
    --         break;
    --     end
    --     print(": "..filePath)
    -- end
else
    error("unsupported version")
end