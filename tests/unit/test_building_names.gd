extends GutTest
## M010 every building on the city map has a name: its own, or a plain
## designation and an address on the street it faces, made up the same way
## every time; even numbers on one side of a street, odd on the other.


func test_every_building_named_or_addressed() -> void:
	for l in [RiversideWard.create(), RiverfrontYards.create(), HalloranSquare.create()]:
		var labels := BuildingNames.all(l)
		assert_eq(labels.size(), l.buildings.size())
		var addressed := 0
		for i in labels.size():
			assert_ne(labels[i], "", "%s building %d" % [l.id, i])
			if String(l.buildings[i].name) != "" and (l.buildings[i].opts as Dictionary).get("show_address", false):
				assert_true(labels[i].begins_with(l.buildings[i].name + ", "), "M011: the mayor's house, named and with its address")
			elif String(l.buildings[i].name) != "":
				assert_eq(labels[i], l.buildings[i].name, "a name stays a name")
			elif labels[i] != "Building":
				addressed += 1
		assert_gt(addressed, 20, "%s: plenty of street addresses" % l.id)


func test_addresses_look_like_chicago() -> void:
	var l := RiversideWard.create()
	var re := RegEx.new()
	re.compile("^(?:[A-Za-z ]+, )?\\d{3,5} [A-Z][A-Za-z. ]+ (St|Ave|Road)$|^(?:[A-Za-z ]+, )?\\d{3,5} [A-Z][A-Za-z. ]+$")
	var odd := 0
	var even := 0
	for b in l.buildings:
		if String(b.name) != "":
			continue
		var addr := BuildingNames.address(l, b)
		if addr == "":
			continue
		assert_not_null(re.search(BuildingNames.label(l, b)), BuildingNames.label(l, b))
		if int(addr.split(" ")[0]) % 2 == 1:
			odd += 1
		else:
			even += 1
	assert_gt(odd, 5, "odd numbers on one side")
	assert_gt(even, 5, "even on the other")
	assert_eq(BuildingNames.all(l), BuildingNames.all(RiversideWard.create()), "the same every time")


func test_kinds_of_building() -> void:
	var y := RiverfrontYards.create()
	var labels := " ".join(BuildingNames.all(y))
	assert_string_contains(labels, "Warehouse, ")
	assert_string_contains(labels, "Works, ")
	var h := HalloranSquare.create()
	assert_string_contains(" ".join(BuildingNames.all(h)), "Flats, ")
