/* ^ ^
  //\,\_,
 |'{|}{|}\
 |___>+<_/
|    () /:|
|()   /:/\|_______
|   /:::\/ CHEESE,\
|)/:/\:::| PLEASE!|
|:::\/::/\_ ______/
|:::::()()_V
|:/\//o o   \ 
|:/  \>u<___/\/\/

by Petra Crockett (mozipha), September 2023

FUZE Gamejam 26 entry (theme: HIDE)

This game is built with a custom 3D map editor that I created. It also uses a physics
engine that I've been coding. Instructions for playing the game can be viewed from the
title screen.



Change log (1.1)
* Added motion controls for camera.
* Added saved settings menu.
* Gameplay stats are shown on completion and best stats are saved.
* Reduced input delay on text screens so they can be dismissed more quickly.
* Adjusted some stages' cat timers.
* Added end-of-stage mouse animation.
* Fixed an audio bug.
* Various obstacle collision box improvements.
* More detail added to environments
* Improved lighting
* Lowered FOV
* Mouse faces correct direction at stage start.
* Codebase organization/clean-up

*/

// CORE LOADER
function getModels()
	var models = [
		// Bank 1
		[
			["Mouse House"], // Bank name (optional)
			["Cheese", "Devils Garage/cheese"],
			["", "DinV Studio/Bed_02"],
			["", "DinV Studio/Box_01"],
			["", "DinV Studio/Box_02"],
			["", "DinV Studio/Cabinet01"],
			["", "DinV Studio/Chair_01"],
			["", "DinV Studio/Grill"],
			["", "DinV Studio/Kitchen Table_01"],
			["", "DinV Studio/KitchenCabBase_01"],
			["", "DinV Studio/KitchenCabBase_03"],
			["", "DinV Studio/KitchenCabBase_04"],
			["", "DinV Studio/KitchenCabBase_05"],
			["", "DinV Studio/KitchenCabBase_07"],
			["", "DinV Studio/KitchenCabBase_08"],
			["", "DinV Studio/KitchenCabTop_08"],
			["", "DinV Studio/KitchenChair_01"],
			["", "DinV Studio/Microwave"],
			["", "DinV Studio/Refrigerator"],
			["", "DinV Studio/Rack_01"],
			["", "DinV Studio/Rack_02"],
			["", "DinV Studio/SmallTable_01"],
			["", "DinV Studio/SofaSmall_01"],
			["", "DinV Studio/Sofa_01"],
			["", "DinV Studio/Stair_02"],
			["", "Fertile Soil Productions/Wall_Doorway"],
			["", "Fertile Soil Productions/Wall_Door"],
			["", "DinV Studio/Book_01"],
			["", "DinV Studio/Book_02"],
			["", "DinV Studio/Book_04"],
			["", "DinV Studio/Book_05"],
			["", "DinV Studio/Container_04"],
			["", "DinV Studio/Picture_L_01"],
			["", "DinV Studio/Picture_L_02"],
			["", "DinV Studio/Picture_L_03"],
			["", "DinV Studio/Picture_L_04"],
			["", "DinV Studio/Picture_L_05"],
			["", "DinV Studio/Picture_S_04"],
			["", "DinV Studio/Shelf_02"],
			["", "DinV Studio/Shelf_03"],
			["", "DinV Studio/Toaster"],
			["", "Kenney/books"],
			["", "Kenney/cardboardBoxClosed"],
			["", "Kenney/kitchenBlender"],
			["", "Kenney/kitchenCoffeeMachine"],
			["", "Quaternius/Plant"],
			["", "Broken Vector/Basket_02"],
			["", "Devils Garage/pot03"],
			["", "Devils Garage/toolbox"],
			["", "DinV Studio/PencilHolder"],
			["", "DinV Studio/Picture_S_05"],
			["", "Fertile Soil Productions/Prop_Vase"]
		]
		// Add additional banks as desired
	]
	// The line below adds essential system banks. Do not modify it.
	models = insertArray(models, [ [ ["Clipboard"] ], [ ["Primitives"] ], [ ["Lights"] ] ], 0)
return models

// ----------------------------------------------------------------
// GLOBAL SETUP

// System setup
var g_editor = false // Are we in the editor? false = game/core loader, true = editor
var g_version = "1.0.00"
var g_freezeFile = false // Setting to true will block file closure and freeze the save file in its current state
var g_frame = 0 // Current frame number
var g_lightBank = 2 // Bank number for lights
var g_intLen = 64 // Number of bits to use for binary variables. FUZE technically has 64-bit signed ints, but it's complicated

var g_bg
initBg()

function initBg()
	g_bg = [
		.idx = 6,
		.col = {0.2, 0.2, 0.2, 1}
	]
	setEnvironment(g_bg.idx, g_bg.col)
return void

// Size of a grid cell. Must be an equal-sided cube whose dimension is a whole number.
var g_cellExt = [
	.lo = {-2.5, -2.5, -2.5},
	.hi = {2.5, 2.5, 2.5}
]

var g_cellObjStart = 2 // First index of object storage in a cell. We don't store objects in a subarray because that would increase access time.
var g_cellBitLen = pow(getCellWidth(), 3)
var g_cell // This is the array that stores all cell and map object data

/* Clears and resets the g_cell array for map initialization. */
function initCell()
	g_cell = []
return void

// Camera
var g_cam = [
	.movSpd = 5,
	.rotSpd = 125,
	.pos = {0, 1, 1},
	.dir = {0, 1, 2},
	.fwd = {0, 0, 1},
	.r = {-1, 0, 0},
	.up = {0, 1, 0},
	.delta = {0, 0, 0}, // Movement difference from last frame
	.fov = 60
]
setFov(g_cam.fov)
initCam()

/* Resets camera to default values. */
function initCam()
	g_cam.pos = {0, 1, 1}
	g_cam.dir = {0, 1, 2}
	g_cam.fwd = {0, 0, 1}
	g_cam.r = {-1, 0, 0}
	g_cam.up = {0, 1, 0}
	g_cam.delta = {0, 0, 0}
return void

// World state
initCell() // Don't init cell in the cell setup block because it needs camera and cursor info
var g_currentMapName = ""
var g_c // Controller input buffer

/* g_cDat is an array instead of a struct so that it can be iterated. g_cIdx
gives friendly masks for the indices -- e.g. g_cDat[g_cIdx.down] to access
the down button's data. */
var g_cIdx = [
	.a = 0,
	.b = 1,
	.x = 2,
	.y = 3,
	.l = 4,
	.r = 5,
	.zl = 6,
	.zr = 7,
	.up = 8,
	.down = 9,
	.left = 10,
	.right = 11,
	.lxPos = 12,
	.lxNeg = 13,
	.lyPos = 14,
	.lyNeg = 15,
	.rxPos = 16,
	.rxNeg = 17,
	.ryPos = 18,
	.ryNeg = 19,
	.lxy = 20,
	.rxy = 21
]

// Default button info
button g_btn
g_btn.lastTime = 0
g_btn.held = false
g_btn.kbHeld = false
g_btn.count = 0

// Extended data about controller button states
array g_cDat[22]
var g_rateInit = 0.2
var g_rateRep = 0.075

var i
for i = 0 to len(g_cDat) loop
	g_cDat[i] = g_btn
repeat

var g_settings = [
	.useMot = false,
	.motXSens = 5,
	.motYSens = 5,
	.useMotPan = true,
	.invMotX = false,
	.invMotY = false,
	.stickXSens = 5,
	.stickYSens = 5,
	.invStickX = false,
	.invStickY = false
]

var g_bestStats = [
	.deathsFall = -1,
	.deathsCat = -1,
	.deathsReset = -1,
	.deathsTotal = -1,
	.catsSeen = -1,
	.throwsYellow = -1,
	.throwsGreen = -1,
	.throwsTotal = -1,
	.throwsFall = -1,
	.throwsEatenPct = -1,
	.totalTime = -1
]

// ----------------------------------------------------------------
// LOAD OBJECT DEFINITIONS AND MAP

var g_font = loadImage("Fonts/GGBot_Bad_comic")
setFont(loadImage("Fonts/GGBot_Bad_comic"))

var g_mapFile = open() // Subsequent opens must use openFile() rather than open() to respect g_freezeFile's state

// Arrange model data in a code-readable format
var g_loadResult = loadObjDefs(g_mapFile)
var g_obj = g_loadResult.obj
var g_bankName = g_loadResult.bankName
loadMergedObjDefs(g_mapFile)

resolveMergedObjDefChanges([])
readGameSettings(g_mapFile)
readBestStats(g_mapFile)

closeFile(g_mapFile)

//showSplash()
	
// ----------------------------------------------------------------
// GAME-SPECIFIC CODE

	// ----------------------------------------------------------------
	// GAME GLOBAL VARIABLES

// Audio cues
var g_nomSnd = loadAudio("Untied Games/birds6")
var g_mouse1Snd = loadAudio("Untied Games/birds3")
var g_mouse2Snd = loadAudio("Untied Games/scream2")
var g_cat1Snd = loadAudio("Gijs De Mik/FX_Whip_05")
var g_cat2Snd = loadAudio("Gijs De Mik/FX_Whip_06")
var g_chargeSnd = loadAudio("Gijs De Mik/FX_Misc_27")
var g_failSnd = loadAudio("Untied Games/die4")
var g_mouseJumpSnd = loadAudio("Untied Games/jump9")
var g_throwSnd = loadAudio("Untied Games/fall2")
var g_winSnd = loadAudio("Wild Forts/FX_Item_Get_02")
var g_wallSnd = loadAudio("Wild Forts/FX_Menu_Select_06")
var g_mouseFallSnd = loadAudio("Gijs De Mik/FX_Ping_18")
var g_catFallSnd = loadAudio("Untied Games/fall3")
var g_rndFallSnd = [
	loadAudio("David Silvera/evil_fall"),
	loadAudio("David Silvera/common_lady_goodbye_2"),
	loadAudio("David Silvera/evil_join_me"),
	loadAudio("David Silvera/evil_no"),
	loadAudio("David Silvera/evil_shadow"),
	loadAudio("David Silvera/female_birmingham_annoyed"),
	loadAudio("David Silvera/male_cooltrick"),
	loadAudio("David Silvera/male_nailedit"),
	loadAudio("David Silvera/misc_air_combo"),
	loadAudio("David Silvera/misc_mission_accomplished_02"),
	loadAudio("David Silvera/misc_you_lose_02"),
	loadAudio("David Silvera/posh_lady_gasp_5"),
	loadAudio("David Silvera/posh_lady_goodbye"),
	loadAudio("David Silvera/wizard_goodbye_1"),
	loadAudio("Wild Forts/Male_Bye_Bye")
]
var g_menuSnd = loadAudio("Gijs De Mik/FX_Ping_01")
var g_menuSelSnd = loadAudio("Gijs De Mik/FX_Ping_03")

// Audio channels
var g_mouseChan = 0
var g_nomChan = 1
var g_catChan = 2
var g_wallChan = 3
var g_throwChan = 4
var g_chargeChan = 5
var g_menuChan = 6

g_cam.rotSpd = 75
array g_mouse[0]
array g_cat[0]
array g_cheese[0]
var g_bye = false
var g_restartTimer = 0
var g_needStageLoad = -1
var g_needSettingsTest = false
var g_firstInputSent = false
var g_throwPower = 0
var g_throwType = 0
var g_mouseJumpCooldown = 0
var g_catJumpCooldown = 0
var g_catTimer = 0
array g_arrow[0]
var g_isDead = false
var g_vol = 2
var g_playTitleSnd = true
var g_dismissDelay = 0.4
var g_curStage = -1
var g_neutral
var g_totalMotion = {0, 0, 0}

var g_stats
resetStats()

var g_stageDat = [
	[
		.name = "Kitchen",
		.title = "It Starts in the Kitchen",
		.info = "Look around with the control stick." + chr(10) + chr(10) + 
			"Hold and release (A) to throw cheese." + chr(10) + chr(10) + 
			"The mouse will follow the cheese." + chr(10) + chr(10) + 
			"Guide the mouse to the hiding place before the cat shows up!",
		.endInfo = "That cat will never find the mouse in this pan. Let's hope the coast is clear before someone decides to cook macaroni!",
		.startPos = {-11.75, 1.1, -3.5},
		.startFwd = normalize({1, 0, -1}),
		.camPos = {-1.25, 9.1, -10.18},
		.camFwd = normalize({-0.43, -0.42, 0.8}),
		.camUp = normalize({-0.2, 0.9, 0.37}),
		.endPos = {11.5, 1, -2.75},
		.catTimer = 28,
		.catStartPos = {-11.75, 2, -3.5},
		.catFwd = normalize({1, 0, -1})
	],
	[
		.name = "Kitchen 2",
		.title = "It Also Continues in the Kitchen",
		.info = "Sometimes the mouse will need to jump over things." + chr(10) + chr(10) + 
			"Throw green cheese with (Y) to make the mouse jump." + chr(10) + chr(10) + 
			"If you get stuck, hold (B) to restart.",
		.endInfo = "The microwave? Are you sure?!",
		.startPos = {-11.5, 1.1, -6},
		.startFwd = normalize({0.707, 0, 0.707}),
		.camPos = {-4.14, 11.47, -11.46},
		.camFwd = normalize({0, -0.75, 0.66}),
		.camUp = normalize({0, 0.666, 0.746}),
		.endPos = {8.25, 4.5, 4.25},
		.catTimer = 30,
		.catStartPos = {-11.5, 2, -6},
		.catFwd = normalize({0.707, 0, 0.707})
	],
	[
		.name = "Kitchen 3",
		.title = "It's a Large Kitchen, Okay?",
		.info = "Some rooms may turn a corner around the camera.",
		.endInfo = "Oh, it's Oscar the Grouch!",
		.startPos = {-24.75, 1.1, -2.125},
		.startFwd = normalize({1, 0, 0}),
		.camPos = {-1.14, 19.55, -21.27},
		.camFwd = normalize({-0.2, -0.53, 0.83}),
		.camUp = normalize({-0.13, 0.85, 0.51}),
		.endPos = {26.625, 0.875, -45.75},
		.catTimer = 55,
		.catStartPos = {21.375, 2, -2.625},
		.catFwd = normalize({0.707, 0, -0.707})
	],
	[
		.name = "Living Room",
		.title = "Lines of Sight",
		.info = "Who knows what sorts of snacks have fallen down behind the sofa?" + chr(10) + chr(10) +
			"(Cheese. It's cheese.)",
		.endInfo = "What are you even hiding in, mouse?",
		.startPos = {10.5, 1.1, 4.5},
		.startFwd = normalize({-1, 0, 0}),
		.camPos = {-4.56, 18.84, -13.72},
		.camFwd = normalize({0.07, -0.65, 0.76}),
		.camUp = normalize({0.06, 0.76, 0.65}),
		.endPos = {-25.75, 1.25, -42.375},
		.catTimer = 35,
		.catStartPos = {-18.25, 9, -10.25},
		.catFwd = normalize({-1, 0, 0})
	],
	[
		.name = "Garage",
		.title = "Garage",
		.info = "Where there are cardboard boxes, there's sure to be a cat.",
		.endInfo = "As everyone knows, green boxes are better for hiding.",
		.startPos = {-10.75, 1.1, -6.5},
		.startFwd = normalize({0.707, 0, -0.707}),
		.camPos = {-1, 8.6, -16.8},
		.camFwd = normalize({0.03, -0.4, 0.9}),
		.camUp = normalize({0.013, 0.9, 0.42}),
		.endPos = {12.75, 6.75, 4.5},
		.catTimer = 30,
		.catStartPos = {-10.75, 2, -6.5},
		.catFwd = normalize({0.707, 0, -0.707})
	],
	[
		.name = "Garage 2",
		.title = "Garage with Chasm",
		.info = "Home repairs? In this economy?",
		.endInfo = "Green boxes: still the best.",
		.startPos = {-10.75, 1.1, -6.5},
		.startFwd = normalize({0.707, 0, -0.707}),
		.camPos = {13.57, 16.1, -20.93},
		.camFwd = normalize({-0.51, -0.54, 0.66}),
		.camUp = normalize({-0.33, 0.84, 0.43}),
		.endPos = {49, 0.5, -16},
		.catTimer = 45,
		.catStartPos = {28.25, 6.5, -6.5},
		.catFwd = normalize({0, 0, -1})
	],
	[
		.name = "Bedroom",
		.title = "Where are you going?",
		.info = "Where are you coming from?",
		.endInfo = "The closet can hide mice from the cat's claws ... it?" + chr(10) + chr(10) + 
			"(I'll see myself out.)",
		.startPos = {10.25, 1.1, 2.5},
		.startFwd = normalize({0, 0, -1}),
		.camPos = {-12.78, 5.77, -12.7},
		.camFwd = normalize({0.71, 0.17, 0.7}),
		.camUp = normalize({0, 1, 0}),
		.endPos = {-22, 1.25, 2.75},
		.catTimer = 30,
		.catStartPos = {1, 6, -1.25},
		.catFwd = normalize({0, 0, -1})
	],
	[
		.name = "Cheese Room",
		.title = "Bounty of the Mouse God",
		.info = "cheesecheesecheesecheesecheesecheese",
		.endInfo = "And with that, the mice of the world are safe and well fed." + chr(10) + chr(10) + 
			"THE END" + chr(10) + chr(10) + 
			"Thanks for playing!" + chr(10) + chr(10) + 
			"--Petra Crockett, September 2023",
		.startPos = {-8, 1.1, 9.5},
		.startFwd = normalize({0.707, 0, -0.707}),
		.camPos = {-11.44, 3.53, 12.79},
		.camFwd = normalize({0.72, -0.17, -0.67}),
		.camUp = normalize({0.13, 0.98, -0.12}),
		.endPos = {7.25, 1, -1.25},
		.catTimer = 1,
		.catStartPos = {30, -60, -28.5},
		.catFwd = normalize({-0.707, 0, -0.707})
	]
]

	// ----------------------------------------------------------------
	// MOUSE ANIMATION

var g_mouseAnim = [
	.hide = [
		.keyIdx = -1,
		.dur = 1,
		.prog = 0,
		.fwdAxis = {0, 1, 0},
		.fwdDeg = 0,
		.upDeg = 0,
		.startPos = {0, 0, 0},
		.startFwd = {0, 0, 1},
		.startUp = {0, 1, 0},
		.startScale = {1, 1, 1},
		.endPos = {0, 0, 0},
		.endFwd = {0, 0, 1},
		.endUp = {0, 1, 0},
		.endScale = {1, 1, 1},
		.keyframe = [
			[
				.time = 0,
				.pos = {0, 0, 0},
				.fwd = {0, 0, 1},
				.up = {0, 1, 0},
				.scale = {2, 2, 2}
			],
			[
				.time = 0.35,
				.pos = {0, 1, 0},
				.fwd = normalize({0, 0.707, 0.707}),
				.up = normalize({0, 0.707, -0.707}),
				.scale = {2, 2, 2}
			],
			[
				.time = 0.5,
				.pos = {0, 1.3, 0},
				.fwd = {0, 0, 1},
				.up = {0, 1, 0},
				.scale = {1.6, 1.6, 1.6}
			],
			[
				.time = 0.65,
				.pos = {0, 1, 0},
				.fwd = normalize({0, -0.707, 0.707}),
				.up = normalize({0, 0.707, 0.707}),
				.scale = {1.2, 1.2, 1.2}
			],
			[
				.time = 1,
				.pos = {0, 0, 0},
				.fwd = {0, -1, 0},
				.up = {0, 0, 1},
				.scale = {0.5, 0.5, 0.5}
			]
		]
	]
]

/* Simple keyframe animation system. */
function playAnim(_anim, _obj, _startPos, _startFwd, _startUp, _startScale, _endPos, _endFwd, _endUp, _endScale)
	if _anim.keyIdx < 0 then
		_anim.keyIdx = 0
		setObjectPos(_obj, _startPos)
		setObjRot(_obj, _startPos, _startFwd, _startUp)
		_anim.fwdAxis = safeCross(_startFwd, _endFwd)
		
		if _anim.fwdAxis == {0, 0, 0} then
			_anim.fwdAxis = _startUp
		endif
		
		_anim.fwdDeg = getAngleBetweenVecs(_startFwd, _endFwd)
		var targUp = axisRotVecBy(_startUp, _anim.fwdAxis, _anim.fwdDeg)
		_anim.upDeg = getAngleBetweenVecs(targUp, _endUp)
		
		_anim.prog = 0
		_anim.startFwd = _startFwd
		_anim.endFwd = _endFwd
		_anim.startUp = _startUp
		_anim.endUp = _endUp
		_anim.startPos = _startPos
		_anim.endPos = _endPos
		_anim.startScale = _startScale
		_anim.endScale = _endScale
	else
		_anim.prog += deltaTime()
		
		if _anim.prog >= _anim.dur then
			_anim.keyIdx = -1
			setObjectPos(_obj, _anim.endPos)
			setObjRot(_obj, _anim.endPos, _anim.endFwd, _anim.endUp)
			_anim.prog = 0
		else
			var nextFwd = _anim.keyframe[_anim.keyIdx].fwd
			var nextUp = _anim.keyframe[_anim.keyIdx].up
			var nextPos = _anim.keyframe[_anim.keyIdx].pos
			var nextTime = _anim.keyframe[_anim.keyIdx].time
			var nextScale = _anim.keyframe[_anim.keyIdx].scale
			var getNext = false
			
			if _anim.keyIdx + 1 < len(_anim.keyframe) then
				if _anim.keyframe[_anim.keyIdx + 1].time * _anim.dur <= _anim.prog / _anim.dur then
					_anim.keyIdx += 1
					
					if _anim.keyIdx + 1 < len(_anim.keyframe) then
						getNext = true
					endif
				else
					getNext = true
				endif
			endif
			
			if getNext then
				nextFwd = _anim.keyframe[_anim.keyIdx + 1].fwd
				nextUp = _anim.keyframe[_anim.keyIdx + 1].up
				nextPos = _anim.keyframe[_anim.keyIdx + 1].pos
				nextTime = _anim.keyframe[_anim.keyIdx + 1].time
				nextScale = _anim.keyframe[_anim.keyIdx + 1].scale
			endif
			
			var baseFwd = axisRotVecBy(_anim.startFwd, _anim.fwdAxis, _anim.fwdDeg * (_anim.prog / _anim.dur))
			var baseUp = axisRotVecBy(_anim.startUp, _anim.fwdAxis, _anim.fwdDeg * (_anim.prog / _anim.dur))
			baseUp = axisRotVecBy(baseUp, baseFwd, _anim.upDeg * (_anim.prog / _anim.dur))
			var baseScale = lerp(_anim.startScale, _anim.endScale, (_anim.prog / _anim.dur))
			
			var frame = _anim.keyframe[_anim.keyIdx]
			var lerpVal = (_anim.prog - (frame.time * _anim.dur)) / ((nextTime - frame.time) * _anim.dur)
			
			var lerpResult = lerpDirVecs(frame.fwd, frame.up, nextFwd, nextUp, lerpVal)
			frame.fwd = lerpResult.fwd
			frame.up = lerpResult.up
			
			frame.pos = {lerp(frame.pos.x, nextPos.x, lerpVal), lerp(frame.pos.y, nextPos.y, lerpVal), 
				lerp(frame.pos.z, nextPos.z, lerpVal)}
			frame.scale = {lerp(frame.scale.x, nextScale.x, lerpVal), lerp(frame.scale.y, nextScale.y, lerpVal), 
				lerp(frame.scale.z, nextScale.z, lerpVal)}
			
			frame.fwd = changeVecSpaceZFwd(frame.fwd, baseFwd, baseUp, safeCross(baseFwd, baseUp), {0, 0, 0})
			frame.up = changeVecSpaceZFwd(frame.up, baseFwd, baseUp, safeCross(baseFwd, baseUp), {0, 0, 0})
			var tweenPos = (_anim.endPos - _anim.startPos) * (_anim.prog / _anim.dur)
			var newPos = _anim.startPos + tweenPos + frame.pos
			var newScale = baseScale * frame.scale
			
			setObjectPos(_obj, newPos)
			setObjRot(_obj, newPos, frame.fwd, frame.up)
			setObjectScale(_obj, newScale)
		endif
	endif
return _anim

	// ----------------------------------------------------------------
	// CAMERA

/* Per-frame camera updater. */
function updateGameCam(_c)
	var oldPos = g_cam.pos
	var oldFwd = g_cam.fwd
	var oldUp = g_cam.up
	var oldDir = g_cam.dir
	var stick
	
	// Use whichever stick has the greatest input
	if length({_c.rx, _c.ry}) > length({_c.lx, _c.ly}) then
		stick = [
			.x = _c.rx,
			.y = _c.ry
		]
	else
		stick = [
			.x = _c.lx,
			.y = _c.ly
		]
	endif
	
	if g_settings.invStickX then
		stick.x *= -1
	endif
	
	if g_settings.invStickY then
		stick.y *= -1
	endif
	
	stick.x *= g_settings.stickXSens / 3
	stick.y *= g_settings.stickYSens / 3
	
	if g_settings.useMot then
		var xChg = _c.velocity[0].x * (g_settings.motXSens / 2)
		var yChg = _c.velocity[0].z * (g_settings.motYSens / 2)
		
		if g_settings.invMotX then
			stick.x += xChg
		else
			stick.x -= xChg
		endif
		
		if g_settings.invMotY then
			stick.y += yChg
		else
			stick.y -= yChg
		endif
		
		g_totalMotion += _c.velocity[0]
		
		if _c.x then setNeutralOrientation() endif
		
		if g_settings.useMotPan then
			var recenterThresh = 12
			
			xChg = g_totalMotion.x / lerp(recenterThresh * 6, recenterThresh / 1, clamp((abs(g_totalMotion.x) - recenterThresh) / 30, 0, 1))
			yChg = g_totalMotion.z / lerp(recenterThresh * 6, recenterThresh / 1, clamp((abs(g_totalMotion.z) - recenterThresh) / 30, 0, 1))
			
			if abs(g_totalMotion.x) > recenterThresh then
				if g_settings.invMotX then
					stick.x += xChg
				else
					stick.x -= xChg
				endif
			endif
			
			if abs(g_totalMotion.z) > recenterThresh then
				if g_settings.invMotY then
					stick.y += yChg
				else
					stick.y -= yChg
				endif
			endif
		endif
	endif
	
	g_cam.fwd = axisRotVecBy(
		g_cam.fwd,
		g_cam.up,
		stick.x * deltaTime() * g_cam.rotSpd * -1 * (1 - abs(g_cam.fwd.y) * 0.75)
	)
	g_cam.r = axisRotVecBy(flattenY(g_cam.fwd), {0, 1, 0}, -90)
	var newFwd = axisRotVecBy(
		g_cam.fwd,
		g_cam.r,
		stick.y * deltaTime() * g_cam.rotSpd
	)
	
	var newUp = normalize(cross(g_cam.r, newFwd))
	
	// Prevent flipping camera upsidedown
	if newUp.y > 0.1 then
		g_cam.fwd = newFwd
		g_cam.up = newUp
	else
		g_cam.up = normalize(cross(g_cam.r, g_cam.fwd))
	endif
	
	g_cam.delta = g_cam.pos - oldPos
	g_cam.dir = g_cam.pos + g_cam.fwd
	setCamera(g_cam.pos, g_cam.dir)
return void

/* Reset controller neutral position for motion control. */
function setNeutralOrientation()
	g_neutral = controls(0).orientation[0]
	g_totalMotion = {0, 0, 0}
return void

	// ----------------------------------------------------------------
	// ACTORS

/* Generic actor creation. Initializes physics. */
function createActor(_type, ref _arr, _pos, _fwd, _up, _scale, _mass)
	colContext con
	
	var bankIdx = getObjDefBankIdx(_type)
	var objDef = g_obj[bankIdx.bank][bankIdx.idx]
	var objSize = absVec3(objDef.ext.hi * _scale - objDef.ext.lo * _scale)
	var colScale = objSize / 2
	var collider = placeObject(cube, _pos, colScale)
	setObjRot(collider, _pos, _fwd, _up)
	setObjectVisibility(collider, false)
	
	var obj
	var objContainer
	var activeObj = activeFromObjDef(bankIdx.bank, bankIdx.idx)
	
	if len(activeObj.children) or len(activeObj.lights) then
		obj = placeGrpObj(activeObj, activeObj, g_cam.fov)
		setObjectScale(obj.obj, _scale)
		objContainer = activeObj
		objContainer.obj = obj.obj
		objContainer.children = obj.children
	else
		obj = placeObjDef(objDef, _pos, _scale)
		objContainer = activeObj
		objContainer.obj = obj
	endif
	
	restoreDefaultObjCol(objContainer)
	setObjRot(objContainer.obj, _pos, _fwd, _up)
	setObjectPos(objContainer.obj, _pos)
	
	con = initColContext(con, collider, _pos, _fwd, _up, colScale, 4, _mass, {0, -50, 0}, 0.001, true, true, true)
	_arr = push(_arr, [ .obj = objContainer, .collider = collider, .colCon = con, .timer = 0, 
		.com = getExtCenter(objDef.ext) * _scale, .tempPos = {0, 0, 0}, .delta = 0, .ticksSinceUpdate = 0,
		.isFrozen = false, .name = _type ])
return void

/* Generic actor removal. */
function removeActor(ref _arr, _idx)
	if len(_arr) then
		removeObject(_arr[_idx].colCon.auxCollider)
		removeGroupObj(_arr[_idx].obj)
		removeObject(_arr[_idx].collider)
		_arr = remove(_arr, _idx)
	endif
return void

/* Removes all actors. */
function clearActors()
	while len(g_cheese) loop
		removeActor(g_cheese, 0)
	repeat
	
	if len(g_cat) then
		removeActor(g_cat, 0)
	endif
	
	if len(g_mouse) then
		removeActor(g_mouse, 0)
	endif
return void

/* Per-frame updater for actors. */
function updateAllActors()
	if len(g_mouse) then
		if g_mouseAnim.hide.keyIdx < 0 then
			g_mouse[0] = updateActor(g_mouse[0], deltaTime())
		endif
	endif
	
	if len(g_cat) then
		g_cat[0] = updateActor(g_cat[0], deltaTime())
	endif
	
	updateThrow()
	
	if len(g_cheese) then
		g_mouse[0] = seekTarget(g_mouse[0], g_cheese[0], g_mouseJumpCooldown, 90)
	endif
	
	if len(g_cat) then
		g_cat[0] = seekTarget(g_cat[0], g_mouse[0], g_catJumpCooldown, 120)
	endif
return void

/* Update actor physics. */
function updateActor(_actor, _timeDelta)
	_actor.colCon = updateObjCollisions(_actor.collider, _actor.colCon, {0, 0, 0}, 
		{0, 0, 1}, {0, 1, 0}, _actor.colCon.scale, _actor.colCon.collisionMode, 
		false, true, true, true, 1, true, _timeDelta)
	
	var appliedCom = changeVecSpaceZFwd(_actor.com, _actor.colCon.fwd, _actor.colCon.up,
		safeCross(_actor.colCon.fwd, _actor.colCon.up), {0, 0, 0})
	setObjectPos(_actor.obj.obj, _actor.colCon.comPos - appliedCom)
	setObjRot(_actor.obj.obj, _actor.colCon.comPos - appliedCom, _actor.colCon.fwd, _actor.colCon.up)
return _actor

/* Moves actor in the direction of a target actor/ */
function seekTarget(_actor, _target, ref _jumpCooldown, _turnSpd)
	// Find angle to look at cheese
	var targetPos = projectVecToPlane(_target.colCon.comPos, _actor.colCon.comPos, {0, 1, 0})
	var deg = getAngleBetweenVecs(_actor.colCon.fwd, targetPos - _actor.colCon.comPos)
	var r = safeCross(_actor.colCon.fwd, _actor.colCon.up)
	
	// Find rotation axis to look at cheese
	if dot(r, targetPos - _actor.colCon.comPos) < 0 then
		_actor.colCon.rotVelAxis = {0, 1, 0}
	else
		_actor.colCon.rotVelAxis = {0, -1, 0}
	endif
	
	// Set velocity and rotation to turn towards cheese. Slower in air
	var jumpPower = 6
	
	if _target.name == "JumpCheese" then
		jumpPower = 16
	else if _target.name == "Mouze" then
		jumpPower = 20
	endif endif
	
	if (_actor.colCon.colThisFrame or _actor.colCon.continuedCol) then
		if distance(_actor.colCon.comPos, targetPos) > 0.1 then
			_actor.colCon.rotVel = _turnSpd
			_actor.colCon.vel += _actor.colCon.fwd * 2 + _actor.colCon.up * jumpPower
			
			if _actor.name == "Mouze" then
				if !getChannelStatus(g_mouseChan) then
					if _target.name == "JumpCheese" then
						playAudio(g_mouseChan, g_mouseJumpSnd, g_vol - 1, getPanPos(_actor.colCon.comPos), getRndPitch(0.9, 1.5), 0)
					else
						playAudio(g_mouseChan, g_mouse1Snd, g_vol, getPanPos(_actor.colCon.comPos), getRndPitch(0.9, 1.5), 0)
					endif
				endif
			else
				if !getChannelStatus(g_catChan) then
					playAudio(g_catChan, getCatSndRr(), g_vol, getPanPos(_actor.colCon.comPos), getRndPitch(0.9, 1.5), 0)
				endif
			endif
			
		else
			_actor.colCon.rotVel = 0
			_actor.colCon.vel = {0, 0, 0}
		endif
	else
		_actor.colCon.rotVel = _turnSpd
	endif
	
	// Bounce away from walls
	if len(_actor.colCon.normal) and _actor.colCon.colThisFrame then
		if _actor.colCon.normal[0] != {0, 0, 0} and dot(_actor.colCon.normal[0], {0, 1, 0}) < 0.5 then
			_actor.colCon.vel += _actor.colCon.normal[0] * 3
			playAudio(g_wallChan, g_wallSnd, g_vol - 1, getPanPos(_actor.colCon.comPos), getRndPitch(0.4, 0.8), 0)
		endif 
	endif
	
	// Fix an infrequent rotation issue where up axis skews
	if _actor.colCon.up != {0, 1, 0} then
		_actor.colCon.up = {0, 1, 0}
	endif
