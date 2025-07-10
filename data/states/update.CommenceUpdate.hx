//a
import flixel.math.FlxRect;
import openfl.utils.ByteArrayData;
import funkin.backend.scripting.MultiThreadedScript;
import haxe.Timer;
import funkin.backend.MusicBeatState;

import funkin.backend.utils.ZipUtil;
import funkin.backend.utils.ZipProgress;
import funkin.backend.utils.ZipReader;

import sys.FileSystem;
import Date;

import funkin.backend.utils.FileAttribute;
import funkin.backend.scripting.GlobalScript;

class ProgressBar extends FlxBasic {

    public var color:FlxColor = FlxColor.WHITE;
    public var progressColor:FlxColor = FlxColor.RED;

    public var progress:Float = 0;

    public var bar:FlxSprite;
    private var percentageText:FlxText;
    private var informationText:FlxText;

    public var infoText:String = "";

    public var informationOffset:Float = 15;

    private var progressRect:FlxRect;

    public var width:Float = 150;

    public var x:Float = 0;
    public var y:Float = 0;

    public var onUpdate:Float->Void;
    public var onComplete:Void->Void;

    public function new(width:Float, ?infoText:String, ?onUpdate:Float->Void, ?onComplete:Void->Void) {
        this.width = width ?? 150;

        this.infoText = infoText ?? "";

        this.onUpdate = onUpdate ?? (percent) -> {};
        this.onComplete = onComplete ?? () -> {};

        bar = new FlxSprite().makeGraphic(width, 8, FlxColor.WHITE);

        percentageText = new FlxText(0, 0, 0, "0%", 24);

        informationText = new FlxText(0, 0, 0, this.infoText, 24);

        this.progressRect = FlxRect.get(0, 0, 0, bar.height);

        this.x = 0;
        this.y = 0;
    }

    override public function update(elapsed:Float) {
        super.update(elapsed);
        if (bar.exists) bar.update(elapsed);
        if (percentageText.exists) percentageText.update(elapsed);
        if (informationText.exists) informationText.update(elapsed);

        progressRect.set(0, 0, bar.width*progress, bar.height);
    }

    override public function draw() {
        super.draw();
        if (bar.visible && bar.active) {
            bar.setPosition(x, y);
            bar.setGraphicSize(width, bar.height);

            bar.color = color;
            bar.draw();

            bar.clipRect = progressRect;
            bar.color = progressColor;
            bar.draw();
            
            bar.clipRect = null;
        }

        if (percentageText.visible && percentageText.active) {
            percentageText.text = Std.string(Math.floor(progress*100)) + "%";
            percentageText.setPosition(bar.x + bar.width + 10, bar.y + (bar.height - percentageText.height) * 0.5);
            percentageText.updateHitbox();
            percentageText.draw();
        }

        if (informationText.visible && informationText.active) {
            if (informationText.text != this.infoText) informationText.text = this.infoText;
            informationText.setPosition(bar.x + (bar.width - informationText.width) * 0.5, bar.y - informationText.height - informationOffset);
            informationText.updateHitbox();
            informationText.draw();
        }
    }
}

final CustomHttpUtil = new MultiThreadedScript(Paths.script("data/utils/HttpUtil"), this);

var os = #if windows "windows" #elseif mac "macos" #elseif linux "linux" #end;
var link = "https://nightly.link/CodenameCrew/CodenameEngine/workflows/"+os+"/main/Codename%20Engine.zip";

var installingColor = 0xFFDCB6E2;
var progressColor = 0xFFA361B3;

var extractingColor = 0xFF752888;
var safteyStepColor = 0xFF49E456;

//region ui variables
var roundedEdges:Int = 20;

var bg:FlxSprite = new FlxSprite().makeSolid(FlxG.width, FlxG.height);
var topBG = new FlxSprite().loadGraphic(Paths.image("updater/menuUpdater"));

var progressBg = new FlxSprite().makeGraphic(FlxG.width * 0.85, FlxG.height * 0.6, 0xFF000000);
progressBg.alpha = 0.35;

var topProgress = new ProgressBar(progressBg.width * 0.65);
topProgress.color = installingColor;
topProgress.progressColor = progressColor;

var bottomProgress = new ProgressBar(topProgress.width);
bottomProgress.color = installingColor;
bottomProgress.progressColor = safteyStepColor;

var lazyCamera = new FlxCamera();
lazyCamera.bgColor = 0;
lazyCamera.alpha = 0;

//endregion

var prev_ALLOW_DEBUG_RELOAD = MusicBeatState.ALLOW_DEBUG_RELOAD;
function create() {
    FlxG.cameras.add(lazyCamera, false);

    cameras = [lazyCamera];

    bg.color = data.newBgColor ?? 0xFF2F2138;
    bg.screenCenter();
    bg.scrollFactor.set();
    bg.camera = FlxG.camera;
    add(bg);

    topBG.setGraphicSize(FlxG.width + 5, FlxG.height + 5);
    topBG.updateHitbox();
    topBG.screenCenter();
    topBG.scrollFactor.set();
    topBG.camera = FlxG.camera;
    add(topBG);
    
    add_roundedShader(progressBg, roundedEdges);
    progressBg.screenCenter();
    progressBg.scrollFactor.set();
    add(progressBg);

    topProgress.x = progressBg.x + (progressBg.width - topProgress.width) * 0.5;
    topProgress.y = progressBg.y + (progressBg.height - topProgress.bar.height) * 0.3;
    add(topProgress);
    
    bottomProgress.x = progressBg.x + (progressBg.width - bottomProgress.width) * 0.5;
    bottomProgress.y = progressBg.y + (progressBg.height - bottomProgress.bar.height) * 0.8;
    add(bottomProgress);

    for (progress in [topProgress, bottomProgress]) {
        add_roundedShader(progress.bar, 5);
        progress.percentageText.setFormat(Paths.font("Funkin.ttf"), 24, FlxColor.WHITE, "left");
        progress.informationText.setFormat(Paths.font("Funkin.ttf"), 32, FlxColor.WHITE, "center");
    }

    // updateInstallProgress();

    FlxTween.tween(lazyCamera, {alpha: 1}, 0.5, {ease: FlxEase.quadInOut, onComplete: () -> {
        doUpdate();
        safelyZipCNE();
    }});

}

