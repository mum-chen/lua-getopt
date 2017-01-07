--======== include and declare constant =======================================
-- local getopt = require('getopt.lua')
local LUA_GETOPT_PATH = "../?.lua;"
package.path = LUA_GETOPT_PATH .. package.path
local getopt = require("getopt")
print = require("src.color-p").print

print("default funciont usage")
getopt.usage_default()

print("callback setting pattern")
getopt.usage_callback()
