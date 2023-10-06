package;

import datetime.DateTime;

class WorklogUtils {
	static public inline var DAY_FORMAT = '%F';
	static public inline var TIME_FORMAT = '%H:%M';
	static inline var JSON_SPACE = '    ';

	static public function parse(filePath:String):Array<DayData> {
		return haxe.Json.parse(try sys.io.File.getContent(filePath) catch (e:haxe.Exception) '[]');
	}

	static public function roundedTime(time:DateTime) {
		var minsInHour = 60;
		var quarter = minsInHour * .25;

		var hour = time.getHour();
		var timeMinute = time.getMinute();
		var minute = Math.round((Math.round(timeMinute / quarter) * quarter));
		if (minute > minsInHour) {
			minute = 0;
			if (minute > timeMinute)
				hour++;
		}

		var newTime = new DateTime(0);
		return newTime.add(Hour(hour)).add(Minute(minute));
	}

	static public function saveToFile(filePath:String, data:Array<DayData>) {
		sys.io.File.saveContent(filePath, haxe.Json.stringify(data, JSON_SPACE));
	}

	static public function getCurrentWeekFilePath(logsDirectory:String):String {
		var currentWeek = DateTime.local().getWeek();
		return haxe.io.Path.join([logsDirectory, 'worklog_${currentWeek}.json']);
	}
}

typedef DayData = {
	var day:Day;
	var exitTime:Time;
	var ?totalTime:Time;
	var ?tasks:Array<Task>;
}

typedef Task = {
	var start:Time;
	var ?finish:Time;
	var ?time:Time;
	var ?work:String;
	var ?description:String;
}

abstract Day(String) {
	inline function new(s:String)
		this = s;

	public function getWeek()
		return toDateTime().getWeek();

	public function equals(dateTime:DateTime)
		return this == dateTime.format(WorklogUtils.DAY_FORMAT);

	@:to
	public function toDateTime()
		return DateTime.fromString(this);

	@:from
	static public function fromDateTime(dateTime:DateTime) {
		return new Day(dateTime.format(WorklogUtils.DAY_FORMAT));
	}
}

abstract Time(String) {
	inline function new(s:String)
		this = s;

	function splitHourMinute() {
		if (this == null)
			return [0, 0];
		return this.split(':').map(c -> (c == '') ? 0 : Std.parseInt(c));
	}

	public function getHour()
		return splitHourMinute()[0];

	public function getMinute()
		return splitHourMinute()[1];

	public function getTotalSeconds()
		return toDateTime().getTime();

	public function add(period:DTPeriod)
		return Time.fromDateTime(toDateTime().add(period));

	@:to
	public function toDateTime() {
		var sp = splitHourMinute();
		var zero = new DateTime(0);
		return zero.add(Hour(sp[0])).add(Minute(sp[1]));
	}

	@:from
	static public function fromDateTime(dateTime:DateTime)
		return new Time(dateTime.format(WorklogUtils.TIME_FORMAT));

	@:from
	static public function fromInt(int:Int)
		return Time.fromDateTime(new DateTime(int));
}