function customReduce(arr, initial, callback) {
    var accumulator = initial;
    for (item in arr) accumulator = callback(accumulator, item);
    return accumulator;
}

function doUpdate() {
    MusicBeatState.ALLOW_DEBUG_RELOAD = false;

    var lastProgressTime:Float = 0;
    var pingList:Array<Float> = [];
    var pingMaxSize:Int = 50;
    CustomHttpUtil.call("requestZip", [link, (e, percent) -> {
        var currentTime = Timer.stamp();
        var interval = (currentTime - lastProgressTime) * 1000; // Convert to milliseconds
    
        // Collect intervals to calculate average ping
        pingList.push(interval);
        if (pingList.length > pingMaxSize) pingList.shift();
    
        // Calculate the average ping using customReduce
        var totalPing = customReduce(pingList, 0.0, (sum, value) -> sum + value);
        var averagePing = Std.int(totalPing / pingList.length);
    
        lastProgressTime = currentTime;

        updateInstallProgress(percent, (pingList.length < pingMaxSize) ? null : averagePing);
    }, (e, loader) -> {
        var data = new ByteArrayData();
        loader.data.readBytes(data, 0, loader.data.length - loader.data.position);

        // for now
        MusicBeatState.ALLOW_DEBUG_RELOAD = prev_ALLOW_DEBUG_RELOAD;

        updateInstallProgress(0, null);
        extractZip(data);
    }]);
}

function updateInstallProgress(?percent:Float, ?averagePing:Int) {
    topProgress.progress = percent ?? 0;
    topProgress.infoText = "Average ping: " + (averagePing ?? "??") + "ms";
}

function updateZipProgress(percent:Float) {
    topProgress.progress = percent ?? 0;
    topProgress.infoText = (downloadZipProgress.fileCount == 0) ? "Gathering Zip Information... Please wait.\nZip saved at ( "+zipPath+" )" : "Extracting Zip!\n" + downloadZipProgress.curFile + " / " + downloadZipProgress.fileCount;
}

function updateArchivesProgress(percent:Float) {
    bottomProgress.progress = percent ?? 0;
    var fileCount = (bottomProgress.progress >= 1) ? safteyZipProgress.fileCount+" / "+safteyZipProgress.fileCount : safteyZipProgress.curFile+" / "+safteyZipProgress.fileCount;
    bottomProgress.infoText = "Safely Zipping your current Codename Engine...\n\n"+fileCount;
}

var isDoneUnzipping = false;
var isDoneArchiving = false;

var isCompleted = false;
function update(elapsed:Float) {
    if (downloadZipProgress != null) {
        if (!downloadZipProgress.done) updateZipProgress(downloadZipProgress.percentage);
        else if (!isDoneUnzipping) {
            isDoneUnzipping = true;
            updateZipProgress(1);
        }
    }

    if (safteyZipProgress != null) {
        if (!safteyZipProgress.done) updateArchivesProgress(safteyZipProgress.percentage);
        else if (!isDoneArchiving) {
            isDoneArchiving = true;
            updateArchivesProgress(1);
        }
    }

    if (isDoneUnzipping && isDoneArchiving && !isCompleted) completed();
}

var downloadZipProgress:ZipProgress = null;
var zipPath = "./.temp/Codename Engine "+os+".zip";
#if !windows zipPath = "./Action Build CodenameEngine for "+os+".zip"; #end
function extractZip(data:ByteArrayData) {
    topProgress.color = progressColor;
    topProgress.progressColor = extractingColor;
    
    CoolUtil.safeSaveFile(zipPath, data);
    // var size = CoolUtil.getSizeString(data.length);

    #if windows
        downloadZipProgress = ZipUtil.uncompressZipAsync(ZipUtil.openZip(zipPath), "./.cache/");
    #else
        isDoneUnzipping = true;
    #end
}

var safteyZipProgress:ZipProgress = null;
function safelyZipCNE() {
    // preventing statics as much as possible sorry.
    var archivesPath = GlobalScript.scripts.get("archivesPath");
    CoolUtil.addMissingFolders(archivesPath);
    CoolUtil.safeAddAttributes(archivesPath, FileAttribute.HIDDEN); // 0x2

    var whitelist = ["mods", "addons"];

    var dateNow = Date.now();
    var dateTime = dateNow.getFullYear()+"-"+dateNow.getMonth()+"-"+dateNow.getDay()+" - "+dateNow.getHours()+"-"+dateNow.getMinutes()+"-"+dateNow.getSeconds();

    // using addons to test zipping
    safteyZipProgress = ZipUtil.writeFolderToZipAsync(ZipUtil.createZipFile(archivesPath+dateTime+".zip"), "./addons", null, null, whitelist);
}

function completed() {
    if (!isCompleted) return;
    isCompleted = true;

    trace("its completed");
}