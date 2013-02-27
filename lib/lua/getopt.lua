--------------------------------------------------------------------------------
-- get command line options lua module                                        --
-- @Author Dusan Saljic                                                       --
-- @Date 2008-05-07                                                           --
--                                                                            --
-- $Id$                                                                       --
--------------------------------------------------------------------------------

--
-- Base name and the local representation of the lua standard library modules
--
local base = _G
local string = require("string")
local table = require("table")

--------------------------------------------------------------------------------
-- Module name
--
--------------------------------------------------------------------------------
module("getopt")

--
-- Module constants
--
_COPYRIGHT = "Copyright (C) 2008 Schmid Technology Schwetzingen"
_DESCRIPTION = "SVID reader is a library to offline read and analyze SVID data base file"
_NAME = "LuaSVIDReader"
_VERSION = "0.1.1"

--
-- Module global constants
--
OPTARGUMENTS = { ['none'] = 0, ['has'] = 1, ['optional'] = 2 }
NONE = OPTARGUMENTS['none']
MNDT = OPTARGUMENTS['has']
OPTN = OPTARGUMENTS['optional']

--
-- Search for an option in the option table. Partial match is allowed, similar
-- as 'getopt' from libc.
--
local function findOption(opt, opt_table)

	local entry
	local double_found = false
	for j, t in base.ipairs(opt_table) do
		if string.match(t[1],opt) then
			if nil == entry then
				entry = j
				if t[1] == opt then break end
			else
				double_found = true
				break
			end
		end
	end
	
	if nil ~= entry and not double_found then
		return true, opt_table[entry]
	elseif nil ~=entry and double_found then
		return false, 'doubled'
	else
		return false, 'notfound'
	end
end

