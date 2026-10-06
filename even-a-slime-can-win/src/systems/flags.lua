-- Story flags
-- `values` is a plain table so title unlock conditions can read it directly.

local M = { values = {} }

function M.reset() M.values = {} end
function M.get(name) return M.values[name] == true end
function M.set(name, v) M.values[name] = (v ~= false) end

function M.set_all(list)
	for _, name in ipairs(list or {}) do M.set(name) end
end

-- true if every `must_have` flag is set and no `cannot_have` flag is set
function M.check(must_have, cannot_have)
	for _, n in ipairs(must_have or {}) do if not M.get(n) then return false end end
	for _, n in ipairs(cannot_have or {}) do if M.get(n) then return false end end
	return true
end

return M