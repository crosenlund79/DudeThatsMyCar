class_name RouletteLayout
extends RefCounted
## The wheel table's betting layout as geometry (pure, no scene), in layout
## px from its top-left corner: the zero down the left, twelve columns of
## three numbers (3 at the top of the first, 1 at the bottom, 36 at the top
## right), the three "2 to 1" boxes for the columns at the right end, the
## dozens below and the even-money boxes below them - the standard layout
## turned on its side. `bet_at` says which bet a point is (a number's middle,
## the line between two numbers for a split, a crossing for a corner, the
## bottom edge of a column of three for a street, of two for a line, the
## zero's edge for 0-1-2, 0-2-3 and the first four); `anchor` where a bet's
## chips sit; `cell` the box of a number. The card table's view scales it.

## A number's box, the zero's width, the outside rows' height.
const W := 40.0
const H := 50.0
const ZERO := 40.0
const ROW := 36.0
## How near a line (a fraction of a box) a point counts as on it.
const EDGE := 0.2

const SIZE := Vector2(ZERO + 13.0 * W, 3.0 * H + 2.0 * ROW)
const EVEN_MONEY := ["low", "even", "red", "black", "odd", "high"]


static func number_at(col: int, row: int) -> int:
	return 3 * col + (3 - row)


## The box of number n (the zero's tall box for 0).
static func cell(n: int) -> Rect2:
	if n == 0:
		return Rect2(0, 0, ZERO, 3.0 * H)
	var col := (n - 1) / 3
	var row := 2 - (n - 1) % 3
	return Rect2(ZERO + col * W, row * H, W, H)


## The box of an outside bet ("column:k", "dozen:k", "red", ...).
static func outside_cell(key: String) -> Rect2:
	var kind := Roulette.kind_of(key)
	match kind:
		"column":
			var k := key.get_slice(":", 1).to_int()
			return Rect2(ZERO + 12.0 * W, (3 - k) * H, W, H)
		"dozen":
			var k2 := key.get_slice(":", 1).to_int()
			return Rect2(ZERO + (k2 - 1) * 4.0 * W, 3.0 * H, 4.0 * W, ROW)
	var i := EVEN_MONEY.find(kind)
	if i < 0:
		return Rect2()
	return Rect2(ZERO + i * 2.0 * W, 3.0 * H + ROW, 2.0 * W, ROW)


## The bet a point on the layout stands for ("" for none).
static func bet_at(p: Vector2) -> String:
	if p.x < 0.0 or p.y < 0.0 or p.x > SIZE.x or p.y > SIZE.y:
		return ""
	var grid_bottom := 3.0 * H
	if p.y >= grid_bottom + EDGE * H:
		if p.x < ZERO:
			return ""
		if p.y < grid_bottom + ROW:
			var k := int((p.x - ZERO) / (4.0 * W)) + 1
			return "dozen:%d" % k if k <= 3 else ""
		var i := int((p.x - ZERO) / (2.0 * W))
		return EVEN_MONEY[i] if i < 6 else ""
	if p.x >= ZERO + 12.0 * W:
		if p.y >= grid_bottom:
			return ""
		return "column:%d" % (3 - int(p.y / H))
	if p.x < ZERO - EDGE * W:
		return "straight:0" if p.y < grid_bottom else ""
	# the number grid, its lines and its bottom edge
	var fx_all := (p.x - ZERO) / W
	var col := clampi(int(floor(fx_all)), 0, 11)
	var fx := fx_all - col
	var left := fx < EDGE
	var right := fx > 1.0 - EDGE and col < 11
	if p.y >= grid_bottom - EDGE * H:
		# the outer edge under a column of three: a street; between two columns: a line
		if left and col == 0:
			return "corner:0-1-2-3"
		if left:
			return _line(col - 1)
		if right:
			return _line(col)
		return "street:%d-%d-%d" % [3 * col + 1, 3 * col + 2, 3 * col + 3]
	var row := clampi(int(p.y / H), 0, 2)
	var fy := p.y / H - row
	var top := fy < EDGE and row > 0
	var bottom := fy > 1.0 - EDGE and row < 2
	var n := number_at(col, row)
	if left and col == 0 and (top or bottom):
		# where the zero meets two numbers: 0-2-3 or 0-1-2
		var upper := row - 1 if top else row
		return "street:0-1-2" if upper == 1 else "street:0-2-3"
	if (left or right) and (top or bottom):
		var c0 := col - 1 if left else col
		var r0 := row - 1 if top else row
		var a := number_at(c0, r0 + 1)  # the lowest of the four
		return "corner:%d-%d-%d-%d" % [a, a + 1, a + 3, a + 4]
	if left:
		return "split:0-%d" % n if col == 0 else "split:%d-%d" % [n - 3, n]
	if right:
		return "split:%d-%d" % [n, n + 3]
	if top:
		return "split:%d-%d" % [n, n + 1]
	if bottom:
		return "split:%d-%d" % [n - 1, n]
	return "straight:%d" % n


static func _line(col: int) -> String:
	var a := 3 * col + 1
	return "line:%d-%d-%d-%d-%d-%d" % [a, a + 1, a + 2, a + 3, a + 4, a + 5]


## Where a bet's chips sit on the layout.
static func anchor(key: String) -> Vector2:
	var kind := Roulette.kind_of(key)
	if not kind in Roulette.INSIDE:
		return outside_cell(key).get_center()
	var nums := Roulette.covers(key)
	if nums.is_empty():
		return Vector2.ZERO
	match kind:
		"straight":
			return cell(nums[0]).get_center()
		"street":
			if nums[0] == 0:
				return Vector2(ZERO, H * (1.0 if nums == [0, 2, 3] else 2.0))
			return Vector2(cell(nums[0]).get_center().x, 3.0 * H)
		"line":
			return Vector2(ZERO + ((nums[0] - 1) / 3 + 1) * W, 3.0 * H)
		"corner":
			if nums[0] == 0:
				return Vector2(ZERO, 3.0 * H)
		"split":
			if nums[0] == 0:
				return Vector2(ZERO, cell(nums[1]).get_center().y)
	var sum := Vector2.ZERO
	for n in nums:
		sum += cell(n).get_center()
	return sum / nums.size()