return _actor

/* Checks if cheese has collided with something. */
function checkCheeseCol()
	if len(g_cheese) then
		if distance(g_mouse[0].colCon.comPos, g_cheese[0].colCon.comPos) < 1 then
			g_stats.throwsEaten += 1
			playAudio(g_nomChan, g_nomSnd, g_vol, getPanPos(g_cheese[0].colCon.comPos), getRndPitch(1.2, 1.6), 0)
			removeActor(g_cheese, 0)
		endif
	endif
return void

/* Makes end-of-stage arrow bounce. */
function updateArrow()
	if len(g_arrow) then
		setObjectPos(g_arrow[0].grp, g_stageDat[g_curStage].endPos + {0, 2 + sin(time() * 300) / 2, 0})
	endif
return void

/* Initializes cat for a stage. */
function resetCat()
	if len(g_cat) then
		removeActor(g_cat, 0)
	endif
	
	g_catTimer = ceil(g_stageDat[g_curStage].catTimer / 3)
return void

	// ----------------------------------------------------------------
	// THROWING
	
/* Throws cheese based on current throw strength. */
function throwCheese(_throwType)
	playAudio(g_throwChan, g_throwSnd, g_vol - 0.7, 0.5, lerp(1.3, 2, g_throwPower), 0)
	
	if _throwType then
		createActor("Cheese", g_cheese, g_cam.pos, g_cam.fwd, g_cam.up, {4, 4, 4}, 15)
		g_cheese[len(g_cheese) -1].name = "JumpCheese"
		setObjectMaterial(g_cheese[len(g_cheese) -1].obj.obj, lime, 0, 1, 0)
		g_stats.throwsGreen += 1
	else
		createActor("Cheese", g_cheese, g_cam.pos, g_cam.fwd, g_cam.up, {4, 4, 4}, 15)
		g_stats.throwsYellow += 1
	endif
	
	g_cheese[len(g_cheese) - 1].colCon.vel += g_cam.fwd * g_throwPower * 35 +  g_cam.up * 25 * g_throwPower
return void

/* Increases throw strength. */
function chargeThrow()
	var c = controls(0)
	
	if (c.a and !g_cDat[g_cIdx.a].held) or (c.y and !g_cDat[g_cIdx.y].held) then
		g_firstInputSent = true
		g_throwPower = clamp(g_throwPower + 1 * deltaTime(), 0, 1)
		
		if !getChannelStatus(g_chargeChan) and g_throwPower < 1 then
			playAudio(g_chargeChan, g_chargeSnd, g_vol - 1, 0.5, 1.6, 0)
		endif
		
		if c.a then
			g_throwType = 0
		else
			g_throwType = 1
		endif
	else if g_throwPower > 0 then
		stopChannel(g_chargeChan)
		throwCheese(g_throwType)
		g_throwPower = 0
	endif endif
	
	if !c.a then
		g_cDat[g_cIdx.a].held = false
	endif
	
	if !c.y then
		g_cDat[g_cIdx.y].held = false
	endif
return void

/* Updates the physics of thrown objects. */
function updateThrow()
	var i = 0
	while i < len(g_cheese) loop
		g_cheese[i].timer += deltaTime()
		
		if length(g_cheese[i].colCon.vel) < 0.1 then
			g_cheese[i].isFrozen = true
		endif
		
		if g_cheese[i].timer >= 10 then
			removeActor(g_cheese, i)
			
			i -= 1
		else if !g_cheese[i].isFrozen then
			if i == g_frame % len(g_cheese) then
				g_cheese[i].delta += deltaTime()
				g_cheese[i] = updateActor(g_cheese[i], g_cheese[i].delta)
				
				g_cheese[i].tempPos = g_cheese[i].colCon.comPos
				g_cheese[i].delta = 0
				g_cheese[i].ticksSinceUpdate = 0
			else
				g_cheese[i].ticksSinceUpdate += 1
				g_cheese[i].delta += deltaTime()
				
				var velFactor = 1
				var scale = 1
				
				if len(g_cheese[i].colCon.objList) then
					scale -= 0.4
				endif
				
				scale -= g_cheese[i].ticksSinceUpdate * 0.1
				velFactor = clamp(scale, 0, 1)
				
				var newVel = (g_cheese[i].colCon.vel + g_cheese[i].colCon.grav * g_cheese[i].delta) * g_cheese[i].delta * velFactor
				var newPos = g_cheese[i].colCon.comPos + newVel * (1 - g_cheese[i].ticksSinceUpdate * 0.1)
				var newFwd = axisRotVecBy(g_cheese[i].colCon.fwd, g_cheese[i].colCon.rotVelAxis, g_cheese[i].colCon.rotVel)
				var newUp = axisRotVecBy(g_cheese[i].colCon.up, g_cheese[i].colCon.rotVelAxis, g_cheese[i].colCon.rotVel)
				
				var appliedCom = changeVecSpaceZFwd(g_cheese[i].com, newFwd, newUp,
					safeCross(newFwd, newUp), {0, 0, 0})
				
				setObjectPos(g_cheese[i].collider, newPos)
				setObjectPos(g_cheese[i].obj.obj, newPos)
			endif
		endif endif
		
		i += 1
	repeat
return void

	// ----------------------------------------------------------------
	// STAGE STATE

/* Returns stage index from name.  */
function getStageIdx(_name)
	var idx = -1
	var i
	for i = 0 to len(stageDat) loop
		if stageDat[i].name == _name then
			idx = i
			break
		endif
	repeat
return idx

/* Resets everything for stage load. */
function initStage(_stageIdx, _showTitle)
	if _stageIdx < len(g_stageDat) then
		/* Stage loads are queued in order to later call the loader from as shallow an execution context as possible.
		Necessary because the Celqi map loader will hit a recursion limit if called from too deep a context. */
		if g_currentMapName != g_stageDat[_stageIdx].name then
			g_needStageLoad = _stageIdx
		else
			clearActors()
			
			if _showTitle then
				showStageTitle(_stageIdx)
			endif
			
			setNeutralOrientation()
			
			g_cam.pos = g_stageDat[_stageIdx].camPos
			g_cam.fwd = g_stageDat[_stageIdx].camFwd
			g_cam.up = g_stageDat[_stageIdx].camUp
			
			updateGameCam(controls(0))
			
			g_restartTimer = 0
			g_firstInputSent = false
			g_catTimer = g_stageDat[_stageIdx].catTimer
			createActor("Mouze", g_mouse, g_stageDat[_stageIdx].startPos, g_stageDat[_stageIdx].startFwd, {0, 1, 0}, {2, 2, 2}, 20)
			g_isDead = false
		endif
		
		g_curStage = _stageIdx
	else
		g_curStage = -1
	endif
return void
	
/* Checks if the restart button has been held long enough to restart. */
function checkRestart()
	var c = controls(0)
	var needQuit = false
	
	if c.b then
		g_restartTimer += deltaTime()
		var strength = interpolate(expo_out, 0, 1, g_restartTimer / 1.5)
		box(0, 0, gwidth(), gheight(), {0, 0, 0, strength}, false)
	else
		g_restartTimer = 0
	endif
	
	if g_restartTimer >= 1.5 then
		g_stats.deathsReset += 1
		needQuit = showGameOver()
			
		if !needQuit then
			initStage(g_curStage, false)
		endif
	endif
return needQuit

/* Checks if actors have fallen off the stage. */
function checkFall()
	var needQuit = false
	if len(g_cat) then
		if g_cat[0].colCon.comPos.y < -75 then
			resetCat()
		else if g_cat[0].colCon.comPos.y < -10 then
			if !getChannelStatus(g_catChan) then
				playAudio(g_catChan, g_catFallSnd, g_vol - 1, getPanPos(g_cat[0].colCon.comPos), 0.7, 0)
			endif
		endif endif
	endif
	
	if len(g_mouse) then
		if g_mouse[0].colCon.comPos.y < -75 then
			g_stats.deathsFall += 1
			needQuit = showGameOver()
			
			if !needQuit then
				initStage(g_curStage, false)
			endif
		else if g_mouse[0].colCon.comPos.y < -10 then
			if !g_isDead then
				g_isDead = true
				playAudio(g_mouseChan, getRndFallSnd(), g_vol - 1, getPanPos(g_mouse[0].colCon.comPos), 1, 0)
			endif
		endif endif
	endif
	
	var i
	for i = 0 to len(g_cheese) loop
		/* If cheese falls off map, stop horizontal movement so the mouse will track
		the initial fall position rather than the continuing fall position. */
		if g_cheese[i].colCon.comPos.y < -10 and (g_cheese[i].colCon.vel.x != 0 or g_cheese[i].colCon.vel.z != 0) then
			g_stats.throwsFall += 1
			g_cheese[i].colCon.vel = {0, g_cheese[i].colCon.vel.y, 0}
		endif
	repeat
return needQuit	

/* Spawns cat if timer has run out. */
function updateCatTimer()
	if g_firstInputSent then
		if g_catTimer > 0 then
			if g_curStage != 7 then
				g_catTimer -= deltaTime()
			else
				g_catTimer = rnd(9999) + 1
			endif
		else if !len(g_cat) then
			g_stats.catsSeen += 1
			createActor("Tabby", g_cat, g_stageDat[g_curStage].catStartPos, g_stageDat[g_curStage].catFwd, {0, 1, 0}, {1, 1, 1}, 50)
		endif endif
	endif
return void

/* Checks if an end condition has been reached. */
function checkStageEnd()
	var needQuit = false
	var ended = false
	
	if len(g_mouse) then
		if distance(g_mouse[0].colCon.comPos, g_stageDat[g_curStage].endPos) < 3.5 then
			ended = true
		
			var mouseOrig = getOriginFromCom(g_mouse[0].colCon.comPos, g_mouse[0].colCon.centerOfMass, g_mouse[0].colCon.fwd, 
				g_mouse[0].colCon.up, g_mouse[0].colCon.scale)
			var endDir = projectVecToPlane(g_stageDat[g_curStage].endPos - mouseOrig, {0, 0, 0}, {0, 1, 0})
			g_mouseAnim.hide = playAnim(g_mouseAnim.hide, g_mouse[0].obj.obj, mouseOrig, g_mouse[0].colCon.fwd, g_mouse[0].colCon.up, {1, 1, 1},
				g_stageDat[g_curStage].endPos, safeNormalize(endDir), {0, 1, 0}, {1, 1, 1})
		endif
	endif
	
	if ended and g_mouseAnim.hide.keyIdx < 0 then
		showStageEnd(g_curStage)
		
		if g_curStage == len(g_stageDat) - 1 then
			showStats()
		endif
		
		initStage(g_curStage + 1, true)
	endif
	
	if len(g_cat) and len(g_mouse) then
		if distance(g_cat[0].colCon.comPos, g_mouse[0].colCon.comPos) < 2 then
			g_stats.deathsCat += 1
			needQuit = showGameOver()
			
			if !needQuit then
				initStage(g_curStage, false)
			endif
		endif
	endif
return needQuit

	// ----------------------------------------------------------------
	// UI

/* Draws in-game UI (throw meter and cat timer). */
function drawGameUi()
	drawThrowMeter(g_throwPower)
	
	textSize(gheight() / 16)
	if !len(g_cat) and g_catTimer > 0 then
		drawTextEx(str(int(ceil(g_catTimer))), { gwidth() / 2, gheight() / 24 }, 
			0.5, align_center, gwidth(), 0, {1, 1}, white)
	else
		if len(g_cat) then
			var xPos
			var size
			var textCol
			if sin(time() * 1000) >= 0 then
				ink(red)
				size = rnd(0.6) + 0.3
				xPos = gwidth() / 2 + (rnd(gwidth()) - gwidth() / 2)
				textCol = red
			else
				xPos = gwidth() / 2
				size = 0.5
				textCol = white
			endif
			
			drawTextEx("A CAT APPEARS!", { xPos, gheight() / 24 }, 
				size, align_center, gwidth(), 0, {1, 1}, textCol)
		endif
	endif
return void

function drawThrowMeter(_lvl)
	var w = gwidth() / 32
	var h = gheight() - w * 2
	var edge = gwidth() / 128
	var meterBg = box(w, w, w * 2, h,
		black, false)
	var meterH = (gheight() - w * 2 - edge * 2) * (_lvl / 1)
	var meterCol = yellow
	
	if g_throwType then
		meterCol = lime
	endif
	
	var meter = box(w + edge, w - edge + h - meterH, w * 2 - edge * 2, meterH,
		meterCol, false)
return void

	// ----------------------------------------------------------------
	// AUDIO

/* Sometimes we play a different fall sound just for fun. */
function getRndFallSnd()
	var rand = rnd(12)
	var snd
	
	if !rand then
		rand = rnd(len(g_rndFallSnd))
		snd = g_rndFallSnd[rand]
	else
		snd = g_mouseFallSnd
	endif
return snd

/* The cat jump randomly picks between two sounds. */
function getCatSndRr()
return getRr(g_cat1Snd, g_cat2Snd)

function getRr(_rr1, _rr2)
	var snd
	
	if rnd(2) then
		snd = _rr1
	else
		snd = _rr2
	endif
return snd

/* Random sound pitch. */
function getRndPitch(_lower, _upper)
	var pitch = rnd(_upper - _lower) + _lower
return pitch

/* Returns pan position based on screen position, */
function getPanPos(_worldPos)
	var panPos = worldPosToScreenPos(_worldPos, g_cam.fwd, g_cam.up, 
		g_cam.pos, g_cam.fov).x / gwidth()
return panPos

	// ----------------------------------------------------------------
	// MENUS

/* Stage title card. */
function showStageTitle(_stageIdx)
	var timer = time()
	
	var c = controls(0)
	while !c.a or g_cDat[g_cIdx.a].held or time() - timer < g_dismissDelay loop
		c = controls(0)
		
		if !c.a then
			g_cDat[g_cIdx.a].held = false
		endif

		clear()
		drawTextEx(g_stageDat[_stageIdx].title, { gwidth() / 2, gheight() / 3 }, 0.75, align_center, 
			gwidth(), 0, {1, 1}, white)
		drawTextEx(g_stageDat[_stageIdx].info, { gwidth() / 2, gheight() / 3 + gheight() / 3 }, 
			0.25, align_center, gwidth(), 0, {1, 1}, white)
		
		update()
	repeat
	
	g_cDat[g_cIdx.a].held = true
return void

/* Title screen. */
function showGameTitle(_playSnd)
	resetStats()
	
	var sel = 0
	var startIdx = 3
	var byeIdx = 4
	
	if g_bestStats.totalTime >= 0 then
		startIdx += 1
		byeIdx += 1
	endif
	
	if _playSnd then
		playAudio(g_menuChan, g_menuSelSnd, g_vol - 0.5, 0.5, getRndPitch(0.8, 1.2) * -1, 0)
	endif
	
	var c = controls(0)
	while !c.a or g_cDat[g_cIdx.a].held loop
		c = controls(0)
		
		if !c.a then
			g_cDat[g_cIdx.a].held = false
		endif
		
		clear()
		drawTextEx("CHEESE, PLEASE", { gwidth() / 2 + gwidth() / 164, gheight() / 4 + gwidth() / 164 }, 1.25, align_center, 
			gwidth(), 0, {1, 1}, gold)
		drawTextEx("CHEESE, PLEASE", { gwidth() / 2, gheight() / 4 }, 1.25, align_center, 
			gwidth(), 0, {1, 1}, yellow)
		drawTextEx("What?", { gwidth() / 2, (gheight() / 4) * 2 }, 
			getSelSize(0, sel), align_center, gwidth(), 0, {1, 1}, getSelCol(0, sel))
		drawTextEx("How?", { gwidth() / 2, (gheight() / 4) * 2 + gheight() / 16}, 
			getSelSize(1, sel), align_center, gwidth(), 0, {1, 1}, getSelCol(1, sel))
		drawTextEx("Settings", { gwidth() / 2, (gheight() / 4) * 2 + (gheight() / 16) * 2 }, 
			getSelSize(2, sel), align_center, gwidth(), 0, {1, 1}, getSelCol(2, sel))
		
		if g_bestStats.totalTime >= 0 then
			drawTextEx("Best stats", { gwidth() / 2, (gheight() / 4) * 2 + (gheight() / 16) * 3 }, 
				getSelSize(3, sel), align_center, gwidth(), 0, {1, 1}, getSelCol(3, sel))
		endif 
		
		drawTextEx("Start", { gwidth() / 2, (gheight() / 4) * 2 + (gheight() / 16) * startIdx }, 
			getSelSize(startIdx, sel), align_center, gwidth(), 0, {1, 1}, getSelCol(startIdx, sel))
		drawTextEx("Bye", { gwidth() / 2, (gheight() / 4) * 2 + (gheight() / 16) * byeIdx }, 
			getSelSize(byeIdx, sel), align_center, gwidth(), 0, {1, 1}, getSelCol(byeIdx, sel))
		
		update()
		
		if menuDirInputStarted(c, false) then
			var snd = false
			loop if c.ly < -0.3 or c.down then
				sel = wrapIncClamp(sel + 1, 0, byeIdx)
				snd = true
				break endif
			if c.ly > 0.3 or c.up then
				sel = wrapIncClamp(sel - 1, 0, byeIdx)
				snd = true
				break
			endif break repeat
			
			if snd then
				playAudio(g_menuChan, g_menuSnd, g_vol - 0.5, 0.5, getRndPitch(0.8, 1.2), 0)
			endif
		endif
	repeat
	
	if sel < byeIdx then
		playAudio(g_menuChan, g_menuSelSnd, g_vol - 0.5, 0.5, getRndPitch(0.8, 1.2), 0)
	endif
	
	g_cDat[g_cIdx.a].held = true
return sel

/* Returns text size of a menu item based on whether it's selected. */
function getSelSize(_idx, _sel)
	var size = 0.25
	
	if _sel == _idx then
		size = 0.35
	endif
return size

/* Returns color of a menu item based on whether it's selected. */
function getSelCol(_idx, _sel)
	var col = white
	
	if _sel == _idx then
		col = lime
	endif
return col

/* Puts brackets around a selected ssetting. */
function getSelBrackets(_str, _idx, _sel)
	if _sel == _idx then
		_str = "< " + _str + " >"
	endif
return _str

/* Settings menu. */
function showSettings(_selStart)
	var sel = _selStart
	var rPos = gwidth() * 0.85
	var needSettingsTest = false
	
	// Put struct in array for easy indexing
	var settingsArr = [
		g_settings.useMot, g_settings.useMotPan, g_settings.motXSens, g_settings.motYSens, g_settings.invMotX, 
		g_settings.invMotY, g_settings.stickXSens, g_settings.stickYSens, g_settings.invStickX, g_settings.invStickY
	]
	
	var settingsRange = [
		[0, 1], [0, 1], [1, 10], [1, 10], [0, 1], [0, 1], [1, 10], [1, 10], [0, 1], [0, 1]
	]
	
	var c = controls(0)
	while (!c.a or g_cDat[g_cIdx.a].held or sel != 11) and !needSettingsTest loop
		c = controls(0)
		
		if !c.a then
			g_cDat[g_cIdx.a].held = false
		endif
		
		var baseH = gheight() / 4.5
		var spacer = gheight() / 20
		
		clear()
		
		drawTextEx("SETTINGS", { gwidth() / 2, gheight() / 8 }, 
			0.25, align_center, gwidth(), 0, {1, 1}, white)
		
		drawTextEx("Use motion control",
			{ gwidth() * 0.1, baseH }, 
			getSelSize(0, sel), align_center_left, gwidth() * 0.75, 0, {1, 1}, getSelCol(0, sel))
		drawTextEx("Allow panning via motion control",
			{ gwidth() * 0.1, baseH + spacer }, 
			getSelSize(1, sel), align_center_left, gwidth() * 0.75, 0, {1, 1}, getSelCol(1, sel))
		drawTextEx("Motion X sensitivity",
			{ gwidth() * 0.1, baseH + spacer * 2 }, 
			getSelSize(2, sel), align_center_left, gwidth() * 0.75, 0, {1, 1}, getSelCol(2, sel))
		drawTextEx("Motion Y sensitivity",
			{ gwidth() * 0.1, baseH + spacer * 3 }, 
			getSelSize(3, sel), align_center_left, gwidth() * 0.75, 0, {1, 1}, getSelCol(3, sel))
		drawTextEx("Invert motion X",
			{ gwidth() * 0.1, baseH + spacer * 4 }, 
			getSelSize(4, sel), align_center_left, gwidth() * 0.75, 0, {1, 1}, getSelCol(4, sel))
		drawTextEx("Invert motion Y",
			{ gwidth() * 0.1, baseH + spacer * 5 }, 
			getSelSize(5, sel), align_center_left, gwidth() * 0.75, 0, {1, 1}, getSelCol(5, sel))
		
		drawTextEx("Control stick X sensitivity",
			{ gwidth() * 0.1, baseH + spacer * 7 }, 
			getSelSize(6, sel), align_center_left, gwidth() * 0.75, 0, {1, 1}, getSelCol(6, sel))
		drawTextEx("Control stick Y sensitivity",
			{ gwidth() * 0.1, baseH + spacer * 8 }, 
			getSelSize(7, sel), align_center_left, gwidth() * 0.75, 0, {1, 1}, getSelCol(7, sel))
		drawTextEx("Invert control stick X",
			{ gwidth() * 0.1, baseH + spacer * 9 }, 
			getSelSize(8, sel), align_center_left, gwidth() * 0.75, 0, {1, 1}, getSelCol(8, sel))
		drawTextEx("Invert control stick Y",
			{ gwidth() * 0.1, baseH + spacer * 10 }, 
			getSelSize(9, sel), align_center_left, gwidth() * 0.75, 0, {1, 1}, getSelCol(9, sel))
		
		drawTextEx("Test settings",
			{ gwidth() * 0.1, baseH + spacer * 12 }, 
			getSelSize(10, sel), align_center_left, gwidth() * 0.75, 0, {1, 1}, getSelCol(10, sel))
		drawTextEx("Done",
			{ gwidth() * 0.1, baseH + spacer * 13 }, 
			getSelSize(11, sel), align_center_left, gwidth() * 0.75, 0, {1, 1}, getSelCol(11, sel))
		
		drawTextEx(getSelBrackets(getBoolStr(settingsArr[0]), 0, sel),
			{ rPos, baseH }, 
			getSelSize(0, sel), align_center, gwidth() * 0.75, 0, {1, 1}, getSelCol(0, sel))
		drawTextEx(getSelBrackets(getBoolStr(settingsArr[1]), 1, sel),
			{ rPos, baseH + spacer }, 
			getSelSize(1, sel), align_center, gwidth() * 0.75, 0, {1, 1}, getSelCol(1, sel))
		drawTextEx(getSelBrackets(str(settingsArr[2]), 2, sel),
			{ rPos, baseH + spacer * 2 }, 
			getSelSize(2, sel), align_center, gwidth() * 0.75, 0, {1, 1}, getSelCol(2, sel))
		drawTextEx(getSelBrackets(str(settingsArr[3]), 3, sel),
			{ rPos, baseH + spacer * 3 }, 
			getSelSize(3, sel), align_center, gwidth() * 0.75, 0, {1, 1}, getSelCol(3, sel))
		drawTextEx(getSelBrackets(getBoolStr(settingsArr[4]), 4, sel),
			{ rPos, baseH + spacer * 4 }, 
			getSelSize(4, sel), align_center, gwidth() * 0.75, 0, {1, 1}, getSelCol(4, sel))
		drawTextEx(getSelBrackets(getBoolStr(settingsArr[5]), 5, sel),
			{ rPos, baseH + spacer * 5 }, 
			getSelSize(5, sel), align_center, gwidth() * 0.75, 0, {1, 1}, getSelCol(5, sel))
		
		drawTextEx(getSelBrackets(str(settingsArr[6]), 6, sel),
			{ rPos, baseH + spacer * 7 }, 
			getSelSize(6, sel), align_center, gwidth() * 0.75, 0, {1, 1}, getSelCol(6, sel))
		drawTextEx(getSelBrackets(str(settingsArr[7]), 7, sel),
			{ rPos, baseH + spacer * 8 }, 
			getSelSize(7, sel), align_center, gwidth() * 0.75, 0, {1, 1}, getSelCol(7, sel))
		drawTextEx(getSelBrackets(getBoolStr(settingsArr[8]), 8, sel),
			{ rPos, baseH + spacer * 9 }, 
			getSelSize(8, sel), align_center, gwidth() * 0.75, 0, {1, 1}, getSelCol(8, sel))
		drawTextEx(getSelBrackets(getBoolStr(settingsArr[9]), 9, sel),
			{ rPos, baseH + spacer * 10 }, 
			getSelSize(9, sel), align_center, gwidth() * 0.75, 0, {1, 1}, getSelCol(9, sel))
		
		update()
		
		if menuDirInputStarted(c, false) then
			var snd = true
			loop if c.ly < -0.3 or c.down then
				sel = wrapIncClamp(sel + 1, 0, 11)
				break endif
			if c.ly > 0.3 or c.up then
				sel = wrapIncClamp(sel - 1, 0, 11)
				break endif
			if c.lx < -0.3 or c.left then
				if sel < len(settingsArr) then
					settingsArr[sel] = wrapIncClamp(settingsArr[sel] - 1, settingsRange[sel][0], settingsRange[sel][1])
				else
					snd = false
				endif
				break endif
			if c.lx > 0.3 or c.right then
				if sel < len(settingsArr) then
					settingsArr[sel] = wrapIncClamp(settingsArr[sel] + 1, settingsRange[sel][0], settingsRange[sel][1])
				else
					snd = false
				endif
				break
			endif break repeat
			
			if snd then
				playAudio(g_menuChan, g_menuSnd, g_vol - 0.5, 0.5, getRndPitch(0.8, 1.2), 0)
			endif
		endif
		
		if c.a and !g_cDat[g_cIdx.a].held then
			if sel <= 9 then
				settingsArr[sel] = wrapIncClamp(settingsArr[sel] + 1, settingsRange[sel][0], settingsRange[sel][1])
				playAudio(g_menuChan, g_menuSnd, g_vol - 0.5, 0.5, getRndPitch(0.8, 1.2), 0)
				g_cDat[g_cIdx.a].held = true
			else if sel == 10 then
				needSettingsTest = true
			endif endif
		endif
	repeat
	
	g_settings = [
		.useMot = settingsArr[0],
		.useMotPan = settingsArr[1],
		.motXSens = settingsArr[2],
		.motYSens = settingsArr[3],
		.invMotX = settingsArr[4],
		.invMotY = settingsArr[5],
		.stickXSens = settingsArr[6],
		.stickYSens = settingsArr[7],
		.invStickX = settingsArr[8],
		.invStickY = settingsArr[9]
	]
	
	playAudio(g_menuChan, g_menuSnd, g_vol - 0.5, 0.5, getRndPitch(0.8, 1.2), 0)
	g_cDat[g_cIdx.a].held = true
	
	if !needSettingsTest then
		clear()
		drawTextEx("Pondering your preferences ...", { gwidth() / 2, gheight() / 2 }, 
			0.25, align_center, gwidth(), 0, {1, 1}, white)
		update()
		
		writeGameSettings()
	endif
return needSettingsTest

/* Launch stage 1 map to test settings. */
function runSettingsTest()
	var c = controls(0)
	
	setNeutralOrientation()
	g_cam.pos = g_stageDat[0].camPos
	g_cam.fwd = g_stageDat[0].camFwd
	g_cam.up = g_stageDat[0].camUp
	
	while !c.a or g_cDat[g_cIdx.a].held loop
		c = controls(0)
		
		if !c.a then
			g_cDat[g_cIdx.a].held = false
		endif
		
		updateGameCam(controls(0))
		drawObjects()
		
		drawTextEx("Press (A) to return", { gwidth() * 0.025, gheight() * 0.95 }, 
			0.25, align_center_left, gwidth(), 0, {1, 1}, white)
		update()
	repeat
	
	playAudio(g_menuChan, g_menuSnd, g_vol - 0.5, 0.5, getRndPitch(0.8, 1.2), 0)
	g_cDat[g_cIdx.a].held = true
return void

/* Story screen. */
function showWhat()
	var timer = time()
	
	var c = controls(0)
	while !c.a or g_cDat[g_cIdx.a].held or time() - timer < g_dismissDelay loop
		c = controls(0)
		
		if !c.a then
			g_cDat[g_cIdx.a].held = false
		endif

		clear()
		drawTextEx("You are a benevolent mouse god who wants only the best for the mice of the world. What the mice of the world want is cheese, and lots of it! Fortunately for them, your godly powers include access to a large supply of cheese. Unfortunately for them, you can't do anything about cats." + chr(10) + chr(10) +
			"And there are a lot of cats in the world. If those hungry mice could think about anything other than cheese, they might realize the danger, but they're absolutely incapable of thinking two thoughts at the same time." + chr(10) + chr(10) +
			"Looks like it's up to you to use your delicious cheese to lure them into safe hiding spots where the cats won't find them. A mouse god's work is never done.", 
			{ gwidth() * 0.125, gheight() / 2 }, 
			0.25, align_center_left, gwidth() * 0.75, 0, {1, 1}, white)
		
		update()
	repeat
	
	playAudio(g_menuChan, g_menuSnd, g_vol - 0.5, 0.5, getRndPitch(0.8, 1.2), 0)
	g_cDat[g_cIdx.a].held = true
return void

/* Instructions screen. */
function showHow()
	var timer = time()
	
	var c = controls(0)
	while !c.a or g_cDat[g_cIdx.a].held or time() - timer < g_dismissDelay loop
		c = controls(0)
		
		if !c.a then
			g_cDat[g_cIdx.a].held = false
		endif

		clear()
		drawTextEx("Use cheese to lure the mouse into the hiding spot." + chr(10) + chr(10) +
			"(A) -- Hold to charge a throw, release to throw yellow cheese" + chr(10) +
			"(Y) -- Hold to charge a throw, release to throw green cheese that makes the mouse jump" + chr(10) + chr(10) +
			"The mouse will always go for the oldest cheese (even if it's fallen into the abyss). If the mouse hasn't eaten it, cheese will disappear after several seconds." + chr(10) + chr(10) +
			"Use the control stick to pan the camera and aim your throw." + chr(10) + chr(10) +
			"Hold (B) to restart the stage." + chr(10) + chr(10) +
			"If using motion controls, press (X) to redefine the controller's neutral position." + chr(10) + chr(10) +
			"Press (A) for menu selection and to dismiss text." + chr(10) + chr(10) +
			"Careful -- when the countdown reaches zero, the cat shows up!", 
			{ gwidth() * 0.125, gheight() / 2 }, 
			0.25, align_center_left, gwidth() * 0.75, 0, {1, 1}, white)
		
		update()
	repeat
	
	playAudio(g_menuChan, g_menuSnd, g_vol - 0.5, 0.5, getRndPitch(0.8, 1.2), 0)
	g_cDat[g_cIdx.a].held = true
return void

/* Stage end card. */
function showStageEnd(_stageIdx)
	stopChannel(g_throwChan)
	playAudio(g_menuChan, g_winSnd, g_vol - 0.5, 0.5, getRndPitch(0.8, 1.2), 0)
	var timer = time()
	g_cDat[g_cIdx.a].held = true
	
	var c = controls(0)
	while !c.a or g_cDat[g_cIdx.a].held or time() - timer < g_dismissDelay loop
		c = controls(0)
		
		if !c.a then
			g_cDat[g_cIdx.a].held = false
		endif

		clear()
		drawTextEx(g_stageDat[_stageIdx].endInfo, 
			{ gwidth() / 2, gheight() / 2 }, 
			0.25, align_center, gwidth() * 0.75, 0, {1, 1}, white)
		
		update()
	repeat
	
	playAudio(g_menuChan, g_menuSelSnd, g_vol - 0.5, 0.5, getRndPitch(0.8, 1.2) * -1, 0)
	g_cDat[g_cIdx.a].held = true
