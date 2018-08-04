local Cam = game.Workspace.CurrentCamera
Cam:ClearAllChildren()
--wait()
--game.Workspace.CurrentCamera = Instance.new("Camera")
Cam.FieldOfView = 70
Cam.CameraType = "Custom"
Cam.CameraSubject = game.Players.LocalPlayer.Character.Humanoid
