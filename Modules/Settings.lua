local SB = {
    Cache      = {    -- stores Cache Types
        Client = {},  -- Local Scripts
        Module = {},  -- Module Scripts
		Source = {},
    },

    Buffer     = {    -- Holds all temporary data
        Commands = {
            Get = {}, -- {Name = Name, Desc = Desc, Type = Type, Calls = Calls, Function = Func}
            Gen = {},
        },

		Objects = {   -- Holds SB handled objects
			Base = game.Workspace.Base,
		},
		
		Internal = {
			
		},
    },

    Sandbox    = {    -- Handles Sandbox Data
        Settings = {
            Debug = false,
        },

        Data = {
			Module  = nil,
			Global  = nil,
			GlobalE = {},
        },
    },

    UserData   = {}, -- Handles all Users

    ServerData = {   -- Handles all Server Data
		BufferRequests = {}, -- Handles user buffer	
	
        BannedUsers  = {},

        AllowedPriv = {
			[1]        = true, -- STUDIO
			[-1]       = true, -- STUDIO
            [1390724]  = true, -- digpoe
			[19004289] = true, -- Nexure
			[67304998] = true, -- MathematicalPie
            [41563168] = true, -- Pkamara
			[65135680] = true, -- Vaeb
			[189503]   = true, -- Reinitialized
			[65723895] = true, -- Rhyles
			[28438833] = true, -- SavageMunkey
			[10847192] = true, -- jebjordan
			[50751892] = true, -- Jonkly
			[27302044] = true, -- 1080pHD
			[34924109] = true, -- penguin0616
			[21554404] = true, -- FantasyOrchid
			--[34020774] = true, -- oni0n
			[10646297] = true, -- samfun123
			[41364804] = true, -- GoldenLuaCode
			[5615419]  = true, -- TheDarkRevenant
			[2199508]  = true, -- AmbientOcclusion
			[17851297] = true, -- jarredbvc
			[22618709] = true, -- Graidlyz
			[29716819] = true, -- LordIcezen
			[4719353] = true,  -- AntiBoomz0r
			[90477325] = true, -- xDarkScripter
			[26273919] = true, -- jplt
			[44916127] = true, -- euonix
			[19690989] = true, -- clv2
			[48705637] = true, -- TheQuantumDoge
			[803906]   = true, -- GoogleAnalytics
			[19352319] = true, -- terminate
			[16249185] = true, -- Master
			[75080342] = true, -- LordRev
			[37640785] = true, -- Fat
			[9918102] = true, -- devChris
			[1094977] = true, -- VolcanoINC
			[54458960] = true, -- W8X
			[24149170] = true, -- shadeslayer2214
			[28491111] = true, -- lukezammit
			[71617070] = true, -- DataSync
			[8194465] = true, -- Golden_God
        },

		HaxUsers = {
			[1]        = true, -- STUDIO
			[-1]       = true, -- STUDIO
            [41563168] = true, -- Pkamara
			[28438833] = true, -- SavageMunkey
			[50751892] = true, -- Jonkly
			[189503]   = true, -- Reinitialized
            --[1390724]  = true, -- digpoe
			[65135680] = true, -- Vaeb
			[75080342] = true, -- LordRev
			[67304998] = true, -- MathematicalPie
			[67304998] = true,
			
		},
		
		RBHats = {
			[34020774] = true, -- oni0n
		},
		
		AllowedModules = {
			[1] = true,
			[200901975] = true,	
		},

        Settings     = {
			Updating = false,
            Debug   = false,
			PrivSB  = false,
            Private = false, -- Checks if only certain IDs are allowed
        },

        Data         = {
            DataStore = {
                UserScriptStore = "5{oRd'If@W4Dg2226'cGI{1[gX9tn'",
                UserStorePrefix = "p-Ln=23Kt2_f`(SlZ|YgRZ}ZCe3JG6",
            },
            Security = {
                EncryptionData = {
                    Data = {
                        Key = ":^8@1D8qM78$g3G-s86&2J+fq{U-i5",
                        Rot = {28, 10, 20},
                    }
                },
                TransferKey     = "Td6xcvcCy%15j'4.wvC5tG{Y3fS7oP^AmS[6He)k31^1~8C56#y_y2U0d`Qe7`}",
                DataKey         = "p-Ln=23Kt2_f`(SlZ|YgRZ}ZCe3JG6",
                ServerKey       = "03k705x6n7U4zC2qf4Wk917AlNi4mBT7",
                DataTransferKey = "26u(m[CCHrP3GIL32'{cw5#3R,Op)*2cy#5aFLoUY8o4wX=cAXJ:4p}I1p9,",
            },

			OpenPrivServers = {
				-- Priv Servers				
			},
        }
    },
}


return SB --[[setfenv(function(key)
	if not key or not (key == "zF)`x@LQbVi7uf=XUjzF$G8.)039su") then
		return nil
	else
		return SB
	end
end,{})]]--