return void

/* Game stats screen. */
function showStats()
	g_stats.throwsEatenPct = (g_stats.throwsEaten / (g_stats.throwsGreen + g_stats.throwsYellow)) * 100
	g_stats.deathsTotal = g_stats.deathsReset + g_stats.deathsFall + g_stats.deathsCat
	g_stats.throwsTotal = g_stats.throwsGreen + g_stats.throwsYellow
	
	var newBest = [
		false, false, false, false, false, false, false, false, false, false, false
	]
	
	if g_curStage == len(g_stageDat) - 1 then		
		var needWrite = false
	
		if g_stats.deathsFall < g_bestStats.deathsFall or g_bestStats.deathsFall < 0 then
			g_bestStats.deathsFall = g_stats.deathsFall
			newBest[0] = true
			needWrite = true
		endif
		
		if g_stats.deathsCat < g_bestStats.deathsCat or g_bestStats.deathsCat < 0 then
			g_bestStats.deathsCat = g_stats.deathsCat
			newBest[1] = true
			needWrite = true
		endif
		
		if g_stats.deathsReset < g_bestStats.deathsReset or g_bestStats.deathsReset < 0 then
			g_bestStats.deathsReset = g_stats.deathsReset
			newBest[2] = true
			needWrite = true
		endif
		
		if g_stats.deathsTotal < g_bestStats.deathsTotal or g_bestStats.deathsTotal < 0 then
			g_bestStats.deathsTotal = g_stats.deathsTotal
			newBest[3] = true
			needWrite = true
		endif
		
		if g_stats.throwsYellow < g_bestStats.throwsYellow or g_bestStats.throwsYellow < 0 then
			g_bestStats.throwsYellow = g_stats.throwsYellow
			newBest[4] = true
			needWrite = true
		endif
		
		if g_stats.throwsGreen < g_bestStats.throwsGreen or g_bestStats.throwsGreen < 0 then
			g_bestStats.throwsGreen = g_stats.throwsGreen
			newBest[5] = true
			needWrite = true
		endif
		
		if g_stats.throwsTotal < g_bestStats.throwsTotal or g_bestStats.throwsTotal < 0 then
			g_bestStats.throwsTotal = g_stats.throwsTotal
			newBest[6] = true
			needWrite = true
		endif
		
		if g_stats.throwsEatenPct > g_bestStats.throwsEatenPct or g_bestStats.throwsEatenPct < 0 then
			g_bestStats.throwsEatenPct = g_stats.throwsEatenPct
			newBest[7] = true
			needWrite = true
		endif
		
		if g_stats.throwsFall < g_bestStats.throwsFall or g_bestStats.throwsFall < 0 then
			g_bestStats.throwsFall = g_stats.throwsFall
			newBest[8] = true
			needWrite = true
		endif
		
		if g_stats.catsSeen < g_bestStats.catsSeen or g_bestStats.catsSeen < 0 then
			g_bestStats.catsSeen = g_stats.catsSeen
			newBest[9] = true
			needWrite = true
		endif
		
		if g_stats.totalTime < g_bestStats.totalTime or g_bestStats.totalTime < 0 then
			g_bestStats.totalTime = g_stats.totalTime
			newBest[10] = true
			needWrite = true
		endif
		
		if needWrite then
			clear()
			drawTextEx("Writing songs about your exploits ...", { gwidth() / 2, gheight() / 2 }, 
				0.25, align_center, gwidth(), 0, {1, 1}, white)
			update()
				
			writeBestStats()
		endif
	endif
	
	var timer = time()
	g_cDat[g_cIdx.a].held = true
	
	var c = controls(0)
	while !c.a or g_cDat[g_cIdx.a].held or time() - timer < g_dismissDelay loop
		c = controls(0)
		
		if !c.a then
			g_cDat[g_cIdx.a].held = false
		endif
		
		clear()
		drawTextEx("STATS", { gwidth() / 2, gheight() / 9 }, 
			0.25, align_center, gwidth(), 0, {1, 1}, white)
		
		printStats(g_stats, newBest, false)
		update()
	repeat
	
	playAudio(g_menuChan, g_menuSelSnd, g_vol - 0.5, 0.5, getRndPitch(0.8, 1.2) * -1, 0)
	g_cDat[g_cIdx.a].held = true	
return void

/* Best game stats screen. */
function showBestStats()
	var newBest = [
		false, false, false, false, false, false, false, false, false, false, false
	]
	var reset = false
	var sel = 0
	
	var timer = time()
	g_cDat[g_cIdx.a].held = true
	
	var c = controls(0)
	while (!c.a or g_cDat[g_cIdx.a].held or time() - timer < g_dismissDelay) and !reset loop
		c = controls(0)
		
		if !c.a then
			g_cDat[g_cIdx.a].held = false
		endif
		
		clear()
		drawTextEx("BEST STATS", { gwidth() / 2, gheight() / 9 }, 
			0.25, align_center, gwidth(), 0, {1, 1}, white)
		
		printStats(g_bestStats, newBest, true)
		
		drawTextEx("Return", { gwidth() * 0.25, gheight() * 0.9 }, 
			getSelSize(0, sel), align_center, gwidth(), 0, {1, 1}, getSelCol(0, sel))
		
		drawTextEx("Reset best stats", { gwidth() * 0.7, gheight() * 0.9 }, 
			getSelSize(1, sel), align_center, gwidth(), 0, {1, 1}, getSelCol(1, sel))
		
		update()
		
		if menuDirInputStarted(c, false) then
			var snd = false
			
			loop if c.lx < -0.3 or c.left then
				sel = wrapIncClamp(sel - 1, 0, 1)
				snd = true
				break endif
			if c.lx > 0.3 or c.right then
				sel = wrapIncClamp(sel + 1, 0, 1)
				snd = true
				break
			endif break repeat
			
			if snd then
				playAudio(g_menuChan, g_menuSnd, g_vol - 0.5, 0.5, getRndPitch(0.8, 1.2), 0)
			endif
		endif
		
		if c.a and !g_cDat[g_cIdx.a].held then
			if sel then
				reset = showResetBestStatsPrompt()
				sel = 0
			endif
		endif
	repeat
	
	playAudio(g_menuChan, g_menuSelSnd, g_vol - 0.5, 0.5, getRndPitch(0.8, 1.2) * -1, 0)
	g_cDat[g_cIdx.a].held = true	
return void

/* Asks for confirmation of stats reset. */
function showResetBestStatsPrompt()
	var sel = 0
	var reset = false
	var timer = time()
	g_cDat[g_cIdx.a].held = true
	
	var c = controls(0)
	while !c.a or g_cDat[g_cIdx.a].held or time() - timer < g_dismissDelay loop
		c = controls(0)
		
		if !c.a then
			g_cDat[g_cIdx.a].held = false
		endif
		
		clear()
		drawTextEx("Really reset best stats?" + chr(10) + chr(10) + 
			"(Think of all the mice who perished in pursuit of these records ...)", { gwidth() / 2, gheight() / 3 }, 
			0.25, align_center, gwidth(), 0, {1, 1}, white)
		
		drawTextEx("No, don't reset", { gwidth() * 0.3, gheight() * 0.66 }, 
			getSelSize(0, sel), align_center, gwidth(), 0, {1, 1}, getSelCol(0, sel))
		
		drawTextEx("Yes, reset", { gwidth() * 0.7, gheight() * 0.66 }, 
			getSelSize(1, sel), align_center, gwidth(), 0, {1, 1}, getSelCol(1, sel))
		
		update()
		
		if menuDirInputStarted(c, false) then
			var snd = false
			loop if c.lx < -0.3 or c.left then
				sel = wrapIncClamp(sel - 1, 0, 1)
				snd = true
				break endif
			if c.lx > 0.3 or c.right then
				sel = wrapIncClamp(sel + 1, 0, 1)
				snd = true
				break
			endif break repeat
			
			if snd then
				playAudio(g_menuChan, g_menuSnd, g_vol - 0.5, 0.5, getRndPitch(0.8, 1.2), 0)
			endif
		endif
		
		if c.a and !g_cDat[g_cIdx.a].held then
			if sel then
				clear()
				drawTextEx("The mice are forgetting ...", { gwidth() / 2, gheight() / 2 }, 
					0.25, align_center, gwidth(), 0, {1, 1}, white)
				update()
				
				deleteBestStats()
				
				reset = true
				g_bestStats = [
					.deathsFall = -1,
					.deathsCat = -1,
					.deathsReset = -1,
					.deathsTotal = -1,
					.catsSeen = -1,
					.throwsYellow = -1,
					.throwsGreen = -1,
					.throwsTotal = -1,
					.throwsFall = -1,
					.throwsEatenPct = -1,
					.totalTime = -1
				]
			endif
		endif
	repeat
	
	playAudio(g_menuChan, g_menuSelSnd, g_vol - 0.5, 0.5, getRndPitch(0.8, 1.2) * -1, 0)
	g_cDat[g_cIdx.a].held = true		
return reset

/* Prints stats table. */
function printStats(_stats, _newBest, _showingBest)
	var sec = mod(_stats.totalTime, 60)
	var secStr = floatToStr(sec, 2)
	
	if sec < 10 then
		secStr = "0" + secStr
	endif
	
	var fields
	
	if _showingBest then
		fields = [
			"Fewest fall deaths:",
			"Fewest cat deaths:",
			"Fewest restart deaths:",
			"Fewest total deaths:",
			"Least yellow cheese thrown:",
			"Least green cheese thrown:",
			"Least total cheese thrown:",
			"Most cheese eaten:",
			"Least cheese fed to the abyss:",
			"Fewest cats seen:",
			"Shortest completion time:"
		]
	else
		fields = [
			"Fall deaths",
			"Cat deaths:",
			"Restart deaths:",
			"Total deaths:",
			"Yellow cheese thrown:",
			"Green cheese thrown:",
			"Total cheese thrown:",
			"Cheese eaten:",
			"Cheese fed to the abyss:",
			"Cats seen:",
			"Completion time:"
		]
	endif
	
	drawTextEx(chr(10) + chr(10) + fields[0] + chr(10) + 
		fields[1] + chr(10) + 
		fields[2] + chr(10) +
		fields[3] + chr(10) + chr(10) +
		fields[4] + chr(10) +
		fields[5] + chr(10) +
		fields[6] + chr(10) + chr(10) +
		fields[7] + chr(10) +
		fields[8] + chr(10) + chr(10) +
		fields[9] + chr(10) + chr(10) +
		fields[10],
		{ gwidth() * 0.25, gheight() / 2.2 }, 
		0.25, align_center_left, gwidth() * 0.75, 0, {1, 1}, white)
	
	drawTextEx(chr(10) + chr(10) + _stats.deathsFall + getNewBestStr(_newBest, 0) + chr(10) + 
		_stats.deathsCat + getNewBestStr(_newBest, 1) + chr(10) + 
		_stats.deathsReset + getNewBestStr(_newBest, 2) + chr(10) +
		_stats.deathsTotal + getNewBestStr(_newBest, 3) + chr(10) + chr(10) +
		_stats.throwsYellow + getNewBestStr(_newBest, 4) + chr(10) +
		_stats.throwsGreen + getNewBestStr(_newBest, 5) + chr(10) +
		_stats.throwsTotal + getNewBestStr(_newBest, 6) + chr(10) + chr(10) +
		floatToStr(_stats.throwsEatenPct, 2) + "%" + getNewBestStr(_newBest, 7) + chr(10) +
		_stats.throwsFall + getNewBestStr(_newBest, 8) + chr(10) + chr(10) +
		_stats.catsSeen + getNewBestStr(_newBest, 9) + chr(10) + chr(10) +
		int(floor(_stats.totalTime / 60)) + ":" + secStr + getNewBestStr(_newBest, 10),
		{ gwidth() * 0.75, gheight() / 2.2 }, 
		0.25, align_center_right, gwidth() * 0.75, 0, {1, 1}, white)
return void

/* Initializes stats. */
function resetStats()
	g_stats = [
		.deathsFall = 0,
		.deathsCat = 0,
		.deathsReset = 0,
		.deathsTotal = 0,
		.catsSeen = 0,
		.throwsYellow = 0,
		.throwsGreen = 0,
		.throwsTotal = 0,
		.throwsFall = 0,
		.throwsEaten = 0,
		.throwsEatenPct = 0,
		.totalTime = 0
	]
return void

/* Flags new best stats at end of game stats screen. */
function getNewBestStr(_arr, _idx)
	var bestStr = ""
	
	if _arr[_idx] then
		bestStr = " (new best!)"
	endif
return  bestStr

/* Game over screen. */
function showGameOver()
	var quit = false
	var timer = time()
	
	if g_throwPower then
		g_cDat[g_cIdx.a].held = true
		g_cDat[g_cIdx.y].held = true
		g_throwPower = 0
	endif
	
	stopChannel(g_throwChan)
	clearActors()
	playAudio(g_menuChan, g_failSnd, g_vol - 0.5, 0.5, getRndPitch(0.8, 1.2), 0)
	
	var text = getGameOverText()
	
	var c = controls(0)
	while ((!c.a or g_cDat[g_cIdx.a].held) and (!c.y or g_cDat[g_cIdx.y].held)) 
			or time() - timer < g_dismissDelay loop
		c = controls(0)
		
		if !c.a then
			g_cDat[g_cIdx.a].held = false
		endif
		
		if !c.y then
			g_cDat[g_cIdx.y].held = false
		else
			quit = true
		endif
		
		clear()
		
		drawTextEx(text, { gwidth() / 2, gheight() / 3 }, 0.75, align_center, 
			gwidth(), 0, {1, 1}, white)
		drawTextEx("Press (A) to try again or (Y) to return to the title screen", { gwidth() / 2, gheight() / 3 + gheight() / 3 }, 
			0.25, align_center, gwidth(), 0, {1, 1}, white)
		
		update()
	repeat
	
	if c.a then
		g_cDat[g_cIdx.a].held = true
	endif
	
	if c.y then
		g_cDat[g_cIdx.y].held = true
	endif
return quit

/* Random game over string. */
function getGameOverText()
	var text = [
		"Oops!",
		"Too bad",
		"YOU DIED",
		"Game Over",
		"Try again",
		"Nice try",
		"Oh no!",
		"Yikes!",
		"Continue?",
		"NEW HIGH SCORE",
		"Don't give up!",
		"You're getting better at this!",
		"So close!",
		"Almost!",
		"You'll get it next time!"
	]
return text[rnd(len(text))]

/* Splash screen for game image. Not normally shown in the game but can be viewed by uncommenting the function call. */
function showSplash()
	clearMap()
	var mapFile = openFile()
	readObjMap(mapFile, "Title Scene")
	closeFile(mapFile)
	
	g_cam.pos = {-1.811072, 5.732574, 2.270597}
	g_cam.fwd = {-0.086969, -0.210776, 0.973663}
	g_cam.up = {-0.018752, 0.977535, 0.209939}
	g_cam.r = normalize(cross(g_cam.fwd, g_cam.up))
	g_cam.dir = g_cam.pos + g_cam.fwd
	setCamera(g_cam.pos, g_cam.dir)
	
	loop
		drawObjects()
		
		drawTextEx("CHEESE, PLEASE", {gwidth() / 2 + gwidth() / 164, gheight() / 7 + gwidth() / 164}, 1.25, align_center, gwidth(), 0, {1, 1, 1}, gold)
		drawTextEx("CHEESE, PLEASE", {gwidth() / 2, gheight() / 7}, 1.25, align_center, gwidth(), 0, {1, 1, 1}, yellow)
		
		update()
	repeat
return void

	// ----------------------------------------------------------------
	// FILE READ

function readGameSettings(_file)
	var sectionIdx = findFileSection(_file, "gameSettings")
	var chunk = getNextFileChunk(_file, sectionIdx.start) // Section
	var field
	
	while inFileSection(chunk) loop
		chunk = getNextFileChunk(_file, chunk.nextIdx) // Block
		while inFileBlock(chunk) loop
			chunk = getNextFileChunk(_file, chunk.nextIdx) // Unit
			while inFileUnit(chunk) loop
				chunk = getNextFileChunk(_file, chunk.nextIdx) // Field
				field = chunk.dat
				
				array elem[0]
				while inFileField(chunk) loop
					chunk = getNextFileChunk(_file, chunk.nextIdx) // Elem
					elem = push(elem, chunk.dat)
				repeat
				
				loop if field == ".useMot" then
					g_settings.useMot = decodeElem(elem)
					break endif
				if field == ".motXSens" then
					g_settings.motXSens = decodeElem(elem)
					break endif
				if field == ".motYSens" then
					g_settings.motYSens = decodeElem(elem)
					break endif
				if field == ".useMotPan" then
					g_settings.useMotPan = decodeElem(elem)
					break endif
				if field == ".invMotX" then
					g_settings.invMotX = decodeElem(elem)
					break endif
				if field == ".invMotY" then
					g_settings.invMotY = decodeElem(elem)
					break endif
				if field == ".stickXSens" then
					g_settings.stickXSens = decodeElem(elem)
					break endif
				if field == ".stickYSens" then
					g_settings.stickYSens = decodeElem(elem)
					break endif
				if field == ".invStickX" then
					g_settings.invStickX = decodeElem(elem)
					break endif
				if field == ".invStickY" then
					g_settings.invStickY = decodeElem(elem)
					break
				endif break repeat
			repeat
		repeat
	repeat
return void

function readBestStats(_file)
	var sectionIdx = findFileSection(_file, "bestStats")
	var chunk = getNextFileChunk(_file, sectionIdx.start) // Section
	var field
	
	while inFileSection(chunk) loop
		chunk = getNextFileChunk(_file, chunk.nextIdx) // Block
		while inFileBlock(chunk) loop
			chunk = getNextFileChunk(_file, chunk.nextIdx) // Unit
			while inFileUnit(chunk) loop
				chunk = getNextFileChunk(_file, chunk.nextIdx) // Field
				field = chunk.dat
				
				array elem[0]
				while inFileField(chunk) loop
					chunk = getNextFileChunk(_file, chunk.nextIdx) // Elem
					elem = push(elem, chunk.dat)
				repeat
				
				loop if field == ".deathsFall" then
					g_bestStats.deathsFall = decodeElem(elem)
					break endif
				if field == ".deathsCat" then
					g_bestStats.deathsCat = decodeElem(elem)
					break endif
				if field == ".deathsReset" then
					g_bestStats.deathsReset = decodeElem(elem)
					break endif
				if field == ".deathsTotal" then
					g_bestStats.deathsTotal = decodeElem(elem)
					break endif
				if field == ".catsSeen" then
					g_bestStats.catsSeen = decodeElem(elem)
					break endif
				if field == ".throwsYellow" then
					g_bestStats.throwsYellow = decodeElem(elem)
					break endif
				if field == ".throwsGreen" then
					g_bestStats.throwsGreen = decodeElem(elem)
					break endif
				if field == ".throwsTotal" then
					g_bestStats.throwsTotal = decodeElem(elem)
					break endif
				if field == ".throwsFall" then
					g_bestStats.throwsFall = decodeElem(elem)
					break endif
				if field == ".throwsEatenPct" then
					g_bestStats.throwsEatenPct = decodeElem(elem)
					break endif
				if field == ".totalTime" then
					g_bestStats.totalTime = decodeElem(elem)
					break
				endif break repeat
			repeat
		repeat
	repeat
return void

	// ----------------------------------------------------------------
	// FILE WRITE

function writeGameSettings()
return writeGameSettings(-1, true)

function writeGameSettings(_file)
return writeGameSettings(_file, false)

function writeGameSettings(_file, _needFileOpen)
	_file = openFileIfNeeded(_file, _needFileOpen)
	
	var sectionIdx = findFileSection(_file, "gameSettings")
	if sectionIdx.start < 0 then
		sectionIdx.start = getEofIdx(_file)
		sectionIdx.end = sectionIdx.start
	endif
	
	var writeStr = sectionStr("gameSettings" + versionStr())
	writeStr += blockStr("")
	writeStr += unitStr("")
	writeStr += fieldStr(".useMot")
	writeStr += elemStr(g_settings.useMot)
	writeStr += fieldStr(".motXSens")
	writeStr += elemStr(g_settings.motXSens)
	writeStr += fieldStr(".motYSens")
	writeStr += elemStr(g_settings.motYSens)
	writeStr += fieldStr(".useMotPan")
	writeStr += elemStr(g_settings.useMotPan)
	writeStr += fieldStr(".invMotX")
	writeStr += elemStr(g_settings.invMotX)
	writeStr += fieldStr(".invMotY")
	writeStr += elemStr(g_settings.invMotY)
	writeStr += fieldStr(".stickXSens")
	writeStr += elemStr(g_settings.stickXSens)
	writeStr += fieldStr(".stickYSens")
	writeStr += elemStr(g_settings.stickYSens)
	writeStr += fieldStr(".invStickX")
	writeStr += elemStr(g_settings.invStickX)
	writeStr += fieldStr(".invStickY")
	writeStr += elemStr(g_settings.invStickY)
	writeFileSegment(_file, writeStr, sectionIdx.start, sectionIdx.end)
	
	closeFileIfNeeded(_file, _needFileOpen)
return void

function writeBestStats()
return writeBestStats(-1, true)

function writeBestStats(_file)
return writeBestStats(_file, false)

function writeBestStats(_file, _needFileOpen)
	_file = openFileIfNeeded(_file, _needFileOpen)
	
	var sectionIdx = findFileSection(_file, "bestStats")
	if sectionIdx.start < 0 then
		sectionIdx.start = getEofIdx(_file)
		sectionIdx.end = sectionIdx.start
	endif
	
	var writeStr = sectionStr("bestStats" + versionStr())
	writeStr += blockStr("")
	writeStr += unitStr("")
	writeStr += fieldStr(".deathsFall")
	writeStr += elemStr(g_bestStats.deathsFall)
	writeStr += fieldStr(".deathsCat")
	writeStr += elemStr(g_bestStats.deathsCat)
	writeStr += fieldStr(".deathsReset")
	writeStr += elemStr(g_bestStats.deathsReset)
	writeStr += fieldStr(".deathsTotal")
	writeStr += elemStr(g_bestStats.deathsTotal)
	writeStr += fieldStr(".catsSeen")
	writeStr += elemStr(g_bestStats.catsSeen)
	writeStr += fieldStr(".throwsYellow")
	writeStr += elemStr(g_bestStats.throwsYellow)
	writeStr += fieldStr(".throwsGreen")
	writeStr += elemStr(g_bestStats.throwsGreen)
	writeStr += fieldStr(".throwsTotal")
	writeStr += elemStr(g_bestStats.throwsTotal)
	writeStr += fieldStr(".throwsFall")
	writeStr += elemStr(g_bestStats.throwsFall)
	writeStr += fieldStr(".throwsEatenPct")
	writeStr += elemStr(g_bestStats.throwsEatenPct)
	writeStr += fieldStr(".totalTime")
	writeStr += elemStr(g_bestStats.totalTime)
	writeFileSegment(_file, writeStr, sectionIdx.start, sectionIdx.end)
	
	closeFileIfNeeded(_file, _needFileOpen)
return void

function deleteBestStats()
return deleteBestStats(-1, true)

function deleteBestStats(_file)
return deleteBestStats(_file, false)

function deleteBestStats(_file, _needFileOpen)
	_file = openFileIfNeeded(_file, _needFileOpen)
	
	var sectionIdx = findFileSection(_file, "bestStats")
	
	if sectionIdx.start >= 0 then
		writeFileSegment(_file, "", sectionIdx.start, sectionIdx.end)
	endif
	
	closeFileIfNeeded(_file, _needFileOpen)
return void

// ----------------------------------------------------------------
// MAIN EXECUTION LOOP

loop
	loop if g_needStageLoad != -1 then
		//g_needStageLoad = 5 // DEBUG: Forces loading of a specific stage
		clearMap()
		var mapFile = openFile()
		g_currentMapName = g_stageDat[g_needStageLoad].name
		readObjMap(mapFile, g_currentMapName)
		closeFile(mapFile)
		initStage(g_needStageLoad, true)
		
		if len(g_arrow) then
			removeGenericObj(g_arrow[0])
			g_arrow = []
		endif
		
		g_arrow = push(g_arrow, 
			createArrowObj(g_stageDat[g_curStage].endPos + {0, 2, 0}, {0, -1, 0}, 2, 0.2, 1, lime, 0, 1, 1))
		g_needStageLoad = -1
		
		break endif
	if g_needSettingsTest then
		if g_currentMapName != g_stageDat[0].name then
			clearMap()
			var mapFile = openFile()
			g_currentMapName = g_stageDat[0].name
			readObjMap(mapFile, g_currentMapName)
			closeFile(mapFile)
		endif
		
		runSettingsTest()
		
		g_needSettingsTest = showSettings(10)
		break endif
	if g_curStage < 0 then
		var sel = showGameTitle(g_playTitleSnd)
		
		loop if sel == 0 then
			showWhat()
			g_playTitleSnd = false
			break endif
		if sel == 1 then
			showHow()
			g_playTitleSnd = false
			break endif
		if sel == 2 then
			g_needSettingsTest = showSettings(0)
			g_playTitleSnd = false
			break endif
		if sel == 3 and g_bestStats.totalTime >= 0 then
			showBestStats()
			break endif
		if (sel == 4 and g_bestStats.totalTime >= 0) or (sel == 3 and g_bestStats.totalTime < 0) then
			initStage(0, true)
			break
		else
			g_bye = true
			break
		endif break repeat
		
		break
	else
		updateAllActors()
		updateGameCam(controls(0))
		chargeThrow()
		updateThrow()
		
		updateCatTimer()
		checkCheeseCol()
		updateArrow()
		drawObjects()
		drawGameUi()
		
		var catQuit = checkStageEnd()
		var fallQuit = checkFall()
		var restartQuit = checkRestart()
		
		if fallQuit or catQuit or restartQuit then
			g_curStage = -1
			g_playTitleSnd = true
		endif
		
		g_stats.totalTime += deltaTime()
	endif break repeat
	
	if g_bye then
		break
	endif
	
	debug()

	update()
	g_frame += 1
repeat

// ----------------------------------------------------------------
// STRUCTS

/* Stores information about an object's collision state. */
// CORE LOADER
struct colContext
	int cell = -1
	vector cellPos = {float_max, float_max, float_max}
	vector comPos = {float_max, float_max, float_max}
	vector colPos = {float_max, float_max, float_max}
	vector scale = {1, 1, 1}
	vector colScale = {float_max, float_max, float_max}
	vector fwd = {0, 0, 1}
	vector colFwd = {float_max, float_max, float_max}
	vector up = {0, 1, 0}
	vector colUp = {float_max, float_max, float_max}
	extent ext = [ .lo = {0, 0, 0}, .hi = {0, 0, 0} ]
	float mass
	vector centerOfMass
	vector dir
	vector delta
	vector grav
	vector vel
	vector rotVel
	vector rotVelAxis
	array gridBit[27][2]
	array objList[0]
	array collision[0]
	array colDepth[0]
	array normal[0]
	str normAxis
	int colThisFrame = false
	var deflectThisFrame = false
	int allCollisions = true
	int collisionMode = 3
	var colDat
	var auxCollider = -1
	var auxColCon = -1
	var continuedCol = false
endstruct

/* Stores info about objects placed in the map. Distinct from active, which is
a reduced dataset, and objDef, which is the basic info need to instantiate an
active or a mapObj. */
// CORE LOADER
struct mapObj
	var obj // Handle of an object or a group, or -1 if the mapObj contains a light
	vector fwd
	vector up
	vector scale
	vector pos
	int bankIdx
	array gridBitList[0]
	int highlight
	array children[0]
	array lights[0]
	array cellIdx[0]
	vector col
	vector mat 
endStruct

// Points to the cell and index that contains the object's data
// CORE LOADER
struct mapObjRef
	int cellIdx
endStruct

/* active is a relic -- it used to e a reduced dataset of mapObj, but
now mostly just recreates mapObj. Due for deprecation. */
// CORE LOADER
struct active
	string name
	var obj
	vector pos
	vector scale
	vector fwd
	vector up
	int bankIdx
	array children[0]
	array lights[0]
	int cellIdx = -1
	array gridBitList[0]
	vector col
	vector mat
endStruct

/* Info about a light. lightObjs placed in the map are always contained in the lights 
array of mapObj or active. They do not exist on their own. All light types use the
same kind of lightObj (distinguished by the name field), so not all fields are always
relevant to a given light. */
// CORE LOADER
struct lightObj
	var light
	string name
	var spr
	vector sprScale
	vector pos
	vector fwd
	float brightness
	vector col
	int res
	float spread
	float range
endStruct

// Extended input data.
struct button
	float lastTime
	int held
	int kbHeld
	int count
endStruct

// Bounding box that describes the dimensions of an object.
// CORE LOADER
struct extent
	vector lo
	vector hi
endStruct

// Data used to instantiate a mapObj or an active.
// CORE LOADER
struct objDef
	string name
	string file
	var obj
	extent ext
	vector scale
	array children[0]
	array lights[0]
endStruct

// ----------------------------------------------------------------
// FILE FUNCTIONS

	// ----------------------------------------------------------------
	// FILE WRITING

/* If g_freezeFile is true, g_mapFile will remain open and will be passed
to anything requesting a file open instead of newly opening the file. Because 
the file never closes, writes won't persist on program close, and because 
g_mapFile is only opened once, the file will never be reloaded from its saved 
state during the session. The result is that file changes will persist for 
the session but will roll back when the session is terminated. */
function openFile()
	var file
	
	if g_freezeFile then
		file = g_mapFile
	else
		file = open()
	endif
return file

/* Allows a function to optionally open a file if it isn't passed one as 
an argument. */
function openFileIfNeeded(_file, _needed)
	if _needed then
		_file = openFile()
	endif
return _file

/* If a file was opened via openFileIfNeeded(), closes it. */
function closeFileIfNeeded(_file, _needed)
	if _needed then
		closeFile(_file)
	endif
return void

/* Closes file, but only if allowed by g_freezeFile. */
function closeFile(_file)
	var closed = false
	if !g_freezeFile then
		close(_file)
		closed = true
	endif
return closed

/* An end buffer stores all file data past a given index and then writes that data 
to a new index when closed. This allows us to write data of an arbitrary size in the
middle of a file without worrying about overwriting what comes after it (if larger
than the original data) or leaving garbage data (if smaller than the original data). */
function openFileEndBuffer(_file, _idx)
	var unalloIdx = getEofIdx(_file)
	
	seek(_file, _idx)
return read(_file, unalloIdx - _idx)

/* Writes the file end buffer data back to the end of the file once other writes are done.  */
function closeFileEndBuffer(_file, _buffer, _idx)
	seek(_file, _idx)
	
	var lastData = len(_buffer) - 1
	if lastData > -1 then
		if lastData < len(_buffer) - 1 then
			_buffer = strSlice(_buffer, 0, lastData + 1)
		endif
		
		write(_file, _buffer)
		
		// Any data remaining in the file after the write point is garbage
		var i
		for i = _idx + lastData + 1 to len(_file) loop
			seek(_file, i)
			write(_file, chr(127))
		repeat
	/* If there's no buffer data, it means the buffer was taken from EOF, so erase
	everything from _idx on. */
	else
		var i
		for i = _idx to len(_file) loop
			seek(_file, i)
			write(_file, chr(127))
		repeat
	endif
return void

/* General-purpose file writer that automatically deals with the end buffer. */
function writeFileSegment(_file, _fileStr, _start, _end)
	var endBuf = openFileEndBuffer(_file, _end)
	seek(_file, _start)
	write(_file, _fileStr)
	closeFileEndBuffer(_file, endBuf, _start + len(_fileStr))
return void

	// ----------------------------------------------------------------
	// FILE READING

// Template for file reads
/*
function readFileTemplate(_file)
	var sectionIdx = findFileSection(_file, "section")
	var chunk = getNextFileChunk(_file, sectionIdx.start) // Section
	while inFileSection(chunk) loop
		chunk = getNextFileChunk(_file, chunk.nextIdx) // Block
		while inFileBlock(chunk) loop
			chunk = getNextFileChunk(_file, chunk.nextIdx) // Unit
			while inFileUnit(chunk) loop
				chunk = getNextFileChunk(_file, chunk.nextIdx) // Field
				while inFileField(chunk) loop
					chunk = getNextFileChunk(_file, chunk.nextIdx) // Elem
				repeat
			repeat
		repeat
	repeat
return void
*/

