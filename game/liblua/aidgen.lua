-- 同guidgen一样算法,用来混淆联盟id
local prime = 253280021 --
local inverse = 1485740093
local modulo = 0x7FFFFFF --2^n -1 这里使用0x7FFFFFF以控制初始值在9位数(十进制)内
local mask = 0x8000000 --使用掩码二进制最高位补上1,保证结果都是9位数

local aidgen = {}
function aidgen.encode(id)
    return (id * prime) & modulo ~ mask
end

function aidgen.decode( code)
    return ( (code~ mask) * inverse ) & modulo
end

return aidgen
