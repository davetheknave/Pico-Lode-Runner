function draw_shimmer(time, offsetX, offsetY)
    local timeScale = 200
    time += timeScale
    local range = 3
    local threshold = abs(((time % timeScale) / timeScale) - 0.5) * 0.5 + 0.3
    for y = 0, 15 do
        for x = 0, 15 do
            local tile = mget(112 + x, 048 + y)
            if simplex((x * 400 * flr(time / 200)), y * 4) > threshold then
                tile += 4
            end
            spr(tile, x * 8 + offsetX, y * 8 + offsetY)
        end
    end
end
