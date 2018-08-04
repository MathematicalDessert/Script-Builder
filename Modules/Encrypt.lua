local Crypt = {}

function Crypt:Encode(Key, SKey, String)
if not inv256 then
  inv256 = {}
  for M = 0, 127 do
    local inv = -1
    repeat inv = inv + 2
    until inv * (2*M + 1) % 256 == 1
    inv256[M] = inv
  end
end
local K, F = Key, 16384 + SKey
return (String:gsub('.',
  function(m)
    local L = K % 274877906944  -- 2^38
    local H = (K - L) / 274877906944
    local M = H % 128
    m = m:byte()
    local c = (m * inv256[M] - (H - M) / 128) % 256
    K = L * F + H + c + m
    return ('%02x'):format(c)
  end
))
end

function Crypt:Decode(Key, SKey, String)
local K, F = Key, 16384 + SKey
return (String:gsub('%x%x',
  function(c)
    local L = K % 274877906944  -- 2^38
    local H = (K - L) / 274877906944
    local M = H % 128
    c = tonumber(c, 16)
    local m = (c + (H - M) / 128) * (2*M + 1) % 256
    K = L * F + H + c + m
    return string.char(m)
  end
))
end

return Crypt
