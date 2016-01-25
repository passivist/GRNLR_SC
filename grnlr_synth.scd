~loadSynth = {|buf, bus|
	SynthDef(\grnlr, {
		// arguments
		arg out,
		pos, trans, dir, vol, pan, send, delay,
		rPitch, rAmp, rPos, rFill,
		filtFreqLo, filtFreqHi, qLo, qHi,
		ampArr=#[0,1,1,0], timeArr=#[1,1,1], envCurve,
		fillFactor=1, dur,
		bufNum=0, bufLength=1200, numChans=2;

		// variables
		var win, sig, randPos, randAmp, randPitch, randFill, env;

		// Randomization
		randPos   = [Rand(-1, 1),     Rand(-1, 1)]     * rPos;
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
		env = Env.new(ampArr, timeArr.normalizeSum * (fillFactor * dur), [envCurve, 0, (envCurve * (-1))] );
		win = EnvGen.kr(env, doneAction: 2); // grain Window
		// kernel
		sig = PlayBuf.ar(
			buf.numChannels, buf.bufnum, (trans * dir),
			startPos: pos * buf.numFrames.postln ,
		);

		// filter
		sig = RLPF.ar(sig, filtFreqLo, qLo);
		sig = RHPF.ar(sig, filtFreqHi, qHi);

		sig = LeakDC.ar(sig);
		sig = (sig * win) * vol;

		sig = Splay.ar(sig, 1, center: pan, level: -6.dbamp); // panorama
		//Out.ar(~feedBus, sig * (randAmp.linlin(0, 1, 0.5, 0) * hall)); // Hall Send
		Out.ar(~send, sig * send); // Hall Send
		Out.ar(~grndl_bus, sig * send); // delay Send
		Out.ar(~grnlr_bus, sig); // To Looper
		Out.ar(~outBus, sig);
	}).add;
}