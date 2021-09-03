# Action for ideckia: Worklog

## Definition

Log in a JSON file your daily work. The path of this file can be configured with the `filePath` property.

* When this action is loaded it will create an entry for the day.
* In that entry, there will be stored
  * day (ex: 2021-06-24)
  * exit time: Based on when the entry was created and the properties `workHours` and `lunchMinutes`, it will calculate at what time would you stop working.
  * tasks: An array which will be filled with the tasks you've done during the day. Every task seems like:
    * start: start time of the task
    * finish: finisth time of the task
    * time: calculated time between start and finish
    * work: description of what where you doing
  * totalTime: Time you've spent working (it is a sum of all the tasks times)

## Properties

| Name | Type | Default | Description | Possible values |
| ----- |----- | ----- | ----- | ----- |
| color | { working : String, notWorking : String } | { working : 'ff00aa00', notWorking : 'ffaa0000' } | Color definitions | null |
| filePath | String | 'worklog.json' | Where is the log? | null |
| lunchMinutes | UInt | 60 | How many minutes do you need to have lunch? | null |
| setColor | Bool | true | Do you want to change the color when you are working and when you are not? | null |
| workHours | UInt | 8 | How many hours do you work on a day? | null |
| showTime | Bool | true | Update and show worked time in item? | null |

## Example in layout file

```json
{
    "state": {
        "text": "",
        "bgColor": "00ff00",
        "action": {
            "name": "worklog",
            "props": {
                "setColor": "false"
            }
        }
    }
}
```

When the action is executed (when clicked the button in the client), it will open the log file:

* If there is a task with no finish time:
  * It will prompt you what you've been doing.
  * When you write and click OK, the task will be updated with the finish time, the text entered and the task time.
  * If setColor is true, it will send to client the new state with the `color.notWorking` color.
  * Will popup a information window with the total time you've spent in your tasks
* If there is no tasks or if there is no task open:
  * It will create a new task with the start time.
  * If setColor is true, it will send to client the new state with the `color.working` color.
