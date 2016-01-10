~grnlrPar = (
	pos:				0,
	dur:        	1,
	fillFactor: 	1,

	trans:      	0,
	dir:				1,
	vol:      	 	1,
	pan:        	0,
	hall:       	0,

	filtFreqLo:		20000,
	filtFreqHi:		20,
	qLo:    	    	1,
	qHi:    	    	1,

	ampArr:			[0,1,1,0],
	timeArr:			[0.3,0.3,0.3],
	envCurve:		-2,

	rAmp: 	   	0,
	rPos:	   		0,
	rPitch:			0,
	rFill:			0,
	rDur:				0,

	posMod: 			1,
	ampMod: 			0,
	pitchMod:		0,
	fillMod:			0,
	durMod:			0,

	rPosMod:			0,
	rAmpMod:			0,
	rPitchMod:		0,
	rFillMod:		0,
	rDurMod:			0,

	dur:				0.1,

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

Tdef(\grnlr, {
	var dur;
	loop{
		var rDur = rand(~grnlrPar.rDur);
		var dur = (~grnlrPar.dur + rand(rDur.neg, rDur)) + (~grnlrSeq.dur * ~grnlrPar.durMod);
		if(~grnlrPar.toggle > 0, {
			Synth(\grnlr, [
				\pos,        	~grnlrPar.pos + (~grnlrSeq.pos * ~grnlrPar.posMod),
				\trans,      	~grnlrPar.trans + (~grnlrSeq.pitch * ~grnlrPar.pitchMod),
				\dir,        	[-1, 1].wchoose([~grnlrPar.dir.linlin(-1, 1, 1, 0), ~grnlrPar.dir.linlin(-1, 1, 0, 1)]),
				\vol,        	~grnlrPar.vol * (~grnlrSeq.amp.linlin(0, 1, ~grnlrPar.ampMod.linlin(0,1,1,0), 1)),
				\pan,        	~grnlrPar.pan,
				\send,       	~grnlrPar.send,

				\filtFreqLo, 	~grnlrPar.filtFreqLo,
				\filtFreqHi, 	~grnlrPar.filtFreqHi,
				\qLo,        	~grnlrPar.qLo,
				\qHi,        	~grnlrPar.qHi,

				\ampArr,			~grnlrPar.ampArr,
				\timeArr,		~grnlrPar.timeArr.normalizeSum,

				\envCurve,		~grnlrPar.envCurve,

				\rAmp,      	~grnlrPar.rAmp,
				\rPos,      	~grnlrPar.rPos,
				\rPitch,    	~grnlrPar.rPitch,
				\rFill,     	~grnlrPar.rFill,

				\fillFactor,	~grnlrPar.fillFactor + (~grnlrSeq.fill * ~grnlrPar.fillMod),
				\dur, 			dur

			]);
		});
		dur.clip(0.001, 2).wait;
	};
}).play;