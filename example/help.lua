--======== include and declare constant =======================================
-- local getopt = require('getopt.lua')
local LUA_GETOPT_PATH = "../src/?.lua;"
package.path = LUA_GETOPT_PATH .. package.path
local getopt = require("getopt")
print = require("color-p").print

print("default funciont usage")
getopt.usage_default()

print("callback setting pattern")
getopt.usage_callback()
