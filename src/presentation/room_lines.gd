class_name RoomLines
extends Node2D
## M013: a few words over the heads of people in a room - the regulars taking
## a win or a loss, Leo calling the wheel, two of them passing the time. A
## small pool of M012's OverheadLine: one line a person at a time (a new
## line from someone already speaking replaces theirs), at most POOL at once,
## gone after a few seconds. Presentation only.

const POOL := 4

var _lines: Array[OverheadLine] = []


func setup(font: Font) -> void:
	name = "RoomLines"
	for i in POOL:
		var l := OverheadLine.new()
		add_child(l)
		l.setup(font)
		_lines.append(l)


## Says `text` over `who` (replacing what they were saying; the oldest line
## gives way if every line is in use).
func say(who: Node2D, text: String) -> void:
	if who == null or text == "":
		return
	var pick: OverheadLine = null
	for l in _lines:
		if l.visible and l.speaker == who:
			pick = l
			break
	if pick == null:
		for l in _lines:
			if not l.visible:
				pick = l
				break
	if pick == null:
		pick = _lines[0]
		for l in _lines:
			if l.left < pick.left:
				pick = l
	pick.say(who, text)


## What `who` is saying now ("" if nothing).
func line_of(who: Node2D) -> String:
	for l in _lines:
		if l.visible and l.speaker == who:
			return l.label.text
	return ""


func speaking() -> int:
	return _lines.filter(func(l: OverheadLine) -> bool: return l.visible).size()


func hush_all() -> void:
	for l in _lines:
		l.hush()
