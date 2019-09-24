# Plugins
> `void ViewportRender:Inject(Plugin plugin)`
> Injects a plugin
>
> `void ViewportRender:Install(ModuleScript module)`
> Installs a plugin from a module
>
> `BindableEvent Plugin.OnCamera`
> A BindableEvent which is fired when a camera is created

# Cameras
> `Camera ViewportRender:CreateCamera()`
> Creates a camera
>
> `Camera Camera.Camera`
> A camera instance
>
> `ViewportFrame Camera.Frame`
> The ViewportFrame for the Camera
>
> `boolean Camera.Running`
> Is the camera running?
>
> `table Camera.Runners`
> A list of connected runners
>
> `BindableEvent Camera.ChangeEvent`
> An event which is fired when properties change
>
> `RbxScriptSignal Camera:OnChange(function callback: function(string property, Instance object, Variant newValue, Variant oldValue))`
> Connects to the above event
>
> `void Camera:Run()`
> Runs the camera renderer
>
> `RbxScriptSignal Camera.Tracker`
> A connection for camera tracking
>
> `RbxScriptSignal Camera:Track(Camera camera = workspace.CurrentCamera, CFrame offset)`
> Starts tracking a camera and returns the new `Camera.Tracker`
>
> `void Camera:Destroy()`
> Destroys and cleans up the camera
