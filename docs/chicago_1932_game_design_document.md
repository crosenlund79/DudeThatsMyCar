# Chicago, 1932 — Game Design Document (Working Concept)

**Status:** Initial design foundation for a new, independent game. Nothing in this document authorizes code changes.  
**Working title:** *Chicago, 1932* — placeholder, not a final title.  
**Project origin:** A separate copy of HyperCars, in its own GitHub repository and development environment. Never modify or merge back into the original HyperCars repository without explicit permission.

## 1. The pitch

A stylish, hand-painted, top-down, single-player crime sandbox set in Chicago during the final years of Prohibition. Start as a small-time driver and fixer, then carve out a place in the city's underworld through bootlegging, protection work, robberies, gang rivalries, police corruption, nightclubs, and spectacular getaways. Fast, expressive 1930s cars, tommy-gun shootouts, smoky jazz, dark humor, and the tension of a city where almost everyone has something to sell—or hide.

**Player fantasy:** *Make a name for yourself in a dangerous city: drive, deal, threaten, negotiate, flee, fight, and live with the consequences.*

**Design statement:** This is a **conversion into an open-city gangster game**, not a racing game reskinned with fedoras. Its appeal should come from the freedom to pursue jobs and explore interconnected neighborhoods. The original GTA games can be discussed as broad genre references, but all assets, storylines, systems, and branding must be original.

## 2. Confirmed direction vs. proposals

**User-established direction:**
- Independently develop a complete new game using a copy of HyperCars.
- Keep its top-down, accessible, hand-painted visual character and satisfying feel where appropriate.
- Change the setting to 1930s Chicago and the central genre to a GTA-like gangster/crime sandbox.
- Feature gangsters, tommy guns, booze runs, corrupt cops, adult nightlife and clubs, street-level vice and the wider underworld.
- Explore an era-fitting original soundtrack using Suno.

**Proposals, not yet approved:**
- Set the playable story in **1932**, so Prohibition-era bootlegging is still illegal (national Prohibition ends in December 1933).
- Begin with a single interconnected district, not all of Chicago.
- Allow both in-car and on-foot movement, with enter/exit vehicles and a compact selection of interiors.
- Combine free-roam jobs with a loose narrative about relationships, power and changing loyalties.
- Build a police/witness/heat system, several factions, money and a modest criminal reputation system.
- Use dark comedy and adult themes without explicit sexual scenes or gratuitous shock content.

The new ChatGPT project should challenge, refine and confirm these proposals before converting them into implementation requirements.

## 3. Period and tone

**Chicago, 1932.** The Great Depression has reshaped the streets; Prohibition creates lucrative illegal liquor routes; businesses, political fixers, patrol officers and rival crews are deeply entangled. A late-night city of elevated trains, brick alleys, cobblestones, electric signs, river bridges, loading docks, warehouses, speakeasies, jazz stages, hotels, theaters and worn apartment blocks.

Tone: **stylized gangster fiction with personality**. Capable of menace, moral compromise, loss and violence, but also full of eccentric characters, sharp dialogue, gallows humor and small absurdities. Avoid either total historical simulation or endless parody.

The game may use a fictionalized Chicago street map and fictional characters to retain creative freedom and reduce historical research burden. Historical realities should inform the atmosphere, not require exact reconstruction.

Adult nightlife, sex work, labor exploitation, gambling and corruption may appear as non-explicit worldbuilding, missions and character relationships; treat people as characters with agency rather than disposable scenery.

## 4. Visual identity

- **Engine and camera:** Godot 2D, top-down view, legible at speed, with optional dramatic framing for moments of action.
- **Art:** retain HyperCars' hand-painted, slightly whimsical, warm organic visual language. Translate its palette into city streets, smoky interiors, period cars, illuminated signage and expressive people. Do not mechanically switch to gritty photorealism or generic pixel art.
- **Vehicles:** original 1930s-inspired sedans, coupes, taxis, delivery trucks and fast getaway cars; strong silhouettes, readable paint schemes, wheels, visible damage.
- **Neighborhoods:** distinct areas with readable landmarks, pedestrians, traffic, back alleys and shortcuts, rather than repetitive road loops.
- **Weather/time:** rain, wet reflective streets, fog, snow where appropriate, sunrise and deep nighttime. Use the existing lighting system wherever practical.
- **Creator art pipeline:** maintain external graphics/audio overrides and `template_` fallback conventions so the creator can replace art asset-by-asset without rewriting code.

## 5. Core gameplay loop

