-- Shiplex Noise
-- Noesis

--sn noise
srand(0)
local s_noise_p = {}
for i = 1, 512 do
    s_noise_p[i] = flr(rnd(256))
end
local s_noise_g = { { 1, 1 }, { 1, -1 }, { -1, 1 }, { -1, 0 }, { -1, -1 }, { 1, -1 }, { 1, -1 }, { 1, 0 } }
function s_noise_cb(x, y, z)
    local t = .5 - x * x - y * y
    if (t < 0) return 0
    return t ^ 4 * (s_noise_g[z + 1][1] * x + s_noise_g[z + 1][2] * y)
end
function simplex(x, y)
    local g = .2113
    local s = (x + y) * .366
    local i, j = flr(x + s), flr(y + s)
    local t = (i + j) * g
    local x0, y0 = x - (i - t), y - (j - t)
    local i1 = 0
    j1 = 1
    if (x0 > y0) i1 = 1
    j1 = 0
    local x1 = x0 - i1 + g
    local y1 = y0 - j1 + g
    local x2 = x0 - 1 + 2 * g
    local y2 = y0 - 1 + 2 * g
    local u = i & 255
    local v = j & 255
    return 70 * (s_noise_cb(x0, y0, s_noise_p[u + s_noise_p[v + 1]] % 8) + s_noise_cb(x1, y1, s_noise_p[u + i1 + s_noise_p[v + j1 + 1]] % 8) + s_noise_cb(x2, y2, s_noise_p[u + 1 + s_noise_p[v + 2]] % 8))
end
