class_name FightInjuries
extends RefCounted
## What a fistfight leaves on the two men (pure): every punch Danny fails to
## stop bruises him (head, body, arms in turn), every one he lands bruises the
## other man, and the loser takes a worse blow to the face. Fistfights are not
## lethal: nothing here ever takes a body past what BodyCondition calls fatal.

const BRUISE := 10
const REGIONS := ["torso", "head", "left_arm", "torso", "right_arm"]
## The loser's beating: a split brow or a black eye (a wound) and the ribs.
const BEATEN := {"head": 34, "torso": 18}
## Never beyond these (below the fatal limits: head 75, body 90, 200 in all).
const CAP := {"head": 70, "torso": 85}
const CAP_TOTAL := 180


## Danny's injuries from a fight he had `results` in (true = he landed / held).
static func apply_to_danny(c: BodyCondition, results: Array, won: bool) -> void:
	for i in results.size():
		if not results[i]:
			c.hurt(REGIONS[i % REGIONS.size()], BRUISE)
	if not won:
		for r in BEATEN:
			c.hurt(r, BEATEN[r])
	_cap(c)


## The other man's injuries from the same fight.
static func apply_to_opponent(c: BodyCondition, results: Array, won: bool) -> void:
	for i in results.size():
		if results[i]:
			c.hurt(REGIONS[(i + 1) % REGIONS.size()], BRUISE)
	if won:
		for r in BEATEN:
			c.hurt(r, BEATEN[r])
	_cap(c)


static func _cap(c: BodyCondition) -> void:
	for r in CAP:
		c.damage[r] = mini(int(c.damage[r]), CAP[r])
	while c.total() > CAP_TOTAL:
		for r in BodyCondition.REGIONS:
			if c.total() > CAP_TOTAL and int(c.damage[r]) > 0:
				c.damage[r] = int(c.damage[r]) - 1