1. **Find a lead:** a fixer, club owner, crew member, contact, rumor, phone call or opportunity.
2. **Prepare:** choose a car, optional weapon, approach and perhaps crew support; consider cash and police attention.
3. **Do the job:** drive a route, deliver contraband, escort someone, collect protection money, follow a target, escape a raid, or fight through an ambush. Permit more than one approach where affordable.
4. **Deal with consequences:** police heat, witnesses, faction standing, damaged vehicles, money, injured relationships, loss of territory or retaliation.
5. **Return to city life:** spend earnings, meet people, repair or switch cars, take the next job, or simply roam and cause trouble.

The game should feel good when the player ignores the main story and drives around the city.

## 6. Primary systems (proposed)

### Driving and vehicles
Preserve HyperCars' responsive, entertaining top-down driving as a starting point, retuned for heavier period vehicles rather than reinvented. Keep collisions, tire response, skids, vehicle condition, repairs and convincing car-to-car interaction. Add roads with junctions, traffic, pedestrians and navigable intersections. A getaway should be exhilarating even without racing opponents.

### On-foot gameplay and vehicle entry
A GTA-like city strongly benefits from walking, getting out of cars, entering clubs and choosing vehicles. Implement simple top-down movement and vehicle entering/exiting, with gunplay and basic interaction, but avoid a giant RPG or animation framework. It is a major technical workstream, not an assumed trivial add-on.

### Combat
Tommy guns, revolvers, shotguns, thrown explosives and vehicle-mounted/passenger-fired gunplay as fitting. Arcade-readable shooting, cover from walls/cars, line of sight, destructible or damageable vehicles, intelligible police and gang responses. Reuse parts of HyperCars' projectile, aiming and damage code without forcing racing-specific weapons or homing missiles into the period.

### Police heat, witnesses and corruption
Witnesses can draw police attention. Heat rises with crimes and can fade through evasion, changing vehicles, hiding, or negotiated favors. Police can pursue, block roads, set up searches or respond selectively in corrupt districts. Corruption is a gameplay relationship with costs and risks—not an all-purpose magic bribe button.

### Factions and reputation
Several fictional crews, officials, independent businesses and civic contacts with clear interests. Jobs affect trust, retaliation and access to opportunities. Keep a small, comprehensible reputation model rather than simulating the entire city economy.

### Bootlegging and criminal enterprises
Driving illegal liquor from warehouse to club, avoiding patrols or rival hijackers, protecting shipments, stealing deliveries, laundering profits, paying off inspectors and operating a small racket. Make runs exciting driving missions first, not a spreadsheet logistics simulator.

### Free-roam city activity
Ambient traffic, pedestrians, club nightlife, small events, optional street races, taxi or delivery work, police encounters, crimes of opportunity, gossip and consequences. Aim for surprising situations, not thousands of procedurally generated chores.

### Progression
Money, reputation, access to districts, contacts, weapons and cars. Safehouses and garages can act as practical hubs. Preserve satisfying consequences without forcing complex crafting or survival meters.

## 7. Missions and moments

Examples of mission types (concepts, not fixed content):
- **The Whiskey Run:** take a fragile shipment through a patrol-heavy neighborhood to a jazz club; choose between a fast road and a suspicious alley route.
- **Protection Money:** a shopkeeper has two competing gangs demanding payment; intimidation, bargaining or betrayal shape the outcome.
- **A Quiet Ride:** pick up a frightened witness and lose the tail without drawing attention.
- **The Club Raid:** police arrive at a speakeasy; hide the books, move the liquor, get the owner out or escape with the cash.
- **Wrong Car, Wrong Man:** an easy vehicle theft turns into a chase because its owner works for a powerful faction.
- **Riverfront Ambush:** a handoff at a bridge or loading dock becomes a firefight and getaway.

Avoid an exclusively combat-based mission structure. Driving, intimidation, stealth-lite, navigation and negotiation should all matter.

## 8. People and city texture

Recurring figures should have recognizable identities: a club singer, a fixer who smiles too often, a weary detective, an ambitious gang lieutenant, an honest shopkeeper under pressure, a nightclub owner, a cab driver, a crooked ward politician. Characters should serve story and play, rather than become generic mission dispensers.

Adult establishments can be important social locations with performers, bartenders, workers, patrons, risks and secrets. Mature themes and suggestive environments are welcome; explicit sexual gameplay is not necessary to achieve the intended adult atmosphere.

## 9. Music and sound

Build an original period-inspired musical identity with Suno: hot jazz, early swing, small brass ensembles, stride piano, upright bass, muted trumpet, clarinet, brushed drums, blues and occasional darker noir cues. Avoid treating all 1930s music as generic big-band soundtrack.

