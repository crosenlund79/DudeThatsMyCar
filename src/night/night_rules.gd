class_name NightRules
extends Resource
## The hours of the henchman's night (minutes after midnight; hours after
## midnight count past 24 * 60). The game is night only: it begins in the
## evening, reminds you to get home late at night and stops the clock at
## dawn until you go to bed. ALL VALUES PROVISIONAL.

## When every night begins (19:30 = 7:30 pm).
@export var start_minute := 19 * 60 + 30
## From here on you are told to get home to bed (04:00 = 4 am).
@export var home_minute := 24 * 60 + 4 * 60
## The sky starts to pale: the clock stops here until you sleep (05:30).
@export var dawn_minute := 24 * 60 + 5 * 60 + 30
## Game minutes per real second (1.0: a night of ten hours takes ten minutes).
@export var minutes_per_second := 1.0
