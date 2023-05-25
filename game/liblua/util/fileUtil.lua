-- --------------------------------------
-- Create Date:2023-03-18 11:14:53
-- Author  : Happy Su
-- Version : 1.0
-- Filename: fileUtil.lua
-- Introduce  : 类介绍
-- --------------------------------------
---@class fileUtil
local fileUtil = BuildOther("fileUtil")

-- 加载lua文件
---@param filePath string 需要加载的lua文件路径，不带.lua后缀
function fileUtil.loadfile(filePath)
    local name = filePath .. ".lua"
    local file = io.open(name, "rb")
    if not file then
        log.Error("sys", "fileUtil error: Can't open " .. name)
        return
    end
    local source = file:read "*a"
    file:close()

    local f, err = load(source, nil, "t")
    if not f then
        log.Error("sys", "fileUtil error: load file[" .. name .. "] error \n " .. err)
    end
    log.Info("sys", "fileUtil.loadfile filePath:", filePath)
    return f()
end

return fileUtil
