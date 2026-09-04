function get_tile(pos)
	return mget(
		round(pos.x),
		round(pos.y)
	)
end

function get_floor(pos)
	return mget(
		round(pos.x),
		pos.y+1
	)
end

function get_ceiling(pos)
	return mget(
		round(pos.x),
		ceil(pos.y-1)
	)
end

function get_left(pos)
	return mget(
		ceil(pos.x-1),
		round(pos.y)
	)
end

function get_right(pos)
	return mget(
		pos.x+1,
		round(pos.y)
	)
end
