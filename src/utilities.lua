function get_tile(pos)
	return mget(
		round(pos.x),
		round(pos.y)
	)
end

function get_floor(pos)
	return {
		round(pos.x),
		pos.y + 1
	}
end

function get_floor_left(pos)
	return {
		round(pos.x) - 1,
		pos.y + 1
	}
end
function get_floor_right(pos)
	return {
		round(pos.x) + 1,
		pos.y + 1
	}
end

function get_ceiling(pos)
	return {
		round(pos.x),
		ceil(pos.y - 1)
	}
end

function get_left(pos)
	return {
		ceil(pos.x - 1),
		round(pos.y)
	}
end

function get_right(pos)
	return {
		pos.x + 1,
		round(pos.y)
	}
end

function round(value)
	return value >= 0 and flr(value + 0.5) or ceil(value - 0.5)
end
