# Action for ideckia: Worklog

## Definition

Log in a JSON file your daily work. The path of this file can be configured with the `file_path` property.

* When this action is loaded it will create an entry for the day.
* In that entry, there will be stored
  * day (ex: 2021-06-24)
  * exit time: Based on when the entry was created and the properties `work_hours` and `lunch_minutes`, it will calculate at what time would you stop working.
  * tasks: An array which will be filled with the tasks you've done during the day. Every task seems like:
    * start: start time of the task
    * finish: finisth time of the task
    * time: calculated time between start and finish
    * work: description of what where you doing
  * totalTime: Time you've spent working (it is a sum of all the tasks times)

## Properties

| Name | Type | Default | Description | Possible values |
| ----- |----- | ----- | ----- | ----- |
| color | { working : String, not_working : String } | { working : 'ff00aa00', not_working : 'ffaa0000' } | Color definitions | null |
| file_path | String | 'worklog.json' | Where is the log? | null |
| lunch_minutes | UInt | 60 | How many minutes do you need to have lunch? | null |
| set_color | Bool | true | Do you want to change the color when you are working and when you are not? | null |
| work_hours | UInt | 8 | How many hours do you work on a day? | null |
| round_to_quarter | Bool | true | Round to the nearest quarter? e.g. 15:04 will be stored as 15:00 (and 16:10 -> 16:15)  | null |

## On single click

* If there is a task with no finish time:
  * It will prompt you what you've been doing.
  * When you write and click OK, the task will be updated with the finish time, the text entered and the task time.
  * If set_color is true, it will send to client the new state with the `color.not_working` color.
  * Will popup a information window with the total time you've spent in your tasks
* If there is no tasks or if there is no task open:
  * It will create a new task with the start time.
  * If set_color is true, it will send to client the new state with the `color.working` color.

## On long press

Shows the current working time dialog

## Example in layout file

```json
{
    "state": {
        "text": "",
        "bgColor": "00ff00",
        "actions": [
            {
                "name": "worklog",
                "props": {
                    "color": {
                        "working" : "ff00aa00",
                        "not_working" : "ffaa0000"
                    },
                    "file_path": "worklog.json",
                    "lunch_minutes": 60,
                    "round_to_quarter": true,
                    "set_color": true,
                    "work_hours": 8
                }
            }
        ]
    }
}
```
