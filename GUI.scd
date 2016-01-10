/*
* GUI TODO:
*
* paramameter:
*
* Buffer			-->
* pos				--> Position im Sample Slider mit Strich auf Waveformdisplay
* posMod			--> zufällige Positionsänderung
* fillFactor	--> multiplikator für die duration (grainLänge)
* fillMod		-->
* dir				--> verändert den Kontext von pos so, dass bei	dir = 1 von pos bis length gespielt wird und bei
*																					dir = -1 von (pos + length) bis pos
* loFiltFreq	--> Frequenz Low-Pass
* hiFiltFreq	--> Frequenz High-Pass
* 						→ hierfür eine art filterView??
*						→ mehr kontroll auf grain zu grain basis
*
*
* trans			--> über MIDI steuern
*
* KONTROLLFUNKTIONEN:
*
* Preset Funktion --> Alle Einstellungen plus Zustand der Modulationsmatrix und location des Buffer Speichern
* und laden
* IN / OUT Routing --> über liste
*
* STRUKTUR:
*
* GUI Werte: werte für paramameter werden in ein globales Dictionary geschrieben
* LFO/ENVS: hmm...
*
*/

(
~send = Bus.audio(s, 2);
loadRelative("INIT_GRNLR.scd");
loadRelative("Grnlr.scd"); // Synthdef

s.waitForBoot{

	var version = "GRNLR v0.2";
	var width = 1000;
	var height = 710;

	var bSize 	= 30;
	var kSize 	= 40;

	var params = (
		offLeft: 10,
		offRight: width - 20,
	);
	var labelFont	= Font("Sans", 10, true);
	var path 		= "String";
	var win 			= Window.new(version, Rect(0, 0, width, height), false, scroll: true);
	var synthView 	= View.new(win, Rect(0, 50, 1000, 700));
	var seqView 	= View.new(win, Rect(0, 50, 1000, 1510)).visible_(false);

	//-------------------------- TOP SWITCHES --------------------------//
	{

		// on / off switch
		var on 	 	= Button.new(win, Rect(params.offRight -20, 10, bSize, bSize)).states_([
			["Off", Color.black, Color.white],
			["On" , Color.black, Color.white]
		]).action_({ |item|
			~grnlrPar.toggle = item.value;
		});

		// all sequences
		var seqAll 	= Button.new(win, Rect(params.offRight - 120, 10, 80, 30)).states_([
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

		var synth	= Button.new(win, Rect(params.offLeft, 10, 70, 30)).states_([
			["Synth", Color.black, Color.white]
		]).action_({
			seqView.visible_(false);
			synthView.visible_(true);
		});
		var seq		= Button.new(win, Rect(params.offLeft + 80, 10, 70, 30)).states_([
			["Sequencer", Color.black, Color.white]
		]).action_({
			synthView.visible_(false);
			seqView.visible_(true);
		});

		var tempo = EZNumber.new(win,
			Rect(params.offLeft + 160, 0, 50, 40), "Tempo", [40, 200, 'lin', 1, 120], {|item|
				TempoClock.default.tempo = item.value/60;
		}, 120, true, layout: 'line2');

	}.value;

	//-------------------------------------------------------------------//
	//-------------------------------------------------------------------//
	//-------------------------- SYNTH ----------------------------------//
	//-------------------------------------------------------------------//
	//-------------------------------------------------------------------//
	{

		var row_1 	= 120;
		var row_2	= 210;
		var row_3	= 300;
		var row_4	= 390;
		var row_5	= 480;
		var row_6	= 570;

		//
		{
			var waveform = SoundFileView.new(synthView, Rect(params.offLeft, 0, params.offRight, 90));

			var buf;
			waveform.canReceiveDragHandler = { View.currentDrag.isString;};
			waveform.receiveDragHandler_{
				path = View.currentDrag.value; path.isString.postln;
				if(path.isString, {
					buf = Buffer.read(s, path);								// load dragged sample into buffer
					buf.postln;

					waveform.load(path);											// load waveform into SoundFileView
					{0.1.wait; ~loadSynth.value(buf);}.fork(AppClock)	// build synthdef with buffer
				});
			};

		}.value;

		// MAIN CONTROLS
		{
			// position
			var pos	 	= Slider.new(synthView,
				Rect(params.offLeft, 90, params.offRight, 20)).action_{|item|
				~grnlrPar.pos = item.value };
			var envPos	= EZKnob.new(synthView,
				Rect(params.offRight - 40, row_1, 40, 80), "ePos", [0, 1, 'lin', 0, ~grnlrPar.posMod], {|item|
					~grnlrPar.posMod = item.value;
			}, unitWidth: 0);
			var rPos	= EZKnob.new(synthView,
				Rect(params.offRight - 40, row_2, 40, 80), "rPos", [0, 0.5, 3, 0, ~grnlrPar.rPos], {|item|
					~grnlrPar.rPos = item.value;
			});
			var env_rPos = EZKnob.new(synthView,
				Rect(params.offRight - 40, row_3, 40, 80), "envR", [0, 1, 'lin', 0, ~grnlrPar.rPosMod], {|item|
					~grnlrPar.rPosMod = item.value;
			}, unitWidth: 0);
			// direction
			var dir		= EZKnob.new(synthView,
				Rect(params.offRight - 100, row_1, 40, 80), "Dir", [-1, 1, 'lin', 0, ~grnlrPar.dir], {|item|
					~grnlrPar.dir = item.value;
			});
			// Pitch
			{
				var x = params.offLeft + 500;

				var pitch  = EZKnob.new(synthView,
					Rect(x, row_1, 40, 80), "Pitch", [-24, 24, 'lin', 0.5, ~grnlrPar.trans], {|item|
						~grnlrPar.trans = item.value;
				});
				var envPitch = EZKnob.new(synthView,
					Rect(x, row_2, 40, 80), "ePitch", [0, 48, 'lin', 0, ~grnlrPar.pitchMod], {|item|
						~grnlrPar.pitchMod = item.value;
				});
				var rPitch = EZKnob.new(synthView,
					Rect(x, row_3, 40, 80), "rPitch", [0, 1, 4, 0, ~grnlrPar.rPitch], {|item|
						~grnlrPar.rPitch = item.value;
				});
				var env_rPitch = EZKnob.new(synthView,
					Rect(x, row_4, 40, 80), "envR", [0, 1, 'lin', 0, ~grnlrPar.rPitchMod], {|item|
						~grnlrPar.rPitchMod = item.value;
				});

			}.value;
			// duration
			{
				var x = params.offLeft;

				var dur  = EZKnob.new(synthView,
					Rect(x, row_1, 40, 80), "Dur", [0.001, 2, 'exp', 0, ~grnlrPar.dur], {|item|
						~grnlrPar.dur = item.value;
				});
				var envDur = EZKnob.new(synthView,
					Rect(x, row_2, 40, 80), "eDur", [0, 1, 'lin', 0, ~grnlrPar.durMod], {|item|
						~grnlrPar.durMod = item.value;
				});
				var rDur = EZKnob.new(synthView,
					Rect(x, row_3, 40, 80), "rDur", [0, 0.5, 'lin', 0, ~grnlrPar.rDur], {|item|
						~grnlrPar.rDur = item.value;
				});
				var env_rDur = EZKnob.new(synthView,
					Rect(x, row_4, 40, 80), "rEnv", [0, 1, 'lin', 0, ~grnlrPar.rDurMod], {|item|
						~grnlrPar.rDurMod = item.value;
				});


			}.value;


			// fill factor
			{
				var x = params.offLeft + 60;
				var fill	 = EZKnob.new(synthView,
					Rect(x, row_1, 40, 80), "Fill", [0.1, 16, 'exp', 0, ~grnlrPar.fillFactor], {|item|
						~grnlrPar.fillFactor = item.value;
				});
				var envFill	 = EZKnob.new(synthView,
					Rect(x, row_2, 40, 80), "eFill", [0, 1, 'lin', 0, ~grnlrPar.fillMod], {|item|
						~grnlrPar.fillMod = item.value;
				});
				var rFill	 = EZKnob.new(synthView,
					Rect(x, row_3, 40, 80), "rFill", [0, 2, 'lin', 0, ~grnlrPar.rFill], {|item|
						~grnlrPar.rFill = item.value;
				});
				var env_rFill	 = EZKnob.new(synthView,
					Rect(x, row_4, 40, 80), "rEnv", [0, 1, 'lin', 0, ~grnlrPar.rFillMod], {|item|
						~grnlrPar.rFillMod = item.value;
				});

			}.value;

			// grain window
			{
				var curve = ~grnlrPar.envCurve;
				var startEnv = Env.new([0, 1, 1, 0], [0.3, 0.3, 0.3], [curve, 1, curve*(-1)]);
				var t_env 	= StaticText.new(synthView,
					Rect(params.offLeft + 120, row_1 - 2, 260, 20)).string_("Grain Window");
				var envView = EnvelopeView.new(synthView,
					Rect(params.offLeft + 120, row_1 + 20, 260, 150)).keepHorizontalOrder_(true);
				var cur	 = EZKnob.new(synthView,
					Rect(params.offLeft + 400, row_1, 40, 80), "Curve", [6, -6, 'lin', 0, ~grnlrPar.envCurve], {|item|
						~grnlrPar.envCurve = item.value;
						curve = ~grnlrPar.envCurve;
						envView.curves = [curve, 0, curve.neg];
				});
				envView.setEnv(startEnv);
				envView.action_{|item|
					var arr = item.value;
					~grnlrPar.timeArr = [arr[0][1], (arr[0][2] - arr[0][1]), (arr[0][3] - arr[0][2])];
					~grnlrPar.ampArr = arr[1];
				};
			}.value;

			// filter
			{
				var x = params.offLeft + 700;

				var filtLoFreq  = EZKnob.new(synthView,
					Rect(x, row_1, 50, 80), "freqLo", [20, 20000, 'exp', 1, ~grnlrPar.filtFreqLo], {|item|
						~grnlrPar.filtFreqLo = item.value;
				}, labelWidth: 80);
				var filtHiFreq  = EZKnob.new(synthView,
					Rect(x + 80, row_1, 50, 80), "freqHi", [20, 20000, 'exp', 1, ~grnlrPar.filtFreqHi], {|item|
						~grnlrPar.filtFreqHi = item.value;
				}, labelWidth: 80);
				var qLo = EZKnob.new(synthView,
					Rect(x, row_2, 40, 80), "qLo", [0.1, 1, 'lin', 0, ~grnlrPar.qLo], {|item|
						~grnlrPar.qLo = item.value;
				});
				var qHi = EZKnob.new(synthView,
					Rect(x + 80, row_2, 40, 80), "qHi", [0.1, 1, 'lin', 0, ~grnlrPar.qHi], {|item|
						~grnlrPar.qHi = item.value;
				});

			}.value;
		}.value;
		// master
		{
			var x = params.offRight - 170;

			var rAmp  = EZKnob.new(synthView,
				Rect(x - 60, row_5, 50, 80), "rAmp", [0, 1, 'lin', 0, ~grnlrPar.rAmp], {|item|
					~grnlrPar.rAmp = item.value;
			}, 0, true);
			var env_ampMod  = EZKnob.new(synthView,
				Rect(x - 60, row_6, 50, 80), "rEnv", [0, 1, 'lin', 0, ~grnlrPar.rAmpMod], {|item|
					~grnlrPar.rAmpMod = item.value;
			}, 0, true);
			var vol  = EZKnob.new(synthView,
				Rect(x, row_5, 50, 80), "vol", [0, 1, 3, 0, ~grnlrPar.vol], {|item|
					~grnlrPar.vol = item.value;
			}, 1, true);
			var envVol  = EZKnob.new(synthView,
				Rect(x, row_6, 50, 80), "env", [0, 1, -4, 0, ~grnlrPar.ampMod], {|item|
					~grnlrPar.ampMod = item.value;
			}, 0, true);
			var pan  = EZKnob.new(synthView,
				Rect(x + 60, row_5, 50, 80), "pan", [-1, 1, 'lin', 0, ~grnlrPar.pan], {|item|
					~grnlrPar.pan = item.value;
			}, 0, true);
			var send  = EZKnob.new(synthView,
				Rect(x + 120, row_5, 50, 80), "send", [-1, 1, 'lin', 0, ~grnlrPar.send], {|item|
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
		{
			// POSITION

			var offY = 0;
			var name = "Position";
			var tDef_name = 'seqPos';
			var length	 = 4 * 128;
			var numSteps = 2;
			var curve	 = 0;
			var env 	 = Env.new(0 ! numSteps);

			var envView  = EnvelopeView.new(seqView, Rect(10, offY + 0, 800, 120)).setEnv(env).keepHorizontalOrder_(true).action_({|item|
				env = asEnv.value(item, curve);
			}).gridOn_(true).grid_(0.0625@0.1);

			var text = StaticText.new(seqView, Rect(820, offY + 0, 80, 20)).string_(name);

			var button 	= Button.new(seqView, Rect(820, offY + 30, 80, 40)).states_([
				[">", Color.black, Color.white],
				["#" , Color.black, Color.white]
			]).action_{|item|
				if(item.value > 0, {Tdef(tDef_name).play;}, { Tdef(tDef_name).stop; })
			};

			var cur	 = EZKnob.new(seqView, Rect(920, offY + 30, 40, 80), "Curve", [-12, 12, 'lin', 0, 0], {|item|
				curve = item.value;
				envView.curves = curve;
				env = asEnv.value(envView, curve);
			});

			var steps	= EZNumber.new(seqView, Rect(870, offY + 70, 45, 40), "Steps", [2, 16, 'lin', 1, numSteps], {|item|
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

			var speed = EZNumber.new(seqView, Rect(820, offY + 70, 45, 40), "Length", [0.25, 32, 'lin', 0.25, 4], {|item|
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

			var envView  = EnvelopeView.new(seqView, Rect(10, offY + 0, 800, 120)).setEnv(env).keepHorizontalOrder_(true).action_({|item|
				env = asEnv.value(item, curve);
			}).gridOn_(true).grid_(0.0625@0.1);

			var text = StaticText.new(seqView, Rect(820, offY + 0, 80, 20)).string_(name);

			var button 	= Button.new(seqView, Rect(820, offY + 30, 80, 40)).states_([
				[">", Color.black, Color.white],
				["#" , Color.black, Color.white]
			]).action_{|item|
				if(item.value > 0, {Tdef(tDef_name).play;}, { Tdef(tDef_name).stop; })
			};

			var cur	 = EZKnob.new(seqView, Rect(920, offY + 30, 40, 80), "Curve", [-12, 12, 'lin', 0, 0], {|item|
				curve = item.value;
				envView.curves = curve;
				env = asEnv.value(envView, curve);
			});

			var steps	= EZNumber.new(seqView, Rect(870, offY + 70, 45, 40), "Steps", [2, 16, 'lin', 1, numSteps], {|item|
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

			var speed = EZNumber.new(seqView, Rect(820, offY + 70, 45, 40), "Length", [0.25, 32, 'lin', 0.25, 4], {|item|
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

			var envView  = EnvelopeView.new(seqView, Rect(10, offY + 0, 800, 120)).setEnv(env).keepHorizontalOrder_(true).action_({|item|
				env = asEnv.value(item, curve);
			}).gridOn_(true).grid_(0.0625@0.1);

			var text = StaticText.new(seqView, Rect(820, offY + 0, 80, 20)).string_(name);

			var button 	= Button.new(seqView, Rect(820, offY + 30, 80, 40)).states_([
				[">", Color.black, Color.white],
				["#" , Color.black, Color.white]
			]).action_{|item|
				if(item.value > 0, {Tdef(tDef_name).play;}, { Tdef(tDef_name).stop; })
			};

			var cur	 = EZKnob.new(seqView, Rect(920, offY + 30, 40, 80), "Curve", [-12, 12, 'lin', 0, 0], {|item|
				curve = item.value;
				envView.curves = curve;
				env = asEnv.value(envView, curve);
			});

			var steps	= EZNumber.new(seqView, Rect(870, offY + 70, 45, 40), "Steps", [2, 16, 'lin', 1, numSteps], {|item|
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

			var speed = EZNumber.new(seqView, Rect(820, offY + 70, 45, 40), "Length", [0.25, 32, 'lin', 0.25, 4], {|item|
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

			var envView  = EnvelopeView.new(seqView, Rect(10, offY + 0, 800, 120)).setEnv(env).keepHorizontalOrder_(true).action_({|item|
				env = asEnv.value(item, curve);
			}).gridOn_(true).grid_(0.0625@0.1);

			var text = StaticText.new(seqView, Rect(820, offY + 0, 80, 20)).string_(name);

			var button 	= Button.new(seqView, Rect(820, offY + 30, 80, 40)).states_([
				[">", Color.black, Color.white],
				["#" , Color.black, Color.white]
			]).action_{|item|
				if(item.value > 0, {Tdef(tDef_name).play;}, { Tdef(tDef_name).stop; })
			};

			var cur	 = EZKnob.new(seqView, Rect(920, offY + 30, 40, 80), "Curve", [-12, 12, 'lin', 0, 0], {|item|
				curve = item.value;
				envView.curves = curve;
				env = asEnv.value(envView, curve);
			});

			var steps	= EZNumber.new(seqView, Rect(870, offY + 70, 45, 40), "Steps", [2, 16, 'lin', 1, numSteps], {|item|
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

			var speed = EZNumber.new(seqView, Rect(820, offY + 70, 45, 40), "Length", [0.25, 32, 'lin', 0.25, 4], {|item|
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

			var envView  = EnvelopeView.new(seqView, Rect(10, offY + 0, 800, 120)).setEnv(env).keepHorizontalOrder_(true).action_({|item|
				env = asEnv.value(item, curve);
			}).gridOn_(true).grid_(0.0625@0.1);

			var text = StaticText.new(seqView, Rect(820, offY + 0, 80, 20)).string_(name);

			var button 	= Button.new(seqView, Rect(820, offY + 30, 80, 40)).states_([
				[">", Color.black, Color.white],
				["#" , Color.black, Color.white]
			]).action_{|item|
				if(item.value > 0, {Tdef(tDef_name).play;}, { Tdef(tDef_name).stop; })
			};

			var cur	 = EZKnob.new(seqView, Rect(920, offY + 30, 40, 80), "Curve", [-12, 12, 'lin', 0, 0], {|item|
				curve = item.value;
				envView.curves = curve;
				env = asEnv.value(envView, curve);
			});

			var steps	= EZNumber.new(seqView, Rect(870, offY + 70, 45, 40), "Steps", [2, 16, 'lin', 1, numSteps], {|item|
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

			var speed = EZNumber.new(seqView, Rect(820, offY + 70, 45, 40), "Length", [0.25, 32, 'lin', 0.25, 4], {|item|
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

			var envView  = EnvelopeView.new(seqView, Rect(10, offY + 0, 800, 120)).setEnv(env).keepHorizontalOrder_(true).action_({|item|
				env = asEnv.value(item, curve);
			}).gridOn_(true).grid_(0.0625@0.1);

			var text = StaticText.new(seqView, Rect(820, offY + 0, 80, 20)).string_(name);

			var button 	= Button.new(seqView, Rect(820, offY + 30, 80, 40)).states_([
				[">", Color.black, Color.white],
				["#" , Color.black, Color.white]
			]).action_{|item|
				if(item.value > 0, {Tdef(tDef_name).play;}, { Tdef(tDef_name).stop; })
			};

			var cur	 = EZKnob.new(seqView, Rect(920, offY + 30, 40, 80), "Curve", [-12, 12, 'lin', 0, 0], {|item|
				curve = item.value;
				envView.curves = curve;
				env = asEnv.value(envView, curve);
			});

			var steps	= EZNumber.new(seqView, Rect(870, offY + 70, 45, 40), "Steps", [2, 16, 'lin', 1, numSteps], {|item|
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

			var speed = EZNumber.new(seqView, Rect(820, offY + 70, 45, 40), "Length", [0.25, 32, 'lin', 0.25, 4], {|item|
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

			var envView  = EnvelopeView.new(seqView, Rect(10, offY + 0, 800, 120)).setEnv(env).keepHorizontalOrder_(true).action_({|item|
				env = asEnv.value(item, curve);
			}).gridOn_(true).grid_(0.0625@0.1);

			var text = StaticText.new(seqView, Rect(820, offY + 0, 80, 20)).string_(name);

			var button 	= Button.new(seqView, Rect(820, offY + 30, 80, 40)).states_([
				[">", Color.black, Color.white],
				["#" , Color.black, Color.white]
			]).action_{|item|
				if(item.value > 0, {Tdef(tDef_name).play;}, { Tdef(tDef_name).stop; })
			};

			var cur	 = EZKnob.new(seqView, Rect(920, offY + 30, 40, 80), "Curve", [-12, 12, 'lin', 0, 0], {|item|
				curve = item.value;
				envView.curves = curve;
				env = asEnv.value(envView, curve);
			});

			var steps	= EZNumber.new(seqView, Rect(870, offY + 70, 45, 40), "Steps", [2, 16, 'lin', 1, numSteps], {|item|
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

			var speed = EZNumber.new(seqView, Rect(820, offY + 70, 45, 40), "Length", [0.25, 32, 'lin', 0.25, 4], {|item|
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

			var envView  = EnvelopeView.new(seqView, Rect(10, offY + 0, 800, 120)).setEnv(env).keepHorizontalOrder_(true).action_({|item|
				env = asEnv.value(item, curve);
			}).gridOn_(true).grid_(0.0625@0.1);

			var text = StaticText.new(seqView, Rect(820, offY + 0, 80, 20)).string_(name);

			var button 	= Button.new(seqView, Rect(820, offY + 30, 80, 40)).states_([
				[">", Color.black, Color.white],
				["#" , Color.black, Color.white]
			]).action_{|item|
				if(item.value > 0, {Tdef(tDef_name).play;}, { Tdef(tDef_name).stop; })
			};

			var cur	 = EZKnob.new(seqView, Rect(920, offY + 30, 40, 80), "Curve", [-12, 12, 'lin', 0, 0], {|item|
				curve = item.value;
				envView.curves = curve;
				env = asEnv.value(envView, curve);
			});

			var steps	= EZNumber.new(seqView, Rect(870, offY + 70, 45, 40), "Steps", [2, 16, 'lin', 1, numSteps], {|item|
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

			var speed = EZNumber.new(seqView, Rect(820, offY + 70, 45, 40), "Length", [0.25, 32, 'lin', 0.25, 4], {|item|
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

			var envView  = EnvelopeView.new(seqView, Rect(10, offY + 0, 800, 120)).setEnv(env).keepHorizontalOrder_(true).action_({|item|
				env = asEnv.value(item, curve);
			}).gridOn_(true).grid_(0.0625@0.1);

			var text = StaticText.new(seqView, Rect(820, offY + 0, 80, 20)).string_(name);

			var button 	= Button.new(seqView, Rect(820, offY + 30, 80, 40)).states_([
				[">", Color.black, Color.white],
				["#" , Color.black, Color.white]
			]).action_{|item|
				if(item.value > 0, {Tdef(tDef_name).play;}, { Tdef(tDef_name).stop; })
			};

			var cur	 = EZKnob.new(seqView, Rect(920, offY + 30, 40, 80), "Curve", [-12, 12, 'lin', 0, 0], {|item|
				curve = item.value;
				envView.curves = curve;
				env = asEnv.value(envView, curve);
			});

			var steps	= EZNumber.new(seqView, Rect(870, offY + 70, 45, 40), "Steps", [2, 16, 'lin', 1, numSteps], {|item|
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

			var speed = EZNumber.new(seqView, Rect(820, offY + 70, 45, 40), "Length", [0.25, 32, 'lin', 0.25, 4], {|item|
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

			var envView  = EnvelopeView.new(seqView, Rect(10, offY + 0, 800, 120)).setEnv(env).keepHorizontalOrder_(true).action_({|item|
				env = asEnv.value(item, curve);
			}).gridOn_(true).grid_(0.0625@0.1);

			var text = StaticText.new(seqView, Rect(820, offY + 0, 80, 20)).string_(name);

			var button 	= Button.new(seqView, Rect(820, offY + 30, 80, 40)).states_([
				[">", Color.black, Color.white],
				["#" , Color.black, Color.white]
			]).action_{|item|
				if(item.value > 0, {Tdef(tDef_name).play;}, { Tdef(tDef_name).stop; })
			};

			var cur	 = EZKnob.new(seqView, Rect(920, offY + 30, 40, 80), "Curve", [-12, 12, 'lin', 0, 0], {|item|
				curve = item.value;
				envView.curves = curve;
				env = asEnv.value(envView, curve);
			});

			var steps	= EZNumber.new(seqView, Rect(870, offY + 70, 45, 40), "Steps", [2, 16, 'lin', 1, numSteps], {|item|
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

			var speed = EZNumber.new(seqView, Rect(820, offY + 70, 45, 40), "Length", [0.25, 32, 'lin', 0.25, 4], {|item|
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
	};
	win.front;
}.value;
)
