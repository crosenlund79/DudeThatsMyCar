# Performance script — Milestone 012

Production guidance for the new spoken material of *Chicago, 1932* M012, for a voice actor if the lines are ever recorded. **In the game this material is text only.** The delivery notes in square brackets are for the performer; the game keeps them with the words (`Callouts.LINES[...].tag`, the `delivery` of a page, `BirdScene`'s lines) and never shows them on screen. No voice has been synthesised or imitated: the established recordings (Danny's opening, the Bird's song and her lines, the greetings of Rourke, Augie and Eddie, Eddie's sales line) are untouched and play as before.

Format: **CHARACTER** [delivery] *the words*. Danny's replies are his choices on screen.

## 1. Call-outs (stage 5)

Who calls out to Danny when he comes near, from what they remember and what the talk has told them (`src/people/callouts.gd`). The call is spoken across the room; the follow-up opens the conversation when Danny answers with E.


### ROURKE

- `rourke_business` — **ROURKE** [Low; not a request] *Mercer. A minute.*  
  Answered: **ROURKE** *Sit. There's something wants doing, and you're the man I want doing it.*  
  DANNY: *I'm listening, Mr. Rourke.*
- `rourke_lie` — **ROURKE** [Cold, quiet] *Danny. Sit down.*  
  Answered: **ROURKE** *People tell me things, Danny. I'd sooner hear them from you, first time round.*  
  DANNY: *Sure, Mr. Rourke.*
- `rourke_pleased` — **ROURKE** [Dry, amused] *There he is.*  
  Answered: **ROURKE** *Lindqvist's sleeping nights again. That's worth a drink, and the drink's on me.*  
  DANNY: *I'll take it.*
- `rourke_shooting` — **ROURKE** [Flat, very calm] *Mercer. Over here. Now.*  
  Answered: **ROURKE** *Shooting draws coppers, and coppers draw aldermen. Keep it quiet in my ward.*  
  DANNY: *It won't happen again.*

### AUGIE

- `augie_wary` — **AUGIE** [Wary, low] *You. Hands where I can see 'em.*  
  Answered: **AUGIE** *Say what you came to say, Dimes, and say it at the bar.*  
  DANNY: *Easy, Augie.*
- `augie_dry` — **AUGIE** [Urgent, under his breath] *Dimes! Over here - the cellar's near dry.*  
  Answered: **AUGIE** *The swells are drinking the paint off the walls. You bring rye, I pay for rye.*  
  DANNY: *Let's see what you've got.*
- `augie_boss` — **AUGIE** [Low, a nod at the corner table] *Dimes - the boss is asking.*  
  Answered: **AUGIE** *He's been asking since eight. Don't make him ask again.*  
  DANNY: *Thanks, Augie.*
- `augie_warm` — **AUGIE** [Warm] *Dimes! Your corner's free.*  
  Answered: **AUGIE** *Good to see a friendly face. The usual?*  
  DANNY: *Pour it.*

### EDDIE

- `eddie_overdue` — **EDDIE** [Sharp, half a joke] *Hey! Dimes! You got something of mine.*  
  Answered: **EDDIE** *The Chicago typewriter, pal. A loan's a loan.*  
  DANNY: *About that.*
- `eddie_noise` — **EDDIE** [Sly] *Heard you been making noise.*  
  Answered: **EDDIE** *Noise uses rounds. Rounds I got.*  
  DANNY: *Show me.*

### THE BIRD

- `bird_again` — **THE BIRD** [Arch, tired] *Come to stop another song, mister?*  
  Answered: **THE BIRD** *You've got a way of walking in on the best part. Well? You stopped it - say something.*  
  DANNY: *Just wanted a word.*
- `bird_hello` — **THE BIRD** [Curious, unhurried] *You're the one Rourke keeps by the door.*  
  Answered: **THE BIRD** *Everybody in here looks at me. You look at the room. Why's that?*  
  DANNY: *Habit.*

### ALD. QUILTY

- `quilty_hello` — **ALD. QUILTY** [Expansive] *Mercer! Come in, come in.*  
  Answered: **ALD. QUILTY** *The ward's door is always open - mine more than most. Sit, sit.*  
  DANNY: *Evening, Alderman.*
- `quilty_shooting` — **ALD. QUILTY** [Genial, worried underneath] *Danny! A word.*  
  Answered: **ALD. QUILTY** *My voters hear shots, Danny, and then they hear about it from me. I'd like to have something to tell them.*  
  DANNY: *Nothing to tell, Alderman.*
- `quilty_kindness` — **ALD. QUILTY** [Pleased, a hand out] *Mercer! A friend of the ward.*  
  Answered: **ALD. QUILTY** *I hear you did a good turn on Marlowe Avenue. I don't forget a good turn. Neither does the ward.*  
  DANNY: *Just neighbourly.*

### LEON SOBCZAK

- `leon_hello` — **LEON SOBCZAK** [Dry, not looking up] *Shut that door - you're letting the coal dust in.*  
  Answered: **LEON SOBCZAK** *North Branch Freight, night dispatch. If you're not a driver with a waybill, you're in my light.*  
  DANNY: *Just looking round.*

