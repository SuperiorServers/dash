if (SERVER) and file.Exists('lua/bin/gmsv_hash_' .. (system.IsWindows() and 'win32' or 'linux') .. '.dll', 'MOD') then -- Use gm_hash if we have it since it's a faster https://github.com/SuperiorServers/gm_hash
	_require 'hash'
	return
end

hash = {}

-- MD5 modified from https://github.com/kikito/md5.lua
do
	local char, byte, format, rep, sub = string.char, string.byte, string.format, string.rep, string.sub
	local bit_or, bit_and, bit_not, bit_xor, bit_rshift, bit_lshift = bit.bor, bit.band, bit.bnot, bit.bxor, bit.rshift, bit.lshift

	-- convert little-endian 32-bit int to a 4-char string
	local function lei2str(i)
	  local f=function (s) return char( bit_and( bit_rshift(i, s), 255)) end
	  return f(0)..f(8)..f(16)..f(24)
	end

	-- convert raw string to big-endian int
	local function str2bei(s)
	  local v=0
	  for i=1, #s do
	    v = v * 256 + byte(s, i)
	  end
	  return v
	end

	-- convert raw string to little-endian int
	local function str2lei(s)
	  local v=0
	  for i = #s,1,-1 do
	    v = v*256 + byte(s, i)
	  end
	  return v
	end

	-- cut up a string in little-endian ints of given size
	local function cut_le_str(s,...)
	  local o, r = 1, {}
	  local args = {...}
	  for i=1, #args do
	    table.insert(r, str2lei(sub(s, o, o + args[i] - 1)))
	    o = o + args[i]
	  end
	  return r
	end

	local swap = function (w) return str2bei(lei2str(w)) end

	-- An MD5 mplementation in Lua, requires bitlib (hacked to use LuaBit from above, ugh)
	-- 10/02/2001 jcw@equi4.com

	local CONSTS = {
	  0xd76aa478, 0xe8c7b756, 0x242070db, 0xc1bdceee,
	  0xf57c0faf, 0x4787c62a, 0xa8304613, 0xfd469501,
	  0x698098d8, 0x8b44f7af, 0xffff5bb1, 0x895cd7be,
	  0x6b901122, 0xfd987193, 0xa679438e, 0x49b40821,
	  0xf61e2562, 0xc040b340, 0x265e5a51, 0xe9b6c7aa,
	  0xd62f105d, 0x02441453, 0xd8a1e681, 0xe7d3fbc8,
	  0x21e1cde6, 0xc33707d6, 0xf4d50d87, 0x455a14ed,
	  0xa9e3e905, 0xfcefa3f8, 0x676f02d9, 0x8d2a4c8a,
	  0xfffa3942, 0x8771f681, 0x6d9d6122, 0xfde5380c,
	  0xa4beea44, 0x4bdecfa9, 0xf6bb4b60, 0xbebfbc70,
	  0x289b7ec6, 0xeaa127fa, 0xd4ef3085, 0x04881d05,
	  0xd9d4d039, 0xe6db99e5, 0x1fa27cf8, 0xc4ac5665,
	  0xf4292244, 0x432aff97, 0xab9423a7, 0xfc93a039,
	  0x655b59c3, 0x8f0ccc92, 0xffeff47d, 0x85845dd1,
	  0x6fa87e4f, 0xfe2ce6e0, 0xa3014314, 0x4e0811a1,
	  0xf7537e82, 0xbd3af235, 0x2ad7d2bb, 0xeb86d391,
	  0x67452301, 0xefcdab89, 0x98badcfe, 0x10325476
	}

	local f=function (x,y,z) return bit_or(bit_and(x,y),bit_and(-x-1,z)) end
	local g=function (x,y,z) return bit_or(bit_and(x,z),bit_and(y,-z-1)) end
	local h=function (x,y,z) return bit_xor(x,bit_xor(y,z)) end
	local i=function (x,y,z) return bit_xor(y,bit_or(x,-z-1)) end
	local z=function (f,a,b,c,d,x,s,ac)
	  a=bit_and(a+f(b,c,d)+x+ac,0xFFFFFFFF)
	  -- be *very* careful that left shift does not cause rounding!
	  return bit_or(bit_lshift(bit_and(a,bit_rshift(0xFFFFFFFF,s)),s),bit_rshift(a,32-s))+b
	end

	local function transform(A,B,C,D,X)
	  local a,b,c,d=A,B,C,D
	  local t=CONSTS

	  a=z(f,a,b,c,d,X[ 0], 7,t[ 1])
	  d=z(f,d,a,b,c,X[ 1],12,t[ 2])
	  c=z(f,c,d,a,b,X[ 2],17,t[ 3])
	  b=z(f,b,c,d,a,X[ 3],22,t[ 4])
	  a=z(f,a,b,c,d,X[ 4], 7,t[ 5])
	  d=z(f,d,a,b,c,X[ 5],12,t[ 6])
	  c=z(f,c,d,a,b,X[ 6],17,t[ 7])
	  b=z(f,b,c,d,a,X[ 7],22,t[ 8])
	  a=z(f,a,b,c,d,X[ 8], 7,t[ 9])
	  d=z(f,d,a,b,c,X[ 9],12,t[10])
	  c=z(f,c,d,a,b,X[10],17,t[11])
	  b=z(f,b,c,d,a,X[11],22,t[12])
	  a=z(f,a,b,c,d,X[12], 7,t[13])
	  d=z(f,d,a,b,c,X[13],12,t[14])
	  c=z(f,c,d,a,b,X[14],17,t[15])
	  b=z(f,b,c,d,a,X[15],22,t[16])

	  a=z(g,a,b,c,d,X[ 1], 5,t[17])
	  d=z(g,d,a,b,c,X[ 6], 9,t[18])
	  c=z(g,c,d,a,b,X[11],14,t[19])
	  b=z(g,b,c,d,a,X[ 0],20,t[20])
	  a=z(g,a,b,c,d,X[ 5], 5,t[21])
	  d=z(g,d,a,b,c,X[10], 9,t[22])
	  c=z(g,c,d,a,b,X[15],14,t[23])
	  b=z(g,b,c,d,a,X[ 4],20,t[24])
	  a=z(g,a,b,c,d,X[ 9], 5,t[25])
	  d=z(g,d,a,b,c,X[14], 9,t[26])
	  c=z(g,c,d,a,b,X[ 3],14,t[27])
	  b=z(g,b,c,d,a,X[ 8],20,t[28])
	  a=z(g,a,b,c,d,X[13], 5,t[29])
	  d=z(g,d,a,b,c,X[ 2], 9,t[30])
	  c=z(g,c,d,a,b,X[ 7],14,t[31])
	  b=z(g,b,c,d,a,X[12],20,t[32])

	  a=z(h,a,b,c,d,X[ 5], 4,t[33])
	  d=z(h,d,a,b,c,X[ 8],11,t[34])
	  c=z(h,c,d,a,b,X[11],16,t[35])
	  b=z(h,b,c,d,a,X[14],23,t[36])
	  a=z(h,a,b,c,d,X[ 1], 4,t[37])
	  d=z(h,d,a,b,c,X[ 4],11,t[38])
	  c=z(h,c,d,a,b,X[ 7],16,t[39])
	  b=z(h,b,c,d,a,X[10],23,t[40])
	  a=z(h,a,b,c,d,X[13], 4,t[41])
	  d=z(h,d,a,b,c,X[ 0],11,t[42])
	  c=z(h,c,d,a,b,X[ 3],16,t[43])
	  b=z(h,b,c,d,a,X[ 6],23,t[44])
	  a=z(h,a,b,c,d,X[ 9], 4,t[45])
	  d=z(h,d,a,b,c,X[12],11,t[46])
	  c=z(h,c,d,a,b,X[15],16,t[47])
	  b=z(h,b,c,d,a,X[ 2],23,t[48])

	  a=z(i,a,b,c,d,X[ 0], 6,t[49])
	  d=z(i,d,a,b,c,X[ 7],10,t[50])
	  c=z(i,c,d,a,b,X[14],15,t[51])
	  b=z(i,b,c,d,a,X[ 5],21,t[52])
	  a=z(i,a,b,c,d,X[12], 6,t[53])
	  d=z(i,d,a,b,c,X[ 3],10,t[54])
	  c=z(i,c,d,a,b,X[10],15,t[55])
	  b=z(i,b,c,d,a,X[ 1],21,t[56])
	  a=z(i,a,b,c,d,X[ 8], 6,t[57])
	  d=z(i,d,a,b,c,X[15],10,t[58])
	  c=z(i,c,d,a,b,X[ 6],15,t[59])
	  b=z(i,b,c,d,a,X[13],21,t[60])
	  a=z(i,a,b,c,d,X[ 4], 6,t[61])
	  d=z(i,d,a,b,c,X[11],10,t[62])
	  c=z(i,c,d,a,b,X[ 2],15,t[63])
	  b=z(i,b,c,d,a,X[ 9],21,t[64])

	  return A+a,B+b,C+c,D+d
	end

	function hash.MD5(s)
	  local msgLen = #s
	  local padLen = 56 - msgLen % 64

	  if msgLen % 64 > 56 then padLen = padLen + 64 end

	  if padLen == 0 then padLen = 64 end

	  s = s .. char(128) .. rep(char(0),padLen-1) .. lei2str(8*msgLen) .. lei2str(0)
	  local t = CONSTS
	  local a,b,c,d = t[65],t[66],t[67],t[68]

	  for i=1,#s,64 do
	    local X = cut_le_str(sub(s,i,i+63),4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4)
	    X[0] = table.remove(X,1) -- zero based!
	    a,b,c,d = transform(a,b,c,d,X)
	  end

	  return format("%08x%08x%08x%08x",swap(a),swap(b),swap(c),swap(d))
	end
