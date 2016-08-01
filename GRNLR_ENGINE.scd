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

					rAmp = ~grVar.grnlr.rAmp.value;
					rPos = ~grVar.grnlr.rPos.value;
					rPitch = ~grVar.grnlr.rPitch.value;
					rFill = ~grVar.grnlr.rFill.value;

					pos = ~grVar.grnlr.pos.value;
					pos = pos + (~grVar[\seqPos].val * ~grVar.grnlr.posMod.value);
					//pos = pos + ((~joy.slot(3, 0).value - 0.5) * ~grVar.grnlr.joyAmt.value);
					pos = pos.wrap(0, 1);
					~pos = pos;

					dir = ~grVar.grnlr.dir.value;
					dir = [-1, 1].wchoose([dir.linlin(-1, 1, 1, 0), dir.linlin(-1, 1, 0, 1)]);

					trans = ~grVar.grnlr.pitch.value + (~grVar[\seqPitch].val * ~grVar.grnlr.pitchMod.value);
					trans = trans + (~notes.choose - 60);

					vol = ~grVar.grnlr.vol.value;
					vol = vol * (~grVar[\seqAmp].val.linlin(0, 1, ~grVar.grnlr.ampMod.value.linlin(0,1,1,0), 1));

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

					fillFactor = ~grVar.grnlr.fillFactor.value;
					fillFactor = fillFactor + (~grVar[\seqFill].val * ~grVar.grnlr.fillMod.value);
					dur = ~grVar.grnlr.dur.value;
					dur = dur * (~grVar.grnlr.rDur.value.rand + (1 - (~grVar.grnlr.rDur.value / 2)) );

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

						\ampArr,		ampArr,
						\timeArr,		timeArr,
						\envCurve,		envCurve,

						\rAmp,      	rAmp,
						\rPos,      	rPos,
						\rPitch,    	rPitch,
						\rFill,     	rFill,

						\fillFactor,	fillFactor,

						\dur, 			dur,

						\buf,           ~grVar.grnlr.buffer,

						\hallBus,       ~send,
						\delayBus,      ~grndl_bus,
						\looperBus,     ~grnlr_bus,
						\outBus,        ~outBus
					]);
				};
			}.defer;
			dur.clip(0.01, 2).wait;
		};
	}).play;

	~firstNote = nil;
	~notes = (60: 60);

	MIDIdef.noteOn(\noteOn, {|vel, note|
		"WHAT".postln;
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
