/*
* GUI TODO:
*
* paramameter:
*
*
* KONTROLLFUNKTIONEN:
*
* Preset Funktion --> Alle Einstellungen plus Zustand der Modulationsmatrix und location des Buffer Speichern
* und laden
* IN / OUT Routing --> über liste
*
* STRUKTUR:
*
*
*/

(
/*
* TODO:	make more flexible! (allow instances)
*			-> change structure so global objects like ~grnlrPar and ~grnlrSeq are no longer needed
*				by using loadRelative in a better way i.e. load INIT_GRNLR when everything else is set up so it can
*				use local scope (will updates to grnlrPar still work??)
*			-> scope doesn't work like that and isn't passed in loadRelative find some other way to do this maybe with an environment?
*
*			rewrite so ~grnlrSeq is incorperated into ~grnlrPar so that the whole state of the synthesizer can be more easily
*			stored and recalled via presets
*
* BUG: send doesn't work on first execution
*/

loadRelative("grnlr_synth.scd");

if(~send.isNil){ ~send = Bus.audio(s, 2) };
if(~grnlr_bus.isNil){ ~grnlr_bus = Bus.audio(s, 2) };
if(~grndl_bus.isNil){ ~grndl_bus = Bus.audio(s, 2) };

s.waitForBoot{
	var width = 880;
	var height = 440;

	var bSize 	= 28;
	var kSize 	= 40;

	var params = (
		offLeft: 10,
		offRight: width - 20,
	);
	var labelFont	= Font("Sans", 10, true);
	var path 		= "String";
	var win 			= Window.new("GRNLR", Rect(0, height, width, height), false, true, scroll: true);
	var synthView 	= View.new(win, Rect(10, 38, width - 20, height - 38));
	var seqView 	= View.new(win, Rect(10, 38, width, 1510)).visible_(false);

	var buf;

	~grnlrPar = (
		ampArr:			[0,1,1,0],
		timeArr:			[0.3,0.3,0.3],

		toggle:			0,
	);

	~grnlrSeq = (
		pos: 				0,
		rPos:				0,
		pitch:			0,
		rPitch:			0,
		amp: 				0,
		rAmp:				0,
		fill:				1,
		rFill:			0,
		dur:				1,
		rDur:				0,
	);


	//-------------------------- TOP SWITCHES --------------------------//
	{
		// all sequences
		var seqAll = Button.new(win, Rect(params.offRight - 65, 5, 40, bSize)).states_([
			[">", Color.black, Color.white],
			["#" , Color.black, Color.white]
		]).action_{|item|
			if(item.value > 0, {
				~grnlrSeq.button_pos.valueAction_(1);
				~grnlrSeq.button_rPos.valueAction_(1);
				~grnlrSeq.button_amp.valueAction_(1);
				~grnlrSeq.button_rAmp.valueAction_(1);
				~grnlrSeq.button_pitch.valueAction_(1);
				~grnlrSeq.button_rPitch.valueAction_(1);
				~grnlrSeq.button_fill.valueAction_(1);
				~grnlrSeq.button_rFill.valueAction_(1);
				~grnlrSeq.button_dur.valueAction_(1);
				~grnlrSeq.button_rDur.valueAction_(1);
			}, {
				~grnlrSeq.button_pos.valueAction_(0);
				~grnlrSeq.button_rPos.valueAction_(0);
				~grnlrSeq.button_amp.valueAction_(0);
				~grnlrSeq.button_rAmp.valueAction_(0);
				~grnlrSeq.button_pitch.valueAction_(0);
				~grnlrSeq.button_rPitch.valueAction_(0);
				~grnlrSeq.button_fill.valueAction_(0);
				~grnlrSeq.button_rFill.valueAction_(0);
				~grnlrSeq.button_dur.valueAction_(0);
				~grnlrSeq.button_rDur.valueAction_(0);
			});
		};

		var synth	= Button.new(win, Rect(params.offLeft, 5, 70, bSize)).states_([
			["Synth", Color.black, Color.white]
		]).action_({
			seqView.visible_(false);
			synthView.visible_(true);
		});
		var seq		= Button.new(win, Rect(params.offLeft + 75, 5, 70, bSize)).states_([
			["Sequencer", Color.black, Color.white]
		]).action_({
			synthView.visible_(false);
			seqView.visible_(true);
		});

		var tempo = EZNumber.new(win,
			Rect(params.offLeft + 140, 7, 94, 24), "Tempo: ", [40, 200, 'lin', 1, 120], {|item|
				TempoClock.default.tempo = item.value/120;
		}, 120, true, layout: 'horz', margin: 2@2);

		// on / off switch
		~grnlrPar.put(\toggle,
			Button.new(win, Rect(params.offRight - 15, 5, bSize, bSize)).states_([
				["Off", Color.black, Color.white],
				["On" , Color.black, Color.white]
		]));

	}.value;

	//-------------------------------------------------------------------//
	//-------------------------------------------------------------------//
	//-------------------------- SYNTH ----------------------------------//
	//-------------------------------------------------------------------//
	//-------------------------------------------------------------------//
	{


		var mainControlsView = UserView.new(synthView, Rect(0, 0, width - 20, height - 38));

		var yOffset = 110;
		var rowSize = 40;

		{
			var waveform = SoundFileView.new(mainControlsView, Rect(0, 0, params.offRight, 120));

			waveform.canReceiveDragHandler = { View.currentDrag.isString;};
			waveform.receiveDragHandler_{
				path = View.currentDrag.value; path.isString.postln;
				if(path.isString, {
					buf = Buffer.read(s, path);														// load dragged sample into buffer
					buf.postln;

					waveform.load(path);																	// load waveform into SoundFileView#
					~grnlrPar.put(\path, path);
					{ 0.1.wait; ~loadSynth.value(buf, ~grnlr_bus) }.fork(AppClock)			// build synthdef with buffer
				});
			};
			~grnlrPar.put(\waveform, waveform);
			~grnlrPar.put(\buffer, buf);

		}.value;

		// position
		{
			{
				var xOffset = 120;

				~grnlrPar.put(\pos, Slider.new(mainControlsView, Rect(0, 120, params.offRight, 18)));

				~grnlrPar.put(\rPos,
					EZNumber.new(mainControlsView,
						Rect(xOffset, rowSize * 3 + yOffset, kSize, kSize), "rPos",
						[0, 1, 3, 0, 0], layout: \line2));
				~grnlrPar.put(\posMod,
					EZNumber.new(mainControlsView,
						Rect(xOffset, rowSize * 4 + yOffset, kSize, kSize), "ePos",
						[0, 1, 'lin', 0, 1], layout: \line2));

				~grnlrPar.put(\rPosMod,
					EZNumber.new(mainControlsView,
						Rect(xOffset, rowSize * 5 + yOffset, kSize, kSize), "envR",
						[0, 1, 'lin', 0, 0], layout: \line2));

				~grnlrPar.put(\dir,
					EZKnob.new(mainControlsView,
						Rect(xOffset, rowSize + yOffset, kSize, kSize*2), "Dir",
						[-1, 1, 'lin', 0, 0]))

			}.value;
			// Pitch
			{
				var xOffset = 180;

				~grnlrPar.put(\pitch,
					EZNumber.new(mainControlsView,
						Rect(xOffset, rowSize * 2 + yOffset, kSize, kSize), "Pitch",
						[-24, 24, 'lin', 0.5, 0], layout: \line2));

				~grnlrPar.put(\rPitch, EZNumber.new(mainControlsView,
					Rect(xOffset, rowSize * 3 + yOffset, kSize, kSize), "rPitch",
					[0, 1, 4, 0, 0],layout: \line2));

				~grnlrPar.put(\pitchMod,
					EZNumber.new(mainControlsView,
						Rect(xOffset, rowSize * 4 + yOffset, kSize, kSize), "ePitch",
						[0, 48, 'lin', 0, 0], layout: \line2));

				~grnlrPar.put(\rPitchMod,
					EZNumber.new(mainControlsView,
						Rect(xOffset, rowSize * 5 + yOffset, kSize, kSize), "envR",
						[0, 1, 'lin', 0, 0], layout: \line2));

			}.value;

			// duration
			{
				~grnlrPar.put(\dur,
					EZKnob.new(mainControlsView,
						Rect(0, rowSize+yOffset, kSize, kSize*2), "Dur",
						[0.01, 2, 'exp', 0, 0.1]));

				~grnlrPar.put(\rDur, EZNumber.new(mainControlsView,
					Rect(0, rowSize * 3 + yOffset, kSize, kSize), "rDur",
					[0, 1, 'lin', 0, 0], layout: \line2));

				~grnlrPar.put(\durMod,
					EZNumber.new(mainControlsView,
						Rect(0, rowSize * 4 + yOffset, kSize, kSize), "eDur",
						[0, 1, 'lin', 0, 0],  layout: \line2));

				~grnlrPar.put(\rDurMod,
					EZNumber.new(mainControlsView,
						Rect(0, rowSize * 5 + yOffset, kSize, kSize), "rEnv",
						[0, 1, 'lin', 0, 0],  layout: \line2));

			}.value;


			// fill factor
			{
				var xOffset = 60;

				~grnlrPar.put(\fillFactor,
					EZKnob.new(mainControlsView,
						Rect(xOffset, rowSize + yOffset, kSize, kSize*2), "Fill",
						[0.1, 16, 'exp', 0, 1]));

				~grnlrPar.put(\rFill, EZNumber.new(mainControlsView,
					Rect(xOffset, rowSize * 3 + yOffset, kSize, kSize), "rFill",
					[0, 2, 'lin', 0, 0], layout: \line2));

				~grnlrPar.put(\fillMod, EZNumber.new(mainControlsView,
					Rect(xOffset, rowSize * 4 + yOffset, kSize, kSize), "eFill",
					[0, 1, 'lin', 0, 0], layout: \line2));

				~grnlrPar.put(\rFillMod,
					EZNumber.new(mainControlsView,
						Rect(xOffset, rowSize * 5 + yOffset, kSize, kSize), "rEnv",
						[0, 1, 'lin', 0, 0], layout: \line2));

			}.value;
			// grain window
			{
				var xOffset = 240;

				var curve = -2;
				var startEnv = Env.new([0, 1, 1, 0], [0.3, 0.3, 0.3], [curve, 1, curve*(-1)]);

				var t_env 	= StaticText.new(mainControlsView,
					Rect(xOffset, rowSize + yOffset - 2, 260, 20)).string_("Grain Window");

				var envView = EnvelopeView.new(mainControlsView,
					Rect(xOffset, rowSize + yOffset + 20, 260, 140)).keepHorizontalOrder_(true);

				~grnlrPar.put(\envCurve,
					EZNumber.new(mainControlsView,
						Rect(xOffset, rowSize * 5 + yOffset, kSize, kSize), "Curve",
						[6, -6, 'lin', 0, -2], {|item|
							curve = ~grnlrPar.envCurve;
							envView.curves = [item.value, 0, item.value.neg];
				}, layout: \line2));

				envView.setEnv(startEnv);
				envView.action_{|item|
					var arr = item.value;
					~grnlrPar.timeArr = [arr[0][1], (arr[0][2] - arr[0][1]), (arr[0][3] - arr[0][2])];
					~grnlrPar.ampArr = arr[1];
				};

			}.value;

			// filter
			{
				var xOffset = 520;

				~grnlrPar.put(\filtFreqLo,
					EZKnob.new(mainControlsView,
						Rect(xOffset, rowSize + yOffset, kSize+10, kSize*2), "freqLo",
						[20, 20000, 'exp', 1, 20000], labelWidth: 50));

				~grnlrPar.put(\filtFreqHi,
					EZKnob.new(mainControlsView,
						Rect(xOffset + 80, rowSize + yOffset, kSize+10, kSize*2),
						"freqHi", [20, 20000, 'exp', 1, 20], labelWidth: 50));

				~grnlrPar.put(\qLo,
					EZNumber.new(mainControlsView,
						Rect(xOffset, rowSize * 3 + yOffset, kSize, kSize), "qLo",
						[0.1, 1, 'lin', 0, 1], layout: \line2));

				~grnlrPar.put(\qHi,
					EZNumber.new(mainControlsView,
						Rect(xOffset + 80, rowSize * 3 + yOffset, kSize, kSize),
						"qHi", [0.1, 1, 'lin', 0, 1], layout: \line2));

			}.value;
		}.value;
		// master

		{
			var xOffset = 800;

			~grnlrPar.put(\vol,
				EZKnob.new(mainControlsView,
					Rect(xOffset, rowSize + yOffset, kSize, kSize*2), "vol",
					[0, 1, 3, 0, 1], true));

			~grnlrPar.put(\rAmp,
				EZNumber.new(mainControlsView,
					Rect(xOffset, rowSize * 3 + yOffset, kSize, kSize), "rVol",
					[0, 1, 'lin', 0, 0], layout: \line2));

			~grnlrPar.put(\ampMod,
				EZNumber.new(mainControlsView,
					Rect(xOffset, rowSize * 4 + yOffset, kSize, kSize), "eVol",
					[0, 1, -4, 0, 0], layout: \line2));

			~grnlrPar.put(\rAmpMod,
				EZNumber.new(mainControlsView,
					Rect(xOffset, rowSize * 5 + yOffset, kSize, kSize), "rEnv",
					[0, 1, 'lin', 0, 0], layout: \line2));

			~grnlrPar.put(\pan,
				EZKnob.new(mainControlsView,
					Rect(xOffset - 60, rowSize + yOffset, 50, 80), "pan",
					[-1, 1, 'lin', 0, 0], true));

			~grnlrPar.put(\send,
				EZKnob.new(mainControlsView,
					Rect(xOffset - 60, rowSize * 3 + yOffset, 50, 80), "send",
					[0, 1, 'lin', 0, 0], true));

			~grnlrPar.put(\delay,
				EZKnob.new(mainControlsView,
					Rect(xOffset - 60, rowSize * 5 + yOffset, 50, 80), "delay",
					[0, 1, 'lin', 0, 0], true));

		}.value;
	}.value;

	//-------------------------------------------------------------------//
	//-------------------------------------------------------------------//
	//-------------------------- SEQUENCER ------------------------------//
	//-------------------------------------------------------------------//
	//-------------------------------------------------------------------//

	{	/* TODO:
		*	A change in EnvLoop Length should reflect in the appearance of the grid
		*/
		var asEnv = { |envView, curve|
			var val, times, levels;
			val = envView.value;
			levels = val[1];
			times = 	Array.new;
			(val[0].size-1).do({|i|
				times=times.add(val[0][i+1] - val[0][i]);
			});
			Env.new(levels, times, curve);
		};

		// Function for generating sequencer GUIs
		var seqFunc = { |parent, name, tDef_name, par_name, position|

			var view = UserView.new(parent, Rect(position.x, position.y, 880, 120));

			var textPos = 720;
			var curvePos = 820;
			var stepsPos = 770;
			var envWidth = 710;

			var length	 = 4 * 24;
			var numSteps = 2;
			var curve	 = 0;
			var env 	 = Env.new(0 ! numSteps);

			var envView  = EnvelopeView.new(view, Rect(0,  0, envWidth, 120)).setEnv(env).keepHorizontalOrder_(true).action_({|item|
				env = asEnv.value(item, curve);
			}).gridOn_(true).grid_(0.0625@0.1);

			var text = StaticText.new(view, Rect(textPos, 0, 80, 20)).string_(name);

			var button 	= Button.new(view, Rect(textPos, 30, 80, 40)).states_([
				[">", Color.black, Color.white],
				["#" , Color.black, Color.white]
			]).action_{|item|
				if(item.value > 0){ Tdef(tDef_name).play(~clock) }{ Tdef(tDef_name).stop }
			};

			var cur	 = EZKnob.new(view, Rect(curvePos, 30, 40, 80), "Curve", [-12, 12, 'lin', 0, 0], {|item|
				curve = item.value;
				envView.curves = curve;
				env = asEnv.value(envView, curve);
			});

			var steps	= EZNumber.new(view, Rect(stepsPos,  70, 45, 40), "Steps", [2, 16, 'lin', 1, numSteps], {|item|
				var old = envView.value;
				var old_numSteps = numSteps;
				var new_amps, new_times;
				numSteps = item.value.floor;
				new_times = Array.fill(numSteps, {|i| 1});
				new_amps  = Array.fill(numSteps, {|i| old[1][i]});
				env = Env.new(new_amps, new_times, curve);
				envView.setEnv(env);

				env = asEnv.value(envView, curve);
			}, numSteps, layout: 'line2');

			var speed = EZNumber.new(view, Rect(textPos,  70, 45, 40), "Length", [0.25, 32, 'lin', 0.25, 4], {|item|
				length = item.value * 24;
			}, 4, layout: 'line2' );

			// make Button semi global
			~grnlrSeq.put(("button_" ++ par_name).asSymbol, button);

			Tdef(tDef_name, {
				var i = 0;
				loop{
					i = (i + 1) % length;
					~grnlrSeq.put(par_name, env.at(i.linlin(0, length, 0, env.duration)));
					(1/24).wait;
				}
			});
		};

		seqFunc.value(seqView, "pos", 	'seqPos',	 	'pos', 		Point(0,    0));
		seqFunc.value(seqView, "rPos", 	'seq_rPos',	 	'rPos', 		Point(0,  125));
		seqFunc.value(seqView, "amp", 	'seqAmp',	 	'amp', 		Point(0,  250));
		seqFunc.value(seqView, "rAmp", 	'seq_rAmp',	 	'rAmp', 		Point(0,  375));
		seqFunc.value(seqView, "pitch", 	'seqPitch',	 	'pitch', 	Point(0,  500));
		seqFunc.value(seqView, "rPitch", 'seq_rPitch',	'rPitch', 	Point(0,  625));
		seqFunc.value(seqView, "fill",	'seqFill',		'fill', 		Point(0,  750));
		seqFunc.value(seqView, "rFill",	'seq_rFill',	'rFill', 	Point(0,  875));
		seqFunc.value(seqView, "dur",		'seqDur',		'dur', 		Point(0, 1000));
		seqFunc.value(seqView, "rdur",	'seq_rDur',		'rDur', 		Point(0, 1125));

	}.value;

	Tdef(\grnlr, {
		var dur;
		dur = 1;
		loop{
			{
				dur = ~grnlrPar.dur.value * ( ~grnlrPar.rDur.value.rand + (1 - (~grnlrPar.rDur.value / 2)) );

				if(~grnlrPar.toggle.value > 0, {
					Synth(\grnlr, [
						\pos,        	~grnlrPar.pos.value + (~grnlrSeq.pos * ~grnlrPar.posMod.value),
						\trans,      	~grnlrPar.pitch.value + (~grnlrSeq.pitch * ~grnlrPar.pitchMod.value),
						\dir,        	[-1, 1].wchoose([~grnlrPar.dir.value.linlin(-1, 1, 1, 0), ~grnlrPar.dir.value.linlin(-1, 1, 0, 1)]),
						\vol,        	~grnlrPar.vol.value * (~grnlrSeq.amp.linlin(0, 1, ~grnlrPar.ampMod.value.linlin(0,1,1,0), 1)),
						\pan,        	~grnlrPar.pan.value,
						\send,       	~grnlrPar.send.value,
						\delay,			~grnlrPar.delay.value,

						\filtFreqLo, 	~grnlrPar.filtFreqLo.value,
						\filtFreqHi, 	~grnlrPar.filtFreqHi.value,
						\qLo,        	~grnlrPar.qLo.value,
						\qHi,        	~grnlrPar.qHi.value,

						\ampArr,			~grnlrPar.ampArr,
						\timeArr,		~grnlrPar.timeArr.normalizeSum,

						\envCurve,		~grnlrPar.envCurve.value,

						\rAmp,      	~grnlrPar.rAmp.value,
						\rPos,      	~grnlrPar.rPos.value,
						\rPitch,    	~grnlrPar.rPitch.value,
						\rFill,     	~grnlrPar.rFill.value,

						\fillFactor,	~grnlrPar.fillFactor.value + (~grnlrSeq.fill.value * ~grnlrPar.fillMod.value),
						\dur, 			dur
					]);

				});
			}.defer;
			dur.clip(0.01, 2).wait;
		};
	}).play;

	//-------------------------- CLEANUP --------------------------------//
	win.onClose_{
		Tdef(\grnlr).stop;
		Tdef(\seqPos).stop;
		Tdef(\seq_rPos).stop;
		Tdef(\seqAmp).stop;
		Tdef(\seq_rAmp).stop;
		Tdef(\seqPitch).stop;
		Tdef(\seq_rPitch).stop;
		Tdef(\seqFill).stop;
		Tdef(\seq_rFill).stop;
		Tdef(\seqDur).stop;
		Tdef(\seq_rDur).stop;

		~send.free;
		~send = nil;

		// here for sinesleeper live set
		~grnlr_bus.free;
		~grnlr_bus = nil;

		if(buf.notNil){ buf.free };
	};
	win.front;
}.value;
)
