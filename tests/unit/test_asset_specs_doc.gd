extends GutTest
## docs/ASSET_SPECS.md is generated from AssetCatalog and must stay in step
## (regenerate: godot --headless --path . -s tests/support/asset_specs_writer.gd).

const Writer := preload("res://tests/support/asset_specs_writer.gd")


func test_asset_specs_doc_matches_the_catalogue() -> void:
	var on_disk := FileAccess.get_file_as_string("res://docs/ASSET_SPECS.md")
	assert_eq(on_disk, Writer.render(), "docs/ASSET_SPECS.md is out of date: run the writer")


func test_every_kind_is_explained() -> void:
	for n in AssetCatalog.SPECS:
		assert_true(Writer.KIND_TEXT.has(AssetCatalog.SPECS[n].kind), n)