/* Light data are saved separately in the file from object data. This function
takes the object data and the light data and assembles them into a complete
object. */
// CORE LOADER
function buildObjMapMergedLight(_obj, _lightList)
	var i
	for i = 0 to len(_obj.lights) loop
		if len(_lightList) then
			_obj.lights[i] = _lightList[0]
			_lightList = remove(_lightList, 0)
		endif
	repeat
	
	var buildResult
	
	for i = 0 to len(_obj.children) loop
		if len(_lightList) then
			buildResult = buildObjMapMergedLight(_obj.children[i], _lightList)
			_obj.children[i] = buildResult.obj
			_lightList = buildResult.lights
		endif
	repeat
	
	var result = [
		.obj = _obj,
		.lights = _lightList
	]
return result

/* Constucts saved cell layout. */
// CORE LOADER
function readCellMap(_file, _mapName)
	var sectionIdx = findFileSection(_file, "cellMap" + _mapName)
	
	var field
	var chunk = getNextFileChunk(_file, sectionIdx.start) // Section
	
	while inFileSection(chunk) loop
		chunk = getNextFileChunk(_file, chunk.nextIdx) // Block
		while inFileBlock(chunk) loop
			chunk = getNextFileChunk(_file, chunk.nextIdx) // Unit
			array cellDat[2]
			
			while inFileUnit(chunk) loop
				chunk = getNextFileChunk(_file, chunk.nextIdx) // Field
				field = chunk.dat
				
				array elem[0]
				while inFileField(chunk) loop
					chunk = getNextFileChunk(_file, chunk.nextIdx) // Elem
					elem = push(elem, chunk.dat)
				repeat
				
				cellDat = decodeCellMap(field, elem, cellDat)
			repeat
			
			addCell(cellDat[0], cellDat[1])
		repeat
	repeat
return void

/* This stub function allows you to display a loading message based on the map
element that is currently loading. */
// CORE LOADER
function loadMapMsg(_mapName, _objName, _objPos)	
	clear()
	drawTextEx("Summoning rodents ...", { gwidth() / 2, gheight() / 2 }, 
		0.25, align_center, gwidth(), 0, {1, 1}, white)
	update()
return void

/* Restores a map from file. */
// CORE LOADER
function readObjMap(_file, _mapName)
	/* Objects are queued before placing them because lights are encoded as
	separate objects. We need to check subsequent objects to see if they're
	lights belonging to the current object before placing the current object. */
	function readObjMap_addQueued(_queued, _queuedLight, _mapName)
		/* If no lights have been loaded from file, load any lights
		from the obj def instead. */
		if len(_queuedLight[0].lights) == 0 then
			_queued[0].obj.lights = 
				g_obj[decodeBank(-1, _queued[0].obj.bankIdx)][decodeIdx(-1, _queued[0].obj.bankIdx)].lights
		endif
		
		var isGrp = false
		
		if (len(_queued[0].obj.children) or len(_queued[0].obj.lights)) and _queued[0].isMerged then
			isGrp = true
		endif
		
		_queued[0].obj = buildObjMapMergedLight(_queued[0].obj, _queuedLight[0].lights).obj
		placeObjFromTemplate(_queued[0].obj, isGrp)
		var mapObjName
		getMapObjName(mapObjName, _queued[0].obj)
		loadMapMsg(_mapName, mapObjName, _queued[0].obj.pos)
		
		_queued = remove(_queued, 0)
		_queuedLight = remove(_queuedLight, 0)
		
		var result = [
			.queuedObj = _queued,
			.queuedLight = _queuedLight
		]
	return result
	
	var loadTimer = time() // Debug timer
	var objTimer = 0
	var placementTimer = 0
	
	loadMapMsg(_mapName, "", 0)
	readCellMap(_file, _mapName)
	
	var redefHappened = false
	
	array queuedObj[0]
	array queuedLight[0]
	var fileLen = len(_file)
	var sectionIdx = findFileSection(_file, "objectMap" + _mapName)
	var currentDef = [
		.name = chr(127),
		.bank = -1,
		.idx = -1
	]
	
	var defResult
	var isMerged
	var isRedef
	var isDelDef
	var genResult
	var genObj
	var newObj
	var idxOffsetFromSection
	var nextIdxOffsetFromSection
	var redefResult = [
		.bank = -1,
		.idx = -1,
		.name = "",
		.isMerged = true
	]
	var addResult
	var lastIdx
		
	var chunk = getNextFileChunk(_file, sectionIdx.start) // Section
	while inFileSection(chunk) loop
		chunk = getNextFileChunk(_file, chunk.nextIdx) // Block
		currentDef.name = chunk.dat
		
		defResult = getObjDefBankIdx(currentDef.name)
		if defResult.bank >= 0 then
			currentDef.bank = defResult.bank
			currentDef.idx = defResult.idx
		endif
		
		isMerged = true
		isRedef = false
		isDelDef = false
		var gridBitList
		var mapObjName
		
		while inFileBlock(chunk) loop
			chunk = getNextFileChunk(_file, chunk.nextIdx) // Unit
			
			genResult = getGenObjFromFile(_file, chunk)
			chunk = genResult.chunk
			
			if !isDelDef then
				genObj = genResult.obj
				
				// If there's not a brightness value, this isn't a light object
				if genObj.brightness == -1 then
					
					newObj = createActiveFromGenericObj(genObj)
					
					if genObj.name != currentDef.name then
						defResult = getObjDefBankIdx(genObj.name)
						
						if defResult.bank >= 0 then
							currentDef.name = genObj.name
							currentDef.bank = defResult.bank
							currentDef.idx = defResult.idx
						endif
						
						if defResult.bank < 0 and g_editor then
							idxOffsetFromSection = chunk.idx - sectionIdx.start
							nextIdxOffsetFromSection = chunk.nextIdx - sectionIdx.start
							
							if !isRedef then
								edFunction(redefResult, "promptObjDefRelink", [ genObj.name, 1 ])
								
								/* The redef changed the file length, so refind our index 
								in the map section. */
								sectionIdx = findFileSection(_file, "objectMap" + _mapName)
								chunk.idx = sectionIdx.start + idxOffsetFromSection
								chunk.nextIdx = sectionIdx.start + nextIdxOffsetFromSection
							endif
							
							if redefResult.bank >= 0 then
								newObj = activeFromObjDef(redefResult.bank, redefResult.idx)
								
								getMapObjName(mapObjName, newObj)
								currentDef.name = mapObjName
								currentDef.bank = decodeBank(-1, newObj.bankIdx)
								currentDef.idx = decodeIdx(-1, newObj.bankIdx)
								isMerged = redefResult.isMerged
								isRedef = true
							else
								isDelDef = true
							endif
							
							redefHappened = true
						else if defResult.bank < 0 and !g_editor then // g_editor != 1: If an object def can't be found and we're in the Core Loader, ignore the def
							isDelDef = true
						endif endif
					endif
					
					if !isDelDef then
						newObj = activeFromObjDef(currentDef.bank, currentDef.idx)
						newObj.pos = genObj.pos
						newObj.scale = genObj.scale
						newObj.fwd = genObj.fwd
						newObj.up = genObj.up
						newObj.col = genObj.col
						newObj.mat = genObj.mat
						
						if decodeBank(-1, newObj.bankIdx) >= 0 and decodeIdx(-1, newObj.bankIdx) >= 0 then
							if len(queuedObj) then
								placementTimer = time()
								addResult = readObjMap_addQueued(queuedObj, queuedLight, _mapName)
								objTimer += time() - placementTimer
								queuedObj = addResult.queuedObj
								queuedLight = addResult.queuedLight
							endif
							
							queuedObj = push(queuedObj, [ .obj = newObj, .isMerged = isMerged ])
							queuedLight = push(queuedLight, [ .lights = [] ])
						endif
					endif
				else // If a light object
					var l = createLightObjFromGenericObj(genObj)
					
					if len(queuedObj) then
						lastIdx = len(queuedObj) - 1
						queuedLight[lastIdx].lights = push(queuedLight[lastidx].lights, l)
					endif
				endif
			endif
		repeat
		
		if len(queuedObj) then
			placementTimer = time()
			addResult = readObjMap_addQueued(queuedObj, queuedLight, _mapName)
			objTimer += time() - placementTimer
			queuedObj = addResult.queuedObj
			queuedLight = addResult.queuedLight
		endif
	repeat
	
	var props = readMapProperties(_file, _mapName)
	setEnvironment(props.bg.idx, props.bg.col)
	
	// Uncomment for load time stats
	/*
	debugPrint(0, ["Map read time: " + str(time() - loadTimer - objTimer),
		"Object placement time: " + str(objTimer),
		"Total load time: " + str(time() - loadTimer)])
	*/
	result = [
		.redefHappened = redefHappened,
		.props = props
	]
return result

/* Map properties are saved separately from map objects. */
// CORE LOADER
function readMapProperties(_file, _mapName)
	var propStruct = [
		.bg = [
			.col = {0.2, 0.2, 0.2},
			.idx = 6
		],
		.cam = [
			.pos = {0, 0, 0},
			.fwd = {0, 0, 1},
			.up = {0, 1, 0}
		],
		.cur = [ .pos = {0, 0, 0} ]
	]
	
	var sectionIdx = findFileSection(_file, "mapProperties" + _mapName)
	if sectionIdx.start >= 0 then
		var chunk = getNextFileChunk(_file, sectionIdx.start) // Section
		var field
		
		while inFileSection(chunk) loop
			chunk = getNextFileChunk(_file, chunk.nextIdx) // Block
			while inFileBlock(chunk) loop
				chunk = getNextFileChunk(_file, chunk.nextIdx) // Unit
				while inFileUnit(chunk) loop
					chunk = getNextFileChunk(_file, chunk.nextIdx) // Field
					field = chunk.dat
					
					array elem[0]
					while inFileField(chunk) loop
						chunk = getNextFileChunk(_file, chunk.nextIdx) // Elem
						elem = push(elem, chunk.dat)
					repeat
					
					propStruct = decodeMapProperties(field, elem, propStruct)
				repeat
			repeat
		repeat
	endif
return propStruct

/* Returns the end-of-file index or the index of the first unallocated space. */
function getEofIdx(_file)
	var eof = findFileChar(_file, chr(127))
	if eof < 0 then
		eof = len(_file)
	endif
return eof

/* A section is the highest-level file division, distinguishing between, for
example, map objects and map properties. */
// CORE LOADER
function findFileSection(_file, _section)
return findFileSection(_file, _section, 0, -1)

function findFileSection(_file, _section, _startAt, _endAt)
return findFileChunk(_file, chr(31) + _section, [ chr(31) ], _startAt, _endAt)

/* A chunk is a file section that exists between any two delimiters, which are
typically non-printing unicode characters. _endAt is non-inclusive. */
// CORE LOADER
function findFileChunk(_file, _searchStartStr, _searchEndStr, _startAt, _endAt)
	seek(_file, _startAt)
	fileStr = read(_file, len(_file) - _startAt)
	
	var startIdx = strFind(fileStr, _searchStartStr)
	var endIdx = -1
	
	if startIdx < _endAt or (_endAt < 0) then
		var i
		var newEnd
		
		for i = 0 to len(_searchEndStr) loop
			newEnd = strFind(fileStr[startIdx + 1:], _searchEndStr[i])
			
			if endIdx == -1 or newEnd < endIdx then
				endIdx = newEnd
			endif
		repeat
		
		if startIdx != -1 and endIdx == -1 then
			startIdx += _startAt
			endIdx = strFind(fileStr, chr(127)) // Find blank space in file.
			if endIdx == -1 then
				endIdx = len(fileStr)
			endif
		else if startIdx != -1 and (_endAt < 0 or endIdx < _endAt) then
			startIdx += _startAt
			endIdx += startIdx + 1 // Compensate for the search's string truncation.
		else
			endIdx = -1 // If there's no start, any end is invalid.
		endif endif
	else
		startIdx = -1
	endif
	
	var result = [
		.start = startIdx,
		.end = endIdx
	]
return result

/* Gets the index of a character within the file. Bails out if unallocated
space is encountered. */
// CORE LOADER
function findFileChar(_file, _char)
return findFileChar(_file, _char, 0)

function findFileChar(_file, _char, _startAt)
	seek(_file, _startAt)
	
	var idx = _startAt
	var charBuf = ""
	while charBuf != _char and charBuf != chr(127) loop
		seek(_file, idx)
		
		charBuf = read(_file, 1)
		if charBuf != _char then
			idx += 1
		endif
		
		if idx > len(_file) then
			idx = -1
			break
		endif
	repeat
return idx

/* Returns an array of the map names in the file. */
// CORE LOADER
function getMapNames(_file)
	array names[0]
	var fileResult = [
		.start = -1,
		.end = 0
	]
	
	var eof = false
	var nameEndIdx
	var versionIdx
	var nameStartIdx
	var nextName
	
	while !eof loop
		fileResult = findFileSection(_file, "objectMap", fileResult.start + 1, -1)
		if fileResult.start >= 0 then
			// Parse to version indicator if it exists, otherwise use section end.
			nameEndIdx = findFileChar(_file, chr(17), fileResult.start)
			versionIdx = findFileChar(_file, chr(18), fileResult.start)
			
			if versionIdx < nameEndIdx and versionIdx >= 0 then
				nameEndIdx = versionIdx
			endif
			
			if nameEndIdx >= 0 then
				nameStartIdx = fileResult.start + len("objectMap") + 1
				seek(_file, nameStartIdx)
				nextName = read(_file, nameEndIdx - nameStartIdx)
				names = push(names, nextName)
			endif
		else
			eof = true
		endif
	repeat
return names

/* Return the next file chunk as delimited by certain non-printing unicode characters 
that signify data purpose. */
// CORE LOADER
function getNextFileChunk(_file, _startIdx)
	seek(_file, _startIdx)
	
	var marker = read(_file, 1)
	var nextMarker = ""
	var nextIdx = _startIdx
	var dat = ""
	var char = ""
	var fileLen = len(_file)
	
	while nextIdx < fileLen loop
		nextIdx += 1
		seek(_file, nextIdx)
		
		char = read(_file, 1)
		if char == chr(31)
				or char == chr(30)
				or char == chr(29)
				or char == chr(28)
				or char == chr(17)
				or char == chr(127) then
			nextMarker = char
			break
		endif
		
		dat += char
	repeat
	
	var result = [
		.marker = marker,
		.idx = _startIdx,
		.nextMarker = nextMarker,
		.nextIdx = nextIdx,
		.dat = dat,
		.fileLen = len(_file)
	]
return result

/* The light definition bank cannot be modified by the user. These light
objects are fully defined in code and do not load from file. */
// CORE LOADER
function loadLightDefs()
	array defs[5]
	objDef newDef
	newDef.file = ""
	newDef.obj = -1
	newDef.ext.lo = {-0.25, -0.25, -0.25}
	newDef.ext.hi = {0.25, 0.25, 0.25}
	newDef.scale = {1, 1, 1}
	newDef.children = []
	lightObj l
	l = initLightObj()
	
	l.name = "point"
	newDef.name = "Point Light"
	newDef.lights = [ l ]
	defs[0] = newDef
	
	l.name = "pointshadow"
	newDef.name = "Point Shadow Light"
	newDef.lights = [ l ]
	defs[1] = newDef
	
	l.name = "spot"
	newDef.name = "Spot Light"
	newDef.lights = [ l ]
	defs[2] = newDef
	
	l.name = "world"
	newDef.name = "World Light"
	newDef.lights = [ l ]
	defs[3] = newDef
	
	l.name = "worldshadow"
	newDef.name = "World Shadow Light"
	newDef.lights = [ l ]
	defs[4] = newDef
return defs

/* The light definition bank cannot be modified by the user. These light
objects are fully defined in code and do not load from file. */
// CORE LOADER
function loadPrimitiveDefs()
	array defs[5]
	var objExt
	objDef newDef
	newDef.file = ""
	newDef.obj = -1
	newDef.scale = {1, 1, 1}
	newDef.children = []
	newDef.lights = []
	
	loadDefMsg("Primitives")
	
	newDef.name = "Cube"
	objExt = placeObject(cube, {0, 0, 0}, newDef.scale)
	newDef.ext = getObjExtent(objExt, {0, 0, 0}, newDef.scale, {0, 0, 1}, {0, 1, 0}, 0.001)
	removeObject(objExt)
	defs[0] = newDef
	
	newDef.name = "Cylinder"
	objExt = placeObject(cylinder, {0, 0, 0}, newDef.scale)
	newDef.ext = getObjExtent(objExt, {0, 0, 0}, newDef.scale, {0, 0, 1}, {0, 1, 0}, 0.001)
	removeObject(objExt)
	defs[1] = newDef
	
	newDef.name = "Hemisphere"
	objExt = placeObject(hemisphere, {0, 0, 0}, newDef.scale)
	newDef.ext = getObjExtent(objExt, {0, 0, 0}, newDef.scale, {0, 0, 1}, {0, 1, 0}, 0.001)
	removeObject(objExt)
	defs[2] = newDef
	
	newDef.name = "Sphere"
	objExt = placeObject(sphere, {0, 0, 0}, newDef.scale)
	newDef.ext = getObjExtent(objExt, {0, 0, 0}, newDef.scale, {0, 0, 1}, {0, 1, 0}, 0.001)
	removeObject(objExt)
	defs[3] = newDef
	
	newDef.name = "Wedge"
	objExt = placeObject(wedge, {0, 0, 0}, newDef.scale)
	newDef.ext = getObjExtent(objExt, {0, 0, 0}, newDef.scale, {0, 0, 1}, {0, 1, 0}, 0.001)
	removeObject(objExt)
	defs[4] = newDef
	
	/* FUZE cones and pyramids have incorrect bounding boxes, which causes glitchy collisions.
	This is not something that can be fixed on my end, so they're disabled. */
	/*
	newDef.name = "Cone"
	objExt = placeObject(cone, {0, 0, 0}, newDef.scale)
	newDef.ext = getObjExtent(objExt, {0, 0, 0}, newDef.scale, {0, 0, 1}, {0, 1, 0}, 0.001)
	removeObject(objExt)
	defs = push(defs, newDef)
	
	newDef.name = "Pyramid"
	objExt = placeObject(pyramid, {0, 0, 0}, newDef.scale)
	newDef.ext = getObjExtent(objExt, {0, 0, 0}, newDef.scale, {0, 0, 1}, {0, 1, 0}, 0.001)
	removeObject(objExt)
	defs = push(defs, newDef)
	*/
return defs

/* Loads unmerged object definitions from the banks created in getModels(). */
// CORE LOADER
function loadObjDefs(_file)
	var models = getModels()
	array obj[len(models)]
	array bankName[len(models)]
	var modelCount = 0 // Prevent user from loading more than FUZE's limit of 124 models
	
	var i
	var j
	
	for i = 0 to len(models) loop
		// Apply bank name from first entry or auto-generate
		if len(models[i][0]) != 2 then
			bankName[i] = models[i][0][0]
			models[i] = remove(models[i], 0)
		else
			bankName[i] = "Bank " + i
		endif
		
		objDef idx[len(models[i])]
		for j = 0 to len(idx) loop
			modelCount += 1
			
			if modelCount >= 125 then
				clear(black)
				ink(white)
				textSize(gheight() / 25)
				printAt(1, 1, 
"ERROR: FUZE has an internal limit of 124 3D models loaded, but you have more than 
124 object definitions.

Please exit Celqi, ensure that the getModels() function contains no more than 124 
object definitions, and restart Celqi.

If you have not already done so and are not using the definitions in your own maps, 
you may free up space by deleting the 'Castle Demo' bank from getModels(). You may 
also want to remove the 'Castle Demo' map using 'File > Manage maps ...' from within 
Celqi.

Press (+)/F5 to close Celqi."
				)
				update()
				
				// Force user to exit
				loop
				repeat
			endif
			
			idx[j] = loadObjDef(_file, models[i][j])
		repeat
		obj[i] = idx
	repeat
	
	obj[g_lightBank - 1] = loadPrimitiveDefs()
	obj[g_lightBank] = loadLightDefs()
	
	var result = [
		.obj = obj,
		.bankName = bankName
	]
return result

/* This stub function allows you to display a loading message based on the 
object defintion that is currently loading. */
// CORE LOADER
function loadDefMsg(_defName)
	clear()
	drawTextEx("Loading cheeses ...", { gwidth() / 2, gheight() / 2 }, 
		0.25, align_center, gwidth(), 0, {1, 1}, white)
	update()
return void

/* Loads an individual unmerged object definition, which includes calculating 
the extent. */
// CORE LOADER
function loadObjDef(_file, _modelDat)
	objDef def
	
	if len(_modelDat[0]) then
		def.name = _modelDat[0]
	else
		def.name = getDefaultDefName(_modelDat[1])
	endif
	
	loadDefMsg(def.name)
		
	def.file = _modelDat[1]
	def.obj = loadModel(_modelDat[1])
	var objExt = placeObject(def.obj, {0, 0, 0}, {1, 1, 1})
	def.ext = getObjExtent(objExt, {0, 0, 0}, {1, 1, 1}, {0, 0, 1}, {0, 1, 0}, 0.001)
	removeObject(objExt)
return def

/* Loads the merged object definitions, which are defined from within the program
rather than in getModels(). */
// CORE LOADER
function loadMergedObjDefs(_file)
	array mergedDefs[0]
	var sectionIdx = findFileSection(_file, "objectDefs")	
	var chunk = getNextFileChunk(_file, sectionIdx.start) // Section
	var isMerged
	var curChildIdx
	var bank
	var idx
	var bankStr
	var depth
	var maxDepth
	var parentResult
	var childResult
	var defRecord
		
	while inFileSection(chunk) loop
		chunk = getNextFileChunk(_file, chunk.nextIdx) // Block
		
		isMerged = true
		curChildIdx = -1
		bank = -1
		idx = -1
		bankStr = ""
		objDef def
		def.name = ""
		def.file = ""
		def.obj = -1
		def.ext.lo = {0, 0, 0}
		def.ext.hi = {0, 0, 0}
		def.scale = {1, 1, 1}
		def.children = []
		def.lights = []
		depth = [0]
		maxDepth = 0
		
		// Assemble parent
		while inFileBlock(chunk) and isMerged and def.name == "" loop
			parentResult = assembleMergedObjDefParent(_file, chunk, def)
			chunk = parentResult.chunk
			def = parentResult.def
			bankStr = parentResult.bankName
		repeat
		
		// Assemble children
		while inFileBlock(chunk) and def.name != "" loop
			childResult = assembleMergedObjDefChild(_file, chunk, def, curChildIdx)
			chunk = childResult.chunk
			def = childResult.def
			curChildIdx = childResult.curChildIdx
		repeat
		
		if len(def.children) or len(def.lights) then
			defRecord = loadAssembledMergedObjDef(def, bankStr)
			mergedDefs = push(mergedDefs, defRecord)
		endif
	repeat
	
	/* Construct merged defs' child references. This can't be done in the initial
	merged def load above because the children may point to other merged defs and 
	this can't happen until those defs actually exist. */
	var missingRefs = []
	var i
	var j
	var childName
	var defBankIdx
	
	for i = 0 to len(mergedDefs) loop
		for j = 0 to len(g_obj[mergedDefs[i].bank][mergedDefs[i].idx].children) loop
			// Read buffered name. .bankIdx's data gets correctly filled below.
			childName = g_obj[mergedDefs[i].bank][mergedDefs[i].idx].children[j].bankIdx
			defBankIdx = getObjDefBankIdx(childName)
			
			if defBankIdx.bank < 0 or defBankIdx.idx < 0 then
				if !contains(missingRefs, childName) then
					missingRefs = push(missingRefs, childName)
				endif
			else
				g_obj[mergedDefs[i].bank][mergedDefs[i].idx].children[j].bankIdx = encodeBankIdx(defBankIdx.bank, defBankIdx.idx)
			endif
		repeat
	repeat
return missingRefs

/* Loads a merged object's top-level container data. */
// CORE LOADER
function assembleMergedObjDefParent(_file, _chunk, _def)
	var isMerged = true
	var bankStr = ""
	var field
	var nameElem
	
	_chunk = getNextFileChunk(_file, _chunk.nextIdx) // Unit
	while inFileUnit(_chunk) and isMerged loop
		_chunk = getNextFileChunk(_file, _chunk.nextIdx) // Field
		field = _chunk.dat
		
		array elem[0]
		while inFileField(_chunk) and isMerged loop
			_chunk = getNextFileChunk(_file, _chunk.nextIdx) // Elem
			elem = push(elem, _chunk.dat)
		repeat
		
		if field == ".name" then
			nameElem = decodeElem(elem)
			
			_def.name = nameElem
		else if field == ".bankName" then
			bankStr = decodeElem(elem)
		endif endif
	repeat
	
	var result = [
		.chunk = _chunk,
		.def = _def,
		.bankName = bankStr
	]
return result

/* Loads a merged object's child data; that is, the actual object data that
fills the top-level container. */
// CORE LOADER
function assembleMergedObjDefChild(_file, _chunk, _def, _curChildIdx)
	_chunk = getNextFileChunk(_file, _chunk.nextIdx) // Unit
	var genResult = getGenObjFromFile(_file, _chunk)
	var genObj = genResult.obj
	_chunk = genResult.chunk
	
	// If not a light
	if genObj.brightness == -1 then
		var child = createActiveFromGenericObj(genObj)
		/* We temporarily store child name in .bankIdx so we can look up the
		correct objDef when loadMergedObjDefs fully constructs the child
		objects. */
		child.bankIdx = genObj.name
		_def.children = push(_def.children, child)
		_curChildIdx += 1
	// Else if a light
	else
		var l = createLightObjFromGenericObj(genObj)
		
		if _curChildidx == -1 then
			_def.lights = push(_def.lights, l)
		else
			_def.children[_curChildIdx].lights = push(_def.children[_curChildIdx].lights, l)
		endif
	endif
	
	var result = [
		.chunk = _chunk,
		.def = _def,
		.curChildIdx = _curChildIdx
	]
return result

/* Puts the merged object into the g_obj array so it can be used. If the
requested bank doesn't exist, it is created. */
// CORE LOADER
function loadAssembledMergedObjDef(_def, _savedBankName)
	loadDefMsg(_def.name)
	
	var bankFound = false
	var defBank
	var defIdx
	
	var j
	for j = 0 to len(g_bankName) loop
		// If the def's bank already exists, load it there
		if _savedBankName == g_bankName[j] then
			g_obj[j] = push(g_obj[j], _def)
			defBank = j
			defIdx = len(g_obj[j]) - 1
			bankFound = true
			
			break
		endif
	repeat
	
	// If the def's bank doesn't exist yet, create it
	if !bankFound then
		g_obj = push(g_obj, [])
		defBank = len(g_obj) - 1
		defIdx = 0
		g_bankName = push(g_bankName, _savedBankName)
		g_obj[len(g_obj) - 1] = push(g_obj[len(g_obj) - 1], _def)
	endif
	
	result = [ .bank = defBank, .idx = defIdx ]
return result

	// ----------------------------------------------------------------
	// FILE ENCODING

/* Encode section headers at various levels of the file tree. Each section header 
is identfied by a non-printing Unicode character that can't be placed with a 
standard keyboard, so user input can't create conflicts. 

The hierarchy from highest to lowest:
Section -- chr(31): Marks major chunks like maps and preferences
Version -- chr(18): Optional delimiter within a section listing the version of Celqi that saved the data
Block -- chr(17): Marks largest individual containers in a section (e.g. an object class within a map)
Unit -- chr(30): Division within a block (e.g. map objects of a type specified by block)
Field -- chr(29): The name of a varible whose value has been saved
Element -- chr(28): Part of the saved value of a variable */
function sectionStr(_str)
return chr(31) + _str

function blockStr(_str)
return chr(17) + _str

function unitStr(_str)
return chr(30) + _str

function fieldStr(_str)
return chr(29) + _str

function elemStr(_elem)
	var enc = encodeElem(_elem)
	var eStr = ""
	var i
	for i = 0 to len(enc) loop
		eStr += chr(28) + enc[i]
	repeat
return eStr

function versionStr()
	var ver = chr(18) + g_version
return ver

/* Given an input variable, returns an encoded elem string to be written
to file.

 Type designators:
"f": float
"i": int
"ia": array of ints
"3": vector3
"s": string */
function encodeElem(_dat)
	var type = getType(_dat)
	var enc
	
	loop if type == "vector" then
		var elem0 = str(_dat[0])
		strRemoveTrailingZeroes(elem0)
		var elem1 = str(_dat[1])
		strRemoveTrailingZeroes(elem1)
		var elem2 = str(_dat[2])
		strRemoveTrailingZeroes(elem2)
		if _dat[3] == 0 then
			enc = [
				"3",
				elem0,
				elem1,
				elem2
			]
		else
			var elem3 = str(_dat[3])
			strRemoveTrailingZeroes(elem3)
			
			enc = [
				"4",
				elem0,
				elem1,
				elem2,
				elem3
			]
		endif
		break endif
	if type == "float" then
		var elem = str(_dat)
		strRemoveTrailingZeroes(elem)
		enc = [
			"f",
			elem
		]
		break endif
	if type == "array" then
		enc = [ "ia" ]
		
		var i
		for i = 0 to len(_dat) loop
			enc = push(enc, str(_dat[i]))
		repeat
		
		break
	else
		var typeCode
		if type == "float" then
			typeCode = "f"
		else if type == "int" then
			typeCode = "i"
		else
			typeCode = "s"
		endif endif
		
		enc = [
			typeCode,
			str(_dat)
		]
		break
	endif break repeat
return enc

	// ----------------------------------------------------------------
	// FILE DECODING

/* Reconstructs a variable's value from encoded file string. */
// CORE LOADER
function decodeElem(_e)
	var dec
	loop if _e[0] == "f" then
		dec = float(_e[1])
		break endif
	if _e[0] == "i" then
		dec = int(_e[1])
		break endif
	if _e[0] == "3" then
		dec = {0, 0, 0}
		
		var i
		for i = 0 to 3 loop
			dec[i] = float(_e[i + 1])
		repeat
		break endif
	if _e[0] == "4" then
		dec = {0, 0, 0, 0}
		
		var i
		for i = 0 to 4 loop
			dec[i] = float(_e[i + 1])
		repeat
		break endif
	if _e[0] == "ia" then
		array newDec[len(_e) - 1]
		dec = newDec
		
		var i
		for i = 0 to len(dec) loop
			dec[i] = int(_e[i + 1])
		repeat
		break
	else
		dec = _e[1]
		break 
	endif break repeat
return dec

/* Reconstructs an object from encoded file string. This object may have the
properties of both a mapObj and a lightObj; the calling function needs to
determine how to parse the data. */
// CORE LOADER
function getGenObjFromFile(_file, _chunk)
	var genObj = initGenericObj()
	var field
	
	while inFileUnit(_chunk) loop
		_chunk = getNextFileChunk(_file, _chunk.nextIdx) // Field
		field = _chunk.dat
		
		array elem[0]
		while inFileField(_chunk) loop
			_chunk = getNextFileChunk(_file, _chunk.nextIdx) // Elem
			elem = push(elem, _chunk.dat)
		repeat
		
		genObj = fillGenericObj(genObj, field, decodeElem(elem))
	repeat
	
	var result = [
		.obj = genObj,
		.chunk = _chunk
	]
return result

/* Formats and initializes a struct to be filled by getGenObjFromFile(). */
// CORE LOADER
function initGenericObj()
return [
	.obj = -1,
	.name = "",
	.pos = {0, 0, 0},
	.scale = {1, 1, 1},
	.fwd = {0, 0, 1},
	.up = {0, 1, 0},
	.bankIdx = -1,
	.children = [],
	.lights = [],
	.brightness = -1,
	.col = {1, 1, 1, 1},
	.mat = {0, 1, 0},
	.spread = -1,
	.res = -1,
	.range = -1
]

/* Fills the generic object with data from getGenObjFromFile(). */
// CORE LOADER
function fillGenericObj(_genObj, _field, _elem)
	loop if _field == ".name" then
		_genObj.name = _elem
		break endif
	if _field == ".bankIdx" then
		_genObj.bankIdx = _elem
		break endif
	if _field == ".idx" then
		_genObj.bankIdx = encodeBankIdx(decodeBank(-1, _genObj.bankIdx), _elem)
		break endif
	if _field == ".bank" then
		_genObj.bankIdx = encodeBankIdx(_elem, decodeIdx(-1, _genObj.bankIdx))
		break endif
	if _field == ".pos" then
		_genObj.pos = _elem
		break endif
	if _field == ".fwd" then
		_genObj.fwd = _elem
		break endif
	if _field == ".up" then
		_genObj.up = _elem
		break endif
	if _field == ".scale" then
		_genObj.scale = _elem
		break endif
	if _field == ".brightness" then
		_genObj.brightness = _elem
		break endif
	if _field == ".col" then
		_genObj.col = _elem
		break endif
	if _field == ".mat" then
		_genObj.mat = _elem
		break endif
	if _field == ".spread" then
		_genObj.spread = _elem
		break endif
	if _field == ".res" then
		_genObj.res = _elem
		break endif
	if _field == ".range" then
		_genObj.range = _elem
		break
	endif break repeat
