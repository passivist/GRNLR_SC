SynthDef(\grnlr, {
	arg out, looperBus, hallBus, delayBus,
	pos, trans, dir, vol, pan, send, delay,
	rPitch, rAmp, rPos, rFill,
	filtFreqLo, filtFreqHi, qLo, qHi,
	ampArr=#[0,1,1,0], timeArr=#[1,1,1], envCurve,
	fillFactor=1, dur,
	buf=0;

	var win, sig, randPos, randAmp, randPitch, randFill, env;

	// Randomization
	randPos   = [Rand(-0.5, 0.5), Rand(-0.5, 0.5)] * rPos;
	randAmp   = [Rand(-0.5, 0.5), Rand(-0.5, 0.5)] * rAmp;
	randPitch = [Rand(-12, 12),   Rand(-12, 12)]   * rPitch;
	randFill  = [Rand(0, 1),      Rand(0, 1)]      * rFill;

	// pitch
	trans = (trans + randPitch).midiratio;

	// density
	fillFactor = fillFactor * (randFill + 1);

	// volume
	vol = vol + randAmp;

	// position
	pos = (pos + randPos).wrap(0, 1);
	pos = pos.wrap(0,1);

	// Envelope
	env = Env.new(ampArr, timeArr * (fillFactor * dur), [envCurve, 0, (envCurve * (-1))] );
	win = EnvGen.kr(env, doneAction: 2); // grain Window
	// kernel
	sig = PlayBuf.ar(
		2, buf, (trans * dir),
		startPos: pos * BufFrames.kr(buf) ,
	);

	// filter
	sig = RLPF.ar(sig, filtFreqLo, qLo).tanh;
	sig = RHPF.ar(sig, filtFreqHi, qHi).tanh;

	sig = LeakDC.ar(sig);
	sig = Balance2.ar(sig[0], sig[1], pan, -6.dbamp);
	sig = (sig * win);

	OffsetOut.ar(delayBus, sig * delay); // delay Send

	sig = sig * vol;

	OffsetOut.ar(hallBus, sig * send); // Hall Send
	OffsetOut.ar(out, sig);
}).add;