package;

import datetime.DateTime;
import WorklogUtils;

using api.IdeckiaApi;

typedef Props = {
	@:editable("Do you want to change the color when you are working and when you are not?", true)
	var set_color:Bool;
	@:editable("Color definitions", {working: 'ff00aa00', not_working: 'ffaa0000'})
	var color:{working:String, not_working:String};
	@:editable("What is the directory where the log files are stored?", '.')
	var logs_directory:String;
	@:editable("How many hours do you work on a day?", 8)
	var work_hours:UInt;
	@:editable("How many minutes do you need to have lunch?", 60)
	var lunch_minutes:UInt;
	@:editable("Round to the neares quarter? e.g. 15:04 will be stored as 15:00 (and 16:10 -> 16:15) ", true)
	var round_to_quarter:Bool;
}

@:name('worklog')
@:description('Log you daily work in a plain json file.')
class Worklog extends IdeckiaAction {
	function initDay():DayData {
		var localNow = DateTime.local();
		var minuteModulo = Std.int((props.work_hours % 1) * 60);
		var exitTime = localNow.add(Hour(Std.int(props.work_hours))).add(Minute(minuteModulo + props.lunch_minutes));
		var startTime = getRounded(localNow);

		return {
			day: localNow,
			exitTime: exitTime,
			tasks: [
				{
					start: startTime
				}
			]
		};
	}

	override public function init(initialState:ItemState):js.lib.Promise<ItemState> {
		return new js.lib.Promise((resolve, reject) -> {
			if (props.set_color)
				initialState.bgColor = props.color.working;

			var data:Array<DayData> = WorklogUtils.parse(WorklogUtils.getCurrentWeekFilePath(props.logs_directory));
			if (data.length > 0) {
				if (data[data.length - 1].day.equals(DateTime.local())) {
					resolve(initialState);
					return;
				}
			}

			data.push(initDay());

			WorklogUtils.saveToFile(WorklogUtils.getCurrentWeekFilePath(props.logs_directory), data);

			resolve(initialState);
		});
	}

	public function execute(currentState:ItemState):js.lib.Promise<ItemState> {
		return processData(currentState, parseFile());
	}

	override public function onLongPress(currentState:ItemState) {
		return new js.lib.Promise((resolve, reject) -> {
			var data = parseFile();
			var todayData:DayData = data[data.length - 1];
			if (todayData != null && todayData.tasks != null && todayData.tasks.length > 0) {
				final todayTasks:Array<Task> = todayData.tasks;

				var lastTask = todayTasks[todayTasks.length - 1];
				var acc:Time = calculateDayAccumulatedTime(todayTasks);
				if (lastTask.finish == null) {
					var now = getRounded(DateTime.local());
					var unregisteredTaskTime = now.add(Second(-Std.int(lastTask.start.getTotalSeconds())));
					acc = acc.add(Hour(unregisteredTaskTime.getHour())).add(Minute(unregisteredTaskTime.getMinute()));
				}
				server.dialog.info('Worklog info', 'Worked time: $acc');
			}

			resolve(currentState);
		});
	}

	function parseFile():Array<DayData> {
		var dailyContent:Array<DayData> = WorklogUtils.parse(WorklogUtils.getCurrentWeekFilePath(props.logs_directory));
		if (dailyContent.length == 0) {
			dailyContent.push(initDay());
		}

		return dailyContent;
	}

	function calculateDayAccumulatedTime(todayTasks:Array<Task>) {
		var acc = new DateTime(0);
		for (task in todayTasks)
			if (task.time != null)
				acc = acc.add(Hour(task.time.getHour())).add(Minute(task.time.getMinute()));
		return acc;
	}

	function processData(currentState:ItemState, data:Array<DayData>) {
		return new js.lib.Promise((resolve, reject) -> {
			final localNow = DateTime.local();
			var todayData:DayData = data[data.length - 1];
			if (!todayData.day.equals(localNow)) {
				todayData = initDay();
				todayData.tasks = [];
				data.push(todayData);
			}

			final todayTasks:Array<Task> = todayData.tasks;

			todayTasks.sort((z1, z2) -> Std.int(z1.start.getTotalSeconds() - z2.start.getTotalSeconds()));
			var lastTask = todayTasks.pop();
			if (lastTask == null || lastTask.finish != null) {
				if (lastTask != null)
					todayTasks.push(lastTask);

				todayTasks.push({
					start: getRounded(localNow)
				});

				WorklogUtils.saveToFile(WorklogUtils.getCurrentWeekFilePath(props.logs_directory), data);

				if (props.set_color)
					currentState.bgColor = props.color.working;

				resolve(currentState);
			} else {
				lastTask.finish = getRounded(localNow);
				lastTask.time = lastTask.finish.add(Second(-Std.int(lastTask.start.getTotalSeconds())));

				server.dialog.custom(haxe.io.Path.join([js.Node.__dirname, 'dialog.json'])).then(response -> {
					switch response {
						case Some(values):
							for (v in values) {
								if (v.id == 'task')
									lastTask.work = v.value;
								if (v.id == 'description' && v.value != '')
									lastTask.description = v.value;
							}
							todayTasks.push(lastTask);
							todayData.totalTime = calculateDayAccumulatedTime(todayTasks);
							todayData.tasks = todayTasks;

							server.dialog.info('Worklog info', 'Worked time: ${todayData.totalTime}');

							if (props.set_color)
								currentState.bgColor = props.color.not_working;

							WorklogUtils.saveToFile(WorklogUtils.getCurrentWeekFilePath(props.logs_directory), data);

							resolve(currentState);
						case None:
					}
				}).catchError(reject);
			}
		});
	}

	inline function getRounded(time:DateTime) {
		return (props.round_to_quarter) ? WorklogUtils.roundedTime(time) : time;
	}
}