## 2. Freight Doesn't Walk (stage 6)

Danny's own job in the Riverfront Yards (`src/jobs/freight_job.gd`, the pages in `Conversations._leon`, `_walt`, Dutch's `freight_ask`). The words are in the code; the delivery notes are here only.

### LEON SOBCZAK — North Branch Freight's night dispatcher
A company man past forty, tired, decent, frightened for his job and trying not to show it. Talks fast, rubs his eyes, never quite looks up from the blotter until he wants something.

- The offer — [Weary, then hopeful; the money is "mine, not the company's" said with a little pride] *Radio cabinets for Hartmann's on State Street. Twelve crates, on the two o'clock truck, or the company hangs it on me...*
- Talked round — [Exasperated at the company, at himself; gives in] *Six dollars. For a crate Mickey Duffy dropped on his own foot. ...Fine. Petty cash.*
- The fee — [Relief, almost laughing] *The truck's loading! Twelve crates, all present and correct.*
- Let down — [Flat, not angry; disappointed] *I paid Walt's six myself at a quarter to the truck. It went out late. Next time just say no, Mercer - it's cheaper.*

### WALT HANEY — foreman of the freight shed
Big, slow to speak, Local 9 to the bone; proud of his gang, contemptuous of the company, not afraid of Danny until he has reason to be.

- Stonewalling — [Dismissive, back turned to the stove] *If Sobczak sent you about them crates, tell him what I told him: nothing.*
- The grievance — [Quiet anger; the numbers matter to him] *Mickey Duffy dropped one crate of glassware. One. Company takes six bucks off the whole gang for it - off men making forty cents an hour.*
- Paid by Danny — [Surprised, gruff warmth] *Boys! The Hartmann's crates. Shake a leg - Mercer's buying.*
- A gun shown — [Measured; humiliated, careful] *Boys. Load the Hartmann's crates. Mr. Mercer is in a hurry.*
- Laughing off a threat — [Amused, with his men laughing behind him] *With what, harsh language?*
- Before a fight — [Almost pleased] *The old way, huh? Suits me.*
- After losing it — [Winded, grudging] *...Boys. Load the damn crates.*
- After winning it — [Not unkind; final] *That's how it goes in the yards, pal. Come back when you've got something better than fists.*

### DUTCH — the night lunch counter
- The tip — [Confiding, pouring coffee nobody asked for] *Walt Haney's boys sat right where you're standing, sore as boils...*

## 3. After the Last Song (stage 7)

Once, on a night after half past one when Danny is in the Copper Owl and has met her, the Bird's song ends for good, she steps down to the end of the bar and asks him to stay (`main._bird_after_last_song`, `_start_bird_film`; the pages in `Conversations._bird_scene`). The film is played in the game (M010's `Cinematic`, held at its last key for the talk): the house lights down to about half, the room hushed under it, the camera leaving Danny for her. Her recorded lines are untouched; nothing of this scene is voiced. The song is the existing *Leave the Lights Low*, which simply ends.

**Tone:** quiet, late, unhurried. Not a seduction and not a confession. She is tired, clever, and taking his measure; she has her own reasons for asking and does not give them all away. No big secret, nothing that changes Danny's past.

**THE BIRD** — a singer at the end of a long night: shoes off under the stool, voice lower than on the stage, dry humour that covers how much she watches.

- Off the bandstand — [Warm for the room, then to him alone, quieter] *That's the last one, folks. ...Stay a minute, Mercer?*
- Narration (on screen): *The band packs up. Somebody starts stacking chairs on the tables.* / *The Bird sits at the end of the bar with a glass of water dressed up as gin.*
- [Wry; looking at the glass, not at him] *Every night a man at that corner table decides what I'm worth. Tonight it was Rourke.*
- [A small shrug; then she turns to him] *Last week it was a fella from the Water Department. They all want the same thing from a singer - to hear they're not like the other fellas.* ... *You sit by the door and watch the room, not the stage. So tell me, Mercer: what do they say about me, when I'm not up there?*

Danny's answer (his choice; remembered - `Memories`: told_truth, kept_quiet, held_back; or none if he walks away):

1. *That you're Rourke's canary, and you hear more than you sing.* — **THE BIRD** [One short laugh; then honest back, almost to herself] *Rourke's canary. Honest. That's rarer in here than gin. Here's one back, then. I hear everything up there. I just never decided what it's worth - to keep it, or to stay.*
2. *Nothing worth repeating.* — **THE BIRD** [Smiling at the glass; fond, a warning underneath] *Liar. A kind one. Kind comes dear in this town, Mercer - mind it doesn't cost you more than it costs them.*
3. *Ask me again when I know you better.* — **THE BIRD** [Looks at him a beat too long; approving] *Fair. Knowing a man and trusting him ain't the same animal. Most of them in here never learned the difference.*
4. (He walks away) — nothing said; she lets it be.

Afterwards she greets him by it: *My honest man.* / *The gentleman who hears nothing worth repeating.* / *Know me any better yet, Mercer?* / *You again. Still saving your words?* [each dry, a private joke between them]
