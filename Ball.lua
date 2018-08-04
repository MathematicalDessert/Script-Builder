wait(0.001);

--------------------------------------------------------------------------------------------------------------

_ray=function(v0,v1,i)
	local mag=(v0-v1).magnitude;
	local ray=Ray.new(v0,(v1-v0).unit*(mag>999 and 999 or mag));
	
	return(type(i)=='table'and workspace.FindPartOnRayWithIgnoreList or workspace.FindPartOnRay)(workspace,ray,i);
end;

--------------------------------------------------------------------------------------------------------------

user=game:service'Players'.LocalPlayer;
backpack=user.Backpack;
mouse=user:GetMouse();
char=user.Character;
torso=char.Torso;
head=char.Head;

hum=char:findFirstChild'Humanoid';
if(not hum or hum.className~='Humanoid')then
	hum=char:children();
	for i=1,#hum do
		if(hum[i].className=='Humanoid')then
			hum=hum[i];
			break;
		end;
	end;
end;

--------------------------------------------------------------------------------------------------------------

repeat until not pcall(function()
	char.ala_ball:Destroy();
	hum.PlatformStand=false;
end);

repeat until not pcall(function()
	backpack.ala_ball:Destroy();
	hum.PlatformStand=false;
end);

--------------------------------------------------------------------------------------------------------------

keys={};

--------------------------------------------------------------------------------------------------------------

bin=Instance.new('HopperBin',backpack);
	bin.Name='Ball';
	script.Parent=bin;
	bin.Selected:connect(function()
		ball=Instance.new'Part';
			ball.Shape=0;
			ball.Friction=10;
			ball.Elasticity=0;
			ball.TopSurface=0;
			ball.formFactor=0;
			ball.BottomSurface=0;
			ball.Transparency=0.5;
			ball.CanCollide=true;
			ball.Color=torso.Color;
			ball.CFrame=head.CFrame;
			ball.Name='Ball';
			ball.Size=Vector3.new(10,10,10);
			ball.Parent=char;
		local weld=Instance.new('Weld',ball);
			weld.Part0=ball;
			weld.Part1=head;
		
		wait(0.001);
		
		hum.PlatformStand=true;
		ball.CanCollide=true;
	end);
	bin.Deselected:connect(function()
		ball:Destroy();
		ball=nil;
		hum.PlatformStand=false;
	end);
	
mouse.KeyDown:connect(function(key)
	keys[key]=true;
end);
	
mouse.KeyUp:connect(function(key)
	keys[key]=false;
end);

hum.Changed:connect(function(p)
	if(p=='PlatformStand'and ball)then
		hum.PlatformStand=true;
	end;
end);

hum.Died:connect(function()
	ball:Destroy();
	ball=nil;
	bin:Destroy();
end);

local jump_time=time();

game:service'RunService'.Stepped:connect(function()
	if(ball and ball.Parent)then
		if(keys[' ']and jump_time<=time())then
			local hit,pos=_ray(ball.Position-Vector3.new(0,3,0),ball.Position-Vector3.new(0,6,0),char);
			if(hit and hit.CanCollide)then
				jump_time=time()+1;
				ball.Velocity=ball.Velocity+Vector3.new(0,100,0);
			end;
		end;
		if(keys.w or keys.s or keys.a or keys.d and ball.Velocity.magnitude<30)then
			local v=((CFrame.Angles(0,math.rad(90),0)*workspace.CurrentCamera.CoordinateFrame).lookVector*Vector3.new(1,0,1)).unit;
			local speed=ball.Velocity.magnitude;
				speed=speed>30 and 30 or speed;
				v=v+v*speed;
			
			if(keys.s)then
				v=v*-1;
			end;
		
			if(keys.d)then
				v=v+workspace.CurrentCamera.CoordinateFrame.lookVector*speed;
			end;
			
			if(keys.a)then
				v=v-workspace.CurrentCamera.CoordinateFrame.lookVector*speed;
			end;
			
			ball.RotVelocity=v;
		end;
	end;
end);
