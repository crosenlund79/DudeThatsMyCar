extends SceneTree
## Writes docs/ASSET_SPECS.md from AssetCatalog (the authoritative contract):
##   godot --headless --path . -s tests/support/asset_specs_writer.gd
## tests/unit/test_asset_specs_doc.gd checks the file stays in step.

const OUT := "res://docs/ASSET_SPECS.md"
const KIND_TEXT := {
	"sprite": "image, scaled to its display size",
	"sheet": "horizontal strip of equal frames",
	"tile": "seamless in both directions",
	"strip": "seamless left-right, drawn along a line",
	"facade": "seamless left-right wall: top half one upper storey, bottom half the ground storey",
	"light": "additive night light; transparent where dark",
}


func _initialize() -> void:
	var f := FileAccess.open(OUT, FileAccess.WRITE)
	f.store_string(render())
	f.close()
	print("wrote ", OUT)
	quit()


static func render() -> String:
	var lines: Array[String] = []
	lines.append("# Replaceable assets — Chicago, 1932")
	lines.append("")
	lines.append("Generated from `src/assets/asset_catalog.gd` (the authoritative contract) by")
	lines.append("`tests/support/asset_specs_writer.gd`. Override rules: `assets/README.md`.")
	lines.append("")
	lines.append("Put your file at the **override path** inside `custom/` (the project folder while developing;")
	lines.append("next to the executable in an exported Windows/Linux game). Restart the game to see it. Any")
	lines.append("resolution works if you keep the template's **aspect ratio, orientation and layout**; a")
	lines.append("missing or invalid file falls back to the packaged `template_` image. A facade's `_lit`")
	lines.append("image is its window light at night and is replaced separately. Cars and people face")
	lines.append("**right** (+X). Facades repeat every %d world px along a wall." % int(AssetCatalog.FACADE_REPEAT))
	lines.append("")
	lines.append("## Graphics (PNG)")
	lines.append("")
	lines.append("| Logical name | Override path | Template px | Kind | In the world | Notes |")
	lines.append("| --- | --- | --- | --- | --- | --- |")
	var names := AssetCatalog.SPECS.keys()
	names.sort()
	for n in names:
		var s: Dictionary = AssetCatalog.SPECS[n]
		var size: Vector2i = s.template_size
		var world := ""
		match s.kind:
			"tile":
				world = "%d px per repeat" % int(s.tile_world_size)
			"strip":
				world = "%d px wide" % int(s.strip_width)
			"facade":
				world = "%d px per repeat" % int(AssetCatalog.FACADE_REPEAT)
			"sheet":
				world = "%d frames, each %dx%d" % [s.frames, int(s.display_size.x), int(s.display_size.y)]
			_:
				if s.has("display_size"):
					world = "%dx%d" % [int(s.display_size.x), int(s.display_size.y)]
				else:
					world = "matches its facade"
		lines.append("| `%s` | `custom/graphics/%s.png` | %dx%d | %s (%s) | %s | %s |" % [n, n, size.x, size.y, s.kind,
			KIND_TEXT[s.kind], world, s.notes])
	lines.append("")
	lines.append("## Audio (OGG, WAV or MP3)")
	lines.append("")
	lines.append("Loops repeat over the whole file, so keep a loop's two ends matching (or both quiet). The defaults are")
	lines.append("Claude-made `template_` sounds, except the Copper Owl's song and Danny's monologue: the user's recordings,")
	lines.append("shipped under their own names (originals untouched in `assets/audio/_inbox/`).")
	lines.append("")
	lines.append("| Logical name | Override path | Default | Loops | Bus | Notes |")
	lines.append("| --- | --- | --- | --- | --- | --- |")
	var sounds := AssetCatalog.AUDIO.keys()
	sounds.sort()
	for n in sounds:
		var a: Dictionary = AssetCatalog.AUDIO[n]
		var packaged := AssetResolver.audio_fallback_path(n).get_file()
		lines.append("| `%s` | `custom/audio/%s.ogg` (or .wav / .mp3) | `%s` | %s | %s | %s |" % [n, n, packaged, "yes" if a.loop else "no",
			a.bus, a.notes])
	lines.append("")
	return "\n".join(lines)
