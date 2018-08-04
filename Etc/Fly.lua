wait(0.001);

local user=game:service'Players'.LocalPlayer;
local cam=workspace.CurrentCamera;
local mouse=user:GetMouse();
local char=user.Character;
local torso=char.Torso;

local tool=Instance.new'HopperBin';
local force,gyro;

local version=0;
local maxSpeed=5;
local speed=1;
local keys={};

----------------------------------------------------------------------------------------------------

for i,v in ipairs{torso,user.Backpack}do
	for i,v in ipairs(v:children())do
		if(v.Name=='Fly')then
			v:Destroy();
		end;
	end;
end;

----------------------------------------------------------------------------------------------------

local function selected(mouse)
	force=Instance.new('BodyPosition',torso);
		force.maxForce=Vector3.new(4e10,4e10,4e10);
		force.position=torso.Position;
		force.Name='Fly';
		force.P=100000;
	gyro =Instance.new('BodyGyro'    ,torso);
		gyro.maxTorque=Vector3.new(4e10,4e10,4e10);
		gyro.cframe=cam.CoordinateFrame;
		gyro.Name='Fly';
		gyro.P=100000;
	
	local v=version;
	
	local oldc;
	while(v==version)do
		local c=gyro.cframe-gyro.cframe.p+force.position;
		
		if(keys[string.char(48)])then speed=1;end;
		if(keys.w)then c=c+cam.CoordinateFrame.lookVector*speed;end;
		if(keys.s)then c=c-cam.CoordinateFrame.lookVector*speed;end;
		if(keys.d)then c=c*CFrame.new(speed,0,0);end;
		if(keys.a)then c=c*CFrame.new(-speed,0,0);end;
		if(keys.e or keys[' '])then c=c*CFrame.new(0,speed,0);end;
		if(keys.q)then c=c*CFrame.new(0,-speed,0);end;
		
		if(oldc~=c)then	
			force.position=c.p;
			oldc=c;
			speed=math.min(speed+speed*0.025,maxSpeed);
		else
			speed=1;
		end;
		
		gyro.cframe=cam.CoordinateFrame;
		
		wait(0.01);
	end;
end;

local function deselected(mouse)
	version=version+1;
	force:Destroy();
	gyro:Destroy();
end;

----------------------------------------------------------------------------------------------------

tool.Name='Fly';
tool.Parent=user.Backpack;
	script.Parent=tool;
tool.Selected:connect(selected);
tool.Deselected:connect(deselected);

mouse.KeyDown:connect(function(key)
	keys[key]=true;
end);

mouse.KeyUp:connect(function(key)
	keys[key]=false;
end);
