/*
* GUI TODO:
*
* paramameter:
*
* dir				--> verändert den Kontext von pos so, dass bei	dir = 1 von pos bis length gespielt wird und bei
*																					dir = -1 von (pos + length) bis pos
* loFiltFreq	--> Frequenz Low-Pass
* hiFiltFreq	--> Frequenz High-Pass
* 						→ hierfür eine art filterView??
*						→ mehr kontroll auf grain zu grain basis
*
*
* transposition	--> über MIDI steuern
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
/* TODO: make more flexible! (allow instances) */
~send = Bus.audio(s, 2);
loadRelative("INIT_GRNLR.scd");
loadRelative("Grnlr.scd");

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
	~grnlr_bus = Bus.audio(s, 2);

	//-------------------------- TOP SWITCHES --------------------------//
	{

		// on / off switch
		var on = Button.new(win, Rect(params.offRight - 15, 5, bSize, bSize)).states_([
			["Off", Color.black, Color.white],
			["On" , Color.black, Color.white]
		]).action_({ |item|
			~grnlrPar.toggle = item.value;
		});

		// all sequences
		var seqAll = Button.new(win, Rect(params.offRight - 65, 5, 40, bSize)).states_([
			[">", Color.black, Color.white],
			["#" , Color.black, Color.white]
		]).action_{|item|
			if(item.value > 0, {
				~grnlrSeq.button_Pos.valueAction_(1);
				~grnlrSeq.button_rPos.valueAction_(1);
				~grnlrSeq.button_Amp.valueAction_(1);
				~grnlrSeq.button_rAmp.valueAction_(1);
				~grnlrSeq.button_Pitch.valueAction_(1);
				~grnlrSeq.button_rPitch.valueAction_(1);
				~grnlrSeq.button_Fill.valueAction_(1);
				~grnlrSeq.button_rFill.valueAction_(1);
				~grnlrSeq.button_Dur.valueAction_(1);
				~grnlrSeq.button_rDur.valueAction_(1);


			}, {
				~grnlrSeq.button_Pos.valueAction_(0);
				~grnlrSeq.button_rPos.valueAction_(0);
				~grnlrSeq.button_Amp.valueAction_(0);
				~grnlrSeq.button_rAmp.valueAction_(0);
				~grnlrSeq.button_Pitch.valueAction_(0);
				~grnlrSeq.button_rPitch.valueAction_(0);
				~grnlrSeq.button_Fill.valueAction_(0);
				~grnlrSeq.button_rFill.valueAction_(0);
				~grnlrSeq.button_Dur.valueAction_(0);
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
					buf = Buffer.read(s, path);								// load dragged sample into buffer
					buf.postln;

					waveform.load(path);											// load waveform into SoundFileView
					{ 0.1.wait; ~loadSynth.value(buf, ~grnlr_bus) }.fork(AppClock)	// build synthdef with buffer
				});
			};

		}.value;

		// position
		{
			var xOffset = 120;

			var pos	 	= Slider.new(mainControlsView,
				Rect(0, 120, params.offRight, 18)).action_{|item|
				~grnlrPar.pos = item.value };

			var rPos	= EZNumber.new(mainControlsView,
				Rect(xOffset, rowSize * 3 + yOffset, kSize, kSize), "rPos",
				[0, 0.7, 3, 0, ~grnlrPar.rPos], {|item|
					~grnlrPar.rPos = item.value;
			}, layout: \line2);

			var envPos	= EZNumber.new(mainControlsView,
				Rect(xOffset, rowSize * 4 + yOffset, kSize, kSize), "ePos",
				[0, 1, 'lin', 0, ~grnlrPar.posMod], {|item|
					~grnlrPar.posMod = item.value;
			}, layout: \line2);

			var env_rPos = EZNumber.new(mainControlsView,
				Rect(xOffset, rowSize * 5 + yOffset, kSize, kSize), "envR",
				[0, 1, 'lin', 0, ~grnlrPar.rPosMod], {|item|
					~grnlrPar.rPosMod = item.value;
			}, layout: \line2);

			var dir		= EZKnob.new(mainControlsView,
				Rect(xOffset, rowSize + yOffset, kSize, kSize*2), "Dir",
				[-1, 1, 'lin', 0, ~grnlrPar.dir], {|item|
					~grnlrPar.dir = item.value;
			});
			// Pitch
			{
				var xOffset = 180;

				var pitch  = EZNumber.new(mainControlsView,
					Rect(xOffset, rowSize * 2 + yOffset, kSize, kSize), "Pitch",
					[-24, 24, 'lin', 0.5, ~grnlrPar.trans], {|item|
						~grnlrPar.trans = item.value;
				}, layout: \line2);

				var rPitch = EZNumber.new(mainControlsView,
					Rect(xOffset, rowSize * 3 + yOffset, kSize, kSize), "rPitch",
					[0, 1, 4, 0, ~grnlrPar.rPitch], {|item|
						~grnlrPar.rPitch = item.value;
				}, layout: \line2);

				var envPitch = EZNumber.new(mainControlsView,
					Rect(xOffset, rowSize * 4 + yOffset, kSize, kSize), "ePitch",
					[0, 48, 'lin', 0, ~grnlrPar.pitchMod], {|item|
						~grnlrPar.pitchMod = item.value;
				}, layout: \line2);

				var env_rPitch = EZNumber.new(mainControlsView,
					Rect(xOffset, rowSize * 5 + yOffset, kSize, kSize), "envR",
					[0, 1, 'lin', 0, ~grnlrPar.rPitchMod], {|item|
						~grnlrPar.rPitchMod = item.value;
				}, layout: \line2);

			}.value;

			// duration
			{

				var dur  = EZKnob.new(mainControlsView,
					Rect(0, rowSize+yOffset, kSize, kSize*2), "Dur",
					[0.001, 2, 'exp', 0, ~grnlrPar.dur], {|item|
						~grnlrPar.dur = item.value;
				});

				var rDur = EZNumber.new(mainControlsView,
					Rect(0, rowSize * 3 + yOffset, kSize, kSize), "rDur",
					[0, 1, 'lin', 0, ~grnlrPar.rDur], {|item|
						~grnlrPar.rDur = item.value;
				}, layout: \line2);

				var envDur = EZNumber.new(mainControlsView,
					Rect(0, rowSize * 4 + yOffset, kSize, kSize), "eDur",
					[0, 1, 'lin', 0, ~grnlrPar.durMod], {|item|
						~grnlrPar.durMod = item.value;
				}, layout: \line2);

				var env_rDur = EZNumber.new(mainControlsView,
					Rect(0, rowSize * 5 + yOffset, kSize, kSize), "rEnv",
					[0, 1, 'lin', 0, ~grnlrPar.rDurMod], {|item|
						~grnlrPar.rDurMod = item.value;
				}, layout: \line2);
			}.value;


			// fill factor
			{
				var xOffset = 60;
				var fill	 = EZKnob.new(mainControlsView,
					Rect(xOffset, rowSize + yOffset, kSize, kSize*2), "Fill",
					[0.1, 16, 'exp', 0, ~grnlrPar.fillFactor], {|item|
						~grnlrPar.fillFactor = item.value;
				});
				var rFill	 = EZNumber.new(mainControlsView,
					Rect(xOffset, rowSize * 3 + yOffset, kSize, kSize), "rFill",
					[0, 2, 'lin', 0, ~grnlrPar.rFill], {|item|
						~grnlrPar.rFill = item.value;
				}, layout: \line2);

				var envFill	 = EZNumber.new(mainControlsView,
					Rect(xOffset, rowSize * 4 + yOffset, kSize, kSize), "eFill",
					[0, 1, 'lin', 0, ~grnlrPar.fillMod], {|item|
						~grnlrPar.fillMod = item.value;
				}, layout: \line2);


				var env_rFill	 = EZNumber.new(mainControlsView,
					Rect(xOffset, rowSize * 5 + yOffset, kSize, kSize), "rEnv",
					[0, 1, 'lin', 0, ~grnlrPar.rFillMod], {|item|
						~grnlrPar.rFillMod = item.value;
				}, layout: \line2);

			}.value;
			// grain window
			{
				var xOffset = 240;

				var curve = ~grnlrPar.envCurve;
				var startEnv = Env.new([0, 1, 1, 0], [0.3, 0.3, 0.3], [curve, 1, curve*(-1)]);

				var t_env 	= StaticText.new(mainControlsView,
					Rect(xOffset, rowSize + yOffset - 2, 260, 20)).string_("Grain Window");

				var envView = EnvelopeView.new(mainControlsView,
					Rect(xOffset, rowSize + yOffset + 20, 260, 140)).keepHorizontalOrder_(true);

				var cur	 = EZNumber.new(mainControlsView,
					Rect(xOffset, rowSize * 5 + yOffset, kSize, kSize), "Curve",
					[6, -6, 'lin', 0, ~grnlrPar.envCurve], {|item|
						~grnlrPar.envCurve = item.value;
						curve = ~grnlrPar.envCurve;
						envView.curves = [curve, 0, curve.neg];
				}, layout: \line2);

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

				var filtLoFreq  = EZKnob.new(mainControlsView,
					Rect(xOffset, rowSize + yOffset, kSize+10, kSize*2), "freqLo",
					[20, 20000, 'exp', 1, ~grnlrPar.filtFreqLo], {|item|
						~grnlrPar.filtFreqLo = item.value;
				}, labelWidth: 50);
				var filtHiFreq  = EZKnob.new(mainControlsView,
					Rect(xOffset + 80, rowSize + yOffset, kSize+10, kSize*2),
					"freqHi", [20, 20000, 'exp', 1, ~grnlrPar.filtFreqHi], {|item|
						~grnlrPar.filtFreqHi = item.value;
				}, labelWidth: 50);
				var qLo = EZNumber.new(mainControlsView,
					Rect(xOffset, rowSize * 3 + yOffset, kSize, kSize), "qLo",
					[0.1, 1, 'lin', 0, ~grnlrPar.qLo], {|item|
						~grnlrPar.qLo = item.value;
				}, layout: \line2);
				var qHi = EZNumber.new(mainControlsView,
					Rect(xOffset + 80, rowSize * 3 + yOffset, kSize, kSize),
					"qHi", [0.1, 1, 'lin', 0, ~grnlrPar.qHi], {|item|
						~grnlrPar.qHi = item.value;
				}, layout: \line2);

			}.value;
		}.value;
		// master

		{
			var xOffset = 800;

			var vol  = EZKnob.new(mainControlsView,
				Rect(xOffset, rowSize + yOffset, kSize, kSize*2), "vol",
				[0, 1, 3, 0, ~grnlrPar.vol], {|item|
					~grnlrPar.vol = item.value;
			}, 1, true);

			var rAmp  = EZNumber.new(mainControlsView,
				Rect(xOffset, rowSize * 3 + yOffset, kSize, kSize), "rVol",
				[0, 1, 'lin', 0, ~grnlrPar.rAmp], {|item|
					~grnlrPar.rAmp = item.value;
			}, layout: \line2);

			var envVol  = EZNumber.new(mainControlsView,
				Rect(xOffset, rowSize * 4 + yOffset, kSize, kSize), "eVol",
				[0, 1, -4, 0, ~grnlrPar.ampMod], {|item|
					~grnlrPar.ampMod = item.value;
			}, layout: \line2);

			var env_ampMod  = EZNumber.new(mainControlsView,
				Rect(xOffset, rowSize * 5 + yOffset, kSize, kSize), "rEnv",
				[0, 1, 'lin', 0, ~grnlrPar.rAmpMod], {|item|
					~grnlrPar.rAmpMod = item.value;
			}, layout: \line2);

			var pan  = EZKnob.new(mainControlsView,
				Rect(xOffset - 60, rowSize + yOffset, 50, 80), "pan",
				[-1, 1, 'lin', 0, ~grnlrPar.pan], {|item|
					~grnlrPar.pan = item.value;
			}, 0, true);

			var send  = EZKnob.new(mainControlsView,
				Rect(xOffset - 60, rowSize * 3 + yOffset, 50, 80), "send",
				[0, 1, 'lin', 0, ~grnlrPar.send], {|item|
					~grnlrPar.send = item.value;
			}, 0, true);

		}.value;
	}.value;

	//-------------------------------------------------------------------//
	//-------------------------------------------------------------------//
	//-------------------------- SEQUENCER ------------------------------//
	//-------------------------------------------------------------------//
	//-------------------------------------------------------------------//

	{	/* TODO:
		*	Refactor Code: implement sequencer with function factory so changes can be implemented more easily
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

		var textPos = 720;
		var curvePos = 820;
		var stepsPos = 770;
		var envWidth = 710;
		{
			// POSITION
			var offY = 0;
			var name = "Position";
			var tDef_name = 'seqPos';
			var length	 = 4 * 128;
			var numSteps = 2;
			var curve	 = 0;
			var env 	 = Env.new(0 ! numSteps);

			var envView  = EnvelopeView.new(seqView, Rect(0, offY + 0, envWidth, 120)).setEnv(env).keepHorizontalOrder_(true).action_({|item|
				env = asEnv.value(item, curve);
			}).gridOn_(true).grid_(0.0625@0.1);

			var text = StaticText.new(seqView, Rect(textPos, offY + 0, 80, 20)).string_(name);

			var button 	= Button.new(seqView, Rect(textPos, offY + 30, 80, 40)).states_([
				[">", Color.black, Color.white],
				["#" , Color.black, Color.white]
			]).action_{|item|
				if(item.value > 0, {Tdef(tDef_name).play;}, { Tdef(tDef_name).stop; })
			};

			var cur	 = EZKnob.new(seqView, Rect(curvePos, offY + 30, 40, 80), "Curve", [-12, 12, 'lin', 0, 0], {|item|
				curve = item.value;
				envView.curves = curve;
				env = asEnv.value(envView, curve);
			});

			var steps	= EZNumber.new(seqView, Rect(stepsPos, offY + 70, 45, 40), "Steps", [2, 16, 'lin', 1, numSteps], {|item|
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

			var speed = EZNumber.new(seqView, Rect(textPos, offY + 70, 45, 40), "Length", [0.25, 32, 'lin', 0.25, 4], {|item|
				length = item.value * 128;
			}, 4, layout: 'line2' );

			// make Button semi global
			~grnlrSeq.button_Pos = button;

			Tdef(tDef_name, {
				var i = 0;
				loop{
					i = (i + 1) % length;
					~grnlrSeq.pos = env.at(i.linlin(0, length, 0, env.duration));
					(1/128).wait;
				}
			});
		}.value;
		{
			// Random POSITION

			var offY 	  = 150;
			var name 	  = "Rand Pos";
			var tDef_name = 'seq_rPos';
			var length	  = 4 * 128;
			var numSteps  = 2;
			var curve	  = 0;
			var env 	  = Env.new(0 ! numSteps);

			var envView  = EnvelopeView.new(seqView, Rect(0, offY + 0, envWidth, 120)).setEnv(env).keepHorizontalOrder_(true).action_({|item|
				env = asEnv.value(item, curve);
			}).gridOn_(true).grid_(0.0625@0.1);

			var text = StaticText.new(seqView, Rect(textPos, offY + 0, 80, 20)).string_(name);

			var button 	= Button.new(seqView, Rect(textPos, offY + 30, 80, 40)).states_([
				[">", Color.black, Color.white],
				["#" , Color.black, Color.white]
			]).action_{|item|
				if(item.value > 0, {Tdef(tDef_name).play;}, { Tdef(tDef_name).stop; })
			};

			var cur	 = EZKnob.new(seqView, Rect(curvePos, offY + 30, 40, 80), "Curve", [-12, 12, 'lin', 0, 0], {|item|
				curve = item.value;
				envView.curves = curve;
				env = asEnv.value(envView, curve);
			});

			var steps	= EZNumber.new(seqView, Rect(stepsPos, offY + 70, 45, 40), "Steps", [2, 16, 'lin', 1, numSteps], {|item|
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

			var speed = EZNumber.new(seqView, Rect(textPos, offY + 70, 45, 40), "Length", [0.25, 32, 'lin', 0.25, 4], {|item|
				length = item.value * 128;
			}, 4, layout: 'line2' );

			// make Button semi global
			~grnlrSeq.button_rPos = button;

			Tdef(tDef_name, {
				var i = 0;
				loop{
					i = (i + 1) % length;
					~grnlrSeq.rPos = env.at(i.linlin(0, length, 0, env.duration));
					(1/128).wait;
				}
			});
		}.value;
		{
			// AMPLITUDE

			var offY = 300;
			var name = "Amplitude";
			var tDef_name = 'seqAmp';
			var length	 = 4 * 128;
			var numSteps = 2;
			var curve	 = 0;
			var env 	 = Env.new(0 ! numSteps);

			var envView  = EnvelopeView.new(seqView, Rect(0, offY + 0, envWidth, 120)).setEnv(env).keepHorizontalOrder_(true).action_({|item|
				env = asEnv.value(item, curve);
			}).gridOn_(true).grid_(0.0625@0.1);

			var text = StaticText.new(seqView, Rect(textPos, offY + 0, 80, 20)).string_(name);

			var button 	= Button.new(seqView, Rect(textPos, offY + 30, 80, 40)).states_([
				[">", Color.black, Color.white],
				["#" , Color.black, Color.white]
			]).action_{|item|
				if(item.value > 0, {Tdef(tDef_name).play;}, { Tdef(tDef_name).stop; })
			};

			var cur	 = EZKnob.new(seqView, Rect(curvePos, offY + 30, 40, 80), "Curve", [-12, 12, 'lin', 0, 0], {|item|
				curve = item.value;
				envView.curves = curve;
				env = asEnv.value(envView, curve);
			});

			var steps	= EZNumber.new(seqView, Rect(stepsPos, offY + 70, 45, 40), "Steps", [2, 16, 'lin', 1, numSteps], {|item|
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

			var speed = EZNumber.new(seqView, Rect(textPos, offY + 70, 45, 40), "Length", [0.25, 32, 'lin', 0.25, 4], {|item|
				length = item.value * 128;
			}, 4, layout: 'line2' );

			// make Button semi global
			~grnlrSeq.button_Amp = button;


			Tdef(tDef_name, {
				var i = 0;
				loop{
					i = (i + 1) % length;
					~grnlrSeq.amp = env.at(i.linlin(0, length, 0, env.duration));
					(1/128).wait;
				}
			});
		}.value;
		{
			// RANDOM AMPLITUDE

			var offY = 450;
			var name = "Rand Amp";
			var tDef_name = 'seq_rAmp';
			var length	 = 4 * 128;
			var numSteps = 2;
			var curve	 = 0;
			var env 	 = Env.new(0 ! numSteps);

			var envView  = EnvelopeView.new(seqView, Rect(0, offY + 0, envWidth, 120)).setEnv(env).keepHorizontalOrder_(true).action_({|item|
				env = asEnv.value(item, curve);
			}).gridOn_(true).grid_(0.0625@0.1);

			var text = StaticText.new(seqView, Rect(textPos, offY + 0, 80, 20)).string_(name);

			var button 	= Button.new(seqView, Rect(textPos, offY + 30, 80, 40)).states_([
				[">", Color.black, Color.white],
				["#" , Color.black, Color.white]
			]).action_{|item|
				if(item.value > 0, {Tdef(tDef_name).play;}, { Tdef(tDef_name).stop; })
			};

			var cur	 = EZKnob.new(seqView, Rect(curvePos, offY + 30, 40, 80), "Curve", [-12, 12, 'lin', 0, 0], {|item|
				curve = item.value;
				envView.curves = curve;
				env = asEnv.value(envView, curve);
			});

			var steps	= EZNumber.new(seqView, Rect(stepsPos, offY + 70, 45, 40), "Steps", [2, 16, 'lin', 1, numSteps], {|item|
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

			var speed = EZNumber.new(seqView, Rect(textPos, offY + 70, 45, 40), "Length", [0.25, 32, 'lin', 0.25, 4], {|item|
				length = item.value * 128;
			}, 4, layout: 'line2' );

			// make Button semi global
			~grnlrSeq.button_rAmp = button;



			Tdef(tDef_name, {
				var i = 0;
				loop{
					i = (i + 1) % length;
					~grnlrSeq.rAmp = env.at(i.linlin(0, length, 0, env.duration));
					(1/128).wait;
				}
			});
		}.value;

		{
			// Pitch

			var offY = 600;
			var name = "Pitch";
			var tDef_name = 'seqPitch';
			var length	 = 4 * 128;
			var numSteps = 2;
			var curve	 = 0;
			var env 	 = Env.new(0.5 ! numSteps);

			var envView  = EnvelopeView.new(seqView, Rect(0, offY + 0, envWidth, 120)).setEnv(env).keepHorizontalOrder_(true).action_({|item|
				env = asEnv.value(item, curve);
			}).gridOn_(true).grid_(0.0625@0.1);

			var text = StaticText.new(seqView, Rect(textPos, offY + 0, 80, 20)).string_(name);

			var button 	= Button.new(seqView, Rect(textPos, offY + 30, 80, 40)).states_([
				[">", Color.black, Color.white],
				["#" , Color.black, Color.white]
			]).action_{|item|
				if(item.value > 0, {Tdef(tDef_name).play;}, { Tdef(tDef_name).stop; })
			};

			var cur	 = EZKnob.new(seqView, Rect(curvePos, offY + 30, 40, 80), "Curve", [-12, 12, 'lin', 0, 0], {|item|
				curve = item.value;
				envView.curves = curve;
				env = asEnv.value(envView, curve);
			});

			var steps	= EZNumber.new(seqView, Rect(stepsPos, offY + 70, 45, 40), "Steps", [2, 16, 'lin', 1, numSteps], {|item|
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

			var speed = EZNumber.new(seqView, Rect(textPos, offY + 70, 45, 40), "Length", [0.25, 32, 'lin', 0.25, 4], {|item|
				length = item.value * 128;
			}, 4, layout: 'line2' );

			// make Button semi global
			~grnlrSeq.button_Pitch = button;



			Tdef(tDef_name, {
				var i = 0;
				loop{
					i = (i + 1) % length;
					~grnlrSeq.pitch = env.at(i.linlin(0, length, 0, env.duration)).linlin(0, 1, -1, 1);
					(1/128).wait;
				}
			});
		}.value;

		{
			// RANDOM PITCH

			var offY = 750;
			var name = "Rand Pitch";
			var tDef_name = 'seq_rPitch';
			var length	 = 4 * 128;
			var numSteps = 2;
			var curve	 = 0;
			var env 	 = Env.new(0 ! numSteps);

			var envView  = EnvelopeView.new(seqView, Rect(0, offY + 0, envWidth, 120)).setEnv(env).keepHorizontalOrder_(true).action_({|item|
				env = asEnv.value(item, curve);
			}).gridOn_(true).grid_(0.0625@0.1);

			var text = StaticText.new(seqView, Rect(textPos, offY + 0, 80, 20)).string_(name);

			var button 	= Button.new(seqView, Rect(textPos, offY + 30, 80, 40)).states_([
				[">", Color.black, Color.white],
				["#" , Color.black, Color.white]
			]).action_{|item|
				if(item.value > 0, {Tdef(tDef_name).play;}, { Tdef(tDef_name).stop; })
			};

			var cur	 = EZKnob.new(seqView, Rect(curvePos, offY + 30, 40, 80), "Curve", [-12, 12, 'lin', 0, 0], {|item|
				curve = item.value;
				envView.curves = curve;
				env = asEnv.value(envView, curve);
			});

			var steps	= EZNumber.new(seqView, Rect(stepsPos, offY + 70, 45, 40), "Steps", [2, 16, 'lin', 1, numSteps], {|item|
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

			var speed = EZNumber.new(seqView, Rect(textPos, offY + 70, 45, 40), "Length", [0.25, 32, 'lin', 0.25, 4], {|item|
				length = item.value * 128;
			}, 4, layout: 'line2' );

			// make Button semi global
			~grnlrSeq.button_rPitch = button;



			Tdef(tDef_name, {
				var i = 0;
				loop{
					i = (i + 1) % length;
					~grnlrSeq.rPitch = env.at(i.linlin(0, length, 0, env.duration)).linlin(0, 1, -1, 1);
					(1/128).wait;
				}
			});
		}.value;

		{
			// Fill

			var offY = 900;
			var name = "Fill Factor";
			var tDef_name = 'seqFill';
			var length	 = 4 * 128;
			var numSteps = 2;
			var curve	 = 0;
			var env 	 = Env.new(0 ! numSteps);

			var envView  = EnvelopeView.new(seqView, Rect(0, offY + 0, envWidth, 120)).setEnv(env).keepHorizontalOrder_(true).action_({|item|
				env = asEnv.value(item, curve);
			}).gridOn_(true).grid_(0.0625@0.1);

			var text = StaticText.new(seqView, Rect(textPos, offY + 0, 80, 20)).string_(name);

			var button 	= Button.new(seqView, Rect(textPos, offY + 30, 80, 40)).states_([
				[">", Color.black, Color.white],
				["#" , Color.black, Color.white]
			]).action_{|item|
				if(item.value > 0, {Tdef(tDef_name).play;}, { Tdef(tDef_name).stop; })
			};

			var cur	 = EZKnob.new(seqView, Rect(curvePos, offY + 30, 40, 80), "Curve", [-12, 12, 'lin', 0, 0], {|item|
				curve = item.value;
				envView.curves = curve;
				env = asEnv.value(envView, curve);
			});

			var steps	= EZNumber.new(seqView, Rect(stepsPos, offY + 70, 45, 40), "Steps", [2, 16, 'lin', 1, numSteps], {|item|
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

			var speed = EZNumber.new(seqView, Rect(textPos, offY + 70, 45, 40), "Length", [0.25, 32, 'lin', 0.25, 4], {|item|
				length = item.value * 128;
			}, 4, layout: 'line2' );

			// make Button semi global
			~grnlrSeq.button_Fill = button;



			Tdef(tDef_name, {
				var i = 0;
				loop{
					i = (i + 1) % length;
					~grnlrSeq.fill = env.at(i.linlin(0, length, 0, env.duration));
					(1/128).wait;
				}
			});
		}.value;

		{
			// RANDOM FILL

			var offY = 1050;
			var name = "RandFill";
			var tDef_name = 'seq_rFill';
			var length	 = 4 * 128;
			var numSteps = 2;
			var curve	 = 0;
			var env 	 = Env.new(0 ! numSteps);

			var envView  = EnvelopeView.new(seqView, Rect(0, offY + 0, envWidth, 120)).setEnv(env).keepHorizontalOrder_(true).action_({|item|
				env = asEnv.value(item, curve);
			}).gridOn_(true).grid_(0.0625@0.1);

			var text = StaticText.new(seqView, Rect(textPos, offY + 0, 80, 20)).string_(name);

			var button 	= Button.new(seqView, Rect(textPos, offY + 30, 80, 40)).states_([
				[">", Color.black, Color.white],
				["#" , Color.black, Color.white]
			]).action_{|item|
				if(item.value > 0, {Tdef(tDef_name).play;}, { Tdef(tDef_name).stop; })
			};

			var cur	 = EZKnob.new(seqView, Rect(curvePos, offY + 30, 40, 80), "Curve", [-12, 12, 'lin', 0, 0], {|item|
				curve = item.value;
				envView.curves = curve;
				env = asEnv.value(envView, curve);
			});

			var steps	= EZNumber.new(seqView, Rect(stepsPos, offY + 70, 45, 40), "Steps", [2, 16, 'lin', 1, numSteps], {|item|
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

			var speed = EZNumber.new(seqView, Rect(textPos, offY + 70, 45, 40), "Length", [0.25, 32, 'lin', 0.25, 4], {|item|
				length = item.value * 128;
			}, 4, layout: 'line2' );

			// make Button semi global
			~grnlrSeq.button_rFill = button;



			Tdef(tDef_name, {
				var i = 0;
				loop{
					i = (i + 1) % length;
					~grnlrSeq.rFill = env.at(i.linlin(0, length, 0, env.duration));
					(1/128).wait;
				}
			});
		}.value;

		{
			// Duration

			var offY = 1200;
			var name = "Duration";
			var tDef_name = 'seqDur';
			var length	 = 4 * 128;
			var numSteps = 2;
			var curve	 = 0;
			var env 	 = Env.new(0 ! numSteps);

			var envView  = EnvelopeView.new(seqView, Rect(0, offY + 0, envWidth, 120)).setEnv(env).keepHorizontalOrder_(true).action_({|item|
				env = asEnv.value(item, curve);
			}).gridOn_(true).grid_(0.0625@0.1);

			var text = StaticText.new(seqView, Rect(textPos, offY + 0, 80, 20)).string_(name);

			var button 	= Button.new(seqView, Rect(textPos, offY + 30, 80, 40)).states_([
				[">", Color.black, Color.white],
				["#" , Color.black, Color.white]
			]).action_{|item|
				if(item.value > 0, {Tdef(tDef_name).play;}, { Tdef(tDef_name).stop; })
			};

			var cur	 = EZKnob.new(seqView, Rect(curvePos, offY + 30, 40, 80), "Curve", [-12, 12, 'lin', 0, 0], {|item|
				curve = item.value;
				envView.curves = curve;
				env = asEnv.value(envView, curve);
			});

			var steps	= EZNumber.new(seqView, Rect(stepsPos, offY + 70, 45, 40), "Steps", [2, 16, 'lin', 1, numSteps], {|item|
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

			var speed = EZNumber.new(seqView, Rect(textPos, offY + 70, 45, 40), "Length", [0.25, 32, 'lin', 0.25, 4], {|item|
				length = item.value * 128;
			}, 4, layout: 'line2' );

			// make Button semi global
			~grnlrSeq.button_Dur = button;


			Tdef(tDef_name, {
				var i = 0;
				loop{
					i = (i + 1) % length;
					~grnlrSeq.dur = env.at(i.linlin(0, length, 0, env.duration));
					(1/128).wait;
				}
			});
		}.value;

		{
			// RANDOM DURATION

			var offY = 1350;
			var name = "Rand Dur";
			var tDef_name = 'seq_rDur';
			var length	 = 4 * 128;
			var numSteps = 2;
			var curve	 = 0;
			var env 	 = Env.new(0 ! numSteps);

			var envView  = EnvelopeView.new(seqView, Rect(0, offY + 0, envWidth, 120)).setEnv(env).keepHorizontalOrder_(true).action_({|item|
				env = asEnv.value(item, curve);
			}).gridOn_(true).grid_(0.0625@0.1);

			var text = StaticText.new(seqView, Rect(textPos, offY + 0, 80, 20)).string_(name);

			var button 	= Button.new(seqView, Rect(textPos, offY + 30, 80, 40)).states_([
				[">", Color.black, Color.white],
				["#" , Color.black, Color.white]
			]).action_{|item|
				if(item.value > 0, {Tdef(tDef_name).play;}, { Tdef(tDef_name).stop; })
			};

			var cur	 = EZKnob.new(seqView, Rect(curvePos, offY + 30, 40, 80), "Curve", [-12, 12, 'lin', 0, 0], {|item|
				curve = item.value;
				envView.curves = curve;
				env = asEnv.value(envView, curve);
			});

			var steps	= EZNumber.new(seqView, Rect(stepsPos, offY + 70, 45, 40), "Steps", [2, 16, 'lin', 1, numSteps], {|item|
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

			var speed = EZNumber.new(seqView, Rect(textPos, offY + 70, 45, 40), "Length", [0.25, 32, 'lin', 0.25, 4], {|item|
				length = item.value * 128;
			}, 4, layout: 'line2' );

			// make Button semi global
			~grnlrSeq.button_rDur = button;


			Tdef(tDef_name, {
				var i = 0;
				loop{
					i = (i + 1) % length;
					~grnlrSeq.rDur = env.at(i.linlin(0, length, 0, env.duration));
					(1/128).wait;
				}
			});
		}.value;

	}.value;
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
