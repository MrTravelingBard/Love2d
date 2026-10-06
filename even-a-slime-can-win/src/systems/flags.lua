-- Story flags
-- `values` is a plain table so title unlock conditions can read it directly.

local M = { values = {} }

function M.reset() M.values = {} end
function M.get(name) return M.values[name] == true end
function M.set(name, v) M.values[name] = (v ~= false) end

function M.set_all(list)
	for _, name in ipairs(list or {}) do M.set(name) end
end

-- true if every `requires` flag is set and no `forbids` flag is set
function M.check(requires, forbids)
	for _, n in ipairs(requires or {}) do if not M.get(n) then return false end end
	for _, n in ipairs(forbids or {}) do if M.get(n) then return false end end
	return true
end

return M