return _genObj

/* Pulls all the data from a generic object necessary for an active. */
// CORE LOADER
function createActiveFromGenericObj(_gen)
	active obj
	obj.obj = _gen.obj
	obj.pos = _gen.pos
	obj.scale = _gen.scale
	obj.fwd = _gen.fwd
	obj.up = _gen.up
	obj.col = _gen.col
	obj.bankIdx = _gen.bankIdx
return obj

/* Pulls all the data from a generic object necessary for a lightObj. */
// CORE LOADER
function createLightObjFromGenericObj(_gen)
	lightObj l
	l = initLightObj()
	l.name = _gen.name
	l.pos = _gen.pos
	l.fwd = _gen.fwd
	l.brightness = _gen.brightness
	l.col = _gen.col
	l.spread = _gen.spread
return l

/* Fills the appropriate variables from the file's saved map properties. */
// CORE LOADER
function decodeMapProperties(_field, _elem, _propStruct)
	loop if _field == "g_bg.idx" then
		_propStruct.bg.idx = decodeElem(_elem)
		break endif
	if _field == "g_bg.col" then
		_propStruct.bg.col = decodeElem(_elem)
		break endif
	if _field == "g_cam.pos" then
		_propStruct.cam.pos = decodeElem(_elem)
		break endif
	if _field == "g_cam.fwd" then
		_propStruct.cam.fwd = decodeElem(_elem)
		break endif
	if _field == "g_cam.up" then
		_propStruct.cam.up = decodeElem(_elem)
		break endif
	if _field == "g_cur.pos" then
		_propStruct.cur.pos = decodeElem(_elem)
		break
	endif break repeat
return _propStruct

/* Fills the appropriate variables from the file's saved cell properties. */
// CORE LOADER
function decodeCellMap(_field, _elem, _cellArr)
	loop if _field == ".pos" then
		_cellArr[0] = decodeElem(_elem)
		break endif
	if _field == ".adj" then
		_cellArr[1] = decodeElem(_elem)
		break
	endif break repeat
return _cellArr

/* Returns true if the given chunk is within the file. */
// CORE LOADER
function inFile(_chunk)
return _chunk.nextMarker != chr(127) 
		and _chunk.nextIdx < _chunk.fileLen

/* Returns true if the given chunk is still within the same section. */
// CORE LOADER
function inFileSection(_chunk)
return _chunk.nextMarker != chr(31) 
		and _chunk.nextMarker != chr(127) 
		and _chunk.nextIdx < _chunk.fileLen

/* Returns true if the given chunk is still within the same block. */			
// CORE LOADER
function inFileBlock(_chunk)
return _chunk.nextMarker != chr(31) 
		and _chunk.nextMarker != chr(17) 
		and _chunk.nextMarker != chr(127) 
		and _chunk.nextIdx < _chunk.fileLen

/* Returns true if the given chunk is still within the same unit. */
// CORE LOADER
function inFileUnit(_chunk)
return _chunk.nextMarker != chr(31) 
		and _chunk.nextMarker != chr(17) 				
		and _chunk.nextMarker != chr(30) 
		and _chunk.nextMarker != chr(127) 
		and _chunk.nextIdx < _chunk.fileLen

/* Returns true if the given chunk is still within the same field. */
// CORE LOADER
function inFileField(_chunk)
return _chunk.nextMarker != chr(31) 
		and _chunk.nextMarker != chr(17) 				
		and _chunk.nextMarker != chr(30) 				
		and _chunk.nextMarker != chr(29) 
		and _chunk.nextMarker != chr(127) 
		and _chunk.nextIdx < _chunk.fileLen

// ----------------------------------------------------------------
// STRING FUNCTIONS

/* The character at the _end index isn't included in the return string. */
function strSlice(_str, _start, _end)
	sliced  = ""
	
	if len(_str) > 0 and _start < len(_str) then
		if _end > len(_str) - 1 or _end < 0 then
			_end = len(_str)
		endif
		
		if _start < 0 then
			_start = 0
		endif
		
		var i
		for i = _start to _end loop
			sliced += _str[i]
		repeat
	endif
return sliced

/* Converts a float to a string with the given number of decimal places. */
function floatToStr(_f, _decimals)
	str fStr = str(_f)
	var decIdx = strFind(fStr, ".")
	
	if _decimals == 0 then
		fStr = strSlice(fStr, 0, decIdx)
	else if _decimals > 0 then
		fStr = strSlice(fStr, 0, decIdx + 1 + _decimals)
	endif endif
return fStr

/* Removes the trailing zeros and, if appropriate, the decimal point from a
stringified float. */
function strRemoveTrailingZeroes(ref _str)
	var newLen = len(_str) - 1
	var continue = strContains(_str, ".")
	var i
	
	for i = len(_str) - 1 to -0.1 step -1 loop
		if !continue then // Check inside of loop to reduce stack size
			break
		endif
		
		if _str[i] == "0" then
			newLen -= 1
		else
			if _str[i] == "." then
				newLen -= 1
			endif
			
			break
		endif
	repeat
	
	_str = _str[:newLen]
return _str


/* Generate a name based on a filepath. */
// CORE LOADER
function getDefaultDefName(_path)
	var name = _path
	var slashIdx = strFind(name, "/") + 1
	name = name[slashIdx:]
	name = strReplace(name, "_", " ")
return name

/* Returns menu display text. */
function getBoolStr(_bool)
	var boolStr
	if _bool then
		boolStr = "Yes"
	else
		boolStr = "No"
	endif
return boolStr

// ----------------------------------------------------------------
// NUMBER FUNCTIONS

/* 1 for 0 or positive, -1 for negative. */
// CORE LOADER
function getSign(_num)
	if _num >= 0 then
		_num = 1
	else
		_num = -1
	endif
return _num

/* Round a float to a given number of decimal places. */
// CORE LOADER
function roundDec(_num, _decimals)
	var factor = pow(10, _decimals)
	
	if _decimals <= 0 then
		factor = 1
	endif
	
	_num = _num * factor
	_num = round(_num)
	_num = _num / factor
	_num = str(_num)
return float(_num)

/* Wrap range is _min up to and including _max. Values above the max
clamp to the min; values below the min clamp to the max. */
function wrapIncClamp(_num, _min, _max)
	if _num < _min then
		_num = _max
	endif
	if _num > _max then
		_num = _min
	endif
return _num

/* The native mod function (%) truncates the result if it's a float, 
so use this for floats. */
// CORE LOADER
function mod(_num1, _num2)
	_num1 = roundDec(_num1, 6)
	_num2 = roundDec(_num2, 6)
	var decPart = fract(_num1 / _num2)
return decPart * _num2

/* Equality check with tolerance value. */
// CORE LOADER
function equals(_num1, _num2, _tolerance)
	var isEqual = true
	
	if strBeginsWith(str(_num1), "{") then // If a vector
		var i
		for i = 0 to 4 loop
			if abs(_num1[i] - _num2[i]) > abs(_tolerance) then
				isEqual = false
				
				break
			endif
		repeat
	else if abs(_num1 - _num2) > abs(_tolerance) then
		isEqual = false
	endif endif
return isEqual

/* Rounds a number (_num) to the closest multiple of another number (_mult), 
with the multiplication sequence offset by the given amount (_offset). */
// CORE LOADER
function roundToMultiple(_num, _mult, _offset)
	_mult = abs(_mult)
	var div = floor(_num / _mult)
return div * _mult - _offset

function roundVec3ToMultiple(_v, _mult, _offset)
	_v[0] = roundToMultiple(_v[0], _mult, _offset)
	_v[1] = roundToMultiple(_v[1], _mult, _offset)
	_v[2] = roundToMultiple(_v[2], _mult, _offset)
return _v

/* abs() for vector3. */
// CORE LOADER
function absVec3(_vec)
return {abs(_vec.x), abs(_vec.y), abs(_vec.z)}

/* Returns number of ints needed to store the given number of bits. */
// CORE LOADER
function bitLenToInt(_bitLen)
return ceil(_bitLen / g_intLen)

/* _val must be 0 or 1. This will fill a length of _count bits starting
at _bitIdx with the _val bit. */
// CORE LOADER
function bitFieldSetLong(_bitIntArr, _bitIdx, _count, _val)
	if _val != 0 then
		_val = int_max
	endif
	
	var intIdx = floor(_bitIdx / g_intLen)
	var shortIdx = _bitIdx - intIdx * g_intLen
	var shortCount = min(g_intLen - _bitIdx % g_intLen, _count)
	_count -= shortCount
	
	while shortCount > 0 and intIdx < len(_bitIntArr) loop
		_bitIntArr[intIdx] = bitFieldInsert(_bitIntArr[intIdx], shortIdx, shortCount, _val)
		intIdx += 1
		shortIdx = 0
		shortCount = min(g_intLen, _count)
		_count -= shortCount
	repeat
return _bitIntArr

/* Bitwise or for multi-int binary numbers. Assumes both bitInt arrays have the
same number of elements. */
// CORE LOADER
function bitOrLong(_bitIntArr1, _bitIntArr2)
	var i
	for i = 0 to len(_bitIntArr1) loop
		_bitIntArr1[i] = _bitIntArr1[i] | _bitIntArr2[i]
	repeat
return _bitIntArr1

/* Compact if statement that returns argument 2 or 3 depending on the truth of
argument 1. */
function ifElse(_cond, _if, _else)
	var result
	
	if _cond then
		result = _if
	else
		result = _else
	endif
return result

// ----------------------------------------------------------------
// ARRAY FUNCTIONS

// CORE LOADER
function contains(_arr, _item)
return contains(_arr, _item, false)

/* Can cast _item to a string before looking for it. */
function contains(_arr, _item, _castToStr)
	if _castToStr then
		_item = str(_item)
	endif
	
	var found = false
	if find(_arr, _item, _castToStr) > -1 then
		found = true
	endif
return found

/* Finds the index of _item in _array, or -1 if not found. */
// CORE LOADER
function find(_arr, _item)
return find(_arr, _item, false)

function find(_arr, _item, _castToStr)
	var idx = -1
	
	var i
	for i = 0 to len(_arr) loop
		if _castToStr then
			_arr[i] = str(_arr[i])
		endif
		if _arr[i] == _item then
			idx = i
			
			break
		endif
	repeat
return idx

/* Removes item at _idx from _arr. */
// CORE LOADER
function remove(_arr, _idx)
	array newArr[len(_arr) - 1]
	var offset = 0
	
	var i
	for i = 0 to len(newArr) loop
		if i == _idx then
			offset = 1
		endif
		
		newArr[i] = _arr[i + offset]
	repeat
return newArr

// CORE LOADER
/* Inserts _elem in _arr at index _idx, pushing items at _idx and higher back by one index place. */
function insert(_arr, _elem, _idx)
	array newArr[len(_arr) + 1]
	_idx = clamp(_idx, 0, len(_arr))
	var offset = 0
	
	var i
	for i = 0 to len(newArr) loop
		if i == _idx then
			newArr[i] = _elem
			offset = -1
		else
			newArr[i] = _arr[i + offset]
		endif
	repeat
return newArr

/* Explodes _elemArr into its constituent elements and inserts them into _arr. */
// CORE LOADER
function insertArray(_arr, _elemArr)
return insertArray(_arr, _elemArr, len(_arr))

function insertArray(_arr, _elemArr, _idx)
	array newArr[len(_arr) + len(_elemArr)]
	_idx = clamp(_idx, 0, len(_arr))
	var offset = 0
	
	var i
	for i = 0 to len(newArr) loop
		if i >= _idx and i < _idx + len(_elemArr) then
			newArr[i] = _elemArr[i - _idx]
			offset -= 1
		else
			newArr[i] = _arr[i + offset]
		endif
	repeat
return newArr

/* Inserts _item at the end of _arr. */
// CORE LOADER
function push(_arr, _item)
	var arrBuffer = _arr
	var newArr[len(arrBuffer) + 1]
	_arr = newArr
	
	var i
	for i = 0 to len(arrBuffer) loop
		_arr[i] = arrBuffer[i]
	repeat
	
	_arr[len(arrBuffer)] = _item
return _arr

/* This won't literally return type -- a string containing an int value,
for example, will be read as an int -- but it sees the general patterns 
that distinguish data types and should be robust enough for most cases. 
FUZE will throw an error if you pass it a handle. */
function getType(_var)
	var type = "string"
	str varStr = str(_var)
	int varLen = len(varStr)
	var continue = true
	
	while continue loop
		if varLen > 2 then
			if varStr[:2] == "[ ." then
				type = "struct"
				break
			endif
		endif
		
		if varLen > 1 then
			if varStr[0] == "{" then
				type = "vector"
				break
			else if varStr[:1] == "[ " then
				type = "array"
				break
			endif endif
		endif
		
		if varLen > 0 then
			// Separating steps of the condition check may help avoid stack overflow?
			var cast = float(0)
			cast = str(cast)
			var cond0 = varStr != cast
			var cond1 = int(varStr) == 0
			var cond2 = strFind(varStr, "0.") != 0
			var cond3 = strFind(varStr, "-0.") != 0
			cast = int(varStr)
			cast = str(cast)
			cast = len(cast)
			var cond4 = cast != varLen
			cast = float(varStr)
			cast = str(cast)
			cast = len(cast)
			var cond5 = cast != varLen
			
			if varStr != "0" and cond0
					and ((cond1 and cond2 and cond3)
					or (cond4 and cond5)) then
				type = "string"
				break
			else if strContains(varStr, ".") then
				type = "float"
				break
			endif endif
			type = "int"
			break
		endif
		
		continue = false
	repeat
return type

// ----------------------------------------------------------------
// VECTOR FUNCTIONS

/* Normalized cross(), but avoids {nan, nan, nan} for a zeroed result. */
// CORE LOADER
function safeCross(_vec1, vec2)
	var vec3 = cross(_vec1, vec2)
	
	if vec3 != {0, 0, 0} then
		 vec3 = normalize(vec3)
	endif
return vec3

/* Notmalizes only if the result will not be {nan, nan, nan}. */
function safeNormalize(_vec)
	if _vec != {0, 0, 0, 0} then
		_vec = normalize(_vec)
	endif
return _vec

/* Makes a 3D unit vector 2D by removing the Y element. */
// CORE LOADER
function flattenY(_v)
//return normalize({_v.x, 0, _v.z})
return safeNormalize({_v.x, 0, _v.z})

/* Rotates 3D vector _v around 3D vector _axis by _deg degrees. */
// CORE LOADER
function axisRotVecBy(_v, _axis, _deg)
	// Euler-Rodrigues rotation formula
	var halfDeg = _deg / 2
	var w = _axis * sin(halfDeg)
	var crossWV = cross(w, _v)
return _v + 2 * cos(halfDeg) * crossWV + 2 * cross(w, crossWV)

/* Returns angle in degrees between two vectors. */
// CORE LOADER
function getAngleBetweenVecs(_v1, _v2)
	angle = 0
	
	if roundVec(_v1, 3) == roundVec(_v2 * -1, 3) then
		angle = 180	
	else if roundVec(_v1, 3) != roundVec(_v2, 3) 
			and roundVec(_v1, 3) != {0, 0, 0}
			and roundVec(_v2, 3) != {0, 0, 0} then
		angle = acos(dot(_v1, _v2) / (distance({0, 0, 0}, _v1) * distance({0, 0, 0}, _v2)))
	endif endif
return angle

/* Rounds a vector to the given number of decimal places. */
// CORE LOADER
function roundVec(_v, _decimals)
	// Help avoid stack overflow by not using a loop
	_v[0] = roundDec(_v[0], _decimals)
	_v[1] = roundDec(_v[1], _decimals)
	_v[2] = roundDec(_v[2], _decimals)
	
	if _v[3] != 0 then
		_v[3] = roundDec(_v[3], _decimals)
	endif
return _v

/* Vector implementation of floor(). */
// CORE LOADER
function floorVec(_v)
	var i
	for i = 0 to 4 loop
		_v[i] = floor(_v[i])
	repeat
return _v

/* Remaps a 3D vector to a different context. */
// CORE LOADER
function changeVecSpace(_vec, _newFwd, _newUp, _newR, _newPos)
	var mapped = {0, 0 ,0}
	mapped.x = _vec.x * _newFwd.x + _vec.y * _newUp.x + _vec.z * _newR.x + _newPos.x
	mapped.y = _vec.x * _newFwd.y + _vec.y * _newUp.y + _vec.z * _newR.y + _newPos.y
	mapped.z = _vec.x * _newFwd.z + _vec.y * _newUp.z + _vec.z * _newR.z + _newPos.z
return mapped

/* Remaps a 3D vector to a different context. Accounts for the fact that
FUZE uses a Z-forward orientation. */
// CORE LOADER
function changeVecSpaceZFwd(_vec, _newFwd, _newUp, _newR, _newPos)
return changeVecSpace(_vec, _newR * -1, _newUp, _newFwd, _newPos)

/* Remaps a world vector as a local vector. */
// CORE LOADER
function worldVecToLocalVec(_vec, _locFwd, _locUp, _locPos)
	_vec -= _locPos
	_locFwd = axisRotVecBy(_locFwd, _locUp, 90)
	var r = cross(_locFwd, _locUp)
	
	// Calculate inverse matrix	
	var minFwd = {_locUp.y * r.z - r.y * _locUp.z, 
		(_locUp.x * r.z - r.x * _locUp.z) * -1, 
		_locUp.x * r.y - r.x * _locUp.y}
	var minUp = {(_locFwd.y * r.z - r.y * _locFwd.z) * -1, 
		_locFwd.x * r.z - r.x * _locFwd.z, 
		(_locFwd.x * r.y - r.x * _locFwd.y) * -1}
	var minR = {_locFwd.y * _locUp.z - _locUp.y * _locFwd.z, 
		(_locFwd.x * _locUp.z - _locUp.x * _locFwd.z) * -1, 
		_locFwd.x * _locUp.y - _locUp.x * _locFwd.y}
	var adjFwd = {minFwd.x, minUp.x, minR.x}
	var adjUp = {minFwd.y, minUp.y, minR.y}
	var adjR = {minFwd.z, minUp.z, minR.z}
	var det = 1 / (_locFwd.x * minFwd.x + _locUp.x * minUp.x + r.x * minR.x)
	var invFwd = det * adjFwd
	var invUp = det * adjUp
	var invR = det * adjR
	
	var newVec = changeVecSpace(_vec, invFwd, invUp, invR, _locPos * -1)
	newVec += _locPos
return newVec

/* Remaps a local vector as a world vector. */
// CORE LOADER
function localVecToWorldVec(_vec, _locFwd, _locUp, _locPos)
	var newVec = changeVecSpaceZFwd(_vec, _locFwd, _locUp, cross(_locFwd, _locUp), {0, 0, 0})
	newVec += _locPos
return newVec

/* Projects world vector to screen postion. */
function worldPosToScreenPos(_worldPos, _camFwd, _camUp, _camPos, _camFov)
	var screenPos = {float_min, float_min}
	var nearClip = 0.25
	var unadjScreenPos = worldVecToLocalVec(_worldPos, _camFwd, _camUp, _camPos)
	
	if unadjScreenPos.z >= nearClip then
		screenPos = {unadjScreenPos.x / (unadjScreenPos.z / 1),
			unadjScreenPos.y / (unadjScreenPos.z / 1),
			1}
		/* These silly calculations allow the screen position to scale with the FOV.
		They were chosen through trial and error and have been tested for FOVs of
		50-110. There's probably a better way to do it, but this works.*/
		var adj = (30 - abs(80 - _camFov)) / 2500
		screenPos = ((screenPos / pow(_camFov, 1.42 - adj)) * {gwidth() / 4, gheight() / 1.3 + adj * 2000, 1}) / {gwidth() / 1280, gheight() / 720}
		screenPos = {gwidth(), gheight()} - ((screenPos + 1) / 2) * {gwidth(), gheight()}
	endif
return {screenPos.x, screenPos.y}

/* Projects a vector onto the plane defined by _planeOrig and _norm. */
// CORE LOADER
function projectVecToPlane(_v, _planeOrig, _norm)
	_norm = safeNormalize(_norm)
	var normDot = dot(_v - _planeOrig, _norm)
return _v - _norm * normDot

function lerpDirVecs(_fwd1, _up1, _fwd2, _up2, _t)
	var axis = safeCross(_fwd1, _fwd2)
	
	if axis == {0, 0, 0} then
		axis = _up1
	endif
	
	var fwdDeg = getAngleBetweenVecs(_fwd1, _fwd2)
	
	var targUp = axisRotVecBy(_up1, axis, fwdDeg)
	var upDeg = getAngleBetweenVecs(targUp, _up2)
	
	var newFwd = axisRotVecBy(_fwd1, axis, fwdDeg * _t)
	var newUp = axisRotVecBy(_up1, axis, fwdDeg * _t)
	newUp = axisRotVecBy(newUp, newFwd, upDeg * _t)
	
	var result = [
		.fwd = newFwd,
		.up = newUp
	]
return result

// ----------------------------------------------------------------
// OBJECT FUNCTIONS

	// ----------------------------------------------------------------
	// EXTENT

/* Builds extent data for an object. Reflects actual object hitbox within 
a margin of error. */
// CORE LOADER
function getObjExtent(_obj, _pos)
return getObjExtent(_obj, _pos, {1, 1, 1}, {0, 0, 1}, {0, 1, 0}, 0.001)

function getObjExtent(_obj, _pos, _scale, _fwd, _up, _res)
	setObjectPos(_obj, {0, 0, 0})
	setObjectScale(_obj, {1, 1, 1})
	setObjRot(_obj, {0, 0, 0}, {0, 0, 1}, {0, 1, 0})
	extent ext
	
	var startResult = findObjExtStartSize(_obj, {0, 0, 0})
	if startResult.isValid then
		ext = findAllObjExtDirs(_obj, {0, 0, 0}, startResult.colBox, startResult.scale, _res)
	else
		ext = [
			.lo = {-0.5, -0.5, -0.5},
			.hi = {0.5, 0.5, 0.5}
		]
	endif
	
	removeObject(startResult.colBox)
	setObjectPos(_obj, _pos)
	setObjectScale(_obj, _scale)
	setObjRot(_obj, _pos, _fwd, _up)
return ext

/* When finding an object's extent, we first need to know where the object is
in relation to its origin. This function creates a cube at the origin and
expands it until it collides with the object. */
// CORE LOADER
function findObjExtStartSize(_obj, _pos)
	var colBoxScale = {0, 0, 0}
	var colBox = placeObject(cube, _pos, colBoxScale)
	var hit = false
	var scaleLimit = 10
	
	while !hit and colBoxScale.x < scaleLimit loop
		colBoxScale += {1, 1, 1}
		setObjectScale(colBox, colBoxScale)
		hit = objectIntersect(colBox, _obj)
	repeat
	
	result = [
		.colBox = colBox,
		.scale = colBoxScale,
		.isValid = hit
	]
return result

/* Moves the collision box found by findObjExtStartSize() in a given direction
until it no longer intersects _obj, which tells us _obj's extent in that
direction. */
// CORE LOADER
function findObjExtDir(_obj, _pos, _colBox, _colBoxScale, _dir, _res)
	// Assume true to begin because findObjExtStartSize() succeeded
	var hit = true
	var colBoxPos = _pos
	var loopCount = 0
	
	while hit loop
		colBoxPos += _dir * _res
		setObjectPos(_colBox, colBoxPos)
		hit = objectIntersect(_colBox, _obj)
		loopCount += 1
	repeat
	
	var dirExt = colBoxPos + (_dir * -1 * _colBoxScale)
		* {abs(_dir.x), abs(_dir.y), abs(_dir.z)}
return dirExt

/* Finds an object's extents in all cardinal directions. */
// CORE LOADER
function findAllObjExtDirs(_obj, _pos, _colBox, _colBoxScale, _res)
	extent ext
	
	ext.lo = findObjExtDir(_obj, _pos, _colBox, _colBoxScale, {-1, 0, 0}, _res)
		+ findObjExtDir(_obj, _pos, _colBox, _colBoxScale, {0, -1, 0}, _res)
		+ findObjExtDir(_obj, _pos, _colBox, _colBoxScale, {0, 0, -1}, _res)
	ext.hi = findObjExtDir(_obj, _pos, _colBox, _colBoxScale, {1, 0, 0}, _res)
		+ findObjExtDir(_obj, _pos, _colBox, _colBoxScale, {0, 1, 0}, _res)
		+ findObjExtDir(_obj, _pos, _colBox, _colBoxScale, {0, 0, 1}, _res)
return ext

/* Gets the center position within an extent. */
// CORE LOADER
function getExtCenter(_ext)
	var ctr = {(_ext.hi.x + _ext.lo.x) / 2,
		(_ext.hi.y + _ext.lo.y) / 2,
		(_ext.hi.z + _ext.lo.z) / 2}
return ctr

/* Gets the longest dimension of an extent. */
// CORE LOADER
function getMaxDim(_ext)
return getMaxDim(_ext, {1, 1, 1})

function getMaxDim(_ext, _scale)
	var h = (_ext.hi.y - _ext.lo.y) * _scale.y
	var w = (_ext.hi.z - _ext.lo.z) * _scale.z
	var d = (_ext.hi.x - _ext.lo.x) * _scale.x
	var maxDim = h
	
	if w > maxDim then
		maxDim = w
	endif
	
	if d > maxDim then 
		maxdim = d
	endif
return maxDim

/* Gets the shortest dimension of an extent. */
// CORE LOADER
function getMinDim(_ext)
return getMinDim(_ext, {1, 1, 1})

function getMinDim(_ext, _scale)
	var h = (_ext.hi.y - _ext.lo.y) * _scale.y
	var w = (_ext.hi.z - _ext.lo.z) * _scale.z
	var d = (_ext.hi.x - _ext.lo.x) * _scale.x
	var minDim = h
	
	if w < minDim then
		minDim = w
	endif
	
	if d < minDim then 
		mindim = d
	endif
return minDim

/* Gets the corners of a scaled and rotated extent. */
// CORE LOADER
function getExtPoints(_ext, _scale, _fwd, _up)
	var r = safeNormalize(cross(_fwd, _up))
	var dim = {(_ext.hi.x - _ext.lo.x) * _scale.x,
		(_ext.hi.y - _ext.lo.y) * _scale.y,
		(_ext.hi.z - _ext.lo.z) * _scale.z}
	var loPos = localVecToWorldVec(_ext.lo * _scale, _fwd, _up, {0, 0, 0})
	var points = [
		loPos,
		loPos + r * -dim.x,
		loPos + _up * dim.y,
		loPos + r * -dim.x + _up * dim.y,
		loPos + _fwd * dim.z,
		loPos + _fwd * dim.z + r * -dim.x,
		loPos + _fwd * dim.z + _up * dim.y,
		loPos + _fwd * dim.z + _up * dim.y + r * -dim.x
	]
return points

/* Gets the min and max values for each axis for a scaled, rotated extent. */
// CORE LOADER
function getExtMinMax(_ext, _scale, _fwd, _up)
	var minMax = [
		.lo = {
			float_max,
			float_max,
			float_max
		},
		.hi = {
			float_min,
			float_min,
			float_min
		}
	]
	var points = getExtPoints(_ext, _scale, _fwd, _up)
	
	var i
	var j
	
	for i = 0 to len(points) loop
		for j = 0 to 3 loop
			if points[i][j] < minMax.lo[j] then
				minMax.lo[j] = points[i][j]
			endif
			
			if points[i][j] > minMax.hi[j] then
				minMax.hi[j] = points[i][j]
			endif
		repeat
	repeat
return minMax

/* Recalculates extent to include an additional object. */
function addObjectToGrpExt(_grpExt, _obj)
	var inSitu = getExtMinMax(getObjDef(-1, _obj).ext, 
		_obj.scale, _obj.fwd, _obj.up)
	inSitu.lo += _obj.pos
	inSitu.hi += _obj.pos
	
	var i
	for i = 0 to 3 loop
		if inSitu.lo[i] < _grpExt.lo[i] then
			_grpExt.lo[i] = inSitu.lo[i]
		endif
		if inSitu.hi[i] > _grpExt.hi[i] then
			_grpExt.hi[i] = inSitu.hi[i]
		endif
	repeat
return _grpExt

/* Fully rebuilds extent for a merged object by referring only to extent data 
from the underlying unmerged objects instead of pulling cached extent data from
underlying merged objects. Used in cases where we aren't sure which merged object 
definitions have accurate extent data. */
function rebuildMergedObjExt(_obj)
	var grpExt = [
		.lo = {
			float_max,
			float_max,
			float_max
		},
		.hi = {
			float_min,
			float_min,
			float_min
		}
	]
	
	var i
	for i = 0 to len(_obj.children) loop
		grpExt = rebuildMergedObjExt(_obj.children[i], grpExt)
	repeat
return grpExt

function rebuildMergedObjExt(_obj, _grpExt)
	if !len(_obj.children) then
		_grpExt = addObjectToGrpExt(_grpExt, _obj)
	endif

	var i
	for i = 0 to len(_obj.children) loop
		_obj.children[i] = applyGrpTransform(_obj.children[i], _obj, true, true)
		_grpExt = rebuildMergedObjExt(_obj.children[i], _grpExt)
	repeat
return _grpExt

	// ----------------------------------------------------------------
	// OBJECT DEFINITIONS

/* Returns an active built from an object definition. */
// CORE LOADER
function activeFromObjDef(_bank, _idx)
return activeFromObjDef(_bank, _idx, true, false, -1)

function activeFromObjDef(_bank, _idx, _createModel)
return activeFromObjDef(_bank, _idx, _createModel, false, -1)

function activeFromObjDef(_bank, _idx, _createModel, _useDef, _def)
	if !_useDef then
		_def = g_obj[_bank][_idx]
	endif
	
	active act
	act.pos = {0, 0, 0}
	act.scale = {1, 1, 1}
	act.fwd = {0, 0, 1}
	act.up = {0, 1, 0}
	act.bankIdx = encodeBankIdx(_bank, _idx)
	act.children = _def.children
	
	if len(act.children) then
		act.col = {-1, -1, -1, -1}
		act.mat = {-1, -1, -1}
	else
		act.col = {1, 1, 1, 1}
		act.mat = {0, 1, 0}
	endif
	
	if _createModel then
		act.obj = _def.obj
	else
		act.obj = -1
	endif
	
	var i
	var newChild
	
	for i = 0 to len(_def.children) loop
		newChild = activeFromObjDef(decodeBank(-1, act.children[i].bankIdx), 
			decodeIdx(-1, act.children[i].bankIdx), _createModel, false, -1)
		/* Children have saved material data, but activeFromObjDef() initializes a default, 
		so overwrite that default with the data saved in the parent. */
		newChild.col = act.children[i].col
		newChild.mat = act.children[i].mat
		act.children[i].children = newChild.children
	repeat
	
	act.lights = _def.lights
return act

/* Bank and index aren't saved into an object definition. Finds the bank and index
of the definition matching _name. */
// CORE LOADER
function getObjDefBankIdx(_name)
	var result = [
		.bank = -1,
		.idx = -1
	]
	
	var i
	var j
	
	for i = 0 to len(g_obj) loop
		for j = 0 to len(g_obj[i]) loop
			if g_obj[i][j].name == _name then
				result.bank = i
				result.idx = j
				
				break
			endif
		repeat
		if result.bank != -1 then break endif
	repeat
return result

/* Rebuilds any merged object definitions that have changed because of changes to a 
child definition. */
function resolveMergedObjDefChanges(_missingRefs)
	var timer = time()
	//showLoadBox("Resolving changes to merged object definitions ...", true, false, false)
	loadDefMsg("")
	/*
	var i
	for i = 0 to len(_missingRefs) loop
		promptObjDefRelink(-1, _missingRefs[i], 0)
	repeat
	*/
	// Rebuild merged extents in case base filepaths were changed
	var j
	for i = 0 to len(g_obj) loop
		for j = 0 to len(g_obj[i]) loop
			if len(g_obj[i][j].children) then
				g_obj[i][j].ext = rebuildMergedObjExt(g_obj[i][j])
			endif
		repeat
	repeat
	
	//removeLoadSpr()
return void

/* Finds the definiton for an instantiated object or returns a default definition 
if none exists. */
// CORE LOADER
function getObjDef(ref _in, _obj)
	var defIsValid = false
	var realBankIdx = false
	
	/* During merged def loads, .bankIdx may temporarily contain a missing object's
	name, so we screen this with len(). */
	if !len(_obj.bankIdx) then
		realBankIdx = true
	endif
	
	var bankIdxStr = str(_obj.bankIdx) // Our if statements are a bit roundabout to help avoid excess stack entries
	
	if realBankIdx and bankIdxStr != "-1" then
		var idx
		decodeIdx(idx, _obj.bankIdx)
		var bank
		decodeBank(bank, _obj.bankIdx)
		var objBank = g_obj[bank]
		_in = objBank[idx]
		defIsValid = true
	endif
	
	if !defIsValid then
		objDef missing
		var zeroVec = {0, 0, 0}
		
		missing.name = str(_obj.bankIdx)
		missing.file = ""
		missing.obj = -1
		missing.ext = [ .lo = zeroVec, .hi = zeroVec ]
		missing.scale = {1, 1, 1}
		missing.children = []
		missing.lights = []
		
		_in = missing
	endif