--
-- Search for long options, and returns the result table like:
--   rez_table[1] ... rez_table[#rez_table] with the structure { 'opt_table[opt_index][3]', option_argument | nil }
--   rez_table[0][1] number of errors during parsing
--   rez_table[-1] ... rez_table[-rez_table[0][1]] with the structure { 0, 'Error string' }
--
local OPTSTATES = { ['begin'] = 0, ['option+optarg'] = 1, ['option+arg'] = 2, ['end'] = 3 }
function getLongOptions(arg_v, opt_table)

	if nil == opt_table or nil == arg_v then return nil end
	
	local opt_res = { }
	opt_res[0] = { 0, nil }
	local err_ind = 0
	local cur_opt = nil
	local state = OPTSTATES['begin']
	
	for i,a in base.ipairs(arg_v) do
	
		-- -- BEGIN
		if state == OPTSTATES['begin'] then
		
			local match = false
			for m,o in string.gmatch(a, '%-%-([%w_%-]+)=([%w()%-%+%.,/%s:%*_]*)') do
				match = true
				local ok,opt = findOption(m, opt_table)
				if not ok then
					opt_res[err_ind][1] = opt_res[err_ind][1] + 1
					if opt == 'notfound' then
						opt_res[-opt_res[err_ind][1]] = { 0, "Unknown option "..m}
					else
						opt_res[-opt_res[err_ind][1]] = { 0, "Too short option '"..m.."', double matched"}
					end
					state = OPTSTATES['begin']
				elseif nil ~= o and opt[2] == OPTARGUMENTS['none'] then
					opt_res[err_ind][1] = opt_res[err_ind][1] + 1
					opt_res[-opt_res[err_ind][1]] = { 0, "Option "..m.." has an argument, but without argument declared."}
					state = OPTSTATES['begin']
				elseif nil ~= o and (opt[2] == OPTARGUMENTS['optional'] or opt[2] == OPTARGUMENTS['has']) then
					table.insert(opt_res, {opt[3], o})
					state = OPTSTATES['end']
				elseif nil == o and opt[2] == OPTARGUMENTS['none'] then
					table.insert(opt_res, {opt[3], nil})
					state = OPTSTATES['end']
				elseif nil ~= m and opt[2] == OPTARGUMENTS['optional'] then
					cur_opt = m
					state = OPTSTATES['option+optarg']
				elseif nil ~= m and opt[2] == OPTARGUMENTS['has'] then
					cur_opt = m
					state = OPTSTATES['option+arg']
				end
			end
			
			if not match then
				for m in string.gmatch(a, '%-%-([%w_%-]+)') do
					match = true
					local ok,opt = findOption(m, opt_table)
					if not ok then
						opt_res[err_ind][1] = opt_res[err_ind][1] + 1
						if opt == 'notfound' then
							opt_res[-opt_res[err_ind][1]] = { 0, "Unknown option "..m}
						else
							opt_res[-opt_res[err_ind][1]] = { 0, "Too short option '"..m.."', double matched"}
						end
						state = OPTSTATES['begin']
					elseif opt[2] == OPTARGUMENTS['none'] then
						table.insert(opt_res, {opt[3], nil})
						state = OPTSTATES['end']
					elseif nil ~= m and opt[2] == OPTARGUMENTS['optional'] then
						cur_opt = m
						state = OPTSTATES['option+optarg']
					elseif nil ~= m and opt[2] == OPTARGUMENTS['has'] then
						cur_opt = m
						state = OPTSTATES['option+arg']
					end
				end
			end
			
			if not match then
				for m in string.gmatch(a, '%-%a') do
					match = true
					local op, ar,val
					for j, t in base.pairs(opt_table) do
						if '-'..t[3] == m then
							op = t[1]
							ar = t[2]
							val = t[3]
							break
						end
					end
					if ar == nil then
						opt_res[err_ind][1] = opt_res[err_ind][1] + 1
						opt_res[-opt_res[err_ind][1]] = { 0, "Unknown short option "..m}
						state = OPTSTATES['begin']
					elseif ar == OPTARGUMENTS['none'] then
						table.insert(opt_res, {val, nil})
						state = OPTSTATES['end']
					elseif ar == OPTARGUMENTS['optional'] then
						cur_opt = op
						state = OPTSTATES['option+optarg']
					elseif ar == OPTARGUMENTS['has'] then
						cur_opt = op
						state = OPTSTATES['option+arg']
					end
				end
			end
		-- -- OPTION+OPTARG
		elseif state == OPTSTATES['option+optarg'] then
			
			local pmatch = false
			for ma in string.gmatch(a, '%-(.*)') do
				pmatch = true
				for j, t in base.pairs(opt_table) do
					if t[1] == cur_opt then
						table.insert(opt_res, {t[3], nil})
						cur_opt = nil
						break
					end
				end
				
				local match = false
				for m,o in string.gmatch(a, '%-%-([%w_%-]+)=([%w()%-%+%.,/%s:%*_]*)') do
				
					match = true
					local ok,opt = findOption(m, opt_table)
					if not ok then
						opt_res[err_ind][1] = opt_res[err_ind][1] + 1
						if opt == 'notfound' then
							opt_res[-opt_res[err_ind][1]] = { 0, "Unknown option "..m}
						else
							opt_res[-opt_res[err_ind][1]] = { 0, "Too short option '"..m.."', double matched"}
						end
						state = OPTSTATES['begin']
					elseif nil ~= o and opt[2] == OPTARGUMENTS['none'] then
						opt_res[err_ind][1] = opt_res[err_ind][1] + 1
						opt_res[-opt_res[err_ind][1]] = { 0, "Option "..m.." has an argument, but witout argument declared."}
						state = OPTSTATES['begin']
					elseif nil ~= o and (opt[2] == OPTARGUMENTS['optional'] or ar == OPTARGUMENTS['has']) then
						table.insert(opt_res, {opt[3], o})
						state = OPTSTATES['end']
					elseif nil == o and opt[2] == OPTARGUMENTS['none'] then
						table.insert(opt_res, {opt[3], nil})
						state = OPTSTATES['end']
					elseif nil ~= m and opt[2] == OPTARGUMENTS['optional'] then
						cur_opt = m
						state = OPTSTATES['option+optarg']
					elseif nil ~= m and opt[2] == OPTARGUMENTS['has'] then
						cur_opt = m
						state = OPTSTATES['option+arg']
					end
				end
			
				if not match then
					for m in string.gmatch(a, '%-%-([%w_-]+)') do
						match = true
						local ok,opt = findOption(m, opt_table)
						if not ok then
							opt_res[err_ind][1] = opt_res[err_ind][1] + 1
							if opt == 'notfound' then
								opt_res[-opt_res[err_ind][1]] = { 0, "Unknown option "..m}
							else
								opt_res[-opt_res[err_ind][1]] = { 0, "Too short option '"..m.."', double matched"}
							end
							state = OPTSTATES['begin']
						elseif opt[2] == OPTARGUMENTS['none'] then
							table.insert(opt_res, {opt[3], nil})
							state = OPTSTATES['end']
						elseif nil ~= m and opt[2] == OPTARGUMENTS['optional'] then
							cur_opt = m
							state = OPTSTATES['option+optarg']
						elseif nil ~= m and opt[2] == OPTARGUMENTS['has'] then
							cur_opt = m
							state = OPTSTATES['option+arg']
						end
					end
				end
				
				if not match then
					for m in string.gmatch(a, '%-%a') do
						match = true
						local op, ar,val
						for j, t in base.ipairs(opt_table) do
							if '-'..t[3] == m then
								op = t[1]
								ar = t[2]
								val = t[3]
								break
							end
						end
						if ar == nil then
							opt_res[err_ind][1] = opt_res[err_ind][1] + 1
							opt_res[-opt_res[err_ind][1]] = { 0, "Unknown short option "..m}
							state = OPTSTATES['begin']
						elseif ar == OPTARGUMENTS['none'] then
						table.insert(opt_res, {val, nil})
							state = OPTSTATES['end']
						elseif ar == OPTARGUMENTS['optional'] then
							cur_opt = op
							state = OPTSTATES['option+optarg']
						elseif ar == OPTARGUMENTS['has'] then
							cur_opt = op
							state = OPTSTATES['option+arg']
						end
					end
				end
			end
			
			if not pmatch then
				for m in string.gmatch(a, '([%w()%-%+%.,/%s:%*_]+)') do
					local ar,val
					for j, t in base.ipairs(opt_table) do
						if t[1] == cur_opt then
							ar = t[2]
							val = t[3]
							break
						end
					end
					
					table.insert(opt_res, {val, m})
					state = OPTSTATES['end']
				end
			end
		-- -- OPTION+ARG
		elseif state == OPTSTATES['option+arg'] then
		
			local pmatch = false
			for ma in string.gmatch(a, '%-(.*)') do
				pmatch = true
				opt_res[err_ind][1] = opt_res[err_ind][1] + 1
				opt_res[-opt_res[err_ind][1]] = { 0, "Option "..cur_opt.." requires an argument, but no argument found." }
				cur_opt = nil
				
				local match = false
				for m,o in string.gmatch(a, '%-%-([%w_%-]+)=([%w()%-%+%.,/%s:%*_]*)') do
					match = true
					local ok,opt = findOption(m, opt_table)
					if not ok then
						opt_res[err_ind][1] = opt_res[err_ind][1] + 1
						if opt == 'notfound' then
							opt_res[-opt_res[err_ind][1]] = { 0, "Unknown option "..m}
						else
							opt_res[-opt_res[err_ind][1]] = { 0, "Too short option '"..m.."', double matched"}
						end
						state = OPTSTATES['begin']
					elseif nil ~= o and opt[2] == OPTARGUMENTS['none'] then
						opt_res[err_ind][1] = opt_res[err_ind][1] + 1
						opt_res[-opt_res[err_ind][1]] = { 0, "Option "..m.." has an argument, but without argument declared."}
						state = OPTSTATES['begin']
					elseif nil ~= o and (opt[2] == OPTARGUMENTS['optional'] or ar == OPTARGUMENTS['has']) then
						table.insert(opt_res, {opt[3], o})
						state = OPTSTATES['end']
					elseif nil == o and opt[2] == OPTARGUMENTS['none'] then
						table.insert(opt_res, {opt[3], nil})
						state = OPTSTATES['end']
					elseif nil ~= m and opt[2] == OPTARGUMENTS['optional'] then
						cur_opt = m
						state = OPTSTATES['option+optarg']
					elseif nil ~= m and opt[2] == OPTARGUMENTS['has'] then
						cur_opt = m
						state = OPTSTATES['option+arg']
					end
				end
				
				if not match then
				for m in string.gmatch(a, '%-%-([%w_%-]+)') do
						match = true
						local ok,opt = findOption(m, opt_table)
						if not ok then
							opt_res[err_ind][1] = opt_res[err_ind][1] + 1
							if opt == 'notfound' then
								opt_res[-opt_res[err_ind][1]] = { 0, "Unknown option "..m}
							else
								opt_res[-opt_res[err_ind][1]] = { 0, "Too short option '"..m.."', double matched"}
							end
							state = OPTSTATES['begin']
						elseif ar == OPTARGUMENTS['none'] then
							table.insert(opt_res, {opt[3], nil})
							state = OPTSTATES['end']
						elseif nil ~= m and opt[2] == OPTARGUMENTS['optional'] then
							cur_opt = m
							state = OPTSTATES['option+optarg']
						elseif nil ~= m and opt[2] == OPTARGUMENTS['has'] then
							cur_opt = m
							state = OPTSTATES['option+arg']
						end
					end
				end
				
				if not match then
					for m in string.gmatch(a, '%-%a') do
						match = true
						local op, ar,val
						for j, t in base.ipairs(opt_table) do
							if '-'..t[3] == m then
								op = t[1]
								ar = t[2]
								val = t[3]
								break
							end
						end
						if ar == nil then
							opt_res[err_ind][1] = opt_res[err_ind][1] + 1
							opt_res[-opt_res[err_ind][1]] = { 0, "Unknown short option "..m}
							state = OPTSTATES['begin']
						elseif ar == OPTARGUMENTS['none'] then
							table.insert(opt_res, {val, nil})
							state = OPTSTATES['end']
						elseif ar == OPTARGUMENTS['optional'] then
							cur_opt = op
							state = OPTSTATES['option+optarg']
						elseif ar == OPTARGUMENTS['has'] then
							cur_opt = op
							state = OPTSTATES['option+arg']
						end
					end
				end
			end
			
			if not pmatch then
				for m in string.gmatch(a, '([%w()%-%+%.,/%s:%*_]+)') do
					local ar,val
					for j, t in base.ipairs(opt_table) do
						if t[1] == cur_opt then
							ar = t[2]
							val = t[3]
							break
						end
					end
					
					table.insert(opt_res, {val, m})
					state = OPTSTATES['end']
				end
			end
		end
		
		if state == OPTSTATES['end'] then
			cur_opt = nil
			state = OPTSTATES['begin']
		end
	end
	
	if state ~= OPTSTATES['end'] then
		if nil ~= cur_opt then
			for j, t in base.pairs(opt_table) do
				if t[1] == cur_opt then
					if t[2] == OPTARGUMENTS['optional'] then table.insert(opt_res, {t[3], nil})
					else
						opt_res[err_ind][1] = opt_res[err_ind][1] + 1
						opt_res[-opt_res[err_ind][1]] = { 0, "Option "..cur_opt.." requiers an argument, but no argument found."}
					end
				break
				end
			end
		end
	end
	
	return opt_res
end

--[[ example of usage:

require "getopt"
do
	local opt_table = {
		{ 'help', getopt.OPTN 'h' },
		{ 'show', getopt.NONE, 's' },
		{ 'to-file', getopt.MNDT, 't' }
	}
	
	local options = getopt.getLongOptions(arg, opt_table)
	
	for o,v in pairs(options) do print (o, v[1], v[2]) end
end
]]

-- End of getopt.lua
-- vim: set ts=2: