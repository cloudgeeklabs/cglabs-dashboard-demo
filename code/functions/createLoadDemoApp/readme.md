# TimerTrigger - createLoadDemoApp

Creates artificial load on app by randomly calling pages and performing actions via API (eventually!)


function.json => Configures the CRON configuration - in this case we are executing every Minute.
```json 

{
    "bindings": [
      {
        "name": "Timer",
        "type": "timerTrigger",
        "direction": "in",
        "schedule": "0 */0 * * * *"
      }
    ]
}

```
