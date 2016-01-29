(
/*
* TODO:	make more flexible! (allow instances)
*			-> change structure so global objects like ~grVar.grnlr and ~grnlrSeq are no longer needed
*				by using loadRelative in a better way i.e. load INIT_GRNLR when everything else is set up so it can
*				use local scope (will updates to grnlrPar still work??)
*			-> scope doesn't work like that and isn't passed in loadRelative find some other way to do this maybe with an environment?
*
*
*			finetune the parameter mappings
*
* ISSUE: Server Latency between Tdefs and Pdefs. Rewrite to have consitency
*/

loadRelative("grnlr_synth.scd");

if(~send.isNil){ ~send = Bus.audio(s, 2) };
if(~grnlr_bus.isNil){ ~grnlr_bus = Bus.audio(s, 2) };
if(~grndl_bus.isNil){ ~grndl_bus = Bus.audio(s, 2) };
if(~outBus.isNil){ ~outBus = Bus.audio(s, 2) };

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

	~grVar = (
		grnlr: (
			ampArr:			[0,1,1,0],
			timeArr:			[0.3,0.3,0.3],
			toggle:			0,
		),
	);

	//-------------------------- TOP SWITCHES --------------------------//
	{
		// all sequences
		var seqAll = Button.new(win, Rect(params.offRight - 65, 5, 40, bSize)).states_([
			[">", Color.black, Color.white],
			["#" , Color.black, Color.white]
		]).action_{|item|
			if(item.value > 0){
				~grVar[\seqPos].button.valueAction_(1);
				~grVar[\seq_rPos].button.valueAction_(1);
				~grVar[\seqAmp].button.valueAction_(1);
				~grVar[\seq_rAmp].button.valueAction_(1);
				~grVar[\seqPitch].button.valueAction_(1);
				~grVar[\seq_rPitch].button.valueAction_(1);
				~grVar[\seqFill].button.valueAction_(1);
				~grVar[\seq_rFill].button.valueAction_(1);
				~grVar[\seqDur].button.valueAction_(1);
				~grVar[\seq_rDur].button.valueAction_(1);
			} {
				~grVar[\seqPos].button.valueAction_(0);
				~grVar[\seq_rPos].button.valueAction_(0);
				~grVar[\seqAmp].button.valueAction_(0);
				~grVar[\seq_rAmp].button.valueAction_(0);
				~grVar[\seqPitch].button.valueAction_(0);
				~grVar[\seq_rPitch].button.valueAction_(0);
				~grVar[\seqFill].button.valueAction_(0);
				~grVar[\seq_rFill].button.valueAction_(0);
				~grVar[\seqDur].button.valueAction_(0);
				~grVar[\seq_rDur].button.valueAction_(0);
			};
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
		/*
		var tempo = EZNumber.new(win,
			Rect(params.offLeft + 140, 7, 94, 24), "Tempo: ", [40, 200, 'lin', 1, 120], {|item|
				TempoClock.default.tempo = item.value/120;
		}, 120, true, layout: 'horz', margin: 2@2);
		*/
		// on / off switch
		~grVar.grnlr.put(\toggle,
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
					~grVar.grnlr.put(\path, path);
					{ 0.1.wait; ~loadSynth.value(buf, ~grnlr_bus) }.fork(AppClock)			// build synthdef with buffer
				});
			};
			~grVar.grnlr.put(\waveform, waveform);
			~grVar.grnlr.put(\buffer, buf);

		}.value;

		// position
		{
			{
				var xOffset = 120;

				~grVar.grnlr.put(\pos, Slider.new(mainControlsView, Rect(0, 120, params.offRight, 18)));

				~grVar.grnlr.put(\rPos,
					EZNumber.new(mainControlsView,
						Rect(xOffset, rowSize * 3 + yOffset, kSize, kSize), "rPos",
						[0, 1, 3, 0, 0], layout: \line2));
				~grVar.grnlr.put(\posMod,
					EZNumber.new(mainControlsView,
						Rect(xOffset, rowSize * 4 + yOffset, kSize, kSize), "ePos",
						[0, 1, 'lin', 0, 1], layout: \line2));

				~grVar.grnlr.put(\rPosMod,
					EZNumber.new(mainControlsView,
						Rect(xOffset, rowSize * 5 + yOffset, kSize, kSize), "envR",
						[0, 1, 'lin', 0, 0], layout: \line2));

				~grVar.grnlr.put(\dir,
					EZKnob.new(mainControlsView,
						Rect(xOffset, rowSize + yOffset, kSize, kSize*2), "Dir",
						[-1, 1, 'lin', 0, 0]))

			}.value;
			// Pitch
			{
				var xOffset = 180;

				~grVar.grnlr.put(\pitch,
					EZNumber.new(mainControlsView,
						Rect(xOffset, rowSize * 2 + yOffset, kSize, kSize), "Pitch",
						[-24, 24, 'lin', 0.5, 0], layout: \line2));

				~grVar.grnlr.put(\rPitch, EZNumber.new(mainControlsView,
					Rect(xOffset, rowSize * 3 + yOffset, kSize, kSize), "rPitch",
					[0, 1, 4, 0, 0],layout: \line2));

				~grVar.grnlr.put(\pitchMod,
					EZNumber.new(mainControlsView,
						Rect(xOffset, rowSize * 4 + yOffset, kSize, kSize), "ePitch",
						[0, 48, 'lin', 0, 0], layout: \line2));

				~grVar.grnlr.put(\rPitchMod,
					EZNumber.new(mainControlsView,
						Rect(xOffset, rowSize * 5 + yOffset, kSize, kSize), "envR",
						[0, 1, 'lin', 0, 0], layout: \line2));

			}.value;

			// duration
			{
				~grVar.grnlr.put(\dur,
					EZKnob.new(mainControlsView,
						Rect(0, rowSize+yOffset, kSize, kSize*2), "Dur",
						[0.01, 2, 'exp', 0, 0.1]));

				~grVar.grnlr.put(\rDur, EZNumber.new(mainControlsView,
					Rect(0, rowSize * 3 + yOffset, kSize, kSize), "rDur",
					[0, 1, 'lin', 0, 0], layout: \line2));

				~grVar.grnlr.put(\durMod,
					EZNumber.new(mainControlsView,
						Rect(0, rowSize * 4 + yOffset, kSize, kSize), "eDur",
						[0, 1, 'lin', 0, 0],  layout: \line2));

				~grVar.grnlr.put(\rDurMod,
					EZNumber.new(mainControlsView,
						Rect(0, rowSize * 5 + yOffset, kSize, kSize), "rEnv",
						[0, 1, 'lin', 0, 0],  layout: \line2));

			}.value;


			// fill factor
			{
				var xOffset = 60;

				~grVar.grnlr.put(\fillFactor,
					EZKnob.new(mainControlsView,
						Rect(xOffset, rowSize + yOffset, kSize, kSize*2), "Fill",
						[0.1, 16, 'exp', 0, 1]));

				~grVar.grnlr.put(\rFill, EZNumber.new(mainControlsView,
					Rect(xOffset, rowSize * 3 + yOffset, kSize, kSize), "rFill",
					[0, 2, 'lin', 0, 0], layout: \line2));

				~grVar.grnlr.put(\fillMod, EZNumber.new(mainControlsView,
					Rect(xOffset, rowSize * 4 + yOffset, kSize, kSize), "eFill",
					[0, 1, 'lin', 0, 0], layout: \line2));

				~grVar.grnlr.put(\rFillMod,
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

				~grVar.grnlr.put(\envCurve,
					EZNumber.new(mainControlsView,
						Rect(xOffset, rowSize * 5 + yOffset, kSize, kSize), "Curve",
						[6, -6, 'lin', 0, -2], {|item|
							curve = ~grVar.grnlr.envCurve;
							envView.curves = [item.value, 0, item.value.neg];
				}, layout: \line2));

				envView.setEnv(startEnv);
				envView.action_{|item|
					var arr = item.value;
					~grVar.grnlr.timeArr = [arr[0][1], (arr[0][2] - arr[0][1]), (arr[0][3] - arr[0][2])];
					~grVar.grnlr.ampArr = arr[1];
				};

			}.value;

			// filter
			{
				var xOffset = 520;

				~grVar.grnlr.put(\filtFreqLo,
					EZKnob.new(mainControlsView,
						Rect(xOffset, rowSize + yOffset, kSize+10, kSize*2), "freqLo",
						[20, 20000, 'exp', 1, 20000], labelWidth: 50));

				~grVar.grnlr.put(\filtFreqHi,
					EZKnob.new(mainControlsView,
						Rect(xOffset + 80, rowSize + yOffset, kSize+10, kSize*2),
						"freqHi", [20, 20000, 'exp', 1, 20], labelWidth: 50));

				~grVar.grnlr.put(\qLo,
					EZNumber.new(mainControlsView,
						Rect(xOffset, rowSize * 3 + yOffset, kSize, kSize), "qLo",
						[0.1, 1, 'lin', 0, 1], layout: \line2));

				~grVar.grnlr.put(\qHi,
					EZNumber.new(mainControlsView,
						Rect(xOffset + 80, rowSize * 3 + yOffset, kSize, kSize),
						"qHi", [0.1, 1, 'lin', 0, 1], layout: \line2));

			}.value;
		}.value;
		// master

		{
			var xOffset = 800;

			~grVar.grnlr.put(\vol,
				EZKnob.new(mainControlsView,
					Rect(xOffset, rowSize + yOffset, kSize, kSize*2), "vol",
					[0, 1, 3, 0, 1], true));

			~grVar.grnlr.put(\rAmp,
				EZNumber.new(mainControlsView,
					Rect(xOffset, rowSize * 3 + yOffset, kSize, kSize), "rVol",
					[0, 1, 'lin', 0, 0], layout: \line2));

			~grVar.grnlr.put(\ampMod,
				EZNumber.new(mainControlsView,
					Rect(xOffset, rowSize * 4 + yOffset, kSize, kSize), "eVol",
					[0, 1, -4, 0, 0], layout: \line2));

			~grVar.grnlr.put(\rAmpMod,
				EZNumber.new(mainControlsView,
					Rect(xOffset, rowSize * 5 + yOffset, kSize, kSize), "rEnv",
					[0, 1, 'lin', 0, 0], layout: \line2));

			~grVar.grnlr.put(\pan,
				EZKnob.new(mainControlsView,
					Rect(xOffset - 60, rowSize + yOffset, 50, 80), "pan",
					[-1, 1, 'lin', 0, 0], true));

			~grVar.grnlr.put(\send,
				EZKnob.new(mainControlsView,
					Rect(xOffset - 60, rowSize * 3 + yOffset, 50, 80), "send",
					[0, 1, 'lin', 0, 0], true));

			~grVar.grnlr.put(\delay,
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
		// TODO: refactor variables into dicts
		var seqFunc = { |parent, name, tDef_name, par_name, position|
			var view, textPos, curvePos, stepsPos, envWidth, text, button;
			var dict;

			dict = ();

			view = UserView.new(parent, Rect(position.x, position.y, 880, 120));

			textPos = 720;
			curvePos = 820;
			stepsPos = 770;
			envWidth = 710;

			text = StaticText.new(view, Rect(textPos, 0, 80, 20)).string_(name);

			dict.put(\button, Button.new(view, Rect(textPos, 30, 80, 40)).states_([
				[">", Color.black, Color.white],
				["#" , Color.black, Color.white]
			]).action_{|item|
				if(item.value > 0){ Tdef(tDef_name).play(~clock, quant: 1)}{ Tdef(tDef_name).stop }
			});

			dict.put(\curve, EZKnob.new(view,
				Rect(curvePos, 30, 40, 80), "Curve", [-12, 12, 'lin', 0, 0],
				{|item|
					dict[\envView].curves = item.value;
					dict[\env] = asEnv.value(dict[\envView], item.value);
			}));

			dict.put(\numSteps, EZNumber.new(view,
				Rect(stepsPos,  70, 45, 40), "Steps", [2, 16, 'lin', 1, 1],
				{|item|
					var old = dict[\envView].value;
					var old_numSteps = item.value;
					var new_amps, new_times;
					new_times = Array.fill(item.value, {|i| 1});
					new_amps  = Array.fill(item.value, {|i| old[1][i]});
					dict[\env] = Env.new(new_amps, new_times, dict.curve.value);
					dict[\envView].setEnv(dict[\env]);

					dict[\env] = asEnv.value(dict[\envView], dict.curve.value);
			}, 1, layout: 'line2'));

			dict.put(\length, EZNumber.new(view,
				Rect(textPos,  70, 45, 40), "Length", [0.25, 32, 'lin', 0.25, 4],
				{ |knob|
					if(Tdef(tDef_name).isPlaying){Tdef(tDef_name).play(~clock, quant: 1)}
				},
				initVal: 4, layout: 'line2' ));

			dict.put(\env, Env.new(0 ! dict.numSteps.value));

			dict.put(\envView, EnvelopeView.new( view,
				Rect(0,  0, envWidth, 120)).setEnv(dict.env).keepHorizontalOrder_(true).action_(
				{|item|
					dict.put(\env, asEnv.value(item, dict.curve.value));
			}).gridOn_(true).grid_(0.0625@0.1));

			dict.put(\val, 0);

			~grVar.put(tDef_name, dict);

			// doesn't this returning true mean that changes made on ~grVar[tDef_name] should reflect in dict???
			(~grVar[tDef_name] === dict).postln;

			// maybe solve timing issues with Pdef?
			Tdef(tDef_name, {
				var i = 0;
				var length, env;
				loop{
					//if(i == 0){ Synth(\ping); ~clock.beats.postln };
					length = ~grVar[tDef_name].length.value * 24;
					env = ~grVar[tDef_name].env;
					i = (i + 1) % length;
					~grVar[tDef_name].put(\val, env.at(i.linlin(0, length, 0, env.duration)));
					(1/24).wait;
				}
			});
		};

		seqFunc.value(seqView, "pos", 	'seqPos',	 	'pos', 		Point(0,    0));
		seqFunc.value(seqView, "amp", 	'seqAmp',	 	'amp', 		Point(0,  250));
		seqFunc.value(seqView, "pitch", 	'seqPitch',	 	'pitch', 	Point(0,  500));
		seqFunc.value(seqView, "fill",	'seqFill',		'fill', 		Point(0,  750));
		seqFunc.value(seqView, "dur",		'seqDur',		'dur', 		Point(0, 1000));
		seqFunc.value(seqView, "rPos", 	'seq_rPos',	 	'rPos', 		Point(0,  125));
		seqFunc.value(seqView, "rAmp", 	'seq_rAmp',	 	'rAmp', 		Point(0,  375));
		seqFunc.value(seqView, "rPitch", 'seq_rPitch',	'rPitch', 	Point(0,  625));
		seqFunc.value(seqView, "rFill",	'seq_rFill',	'rFill', 	Point(0,  875));
		seqFunc.value(seqView, "rdur",	'seq_rDur',		'rDur', 		Point(0, 1125));

	}.value;

	Tdef(\grnlr, {
		var dur;
		var pos, dir, trans;
		var vol, pan, send, delay;
		var filtFreqLo, filtFreqHi, qLo, qHi;
		var ampArr, timeArr, envCurve;
		var rAmp, rPos, rPitch, rFill;
		var fillFactor;

		dur = 1;
		loop{
			{
				if(~grVar.grnlr.toggle.value > 0){
					pos = ~grVar.grnlr.pos.value + (~grVar[\seqPos].val * ~grVar.grnlr.posMod.value);

					dir = ~grVar.grnlr.dir.value;
					dir = [-1, 1].wchoose([dir.linlin(-1, 1, 1, 0), dir.linlin(-1, 1, 0, 1)]);

					trans = ~grVar.grnlr.pitch.value + (~grVar[\seqPitch].val * ~grVar.grnlr.pitchMod.value);
					trans = trans + (~notes.choose - 60);

					vol = ~grVar.grnlr.vol.value * (~grVar[\seqAmp].val.linlin(0, 1, ~grVar.grnlr.ampMod.value.linlin(0,1,1,0), 1));
					pan = ~grVar.grnlr.pan.value;
					send = ~grVar.grnlr.send.value;
					delay = ~grVar.grnlr.delay.value;

					filtFreqLo = ~grVar.grnlr.filtFreqLo.value;
					filtFreqHi = ~grVar.grnlr.filtFreqHi.value;
					qLo = ~grVar.grnlr.qLo.value;
					qHi = ~grVar.grnlr.qHi.value;

					ampArr = ~grVar.grnlr.ampArr;
					timeArr = ~grVar.grnlr.timeArr.normalizeSum;
					envCurve = ~grVar.grnlr.envCurve.value;

					rAmp = ~grVar.grnlr.rAmp.value;
					rPos = ~grVar.grnlr.rPos.value;
					rPitch = ~grVar.grnlr.rPitch.value;
					rFill = ~grVar.grnlr.rFill.value;

					fillFactor = ~grVar.grnlr.fillFactor.value + (~grVar[\seqFill].val * ~grVar.grnlr.fillMod.value);

					dur = ~grVar.grnlr.dur.value * (~grVar.grnlr.rDur.value.rand + (1 - (~grVar.grnlr.rDur.value / 2)) );

					Synth(\grnlr, [
						\pos,        	pos,
						\trans,      	trans,
						\dir,        	dir,
						\vol,        	vol,
						\pan,        	pan,
						\send,       	send,
						\delay,			delay,

						\filtFreqLo, 	filtFreqLo,
						\filtFreqHi, 	filtFreqHi,
						\qLo,        	qLo,
						\qHi,        	qHi,

						\ampArr,			ampArr,
						\timeArr,		timeArr,
						\envCurve,		envCurve,

						\rAmp,      	rAmp,
						\rPos,      	rPos,
						\rPitch,    	rPitch,
						\rFill,     	rFill,

						\fillFactor,	fillFactor,

						\dur, 			dur
					]);
				};
			}.defer;
			dur.clip(0.01, 2).wait;
		};
	}).play;

	~firstNote = nil;
	~notes = (60: 60);


	MIDIdef.noteOn(\noteOn, {|vel, note|
		if(~firstNote.isNil){
			~notes = ();
			~firstNote = note;
		};
		~notes.put(note.asSymbol, note);
	}, chan: 1);


	MIDIdef.noteOff(\noteOff, {|vel, note|
		if(~notes[note.asSymbol] == ~firstNote){
			~firstNote = nil;
		}
	});

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