return _in

	// ----------------------------------------------------------------
	// OBJECT PLACEMENT

/* Inserts a primitive into an object definition placement based on name,
since primitives can't be referenced by model handle. */
// CORE LOADER
function placeObjDef(_def, _pos, _scale)
	var newObj
	
	loop if _def.name == "Cone" then
		newObj = placeObject(cone, _pos, _scale)
		break endif
	if _def.name == "Cube" then
		newObj = placeObject(cube, _pos, _scale)
		break endif
	if _def.name == "Cylinder" then
		newObj = placeObject(cylinder, _pos, _scale)
		break endif
	if _def.name == "Hemisphere" then
		newObj = placeObject(hemisphere, _pos, _scale)
		break endif
	if _def.name == "Pyramid" then
		newObj = placeObject(pyramid, _pos, _scale)
		break endif
	if _def.name == "Sphere" then
		newObj = placeObject(sphere, _pos, _scale)
		break endif
	if _def.name == "Wedge" then
		newObj = placeObject(wedge, _pos, _scale)
		break
	else
		newObj = placeObject(_def.obj, _pos, _scale)
		break
	endif break repeat
return newObj

/* Places an object into the map using an object _t as the template. */
// CORE LOADER
function placeObjFromTemplate(_t, _merged)
	array placedObj[0]
	
	var hasChild = len(_t.children)
	var hasLight = len(_t.lights)
	if (hasChild or hasLight) and _merged then
		var newPlacedObj = addMapObj(_t, _t.pos, _t.fwd, _t.up, _t.scale, true)
		placedObj = [ newPlacedObj ]
	else if hasChild or hasLight then
		var newObj
		var newPlacedObj
		var i
		var childIsGrp
		
		for i = 0 to len(_t.children) loop
			newObj = applyGrpTransform(_t.children[i], _t)
			childIsGrp = false
			
			if len(_t.children[i].children) or len(_t.children[i].lights) then
				childIsGrp = true
			endif
			
			newPlacedObj = addMapObj(newObj, newObj.pos, 
				newObj.fwd, 
				newObj.up, 
				newObj.scale, childIsGrp)
			placedObj = push(placedObj, newPlacedObj)
		repeat
		
		for i = 0 to len(_t.lights) loop
			newObj = getActiveLightFromName(_t.lights[i].name)
			newObj.pos = _t.pos
			newObj.fwd = _t.fwd
			newObj.up = _t.up
			newObj.lights = [ _t.lights[i] ]
			
			newPlacedObj = addMapObj(newObj, newObj.pos, 
				newObj.fwd, 
				newObj.up, 
				newObj.scale, true)
			placedObj = push(placedObj, newPlacedObj)
		repeat
	else
		newPlacedObj = addMapObj(_t, _t.pos, _t.fwd, _t.up, _t.scale, false)
		placedObj = [ newPlacedObj ]
	endif endif
return placedObj

/* Creates a light using light _t as a template. */
// CORE LOADER
function placeLightFromTemplate(_t)
	_t.light = placeLightByType(_t.name, _t.col, _t.pos, _t.brightness, _t.res, _t.fwd, _t.spread, _t.range)
	
	if g_editor then
		if _t.col.a != g_sprAlpha then _t.col.a = g_sprAlpha endif
		
		_t.spr = createSprite()
		
		loop if _t.name == "point" then
			setSpriteImage(_t.spr, g_imgPointLight)
			break endif
		if _t.name == "pointshadow" then
			setSpriteImage(_t.spr, g_imgPointShadowLight)
			break endif
		if _t.name == "spot" then
			setSpriteImage(_t.spr, g_imgSpotLight)
			break endif
		if _t.name == "world" then
			setSpriteImage(_t.spr, g_imgWorldLight)
			break
		else
			setSpriteImage(_t.spr, g_imgWorldShadowLight)
			break
		endif break repeat
		
		setSpriteColor(_t.spr, _t.col)
		setSpriteScale(_t.spr, _t.sprScale)
	endif
return _t

/* Universal light placement function. */
// CORE LOADER
function placeLightByType(_type, _pos, _dir, _col, _brightness, _range, _res)
return placeLightByType(_type, _col, _pos, _brightness, _res, _dir, 0, _range)

function placeLightByType(_type, _pos, _dir, _col, _brightness, _spread)
return placeLightByType(_type, _col, _pos, _brightness, 0, _dir, _spread, 0)

function placeLightByType(_type, _pos, _col, _brightness, _res)
return placeLightByType(_type, _col, _pos, _brightness, _res, {0, 0, 1}, 0, 0)

function placeLightByType(_type, _pos, _col, _brightness)
return placeLightByType(_type, _col, _pos, _brightness, 0, {0, 0, 1}, 0, 0)

function placeLightByType(_type, _col)
return placeLightByType(_type, _col, {0, 0, 0}, 0, 0, {0, 0, 1}, 0, 0)

function placeLightByType(_type, _col, _pos, _brightness, _res, _dir, _spread, _range)
	var newLight
	
	loop if _type == "point" then
		newLight = pointLight(_pos, _col, _brightness)
		break endif
	if _type == "pointshadow" then
		newLight = pointShadowLight(_pos, _col, _brightness, _res)
		break endif
	if _type == "spot" then
		newLight = spotLight(_pos, _dir, _col, _brightness, _spread)
		break endif
	if _type == "world" then
		newLight = worldLight(_dir, _col, _brightness)
		break endif
	if _type == "worldshadow" then
		newLight = worldShadowLight(_pos, _dir, _col, _brightness, _range, _res)
		break
	endif break repeat
return newLight

/* Places an object that contains children or lights from a template. */
// CORE LOADER
function placeGrpObj(_template, _appliedTemplate)
	var fov
	
	if g_editor then
		fov = g_cam.fov
	else
		fov = 70
	endif
return placeGrpObj(_template, _appliedTemplate, fov)

function placeGrpObj(_template, _appliedTemplate, _fov)
	var result = placeGrpObjNoLightTransform(_template, _appliedTemplate, _fov)
	
	var lightContainer = [ 
		.lights = result.lights, 
		.children = result.children, 
		.pos = _template.pos,
		.scale = _template.scale,
		.fwd = {0, 0, 1},
		.up = {0, 1, 0}]
		
	setGrpLightsPos(lightContainer, _fov)
	edFunction(-1, "setGrpLightsSprScale", [ lightContainer, lightContainer.scale ])
return result

// CORE LOADER
function placeGrpObjNoLightTransform(_template, _appliedTemplate, _fov)
	var newObj
	var children
	array lights[len(_template.lights)]
	
	if len(_template.children) or len(_template.lights) then
		newObj = createObjectGroup(_template.pos)
		setObjectScale(newObj, _template.scale)
		children = _template.children
		
		var bank
		var idx
		var newGrp
		var i
		
		for i = 0 to len(_template.children) loop
			decodeBank(bank, _template.children[i].bankIdx)
			decodeIdx(idx, _template.children[i].bankIdx)
			
			if len(_template.children[i].children) 
					or len(_template.children[i].lights) then
				newGrp = placeGrpObjNoLightTransform(
					_template.children[i],
					_appliedTemplate.children[i],
					_fov
				)
				children[i].obj = newGrp.obj
				children[i].children = newGrp.children
				children[i].lights = newGrp.lights
			else
				children[i].obj = placeObjDef(
					getObjDef(-1, _template.children[i]), 
					_template.children[i].pos,
					_template.children[i].scale
				)
			endif
			
			setObjRot(children[i].obj, children[i].pos,
				children[i].fwd, children[i].up)
			setObjectParent(children[i].obj, newObj)
		repeat
		
		for i = 0 to len(lights) loop
			lights[i] = placeLightFromTemplate(_template.lights[i])
		repeat
	else
		//DEBUG CONDITION; SHOULD NEVER OCCUR
		clear(black)
		ink(white)
		textSize(gheight() / 25)
		printAt(1, 1, "Error in placeGrpObjNoLightTransform():" + chr(10) +
			getMapObjName(-1, _template) + " is not a merged object." + chr(10) +
			"Creating placeholder waffle ...")
		update()
		sleep(1)
		
		var newModel = loadModel("Devils Garage/waffle") // Sorry, have a waffle instead :(
		newObj = placeObject(newModel, {0, 0, 0}, {1, 1, 1})
	endif
	
	var result = [
		.obj = newObj,
		.children = children,
		.lights = lights
	]
return result

/* Creates a cube collider of the same size as _obj's extent. */
// CORE LOADER
function createObjCollider(_obj)
	var ext = g_obj[decodeBank(-1, _obj.bankIdx)][decodeIdx(-1, _obj.bankIdx)].ext
	var colliderPos = getExtCenter(ext)
	var colliderScale = absVec3(ext.hi - ext.lo) / 2
	var colObj = [
		.obj = placeObject(cube, _obj.pos + colliderPos, colliderScale),
		.pos = colliderPos,
		.scale = colliderScale,
		.fwd = {0, 0, 1},
		.up = {0, 1, 0}
	]
	colObj = applyGrpTransform(colObj, _obj)
	setObjectPos(colObj.obj, colObj.pos)
	setObjectScale(colObj.obj, colObj.scale)
	setObjRot(colObj.obj, colObj.pos, colObj.fwd, colObj.up)
return colObj

/* Places instantiated object data in a cell that the object intersects. */
// CORE LOADER
function addCellToGridBitList(_obj, _objCollider, _midCell, _midCellPos)
	var cellW = getCellWidth()
	var cellHalfW = cellW / 2
	var cellCollider = placeObject(cube, _midCellPos, {cellHalfW, cellHalfW, cellHalfW})
	var added = false
	var allowCell = []
	
	var inter = mergedObjIntersect(_obj, cellCollider, false)
	if inter then
		if _midCell < 0 then
			_midCell = addCell(_midCellPos)
		endif
		
		_obj = getGrpCollisionBits(_obj, _midCell)
		added = true
	endif
	
	var dirs = [
		{1, 0, 0},
		{-1, 0, 0},
		{0, 1, 0},
		{0, -1, 0},
		{0, 0, 1},
		{0, 0, -1}
	]
	var adjIdx
	var adjArr = getAdj(_midCell, _midCellPos)
	
	/* If the object extends into an adjacent cell, allow checking gridBit for that cell. */
	var i
	for i = 0 to len(dirs) loop
		adjIdx = getAdjIdxFromOffset(dirs[i])
		setObjectPos(cellCollider, _midCellPos + dirs[i] * cellW)
		
		if objectIntersect(_objCollider, cellCollider) then
			allowCell = push(allowCell, [ adjArr[adjIdx], _midCellPos + dirs[i] * cellW ])
		endif
	repeat
	
	removeObject(cellCollider)
	
	var result = [
		.obj = _obj,
		.added = added,
		.cell = _midCell,
		.allow  = allowCell
	]
return result

/* Places an object in the map. */
// CORE LOADER
function addMapObj(_activeObj, _pos, _fwd, _up, _scale, _isGrp)
	_pos = roundVec(_pos, 6)
	mapObj newObj
	
	if _isGrp then
		var newGrp = placeGrpObj(_activeObj, _activeObj)
		newObj.obj = newGrp.obj
		newObj.children = newGrp.children
		newObj.lights = newGrp.lights
	else
		newObj.obj = placeObjDef(
			getObjDef(-1, _activeObj),
			_pos, 
			_scale
		)
		newObj.children = []
	endif
	
	newObj.fwd = _fwd
	newObj.up = _up
	newObj.scale = _scale
	newObj.pos = _pos
	newObj.bankIdx = _activeObj.bankIdx
	newObj.col = _activeObj.col
	newObj.mat = _activeObj.mat
	restoreDefaultObjCol(newObj)
	
	setObjectPos(newObj.obj, _pos)
	setObjRot(newObj.obj, _pos, _fwd, _up)
	setGrpLightsPos(newObj)
	
	var isRef
	var canPlaceObj = true
	var baseCell = -1
	var baseIdx = -1
	var refCellIdx = -1
	array cellIdx[0]
	array checkedCellPos[0]
	var i
	var addResult
	var newObjCell
	array allowCell[0]
	
	var bank
	decodeBank(bank, newObj.bankIdx)
	var idx
	decodeIdx(idx, newObj.bankIdx)
	var objDef = g_obj[bank][idx]
	var extCenter = getExtCenter(getExtMinMax(objDef.ext, newObj.scale, newObj.fwd, newObj.up))
	var objCollider = createObjCollider(newObj)
	var checkCell = getCellIdxFromPos(objCollider.pos)
	var toCheck = [ [ checkCell, getCellPosFromPos(objCollider.pos)] ]
	var toCheckCell
	var toCheckPos
	
	// Add object to all cells that it intersects
	while len(toCheck) loop
		toCheckCell = toCheck[0][0]
		toCheckPos = toCheck[0][1]
		
		if !contains(checkedCellPos, toCheckPos) then
			checkedCellPos = push(checkedCellPos, toCheckPos)
			addResult = addCellToGridBitList(newObj, objCollider.obj, toCheckCell, toCheckPos)
			// addResult.allow contains cells that the object might overlap
			toCheck = insertArray(toCheck, addResult.allow)
			
			if addResult.added then
				newObj = addResult.obj
				cellIdx = push(cellIdx, addResult.cell)
				
				// Base cell, where the object data is stored
				if len(cellIdx) == 1 then
					baseCell = addResult.cell
					
					// Ensure the object doesn't already exist
					for i = g_cellObjStart to len(g_cell[baseCell]) loop
						isMapObjRef(isRef, g_cell[baseCell][i])
						
						if !isRef then
							if mapObjEquals(g_cell[baseCell][i], newObj) then
								canPlaceObj = false
								
								break
							endif
						endif
					repeat
					
					if !canPlaceObj then break endif
					
					baseIdx = len(g_cell[addResult.cell])
					refCellIdx = encodeCellIdx(addResult.cell, baseIdx)
				// Additional cells, where object references are stored
				else
					mapObjRef newRef
					newRef.cellIdx = refCellIdx
					g_cell[addResult.cell] = push(g_cell[addResult.cell], newRef)
				endif
			endif
		endif
		
		toCheck = remove(toCheck, 0)
	repeat
	
	removeObject(objCollider.obj)
	
	if !canPlaceObj then
		newObj = removeGroupObj(newObj)
	else
		g_cell[baseCell] = push(g_cell[baseCell], newObj)
		
		// Add list of what cells the object exists in.
		array cellIdxList[len(cellIdx)]
		var lastObjIdx
		
		for i = 0 to len(cellIdx) loop
			lastObjIdx = len(g_cell[cellIdx[i]]) - 1
			cellIdxList[i] = [ .cell = cellIdx[i], .idx = lastObjIdx ]
		repeat
		
		array baseCellIdx[len(cellIdxList)]
		g_cell[baseCell][baseIdx].cellIdx = baseCellIdx
		
		for i = 0 to len(cellIdxList) loop
			g_cell[baseCell][baseIdx].cellIdx[i] = encodeCellIdx(cellIdxList[i].cell, cellIdxList[i].idx)
		repeat
		
		// Store data about light sprites if we're in the editor
		if g_editor then
			var lightTypes
			edFunction(lightTypes, "getGrpLightsTypes", [ newObj ])
			
			if len(lightTypes) then
				var objRef = [ .cell = cellIdx[0], .idx = len(g_cell[cellIdx[0]]) - 1 ]
				
				g_lightIcons = push(g_lightIcons, objRef)
				
				if contains(lightTypes, "world") or contains(lightTypes, "worldshadow") then
					g_worldLights = push(g_worldLights, objRef)
				endif
			endif
		endif
		
		// Uncomment to view gridBit data when an object is placed
		//debugGridBit3d(g_cell[cellIdx[0]][len(g_cell[cellIdx[0]]) - 1].gridBitList, 999)
		//debugGridBit(g_cell[cellIdx[0]][len(g_cell[cellIdx[0]]) - 1].gridBitList, 0)
	endif
return newObj

	// ----------------------------------------------------------------
	// OBJECT REMOVAL

/* Removes an object or merged object. */
// CORE LOADER
function removeGroupObj(_obj)
	var i
	for i = 0 to len(_obj.lights) loop
		deleteLightObj(_obj.lights[i])
	repeat
	
	for i = 0 to len(_obj.children) loop
		if len(_obj.children[i].children) or len(_obj.children[i].lights) then
			_obj.children[i] = removeGroupObj(_obj.children[i])
		else
			removeObject(_obj.children[i].obj)
			_obj.children[i].obj = -1
		endif
	repeat
	
	removeObject(_obj.obj)
	_obj.obj = -1
return _obj

/* Removes instantiated object models from the world without cleaning up the
g_cell entries. Should only be used when clearing a map or in other cases
where record sanitation doesn't matter. */
// CORE LOADER
function fastDeleteMapObj(_obj)
	if !isMapObjRef(-1, _obj) then
		removeGroupObj(_obj)
	endif
return void

/* Removes instantiated elements of a light object. */
// CORE LOADER
function deleteLightObj(_obj)
	removeLight(_obj.light)
	_obj.light = -1
	
	if g_editor then
		removeSprite(_obj.spr)
	endif
	
	_obj.spr = -1
return _obj

/* Deletes every object in the map. */
// CORE LOADER
function clearMap()
	var i
	var j
	
	for i = 0 to len(g_cell) loop
		j = g_cellObjStart
		while j < len(g_cell[i]) loop
			fastDeleteMapObj(g_cell[i][j])
			
			j += 1
		repeat
	repeat
	
	g_cell = []
return void

	// ----------------------------------------------------------------
	// OBJECT RETRIEVAL

/* Checks whether _obj is actually a reference to another object. */
// CORE LOADER
function isMapObjRef(ref _in, _obj)
	_in = false
	
	var cellIdxLen = len(_obj.cellIdx)
	var cellIdxStr = str(_obj.cellIdx) // Avoid multiple nested ifs to reduce stack size
	
	if !cellIdxLen and cellIdxStr != "-1" then
		_in = true
	endif
return _in

/* Returns the actual mapObj that a reference points to. */
// CORE LOADER
function getMapObjFromRef(_ref)
	var obj
	
	if isMapObjRef(-1, _ref) then
		var idx
		decodeIdx(idx, _ref.cellIdx)
		
		obj = g_cell[decodeCell(_ref.cellIdx)][idx]
	else
		obj = _ref
	endif
return obj

	// ----------------------------------------------------------------
	// LIGHT OBJECT

/* Returns an active light of the specifed name. */
// CORE LOADER
function getActiveLightFromName(_name)
	var newObj
	
	loop if _name == "point" then
		newObj = activeFromObjDef(g_lightBank, 0)
		break endif
	if _name == "pointshadow" then
		newObj = activeFromObjDef(g_lightBank, 1)
		break endif
	if _name == "spot" then
		newObj = activeFromObjDef(g_lightBank, 2)
		break endif
	if _name == "world" then
		newObj = activeFromObjDef(g_lightBank, 3)
		break endif
	if _name == "worldshadow" then
		newObj = activeFromObjDef(g_lightBank, 4)
		break
	endif break repeat
return newObj

/* Default values for a light object. */
// CORE LOADER
function initLightObj()
	var alpha
	
	if g_editor then
		alpha = g_sprAlpha
	else
		alpha = 1
	endif
	
	lightObj l
	l.light = -1
	l.spr = -1
	l.sprScale = {12, 12, 12}
	l.pos = {0, 0, 0}
	l.fwd = {0, 0, 1}
	l.brightness = 1
	l.col = {1, 1, 1, alpha}
	l.spread = 1
	l.res = 8
	l.range = 100
	l.name = ""
return l

/* This function modifies properties of the object passed to it in order
to apply recursive transforms to lights to sync them with the rest of the
object. This is needed because lights can't be auto-modified as part of an 
object group like objects can. DO NOT modify this function to return the object, 
because these object modifications are only relevant in the context of this
specific function and should be discarded when done. */
// CORE LOADER
function setGrpLightsPos(_obj)
	var fov
	
	if g_editor then
		fov = g_cam.fov
	else
		fov = 70
	endif
return setGrpLightsPos(_obj, fov)

function setGrpLightsPos(_obj, _fov)
	var i
	var light2dPos
	
	for i = 0 to len(_obj.lights) loop
		_obj.lights[i] = applyGrpPos(_obj.lights[i], _obj)
		
		if g_editor then
			edFunction(light2dPos, "worldPosToScreenPos", [ _obj.lights[i].pos, 
				g_cam.fwd, g_cam.up, g_cam.pos, _fov ])
			setSpriteLocation(_obj.lights[i].spr, light2dPos)
		endif
		
		setLightPos(_obj.lights[i].light, _obj.lights[i].pos)
	repeat
	
	for i = 0 to len(_obj.children) loop
		_obj.children[i] = applyGrpTransform(_obj.children[i], _obj, false, true)
		_obj.children[i].scale *= _obj.scale
		setGrpLightsPos(_obj.children[i], _fov)
	repeat
return void
	
	// ----------------------------------------------------------------
	// OBJECT PROPERTIES

/* Applies material for a merged object without setting the .col/.mat properties. */
// CORE LOADER
function applyGroupMaterial(_obj, _tint, _metal, _rough, _em)
	if len(_obj.children) then
		var i
		for i = 0 to len(_obj.children) loop
			if len(_obj.children[i].children) then
				applyGroupMaterial(_obj.children[i], _tint, _metal, _rough, _em)
			else
				setObjectMaterial(_obj.children[i].obj, _tint, _metal, _rough, _em)
			endif
		repeat
	else
		setObjectMaterial(_obj.obj, _tint, _metal, _rough, _em)
	endif
return void

/* Sets and applies material for a merged object. */
// CORE LOADER
function setGroupMaterial(_obj)
return setGroupMaterial(_obj, {-1, -1, -1, -1}, -1, -1, -1)

function setGroupMaterial(_obj, _overrideCol, _overrideMetal, _overrideRough, _overrideEm)
	var newMat = [
		ifElse(_overrideMetal == -1, _obj.mat[0], _overrideMetal),
		ifElse(_overrideRough == -1, _obj.mat[1], _overrideRough),
		ifElse(_overrideEm == -1, _obj.mat[2], _overrideEm)
	]
	
	var newCol = ifElse(_overrideCol == {-1, -1, -1, -1}, _obj.col, _overrideCol)
	_obj.mat = newMat
	_obj.col = newCol
	
	if !len(_obj.lights) and !len(_obj.children) then
		setObjectMaterial(_obj.obj, newCol, newMat[0], newMat[1], newMat[2])
	endif
	
	if len(_obj.children) then
		if _overrideCol == {-1, -1, -1, -1} then
			_overrideCol = _obj.col
		endif
		
		if _overrideMetal == -1 then
			_overrideMetal = _obj.mat[0]
		endif
		
		if _overrideRough == -1 then
			_overrideRough = _obj.mat[1]
		endif
		
		if _overrideEm == -1 then
			_overrideEm = _obj.mat[2]
		endif
	endif
	
	var i
	for i = 0 to len(_obj.children) loop
		_obj.children[i] = setGroupMaterial(_obj.children[i], _overrideCol, _overrideMetal, 
			_overrideRough, _overrideEm)
	repeat
return _obj

/* Sets rotation for a merged object. _pos is needed in order for
safeObjPointAt() to work; if the bug in objectPoinAt() is fixed in the
future, _pos will no longer be needed. */
// CORE LOADER
function setObjRot(_obj, _pos, _fwd, _up)
	/* A straight up or down forward wrecks the algorithm, so fudge the 
	vectors if necessary. */
	if equals(abs(_fwd.y ), 1, 0.000001) then
		_fwd = axisRotVecBy(_fwd, _up, 0.015)
	endif
	
	/* When called from any orientation, objectPointAt() will always 
	result in a positive-y up vector and a 0-y right vector, so it's 
	predictable enough that we can infer the object's up/right vectors 
	even without specific data about how they've been modified. */
	safeObjectPointAt(_obj, _pos, _pos + _fwd)
	
	var unrolledR
	unrolledR = axisRotVecBy(flattenY(_fwd), {0, 1, 0}, -90)
	
	var unrolledUp = axisRotVecBy(_fwd, unrolledR, 90)
	var roll = getAngleBetweenVecs(unrolledUp, _up)
	
	if roll and roll >= -360 and roll <= 360 then
		if roundVec(axisRotVecBy(unrolledUp, _fwd, roll), 2) != roundVec(_up, 2) then
			roll *= -1
		endif
		
		rotateObject(_obj, {0, 0, 1}, roll)
	endif
return void

/* objectPointAt() doesn't like straight up/down -- it will make the object
disappear, which we fix by never using an exact up/down rotation. */
// CORE LOADER
function safeObjectPointAt(_obj, _objPos, _dir)
	var dif = _dir - _objPos
	
	if dif.x == 0 and dif.z == 0 then
		_dir = _objPos + axisRotVecBy(dif, {1, 0, 0}, 0.015)
	endif
	
	objectPointAt(_obj, _dir)
return void

/* Objects in a group use the group's local space for scale. This function 
applies the group's scale modifier to a non-group object. */
// CORE LOADER
function applyGrpScale(_grpScale, _childScale, _childFwd, _childUp)
	var locR = cross(_childFwd, _childUp)
	var deg = getAngleBetweenVecs({-1, 0, 0}, locR)
	
	var locX = absVec3(axisRotVecBy({1, 0, 0}, cross({-1, 0, 0}, locR), 
		-deg))
	deg = getAngleBetweenVecs({0, 1, 0}, _childUp)
	var locY = absVec3(axisRotVecBy({0, 1, 0}, cross({0, 1, 0}, _childUp), 
		-deg))
	deg = getAngleBetweenVecs({0, 0, 1}, _childFwd)
	var locZ = absVec3(axisRotVecBy({0, 0, 1}, cross({0, 0, 1}, _childFwd), 
		-deg))
	
	appliedScale = absVec3(_grpScale.x * (locX * getSign(_grpScale.x)))
		+ absVec3(_grpScale.y * (locY * getSign(_grpScale.y)))
		+ absVec3(_grpScale.z * (locZ * getSign(_grpScale.z)))
	
	appliedScale = {appliedScale.x / (locX.x + locY.x + locZ.x) * getSign(_grpScale.x),
		appliedScale.y / (locX.y + locY.y + locZ.y) * getSign(_grpScale.y),
		appliedScale.z / (locX.z + locY.z + locZ.z) * getSign(_grpScale.z)}
return _childScale * appliedScale

/* Objects in a group use the group's local space for position, rotation, and
scale. This function applies the group's postion/rotation/scale modifiers to 
a non-group object. */
// CORE LOADER
function applyGrpTransform(_obj, _grpObj)
return applyGrpTransform(_obj, _grpObj, true, true)

function applyGrpTransform(_obj, _grpObj, _hasScale, _hasUp)
		
	if _hasScale then
		_obj.scale = applyGrpScale(_grpObj.scale, _obj.scale, _obj.fwd, _obj.up)
	endif
	
	var objR = cross(_grpObj.fwd, _grpObj.up)
	
	_obj.pos *= _grpObj.scale
	
	_obj.pos = changeVecSpaceZFwd(_obj.pos, _grpObj.fwd, _grpObj.up, 
		objR, {0, 0, 0})
	_obj.pos += _grpObj.pos
	_obj.fwd = changeVecSpaceZFwd(_obj.fwd, _grpObj.fwd, _grpObj.up, 
		objR, {0, 0, 0})
	
	if _hasUp then
		_obj.up = changeVecSpaceZFwd(_obj.up, _grpObj.fwd, _grpObj.up, 
			objR, {0, 0, 0})
	endif
return _obj

/* Objects in a group use the group's local space for position. This 
function applies the group's postion modifier to a non-group object. */
// CORE LOADER
function applyGrpPos(_obj, _grpObj)
return applyGrpPos(_obj, _grpObj, true)

function applyGrpPos(_obj, _grpObj, _scalePos)
	if _scalePos then
		_obj.pos *= _grpObj.scale
	endif
	
	var objR = cross(_grpObj.fwd, _grpObj.up)
	_obj.pos = changeVecSpaceZFwd(_obj.pos, _grpObj.fwd, _grpObj.up, 
		objR, {0, 0, 0})
	_obj.pos += _grpObj.pos
return _obj

/* Checks equality of two mapObjs. Does not consider equality among children or
lights within the object. */
// CORE LOADER
function mapObjEquals(_obj1, _obj2)
	var eq = _obj1.fwd == _obj2.fwd 
		and _obj1.up == _obj2.up 
		and _obj1.scale == _obj2.scale 
		and _obj1.pos == _obj2.pos 
		and _obj1.bankIdx == _obj2.bankIdx
return eq

/* Sets an object back to the default non-flashing color. An override color will replace the color of
any children below the point in the parent/child structure where it is given. */
function restoreDefaultObjCol(_obj)
	setGroupMaterial(_obj, {-1, -1, -1, -1}, -1, -1, -1)
return void

/* To reduce variable count, bank and index numbers are stored together
in a single variable. They each occupy 16 bits of a 32-bit int, with the
16 MSBs representing the bank and the 16 LSBs representing the index. */
// CORE LOADER
function encodeBankIdx(_bank, _idx)
return bitFieldInsert(0, 0, 16, _idx) | bitFieldInsert(0, 16, 16, _bank)

function decodeBankIdx(_bankIdx)
	result = [
		.bank = bitFieldExtract(_bankIdx, 16, 16),
		.idx = bitFieldExtract(_bankIdx, 0, 16)
	]
return result

// CORE LOADER
function decodeBank(ref _in, _bankIdx)
	_in = bitFieldExtract(_bankIdx, 16, 16)
return _in

// CORE LOADER
function decodeIdx(ref _in, _bankIdx)
	_in = bitFieldExtract(_bankIdx, 0, 16)
return _in

/* Cell and index work the same way as bank/index but are separate functions
both for clarity and in case the system changes. */
// CORE LOADER
function decodeCell(_cellIdx)
return bitFieldExtract(_cellIdx, 16, 16)

// CORE LOADER
function encodeCellIdx(_cell, _idx)
return bitFieldInsert(0, 0, 16, _idx) | bitFieldInsert(0, 16, 16, _cell)

/* To reduce variable count, object names are stored only in the definition
and not cached in the object instantiation. This function reads the object's 
name out of the appropriate definition. */
// CORE LOADER
function getMapObjName(ref _in, _obj)
	var isRef
	isMapObjRef(isRef, _obj)
	
	if isRef then
		_obj = getMapObjFromRef(_obj)
	endif
	
	_in = ""
	
	/* During merged def loads, .bankIdx may temporarily contain a missing object's
	name, so we screen this with len(). */
	var bankIdxLen = len(_obj.bankIdx)
	var bankIdxStr = str(_obj.bankIdx) // Avoid multiple nested ifs to reduce stack size
	
	if !bankIdxLen and bankIdxStr != "-1" then
		var bank
		decodeBank(bank, _obj.bankIdx)
		var idx
		decodeIdx(idx, _obj.bankIdx)
		var objBank = g_obj[bank]
		var nameObj = objBank[idx]
		_in = nameObj.name
	else if bankIdxLen then
		_in = _obj.bankIdx
	endif endif
return _in

	// ----------------------------------------------------------------
	// COMPOSITE OBJECTS	

/* Removes a composite object with a standard structure. */
function removeGenericObj(_obj)
	var i
	for i = 0 to len(_obj.obj) loop
		removeObject(_obj.obj[i])
	repeat
	
	removeObject(_obj.grp)
return void

/* Creates an arrow. Remove with removeGenericObj(). */
function createArrowObj(_pos, _fwd, _len, _rad, _headSize, _col, _metal, _rough, _emit)
	var grp = createObjectGroup({0, 0, 0})
	array shape[2]
	
	shape[0] = placeObject(cylinder, {0, 0, (_len / 2) * -1 - _headSize / 2}, {_rad / 2, _rad / 2, _len / 2 - _headSize / 2})
	shape[1] = placeObject(pyramid, {0, 0, _headSize * -1}, {_headSize / 2, _headSize, _headSize / 2})
	rotateObject(shape[1], {1, 0, 0}, 90)
	
	var i
	for i = 0 to 2 loop
		setObjectMaterial(shape[i], _col, _metal, _rough, _emit)
		setObjectParent(shape[i], grp)
	repeat
	
	safeObjectPointAt(grp, {0, 0, 0}, _fwd)
	setObjectPos(grp, _pos)
	
	var obj = [
		.grp = grp,
		.obj = shape,
		.l = _len,
		.rad = _rad,
		.headSize = _headSize
	]
return obj

