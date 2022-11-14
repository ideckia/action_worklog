# Action for ideckia: Worklog

## Definition

Save weekly working log in a plain JSON file. The files will be named `worklog_weekNumber.json` e.g. `worklog_45.json`

The path of the directory where the files will be saved can be configured with the `logs_directory` property.

* When this action is loaded it will create an entry for the day.
* In that entry, there will be stored
  * day (ex: 2021-06-24)
  * exit time: Based on when the entry was created and the properties `work_hours` and `lunch_minutes`, it will calculate at what time would you stop working.
  * tasks: An array which will be filled with the tasks you've done during the day. Every task seems like:
    * start: start time of the task
    * finish: finisth time of the task
    * time: calculated time between start and finish
    * work: short description of the work (for example, jira identifier)
    * description: larger description of what where you doing
  * totalTime: Time you've spent working (it is a sum of all the tasks times)

## Properties

| Name | Type | Description | Shared | Default | Possible values |
| ----- |----- | ----- | ----- | ----- | ----- |
| color | { working : String, not_working : String } | Color definitions | false | { working : 'ff00aa00', not_working : 'ffaa0000' } | null |
| logs_directory | String | What is the directory where the log files are stored? | false | '.' | null |
| lunch_minutes | UInt | How many minutes do you need to have lunch? | false | 60 | null |
| set_color | Bool | Do you want to change the color when you are working and when you are not? | false | true | null |
| work_hours | UInt | How many hours do you work on a day? | false | 8 | null |
| round_to_quarter | Bool | Round to the neares quarter? e.g. 15:04 will be stored as 15:00 (and 16:10 -> 16:15)  | false | true | null |

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
                    "logs_directory": "/home/ideckia/worklogs",
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
