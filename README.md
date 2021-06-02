# Action for ideckia: Worklog

## Definition

## Properties

| Name | Type | Default | Description | Possible values |
| ----- |----- | ----- | ----- | ----- |
| color | { working : String, notWorking : String } | { working : 'ff00aa00', notWorking : 'ffaa0000' } | Color definitions | null |
| filePath | String | 'worklog.json' | Where is the log? | null |
| lunchMinutes | UInt | 60 | How many minutes do you need to have lunch? | null |
| setColor | Bool | true | Do you want to change the color when you are working and when you are not? | null |
| workHours | UInt | 8 | How many hours do you work on a day? | null |

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