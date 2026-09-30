--[[$const]] DEBUG_DEFAULT_COLOR = 2

debug = {
    color = DEBUG_DEFAULT_COLOR,
    points = {},
    lines = {},
    arrows = {},
    rects = {},
    text = {}
}

-- types of things to draw: points/circles, arrows, lines, rect, text

function debug.point(x, y)
    add(debug.points, { x, y, debug.color })
end
function debug.sprite_point(x, y)
    debug.point(x * 8 + 3, y * 8 + 3)
end

function debug.line(x, y, x2, y2)
    add(debug.lines, { x, y, x2, y2, debug.color })
end
function debug.arrow(x, y, x2, y2)
    add(debug.arrows, { x, y, x2, y2, debug.color })
end
function debug.rect(x, y, x2, y2)
    add(debug.rects, { x, y, x2, y2, debug.color })
end
function debug.print(text, x, y)
    add(debug.text, { text, x, y, debug.color })
end

function debug.draw()
    for p in all(debug.points) do
        circ(p[1], p[2], 1, p[3])
    end
    for l in all(debug.lines) do
        line(l[1], l[2], l[3], l[4], l[5])
    end
    for a in all(debug.arrows) do
        line(a[1], a[2], a[3], a[4], a[5])
        circ(a[3], a[4], 2, a[5])
    end
    for r in all(debug.rects) do
        rect(r[1], r[2], r[3], r[4], r[5])
    end
    for t in all(debug.text) do
        print(t[1], t[2], t[3], t[4])
    end
    debug.points = {}
    debug.lines = {}
    debug.arrows = {}
    debug.rects = {}
    debug.text = {}
end
