package haxe;
#if (macro || (!neko && !cpp))


// Original haxe.Timer class

class Timer {
	#if (neko || php || cpp)
	#else

	private var id : Null<Int>;

	/**
		Create a new timer that will run every [time_ms] (in milliseconds).
	**/
	public function new( time_ms : Int ){
		#if flash9
			var me = this;
			id = untyped __global__["flash.utils.setInterval"](function() { me.run(); },time_ms);
		#elseif flash
			var me = this;
			id = untyped _global["setInterval"](function() { me.run(); },time_ms);
		#elseif js
			var me = this;
			id = untyped window.setInterval(function() me.run(),time_ms);
		#end
	}

	/**
		Stop the timer definitely.
	**/
	public function stop() {
		if( id == null )
			return;
		#if flash9
			untyped __global__["flash.utils.clearInterval"](id);
		#elseif flash
			untyped _global["clearInterval"](id);
		#elseif js
			untyped window.clearInterval(id);
		#end
		id = null;
	}

	/**
		This is the [run()] method that is called when the Timer executes. It can be either overriden in subclasses or directly rebinded with another function-value.
	**/
	public dynamic function run() {
	}

	/**
		This will delay the call to [f] for the given time. [f] will only be called once.
	**/
	public static function delay( f : Void -> Void, time_ms : Int ) {
		var t = new haxe.Timer(time_ms);
		t.run = function() {
			t.stop();
			f();
		};
		return t;
	}

	#end

	/**
		Measure the time it takes to execute the function [f] and trace it. Returns the value returned by [f].
	**/
	public static function measure<T>( f : Void -> T, ?pos : PosInfos ) : T {
		var t0 = stamp();
		var r = f();
		Log.trace((stamp() - t0) + "s", pos);
		return r;
	}

	/**
		Returns the most precise timestamp, in seconds. The value itself might differ depending on platforms, only differences between two values make sense.
	**/
	public static function stamp() : Float {
		#if flash
			return flash.Lib.getTimer() / 1000;
		#elseif (neko || php)
			return Sys.time();
		#elseif js
			return Date.now().getTime() / 1000;
		#elseif cpp
			return untyped __global__.__time_stamp();
		#else
			return 0;
		#end
	}

}


#else


class Timer {
	
	
	private static var sRunningTimers:Array <Timer> = [];
	
	private var mTime:Float;
	private var mFireAt:Float;
	private var mRunning:Bool;
	
	
	public function new (time:Float) {
		
		mTime = time;
		sRunningTimers.push (this);
		mFireAt = getMS () + mTime;
		mRunning = true;
		
	}
	
	
	public static function delay (f:Void -> Void, time:Int) {
		
		var t = new Timer (time);
		
		t.run = function () {
			
			t.stop ();
			f ();
			
		};
		
		return t;
		
	}
	
	
	private static function getMS ():Float {
		
		return stamp () * 1000.0;
		
	}
	
	
	public static function measure<T> (f:Void -> T, ?pos:PosInfos):T {
		
		var t0 = stamp ();
		var r = f ();
		Log.trace ((stamp () - t0) + "s", pos);
		return r;
		
	}
	
	
	dynamic public function run () {
		
		
		
	}
	
	
	public static function stamp ():Float {
		
		return lime_time_stamp ();
		
	}
	
	
	public function stop ():Void {
		
		if (mRunning) {
			
			mRunning = false;
			sRunningTimers.remove (this);
			
		}
		
	}
	

	@:noCompletion private function __check (inTime:Float) {
		
		if (inTime >= mFireAt) {
			
			mFireAt += mTime;
			run ();
			
		}
		
	}
	
	
	@:noCompletion public static function __checkTimers () {
		
		var now = getMS ();
		var index = 0;
		
		while (index < sRunningTimers.length) {
			
			sRunningTimers[index].__check (now);
			index++;
			
		}
		
	}
	
	
	@:noCompletion public static function __nextWake (limit:Float):Float {
		
		var now = lime_time_stamp () * 1000.0;
		var sleep;
		
		for (timer in sRunningTimers) {
			
			sleep = timer.mFireAt - now;
			
			if (sleep < limit) {
				
				limit = sleep;
				
				if (limit < 0) {
					
					return 0;
					
				}
				
			}
			
		}
		
		return limit * 0.001;
		
	}
	
	
	
	
	// Native Methods
	
	
	
	
	static var lime_time_stamp = flash.Lib.load ("lime", "lime_time_stamp", 0);
	
	
}


#end