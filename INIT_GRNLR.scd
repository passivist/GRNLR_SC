(
~loadGRNLR = {
	// Initialize some variables we need
	if(~clock.isNil){~clock = TempoClock.default};
	if(~send.isNil){ ~send = Bus.audio(s, 2) };
	if(~grnlr_bus.isNil){ ~grnlr_bus = Bus.audio(s, 2) };
	if(~grndl_bus.isNil){ ~grndl_bus = Bus.audio(s, 2) };
	if(~outBus.isNil){ [0, 1] }; // default to first stereo output

	loadRelative("GRNLR_GUI.scd");
}.value;
)