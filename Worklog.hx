package;

import datetime.DateTime;

using Types;
using api.IdeckiaApi;

typedef Props = {
	@:editable("Do you want to change the color when you are working and when you are not?", true)
	var setColor:Bool;
	@:editable("Color definitions", {working: 'ff00aa00', notWorking: 'ffaa0000'})
	var color:{working:String, notWorking:String};
	@:editable("Where is the log?", 'worklog.json')
	var filePath:String;
	@:editable("How many hours do you work on a day?", 8)
	var workHours:UInt;
	@:editable("How many minutes do you need to have lunch?", 60)
	var lunchMinutes:UInt;
}

@:name('worklog')
class Worklog extends IdeckiaAction {
	static public inline var DAY_FORMAT = '%F';
	static public inline var TIME_FORMAT = '%H:%M';
	static public inline var JSON_SPACE = '    ';

	function initDay():DayDataJson {
		var localNow = DateTime.local();
		var minuteModulo = Std.int((props.workHours % 1) * 60);
		var exitTime = localNow.add(Hour(Std.int(props.workHours))).add(Minute(minuteModulo + props.lunchMinutes));

		return {
			day: localNow.format(DAY_FORMAT),
			exitTime: exitTime.format(TIME_FORMAT),
			tasks: [
				{
					start: nearestQuarter(localNow).format(TIME_FORMAT)
				}
			]
		};
	}

	override public function init(initialState:ItemState):js.lib.Promise<ItemState> {
		return new js.lib.Promise((resolve, reject) -> {
			if (props.setColor)
				initialState.bgColor = props.color.working;

			var data:Array<DayDataJson> = haxe.Json.parse(try sys.io.File.getContent(props.filePath) catch (e:haxe.Exception) '[]');
			if (data.length > 0) {
				if (data[data.length - 1].day == DateTime.local().format(DAY_FORMAT)) {
					resolve(initialState);
					return;
				}
			}

			data.push(initDay());

			sys.io.File.saveContent(props.filePath, haxe.Json.stringify(data, JSON_SPACE));

			resolve(initialState);
		});
	}

	public function execute(currentState:ItemState):js.lib.Promise<ItemState> {
		return processData(currentState, parseFile());
	}

	function parseFile():Array<DayData> {
		var dailyContent:Array<DayDataJson> = haxe.Json.parse(try sys.io.File.getContent(props.filePath) catch (e:haxe.Exception) '[]');
		if (dailyContent.length == 0) {
			dailyContent.push(initDay());
		}

		return dailyContent.map(parseDayDataJson);
	}

	function parseDayDataJson(stringData:DayDataJson):DayData {
		inline function stringToDateTime(s:String) {
			if (s == null)
				return null;
			var zero = new DateTime(0);
			var sp = s.split(':');
			return nearestQuarter(zero.add(Hour(Std.parseInt(sp[0]))).add(Minute(Std.parseInt(sp[1]))));
		}
		var item:DayData = {
			day: DateTime.fromString(stringData.day),
			totalTime: stringToDateTime(stringData.totalTime),
			exitTime: stringToDateTime(stringData.exitTime)
		};
		if (stringData.tasks != null) {
			item.tasks = [];
			for (t in stringData.tasks) {
				item.tasks.push({
					start: stringToDateTime(t.start),
					finish: stringToDateTime(t.finish),
					time: stringToDateTime(t.time),
					work: t.work
				});
			}
		}
		return item;
	}

	function processData(currentState:ItemState, data:Array<DayData>) {
		return new js.lib.Promise((resolve, reject) -> {
			final localNow = DateTime.local();
			var lastData:DayData = data[data.length - 1];
			if (lastData == null)
				lastData = {
					day: localNow,
					totalTime: 0,
					exitTime: localNow
				};

			final todayTasks:Array<Task> = lastData.tasks == null ? [] : lastData.tasks;

			todayTasks.sort((z1, z2) -> Std.int(z1.start.getTime() - z2.start.getTime()));
			var lastTask = todayTasks.pop();
			if (lastTask == null || lastTask.finish != null) {
				if (lastTask != null)
					todayTasks.push(lastTask);

				todayTasks.push({
					start: nearestQuarter(localNow)
				});

				saveToFile(data);

				if (props.setColor)
					currentState.bgColor = props.color.working;

				resolve(currentState);
			} else {
				lastTask.finish = nearestQuarter(localNow);
				lastTask.time = lastTask.finish.add(Second(-Std.int(lastTask.start.getTime())));

				var acc = new DateTime(0);
				for (task in todayTasks) {
					acc = acc.add(Hour(task.time.getHour())).add(Minute(task.time.getMinute()));
				}

				server.dialog.entry('What where you doing?').then(returnValue -> {
					if (returnValue != '') {
						lastTask.work = returnValue;
						acc = acc.add(Hour(lastTask.time.getHour())).add(Minute(lastTask.time.getMinute()));
						lastData.totalTime = acc;
						todayTasks.push(lastTask);
						lastData.tasks = todayTasks;

						server.dialog.info('Worked time: ${acc.format(TIME_FORMAT)}').catchError(reject);

						if (props.setColor)
							currentState.bgColor = props.color.notWorking;

						saveToFile(data);

						resolve(currentState);
					}
				}).catchError(reject);
			}
		});
	}

	function saveToFile(data:Array<DayData>) {
		inline function toTimeFormat(dt:DateTime) {
			if (dt == null)
				return null;
			return dt.format(TIME_FORMAT);
		}

		var fileContent = [];
		var dataJson:DayDataJson;
		for (e in data) {
			dataJson = {
				day: e.day.format(DAY_FORMAT),
				totalTime: toTimeFormat(e.totalTime),
				exitTime: toTimeFormat(e.exitTime)
			};
			if (e.tasks != null) {
				dataJson.tasks = [];
				for (t in e.tasks) {
					dataJson.tasks.push({
						start: toTimeFormat(t.start),
						finish: toTimeFormat(t.finish),
						time: toTimeFormat(t.time),
						work: t.work
					});
				}
			}
			fileContent.push(dataJson);
		}

		sys.io.File.saveContent(props.filePath, haxe.Json.stringify(fileContent, JSON_SPACE));
	}

	function nearestQuarter(time:DateTime) {
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
}
