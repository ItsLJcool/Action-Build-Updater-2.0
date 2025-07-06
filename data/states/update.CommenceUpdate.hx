//a
import flixel.math.FlxRect;
import openfl.utils.ByteArrayData;
import funkin.backend.scripting.MultiThreadedScript;
import haxe.Timer;
import funkin.backend.MusicBeatState;

import funkin.backend.utils.ZipUtil;
import funkin.backend.utils.ZipProgress;
import funkin.backend.utils.ZipReader;

final CustomHttpUtil = new MultiThreadedScript(Paths.script("data/utils/HttpUtil"), this);

var os = #if windows "windows" #elseif mac "macos" #elseif linux "linux" #end;
var link = "https://nightly.link/CodenameCrew/CodenameEngine/workflows/"+os+"/main/Codename%20Engine.zip";

//region ui variables
var roundedEdges:Int = 20;

var bg:FlxSprite = new FlxSprite().makeSolid(FlxG.width, FlxG.height);
var topBG = new FlxSprite().loadGraphic(Paths.image("updater/menuUpdater"));

var progressBg = new FlxSprite().makeGraphic(FlxG.width * 0.85, FlxG.height * 0.6, 0xFF000000);
progressBg.alpha = 0.35;

var progressBar = new FlxSprite().makeGraphic(progressBg.width * 0.65, 8, 0xFFFFFFFF);
var progressRect = FlxRect.get(0, 0, 0, progressBar.height);

var progressText = new FlxText(0, 0, 0, "0%");
progressText.setFormat(Paths.font("Funkin.ttf"), 24, FlxColor.WHITE, "left");
progressText.updateHitbox();

var progressInformationText = new FlxText(0, 0, 0, "your pc gonna explode!!");
progressInformationText.setFormat(Paths.font("Funkin.ttf"), 32, FlxColor.WHITE, "center");
progressInformationText.updateHitbox();

var lazyCamera = new FlxCamera();
lazyCamera.bgColor = 0;
lazyCamera.alpha = 0;

//endregion

var installingColor = 0xFFDCB6E2;
var progressColor = 0xFFA361B3;
var extractingColor = 0xFF752888;

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

    add_roundedShader(progressBar, 5);
    progressBar.x = progressBg.x + (progressBg.width - progressBar.width) * 0.5;
    progressBar.y = progressBg.y + (progressBg.height - progressBar.height) * 0.65;
    add(progressBar);
    progressBar.onDraw = (spr) -> {
        spr.color = installingColor; // not filled
        spr.draw();

        spr.clipRect = progressRect;
        spr.color = progressColor; // filled
        spr.draw();

        spr.clipRect = null;
    }

    add(progressText);

    add(progressInformationText);
    updateInstallProgress();

    FlxTween.tween(lazyCamera, {alpha: 1}, 0.5, {ease: FlxEase.quadInOut});

    doUpdate();
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

        installingColor = progressColor;
        progressColor = extractingColor;
        updateInstallProgress(0, null);
        extractZip(data);
    }]);
}

function customReduce(arr, initial, callback) {
    var accumulator = initial;
    for (item in arr) accumulator = callback(accumulator, item);
    return accumulator;
}

function updateInstallProgress(?percent:Float, ?averagePing:Int) {
    var percent = percent ?? 0;
    progressText.text = Std.string(Math.floor(percent*100)) + "%";
    progressText.x = progressBar.x + progressBar.width + 10;
    progressText.y = progressBar.y + (progressBar.height - progressText.height) * 0.5;
    progressText.updateHitbox();

    progressInformationText.text = "Average ping: " + (averagePing ?? "??") + "ms";
    progressInformationText.x = progressBar.x + (progressBar.width - progressInformationText.width) * 0.5;
    progressInformationText.y = progressBar.y - progressInformationText.height - 50;
    progressInformationText.updateHitbox();

    progressRect.set(0, 0, progressBar.width*percent, progressBar.height);
}

function updateZipProgress(?percent:Float) {
    var percent = percent ?? 0;
    progressText.text = Std.string(Math.floor(percent*100)) + "%";
    progressText.x = progressBar.x + progressBar.width + 10;
    progressText.y = progressBar.y + (progressBar.height - progressText.height) * 0.5;
    progressText.updateHitbox();

    progressInformationText.text = "Extracting Zip!\nZip Saved at ( "+zipPath+" )";
    progressInformationText.x = progressBar.x + (progressBar.width - progressInformationText.width) * 0.5;
    progressInformationText.y = progressBar.y - progressInformationText.height - 50;
    progressInformationText.updateHitbox();

    progressRect.set(0, 0, progressBar.width*percent, progressBar.height);
}

var isDoneUnzipping = false;
function update(elapsed:Float) {
    if (controls.BACK) FlxG.switchState(new ModState("update.NewUpdate"));

    if (zipProgress != null && !zipProgress?.done) updateZipProgress(zipProgress.percentage);
    if (zipProgress?.done && !isDoneUnzipping) {
        isDoneUnzipping = true;
        updateZipProgress(1);
        completed();
    }
}

var zipReader:ZipReader = null;
var zipProgress:ZipProgress = null;
var zipPath = "./.temp/Codename Engine "+os+".zip";
#if !windows zipPath = "./Action Build CodenameEngine for "+os+".zip"; #end
function extractZip(data:ByteArrayData) {
    
    CoolUtil.safeSaveFile(zipPath, data);
    var size = CoolUtil.getSizeString(data.length);
    
    #if !ALLOW_MULTITHREADING
        // not tested!!
        completed();
    #end

    #if windows
        zipProgress = ZipUtil.uncompressZipAsync(ZipUtil.openZip(zipPath), "./.cache/");
    #else
        completed();
    #end
}

function completed() {
    trace("coolio its completed");
}