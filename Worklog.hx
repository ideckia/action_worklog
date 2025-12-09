package;

import WorklogUtils;
import datetime.DateTime;

using api.IdeckiaApi;
using StringTools;

typedef Props = {
	@:editable("prop_change_color", true)
	var set_color:Bool;
	@:editable("prop_color_def", {working: 'ff00aa00', not_working: 'ffaa0000'})
	var color:{working:String, not_working:String};
	@:editable("prop_logs_directory", '.')
	var logs_directory:String;
	@:editable("prop_work_hours", 8)
	var work_hours:UInt;
	@:editable("prop_lunch_minutes", 60)
	var lunch_minutes:UInt;
	@:editable("prop_round_to_quarter", true)
	var round_to_quarter:Bool;
}

@:name('worklog')
@:description('action_description')
@:localize
class Worklog extends IdeckiaAction {
	static inline var PREVIOUS_WORK:String = '_prev_';

	function initDay():DayData {
		var localNow = DateTime.local();
		var minuteModulo = Std.int((props.work_hours % 1) * 60);
		var exitTime = localNow.add(Hour(Std.int(props.work_hours))).add(Minute(minuteModulo + props.lunch_minutes));
		var startTime = getRounded(localNow);

		return {
			day: localNow,
			exitTime: exitTime,
			totalTime: 0,
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

	public function execute(currentState:ItemState):js.lib.Promise<ActionOutcome> {
		return new js.lib.Promise((resolve, reject) -> {
			processData(currentState, parseFile()).then(state -> {
				var data = parseFile();
				var todayData:DayData = data[data.length - 1];
				var totalTime = null;
				if (todayData != null && todayData.tasks != null && todayData.tasks.length > 0) {
					totalTime = calculateDayAccumulatedTime(todayData.tasks);
				}
				state.extraData = {
					data: {
						isWorking: state.bgColor == props.color.working,
						totalTime: totalTime
					}
				}
				resolve(new ActionOutcome({state: state}));
			}).catchError(reject);
		});
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

				core.dialog.info('Worklog info', Loc.worked_time_label.tr([acc]));
			}

			resolve(new ActionOutcome({state: currentState}));
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

				var locale = core.data.getCurrentLocale();
				var dialogPath = haxe.io.Path.join([js.Node.__dirname, 'dialog_$locale.json']);
				if (!sys.FileSystem.exists(dialogPath)) {
					dialogPath = haxe.io.Path.join([js.Node.__dirname, 'dialog_en_uk.json']);
				}

				core.dialog.custom(dialogPath).then(response -> {
					switch response {
						case Some(values):
							for (v in values) {
								if (v.id == 'task') {
									if (v.value == PREVIOUS_WORK) {
										if (todayTasks.length == 0) {
											core.dialog.error('Worklog error', Loc.error_no_previous_task.tr());
											resolve(currentState);
											return;
										}

										lastTask.work = todayTasks[todayTasks.length - 1].work;
									} else
										lastTask.work = v.value;
								}
								if (v.id == 'description' && v.value != '')
									lastTask.description = v.value;
							}
							todayTasks.push(lastTask);
							todayData.totalTime = calculateDayAccumulatedTime(todayTasks);
							todayData.tasks = todayTasks;

							core.dialog.info('Worklog info', Loc.worked_time_label_at.tr([todayData.totalTime, lastTask.finish, lastTask.work]));

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