Use music purposefully: title theme, speakeasy bands, radio/gramophone in cars or buildings, pursuit intensity, melancholic late-night themes. Music should support engine noise, traffic, weapon fire and voices rather than compete with them. Diegetic music (heard from a club or radio) is particularly promising.

Do not simply transplant the two HyperCars racing tracks if they do not fit the period. Keep ownership/license records for any generated music and voice assets. Original visual art and replaceable audio are part of the production plan.

## 10. What we reuse, adapt, or retire from HyperCars

**Strong candidates to retain/adapt:**
- Godot 2D foundation, camera, controller handling and UI infrastructure.
- Top-down vehicle physics, collisions, wheel visuals, condition/damage and repair rules.
- Projectile/combat code, explosions and effect pipeline, once period-appropriate.
- Vehicle AI/pathing where usable, plus finite-state behavior and faction personality concepts.
- Time of day, weather, lighting, audio buses/ducking and asset override resolver.
- Save architecture, automated tests, deterministic debugging tools and developer utilities.

**Major redesign required:**
- Track-centered world => interconnected city map, crossroads, paths and interiors.
- Lap/checkpoint racing => missions, free roaming and location-based objectives.
- Racer AI => mixed civilian, gang, police and pedestrian behaviors.
- Race scoreboard/announcer => wanted level, objective feedback, city map and character/vehicle HUD.
- Garage race economy => criminal jobs, cash, repair, contacts and progression.
- Weapons => credible era-fitting tools and both in-car/on-foot contexts.

**Do not automatically carry over:**
- Championships, Knockout and Battle Royale as primary modes.
- Homing missiles, orbiting missiles and futuristic racing mechanics.
- Racing-specific progression, race rankings, car ownership prizes and rival junker rules.
- Multiplayer until the new single-player city works convincingly.

Existing systems are *sources to inspect*, not mandatory features to preserve. Avoid forcing every HyperCars system into a game where it no longer belongs.

## 11. Suggested first playable vertical slice

**One small interconnected district** with 4–8 blocks, an alley network, one garage/safehouse, one speakeasy, a police station exterior and a warehouse/loading area. Start with a few distinguishable 1930s cars, modest traffic and pedestrians, one player character who can walk and drive, basic police pursuit and simple firearms.

Implement three interconnected activities: (1) a booze delivery and getaway, (2) a vehicle theft or extraction, and (3) a gang confrontation that can escalate into a police chase. Include money, a modest heat mechanic, day/night and a save loop. The goal is to prove **roaming -> taking a job -> driving/fighting -> escaping -> returning** is fun before building out Chicago.

Acceptance: the player can freely move through the district, get in/out of vehicles, drive and shoot, trigger a job, face a credible law response, finish or fail, then return to free roam without reloading. Driving should still feel good. Art should remain cohesive using replaceable placeholders.

## 12. Production constraints

- This is an independent repository. **Never change the original HyperCars repository** from this project.
- Follow `_StarterGodotPack`: modular, proportionate design; unit and cross-module tests; explicit branch safeguards; asset overrides with `template_` fallback; no automatic installers/exports.
- Audit the current cloned source before implementing; do not infer architecture from historical descriptions.
- Preserve deterministic testing for simulation while permitting varied normal play.
- Deliver coherent increments, not an unlimited open-world engine or a dozen new subsystems at once.
- Do not write an implementation prompt or begin code changes until the new project's high-level direction is approved.

## 13. Open design questions for the new ChatGPT thread

1. **Tone:** grim and grounded, pulpy and darkly funny, or a deliberate mixture?
2. **Character:** one named protagonist with a story, or a customizable gangster rising through the ranks?
3. **Movement:** how ambitious should on-foot shooting/interiors be in version one?
4. **World:** historical Chicago landmarks versus a fictionalized street layout?
5. **Structure:** narrative missions, free-form criminal empire, or a hybrid?
6. **Consequences:** how punitive should arrests, deaths, vehicle loss and faction betrayal become?
7. **Visual style:** how far should the user-redrawn art preserve HyperCars' playful caricature?
8. **Scale:** which small district best proves the core fantasy before expanding?

## 14. Instructions for the receiving ChatGPT thread

Treat this document as a **working GDD, not an approved implementation specification**. Preserve the user-established direction; identify proposals separately; challenge weak ideas constructively. First help choose the strongest distinctive identity and an achievable first playable slice. Discuss scope and what to salvage from the existing Godot project. Do not issue Claude Code prompts or edit code until explicitly requested. Keep the original HyperCars project out of scope.
