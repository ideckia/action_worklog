import datetime.DateTime;

typedef DayDataJson = {
    var day:String;
    var exitTime:String;
    var ?totalTime:String;
    var ?tasks:Array<TaskJson>;
}

typedef TaskJson = {
    var start:String;
    var ?finish:String;
    var ?time:String;
    var ?work:String;
}

typedef DayData = {
    var day:DateTime;
    var exitTime:DateTime;
    var ?totalTime:DateTime;
    var ?tasks:Array<Task>;
}

typedef Task = {
    var start:DateTime;
    var ?finish:DateTime;
    var ?time:DateTime;
    var ?work:String;
}