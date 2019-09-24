-- Documentation available at https://github.com/Hexcede/ViewportRender/blob/master/Documentation.md

-- Services
local RunService = game:GetService("RunService")

-- Render object
local Render = {}

-- Plugins
Render.Installations = {}
function Render:Inject(plugin)
	-- Set up an OnCamera event if one isn't already setup
	plugin.OnCamera = plugin.OnCamera or Instance.new("BindableEvent")
	
	-- Store the plugin
	table.insert(Render.Installations, plugin)
end
function Render:Install(module)
	-- Require the plugin
	local plugin = require(module)
	
	-- Inject the plugin
	Render:Inject(plugin)
end

-- Create a camera
function Render:CreateCamera()
	-- Camera object
	local camera = {}
	
	-- Default camera data
	camera.Camera = Instance.new("Camera")
	camera.Frame = Instance.new("ViewportFrame")
	camera.Frame.BackgroundTransparency = 1
	camera.Frame.Ambient = Color3.new(1, 1, 1)
	camera.Frame.LightColor = Color3.new(1, 1, 1)
	camera.Frame.CurrentCamera = camera.Camera
	camera.Camera.Parent = camera.Frame
	camera.Runners = {}
	
	-- Camera change event
	camera.ChangeEvent = Instance.new("BindableEvent")
	function camera:OnChange(callback)
		return camera.ChangeEvent.Event:Connect(callback)
	end
	
	-- Camera runner
	function camera:Run()
		camera.Running = true
		spawn(function()
			-- Clone/real hash
			local hash = {}
			
			-- Workspace hash
			hash[workspace] = camera.Frame
			
			-- Hash updater
			local pendingHash = {}
			local function waitForHash(object)
				pendingHash[object] = Instance.new("BindableEvent")
				pendingHash[object].Event:Wait()
				return hash[object]
			end
			
			local function addObject(object)
				-- Caching
				if hash[object] then
					return hash[object]
				end
				
				-- Object cloning
				local archivable = object.Archivable
				object.Archivable = true
				
				local pass, viewModel = pcall(function()return object:Clone()end)
				if not pass or not viewModel then
					return
				end
				
				object.Archivable = archivable
				
				-- Object hashing
				hash[object] = viewModel
				hash[viewModel] = object
				
				if pendingHash[object] then
					-- Hash updating
					pendingHash[object]:Fire()
					pendingHash[object] = nil
				end
				
				-- Clear children
				viewModel:ClearAllChildren()
				
				if object:IsA("BasePart") then
					-- Part Rendering
					
					-- Start a runner
					local runnerIndex = #camera.Runners+1
					table.insert(camera.Runners, RunService.RenderStepped:Connect(function()
						-- Destroy the runner if the part is destroyed
						if not object:IsDescendantOf(workspace) then
							viewModel:Destroy()
							
							camera.Runners[runnerIndex]:Disconnect()
							camera.Runners[runnerIndex] = nil
							
							return
						end
						
						-- If the object is visible
						if object.Transparency < 0.98 then
							-- Fire change event and change CFrame
							camera.ChangeEvent:Fire("CFrame", object, object.CFrame, viewModel.CFrame)
							viewModel.CFrame = object.CFrame
						else
							-- Hide the object
							viewModel.Transparency = 1
						end
					end))
				end
				
				-- Hashed object parenting
				viewModel.Parent = hash[object.Parent] or waitForHash(object.Parent)
				
				-- Object updating
				local onChange = object.Changed:Connect(function(property)
					if property ~= "Parent" then
						pcall(function()
							-- Fire change event and change property
							camera.ChangeEvent:Fire(property, object, object[property], viewModel[property])
							viewModel[property] = object[property]
						end)
					end
				end)
				
				-- Event disconnection
				local onMove
				onMove = viewModel.AncestryChanged:Connect(function()
					if not viewModel.Parent then
						onChange:Disconnect()
						onMove:Disconnect()
					end
				end)
				
				-- Return viewModel
				return viewModel
			end
			
			-- Descendant finding
			for _, descendant in ipairs(workspace:GetDescendants()) do
				spawn(function()
					addObject(descendant)
				end)
			end
			workspace.DescendantAdded:Connect(addObject)
			
			-- Descendant removing
			workspace.DescendantRemoving:Connect(function(object)
				if hash[object] then
					-- Hash clearing/viewmodel cleanup
					hash[hash[object]] = nil
					hash[object]:Destroy()
					hash[object] = nil
				end
			end)
		end)
	end
	
	-- Camera tracking
	function camera:Track(targetCamera, offset)
		-- Remove old tracker
		if camera.Tracker then
			camera.Tracker:Disconnect()
		end
		
		-- Start tracking
		camera.Tracker = RunService.RenderStepped:Connect(function()
			-- Get the default camera if necessary
			local targetCamera = targetCamera or workspace.CurrentCamera
			
			-- Update the FieldOfView and CFrame
			camera.Camera.FieldOfView = targetCamera.FieldOfView
			camera.Camera.CFrame = targetCamera.CFrame*offset
		end)
	end
	
	-- Destroy camera
	function camera:Destroy()
		camera.Running = false
		
		-- Clear data
		camera.Frame:Destroy()
		camera.Frame:ClearAllChildren()
		camera.Camera:Destroy()
		camera.Frame = nil
		camera.Camera = nil
		
		-- Clear tracker
		if camera.Tracker then
			camera.Tracker:Disconnect()
		end
		camera.Tracker = nil
		
		-- Clear runners
		for _, runner in ipairs(camera.Runners) do
			runner:Disconnect()
		end
		camera.Runners = nil
	end
	
	-- Plugin handling
	for _, plugin in ipairs(Render.Installations) do
		-- Fire the OnCamera plugin event
		plugin.OnCamera:Fire(camera)
	end
	
	-- Return camera
	return camera
end

-- Return Render
return Render
