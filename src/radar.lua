-- Liberty Radar: circular enemy radar for Helldivers 2 (Bingus Shared Loader addon)
if rawget(_G, 'LibertyRadarProbe') then return end
local state = { version = '1.1.0', status = 'starting', runs = 0, done = false }
rawset(_G, 'LibertyRadarProbe', state)
local loader = rawget(_G, 'CowboyBingusModLoader')
local log
if type(loader) == 'table' and type(loader.open_log) == 'function' then
    pcall(function() log = loader.open_log('LibertyRadarProbe.log') end)
end
local function say(fmt, ...)
    if not log then return end
    local okf, line = pcall(string.format, fmt, ...)
    if not okf then line = 'FORMAT_ERR:' .. tostring(fmt) end
    pcall(function()
        log:write(os.date('%H:%M:%S '), line, '\n')
        log:flush()
    end)
end

local STRUCTURES = {
    ['8901f188db366b4b'] = 'hole_a', ['9b58c95349d051f9'] = 'hole_b',
    ['8c31b749759cbd61'] = 'hole_c', ['36cc8ead2bb18d78'] = 'hole_d',
    ['bc2af8548c6d5e06'] = 'hole_e', ['f78bf0ff5c62140d'] = 'hole_f',
    ['97dd3178e9f0ab70'] = 'hole_g', ['4776a1cf3f19a13b'] = 'hole_h',
    ['3a2cef12ed32a088'] = 'hole_bile_titan',
    ['095686275a113614'] = 'tower_a', ['aa28caf964d05500'] = 'tower_b',
    ['e02e6bd34b606a85'] = 'tower_c', ['06d3c4720e642fc1'] = 'egg',
}
local CATALOG = {
    ['1a7fcdff98c664b0'] = 'Charger', ['3aff5fd7d5450b99'] = 'ChargerBehemoth',
    ['6b202392f4ab605e'] = 'SporeCharger', ['960b48a421a3faaa'] = 'Dragonroach',
    ['9e2e17f2ccccafdd'] = 'BileTitan', ['a05bd1ec67b3ac4c'] = 'ChargerBehemoth',
    ['dcf8e74212fbee3b'] = 'Impaler', ['ef04cb84d097a497'] = 'BileTitan',
    ['fd5247653c897803'] = 'ChargerBehemoth',
}
local AVATAR_RESOURCE = '\151\250\077\041\077\051\028\077'
-- hex64 form of AVATAR_RESOURCE: the health walk stores res as a
-- hex string, and every squad member's avatar shares this hash -
-- excluded so merged health enemies never draw dots on players
local AVATAR_HEX = '4d1c334d294dfa97'
local seen_res = {}

-- friendlies that hold an AiEnemy/Targeting record but are never enemies
-- (SEAF, sentries, drones, vehicles, props, wrecks) - from High Alert 1.9.0
local FRIENDLY_HASHES = {
    '019544309fac4508', '021eaecf4ca267dc', '04c99523a808ef90', '050a141871a97091', '07abc11f4596a788',
    '0bce5532d5d5e3eb', '0e37a0fa0a978620', '111beed56922bf4c', '11332832c10681bc', '1312b769f47256d9',
    '14453b8fcb040099', '1d42a8677882f1cd', '1db272dda55199e0', '1e592fe6daed807f', '1ead9f7191bfc50a',
    '299c0d3dfd2f0994', '2b6b66449798def2', '2d398d1ec35e0838', '341af8820251a624', '353c5d1070126899',
    '37079568dc86e9c6', '37bacd53809f3a77', '37cde43876ba26bb', '3cb772e481dbe9f8', '44d72a2c4d5f0507',
    '4676bd9a16d3ac28', '491e961533affc15', '4abcf54464695efa', '4b071633584e4594', '4d19a06b81fa744a',
    '4df41f84668d07fb', '4e69b56270226250', '51a0812e3bce2d74', '526a3c003f2ea8dd', '548136f66f5c9b5c',
    '54d86057f5dacfb9', '56070f36cfffa8a8', '5beec97f4c7f4ae9', '5ca062d2fa1f76b9', '5cf84155e60c6e4d',
    '61efb2d6a167f285', '674fb0849f8a1140', '688949109126ece4', '68a34d32a1025f04', '694c059e2bab805e',
    '6b09879e8677752d', '6b22ae8e5f669d4f', '6fb1e73e00a84329', '73681ffd58fa1a90', '74599e56f72f9d7e',
    '75f7e96af7dcd303', '776a8fd06099e43c', '78dabc7344e50234', '7956c174e9faefe0', '79eb2092ebe7cddc',
    '7ff0fd4572f5996f', '820cc3bafe962858', '8365609b35ef6672', '840590f468d65a1b', '847a06ca8885c6ab',
    '84e683468c0bca1a', '8633ff89ef4f6788', '8661ca5cf58d8162', '87f46b6d12bb016a', '8d435a5c9a304215',
    '8e325c933e55bf62', '9402b0fc52136a70', '9579d47b23904246', '979e9bc6d48d1fc6', '9cc8c7ae4cedb109',
    '9d90f5cd1a00a353', 'a00331f24deef2ee', 'a0ff2f9a0ca6992a', 'a1bdb3a13e3633dd', 'a45cfd1c3607eec8',
    'a6b6c68624ab47ec', 'a6dcc225e1263606', 'a8d4030e707a49b4', 'aa4564f90cdbf5f1', 'b2053a1838092f8b',
    'b9baf571fc8f9959', 'bc650c081eab0735', 'bcfc57848f206106', 'bfb5c88d557595d8', 'c2d93163fdbb14a1',
    'c30b36e82086d814', 'c47287d738be91c3', 'c734373e4b3e1df7', 'cc16ff3a5eeb6d83', 'cdca29c351ea71d8',
    'd25291cb6bbeae8b', 'd4d4eae659bc671c', 'd5a6aba03479cfb8', 'd87d04aacbc0269c', 'd9c51b722b223bc4',
    'd9e5d03ff013187f', 'db6676e595797e8a', 'dc0b7c25253a8255', 'e515a723de95dc3d', 'e9b891f3eaa0d606',
    'ef85d6cf58e31d70', 'f800d5f62789246c', 'f903a153f47ad10f', 'f9d5219640d65ef9', 'fa75f8dcbffba877',
}
local FRIENDLY_SET = {}
-- 1.0.28: health-merge junk from the 1.0.27 client test (RESEARCH
-- 11.26). High Alert's list never saw what only the health table
-- holds: fuel barrels and Super Earth faction props. Faction 'se'
-- is never an enemy, so these are safe kills.
table.insert(FRIENDLY_HASHES, 'add299f56916ae1f') -- habs_barrel_fuel
table.insert(FRIENDLY_HASHES, '27bb558c893383cc') -- se faction
table.insert(FRIENDLY_HASHES, '75be82ed8592a6b3') -- se faction
table.insert(FRIENDLY_HASHES, '9d4f7cb4eb34515d') -- se faction
table.insert(FRIENDLY_HASHES, 'a9982969137f3d77') -- se faction
table.insert(FRIENDLY_HASHES, 'e44b691dc039a505') -- se faction
for _, h in ipairs(FRIENDLY_HASHES) do FRIENDLY_SET[h] = true end

-- heavy enemies: hash set curated from the APW + shalzuth + Enemy HP
-- HUD+ name-table union. Unknown hashes render small/yellow; the
-- per-session 'NEW res' log grows coverage after game updates.
local HEAVY_HASHES = {
    '0ab7b92b131c228c', '137988cea16458f7', '16023e554fee830e',
    '17c5d12d8d5dee2c', '1897bdd32105d2dc', '1a7fcdff98c664b0',
    '1c6981ca2fb69508', '1e66ee1f6f7fd00e', '30f2dee2333f227a',
    '31bae74d2f064d8d', '32cdeada234fb8df', '36390775d61159eb',
    '390e6b3d2f26bd70', '3aafba89b53b0f63', '3aff5fd7d5450b99',
    '3e0537d606438fea', '48c91e42b9f16512', '49674794a165eda8',
    '4e342031a9d5c4f9', '51c6132ec1d10e7e', '53d8919d7b8abd67',
    '5b596a4d21bc91a3', '5d142c3a73ebc634', '63df3d07b7424588',
    '6a7a54d5fb3a6d17', '6b202392f4ab605e', '6dab2eadf5d8b692',
    '7acb4bd753b71de0', '8372619b2702d743', '843d18d4b5512b63',
    '8a4de24951a1726d', '8fb47dd28b398cf7', '8fc2784308e9ba99',
    '965eae5a51acdd4a',
    '960b48a421a3faaa', '96ba14c9ebb49ce1', '972baac825d4d165',
    '9ab036439f74c115', '9e2e17f2ccccafdd', 'a05bd1ec67b3ac4c',
    'b0c9faf4af8903f9', 'b846cdcf41967725', 'b8580cac32214fc0',
    'b940c889d77f8219', 'b971b1141e1cbfac', 'bb37f12d0f46690f',
    'c2b9eb21b06f8378', 'c6449ffd9ea3779c', 'c8378469e1936877',
    'c89ed7ac3e425b25', 'c9af550acbec004c', 'd37e8d120d2836e3',
    'dcf8e74212fbee3b', 'e44ec9f9b3fe1d2a', 'ef04cb84d097a497',
    'ef570293245a17c2', 'f196069e7e14c497', 'f22d027b37bef107',
    'f2b4a99d1b0e40c8',
    '672f7da17f3ba34a',
}
local HEAVY_SET = {}
for _, h in ipairs(HEAVY_HASHES) do HEAVY_SET[h] = true end

-- hole spawner resources: the ONLY structures that get the seal filter
-- (towers/eggs/warp/tesla lack the 64B-row flag)
state.hseen = {}
local HOLE_SET = {
    ['8901f188db366b4b'] = true, ['9b58c95349d051f9'] = true,
    ['8c31b749759cbd61'] = true, ['36cc8ead2bb18d78'] = true,
    ['bc2af8548c6d5e06'] = true, ['f78bf0ff5c62140d'] = true,
    ['97dd3178e9f0ab70'] = true, ['4776a1cf3f19a13b'] = true,
    ['3a2cef12ed32a088'] = true,
}

-- spawners/nests: bug holes + towers + egg (STRUCTURES table) plus
-- illuminate structures collected from the HRES log. Rendered as red
-- hollow rings. Bot emplacements and barrels are NOT marked; the bot
-- fabricator hash has not been captured yet (watch HRES logs).
local STRUCTURE_SET = {}
for h in pairs(STRUCTURES) do STRUCTURE_SET[h] = true end
STRUCTURE_SET['74e2285c01da4f71'] = true  -- Warp Ship
STRUCTURE_SET['e8e7d998fcbd32f8'] = true  -- Illuminate Tesla Tower
STRUCTURE_SET['0d382ae7ffea9d45'] = true  -- Lightning Spire
-- bot fabricators + spawner structures (hashlist naming, RESEARCH 11.15)
STRUCTURE_SET['22cc0ed4ceb9cb68'] = true  -- Cyborg Factory (assault)
STRUCTURE_SET['a1a7b76b29088843'] = true  -- Cyborg Factory (phalanx)
STRUCTURE_SET['4fb8eb356ac8553e'] = true  -- Cyborg Factory (standard)
STRUCTURE_SET['a8ae6952b375ef6c'] = true  -- Cyborg Gunship Spawner
STRUCTURE_SET['d84ffc32a6e640a8'] = true  -- Cyborg Landed Dropship
STRUCTURE_SET['84ea7cfc98b30ff8'] = true  -- Assassinate Fabricator

-- ships tracked through the ai_enemy table (the health-table path
-- missed them in the 1.0.5 illuminate test): drawn as rings from the
-- enemies list, so they can move. 'Tentacle' is the ship candidate -
-- unconfirmed; if rings follow troop squads, remove this hash.
local RING_SET = {}
RING_SET['74e2285c01da4f71'] = true  -- Warp Ship

local ok, err = pcall(function()
    assert(type(loader) == 'table' and loader.api == 1,
        'Bingus Shared Loader API 1 required')
    assert(type(update) == 'function', 'Game update callback unavailable')
    local ffi, bit = require('ffi'), require('bit')
    assert(ffi.abi('64bit') and ffi.os == 'Windows', 'Windows x64 required')
    ffi.cdef[[
        void *GetModuleHandleA(const char *name);
        void *GetCurrentProcess(void);
        int ReadProcessMemory(void *process, const void *address, void *buffer, size_t size, size_t *read);
        uint64_t GetTickCount64(void);
        int QueryPerformanceCounter(int64_t *counter);
        int QueryPerformanceFrequency(int64_t *frequency);
        short GetAsyncKeyState(int vKey);
    ]]
    local k = ffi.load('kernel32')
    local user32 = ffi.load('user32')
    local process = k.GetCurrentProcess()
    local scratch, transferred = ffi.new('uint8_t[65536]'), ffi.new('size_t[1]')
    local function pointer(a) return ffi.cast('void *', a) end

    local function read(address, size)
        if type(address) ~= 'number' or address < 65536 or size < 1 or size > 65536 then return nil end
        if k.ReadProcessMemory(process, pointer(address), scratch, size, transferred) == 0 then return nil end
        if tonumber(transferred[0]) ~= size then return nil end
        return ffi.string(scratch, size)
    end
    local function u32(s, o)
        o = o or 0
        local a, b, c, d = s:byte(o + 1, o + 4)
        if not d then return nil end
        return a + b * 256 + c * 65536 + d * 16777216
    end
    local function ptr8(s, o)
        local lo, hi = u32(s, o), u32(s, o + 4)
        if not lo or not hi or hi >= 32768 then return nil end
        local p = lo + hi * 4294967296
        if p < 65536 or p >= 140737488355328 then return nil end
        return p
    end
    local function hex64(s, o)
        return string.format('%08x%08x', u32(s, o + 4), u32(s, o))
    end
    local function f32(s, o)
        local v = ffi.new('uint32_t[1]', u32(s, o))
        local f = tonumber(ffi.cast('float *', v)[0])
        if f ~= f or math.abs(f) > 1000000 then return nil end
        return f
    end

    local module = k.GetModuleHandleA('game.dll')
    assert(module ~= nil, 'game.dll not loaded')
    local game = tonumber(ffi.cast('uintptr_t', module))
    assert(game and game > 65536, 'game.dll base invalid')
    -- build pin: every offset below is only proven for this game.dll build
    -- (High Alert 1.9.0 proven constants)
    local lfanew_b = read(game + 0x3c, 4)
    local lfanew = lfanew_b and u32(lfanew_b, 0)
    local stamp_b = lfanew and read(game + lfanew + 8, 4)
    local size_b = lfanew and read(game + lfanew + 0x50, 4)
    local stamp = stamp_b and u32(stamp_b, 0)
    local imgsz = size_b and u32(size_b, 0)
    if stamp ~= 0x6ab3b43f or imgsz ~= 0x4744000 then
        say('BUILD MISMATCH stamp=0x%s size=0x%s - offsets unverified, probe disabled',
            stamp and string.format('%08x', stamp) or 'nil',
            imgsz and string.format('%x', imgsz) or 'nil')
        state.done = true
        return
    end
    say('BUILD ok game.dll stamp=0x6ab3b43f size=0x4744000')

    -- cfg file: %LOCALAPPDATA%\CowboyBingus\Helldivers2\LibertyRadar.cfg
    -- key=value lines, # comments; template written on first run, edits
    -- need a game restart. Values are clamped.
    local function cfg_load()
        local defs = {
            range = 100, scale = 1.0, cx_frac = 0.5, cy_frac = 0.29,
            tilt = 0.55, persp = 0.22, dot_r = 5, interval = 100,
            max_dots = 48, menu_hide = 1,
        }
        local la = os.getenv('LOCALAPPDATA') or ''
        local path = la .. '\\CowboyBingus\\Helldivers2\\LibertyRadar.cfg'
        local f = io.open(path, 'r')
        if f then
            for line in f:lines() do
                local key, val = line:match('^%s*([%w_]+)%s*=%s*([%-%.%d]+)%s*$')
                if key and defs[key] ~= nil then
                    local num = tonumber(val)
                    if num then defs[key] = num end
                end
            end
            f:close()
        else
            local w = io.open(path, 'w')
            if w then
                w:write('# Liberty Radar cfg - edits need a game restart\n')
                w:write('# range: detection radius in meters (20-200)\n')
                w:write('# scale: radar size multiplier (0.5-2.0)\n')
                w:write('# cx_frac/cy_frac: radar center as screen fraction (0.1-0.9)\n')
                w:write('# tilt: vertical compression, cos of tilt angle (0.3-1.0, 1.0 = flat)\n')
                w:write('# persp: far-edge extra compression (0-0.5)\n')
                w:write('# dot_r: dot radius px at 1440p (3-10)\n')
                w:write('# interval: scan interval ms (30-250; 100 = 10 Hz, dots are interpolated between scans)\n')
                w:write('# max_dots: max dots drawn (8-96)\n')
                w:write('# menu_hide: hide radar when the game shows the cursor (0/1)\n')
                for k, v in pairs(defs) do
                    w:write(string.format('%s=%s\n', k, tostring(v)))
                end
                w:close()
            end
        end
        defs.range = math.max(20, math.min(200, defs.range))
        defs.scale = math.max(0.5, math.min(2.0, defs.scale))
        defs.cx_frac = math.max(0.1, math.min(0.9, defs.cx_frac))
        defs.cy_frac = math.max(0.1, math.min(0.9, defs.cy_frac))
        defs.tilt = math.max(0.3, math.min(1.0, defs.tilt))
        defs.persp = math.max(0, math.min(0.5, defs.persp))
        defs.dot_r = math.max(3, math.min(10, defs.dot_r))
        defs.interval = math.max(30, math.min(250, defs.interval))
        defs.max_dots = math.max(8, math.min(96, math.floor(defs.max_dots)))
        defs.menu_hide = (defs.menu_hide ~= 0) and 1 or 0
        return defs
    end
    local cfg = cfg_load()
    say('CFG range=%d scale=%.2f cx=%.2f cy=%.2f tilt=%.2f persp=%.2f dot_r=%d interval=%d max_dots=%d menu_hide=%d',
        cfg.range, cfg.scale, cfg.cx_frac, cfg.cy_frac, cfg.tilt, cfg.persp,
        cfg.dot_r, cfg.interval, cfg.max_dots, cfg.menu_hide)
    local exeh = k.GetModuleHandleA(nil)
    local exe_base = exeh and tonumber(ffi.cast('uintptr_t', exeh)) or nil
    local function global(rva)
        local b = read(game + rva, 8)
        return b and ptr8(b, 0) or nil
    end

    local function hash_lookup(addr, id, limit)
        local h = read(addr, 20)
        if not h then return nil, 'header_unreadable' end
        local entries, cap, empty, mult = ptr8(h, 0), u32(h, 8), u32(h, 12), u32(h, 16)
        if not entries or not cap or cap == 0 or cap > 1048576 then return nil, 'bad_capacity' end
        if math.floor(cap / 2) * 2 ~= cap then return nil, 'not_power_of_two' end
        if id == empty then return nil, 'empty_key' end
        local low = tonumber(ffi.cast('uint32_t', ffi.new('uint64_t', id) * ffi.new('uint64_t', mult)))
        local start = bit.band(low, cap - 1)
        -- probe window in ONE read instead of one RPM call per row (per-row
        -- reads were the single biggest cost driver); windows never wrap, so
        -- a probe that runs into the table end gets one continuation read
        local nrows = math.min(cap, 256)
        local win = read(entries + start * 8, nrows * 8)
        for attempt = 1, 2 do
            if win then
                for i = 0, nrows - 1 do
                    local key, index = u32(win, i * 8), u32(win, i * 8 + 4)
                    if key == empty then return nil, 'absent' end
                    if key == id then
                        if index == 4294967295 then return nil, 'tombstone' end
                        if index >= limit then return nil, 'index_bound' end
                        return index
                    end
                end
            end
            if attempt == 1 and nrows == cap - start and nrows < 256 then
                nrows = math.min(256 - nrows, start)
                win = nrows > 0 and read(entries, nrows * 8) or nil
            else
                break
            end
        end
        return nil, 'probe_budget'
    end

    local function motion_pos(id)
        local m = global(0x3326508)
        if not m then return nil, 'no_motion_manager' end
        local idx, why = hash_lookup(m + 0x40, id, 4096)
        if not idx then return nil, 'hash:' .. tostring(why) end
        local recs_b = read(m + 0x68, 8)
        local recs = recs_b and ptr8(recs_b, 0) or nil
        if not recs then return nil, 'no_records' end
        local raw = read(recs + idx * 0x308 + 0x2e0, 12)
        if not raw then return nil, 'pos_unreadable' end
        local x, y, z = f32(raw, 0), f32(raw, 4), f32(raw, 8)
        if not x or not y or not z then return nil, 'pos_nonfinite' end
        return { x, y, z }
    end

    -- component-manager entity enumeration (loot spike v69/v70): each
    -- entity family owns a manager - global slot -> struct with count
    -- @hh+12 (hh = +8) and an entity-record pointer array @+0x40; records
    -- are 24B: res @+0, entity id @+8. Layout verified stable across
    -- sessions (v67/v69/v70 logs identical counts and rosters).
    --   0x33265c8 = structures (holes/nests/eggs - health walk NEVER sees
    --               holes), 0x33267c8 = supply pickups
    local function mgr_entities(rva, cap, moff)
        moff = moff or 0
        local p = global(rva)
        if not p then return nil end
        p = p + moff
        local hh = read(p + 8, 16)
        local cnt = hh and u32(hh, 12)
        if not cnt or cnt < 1 or cnt > 4096 then return nil end
        local he_b = read(p + 0x40, 8)
        local he = he_b and ptr8(he_b, 0)
        if not he then return nil end
        local win = read(he, 8 * math.min(cnt, cap))
        if not win then return nil end
        local out = {}
        for i = 0, math.min(cnt, cap) - 1 do
            local ob = ptr8(win, i * 8)
            local e = ob and read(ob, 24)
            if e then
                local eid = u32(e, 8)
                local res = hex64(e, 0)
                if eid ~= 0 and res ~= '0000000000000000' then
                    out[#out + 1] = { id = eid, res = res }
                end
            end
        end
        return out
    end

    local function faction_info(id)
        local fm = global(0x3326cb8)
        if not fm then return nil, 'no_faction_manager' end
        local fi, why = hash_lookup(fm + 0x12050, id, 131072)
        if not fi then return nil, 'hash:' .. tostring(why) end
        local ma_b = read(fm + 0x12078, 8)
        local ca_b = read(fm + 0x12070, 8)
        local ma = ma_b and ptr8(ma_b, 0)
        local ca = ca_b and ptr8(ca_b, 0)
        if not ma or not ca then return nil, 'arrays_nil' end
        local mask_b = read(ma + 4 * fi, 4)
        local node_b = read(ca + 96 * fi, 4)
        if not mask_b or not node_b then return nil, 'rows_unreadable' end
        return { mask = u32(mask_b, 0), pose_node = u32(node_b, 0) }
    end

    local function bone(unit, node)
        if not exe_base then return nil, nil, 'no_exe_base' end
        if type(unit) ~= 'number' or type(node) ~= 'number' then return nil, nil, 'args' end
        if node < 0 or node >= 1024 then return nil, nil, 'node_range' end
        local reg_b = read(exe_base + 0x1a100f0, 8)
        local reg = reg_b and ptr8(reg_b, 0)
        if not reg then return nil, nil, 'no_registry' end
        local index = unit % 0x400000
        local generation = math.floor(unit / 0x400000) % 256
        local cb = read(reg + 0x98, 4)
        local count = cb and u32(cb, 0)
        if not count or count > 0x400000 or index >= count then return nil, nil, 'count_bound' end
        local ga_b = read(reg + 0xa0, 8)
        local ga = ga_b and ptr8(ga_b, 0)
        if not ga then return nil, nil, 'gen_array_nil' end
        local gbb = read(ga + index, 1)
        if not gbb or gbb:byte(1) ~= generation then return nil, nil, 'gen_mismatch' end
        local oa_b = read(reg + 0x88, 8)
        local oa = oa_b and ptr8(oa_b, 0)
        if not oa then return nil, nil, 'obj_array_nil' end
        local ob_b = read(oa + 8 * index, 8)
        local object = ob_b and ptr8(ob_b, 0)
        if not object then return nil, nil, 'object_nil' end
        local ib = read(object + 8, 4)
        if not ib or u32(ib, 0) ~= unit then return nil, nil, 'unit_mismatch' end
        local bb = read(object + 0x70, 4)
        local bones = bb and u32(bb, 0)
        if not bones or bones < 1 or bones > 1024 or node >= bones then return nil, nil, 'bone_bound' end
        local ba_b = read(object + 0x88, 8)
        local ba = ba_b and ptr8(ba_b, 0)
        if not ba then return nil, nil, 'bone_array_nil' end
        local b = read(ba + node * 64, 64)
        if not b then return nil, nil, 'bone_unreadable' end
        local x, y, z = f32(b, 48), f32(b, 52), f32(b, 56)
        if not x or not y or not z then return nil, nil, 'pos_nonfinite' end
        local fwd = nil
        local fx, fy, fz = f32(b, 16), f32(b, 20), f32(b, 24)
        if fx and fy and fz then
            local len = math.sqrt(fx * fx + fy * fy + fz * fz)
            if len >= 0.5 and len <= 1.5 then fwd = { fx, fy, fz, len } end
        end
        return { x, y, z }, fwd, nil
    end

    -- view yaw candidates: held-weapon muzzle poses (APW-proven chain:
    -- weapon 0x33266d8 -> attach 0x3326dc0 filter by avatar -> pose 0x3326ce0)
    local function weapon_muzzles(avatar_id)
        local out = {}
        local wm = global(0x33266d8)
        local am = global(0x3326dc0)
        if not wm or not am then return out, 'no_manager' end
        local nb = read(wm + 0x38, 4)
        local total = nb and u32(nb, 0) or nil
        if not total or total < 1 or total > 1024 then return out, 'no_weapons' end
        local we_b = read(wm + 0x68, 8)
        local we = we_b and ptr8(we_b, 0) or nil
        local pa = we and read(we, 8 * total) or nil
        local pb_b = read(am + 0x40, 8)
        local parent_base = pb_b and ptr8(pb_b, 0) or nil
        if not pa or not parent_base then return out, 'no_arrays' end
        local wd = global(0x3326ce0)
        for n = 0, total - 1 do
            local obj = ptr8(pa, 8 * n)
            if obj and obj >= 65536 and obj < 0x800000000000 then
                local eb = read(obj, 24)
                if eb then
                    local id, unit, flags = u32(eb, 8), u32(eb, 12), u32(eb, 20)
                    if id ~= 0 and unit ~= 0 and flags % 4 == 1 then
                        local ai = hash_lookup(am + 0x20, id, 32768)
                        if ai and ai < 16384 then
                            local att = read(parent_base + 48 * ai, 20)
                            if att and u32(att, 4) == avatar_id then
                                local m = { id = id, unit = unit,
                                    att0 = u32(att, 0), att8 = u32(att, 8) }
                                if wd then
                                    local wi = hash_lookup(wd + 48, id, 32768)
                                    if wi and wi < 16384 then
                                        local arr_b = read(wd + 88, 8)
                                        local arr = arr_b and ptr8(arr_b, 0) or nil
                                        local wb = arr and read(arr + 1008 * wi, 228) or nil
                                        local cnt = wb and u32(wb, 216) or nil
                                        local ix = wb and u32(wb, 220) or nil
                                        if cnt and ix and cnt >= 1 and cnt <= 24 and ix < cnt then
                                            m.node = u32(wb, 120 + 4 * ix)
                                        end
                                    end
                                end
                                if m.node then
                                    local mp, mf = bone(unit, m.node)
                                    if mp and mf then m.pos, m.fwd = mp, mf end
                                end
                                out[#out + 1] = m
                            end
                        end
                    end
                end
            end
        end
        return out
    end

    local function angle_diff(a, b)
        local d = a - b
        while d > math.pi do d = d - 2 * math.pi end
        while d < -math.pi do d = d + 2 * math.pi end
        return d
    end

    -- P0f: empirical hunt for the view yaw/pitch floats. Candidates are finite
    -- f32 in [-360,360] inside controller-plausible regions; a candidate is
    -- logged only when it changed since the previous scan (>=0.5). Offline we
    -- keep the ones that moved with view sweeps (protocol B/C) but not with
    -- body-only rotation (protocol A).
    local function scan_regions(pl, ei)
        local rs = {}
        local p = global(0x3326468)
        if p then
            rs[#rs + 1] = { base = p, size = 0x800 }
            rs[#rs + 1] = { base = p + 0x800, size = 0x800 }
        end
        local owner = global(0x346bf98)
        if owner and ei then
            rs[#rs + 1] = { base = owner + 0xf32f18 + ei * 24 - 0x100, size = 0x400 }
        end
        local seek = global(0x3326df0)
        if seek then rs[#rs + 1] = { base = seek, size = 0x200 } end
        if pl and pl.unit and exe_base then
            local reg_b = read(exe_base + 0x1a100f0, 8)
            local reg = reg_b and ptr8(reg_b, 0) or nil
            if reg then
                local cb_b = read(reg + 0x98, 4)
                local count = cb_b and u32(cb_b, 0) or nil
                local index = pl.unit % 0x400000
                local generation = math.floor(pl.unit / 0x400000) % 256
                if count and index < count then
                    local ga_b = read(reg + 0xa0, 8)
                    local ga = ga_b and ptr8(ga_b, 0) or nil
                    local gbb = ga and read(ga + index, 1) or nil
                    local oa_b = read(reg + 0x88, 8)
                    local oa = oa_b and ptr8(oa_b, 0) or nil
                    local ob_b = oa and read(oa + 8 * index, 8) or nil
                    local object = ob_b and ptr8(ob_b, 0) or nil
                    if object and gbb and gbb:byte(1) == generation then
                        rs[#rs + 1] = { base = object, size = 0x400 }
                    end
                end
            end
        end
        return rs
    end

    local function scan_view(k, regions, muzzle_deg)
        local sc = state.scan
        if not sc then sc = { prev = {} }; state.scan = sc end
        local found, lines = 0, {}
        for ri, r in ipairs(regions) do
            for off = 0, r.size - 256, 256 do
                local blk = read(r.base + off, 256)
                if blk then
                    for j = 0, 252, 4 do
                        local v = f32(blk, j)
                        local key = ri .. ':' .. (off + j)
                        if v and v <= 360 and (v == 0 or v >= 0.05 or v <= -0.05) then
                            local old = sc.prev[key]
                            sc.prev[key] = v
                            if old and math.abs(v - old) >= 0.5 then
                                found = found + 1
                                if #lines < 28 then
                                    lines[#lines + 1] = string.format('%s=%.2f>%.2f',
                                        key, old, v)
                                end
                            end
                        else
                            sc.prev[key] = nil
                        end
                    end
                end
            end
        end
        say('SCAN k=%d mz=%.1f ch=%d | %s', k, muzzle_deg or 0, found,
            #lines > 0 and table.concat(lines, ' ') or 'quiet')
    end

    -- alive map from the health table (P0b-proven chain), WALKED IN CHUNKS
    -- across samples: 96 slots per 250ms tick instead of a 1024-slot burst,
    -- so the main thread never sees a multi-ms spike (the "full scan every
    -- tick" trap). Full sweep period ~2.5s; corpses get amap[id]=false.
    local HEALTH_CHUNK = 96
    local function health_alive_step()
        local hm0 = global(0x3326688)
        if not hm0 then return end
        local hm = hm0 + 0x1008
        local hh = read(hm + 8, 16)
        local hcount = hh and u32(hh, 12) or nil
        local he_b = read(hm + 0x40, 8)
        local hd_b = read(hm + 0x50, 8)
        local hn_b = read(hm + 0x58, 8)
        local he = he_b and ptr8(he_b, 0) or nil
        local hd = hd_b and ptr8(hd_b, 0) or nil
        local hn = hn_b and ptr8(hn_b, 0) or nil
        if not hcount or hcount < 1 or not he or not hd or not hn then return end
        if hcount > 1024 then hcount = 1024 end
        local hw = state.hwalk
        if not hw then hw = { cursor = 0 }; state.hwalk = hw end
        local amap = state.amap
        if not amap then amap = {}; state.amap = amap end
        local target = math.min(hw.cursor + HEALTH_CHUNK, hcount)
        local pa_b = read(he + hw.cursor * 8, 8 * (target - hw.cursor))
        for i = hw.cursor, target - 1 do
            local obj = pa_b and ptr8(pa_b, 8 * (i - hw.cursor)) or nil
            if obj then
                local ent = read(obj, 24)
                if ent then
                    local eid = u32(ent, 8)
                    if eid and eid ~= 0 then
                        -- P3 prep: catalogue health-walk res hashes once
                        -- per session; known structures get a one-shot
                        -- motion probe (are buildings in the motion table?)
                        local hres = hex64(ent, 0)
                        state.hres = state.hres or {}
                        if hres and not state.hres[hres] then
                            state.hres[hres] = true
                            if STRUCTURES[hres] then
                                local bmp = motion_pos(eid)
                                say('BLD res=%s (%s) id=%d motion=%s', hres,
                                    STRUCTURES[hres], eid,
                                    bmp and 'HIT' or 'MISS')
                            elseif not FRIENDLY_SET[hres] then
                                say('HRES res=%s%s', hres, CATALOG[hres] or '')
                            end
                        end
                        if hres and STRUCTURE_SET[hres] then
                            local bc = state.bld_cache
                            if not bc then bc = {}; state.bld_cache = bc end
                            local b = bc[eid]
                            if not b then
                                b = { x = nil, y = nil, k = 0 }
                                bc[eid] = b
                            end
                            b.k = state.threat_k or 0
                            b.idx = i
                            if not b.x then
                                local bmp = motion_pos(eid)
                                if bmp then b.x, b.y = bmp[1], bmp[2] end
                            end
                        end
                        -- hp@+20 and status@+412 share the 440B record: one
                        -- window read covers both; only max-hp needs a second
                        local win = read(hd + 440 * i + 20, 396)
                        local mxb = read(hn + 28 * i + 20, 4)
                        local hp = win and u32(win, 0)
                        local mx = mxb and u32(mxb, 0)
                        local sv = win and u32(win, 392)
                        if hp and mx and sv then
                            amap[eid] = (hp > 0 and mx > 0 and hp <= mx and sv == 0) or false
                        end
                        -- client-safe aliveness (1.0.27): the mirror
                        -- roster's alive byte is host-authoritative and
                        -- reads dead for every network-replicated enemy
                        -- (1.0.26 client log: live_with_pos=0 for a whole
                        -- mission). The health table IS replicated, so
                        -- track live non-friendlies here; the scan merges
                        -- them into the dot list.
                        if hp and mx and hp > 0 and mx > 0
                            and hp <= mx and sv == 0 then
                            if hres and not FRIENDLY_SET[hres]
                                and not STRUCTURE_SET[hres]
                                and hres ~= AVATAR_HEX then
                                local lv = state.hlive
                                if not lv then lv = {}; state.hlive = lv end
                                local rec = lv[eid]
                                if not rec or rec.res ~= hres then
                                    rec = { res = hres }
                                    lv[eid] = rec
                                end
                                rec.k = state.threat_k or 0
                            end
                            -- self-heal: a struct_dead id seen alive again
                            -- (id reuse) gets its ring back within a sweep
                            if hres and STRUCTURE_SET[hres]
                                and state.struct_dead then
                                state.struct_dead[eid] = nil
                            end
                        elseif hp == 0 and hres and STRUCTURE_SET[hres] then
                            -- hp==0 is the same strict signal the
                            -- fast-destroy pass trusts; a compound-false
                            -- (mx not synced yet) must NOT kill a live
                            -- ring (hole-mystery lesson: false positives
                            -- are worse than a lingering ring)
                            state.struct_dead = state.struct_dead or {}
                            state.struct_dead[eid] = true
                        end
                    end
                end
            end
        end
        hw.cursor = target >= hcount and 0 or target
        -- fast destroy: re-verify cached structures every scan (same
        -- slot still holds this id and hp > 0); a destroyed nest drops
        -- within one scan instead of riding the 60-scan TTL. A compacted
        -- table also mismatches the id, and the walk re-adds live
        -- entities with a fresh slot, so a wrong drop self-heals.
        local bc2 = state.bld_cache
        if bc2 and he and hd and next(bc2) then
            for eid2, b2 in pairs(bc2) do
                local idx2 = b2.idx
                if idx2 then
                    local pob = read(he + 8 * idx2, 8)
                    local obj2 = pob and ptr8(pob, 0) or nil
                    local ent2 = obj2 and read(obj2, 24) or nil
                    local alive2 = false
                    if ent2 and u32(ent2, 8) == eid2 then
                        local hpb = read(hd + 440 * idx2 + 20, 4)
                        local hp2 = hpb and u32(hpb, 0)
                        alive2 = (hp2 or 0) > 0
                        if hp2 == 0 then
                            state.struct_dead = state.struct_dead or {}
                            state.struct_dead[eid2] = true
                        end
                    end
                    if not alive2 then bc2[eid2] = nil end
                end
            end
        end
    end

    -- hostiles for the radar: friendly-hash whitelist (replaces the
    -- polarity-broken faction mask) + health alive map + ring clip.
    -- No height gate: flyers and cliff units belong on a radar.
    -- Sorted nearest-first; dx/dy are motion-table horizontal components.
    local function collect_hostiles(list, pl, amap, range)
        local out = {}
        if not pl or not pl.pos then return out, 0, 0 end
        local r2 = range * range
        local dead, nhv = 0, 0
        for _, e in ipairs(list) do
            if amap and amap[e.id] == false then
                dead = dead + 1
            elseif not FRIENDLY_SET[e.res or ''] then
                local dx = e.pos[1] - pl.pos[1]
                local dy = e.pos[2] - pl.pos[2]
                local d2 = dx * dx + dy * dy
                if d2 <= r2 then
                    local rng = RING_SET[e.res or ''] == true
                    local hv = (not rng) and HEAVY_SET[e.res or ''] == true
                    if hv then nhv = nhv + 1 end
                    out[#out + 1] = { id = e.id, dx = dx, dy = dy,
                                      d = math.sqrt(d2), hv = hv,
                                      ring = rng }
                end
            end
        end
        table.sort(out, function(a, b) return a.d < b.d end)
        return out, dead, nhv
    end

    local function in_mission()
        local mode = global(0x33266a0)
        if not mode then return false, 'no_mode' end
        local m = read(mode, 0x44)
        if not m then return false, 'mode_unreadable' end
        local phase = u32(m, 0x40)
        if u32(m, 8) == 0 or not phase or phase < 1 or phase > 7 then
            return false, 'phase=' .. tostring(phase)
        end
        return true, 'phase=' .. phase
    end

    local function player_id()
        local inside = in_mission()
        if not inside then return nil, 'not_in_mission' end
        local players = global(0x3326468)
        if not players then return nil, 'no_players' end
        local counts = read(players + 0x84, 8)
        if not counts then return nil, 'no_counts' end
        if u32(counts) == 0 or u32(counts, 4) == 0 then return nil, 'empty_counts' end
        local ref_b = read(players + 0x3a8, 4)
        local ref = ref_b and u32(ref_b, 0) or nil
        if not ref or ref == 0 or ref == 0x7fff then return nil, 'bad_ref' end
        local owner = global(0x346bf98)
        if not owner then return nil, 'no_owner' end
        local ei, why = hash_lookup(owner + 0xf22ec8, ref, 1048576)
        if not ei then return nil, 'ref_hash:' .. tostring(why) end
        local entity = read(owner + 0xf32f18 + ei * 24, 24)
        if not entity then return nil, 'entity_unreadable' end
        if entity:sub(1, 8) ~= AVATAR_RESOURCE then
            return nil, 'not_avatar:' .. hex64(entity, 0)
        end
        return { id = u32(entity, 8), unit = u32(entity, 12), ref = ref, ei = ei }
    end

    local function dump_table_keys(t, label)
        if type(t) ~= 'table' then
            say('DUMP %s: type=%s', label, type(t))
            return
        end
        local names = {}
        local okp, errp = pcall(function()
            for key, val in pairs(t) do
                names[#names + 1] = tostring(key) .. ':' .. type(val)
                if #names >= 60 then error('enough') end
            end
        end)
        if #names == 0 then
            say('DUMP %s: pairs_empty (%s)', label, okp and 'ok' or tostring(errp))
            return
        end
        say('DUMP %s (%d+): %s', label, #names, table.concat(names, ' '))
    end

    -- True camera pose via the WORLD-level binding. Safe, unlike the
    -- Unit/Camera level bindings that crash on transient avatar states
    -- (proven in production by High Alert 1.9.0). Cached world + self-heal.
    local cam = { pose = nil, world = nil, why = 'init' }

    local function screen_size()
        if state.screen then return state.screen end
        local w, h = 2560, 1440
        local sr0 = rawget(_G, 'stingray')
        if type(sr0) == 'table' and type(sr0.Application) == 'table'
            and type(sr0.Application.resolution) == 'function' then
            local ok, rw, rh = pcall(sr0.Application.resolution)
            if ok and type(rw) == 'number' and type(rh) == 'number'
                and rw > 100 and rh > 100 then
                w, h = math.floor(rw), math.floor(rh)
            end
        end
        state.screen = { w = w, h = h }
        say('SCREEN %dx%d', w, h)
        return state.screen
    end

    local function cam_vector_of(sr, v)
        if v == nil then return nil end
        local ok, x, y, z = pcall(function()
            return sr.Vector3.x(v), sr.Vector3.y(v), sr.Vector3.z(v)
        end)
        if not ok or type(x) ~= 'number' or type(y) ~= 'number' or type(z) ~= 'number'
            or x ~= x or y ~= y or z ~= z then return nil end
        return { x = x, y = y, z = z }
    end

    local CAM_AXES = { 'right', 'forward', 'up', 'translation' }
    local function cam_pose_of(sr, matrix)
        local M = sr.Matrix4x4
        if type(M) ~= 'table' then return nil end
        local out = {}
        for i = 1, 4 do
            local get = M[CAM_AXES[i]]
            if type(get) ~= 'function' then return nil end
            local ok, value = pcall(get, matrix)
            local xyz = ok and cam_vector_of(sr, value) or nil
            if not xyz then return nil end
            out[i] = xyz
        end
        return out
    end

    local function cam_world_alive(sr, world)
        local okw, worlds = pcall(sr.Application.worlds)
        if okw and type(worlds) == 'table' then
            for _, w in ipairs(worlds) do
                if w == world then return true end
            end
        end
        return false
    end

    local function cam_lookup(sr)
        local App, World = sr.Application, sr.World
        if not (type(App) == 'table' and type(World) == 'table'
            and type(World.debug_camera_pose) == 'function'
            and type(sr.Matrix4x4) == 'table') then
            cam.pose, cam.world, cam.why = nil, nil, 'engine exposes no camera pose'
            return false
        end
        local okm, main = pcall(App.main_world)
        local order = {}
        if okm and main ~= nil then order[#order + 1] = main end
        local okw, worlds = pcall(App.worlds)
        if okw and type(worlds) == 'table' then
            for _, w in ipairs(worlds) do
                if w ~= main then order[#order + 1] = w end
            end
        end
        for _, w in ipairs(order) do
            local ok, matrix = pcall(World.debug_camera_pose, w)
            if ok and matrix ~= nil then
                local pose = cam_pose_of(sr, matrix)
                local forward = pose and pose[2]
                if forward then
                    -- a real camera basis is unit length; anything else is garbage
                    local len = math.sqrt(forward.x ^ 2 + forward.y ^ 2 + forward.z ^ 2)
                    if len > 0.5 and len < 2 then
                        cam.pose, cam.world, cam.why = pose, w, nil
                        return true
                    end
                end
            end
        end
        cam.pose, cam.world, cam.why = nil, nil, 'no world returned a usable camera pose'
        return false
    end

    local function camera_tick()
        local sr = rawget(_G, 'stingray')
        if type(sr) ~= 'table' then cam.pose = nil; return false end
        if cam.world and cam_world_alive(sr, cam.world) then
            local ok, matrix = pcall(sr.World.debug_camera_pose, cam.world)
            local pose = ok and matrix and cam_pose_of(sr, matrix)
            if pose then cam.pose = pose; return true end
        end
        cam.pose = nil
        return cam_lookup(sr)
    end

    -- camera horizontal basis; right sign verified against the real camera
    -- right axis, which also settles the radar mirror question by construction
    local function camera_basis()
        local pose = cam.pose
        if not pose then return nil end
        local forward, right = pose[2], pose[1]
        local fx0, fy0 = forward.x, forward.y
        local flat = math.sqrt(fx0 * fx0 + fy0 * fy0)
        local rx0, ry0 = right.x, right.y
        local rflat = math.sqrt(rx0 * rx0 + ry0 * ry0)
        -- measure the right->forward quarter turn while forward still has
        -- ground length; handedness cannot be guessed when looking straight
        -- up/down, and the right axis is the one that stays flat
        if rflat >= 0.05 and flat >= 0.25 then
            state.cam_perp = ((-ry0) * fx0 + rx0 * fy0 > 0) and 1 or 2
        end
        local fx, fy
        if flat >= 0.12 then
            fx, fy = fx0 / flat, fy0 / flat
        elseif rflat >= 0.05 and state.cam_perp then
            -- near-vertical view: rotate the still-flat right axis 90 deg
            if state.cam_perp == 1 then
                fx, fy = -ry0 / rflat, rx0 / rflat
            else
                fx, fy = ry0 / rflat, -rx0 / rflat
            end
        elseif state.cam_last and (state.runs or 0) - (state.cam_age or 0) < 12 then
            -- hold the last good answer briefly instead of snapping to body
            fx, fy = math.cos(state.cam_last), math.sin(state.cam_last)
        end
        if not fx then return nil end
        state.cam_last = math.atan2(fy, fx)
        state.cam_age = state.runs or 0
        -- right basis: the real camera right stays flat even when pitched
        local rx, ry
        if rflat >= 0.05 then
            rx, ry = rx0 / rflat, ry0 / rflat
        else
            rx, ry = fy, -fx
        end
        return { fx = fx, fy = fy, rx = rx, ry = ry }
    end

    -- P1 radar: overlay world gui, static ring + center, dynamic enemy dots.
    local radar = state.radar
    if not radar then
        radar = { gui = nil, sr = nil, ring_ids = {}, pool = {},
                  built = false, cx = 1280, cy = 420, R = 150, range = cfg.range,
                  POOL = 64, dot = 8, upd_ok = 0, upd_fail = 0 }
        state.radar = radar
    end


    -- game UI material binding (Radar Sweep v2.5 recipe): primitives on a gui
    -- bound to the game's own UI material honor Color alpha
    local UI_RVA = { font = 0x3772268, atlas = 0x3772ee8, mat = 0x37c5478,
                     slot = '88bac99b00000000' }
    local BIND_UI_MATERIAL = false
    local mat_state = { ids = nil, blocked = false, bound = false }

    local function ui_ids()
        if mat_state.ids ~= nil then return mat_state.ids or nil end
        mat_state.ids = false
        local font_b = read(game + UI_RVA.font, 8)
        local font = font_b and hex64(font_b, 0)
        if not font then return nil, 'no font id' end
        local atlas_b = read(game + UI_RVA.atlas, 8)
        local atlas = atlas_b and hex64(atlas_b, 0)
        if not atlas then return nil, 'no atlas id' end
        local owner_b = read(game + UI_RVA.mat, 8)
        local owner = owner_b and ptr8(owner_b, 0) or nil
        local mat_b = owner and read(owner + 24, 8)
        local mat = mat_b and hex64(mat_b, 0)
        if not mat then return nil, 'no material id' end
        mat_state.ids = { font = font, atlas = atlas, material = mat }
        return mat_state.ids
    end

    local function bind_ui_material(gui)
        if mat_state.blocked then return false end
        local sr0 = rawget(_G, 'stingray')
        if type(sr0) ~= 'table' then return false end
        local from_hex
        pcall(function() from_hex = rawget(sr0.IdString64, 'from_hex') end)
        if type(sr0.Gui) ~= 'table' or type(sr0.Gui.material) ~= 'function'
            or type(sr0.Material) ~= 'table' or type(sr0.Application) ~= 'table'
            or type(sr0.Application.can_get) ~= 'function'
            or type(from_hex) ~= 'function' then
            mat_state.blocked = true
            say('MAT: no Gui.material/can_get/IdString64 - debug material stays')
            return false
        end
        local ids, why = ui_ids()
        if not ids then
            mat_state.blocked = true
            say('MAT: ui ids unavailable: %s', tostring(why))
            return false
        end
        local ok, ink = pcall(function()
            local mat = from_hex(ids.material)
            local atlas = from_hex(ids.atlas)
            if not (mat and atlas) then return nil end
            local can = sr0.Application.can_get
            if can('material', mat) ~= true then return nil end
            if can('texture', atlas) ~= true then return nil end
            local i = sr0.Gui.material(gui, mat)
            if i == nil then return nil end
            sr0.Material.set_texture(i, from_hex(UI_RVA.slot), atlas)
            return i
        end)
        if not ok or ink == nil then
            mat_state.blocked = true
            say('MAT: game UI material not resident - debug material stays')
            return false
        end
        mat_state.bound = true
        say('MAT bound material=%s atlas=%s', ids.material, ids.atlas)
        return true
    end

    local function radar_setup()
        if radar.gui then return true end
        local sr = rawget(_G, 'stingray')
        if type(sr) ~= 'table' then say('RADAR: no stingray'); return false end
        state.wgui = state.wgui or {}
        local okw, worlds = pcall(sr.Application.worlds)
        local okm, game_world = pcall(sr.Application.main_world)
        if not okw or type(worlds) ~= 'table' or not okm or game_world == nil then
            say('RADAR: worlds unavailable okw=%s gm=%s',
                tostring(okw), okm and type(game_world) or tostring(game_world))
            return false
        end
        local target = nil
        for i = 1, #worlds do
            if worlds[i] ~= nil and worlds[i] ~= game_world then target = worlds[i]; break end
        end
        if not target then say('RADAR: no overlay world (#=%d)', #worlds); return false end
        -- retained mode ONLY: immediate mode never composited on this build
        -- (tested v35-v38), while retained triangle dots render fine
        state.immediate = false
        local okc, gui = pcall(sr.World.create_screen_gui, target, 'scale', 1, 1)
        if not okc or gui == nil then
            say('RADAR: create fail %s', tostring(gui):sub(1, 90))
            return false
        end
        radar.sr = sr
        radar.gui = gui
        pcall(sr.Gui.set_visible, gui, true)
        -- UI material binding OFF for now: its atlas texel alpha made dots
        -- look slightly translucent; the engine default material is opaque
        -- (re-enable when real per-dot alpha fading is wanted again)
        if BIND_UI_MATERIAL then
            bind_ui_material(gui)
        end
        -- stock Stingray has Gui.update_triangle; if HD2 exposes it, the
        -- per-frame interpolated redraw path becomes available
        state.has_ut = type(sr.Gui) == 'table'
            and type(sr.Gui.update_triangle) == 'function'
        say('GUIAPI update_triangle probe only - DISABLED: it is callable but')
        say('GUIAPI the engine-side update CRASHES the game, proven v48')

        state.has_ut = false
        -- update_triangle interpolation (path 1) re-enabled with tilt+cfg
        -- one-time API introspection: look for camera-capable namespaces
        -- world gui probe: can we create a gui plane in the 3D world and
        -- move it around? (the 0.2.2 floating-panel effect, pure Lua path)
        state.wgui = {}
        for _, n in ipairs({ 'create_world_gui', 'create_screen_gui', 'destroy_gui' }) do
            state.wgui[n] = type(sr.World) == 'table' and type(sr.World[n]) == 'function'
            say('WGUI World.%s = %s', n, tostring(state.wgui[n]))
        end
        local poshits = {}
        if type(sr.Gui) == 'table' then
            for k, v in pairs(sr.Gui) do
                if type(v) == 'function' and (k:find('world') or k:find('position')
                    or k:find('move') or k:find('place')) then
                    poshits[#poshits + 1] = k
                end
            end
        end
        say('GUIAPI world/pos functions: %s', #poshits > 0
            and table.concat(poshits, ' ') or 'none')
        pcall(dump_table_keys, sr, 'stingray')
        pcall(dump_table_keys, sr.Unit, 'sr.Unit')
        pcall(dump_table_keys, sr.Camera, 'sr.Camera')
        pcall(dump_table_keys, sr.Viewport, 'sr.Viewport')
        pcall(dump_table_keys, sr.Application, 'sr.Application')
        pcall(dump_table_keys, sr.World, 'sr.World')
        say('RADAR: gui ready cx=%d cy=%d R=%d range=%dm',
            radar.cx, radar.cy, radar.R, radar.range)
        return true
    end

    -- mockup v2: no glow, no ellipse. Player = static green circle (12-tri
    -- fan, built once). Enemy dots = decagon triangle fans rebuilt per tick
    -- (Gui has no update_triangle), alpha fades with distance.
    local function radar_build_ring()
        if radar.built or not radar.gui then return end
        local scr = screen_size()
        radar.cx = math.floor(scr.w * cfg.cx_frac)
        radar.cy = math.floor(scr.h * cfg.cy_frac)
        radar.R = math.floor(scr.h * 150 / 1440 * cfg.scale)
        radar.built = true
        say('RADAR: built (marker+dots drawn per tick)')
    end

    local function radar_draw_dots(hostiles, pl)
        local sr, Gui = radar.sr, radar.sr.Gui
        if not radar.built then return end
        local scr = screen_size()
        local okv3, s1 = pcall(sr.Vector3, 0, 0, 0)
        local okv3b, s2 = pcall(sr.Vector3, 0, 0, 0)
        local okv3c, s3 = pcall(sr.Vector3, 0, 0, 0)
        local okuv, uv = pcall(sr.Vector2, 0, 0)
        local set_xyz = type(sr.Vector3) == 'table' and sr.Vector3.set_xyz or nil
        if not (okv3 and okv3b and okv3c and okuv and set_xyz) then return end
        -- project hostiles with the TRUE camera basis (radar up = view),
        -- Tilted-disc perspective (HUD Plus 0.2.2 WorldPose math, Lua port):
        -- vertical axis compressed by cos(tilt), far side compressed more
        -- (fov ratio) - the mockup's 3D ground-disc look.
        local pts = {}
        local cb = camera_basis()
        if cb and pl and pl.pos then
            local scale = radar.R / radar.range
            local TILTC = cfg.tilt
            for _, e in ipairs(hostiles) do
                local fc = e.dx * cb.fx + e.dy * cb.fy
                local rc = e.dx * cb.rx + e.dy * cb.ry
                -- near edge (behind view) expands, far edge compresses
                local yk = TILTC * (1 - cfg.persp * (fc / radar.range))
                pts[#pts + 1] = {
                    x = radar.cx + rc * scale,
                    y = radar.cy + fc * scale * yk,
                    d = e.d,
                }
            end
            state.radar_yaw = math.deg(math.atan2(cb.fy, cb.fx))
        end
        -- player marker: hollow green equilateral triangle, apex view-up
        -- (rebuilt per scan; static). Circumradius midway between the
        -- small-yellow and red dot radii so it reads as "you", not a mob.
        for _, id in ipairs(radar.pmark or {}) do
            pcall(Gui.destroy_triangle, radar.gui, id)
        end
        radar.pmark = {}
        local mok, mtint = pcall(sr.Color, 255, 60, 255, 80)
        if mok and mtint then
            local SMALL_R = math.max(3, math.floor(cfg.dot_r * 0.8))
            local RR = math.floor(cfg.dot_r * screen_size().h / 1440 + 0.5)
            local PT = math.max(4, math.floor((SMALL_R + RR) / 2 + 0.5))
            local PW = math.max(2, math.floor(PT * 0.42 + 0.5))
            -- concentric outer/inner triangles (orientation as shipped
            -- in 1.0.28 - user confirmed it is fine), each edge one
            -- trapezoid of two tris: corners close (the edge-offset
            -- draw left V gaps at the vertices)
            local function vtri(r)
                return {
                    { radar.cx, radar.cy + r },
                    { radar.cx + r * 0.866, radar.cy - r * 0.5 },
                    { radar.cx - r * 0.866, radar.cy - r * 0.5 },
                }
            end
            local vo, vi = vtri(PT), vtri(PT - PW)
            for j = 1, 3 do
                local a, b = vo[j], vo[j % 3 + 1]
                local c, d = vi[j], vi[j % 3 + 1]
                local tris = {
                    { a[1], a[2], b[1], b[2], d[1], d[2] },
                    { a[1], a[2], d[1], d[2], c[1], c[2] },
                }
                for _, t in ipairs(tris) do
                    set_xyz(s1, t[1], 0, t[2])
                    set_xyz(s2, t[3], 0, t[4])
                    set_xyz(s3, t[5], 0, t[6])
                    local ok, id = pcall(Gui.triangle, radar.gui, s1,
                        s2, s3, 4, mtint)
                    if ok and id ~= nil then
                        radar.pmark[#radar.pmark + 1] = id
                    end
                end
            end
            -- center pip: unambiguous "you" while keeping the hollow look
            local PR = math.max(1.5, PT * 0.22)
            for j = 0, 5 do
                local a0 = j * 2 * math.pi / 6
                local a1 = (j + 1) * 2 * math.pi / 6
                set_xyz(s1, radar.cx, 0, radar.cy)
                set_xyz(s2, radar.cx + PR * math.cos(a0), 0,
                    radar.cy + PR * math.sin(a0))
                set_xyz(s3, radar.cx + PR * math.cos(a1), 0,
                    radar.cy + PR * math.sin(a1))
                local ok, id = pcall(Gui.triangle, radar.gui, s1, s2, s3,
                    4, mtint)
                if ok and id ~= nil then
                    radar.pmark[#radar.pmark + 1] = id
                end
            end
        end
        local near = pts[1]
        state.draw_k = (state.draw_k or 0) + 1
        if state.draw_k % 32 == 1 then
            say('SCAN pts=%d cam=%s | near %s', #pts,
                state.radar_yaw and string.format('%.0f', state.radar_yaw) or 'none',
                near and string.format('%.0fm', near.d) or 'none')
        end
    end

    -- PER FRAME: re-project the last scan's hostiles with a fresh camera
    -- basis (view rotation = frame-rate smooth; enemy data stays at the
    -- scan rate so the device burden does not grow)
    local function radar_frame_dots()
        if not state.fdent then
            state.fdent = true
            say('FD ENTRY: built=%s mission=%s menu=%s plz=%s hostiles=%s ut=%s',
                tostring(radar.built), tostring(state.in_mission),
                tostring(state.menu_open),
                tostring(state.pl_pos and state.pl_pos[3]),
                tostring(#(state.hostiles or {})), tostring(state.has_ut))
        end
        if not radar.built then return end
        if not state.in_mission or state.menu_open then return end
        local pl_pos = state.pl_pos
        if not pl_pos or pl_pos[3] > 150 then return end
        local sr, Gui = radar.sr, radar.sr.Gui
        -- per-frame menu gate (the scan gate only toggles visibility)
        if cfg.menu_hide == 1 and type(sr.Window) == 'table'
            and type(sr.Window.show_cursor) == 'function' then
            local okc, shown = pcall(sr.Window.show_cursor)
            if okc and shown == true then return end
        end
        local okv3, s1 = pcall(sr.Vector3, 0, 0, 0)
        local okv3b, s2 = pcall(sr.Vector3, 0, 0, 0)
        local okv3c, s3 = pcall(sr.Vector3, 0, 0, 0)
        local okuv, uv = pcall(sr.Vector2, 0, 0)
        if not (okv3 and okv3b and okv3c and okuv) then return end
        local set_xyz = type(sr.Vector3) == 'table' and sr.Vector3.set_xyz or nil
        if not set_xyz then return end
        -- fresh pose EVERY frame: camera_tick used to run only inside
        -- the 20 Hz scan, so the per-frame re-projection reused a stale
        -- basis and dots moved at the scan rate ("not 60 Hz" bug)
        camera_tick()
        local cb = camera_basis()
        if not cb then return end
        local scr = screen_size()
        -- destroy last frame's dots, create current (update_triangle crashes
        -- this build - proven v48)
        for _, id in ipairs(radar.pool) do
            pcall(Gui.destroy_triangle, radar.gui, id)
        end
        radar.pool = {}
        local RR = math.floor(cfg.dot_r * scr.h / 1440 + 0.5)
        local SMALL_R = math.max(3, math.floor(cfg.dot_r * 0.8))
        -- frame-scoped Color cache: dozens of blips share alpha tiers,
        -- one Color object per tier per frame. Cross-frame reuse stays
        -- forbidden (built-once colors die - Radar Sweep lore).
        local cc = {}
        local function colr(a, r, g, b)
            local key = a + r * 256 + g * 65536 + b * 16777216
            local c = cc[key]
            if c == nil then
                local okc, nc = pcall(sr.Color, a, r, g, b)
                c = okc and nc or false
                cc[key] = c
            end
            return c or nil
        end
        local scale = radar.R / radar.range
        local hostiles = state.hostiles or {}
        local n = math.min(#hostiles, cfg.max_dots)
        -- scan-interval interpolation: dots advance along their
        -- scan-to-scan delta so enemy motion stays smooth at a 10 Hz
        -- scan. Lerped dots correct by the FULL player delta (their
        -- sample time trails by one interval); fresh dots by kpos of it
        local prev_by_id = state.prev_by_id
        local kpos = 0
        if state.pts_time and state.pts_dt and state.pts_dt > 0 then
            kpos = (tonumber(k.GetTickCount64()) - state.pts_time)
                / state.pts_dt
            if kpos < 0 then kpos = 0 elseif kpos > 1 then kpos = 1 end
        end
        local fdx, fdy, pdx, pdy = 0, 0, 0, 0
        local plc, plp = state.pl_cur, state.pl_prev
        if plc and plp then
            fdx, fdy = plc.x - plp.x, plc.y - plp.y
            pdx, pdy = fdx * kpos, fdy * kpos
        end
        local d1x, d1y, d1a = nil, nil, nil
        for i = 1, n do
            local e = hostiles[i]
            local dx, dy, d = e.dx, e.dy, e.d
            local pv = prev_by_id and prev_by_id[e.id] or nil
            if pv then
                dx = pv.dx + (e.dx - pv.dx) * kpos - fdx
                dy = pv.dy + (e.dy - pv.dy) * kpos - fdy
                d = pv.d + (e.d - pv.d) * kpos
            else
                dx, dy = e.dx - pdx, e.dy - pdy
            end
            local fc = dx * cb.fx + dy * cb.fy
            local rc = dx * cb.rx + dy * cb.ry
            local yk = cfg.tilt * (1 - cfg.persp * (fc / radar.range))
            local x = radar.cx + rc * scale
            local y = radar.cy + fc * scale * yk
            local alpha = math.floor(255 * (1 - d / radar.range))
            -- tiers: enemy-table structure = red hollow ring (apex on
            -- the inner arc), heavy = big red dot (12 segments),
            -- small = smaller yellow dot (6 segments)
            if i == 1 then d1x, d1y, d1a = x, y, alpha end
            local tint
            if e.ring then
                tint = colr(alpha, 255, 40, 40)
            else
                local cr, cg = 255, 40
                if not e.hv then cr, cg = 255, 224 end
                tint = colr(alpha, cr, cg, 40)
            end
            if tint then
                local SEG2, R2, RI2
                if e.ring then
                    SEG2, R2 = 16, RR
                    RI2 = RR - math.max(1.2, RR * 0.3)
                elseif e.hv then
                    SEG2, R2 = 12, RR
                else
                    SEG2, R2 = 6, SMALL_R
                end
                for j = 0, SEG2 - 1 do
                    local a0 = j * 2 * math.pi / SEG2
                    local a1 = (j + 1) * 2 * math.pi / SEG2
                    if RI2 then
                        local am = (a0 + a1) * 0.5
                        set_xyz(s1, x + RI2 * math.cos(am), 0,
                            y + RI2 * math.sin(am))
                    else
                        set_xyz(s1, x, 0, y)
                    end
                    set_xyz(s2, x + R2 * math.cos(a0), 0, y + R2 * math.sin(a0))
                    set_xyz(s3, x + R2 * math.cos(a1), 0, y + R2 * math.sin(a1))
                    local ok, id
                    if state.tri6 ~= false then
                        ok, id = pcall(Gui.triangle, radar.gui, s1, s2, s3, 5, tint)
                    end
                    if not ok then
                        ok, id = pcall(Gui.triangle, radar.gui, s1, s2, s3, 5,
                            tint, 'core/performance_hud/debug', uv, uv, uv)
                    end
                    if ok and id ~= nil then
                        radar.pool[#radar.pool + 1] = id
                    end
                end
            end
        end
        -- structures: red hollow ring, heavy-dot size (RR), same fade;
        -- player-delta corrected like fresh dots (sampled last scan)
        local structs = state.structures or {}
        local plw = state.pl_pos
        local sn = math.min(#structs, 32)
        if plw and sn > 0 then
            local TH = math.max(1.2, RR * 0.3)
            local RI = RR - TH
            local NA = 16
            for si = 1, sn do
                local b = structs[si]
                local bdx = b.x - plw[1] - pdx
                local bdy = b.y - plw[2] - pdy
                local bd2 = bdx * bdx + bdy * bdy
                if bd2 <= radar.range * radar.range then
                    local bd = math.sqrt(bd2)
                    local fc = bdx * cb.fx + bdy * cb.fy
                    local rc = bdx * cb.rx + bdy * cb.ry
                    local yk = cfg.tilt * (1 - cfg.persp * (fc / radar.range))
                    local x = radar.cx + rc * scale
                    local y = radar.cy + fc * scale * yk
                    local alpha = math.floor(255 * (1 - bd / radar.range))
                    local stint = colr(alpha, 255, 40, 40)
                    if stint then
                        for j = 0, NA - 1 do
                            local a0 = j * 2 * math.pi / NA
                            local a1 = (j + 1) * 2 * math.pi / NA
                            local am = (a0 + a1) * 0.5
                            set_xyz(s1, x + RI * math.cos(am), 0,
                                y + RI * math.sin(am))
                            set_xyz(s2, x + RR * math.cos(a0), 0,
                                y + RR * math.sin(a0))
                            set_xyz(s3, x + RR * math.cos(a1), 0,
                                y + RR * math.sin(a1))
                            local ok, id = pcall(Gui.triangle, radar.gui,
                                s1, s2, s3, 5, stint)
                            if ok and id ~= nil then
                                radar.pool[#radar.pool + 1] = id
                            end
                        end
                    end
                end
            end
        end
        -- pickups: blue solid circles (provisional - every hash gets its
        -- own icon once the user identifies them on the radar)
        -- samples: green solid triangles (approved icon table)
        local picks = state.picks or {}
        local pn = math.min(#picks, 24)
        if plw and pn > 0 then
            for pi = 1, pn do
                local pk = picks[pi]
                local pkdx = pk.x - plw[1] - pdx
                local pkdy = pk.y - plw[2] - pdy
                local pkd2 = pkdx * pkdx + pkdy * pkdy
                if pkd2 <= radar.range * radar.range then
                    local pdd = math.sqrt(pkd2)
                    local fc = pkdx * cb.fx + pkdy * cb.fy
                    local rc = pkdx * cb.rx + pkdy * cb.ry
                    local yk = cfg.tilt * (1 - cfg.persp * (fc / radar.range))
                    local x = radar.cx + rc * scale
                    local y = radar.cy + fc * scale * yk
                    local alpha = math.floor(255 * (1 - pdd / radar.range))
                    local pint = colr(alpha, 80, 255, 120)
                    if pint then
                        -- one triangle per sample, apex up
                        local R2 = SMALL_R + 1
                        set_xyz(s1, x, 0, y - R2)
                        set_xyz(s2, x - R2 * 0.87, 0, y + R2 * 0.5)
                        set_xyz(s3, x + R2 * 0.87, 0, y + R2 * 0.5)
                        local ok2, id2 = pcall(Gui.triangle, radar.gui,
                            s1, s2, s3, 5, pint)
                        if ok2 and id2 ~= nil then
                            radar.pool[#radar.pool + 1] = id2
                        end
                    end
                end
            end
        end
        -- supply boxes, per-type icons: ammo = blue triangle (apex up),
        -- grenade = blue circle, health pack = blue cross (icon table)
        local sup = state.sup or {}
        local sn2 = math.min(#sup, 24)
        if plw and sn2 > 0 then
            for si = 1, sn2 do
                local sp = sup[si]
                local sdx = sp.x - plw[1] - pdx
                local sdy = sp.y - plw[2] - pdy
                local sdd2 = sdx * sdx + sdy * sdy
                if sdd2 <= radar.range * radar.range then
                    local fc = sdx * cb.fx + sdy * cb.fy
                    local rc = sdx * cb.rx + sdy * cb.ry
                    local yk = cfg.tilt * (1 - cfg.persp * (fc / radar.range))
                    local x = radar.cx + rc * scale
                    local y = radar.cy + fc * scale * yk
                    local dd = math.sqrt(sdd2)
                    local alpha = math.floor(255 * (1 - dd / radar.range))
                    local sint = colr(alpha, 100, 180, 255)
                    if sint then
                        local R2 = SMALL_R + 1
                        if sp.res == 'b4ca4c5b922f7965' then
                            -- health pack: blue cross (icon table)
                            local T = math.max(1.2, R2 * 0.35)
                            set_xyz(s1, x - T, 0, y - R2)
                            set_xyz(s2, x + T, 0, y - R2)
                            set_xyz(s3, x + T, 0, y + R2)
                            local ok2, id2 = pcall(Gui.triangle, radar.gui,
                                s1, s2, s3, 5, sint)
                            if ok2 and id2 ~= nil then
                                radar.pool[#radar.pool + 1] = id2
                            end
                            set_xyz(s1, x - T, 0, y - R2)
                            set_xyz(s2, x + T, 0, y + R2)
                            set_xyz(s3, x - T, 0, y + R2)
                            ok2, id2 = pcall(Gui.triangle, radar.gui,
                                s1, s2, s3, 5, sint)
                            if ok2 and id2 ~= nil then
                                radar.pool[#radar.pool + 1] = id2
                            end
                            set_xyz(s1, x - R2, 0, y - T)
                            set_xyz(s2, x + R2, 0, y - T)
                            set_xyz(s3, x + R2, 0, y + T)
                            ok2, id2 = pcall(Gui.triangle, radar.gui,
                                s1, s2, s3, 5, sint)
                            if ok2 and id2 ~= nil then
                                radar.pool[#radar.pool + 1] = id2
                            end
                            set_xyz(s1, x - R2, 0, y - T)
                            set_xyz(s2, x + R2, 0, y + T)
                            set_xyz(s3, x - R2, 0, y + T)
                            ok2, id2 = pcall(Gui.triangle, radar.gui,
                                s1, s2, s3, 5, sint)
                            if ok2 and id2 ~= nil then
                                radar.pool[#radar.pool + 1] = id2
                            end
                        elseif sp.res == '79ccffd281e3f3a9' then
                            -- ammo box: blue solid triangle, apex up
                            -- (distinct from the sample's inverted triangle)
                            set_xyz(s1, x, 0, y + R2)
                            set_xyz(s2, x - R2 * 0.87, 0, y - R2 * 0.5)
                            set_xyz(s3, x + R2 * 0.87, 0, y - R2 * 0.5)
                            local ok2, id2 = pcall(Gui.triangle, radar.gui,
                                s1, s2, s3, 5, sint)
                            if ok2 and id2 ~= nil then
                                radar.pool[#radar.pool + 1] = id2
                            end
                        else
                            -- grenade box: blue solid circle
                            for j = 0, 7 do
                                local a0 = j * 2 * math.pi / 8
                                local a1 = (j + 1) * 2 * math.pi / 8
                                set_xyz(s1, x, 0, y)
                                set_xyz(s2, x + R2 * math.cos(a0), 0,
                                    y + R2 * math.sin(a0))
                                set_xyz(s3, x + R2 * math.cos(a1), 0,
                                    y + R2 * math.sin(a1))
                                local ok2, id2 = pcall(Gui.triangle, radar.gui,
                                    s1, s2, s3, 5, sint)
                                if ok2 and id2 ~= nil then
                                    radar.pool[#radar.pool + 1] = id2
                                end
                            end
                        end
                    end
                end
            end
        end
        -- identification dots: magenta = mgr 0x3326da0
        for _, spec in ipairs({ { key = 'mda0', cap = 8, cr = 240, cg = 90,
                                  cb2 = 240 } }) do
            local lst = state[spec.key] or {}
            local ln = math.min(#lst, spec.cap)
            if plw and ln > 0 then
                for li = 1, ln do
                    local pk = lst[li]
                    local pkdx = pk.x - plw[1] - pdx
                    local pkdy = pk.y - plw[2] - pdy
                    local pkd2 = pkdx * pkdx + pkdy * pkdy
                    if pkd2 <= radar.range * radar.range then
                        local pdd = math.sqrt(pkd2)
                        local fc = pkdx * cb.fx + pkdy * cb.fy
                        local rc = pkdx * cb.rx + pkdy * cb.ry
                        local yk = cfg.tilt
                            * (1 - cfg.persp * (fc / radar.range))
                        local x = radar.cx + rc * scale
                        local y = radar.cy + fc * scale * yk
                        local alpha = math.floor(255 * (1 - pdd / radar.range))
                        local pok, pint = pcall(sr.Color, alpha, spec.cr,
                            spec.cg, spec.cb2)
                        if pok and pint then
                            for j = 0, 7 do
                                local a0 = j * 2 * math.pi / 8
                                local a1 = (j + 1) * 2 * math.pi / 8
                                set_xyz(s1, x, 0, y)
                                set_xyz(s2, x + SMALL_R * math.cos(a0), 0,
                                    y + SMALL_R * math.sin(a0))
                                set_xyz(s3, x + SMALL_R * math.cos(a1), 0,
                                    y + SMALL_R * math.sin(a1))
                                local ok2, id2 = pcall(Gui.triangle, radar.gui,
                                    s1, s2, s3, 5, pint)
                                if ok2 and id2 ~= nil then
                                    radar.pool[#radar.pool + 1] = id2
                                end
                            end
                        end
                    end
                end
            end
        end
        if not state.fdlog then
            state.fdlog = true
            say('FRAME DOTS ran: n=%d pool=%d d1=(%.0f,%.0f) a=%d cb=%.2f/%.2f',
                n, #radar.pool, tonumber(d1x) or -1, tonumber(d1y) or -1,
                tonumber(d1a) or -1, cb.fx, cb.fy)
        end
    end

    -- best-effort cleanup so an error never leaves stuck radar elements
    local function radar_park()
        if not (radar and radar.gui and radar.sr) then return end
        for _, id in ipairs(radar.pool) do
            pcall(radar.sr.Gui.destroy_triangle, radar.gui, id)
        end
        radar.pool = {}
        say('RADAR parked (cleanup)')
    end

    local function probe_once()
        local inside, why = in_mission()
        if not inside then
            if why ~= state.last_wait then
                state.last_wait = why
                say('waiting: reason=%s', tostring(why))
            end
            state.mission_at = nil
            return false
        end
        state.last_wait = nil
        -- give the world 6s to finish rebuilding before any stingray call
        -- (the death of the previous-gen radar mod)
        if not state.mission_at then
            state.mission_at = tonumber(k.GetTickCount64())
        end
        local warm = tonumber(k.GetTickCount64()) - state.mission_at < 6000

        -- enemies: collect live ids with motion positions
        local list = {}
        local pos_fail = 0
        local enemies = global(0x33266c8)
        if enemies then
            -- roster id set (alive or not): merge diagnostics flag
            -- health-enemies that sit outside the AI mirror
            state.mirror_ids = {}
            local count_b = read(enemies + 0x2320, 4)
            local owners_b = read(enemies + 0x2348, 8)
            local count = count_b and u32(count_b)
            local owners = owners_b and ptr8(owners_b, 0)
            if owners and count and count > 0 and count <= 4096 then
                -- batch read the pointer array; if a region tail is unreadable
                -- the WHOLE batch fails, so fall back to per-entry reads
                local pa_b = read(owners, 8 * count)
                if not pa_b then state.batch_fail = (state.batch_fail or 0) + 1 end
                for i = 0, count - 1 do
                    -- owners[i] IS the entity pointer (one level only - the
                    -- extra deref here caused the "no dots" regression v27-v29)
                    local enemy
                    if pa_b then
                        enemy = ptr8(pa_b, i * 8)
                    else
                        local s = read(owners + i * 8, 8)
                        enemy = s and ptr8(s, 0) or nil
                    end
                    if enemy then
                        local e = read(enemy, 24)
                        if e then
                            local mids = state.mirror_ids
                            if mids then mids[u32(e, 8)] = true end
                            local alive = bit.band(e:byte(21) or 0, 3) == 1
                            if alive then
                                local eid = u32(e, 8)
                                local res = hex64(e, 0)
                                local mp = eid and motion_pos(eid)
                                if mp then
                                    list[#list + 1] = { id = eid, res = res, pos = mp }
                                    if not seen_res[res] then
                                        seen_res[res] = true
                                        say('  NEW res=%s%s', res,
                                            STRUCTURES[res] or CATALOG[res] or '')
                                    end
                                else
                                    pos_fail = pos_fail + 1
                                end
                            end
                        end
                    end
                end
            end
            state.enemies_k = (state.enemies_k or 0) + 1
            if state.enemies_k % 8 == 1 then
                say('ENEMIES count=%s owners=%s batch_fail=%s live_with_pos=%d pos_fail=%d',
                    tostring(count), tostring(owners ~= nil),
                    tostring(state.batch_fail or 0), #list, pos_fail)
                -- 1.0.27 diag: what does the alive byte hold on a client?
                -- host expects 1=alive; the client census settles it.
                if owners and count and count > 0 then
                    local h0, h1, h2, h3, hn2 = 0, 0, 0, 0, 0
                    for ci = 0, math.min(count, 256) - 1 do
                        local cs = pa_b and ptr8(pa_b, ci * 8)
                            or select(2, pcall(read, owners + ci * 8, 8))
                        local cee = cs and ptr8(cs, 0) or nil
                        local ceb = cee and read(cee, 24)
                        if ceb then
                            local cv = bit.band(ceb:byte(21) or 0, 3)
                            if cv == 0 then h0 = h0 + 1
                            elseif cv == 1 then h1 = h1 + 1
                            elseif cv == 2 then h2 = h2 + 1
                            else h3 = h3 + 1 end
                        else
                            hn2 = hn2 + 1
                        end
                    end
                    say('MC b21&3 0=%d 1=%d 2=%d 3=%d unread=%d',
                        h0, h1, h2, h3, hn2)
                end
            end
        end

        -- 1.0.27: merge health-walk live enemies into the dot list.
        -- On a client the mirror roster's alive byte never reads 1
        -- (host-only state), so the health table is the only replicated
        -- enemy source. The NEW log gains anything this lets through -
        -- same contract as the mirror path.
        local hlv = state.hlive
        if hlv and next(hlv) then
            local nowt = state.threat_k or 0
            for eid, rec in pairs(hlv) do
                if nowt - (rec.k or 0) > 60 then hlv[eid] = nil end
            end
            local have = {}
            for _, e in ipairs(list) do have[e.id] = true end
            for eid, rec in pairs(hlv) do
                if not have[eid] then
                    local mp = motion_pos(eid)
                    if mp then
                        list[#list + 1] = { id = eid, res = rec.res, pos = mp }
                        if not seen_res[rec.res] then
                            seen_res[rec.res] = true
                            say('  NEW(res) res=%s%s mirror=%s', rec.res,
                                STRUCTURES[rec.res] or CATALOG[rec.res] or '',
                                (state.mirror_ids or {})[eid] and 'Y' or 'n')
                        end
                    end
                end
            end
        end

        -- player position + facing
        local pl, pwhy = player_id()
        local pl_data = nil
        if pl then
            local fi = faction_info(pl.id)
            local bp, fwd = nil, nil
            if fi then bp, fwd = bone(pl.unit, fi.pose_node) end
            if bp then
                pl_data = { pos = bp, fwd = fwd, node = fi and fi.pose_node or nil,
                            id = pl and pl.id or nil }
                local fstr = fwd and string.format('%.2f,%.2f,%.2f', fwd[1], fwd[2], fwd[3]) or 'nil'
                state.player_k = (state.player_k or 0) + 1
                if state.player_k % 4 == 1 then
                    say('PLAYER pos=%.1f,%.1f,%.1f fwd=%s', bp[1], bp[2], bp[3], fstr)
                end
            else
                say('PLAYER bone FAIL: %s', tostring(pwhy))
            end
        else
            say('PLAYER unresolved: %s', tostring(pwhy))
        end

        -- P0f view-float scan (SHELVED with the radar; flip to re-enable)
        state.scan_k2 = (state.scan_k2 or 0) + 1
        if false and pl and pl.ei and state.scan_k2 % 2 == 0 then
            scan_view(state.scan_k2, scan_regions(pl, pl.ei), state.radar_yaw)
        end

        -- bone azimuth scan (SHELVED with the radar)
        state.scan_k = (state.scan_k or 0) + 1
        if false and pl and state.scan_k % 16 == 1 then
            local parts = {}
            for node = 0, 95 do
                local _, nf = bone(pl.unit, node)
                if nf then
                    parts[#parts + 1] = string.format('%d:%.0f', node,
                        (math.deg(math.atan2(nf[3], nf[1])) % 360))
                end
            end
            say('BONEAZ %s', #parts > 0 and table.concat(parts, ' ') or 'none')
        end

        -- one scan feeds the 100m radar ring; alive map walked in chunks
        state.in_mission = true
        state.threat_k = (state.threat_k or 0) + 1
        health_alive_step()
        -- static layers (structures/samples/supplies) refresh every 5th
        -- tick (500ms): they do not move, only the enemy scan needs the
        -- 100ms cadence (1.1.0 perf pass)
        local slow = (state.threat_k % 5) == 1
        if slow then
        -- structure markers: the health walk is chunked, so cached
        -- positions survive between visits (60 scans ~= 6 s TTL) and
        -- destroyed structures expire instead of sticking forever
        local blist = {}
        local tk = state.threat_k or 0
        for eid, b in pairs(state.bld_cache or {}) do
            if b.x and tk - b.k <= 60 and (state.amap or {})[eid] ~= false then
                blist[#blist + 1] = { id = eid, x = b.x, y = b.y }
            end
        end
        -- hole/nest manager: the structure family has its own component
        -- manager; the health walk never sees holes (spike-proven). Same
        -- eid may also sit in the health cache - dedup by id.
        -- hole/nest manager: render ALL STRUCTURE_SET matches (the seal
        -- filter from 1.0.24 is REVERTED - it was built on a misobservation;
        -- per-hole diagnostics below now record why anything is missing)
        local smgr_p = global(0x33265c8)
        if smgr_p then
            local hh = read(smgr_p + 8, 16)
            local scnt = hh and u32(hh, 12)
            local he_b = read(smgr_p + 0x40, 8)
            local he = he_b and ptr8(he_b, 0) or nil
            if scnt and scnt >= 1 and scnt <= 4096 and he then
                local have = {}
                for _, b in ipairs(blist) do have[b.id] = true end
                local win = read(he, 8 * math.min(scnt, 64))
                if win then
                    for i = 0, math.min(scnt, 64) - 1 do
                        local ob = ptr8(win, i * 8)
                        local e = ob and read(ob, 24)
                        if e then
                            local se_res = hex64(e, 0)
                            local se_id = u32(e, 8)
                            local mp = motion_pos(se_id)
                            local verdict = 'ok'
                            if not STRUCTURE_SET[se_res] then
                                verdict = 'res-not-in-set'
                            elseif have[se_id] then
                                verdict = 'dup'
                            elseif not mp then
                                verdict = 'motion-miss'
                            end
                            local sig = verdict .. '|' .. se_res
                            if state.hseen[se_id] ~= sig then
                                state.hseen[se_id] = sig
                                say('HOLE id=%u res=%s %s%s', se_id, se_res,
                                    verdict,
                                    mp and string.format(' %.1f,%.1f,%.1f',
                                        mp[1], mp[2], mp[3]) or '')
                            end
                            -- 1.0.27: a health-tracked structure whose
                            -- hp hit 0 keeps its motion entry on a client,
                            -- so motion presence alone renders dead rings
                            -- forever. The health-table death signal is
                            -- the strict hp==0 the fast-destroy pass
                            -- already trusts (no compound-false kills).
                            if verdict == 'ok'
                                and (state.struct_dead or {})[se_id] then
                                verdict = 'hp-dead'
                            end
                            if verdict == 'ok' then
                                blist[#blist + 1] =
                                    { id = se_id, x = mp[1], y = mp[2] }
                                have[se_id] = true
                            end
                        end
                    end
                end
            end
        end
        state.structures = blist
        -- SAMPLE manager (user-confirmed 1.0.8: every marker it drew was
        -- a sample; its 6-8 res types are sample tiers). Picked samples
        -- vanish from the manager, so the per-scan enumeration is also
        -- the death check.
        local pmgr = mgr_entities(0x33267c8, 64)
        local picks = {}
        if pmgr and pl_data and pl_data.pos then
            for _, pe in ipairs(pmgr) do
                local mp = motion_pos(pe.id)
                if mp then
                    local dx = mp[1] - pl_data.pos[1]
                    local dy = mp[2] - pl_data.pos[2]
                    picks[#picks + 1] = { id = pe.id, res = pe.res,
                                          x = mp[1], y = mp[2],
                                          d2 = dx * dx + dy * dy }
                end
            end
            -- render the NEAREST dozen: roster order once hid a pickup
            -- the user stood next to (1.0.7 - first-12 slice was all far)
            table.sort(picks, function(a, b) return a.d2 < b.d2 end)
        end
        state.picks = picks
        -- discoverable supply boxes (hashlist naming, RESEARCH 11.14):
        --   79ccffd281e3f3a9 ammo_box / 97af34fbf093409c grenade_box /
        --   b4ca4c5b922f7965 health_pack - managers 0x3326b28 + 0x3326b40
        local sup = {}
        local sup_have = {}
        -- whitelist: these two managers hold the whole fac_helldivers
        -- equipment family (support weapons, fuel barrels, event samples,
        -- destructible cars...) - only the three supply boxes render
        local SUP_OK = {
            ['79ccffd281e3f3a9'] = true, -- ammo box
            ['97af34fbf093409c'] = true, -- grenade box
            ['b4ca4c5b922f7965'] = true, -- health pack
        }
        for _, mrva in ipairs({ 0x3326b28, 0x3326b40 }) do
            -- enumerate the FULL array (258+93 entities): a 128-slot cap
            -- truncated in manager order, so boxes behind slot 128 never
            -- reached the distance sort - the nearest ones went missing
            local ents = mgr_entities(mrva, 4096)
            if ents then
                for _, se in ipairs(ents) do
                    if not sup_have[se.id] and SUP_OK[se.res or ''] then
                        sup_have[se.id] = true
                        local mp = motion_pos(se.id)
                        if mp and pl_data and pl_data.pos then
                            local dx = mp[1] - pl_data.pos[1]
                            local dy = mp[2] - pl_data.pos[2]
                            sup[#sup + 1] = { id = se.id, res = se.res,
                                              x = mp[1], y = mp[2],
                                              d2 = dx * dx + dy * dy }
                        end
                    end
                end
            end
        end
        table.sort(sup, function(a, b) return a.d2 < b.d2 end)
        state.sup = sup
        end -- slow gate
        if state.threat_k % 32 == 2 then
            local rset = {}
            for _, s in ipairs(state.sup or {}) do
                rset[s.res:sub(1, 6)] = true
            end
            local rl = {}
            for r in pairs(rset) do rl[#rl + 1] = r end
            say('SUP n=%d res=%s', #(state.sup or {}),
                table.concat(rl, ','))
        end
        local hostiles, dead, nhv = collect_hostiles(list, pl_data,
            state.amap or {}, radar.range)
        state.hostiles = hostiles
        state.pl_pos = pl_data and pl_data.pos or nil
        -- horizontal player history: the per-frame interpolation must
        -- cancel player movement or dots swim while sprinting
        state.pl_prev = state.pl_cur
        state.pl_cur = pl_data and pl_data.pos
            and { x = pl_data.pos[1], y = pl_data.pos[2] } or nil
        -- per-id previous positions for the per-frame interpolation
        local by_id = {}
        for _, e in ipairs(hostiles) do
            by_id[e.id] = { dx = e.dx, dy = e.dy, d = e.d }
        end
        state.prev_by_id = state.cur_by_id
        state.cur_by_id = by_id
        local nowk = tonumber(k.GetTickCount64())
        state.pts_dt = state.pts_time and (nowk - state.pts_time) or 50
        if state.pts_dt < 1 then state.pts_dt = 50 end
        state.pts_time = nowk
        if state.threat_k % 32 == 1 then
            say('RADAR hostiles=%d dead=%d heavy=%d structs=%d picks=%d runs=%d',
                #hostiles, dead, nhv, #(state.structures or {}),
                #(state.picks or {}), state.runs)
            local spicks = state.picks or {}
            local roster = {}
            for i = 1, math.min(8, #spicks) do
                roster[#roster + 1] = string.format('%s:%u:%.0fm',
                    spicks[i].res:sub(1, 4), spicks[i].id,
                    math.sqrt(spicks[i].d2 or 0))
            end
            local uroster = {}
            for i = 1, math.min(6, #(state.unk or {})) do
                local uk = state.unk[i]
                uroster[#uroster + 1] = string.format('%s:%.0fm',
                    uk.res:sub(1, 6), math.sqrt(uk.d2 or 0))
            end
            say('PICK n=%d near8 %s', #spicks,
                table.concat(roster, ' '))
        end
        -- retained mode: display gate + per-scan draw. The game shows the
        -- cursor whenever a menu is open - that is our menu signal.
        local show = pl_data ~= nil
            and pl_data.pos and pl_data.pos[3] < 150
        if show and cfg.menu_hide == 1 then
            local sr0 = rawget(_G, 'stingray')
            if type(sr0) == 'table' and type(sr0.Window) == 'table'
                and type(sr0.Window.show_cursor) == 'function' then
                local okc, shown = pcall(sr0.Window.show_cursor)
                if okc and shown == true then show = false end
            end
        end
        if show ~= state.last_show then
            state.last_show = show
            if radar_setup() then
                pcall(radar.sr.Gui.set_visible, radar.gui, show)
            end
            say('RADAR %s', show and 'shown' or 'hidden')
        end
        if show and not warm and radar_setup() then
            camera_tick()
            radar_build_ring()
            radar_draw_dots(hostiles, pl_data)
        end
        return true
    end

    -- ------------------------- the MODS tab -------------------------
    -- Optional ModOptionsMenu dependency (Radar Sweep v2.6 pattern): poll
    -- for _G.ModOptionsMenu once per tick until it speaks api 1, register
    -- our knobs, apply changes live (geometry keys reset radar.built so the
    -- next scan recomputes cx/cy/R), and write the cfg file 2 s after the
    -- last change. Labels are Chinese + English: High Alert ships Chinese
    -- labels into the same widgets and they render fine.
    local MENU_NAME = "LIBERTY RADAR"
    local MENU_SPEC = {
        { key = 'range', type = 'slider', min = 20, max = 200, step = 5,
          label = '探测半径 / Detection Range' },
        { key = 'scale', type = 'slider', min = 0.5, max = 2.0, step = 0.05,
          label = '雷达大小 / Radar Size', geo = true },
        { key = 'cx_frac', type = 'slider', min = 0.1, max = 0.9, step = 0.01,
          label = '水平位置 / Position X', geo = true },
        { key = 'cy_frac', type = 'slider', min = 0.1, max = 0.9, step = 0.01,
          label = '垂直位置 / Position Y', geo = true },
        { key = 'tilt', type = 'slider', min = 0.3, max = 1.0, step = 0.05,
          label = '俯视压缩 / Tilt' },
        { key = 'persp', type = 'slider', min = 0, max = 0.5, step = 0.05,
          label = '透视压缩 / Perspective' },
        { key = 'dot_r', type = 'slider', min = 3, max = 10, step = 1,
          label = '点大小 / Dot Size' },
        { key = 'interval', type = 'slider', min = 30, max = 250, step = 10,
          label = '扫描间隔ms / Scan Interval' },
        { key = 'max_dots', type = 'slider', min = 8, max = 96, step = 4,
          label = '最大标记 / Max Blips' },
        { key = 'menu_hide', type = 'toggle',
          label = '菜单时隐藏 / Hide in Menus' },
    }
    local MENU = { done = false, live = nil }
    local MENU_LAST = {}
    local menu_dirty, menu_dirty_at, menu_poll_at = false, 0, 0

    local function write_cfg()
        local la = os.getenv('LOCALAPPDATA') or ''
        local path = la .. '\\CowboyBingus\\Helldivers2\\LibertyRadar.cfg'
        local w = io.open(path, 'w')
        if not w then return end
        w:write('# Liberty Radar cfg - edits need a game restart\n')
        w:write('# menu changes apply live and overwrite this file\n')
        local order = { 'range', 'scale', 'cx_frac', 'cy_frac', 'tilt',
                        'persp', 'dot_r', 'interval', 'max_dots', 'menu_hide' }
        for _, k in ipairs(order) do
            w:write(string.format('%s=%s\n', k, tostring(cfg[k])))
        end
        w:close()
    end

    local function menu_apply(key, value)
        local spec
        for _, s in ipairs(MENU_SPEC) do
            if s.key == key then spec = s break end
        end
        if not spec then return false end
        if spec.type == 'toggle' then
            value = value and true or false
            local nv = value and 1 or 0
            if cfg[key] == nv then return false end
            MENU_LAST[key] = value
            cfg[key] = nv
        else
            value = tonumber(value)
            if value == nil or value ~= value then return false end
            if value < spec.min then value = spec.min end
            if value > spec.max then value = spec.max end
            if cfg[key] == value then return false end
            MENU_LAST[key] = value
            cfg[key] = value
        end
        if spec.geo then radar.built = false end
        -- range is consumed as radar.range (copied once at build time) -
        -- sync it or the slider never takes effect
        if key == 'range' and radar then
            radar.range = tonumber(cfg[key]) or radar.range
        end
        menu_dirty, menu_dirty_at = true, tonumber(k.GetTickCount64())
        say('MENU %s = %s', key, tostring(cfg[key]))
        return true
    end

    local function menu_step(now)
        if state.done then return end
        if not MENU.done then
            local MM = rawget(_G, 'ModOptionsMenu')
            if type(MM) ~= 'table' or MM.api ~= 1
                or type(MM.register_option) ~= 'function'
                or type(MM.get) ~= 'function' then return end
            MENU.done, MENU.live = true, MM
            local rejected = 0
            for _, spec in ipairs(MENU_SPEC) do
                local id = 'liberty_radar_' .. spec.key
                local default = cfg[spec.key]
                if spec.type == 'toggle' then
                    default = default == 1
                end
                local ok, err = pcall(MM.register_option, id, {
                    type = spec.type, mod = MENU_NAME, label = spec.label,
                    min = spec.min, max = spec.max, step = spec.step,
                    default = default,
                })
                if not ok then
                    rejected = rejected + 1
                    say('MENU register fail %s: %s', spec.key, tostring(err))
                end
            end
            say('MENU registered %d options (%d rejected)', #MENU_SPEC, rejected)
            if type(MM.on_change) == 'function' then
                for _, spec in ipairs(MENU_SPEC) do
                    local id = 'liberty_radar_' .. spec.key
                    pcall(MM.on_change, id, function(value)
                        pcall(menu_apply, spec.key, value)
                    end)
                end
            end
            return
        end
        -- poll fallback: a menu whose on_change never fires is still readable
        if MENU.live and now - menu_poll_at >= 2000 then
            menu_poll_at = now
            for _, spec in ipairs(MENU_SPEC) do
                local ok, v = pcall(MENU.live.get, 'liberty_radar_' .. spec.key)
                if ok then pcall(menu_apply, spec.key, v) end
            end
        end
        if menu_dirty and now - menu_dirty_at >= 2000 then
            menu_dirty = false
            write_cfg()
        end
    end

    -- per-tick cost self-measurement (QPC), reported every 32 ticks
    local qpc = ffi.new('int64_t[1]')
    local qpf_s = ffi.new('int64_t[1]')
    k.QueryPerformanceFrequency(qpf_s)
    local qpf = qpf_s[0] > 0 and tonumber(qpf_s[0]) or nil

    local previous_update = update
    local last = 0
    local MAX_RUNS = 1000000000
    update = function(...)
        local r = previous_update(...)
        local f_t0
        if qpf then
            k.QueryPerformanceCounter(qpc)
            f_t0 = tonumber(qpc[0])
        end
        local fok, ferr = pcall(radar_frame_dots)
        if qpf and f_t0 then
            k.QueryPerformanceCounter(qpc)
            local now_q = tonumber(qpc[0])
            local fus = (now_q - f_t0) * 1e6 / qpf
            state.f_n = (state.f_n or 0) + 1
            state.f_sum = (state.f_sum or 0) + fus
            if fus > (state.f_worst or 0) then state.f_worst = fus end
            if state.f_qprev then
                state.f_dt = (state.f_dt or 0) + (now_q - state.f_qprev) / qpf
                state.f_dtn = (state.f_dtn or 0) + 1
            end
            state.f_qprev = now_q
            if state.f_n >= 128 then
                local dt = (state.f_dt or 0) / math.max(1, state.f_dtn or 1)
                say('FRAMEC avg=%.0fus worst=%.0fus dt=%.1fms (~%.0f fps) n=%d',
                    state.f_sum / state.f_n, state.f_worst, dt * 1000,
                    dt > 0 and 1 / dt or 0, state.f_n)
                state.f_n, state.f_sum, state.f_worst = 0, 0, 0
                state.f_dt, state.f_dtn, state.f_qprev = 0, 0, nil
            end
        end
        if not fok and not state.ferrlog then
            state.ferrlog = true
            say('FD ERR: %s', tostring(ferr))
        end
        -- menu hiding is handled by the Window.show_cursor gate in the scan;
        -- no manual key toggle (an ESC latch stuck the radar hidden)
        local passed, why = pcall(function()
            if state.done then return end
            local now = tonumber(k.GetTickCount64())
            pcall(menu_step, now)
            if now - last < (cfg.interval or 50) then return end
            last = now
            local t0
            if qpf then
                k.QueryPerformanceCounter(qpc)
                t0 = tonumber(qpc[0])
            end
            local ran = probe_once()
            if ran and qpf and t0 then
                k.QueryPerformanceCounter(qpc)
                local us = (tonumber(qpc[0]) - t0) * 1e6 / qpf
                state.cost_n = (state.cost_n or 0) + 1
                state.cost_sum = (state.cost_sum or 0) + us
                if us > (state.cost_worst or 0) then state.cost_worst = us end
                if state.cost_n >= 32 then
                    say('COST avg=%.0fus worst=%.0fus over %d ticks (~%.1f ms/s)',
                        state.cost_sum / state.cost_n, state.cost_worst, state.cost_n,
                        state.cost_sum / state.cost_n * 4 / 1000)
                    state.cost_n, state.cost_sum, state.cost_worst = 0, 0, 0
                end
            end
            if ran then
                state.runs = state.runs + 1
                state.status = 'probe_run_' .. state.runs
                if state.runs >= MAX_RUNS then
                    state.done = true
                    say('PROBE COMPLETE after %d runs', state.runs)
                end
            end
        end)
        if not passed then
            state.done = true
            state.status = 'probe_error'
            say('PROBE ERROR: %s', tostring(why))
            pcall(radar_park)
        end
        return r
    end
    state.status = 'loaded'
    say('Liberty Radar probe v%s loaded; interval=%dms max_runs=%d', state.version, cfg.interval or 50, MAX_RUNS)
    say('Liberty Radar: camera-yaw radar, 100m ring, hostiles only; warning duties moved to High Alert')
end)

if not ok then
    state.status = 'disabled'
    state.done = true
    say('PROBE DISABLED: %s', tostring(err))
end
