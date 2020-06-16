-- gcr except not using uis
local module = {}

-- services
local players = game:GetService("Players")
local rs = game:GetService("ReplicatedStorage")

-- component folder
local shared = rs:WaitForChild("shared")
local modules = shared:WaitForChild("modules")
local components = modules:WaitForChild("components")

-- initialization
local plr = players.LocalPlayer
local pgui = plr:WaitForChild("PlayerGui")

local uiBinds = {}
local uiHooks = {}

-- local functions
-- run the components
local function runComponent(name, parent)
	local component = components:FindFirstChild(name, true)
	if component then
		if parent then
			require(component)(parent)
		end
	else
		warn(("[gcr] Component %s does not exist."):format(name))
	end
end

local function empty()
	-- this is used for self:hookButton()
end

-- gcr functions
function module:init()
	self:runComponents(pgui)
end

function module:runComponents(container)
	-- loop through container and run components
	for _,v in pairs(container:GetDescendants()) do
		if v:IsA("Configuration") then
			runComponent(v.Name, v.Parent)
		end
	end

	-- handle new instances being added
	container.DescendantAdded:connect(function(descendant)
		if descendant:IsA("Configuration") then
			runComponent(descendant.Name, descendant.Parent)
		end
	end)
end

function module:bind(eventName, func)
	if not uiBinds[eventName] then
		uiBinds[eventName] = {}
	else
		warn(("[gcr] Attempted to overwrite bind %s!"):format(eventName))
	end

	table.insert(uiBinds[eventName], func)
end

function module:fire(eventName, ...)
	-- check if event exists
	if uiBinds[eventName] then
		-- fire event
		local args = {...}
		for _,v in pairs(uiBinds[eventName]) do
			local s, err = pcall(v, unpack(args))
			if not s then
				error(err)
			end
		end
	else
		warn(("[gcr] Event %s does not exist."):format(eventName))
	end
end

function module:hookButton(button, clickFunction, enterFunction, leaveFunction)
	if button.ClassName == "TextButton" then
		-- check if button has already been hooked
		if uiHooks[button] then
			for _,v in pairs(uiHooks[button]) do
				v:disconnect()
			end

			-- default if needed
			enterFunction = enterFunction or empty
			leaveFunction = leaveFunction or empty

			-- connect events
			uiHooks[button] = {
				button.MouseButton1Click:connect(clickFunction),
				button.MouseEnter:connect(enterFunction),
				button.MouseLeave:connect(leaveFunction)
			}
		end
	else
		warn("[gcr] Attempted to call hookButton on an instance that isn't a TextButton.")
	end
end

return module