// ----------------------------------------------------------------
// CELLS

/* Adds a new cell in the map. The cell will snap to the closest appropriate
position to _pos. */
// CORE LOADER
function addCell(_pos)
return addCell(_pos, [])

function addCell(_pos, _savedAdj)
	var idx = len(g_cell)
	
	g_cell = push(g_cell, [ 0, [] ]) // [ pos, adjacent cells ]
	g_cell[idx][0] = getCellPosFromPos(_pos) // Cell position
	
	/* If _savedAdj contains data, we assume that all cells are being loaded from
	and that we don't need to update other cells' data, because their saved data
	will already be correct. */
	if !len(_savedAdj) then
		var adj = generateAdjacentCells(_pos)
		
		g_cell[idx][1] = adj // Adjacent cells
		/* Additional indices in g_cell[idx] contain objects within the cell. If you
		need to iterate objects in the cell, begin indexing at g_cellObjStart, which
		gives the first index in a cell that contains an object. */
		
		var i
		for i = 0 to len(adj) loop
			if adj[i] > -1 and i != 13 then
				updateAdjacentCell(adj[i], 
					getAdjIdxFromOffset(getOffsetFromAdjIdx(i) * -1), idx)
			endif
		repeat
	else
		g_cell[idx][1] = _savedAdj
	endif
return idx

/* Gets the width/height/depth of a cell. */
// CORE LOADER
function getCellWidth()
return abs(g_cellExt.lo.x) + abs(g_cellExt.hi.x)

/* Discovers which cells are adjacent to the cell that contains the given 
position. */
// CORE LOADER
function generateAdjacentCells(_pos)
	array adj[27]
	var cellW = getCellWidth()
	var idx = 0
	var z
	var y
	var x
	
	for z = -1 to 2 loop
		for y = -1 to 2 loop
			for x = -1 to 2 loop
				// If no cell is adjacent in this direction, the cell index will be -1
				adj[idx] = getCellIdxFromPos(_pos + {cellW * x, cellW * y, cellW * z})
				
				idx += 1
			repeat
		repeat
	repeat
return adj

/* Assigns a neighbor cell to a cell's adj array and update cell oulines. */
// CORE LOADER
function updateAdjacentCell(_idx, _adjIdx, _neighborIdx)
	g_cell[_idx][1][round(_adjIdx)] = _neighborIdx
return void

/* Gets a cell's array of adjacent cells. _pos allows for a fallback check if
_midCell dosn't exist. */
// CORE LOADER
function getAdj(_midCell, _pos)
	array adj[27]
	
	if _midCell >= 0 and _midCell < len(g_cell) then
		adj = g_cell[_midCell][1]
	/* Fallback for when we are OOB and don't have a list of adjacents. Slower. */
	else
		var cellW = getCellWidth()
		var exactPos = getCellPosFromPos(_pos)
		var rangeCells = getCellsInRange(exactPos, sqrt(pow(cellW, 2) + (pow(cellW, 2) * 2)))
		var i
		var adjPos
		var j
		
		for i = 0 to len(adj) loop
			adjPos = exactPos + getOffsetFromAdjIdx(i) * cellW
			
			/* This is basically getCellIdxFromCellPos(), but duplicating the
			code instead of making the function call is faster, and speed is
			paramount here. */
			adj[i] = -1
			
			for j = 0 to len(rangeCells) loop
				if adjPos == g_cell[rangeCells[j]][0] then
					adj[i] = rangeCells[j]
					
					break
				endif
			repeat
		repeat
	endif
return adj

/* Converts an adjacent index to a cell position relative to the middle cell. */
// CORE LOADER
function getOffsetFromAdjIdx(_idx)
return {_idx % 3 - 1, floor((_idx % 9) / 3) - 1, floor(_idx / 9) - 1}

/* Returns an array indices of cells whose midpoints are within the given
range from the origin. */
// CORE LOADER
function getCellsInRange(_origin, _range)
	array cells[0]
	
	var i
	for i = 0 to len(g_cell) loop
		if distance(_origin, g_cell[i][0]) <= _range then
			cells = push(cells, i)
		endif
	repeat
return cells

/* Converts a position offset from a cell into an index for adjacent positions. */
// CORE LOADER
function getAdjIdxFromOffset(_off)
	var adjIdx
	
	if abs(_off.x) <= 1 and abs(_off.y) <= 1 and abs(_off.z) <= 1 then
		adjIdx = (_off.x + 1) + (_off.y + 1) * 3 + (_off.z + 1) * 9
	else
		adjIdx = -1
	endif	
return adjIdx

/* Returns whether the position is within the given cell. */
// CORE LOADER
function isPosInCell(_pos, _cellIdx)
	var isInCell = true
	
	if _cellIdx > -1 then
		var cPos = g_cell[_cellIdx][0]
		
		var i
		for i = 0 to 3 loop
			if _pos[i] < cPos[i] + g_cellExt.lo[i] 
					or _pos[i] >= cPos[i] + g_cellExt.hi[i] then
				isInCell = false
				
				break
			endif 
		repeat
	else
		isInCell = false
	endif
return isInCell

/* Finds the position of the cell that does (or would) contain _pos. The
cell itself does not necessarily exist. */
// CORE LOADER
function getCellPosFromPos(_pos)
	// Assume cell is an equal-sided cube
	var cellW = getCellWidth()
	var cellPos = roundVec3ToMultiple(_pos, cellW, -cellW / 2)
return cellPos

/* Finds the cell that contains position _pos. */
// CORE LOADER
function getCellIdxFromPos(_pos)
	var idx = -1
	
	var i
	for i = 0 to len(g_cell) loop
		if isPosInCell(_pos, i) then
			idx = i
			
			break
		endif
	repeat
return idx

/* Snaps a direction's axis values to 1, 0, or -1. Conceptually equivalent to
a unit vector for finding adjacent cells. */
// CORE LOADER
function getCellDir(_dir)
	var i
	for i = 0 to 3 loop
			var rounded = roundDec(_dir[i], 6)
		if rounded != 0 then
			_dir[i] = getSign(rounded)
		else
			_dir[i] = 0
		endif
	repeat
return _dir

/* Checks if a position has moved into an adjacent cell. */
// CORE LOADER
function updateCellContext(_oldCell, _oldCellPos, _newPos, _allowAddCell, _forceUpdate)
	var result = [
		.cell = _oldCell,
		.cellPos = _oldCellPos
	]
	
	var newCellPos = getCellPosFromPos(_newPos)
	if _oldCellPos != newCellPos or _forceUpdate then
		var cellIdx = -1
		var adjCells = getAdj(_oldCell, _oldCellPos)
		
		var i
		for i = 0 to len(adjCells) loop
			if isPosInCell(newCellPos, adjCells[i]) then
				cellIdx = adjCells[i]
				break
			endif
		repeat
		
		result.cellPos = newCellPos
		
		// If we're OOB
		if cellIdx < 0 then
			cellIdx = getCellIdxFromPos(_newPos)
			if cellIdx < 0 and _allowAddCell then
				cellIdx = addCell(_newPos)
			endif
		endif
		
		result.cell = cellIdx
	endif
return result

// ----------------------------------------------------------------
// INPUT

/* Checks whether a directional input should cause menu navigation and, if so,
updates g_cDat with the input info and returns true. */
function menuDirInputStarted(_c, _kbActive)
	var started = (_kbActive // _kbActive bypasses the repeat rate in order to use the keyboard's built-in repeat rate.
		or (g_cDat[g_cIdx.lxy].count <= 1 and time() - g_cDat[g_cIdx.lxy].lastTime >= g_rateInit)
		or (g_cDat[g_cIdx.lxy].count > 1 and time() - g_cDat[g_cIdx.lxy].lastTime >= g_rateRep))
		and (abs(_c.lx) > 0.3 or abs(_c.ly) > 0.3 or _c.up or _c.down or _c.left or _c.right)
	
	if started then
		updateLxyStarted()
	else if abs(_c.lx) <= 0.3 and abs(_c.ly) <= 0.3 and !_c.up 
			and !_c.down and !_c.left and !_c.right then
		updateLxyStopped()
	endif endif
return started

/* Updates g_cDat for left stick input starting. */
function updateLxyStarted()
	g_cDat[g_cIdx.lxy].lastTime = time()
	g_cDat[g_cIdx.lxy].held = true
	g_cDat[g_cIdx.lxy].count += 1
return void

/* Updates g_cDat for left stick input stopping. */
function updateLxyStopped()
	g_cDat[g_cIdx.lxy].held = false
	g_cDat[g_cIdx.lxy].count = 0
return void


// ----------------------------------------------------------------
// COLLISIONS

/* Returns the normal direction of a surface. */
// CORE LOADER
function getNormal(ref _in, _obj, _cell, _colCon, _range, _castPos, _planeOrig, _castFwd, _castUp, _gridBitAdj)
	var castCount = 3
	_castFwd = safeNormalize(_castFwd)
	_castUp = safeNormalize(_castUp)
	var validResult = false
	var scores = []
	var hiScoreIdx = 0
	
	var r = safeCross(_castFwd, _castUp)
	var offset = [
		_castUp * _range,
		r * _range,
		r * -_range + _castUp * -_range
	]
	
	var hits = []
	var norms = []
	var i
	for i = 0 to castCount loop
		var newHit
		raycastGrp(newHit, _obj, _cell, _castPos + offset[i], _castFwd, 
			_colCon.gridBit[_gridBitAdj], false, float_max)
		
		if newHit.hit < float_max then
			hits = push(hits, _castPos + offset[i] + _castFwd * newHit.hit)
		endif
	repeat
	
	if len(hits) > 1 then // Need at least two hits + _planeOrigin to find a plane
		array newNorms[len(hits)] 
		norms = newNorms
		
		for i = 0 to len(hits) loop
			 norms[i] = safeCross(hits[(i + 1) % len(hits)] - _planeOrig, hits[i] - _planeOrig)
			
			if norms[i] == {0, 0, 0} then
				norms[i] = {0, 1, 0}
			endif
		repeat
		
		for i = 0 to len(norms) loop
			if !len(scores) then
				scores = push(scores, [ .pos = norms[i], .score = 1 ])
			else
				var j
				for j = 0 to len(scores) loop
					if equals(norms[i], scores[j].pos, 0.001) then
						scores[j].score += 1
						
						break
					else
						scores = push(scores, [ .pos = norms[i], .score = 1 ])
					endif
				repeat
			endif
		repeat
		
		if len(scores) then
			for i = 1 to len(scores) loop
				if scores[i].score > scores[hiScoreIdx].score then
					hiScoreIdx = i
				endif
			repeat
			
			validResult = true
		endif
	endif
	
	if validResult then
		_in = scores[hiScoreIdx].pos
	else
		_in = {0, 0, 0}
	endif
return _in

/* Call this when an object is first created to initialize its collision
context. 

_grav = {0, -1, 0} approximates normal Earth gravity.
Mass value is clamped between 1 and 100. */
// CORE LOADER
function initColContext(_colCon, _obj, _comPos, _fwd, _up, _scale, _mode, _mass)
return initColContext(_colCon, _obj, _comPos, _fwd, _up, _scale, _mode, _mass, {0, -1, 0}, 0.001, true, true, true)
function initColContext(_colCon, _obj, _comPos, _fwd, _up, _scale, _mode, _mass, _grav, _extRes, _initAuxColllider, _initExt, _initGridBit)
	if _initExt then
		_colCon.ext = getObjExtent(_obj, _comPos, _scale, _fwd, _up, _extRes)
	endif
	
	if _initGridBit then
		_colCon.gridBit = getExtCollisionBitsFast(
			floorVec(_comPos) + 0.5,
			_colCon.ext, 
			_scale, 
			_fwd, 
			_up
		)
	endif
	
	_colCon.cell = -1
	_colCon.cellPos = {float_max, float_max, float_max}
	_colCon.comPos = _comPos
	_colCon.colPos = {float_max, float_max, float_max}
	_colCon.scale = _scale
	_colCon.colScale = {float_max, float_max, float_max}
	_colCon.fwd = _fwd
	_colCon.colFwd = {float_max, float_max, float_max}
	_colCon.up = _up
	_colCon.colUp = {float_max, float_max, float_max}
	_colCon.mass = clamp(_mass, 1, 100)
	_colCon.centerOfMass = getExtCenter(_colCon.ext) * _scale
	_colCon.grav = _grav
	_colCon.vel = {0, 0, 0}
	_colCon.rotVel = 0
	_colCon.rotVelAxis = {1, 0, 0}
	_colCon.objList = []
	_colCon.collision = []
	_colCon.normal = []
	_colCon.normAxis = "up"
	_colCon.colThisFrame = false
	_colCon.deflectThisFrame = false
	_colCon.allCollisions = true
	_colCon.collisionMode = _mode
	_colCon.colDat = []
	
	var orig = getOriginFromCom(_comPos, _colCon.centerOfMass, _fwd, _up, _scale)
	setObjectPos(_obj, orig)
	
	if _initAuxColllider then
		_colCon.auxCollider = placeObject(cube, orig, {0.5, 0.5, 0.5})
		setObjectVisibility(_colCon.auxCollider, false)
		
		colContext auxCon
		auxCon.ext = [ .lo = {-1, -1, -1}, .hi = {1, 1, 1} ]
		_colCon.auxColCon = initColContext(auxCon, _colCon.auxCollider, orig, _fwd, _up, _scale, 1, 0, {0, 0, 0}, 0.001, false, false, false)
	endif
return _colCon

function getOriginFromCom(_comPos, _centerOfMass, _fwd, _up, _scale)
return _comPos - changeVecSpaceZFwd(_centerOfMass * _scale, _fwd, _up, safeCross(_fwd, _up), {0, 0, 0})

/* This is the main collision check function. When given an object and a new position, it calculates whether 
placing the object in that position causes a collision and positions the object to account for that collision.

_obj (object reference): The object whose position, rotation, or scale has changed.
_colCon (colContext): The object's collision context, which stores data about the object's position and collisions.
_pos (vector): The new position of _obj.
_fwd (vector): _obj's new foward vector.
_up (vector): _obj's new up vector.
_scale (vector): _obj's new scale.
_collisionMode (int): Algorithm for collision checks (1: bounding box; 2: simple raycast; 3: cuboid raycast; 
	4: spheroid raycast).
_forceUpdate (bool): Whether to check collisions even if the cached data says not to.
_getAllCollisions (bool): Whether to consider all current collisions instead of only the first one found.
_handleTransformChange (bool): Whether the function should apply the transform changes given as arguments (strongly 
	recommended to be true; if false, some parts of the collision context will need to be updated manually).
_getNormal (bool): Whether to redirect _obj based on the obstacle's shape rather than simply stopping _obj in place.
_frict (float): Velocity factor for _obj's redirected motion. (1: velocity transfers proportionally; >1: velocity 
	increases; <1 but >0: velocity reduces; 0: no velocity -- same as setting _getNormal to false; <0: velocity inverts).
_normRecurLimit (int): Number of times _obj's motion can be redirected in a single call. (1: _obj can only redirect off 
	of one surface at a time and additional surfaces will block the motion; >1: _obj can redirect off of multiple surfaces 
	at a time).
*/
// CORE LOADER
function updateObjCollisions(_obj, ref _colCon, _comPos)
return updateObjCollisions(_obj, _colCon, _comPos, _colCon.fwd, _colCon.up, _colCon.scale, _colCon.collisionMode, false, false, true, false, 0, false, deltaTime())

function updateObjCollisions(_obj, ref _colCon, _comPos, _fwd)
return updateObjCollisions(_obj, _colCon, _comPos, _fwd, _colCon.up, _colCon.scale, _colCon.collisionMode, false, false, true, false, 0, false, deltaTime())

function updateObjCollisions(_obj, ref _colCon, _comPos, _fwd, _up)
return updateObjCollisions(_obj, _colCon, _comPos, _fwd, _up, _colCon.scale, _colCon.collisionMode, false, false, true, false, 0, false, deltaTime())

function updateObjCollisions(_obj, ref _colCon, _comPos, _fwd, _up, _scale)
return updateObjCollisions(_obj, _colCon, _comPos, _fwd, _up, _scale, _colCon.collisionMode, false, false, true, false, 0, false, deltaTime())

function updateObjCollisions(_obj, ref _colCon, _comPos, _fwd, _up, _scale, _collisionMode)
return updateObjCollisions(_obj, _colCon, _comPos, _fwd, _up, _scale, _collisionMode, false, false, true, false, 0, false, deltaTime())

function updateObjCollisions(_obj, ref _colCon, _comPos, _fwd, _up, _scale, _collisionMode, _forceUpdate)
return updateObjCollisions(_obj, _colCon, _comPos, _fwd, _up, _scale, _collisionMode, _forceUpdate, false, true, false, 0, false, deltaTime())

function updateObjCollisions(_obj, ref _colCon, _addVel, _fwd, _up, _scale, _collisionMode, _forceUpdate, _getAllCollisions, _handleTransformChange, _getNormal, _normRecurLimit, _useGrav, _delta)
	var prevComPos = _colCon.comPos
	var prevScale = _colCon.scale
	var prevFwd = _colCon.fwd
	var prevUp = _colCon.up
	var prevCell = _colCon.cell
	var prevCellPos = _colCon.cellPos
	
	var eqRes = _delta * length(_colCon.grav)
	var checkCol = true
	
	// TODO: Rot speed needs to be multiplied by _delta
	_fwd = getNewColFwd(_colCon, _delta)
	_up = getNewColUp(_colCon, _delta)
	
	var comPos
	// On recursions, _addVel represents a new absolute position rather than a velocity addition
	if _normRecurLimit > 0 then
		_colCon.vel += _addVel
		comPos = _colCon.comPos + _colCon.vel * _delta
	else
		comPos = _addVel
	endif
	
	if _useGrav and _normRecurLimit > 0 then
		_colCon.vel = _colCon.vel + _colCon.grav * _delta
		comPos = _colCon.comPos + _colCon.vel * _delta
	endif
	
	var prevOrig = getOriginFromCom(prevComPos, _colCon.centerOfMass, prevFwd, prevUp, prevScale)
	var orig = getOriginFromCom(comPos, _colCon.centerOfMass, _fwd, _up, _scale)
	
	// Short-circuit collision check if nothing has changed from the previous collision
	if _normRecurLimit > 0
			and length(_colCon.vel) <= eqRes 
			and (_colCon.colThisFrame or _colCon.deflectThisFrame)
			and _collisionMode >= 3 
			and !_forceUpdate 
			and equals(comPos, _colCon.colPos, eqRes)
			and equals(_fwd, _colCon.colFwd, eqRes)
			and equals(_up, _colCon.colUp, eqRes)
			and _scale == _colCon.colScale
			then
		_colCon.colThisFrame = true
		checkCol = false
		
		if _useGrav then
			_colCon.vel = {0, 0, 0}
		endif
	endif
	
	_colCon.deflectThisFrame = false
	
	if checkCol then
		if _handleTransformChange then
			if orig != prevOrig then
				setObjectPos(_obj, orig)
			endif
			
			if _fwd != prevFwd or _up != prevUp then
				setObjRot(_obj, orig, _fwd, _up)
			endif
			
			if _scale != _colCon.scale then
				setObjectScale(_obj, _scale)
			endif
		endif
		
		if _forceUpdate then
			_colCon.objList = []
		endif
		
		var cellResult
		var center = getExtCenter(_colCon.ext) * _scale
		center = changeVecSpaceZFwd(center, _fwd, _up, safeCross(_fwd, _up), {0, 0, 0})
		var prevCenter = getExtCenter(_colCon.ext) * _colCon.scale
		prevCenter = changeVecSpaceZFwd(prevCenter, prevFwd, prevUp, safeCross(prevFwd, prevUp), {0, 0, 0})
		var objMaxDim = distance(_colCon.ext.lo * _colCon.scale, prevCenter)
		var objMinDim = getMinDim(_colCon.ext, _scale)
		
		// Use aux collider only if object is moving fast enough to potentially clip through obstacles
		if _collisionMode <= 1 or distance(prevOrig + prevCenter, orig + center) <= objMinDim then
			var timer = time()
			cellResult = updateCellContext(_colCon.cell, _colCon.cellPos, orig, false, true)
			
			updateColContext(_colCon, cellResult.cell, orig, _fwd, _up, 
				_colCon.ext, _scale, _obj, _getAllCollisions, _collisionMode, prevOrig, _getNormal, [], [])
			
			_colCon.fwd = _fwd
			_colCon.up = _up
		else // Use aux collider
			var timer = time()
			var lineDir = safeNormalize((orig + center) - (prevOrig + prevCenter))
			
			if lineDir == {0, 0, 0} then
				lineDir = _fwd
			endif
			
			var linePos = ((orig + center + lineDir * objMaxDim) + (prevOrig + prevCenter)) / 2
			var lineScale = {objMaxDim, objMaxDim, distance(prevOrig + prevCenter, orig + center + lineDir * objMaxDim) / 2}
			var rotAxis = safeCross({0, 0, 1}, lineDir)
			
			if rotAxis == {0, 0, 0} then
				rotAxis = {0, 1, 0}
			endif
			
			var lineUp = axisRotVecBy({0, 1, 0}, rotAxis, getAngleBetweenVecs({0, 0, 1}, lineDir))
			
			setObjectPos(_colCon.auxCollider, linePos)
			setObjectScale(_colCon.auxCollider, lineScale)
			setObjRot(_colCon.auxCollider, linePos, lineDir, lineUp)
			
			/* Run basic collison check for the aux collider, which covers all the space the object has moved through  
			since the previous frame, and then use its results as the collision pool for a complex collison check using 
			the actual object. This ensures that objects not close enough to the object's old and new positions to be 
			seen by a normal collision check will still be included. */
			//var auxCon = initColContext(_colCon.auxColCon, _colCon.auxCollider, linePos, lineDir, lineUp, lineScale, 1, 0, {0, 0, 0}, 0.05, false, false, false)
			
			var auxCon = _colCon.auxColCon
			
			cellResult = updateCellContext(auxCon.cell, auxCon.cellPos, linePos, false, _forceUpdate)
			
			updateColContext(auxCon, cellResult.cell, linePos, lineDir, lineUp, 
				auxCon.ext, lineScale, _colCon.auxCollider, true, auxCon.collisionMode, prevOrig + prevCenter, false, [], [])
			_colCon.auxColCon = auxCon
			
			cellResult = updateCellContext(_colCon.cell, _colCon.cellPos, orig, false, _forceUpdate)
			updateColContext(_colCon, cellResult.cell, orig, _fwd, _up, 
				_colCon.ext, _scale, _obj, _getAllCollisions, _collisionMode, prevOrig, _getNormal, auxCon.collision, auxCon.gridBit)
			
			_colCon.fwd = _fwd
			_colCon.up = _up
		endif
		
		_colCon.cellPos = cellResult.cellPos
		_colCon.cell = cellResult.cell
		
		if _normRecurLimit > 0 then
			_colCon.colPos = comPos
		endif
		
		_colCon.colScale = _scale
		_colCon.colFwd = _fwd
		_colCon.colUp = _up
		
		var resetFwdUp = true
		
		if _handleTransformChange and _colCon.colThisFrame then
			if len(_colCon.normal) and _getNormal and _normRecurLimit then
				var deflPos
				
				if len(_colCon.colDepth) then
					// Push object out of the surface it has collided with
					if _colCon.colDepth[0] < float_max and _colCon.normal[0] != {0, 0, 0} then
						deflPos = comPos + _colCon.normal[0] * _colCon.colDepth[0]
					else // Backup in case we couldn't find the surface normal/collision depth
						deflPos = comPos - _colCon.delta
					endif
				else
					deflPos = comPos - _colCon.delta
				endif
				
				// Bounce obj off surface and modify vel based on rotation
				if _useGrav then
					_colCon.vel = reflect(_colCon.vel, _colCon.normal[0]) / (_colCon.mass * 0.1 + 1)
					
					if _colCon.rotVelAxis != {0, 0, 0} then
						_colCon.vel = axisRotVecBy(_colCon.vel, _colCon.rotVelAxis, _colCon.rotVel / (_colCon.mass * 4))
					endif
					
					deflPos += (_colCon.vel + _colCon.grav * _delta) * _delta
					
					if _normRecurLimit > 0 and len(_colCon.normal) then
						if _colCon.normal[0] != {0, 0, 0} then
							var r = safeCross(_fwd, _up)
							
							var limit = 0.99
							if (_colCon.normAxis == "fwd" and abs(dot(_fwd, _colCon.normal[0])) < limit) 
									or (_colCon.normAxis == "up" and abs(dot(_up, _colCon.normal[0])) < limit) 
									or (r != {0, 0, 0} and _colCon.normAxis == "r" and abs(dot(r, _colCon.normal[0])) < limit) 
									or length(_colCon.vel) > length(_colCon.grav) * 4 then
								resetFwdUp = false
							else
								_colCon.rotVel = 0
								var normAxis
								
								if _colCon.normAxis == "fwd" and abs(dot(_fwd, _colCon.normal[0])) >= limit then
									normAxis = _fwd * getSign(dot(_fwd, _colCon.normal[0]))
								else if _colCon.normAxis == "up" and abs(dot(_up, _colCon.normal[0])) >= limit then
									normAxis = _up * getSign(dot(_up, _colCon.normal[0]))
								else
									normAxis = r * getSign(dot(r, _colCon.normal[0]))
								endif endif
								
								var deg = getAngleBetweenVecs(normAxis, _colCon.normal[0])
								var axis = safeCross(normAxis, _colCon.normal[0])
								
								if axis != {0, 0, 0} then
									_fwd = axisRotVecBy(_fwd, axis, deg)
									_up = axisRotVecBy(_up, axis, deg)
								endif
							endif
						endif
					endif
				endif
				
				/* To avoid looping through redundant positions, only continue if the deflected position isn't the same as 
				the position the object started in. */
				if length(prevComPos - deflPos) > eqRes or length(_fwd - _colCon.fwd) > eqRes or length(_up - _colCon.up) > eqRes then
					_colCon.comPos = prevComPos
					_colCon.scale = prevScale
					
					if resetFwdUp then
						_colCon.fwd = prevFwd
						_colCon.up = prevUp
					endif
					
					var argColCon = _colCon
					
					updateObjCollisions(_obj, argColCon, deflPos, _fwd, _up, _scale, _collisionMode, _forceUpdate, 
						_getAllCollisions, _handleTransformChange, _getNormal, abs(_normRecurLimit) * -1 + 1, false, _delta)
					_colCon = argColCon
					
					if !_colCon.colThisFrame then
						_colCon.deflectThisFrame = true
					endif
				endif
				
				if _colCon.colThisFrame then
					if _handleTransformChange then
						if _scale != _colCon.scale then
							setObjectScale(_obj, prevScale)
						endif
						
						if _fwd != prevFwd or _up != prevUp then
							setObjRot(_obj, orig, prevFwd, prevUp)
						endif
						
						if orig != prevOrig then
							setObjectPos(_obj, prevOrig)
						endif
					endif
				endif
			endif
		else
			_colCon.comPos = comPos
			_colCon.scale = _scale
			_colCon.fwd = _fwd
			_colCon.up = _up
		endif
	endif
return _colCon

/* Recalculates collision bits and finds current collisions. 
_collisionMode can be 1 (bounding box), 2 (single raycast), 3 (cuboid raycasts), 
or 4 (spheroid raycasts) */
// CORE LOADER
function updateColContext(ref _colCon, _cell, _pos, _fwd, _up, _ext, _scale, _collider, _getAllCollisions, _collisionMode, _prevPos, _getNormal, _colOverride, _gridBitOverride)
	var timer = time()
	_colCon.collision = []
	_colCon.normal = []
	_colCon.colDepth = []
	var cellPos = getCellPosFromPos(_pos)
	var gridPos = getGridIdxFromPosInCell(_pos, cellPos, true)
	var oldGridBit = _colCon.gridBit
	_colCon.gridBit = getExtCollisionBitsFast(
		_pos,
		_ext, 
		_scale, 
		_fwd, 
		_up
	)
	_colCon.colThisFrame = false
	var usedCached = false
		
	if len(_colOverride) then
		_colCon.collision = _colOverride
	endif
	
	if len(_gridBitOverride) then
		_colCon.gridBit = _gridBitOverride
	endif
	
	// Reuse collison pool if object hasn't moved enough to recalculate gridBit
	if !len(_colOverride) and _cell == _colCon.cell and len(_colCon.objList) 
			and oldGridBit[13][0] == _colCon.gridBit[13][0]
			and oldGridBit[13][1] == _colCon.gridBit[13][1] then
		usedCached = true
		getColPoolFromCache(_colCon, _collider)
	endif
	
	// Get new collision data pool if current pool is ineligible for reuse
	if  !len(_colOverride) and !usedCached then
		getColPool(_colCon, _cell, _pos, _collider)
	endif
	
	if _collisionMode >= 3 and len(_colCon.collision) then
		resolveComplexRaycastCollision(_colCon, _cell, _pos, _fwd, _up, _ext, _scale, _getAllCollisions, 
			_collisionMode, _prevPos, _getNormal, _gridBitOverride)
	else if _collisionMode == 2 and len(_colCon.collision) then
		resolveSimpleRaycastCollision(_colCon, _pos, _fwd, _up, _ext, _scale, _prevPos)
	endif endif
	
	_colCon.allCollisions = _getAllCollisions
return _colCon

/* Regenerate object list and find bounding box collisions. */
// CORE LOADER
function getColPool(ref _colCon, _cell, _pos, _collider)
	_colCon.cell = _cell
	_colCon.objList = []
	
	var h
	var i
	var curCell
	var obj
	var objGridBit
	var hit
	var curAdj = getAdj(_cell, _pos)
	
	for h = 0 to len(curAdj) loop
		curCell = curAdj[h]
		
		if curCell >= 0 and (_colCon.gridBit[h][0]
				or _colCon.gridBit[h][1]) then
			for i = g_cellObjStart to len(g_cell[curCell]) loop
				obj = getMapObjFromRef(g_cell[curCell][i])
				getObjGridBitForCell(objGridBit, obj, curCell)
				
				if _colCon.gridBit[h][0] & objGridBit[0]
						or _colCon.gridBit[h][1] & objGridBit[1] then
					hit = mergedObjIntersect(obj, _collider, false)
					
					if hit then
						_colCon.objList = insert(_colCon.objList, [ .cell = curCell, .idx = i, .adj = h ], 0)
						_colCon.collision = push(_colCon.collision, [ .cell = curCell, .idx = i, .adj = h ])
						_colCon.normal = push(_colCon.normal, {0, 0, 0})
						_colCon.colThisFrame = true
					else
						_colCon.objList = push(_colCon.objList, [ .cell = curCell, .idx = i, .adj = h ])
					endif
				endif
			repeat
		endif
	repeat
return _colCon

/* Find bounding box collisions from an existing object list. */
// CORE LOADER
function getColPoolFromCache(ref _colCon, _collider)
	var i
	var obj
	var hit
	
	for i = 0 to len(_colCon.objList) loop
		obj = getMapObjFromRef(g_cell[_colCon.objList[i].cell][_colCon.objList[i].idx])
		hit = mergedObjIntersect(obj, _collider, false)
		
		if hit then
			_colCon.collision = push(_colCon.collision, _colCon.objList[i])
			_colCon.normal = push(_colCon.normal, {0, 0, 0})
			_colCon.colThisFrame = true
			
			if i > 0 then
				_colCon.objList = insert(_colCon.objList, _colCon.objList[i], 0)
				_colCon.objList = remove(_colCon.objList, i + 1)
			endif
		endif
	repeat
return _colCon

/* Find current and previous data about object's collision boundaries and direction. */
// CORE LOADER
function getRaycastColPoints(_ext, _pos, _fwd, _up, _scale, _prevPos, _prevFwd, _prevUp, _prevScale)
	var castPoint = getExtPoints(_ext, _scale, _fwd, _up)
	var center = (castPoint[0] + castPoint[1] + castPoint[2] + castPoint[3] 
		+ castPoint[4] + castPoint[5] + castPoint[6] + castPoint[7]) / 8
	
	var prevCastPoint = getExtPoints(_ext, _prevScale, _prevFwd, _prevUp)
	var prevCenter = (prevCastPoint[0] + prevCastPoint[1] + prevCastPoint[2] 
		+ prevCastPoint[3] + prevCastPoint[4] + prevCastPoint[5] + prevCastPoint[6] 
		+ prevCastPoint[7]) / 8
	
	var delta = (center + _pos) - (prevCenter + _prevPos) 
	var dir = safeNormalize(delta)
	
	var result = [
		.castPoint = castPoint,
		.prevCastPoint = prevCastPoint,
		.center = center,
		.prevCenter = prevCenter,
		.delta = delta,
		.dir = dir
	]
return result

