//a
import flixel.text.FlxTextBorderStyle;
import haxe.io.Path;
import sys.io.Process;

import funkin.backend.scripting.MultiThreadedScript;

import Sys;

final FileUtil = new MultiThreadedScript(Paths.script("data/utils/FileUtil"), this);

var dontDelete = ["mods", "addons"];

var movingFilesText:FlxText;
function create() {
    movingFilesText = new FlxText(0, 0, FlxG.width * 0.5, "Moving Files...", 48);
	movingFilesText.setFormat(Paths.font("Funkin.ttf"), movingFilesText.size, FlxColor.WHITE, "center", FlxTextBorderStyle.OUTLINE, 0xFF000000);
    movingFilesText.borderSize = 3;
	movingFilesText.screenCenter();
    movingFilesText.y = FlxG.height * 0.2;
    movingFilesText.alpha = 0.0001;
    add(movingFilesText);

    FlxTween.tween(movingFilesText, {alpha: 1}, 0.75, {onComplete: fire});
}

var readyToLeave:Bool = false;
function fire() {

    for (f in FileSystem.readDirectory("./")) {
        if (!FileSystem.isDirectory(fPath) || dontDelete.contains(f)) continue;
        if (CoolUtil.getFileAttributes(f).isHidden) continue;
        FileSystem.deleteDirectory(f);
    }

    FileUtil.call("copyFolder", ['./.cache', '.', () -> {
        readyToLeave = true;
        CoolUtil.playMenuSFX(0);
    }, (e) -> {
        failed("Error: "+e);
    }]);
}

function doneTime() {
    new Process('start /B CodenameEngine.exe', null);
    Sys.exit(0);
}

function update(elapsed) {
    if (readyToLeave && failedText.length == 0) {
        readyToLeave = false;
        if (window.opacity != null) return FlxTween.tween(window, {opacity: 0}, 1, {onComplete: doneTime});
        new FlxTimer().start(0.5, doneTime);
    }

    if (timeTillFading > 0) timeTillFading -= elapsed;
    else if (timeTillFading <= 0) {
        var first = failedText[0];
        first?.alpha -= elapsed*3;
        if (first?.alpha <= 0) {
            failedText.shift();
            for (item in failedText) item.y -= first.height;
        }
    }
}

var failedText:Array<FlxText> = [];
var timeTillFading:Float = 0;
function failed(text) {
    timeTillFading = 1;
    var latest = failedText[failedText.length-1] ?? movingFilesText;
    var text = new FlxText(0, 0, FlxG.width * 0.9, text, 48);
	text.setFormat(Paths.font("Funkin'.ttf"), text.size, FlxColor.RED, "center", FlxTextBorderStyle.OUTLINE, 0xFF000000);
    text.borderSize = 3;
	text.screenCenter();
    text.y = (latest.y + latest.height);
    if (failedText.length == 0) text.y += 50;
    add(text);
    failedText.push(text);
    
    CoolUtil.playMenuSFX(5, 1);
}