end


-- SHA2 modified from http://lua-users.org/wiki/SecureHashAlgorithm
do
	local bit_band 		= bit.band
	local bit_ror     = bit.ror
	local bit_bxor 		= bit.bxor
	local bit_rshift 	= bit.rshift
	local bit_bnot		= bit.bnot

	local string_gsub 	= string.gsub
	local string_format = string.format
	local string_byte 	= string.byte
	local string_char   = string.char
	local string_rep	= string.rep


	local k = {
		0x428a2f98, 0x71374491, 0xb5c0fbcf, 0xe9b5dba5,
		0x3956c25b, 0x59f111f1, 0x923f82a4, 0xab1c5ed5,
		0xd807aa98, 0x12835b01, 0x243185be, 0x550c7dc3,
		0x72be5d74, 0x80deb1fe, 0x9bdc06a7, 0xc19bf174,
		0xe49b69c1, 0xefbe4786, 0x0fc19dc6, 0x240ca1cc,
		0x2de92c6f, 0x4a7484aa, 0x5cb0a9dc, 0x76f988da,
		0x983e5152, 0xa831c66d, 0xb00327c8, 0xbf597fc7,
		0xc6e00bf3, 0xd5a79147, 0x06ca6351, 0x14292967,
		0x27b70a85, 0x2e1b2138, 0x4d2c6dfc, 0x53380d13,
		0x650a7354, 0x766a0abb, 0x81c2c92e, 0x92722c85,
		0xa2bfe8a1, 0xa81a664b, 0xc24b8b70, 0xc76c51a3,
		0xd192e819, 0xd6990624, 0xf40e3585, 0x106aa070,
		0x19a4c116, 0x1e376c08, 0x2748774c, 0x34b0bcb5,
		0x391c0cb3, 0x4ed8aa4a, 0x5b9cca4f, 0x682e6ff3,
		0x748f82ee, 0x78a5636f, 0x84c87814, 0x8cc70208,
		0x90befffa, 0xa4506ceb, 0xbef9a3f7, 0xc67178f2,
	}

	local function str2hexa (s)
		return string_gsub(s, ".", function(c)
			return string_format("%02x", string_byte(c))
		end)
	end

	local function num2s (l, n)
		local s = ""
		for i = 1, n do
			local rem = l % 256
			s = string_char(rem) .. s
			l = (l - rem) / 256
		end
		return s
	end

	local function s232num (s, i)
		local n = 0
		for i = i, i + 3 do
			n = n*256 + string_byte(s, i)
		end
		return n
	end

	local function preproc (msg, len)
		local extra = -(len + 1 + 8) % 64
		len = num2s(8 * len, 8)
		msg = msg .. "\128" .. string_rep("\0", extra) .. len
		return msg
	end

	local function initH256 (H)
		H[1] = 0x6a09e667
		H[2] = 0xbb67ae85
		H[3] = 0x3c6ef372
		H[4] = 0xa54ff53a
		H[5] = 0x510e527f
		H[6] = 0x9b05688c
		H[7] = 0x1f83d9ab
		H[8] = 0x5be0cd19
		return H
	end

	local function digestblock (msg, i, H)
		local w = {}
		for j = 1, 16 do
			w[j] = s232num(msg, i + (j - 1)*4)
		end

		for j = 17, 64 do
			local v = w[j - 15]
			local s0 = bit_bxor(bit_ror(v, 7), bit_ror(v, 18), bit_rshift(v, 3))
			v = w[j - 2]
			local s1 = bit_bxor(bit_ror(v, 17), bit_ror(v, 19), bit_rshift(v, 10))
			w[j] = w[j - 16] + s0 + w[j - 7] + s1
		end

		local a, b, c, d, e, f, g, h = H[1], H[2], H[3], H[4], H[5], H[6], H[7], H[8]

		for i = 1, 64 do
			local s0 = bit_bxor(bit_ror(a, 2), bit_ror(a, 13), bit_ror(a, 22))
			local maj = bit_bxor(bit_band(a, b), bit_band(a, c), bit_band(b, c))
			local t2 = s0 + maj
			local s1 = bit_bxor(bit_ror(e, 6), bit_ror(e, 11), bit_ror(e, 25))
			local ch = bit_bxor (bit_band(e, f), bit_band(bit_bnot(e), g))
			local t1 = h + s1 + ch + k[i] + w[i]

			h = g
			g = f
			f = e
			e = d + t1
			d = c
			c = b
			b = a
			a = t1 + t2
		end

		H[1] = bit_band(H[1] + a)
		H[2] = bit_band(H[2] + b)
		H[3] = bit_band(H[3] + c)
		H[4] = bit_band(H[4] + d)
		H[5] = bit_band(H[5] + e)
		H[6] = bit_band(H[6] + f)
		H[7] = bit_band(H[7] + g)
		H[8] = bit_band(H[8] + h)
	end

	local HH = {}
	function hash.SHA256(msg)
		msg = preproc(msg, #msg)
		local H = initH256(HH)
		for i = 1, #msg, 64 do
			digestblock(msg, i, H)
		end

		return str2hexa(num2s(H[1], 4)..num2s(H[2], 4)..num2s(H[3], 4)..num2s(H[4], 4)..num2s(H[5], 4)..num2s(H[6], 4)..num2s(H[7], 4)..num2s(H[8], 4))
	end
end

do
	local band = bit.band
	local bnot = bit.bnot
	local bor = bit.bor
	local bxor = bit.bxor
	local floor = math.floor

	// The four core functions - F1 is optimized somewhat
	// local function f1(x, y, z) bit.bor(bit.band(x, y), bit.band( bit.bnot( x), z)) end
	local function f1(x, y, z) return bxor( z, band( x, bxor( y, z))) end
	local function f2(x, y, z) return bxor( y, band( z, bxor( x, y))) end
	local function f3(x, y, z) return bxor(bxor( x, y), z) end
	local function f4(x, y, z) return bxor( y, bor( x, bnot( z))) end

	// This is the central step in the MD5 algorithm.
	local function Step(func, w, x, y, z, flData, iStep)
		w = w + func(x, y, z) + flData

		return bor((w * 2^iStep) % 0x100000000, floor(w % 0x100000000 / 2^(0x20 - iStep))) + x
	end

	-- This is called every tick so it has to be super optimised
	function hash.PseudoRandom(nSeed)
		nSeed = nSeed % 0x100000000

		local a = Step(f1, 0x67452301, 0xefcdab89, 0x98badcfe, 0x10325476, nSeed + 0xd76aa478, 7)
		local d = Step(f1, 0x10325476, a, 0xefcdab89, 0x98badcfe, 0xe8c7b7d6, 12)
		local c = Step(f1, 0x98badcfe, d, a, 0xefcdab89, 0x242070db, 17)
		local b = Step(f1, 0xefcdab89, c, d, a, 0xc1bdceee, 22)
		a = Step(f1, a, b, c, d, 0xf57c0faf, 7)
		d = Step(f1, d, a, b, c, 0x4787c62a, 12)
		c = Step(f1, c, d, a, b, 0xa8304613, 17)
		b = Step(f1, b, c, d, a, 0xfd469501, 22)
		a = Step(f1, a, b, c, d, 0x698098d8, 7)
		d = Step(f1, d, a, b, c, 0x8b44f7af, 12)
		c = Step(f1, c, d, a, b, 0xffff5bb1, 17)
		b = Step(f1, b, c, d, a, 0x895cd7be, 22)
		a = Step(f1, a, b, c, d, 0x6b901122, 7)
		d = Step(f1, d, a, b, c, 0xfd987193, 12)
		c = Step(f1, c, d, a, b, 0xa67943ae, 17)
		b = Step(f1, b, c, d, a, 0x49b40821, 22)

		a = Step(f2, a, b, c, d, 0xf61e25e2, 5)
		d = Step(f2, d, a, b, c, 0xc040b340, 9)
		c = Step(f2, c, d, a, b, 0x265e5a51, 14)
		b = Step(f2, b, c, d, a, nSeed + 0xe9b6c7aa, 20)
		a = Step(f2, a, b, c, d, 0xd62f105d, 5)
		d = Step(f2, d, a, b, c, 0x02441453, 9)
		c = Step(f2, c, d, a, b, 0xd8a1e681, 14)
		b = Step(f2, b, c, d, a, 0xe7d3fbc8, 20)
		a = Step(f2, a, b, c, d, 0x21e1cde6, 5)
		d = Step(f2, d, a, b, c, 0xc33707f6, 9)
		c = Step(f2, c, d, a, b, 0xf4d50d87, 14)
		b = Step(f2, b, c, d, a, 0x455a14ed, 20)
		a = Step(f2, a, b, c, d, 0xa9e3e905, 5)
		d = Step(f2, d, a, b, c, 0xfcefa3f8, 9)
		c = Step(f2, c, d, a, b, 0x676f02d9, 14)
		b = Step(f2, b, c, d, a, 0x8d2a4c8a, 20)

		a = Step(f3, a, b, c, d, 0xfffa3942, 4)
		d = Step(f3, d, a, b, c, 0x8771f681, 11)
		c = Step(f3, c, d, a, b, 0x6d9d6122, 16)
		b = Step(f3, b, c, d, a, 0xfde5382c, 23)
		a = Step(f3, a, b, c, d, 0xa4beeac4, 4)
		d = Step(f3, d, a, b, c, 0x4bdecfa9, 11)
		c = Step(f3, c, d, a, b, 0xf6bb4b60, 16)
		b = Step(f3, b, c, d, a, 0xbebfbc70, 23)
		a = Step(f3, a, b, c, d, 0x289b7ec6, 4)
		d = Step(f3, d, a, b, c, nSeed + 0xeaa127fa, 11)
		c = Step(f3, c, d, a, b, 0xd4ef3085, 16)
		b = Step(f3, b, c, d, a, 0x04881d05, 23)
		a = Step(f3, a, b, c, d, 0xd9d4d039, 4)
		d = Step(f3, d, a, b, c, 0xe6db99e5, 11)
		c = Step(f3, c, d, a, b, 0x1fa27cf8, 16)
		b = Step(f3, b, c, d, a, 0xc4ac5665, 23)

		a = Step(f4, a, b, c, d, nSeed + 0xf4292244, 6)
		d = Step(f4, d, a, b, c, 0x432aff97, 10)
		c = Step(f4, c, d, a, b, 0xab9423c7, 15)
		b = Step(f4, b, c, d, a, 0xfc93a039, 21)
		a = Step(f4, a, b, c, d, 0x655b59c3, 6)
		d = Step(f4, d, a, b, c, 0x8f0ccc92, 10)
		c = Step(f4, c, d, a, b, 0xffeff47d, 15)
		b = Step(f4, b, c, d, a, 0x85845e51, 21)
		a = Step(f4, a, b, c, d, 0x6fa87e4f, 6)
		d = Step(f4, d, a, b, c, 0xfe2ce6e0, 10)
		c = Step(f4, c, d, a, b, 0xa3014314, 15)
		b = Step(f4, b, c, d, a, 0x4e0811a1, 21)
		a = Step(f4, a, b, c, d, 0xf7537e82, 6)
		d = Step(f4, d, a, b, c, 0xbd3af235, 10)
		c = (0x98badcfe + Step(f4, c, d, a, b, 0x2ad7d2bb, 15)) % 0x100000000
		b = (0xefcdab89 + Step(f4, b, c, d, a, 0xeb86d391, 21)) % 0x100000000

		return floor(b / 0x10000) % 0x100 + floor(b / 0x1000000) % 0x100 * 0x100 + c % 0x100 * 0x10000 + floor( c / 0x100) % 0x100 * 0x1000000
	end
end