/* Get collision results using a simple raycast algorithm that uses one cast from the object
center in the direction of object movement. */
// CORE LOADER
function resolveSimpleRaycastCollision(ref _colCon, _pos, _fwd, _up, _ext, _scale, _prevPos)
	var colPool = _colCon.collision
	
	_colCon.collision = []
	_colCon.normal = []
	_colCon.colDepth = []
	_colCon.colThisFrame = false
	_colCon.colDat = []
	
	var pointResult = getRaycastColPoints(_ext, _pos, _fwd, _up, _scale, _prevPos, _colCon.fwd, 
		_colCon.up, _colCon.scale)
	
	_colCon.delta = pointResult.delta
	var dir = pointResult.dir
	var castObj
	var cast
	var maxDim = getMaxDim(_ext, _scale) / 2
	
	if length(_colCon.delta) then
		for i = 0 to len(colPool) loop
			castObj = getMapObjFromRef(g_cell[colPool[i].cell][colPool[i].idx])
			raycastGrp(cast, castObj, colPool[i].cell, _prevPos, dir, colPool[i].adj,
				false, float_max)
			cast = cast.hit
			
			if cast <= maxDim then
				_colCon.collision = [ colPool[i] ]
				_colCon.colThisFrame = true
				_colCon.normal = [ {0, 0, 0} ]
				_colCon.colDepth = [ float_max ]
				
				break
			endif
		repeat
	endif
return _colCon


/* Get collision results using a complex raycast algorithm that checks a polygon made of raycasts,
finds collision depth and normal, and calculates target rotation. */
// CORE LOADER
function resolveComplexRaycastCollision(ref _colCon, _cell, _pos, _fwd, _up, _ext, _scale, _getAllCollisions, 
		_collisionMode, _prevPos, _getNormal, _gridBitOverride)
	var colPool = _colCon.collision
	
	_colCon.collision = []
	_colCon.normal = []
	_colCon.colDepth = []
	_colCon.colThisFrame = false
	_colCon.colDat = []
	
	var pointResult = getRaycastColPoints(_ext, _pos, _fwd, _up, _scale, _prevPos, _colCon.fwd, 
		_colCon.up, _colCon.scale)
	
	var castPoint = pointResult.castPoint
	var prevCastPoint = pointResult.prevCastPoint
	var center = pointResult.center
	var prevCenter = pointResult.prevCenter
	_colCon.delta = pointResult.delta
	var dir = pointResult.dir
	
	timer = time()
	var prevCastDat = getCollisionCastDat(_collisionMode, _prevPos, _colCon.fwd, _colCon.up, 
		_colCon.scale, _ext, prevCastPoint, prevCenter, _prevPos - (_pos - _prevPos))
	var castObj
	var cast
	var castDat = getCollisionCastDat(_collisionMode, _pos, _fwd, _up, _scale, _ext, castPoint, center, _prevPos)
	var castOrder = [ 3, 4, 5, 6, 0, 1, 2, 7, 8, 9 ]
	
	var castResult
	complexRaycast(castResult, _colCon, colPool, castDat, prevCastDat, castOrder, _getAllCollisions, _gridBitOverride)
	var closestCol = castResult.bestCol
	_colCon = castResult.colCon
				
	if _getNormal and closestCol.cast < float_max then
		_colCon.delta = closestCol.castDat[0] - prevCastDat[closestCol.castDatIdx][0]
		dir = safeNormalize(_colCon.delta)
		castObj = getMapObjFromRef(g_cell[closestCol.obj.cell][closestCol.obj.idx])
		var castHit = closestCol.castDat[0] + closestCol.cast * closestCol.castDat[1]
		_colCon.colDat = closestCol
		var normCastPos
		
		if closestCol.cast <= closestCol.castDat[2] / 2 or closestCol.castDatIdx >= 7 then
			normCastPos = castHit - closestCol.castDat[0] + prevCastDat[closestCol.castDatIdx][0]
			_colCon.colDat.invCastDir = false
		else
			var invCastStart = closestCol.castDat[0] + closestCol.castDat[1] * closestCol.castDat[2]
			var prevInvCastStart = prevCastDat[closestCol.castDatIdx][0] + prevCastDat[closestCol.castDatIdx][1] 
				* prevCastDat[closestCol.castDatIdx][2]
			normCastPos = castHit - invCastStart + prevInvCastStart
			dir = safeNormalize(invCastStart - prevInvCastStart)
			_colCon.delta = invCastStart - prevInvCastStart
			_colCon.colDat.invCastDir = true
		endif
		
		var rotAxis = safeCross({0, 0, 1}, dir)
		
		if rotAxis == {0, 0, 0} then
			rotAxis = {0, 1, 0}
		endif
		
		var normCastUp = axisRotVecBy({0, 1, 0}, rotAxis, getAngleBetweenVecs({0, 0, 1}, dir))
		var normCast
		var colPoolCell = -1
		var safeFloorCheck = true
		
		if safeFloorCheck then
			var floorResult
			raycastSafeFloor(floorResult, _colCon, colPool, dir, normCastPos, closestCol.obj.adj)
			normCast = floorResult.normCast
			
			if floorResult.colPoolCell >= 0 then
				colPoolCell = floorResult.colPoolCell
			else
				colPoolCell = closestCol.obj.cell
			endif
		else
			colPoolCell = closestCol.obj.cell
			var curObj = getMapObjFromRef(g_cell[closestCol.obj.cell][closestCol.obj.idx])
			raycastGrp(normCast, curObj, colPoolCell, normCastPos, 
				dir, closestCol.obj.adj, true, float_max)
			normCast = normCast.hit
		endif
		
		//debugLine(normCastPos, castPoint, 0.005, 5, blue)
		var norm
		var normCastHit
		
		_colCon.dir = dir
		
		if normCast >= float_max then
			getNormal(norm, castObj, closestCol.obj.cell, _colCon, 0.00001, normCastPos, prevCastDat[closestCol.castDatIdx][0] + prevCastDat[closestCol.castDatIdx][1], 
				dir, normCastUp, closestCol.obj.adj)
			//debugLine(closestCol.castDat[0], closestCol.castDat[0] + closestCol.castDat[1] * closestCol.castDat[2], 0.005, 5, lime)
			_colCon.colDepth = push(_colCon.colDepth, float_max)
		else
			normCastHit = normCastPos + dir * normCast
			
			getNormal(norm, castObj, colPoolCell, _colCon, 0.00001, normCastPos, normCastHit, 
				dir, normCastUp, closestCol.obj.adj)
			
			var depthStart
			if _colCon.colDat.invCastDir then
				depthStart = closestCol.castDat[0] + closestCol.castDat[1] * closestCol.castDat[2]
			else
				depthStart = closestCol.castDat[0]
			endif
			
			var depthProj = projectVecToPlane(depthStart, normCastHit, norm)
			var overage = 0.01 // Add a small amount to ensure the depth clears the collision surface
			var pointDepth = distance(depthStart, depthProj) + overage
			_colCon.colDepth = push(_colCon.colDepth, pointDepth)
		endif
		
		setTargetFaceForColRot(_colCon, norm, _fwd, _up)
		
		//debugLine(castHit, castHit + norm * 0.25, 0.005, 5, orange)
		_colCon.normal = push(_colCon.normal, norm)
	else
		_colCon.normal = push(_colCon.normal, {0, 0, 0})
		_colCon.colDepth = push(_colCon.colDepth, float_max)
	endif
return _colCon

/* Sets a target face for the collision context's hitbox to rotate towards upon
collision. The face is selected based on how closely it matches the collision 
surface's normal and on how much of the object's surface area it occupies. */
// CORE LOADER
function setTargetFaceForColRot(ref _colCon, _norm, _fwd, _up)
	// Set preferred face for the object to land on and init rotaion axis
	if _norm != {0, 0, 0} then
		var fwdDif = dot(_fwd, _norm)
		var upDif = dot(_up, _norm)
		var r = safeCross(_fwd, _up)
		
		var rDif = dot(r, _norm)
		var mostAngledDir
		var offAxis
		
		var fwdLen = abs(_colCon.ext.hi.z - _colCon.ext.lo.z) * _colCon.scale.z
		var upLen = abs(_colCon.ext.hi.y - _colCon.ext.lo.y) * _colCon.scale.y
		var rLen = abs(_colCon.ext.hi.x - _colCon.ext.lo.x) * _colCon.scale.x
		var fwdArea = upLen * rLen
		var upArea = fwdLen * rLen
		var rArea = fwdLen * upLen
		
		var fwdScore = fwdArea / (fwdArea + upArea + rArea)
		var upScore = upArea / (fwdArea + upArea + rArea)
		var rScore = rArea / (fwdArea + upArea + rArea)
		
		if (abs(fwdDif) + fwdScore) > (abs(upDif) + upScore) and (abs(fwdDif) + fwdScore) > (abs(rDif) + rScore) then
			mostAngledDir = _fwd * getSign(fwdDif)
			offAxis = r * getSign(fwdDif)
			_colCon.normAxis = "fwd"
		else if (abs(upDif) + upScore) > (abs(fwdDif) + fwdScore) and (abs(upDif) + upScore) > (abs(rDif) + rScore) then
			mostAngledDir = _up * getSign(upDif)
			offAxis = r * getSign(upDif) * -1
			_colCon.normAxis = "up"
		else
			mostAngledDir = r * getSign(rDif)
			offAxis = _fwd * getSign(rDif)
			_colCon.normAxis = "r"
		endif endif
		
		var newRotAxis = safeCross(mostAngledDir, _norm)
		
		if newRotAxis != {0, 0, 0} then
			_colCon.rotVelAxis = newRotAxis
		else
			newRotAxis = offAxis
		endif
		
		var massScaler = lerp(2, 10, _colCon.mass / 100)
		var gravNorm
		
		if _colCon.grav != {0, 0, 0} then
			gravNorm = normalize(_colCon.grav)
		else
			gravNorm = {0, 0, 0}
		endif
		
		var lowLimit = (dot(_norm * -1, gravNorm) + 1) / 2
		
		if abs(dot(mostAngledDir, _norm)) > 0.5 and lowLimit > 0.9 and _colCon.rotVel > 0 then
			if _colCon.rotVel > 180 then
				_colCon.rotVel = max((length(_colCon.vel) * 200) / _colCon.mass, 240)
			else
				_colCon.rotVel = max((length(_colCon.vel) * 100) / _colCon.mass, 120)
			endif
		else if length(_colCon.vel) > 0.1 and length(_colCon.delta) > 0.1 then
			var velMod = abs(dot(_norm, safeNormalize(_colCon.vel)))
			_colCon.rotVel = (length(_colCon.vel) * 200) / _colCon.mass
		endif endif
	endif
return _colCon

/* Returns shape data for raycast collision detection. */
// CORE LOADER
function getCollisionCastDat(_type, _pos, _fwd, _up, _scale, _ext, _extPoints, _center, _prevPos)
	var r = safeCross(_fwd, _up)
	var zDir = _center + safeNormalize(_fwd) * abs(_ext.hi.z - _ext.lo.z) * 0.5 * _scale.z
	var xDir = _center + safeNormalize(r * -1) * abs(_ext.hi.x - _ext.lo.x) * 0.5  * _scale.x
	var yDir = _center + safeNormalize(_up) * abs(_ext.hi.y - _ext.lo.y) * 0.5  * _scale.y
	var castDat
	
	if _type == 3 then
		// Spheroid -- diagonal casts towards the extent corners are shorter vs. cuboid
		var avgDim = (distance(_extPoints[0], _extPoints[1]) / 2 + distance(_extPoints[0], _extPoints[2]) / 2 + distance(_extPoints[0], _extPoints[4]) / 2) / 3
		var point = [
			normalize(_extPoints[4] - _center),
			normalize(_extPoints[5] - _center),
			normalize(_extPoints[6] - _center),
			normalize(_extPoints[7] - _center),
			normalize(_extPoints[0] - _center)
		]
		castDat = [ // position, direction, distance
			[ _pos + yDir, normalize(yDir - _center) * -1, abs(_ext.hi.y - _ext.lo.y) * _scale.y ], 
			[ _pos + zDir, normalize(zDir - _center) * -1, abs(_ext.hi.z - _ext.lo.z) * _scale.z ], 
			[ _pos + xDir, normalize(xDir - _center) * -1, abs(_ext.hi.x - _ext.lo.x) * _scale.x ],
			[ _pos + point[0] * avgDim, point[0] * -1, avgDim * 2 ], 
			[ _pos + point[1] * avgDim, point[1] * -1, avgDim * 2 ], 
			[ _pos + point[2] * avgDim, point[2] * -1, avgDim * 2 ], 
			[ _pos + point[3] * avgDim, point[3] * -1, avgDim * 2 ],
			[ _prevPos + _center, normalize((_pos + _center) - (_prevPos + _center)), distance(_prevPos + _center, _pos + _center) ],
			[ _prevPos + _center, normalize((_pos + point[4] * avgDim) - (_prevPos + _center)), distance(_prevPos + _center, _pos + point[4] * avgDim) ],
			[ _prevPos + _center, normalize((_pos + point[3] * avgDim) - (_prevPos + _center)), distance(_prevPos + _center, _pos + point[3] * avgDim) ]
		]
	else
		// Cuboid
		var rad = distance(_center, _ext.hi * _scale)
		var crossDist = distance(_ext.lo * _scale, _ext.hi * _scale)
		
		castDat = [ // position, direction, distance
			[ _pos + yDir, normalize(yDir - _center) * -1, abs(_ext.hi.y - _ext.lo.y) * _scale.y ], 
			[ _pos + zDir, normalize(zDir - _center) * -1, abs(_ext.hi.z - _ext.lo.z) * _scale.z ], 
			[ _pos + xDir, normalize(xDir - _center) * -1, abs(_ext.hi.x - _ext.lo.x) * _scale.x ],
			[ _pos + _extPoints[4], normalize(_extPoints[4] - _center) * -1, crossDist ], 
			[ _pos + _extPoints[5], normalize(_extPoints[5] - _center) * -1, crossDist ], 
			[ _pos + _extPoints[6], normalize(_extPoints[6] - _center) * -1, crossDist ], 
			[ _pos + _extPoints[7], normalize(_extPoints[7] - _center) * -1, crossDist ],
			[ _prevPos + _center, normalize((_pos + _center) - (_prevPos + _center)), distance(_prevPos + _center, _pos + _center) ],
			[ _prevPos + _center, normalize((_pos + _extPoints[0]) - (_prevPos + _center)), distance(_prevPos + _center, _pos + _extPoints[0]) ],
			[ _prevPos + _center, normalize((_pos + _extPoints[7]) - (_prevPos + _center)), distance(_prevPos + _center, _pos + _extPoints[7]) ]
		]
	endif
	// Uncomment for collision shape debug
	/*var i
	for i = 0 to len(castDat) loop
		castDat[i][0] = castDat[i][0] + castDat[i][1] * 0.1
		castDat[i][2] -= 0.2
		debugLine(castDat[i][0], castDat[i][0] + castDat[i][1] * castDat[i][2], 0.01, 10, lime)
	repeat*/
return castDat

/* Checks for collisions based on cast shape defined by getCollisionCastDat(). */
// CORE LOADER
function complexRaycast(ref _in, _colCon, _colPool, _castDat, _prevCastDat, _castOrder, _getAllCollisions, _gridBitOverride)
	if !len(_gridBitOverride) then
		_gridBitOverride = _colCon.gridBit
	endif
	
	var bestCol = [ .obj = -1, .cast = float_max, .castDat = -1 ]
	var castObj
	var cast
	var i
	var j
	
	for i = 0 to len(_colPool) loop
		castObj = getMapObjFromRef(g_cell[_colPool[i].cell][_colPool[i].idx])
		
		for j = 0 to len(_castOrder) loop
			raycastGrp(cast, castObj, _colPool[i].cell, _castDat[_castOrder[j]][0], _castDat[_castOrder[j]][1], 
				_gridBitOverride[_colPool[i].adj], false, float_max)
			cast = cast.hit
			
			if cast <= _castDat[_castOrder[j]][2] then
				_colCon.collision = push(_colCon.collision, _colPool[i])
					_colCon.colThisFrame = true
				
				if bestCol.cast >= float_max or cast < bestCol.cast then
					bestCol = [ .obj = _colPool[i], .cast = cast, .castDat = _castDat[_castOrder[j]], .castDatIdx = _castOrder[j], .colPoolIdx = i, .invCastDir = false ]
				endif
				
				break
			endif
		repeat
					
		if !_getAllCollisions and len(_colCon.collision) then
			break
		endif
	repeat
	
	_in = [
		.colCon = _colCon,
		.bestCol = bestCol
	]
return _in

/* raycastSafeFloor will check normal-finding raycasts against all possible collision targets which
ensures any raycast that should be blocked by a nearby object will be blocked, returning the 
blocking surface's normal instead. The practical impact of this is that floor tiles will always 
return the correct upward normal instead of sometimes returning the non-upward normal from the 
tile's edge (because the edge is covered by the adjacent tiles which block the raycast). Using 
safeFloorCheck involves additional raycasts and hits the CPU, of course. */
// CORE LOADER
function raycastSafeFloor(ref _in, _colCon, _colPool, _dir, _normCastPos, _gridBitAdj)
	_in = [
		.normCast = float_max,
		.colPoolCell = -1
	]
	var curObj
	var newCast
	var i
	for i = 0 to len(_colPool) loop
		curObj = getMapObjFromRef(g_cell[_colPool[i].cell][_colPool[i].idx])
		raycastGrp(newCast, curObj, _colPool[i].cell, _normCastPos, 
			_dir, _colCon.gridBit[_gridBitAdj], true, float_max)
		newCast = newCast.hit
		
		if newCast < _in.normCast then
			_in.normCast = newCast
			_in.colPoolCell = _colPool[i].cell
		endif
	repeat
return _in

/* Finds collisions involving merged objects. */
// CORE LOADER
function mergedObjIntersect(_mergedObj, _obj)
return mergedObjIntersect(_mergedObj, _obj, false)

function mergedObjIntersect(_mergedObj, _obj, _hit)
	if !len(_mergedObj.children) then
		_hit = objectIntersect(_mergedObj.obj, _obj)
	else
		var i
		for i = 0 to len(_mergedObj.children) loop
			_hit = mergedObjIntersect(_mergedObj.children[i], _obj, _hit)
			
			if _hit then break endif
		repeat
	endif
return _hit

/* Performs a raycast that can hit any child within _obj. _gridBit is the
collision bit array of the casting object -- the cast will not be performed
if the caster's gridBit doesn't overlap _obj's gridBit. If _gridBit is not
given, it will be set so it always overlaps, making it irrelevant. If
_getAll is true, the nearest collision wil be returned; otherwise, the
first collision encountered will be returned. */
// CORE LOADER
function raycastGrp(ref _in, _obj, _cell, _pos, _dir)
return raycastGrp(_in, _obj, _cell, _pos, _dir, [])

function raycastGrp(ref _in, _obj, _cell, _pos, _dir, _gridBit)
return raycastGrp(_in, _obj, _cell, _pos, _dir, _gridBit, false, float_max)

function raycastGrp(ref _in, _obj, _cell, _pos, _dir, _gridBit, _getAll)
return raycastGrp(_in, _obj, _cell, _pos, _dir, _gridBit, _getAll, float_max)

function raycastGrp(ref _in, _obj, _cell, _pos, _dir, _gridBit, _getAll, _hit)
	_in = [
		.hit = _hit,
		.child = _obj
	]
	var abort = false
	var merged = len(_obj.children) or len(_obj.lights)
	
	// Categorically exclude lights. They have collision data but we can't collide with them.
	if !merged and !len(_gridBit) then
		_in.hit = raycastObject(_obj.obj, _pos, _dir)
		
		abort = true
	endif
	
	if !abort and !merged and len(_gridBit) then
		var objGridBit
		getObjGridBitForCell(objGridBit, _obj, _cell)
		
		if _gridBit[0] & objGridBit[0] 
				or _gridBit[1] & objGridBit[1] then
			_in.hit = raycastObject(_obj.obj, _pos, _dir)
		endif
		
		abort = true
	endif
	
	if !abort and (_getAll or _in.hit >= float_max) then
		var i
		var objGridBit
		
		for i = 0 to len(_obj.children) loop
			var gridMatch = false
			
			if !len(_gridBit) then
				gridMatch = true
			else
				getObjGridBitForCell(objGridBit, _obj.children[i], _cell)
				
				if objGridBit[0] & _gridBit[0] 
						or objGridBit[1] & _gridBit[1] then
					gridMatch = true
				endif
			endif
			
			if gridMatch then
				var castResult
				raycastGrp(castResult, _obj.children[i], _cell, _pos, _dir, _gridBit, _getAll, _in.hit)
				
				if castResult.hit < _in.hit then
					_in = castResult
				endif
				
				if !_getAll and _in.hit < float_max then
					break
				endif
			endif
		repeat
	endif
return _in

/* Gets a new target rotation for an object's forward vector by adding its current rotational 
velocity to its current forward direction. Typically, the output of this function should be passed 
to updateObjCollisions()'s _fwd input every frame to update a physics object. */
// CORE LOADER
function getNewColFwd(_colCon, _delta)
	var fwd = axisRotVecBy(_colCon.fwd, _colCon.rotVelAxis, _colCon.rotVel * _delta)
return fwd

/* Gets a new target rotation for an object's up vector by adding its current rotational velocity 
to its current up direction. Typically, the output of this function should be passed to updateObjCollisions()'s 
_up input every frame to update a physics object. */
// CORE LOADER
function getNewColUp(_colCon, _delta)
return axisRotVecBy(_colCon.up, _colCon.rotVelAxis, _colCon.rotVel * _delta)

	// ----------------------------------------------------------------
	// COLLISION BITS

/* Gets a binary representation of an object's collision box within a cell. 
The cell (5x5x5 dimensions) is divided into 125 units, with 0 at {0, 0, 0}
and 124 at {5, 5, 5} (incrementing x first, then y, then z). */
// CORE LOADER
function getObjCollisionBits(_obj, _objCell, _gridCellLen, _posOffset)
	var def
	getObjDef(def, _obj)
	var objExt = def.ext
	var cellHalfW = getCellWidth() / 2
	var cellBounds = [
		.lo = g_cell[_objCell][0] - cellHalfW,
		.hi = g_cell[_objCell][0] + cellHalfW
	]
	
	var bounds = getExtMinMax(objExt, _obj.scale, 
		_obj.fwd, _obj.up)
	_obj.pos += _posOffset
	bounds.lo = {
		max(bounds.lo.x + _obj.pos.x, cellBounds.lo.x),
		max(bounds.lo.y + _obj.pos.y, cellBounds.lo.y),
		max(bounds.lo.z + _obj.pos.z, cellBounds.lo.z)
	}
	bounds.hi = {
		min(bounds.hi.x + _obj.pos.x, cellBounds.hi.x),
		min(bounds.hi.y + _obj.pos.y, cellBounds.hi.y),
		min(bounds.hi.z + _obj.pos.z, cellBounds.hi.z)
	}
	bounds.lo = floorVec(bounds.lo) + 0.5
	bounds.hi = floorVec(bounds.hi) + 0.5
	
	var gridPosExt = [
		.lo = {-0.5, -0.5, -0.5},
		.hi = {0.5, 0.5, 0.5}
	]
	var dat
	array bitInt[bitLenToInt(_gridCellLen)]
	bitInt[0] = 0
	bitInt[1] = 0
		
	var gridCollider = placeObject(cube, g_cell[_objCell][0], {0.5, 0.5, 0.5})
	
	var z
	var y
	var x
	var isInter
	var intIdx
	
	for z = bounds.lo.z to bounds.hi.z + 1 loop
		for y = bounds.lo.y to bounds.hi.y + 1 loop
			for x = bounds.lo.x to bounds.hi.x + 1 loop
				/* Because of boundary collisions, we need to check that we're
				acually looking at a position in the cell. */
				if isPosInCell({x, y, z}, _objCell) then
					setObjectPos(gridCollider, {x, y, z})
					isInter = objectIntersect(_obj.obj, gridCollider)
					
					if isInter then
						gridIdx = getGridIdxFromPosInCell({x, y, z}, g_cell[_objCell][0], false)
						
						if gridIdx < _gridCellLen then
							intIdx = floor(gridIdx / g_intLen)
							bitInt[intIdx] = bitFieldInsert(bitInt[intIdx], gridIdx % g_intLen, 1, 1)
						else
							// DEBUG CONDITION: SHOULD NEVER OCCUR
							clear(black)
							ink(white)
							textSize(gheight() / 25)
							printAt(1, 1, "ERROR: gridIdx for getObjCollisionBits() is -1" + chr(10) + 
								"grid idx is " + gridIdx + chr(10) + 
								"cell is " + _objCell)
							update()
							sleep(1)
						endif
					endif
				endif
			repeat
		repeat
	repeat
	
	removeObject(gridCollider)
return bitInt

/* Constructs collision bit data for an object and all its children within 
the bounds of the given cell. Each parent within the hierarchy has a 
gridBit comprised of the intersection of all of its children's gridBits. */
// CORE LOADER
function getGrpCollisionBits(_obj, _cell)
	var depth = 0
	var childIdx = 0
	var parents = []
	var curObj = _obj
	var appliedObj = _obj
	var cellFound
	var i
	var colBits
	var bitArr
	
	loop
		if len(curObj.children) and childIdx < len(curObj.children) then
			depth += 1
			
			if len(parents) then
				appliedObj = applyGrpTransform(curObj, parents[len(parents) - 1][2])
			else
				appliedObj = curObj
			endif
			
			parents = push(parents, [ curObj, childIdx, appliedObj ]) // [ parent, child index within parent, parent with applied transform ]
			curObj = curObj.children[childIdx]
			childIdx = 0
			
			appliedObj = applyGrpTransform(curObj, parents[len(parents) - 1][2])
		else
			cellFound = false
			
			for i = 0 to len(curObj.gridBitList) loop
				if curObj.gridBitList[i][0] == _cell then
					curObj.gridBitList[i][1] =
						bitOrLong(curObj.gridBitList[i][1], 
						getObjCollisionBits(appliedObj, _cell, g_cellBitLen, 0))
					cellFound = true
					
					break
				endif
			repeat
			
			// Create new grid bit entry if no existing entry was found to merge
			if !cellFound then
				colBits = getObjCollisionBits(appliedObj, _cell, g_cellBitLen, 0)
				bitArr = [ _cell, colBits ]
				curObj.gridBitList = push(curObj.gridBitList, bitArr)
			endif
			
			depth -= 1
			
			if depth >= 0 then
				parents[depth][0].children[parents[depth][1]] = curObj
				
				// Combine child's grid bits with parent's
				cellFound = false
				
				for i = 0 to len(parents[depth][0].gridBitList) loop
					if parents[depth][0].gridBitList[i][0] == _cell then
						parents[depth][0].gridBitList[i][1] =
							bitOrLong(parents[depth][0].gridBitList[i][1], 
							curObj.gridBitList[len(curObj.gridBitList) - 1][1])
						cellFound = true
						
						break
					endif
				repeat
				
				// Create new parent grid bit entry if no existing entry was found to merge
				if !cellFound then
					parents[depth][0].gridBitList =
						push(parents[depth][0].gridBitList, 
						curObj.gridBitList[len(curObj.gridBitList) - 1])
				endif
				
				curObj = parents[depth][0]
				appliedObj = parents[depth][2]
				childIdx = parents[depth][1] + 1
				parents = remove(parents, len(parents) - 1)
			endif
		endif
		
		if depth <= 0 and childIdx >= len(curObj.children) then break endif
	repeat
return curObj

/* Quickly finds an approximation of a collision box within a cell. Like
getObjCollisionBits() but faster and less accurate. */
// CORE LOADER
function getExtCollisionBitsFast(_pos, _ext, _scale, _fwd, _up)
	var cellW = getCellWidth()
	var cellW2 = pow(cellW, 2)
	var cellW3 = cellW2 * cellW
	var cellPos = getCellPosFromPos(_pos)
	var minMax = getExtMinMax(_ext, _scale, _fwd, _up)
	
	minMax.lo += _pos
	minMax.hi += _pos
	minMax.lo = roundVec(minMax.lo, 2)
	minMax.hi = roundVec(minMax.hi, 2)
	
	var loCellPos = getCellPosFromPos(minMax.lo)
	array cells[27][bitLenToInt(g_cellBitLen)]
	var offset = (loCellPos - cellPos) / cellW
	var adj = getAdjIdxFromOffset(offset)
	var firstBitPos = getGridIdxFromPosInCell(minMax.lo, 0, false)
	
	var xW = getAdjBitWidths(minMax.lo.x, minMax.hi.x, cellW, firstBitPos, 0)
	var yW = getAdjBitWidths(minMax.lo.y, minMax.hi.y, cellW, firstBitPos, 1)
	var zW = getAdjBitWidths(minMax.lo.z, minMax.hi.z, cellW, firstBitPos, 2)
	
	var x
	var y
	var z
	var adjIdx
	var i
	var j
	var xOffset
	var yOffset
	var zOffset
	
	for z = 0 to len(zW) loop
		for y = 0 to len(yW) loop
			for x = 0 to len(xW) loop
				adjIdx = adj + x + 3 * y + 9 * z
				
				if adjIdx >= 27 then break endif
				
				for i = 0 to yW[y] loop
					for j = 0 to zW[z] loop
						xOffset = (-firstBitPos % cellW) * max(0, x)
						/* Snap firstBitPos to its resolution (y: res unit = 5; z: res unit = 25), invert it, multiply 
						by the cell offset to position it, then add the number of res units determined by getAdjBitWidths() */
						yOffset = -cellW * floor((firstBitPos % cellW2) / cellW) * max(0, y) + i * cellW
						zOffset = -1 * cellW2 * floor((firstBitPos % cellW3) / cellW2) * max(0, z) + j * cellW2
						
						cells[adjIdx] = bitFieldSetLong(cells[adjIdx], 
							firstBitPos + xOffset + yOffset + zOffset,
							xW[x], 1)
					repeat
				repeat
			repeat
		repeat
	repeat
return cells
	
/* Gets a row of bits along a given axis, potentially spanning up to three cells,
that can be copied along other axes to fill out the binary collision box 
representation.

_axis: 0 = x, 1 = y, 2 = z */
// CORE LOADER
function getAdjBitWidths(_axisMin, _axisMax, _cellW, _firstBitPos, _axis)
	var bitFullW = ceil(_axisMax) - floor(_axisMin)
	var axisUnit = pow(_cellW, _axis)
	var maxAxisVal = _cellW * axisUnit
	var axisVal = _firstBitPos % (_cellW * axisUnit)
	
	array adjW[3]
	adjW[0] = min(ceil((maxAxisVal - axisVal) / axisUnit), bitFullW)
	adjW[1] = bitFullW - adjW[0]
	adjW[2] = 0
	
	if adjW[1] > _cellW then
		adjW[2] = adjW[1] - _cellW
		adjW[1] = _cellW
	endif
	
	// Trim cells that don't have bits
	if adjW[1] == 0 then
		adjW = [ adjW[0] ]
	else if adjW[2] == 0 then
		adjW = [ adjW[0], adjW[1] ]
	endif endif
return adjW

/* Finds the binary collision box bit index equivalent of a normal position. 
Assumes the position is within the cell indicated by _cellPos. */
// CORE LOADER
function getGridIdxFromPosInCell(_pos, _cellPos, _useCellPos)
	var cellW = getCellWidth()
	
	if !_useCellPos then
		_cellPos = getCellPosFromPos(_pos)
	endif
	
	_pos = floorVec(_pos - _cellPos + {cellW, cellW, cellW} * 0.5)
return _pos.x + _pos.y * cellW + _pos.z * cellW * cellW

/* Searches in an object's grid bit list and returns the data for a specific
cell.  */
// CORE LOADER
function getObjGridBitForCell(ref _in, _obj, _cell)
	array gridBit[bitLenToInt(g_cellBitLen)]
	_in = gridBit
	
	var i
	for i = 0 to len(_obj.gridBitList) loop
		if _obj.gridBitList[i][0] == _cell then
			_in = _obj.gridBitList[i][1]
			
			break
		endif
	repeat
return _in

// ----------------------------------------------------------------
// SYSTEM

/* This function is a wrapper for editor-only functions that is left blank in
the Core Loader, which allows non-editor calls where the target function 
doesn't exist to silently fail instead of throwing a FUZE error. */
// CORE LOADER
function edFunction(ref _in, _funcName, _argArr)
return _in

// ----------------------------------------------------------------
// DEBUG

/* General debug function for printing data to screen. */
function debug()
	// Title image overlay
	//setFont(loadImage("Fonts/GGBot_Bad_comic"))
	//drawTextEx("CHEESE, PLEASE", {gwidth() / 2 + gwidth() / 164, gheight() / 7 + gwidth() / 164}, 1.25, align_center, gwidth(), 0, {1, 1, 1}, gold)
	//drawTextEx("CHEESE, PLEASE", {gwidth() / 2, gheight() / 7}, 1.25, align_center, gwidth(), 0, {1, 1, 1}, yellow)
return void

