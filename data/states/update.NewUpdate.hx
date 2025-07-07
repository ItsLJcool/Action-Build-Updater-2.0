//a

import funkin.menus.BetaWarningState;
import flixel.text.FlxTextBorderStyle;
import flixel.text.FlxTextFormatMarkerPair;
import flixel.text.FlxTextFormat;
import funkin.backend.scripting.MultiThreadedScript;
import openfl.geom.ColorTransform;

import flixel.group.FlxTypedSpriteGroup;
import funkin.backend.MusicBeatState;

import openfl.display.BitmapData;
import flixel.math.FlxRect;


final FileUtil = new MultiThreadedScript(Paths.script("data/utils/FileUtil"), this);

importScript("data/utils/UpdaterUtil");

final possibleMusics = getUpdaterAudioPaths();

var bgBgColor = 0xFF4D2A62;
var bgBg = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, bgBgColor);
var bg:FlxSprite = new FlxSprite().makeSolid(FlxG.width, FlxG.height, 0xFF5E446E);
var topBG = new FlxSprite().loadGraphic(Paths.image("updater/menuUpdater"));

var roundedEdges:Int = 12;
var cameraPadding:FlxPoint = FlxPoint.get(35, 1);
var commitInformationBG = new FlxSprite().makeGraphic(350, FlxG.height * 0.95, FlxColor.BLACK);
commitInformationBG.alpha = 0.5;

var commitInfoCamera = new FlxCamera(0, 0, commitInformationBG.width - cameraPadding.x, commitInformationBG.height - cameraPadding.y);
commitInfoCamera.bgColor = 0;

var fileChangesBG = new FlxSprite().makeGraphic(FlxG.width * 0.65, FlxG.height * 0.75, FlxColor.BLACK);
fileChangesBG.alpha = 0.5;

var fileChangesCamera = new FlxCamera(0, 0, fileChangesBG.width - cameraPadding.x, fileChangesBG.height - cameraPadding.y);
fileChangesCamera.bgColor = 0;

var selectionBG = new FlxSprite().makeGraphic(fileChangesBG.width, FlxG.height * 0.15, FlxColor.BLACK);
selectionBG.alpha = 0.5;

var commitGroup = new FlxTypedSpriteGroup();
var fileChangesGroup = new FlxTypedSpriteGroup();
var selectionGroup = new FlxTypedSpriteGroup();


var prev_mouseVisible = false;
var prev_autoPause = false;
function create() {
    prev_autoPause = FlxG.autoPause;
    prev_mouseVisible = FlxG.mouse.visible;

    FlxG.mouse.visible = true;
    FlxG.autoPause = false;

    FlxG.cameras.add(commitInfoCamera, false);
    FlxG.cameras.add(fileChangesCamera, false);

    bgBg.screenCenter();
    bgBg.scrollFactor.set();
    add(bgBg);

    bg.screenCenter();
    bg.scrollFactor.set();
    add(bg);

	topBG.setGraphicSize(FlxG.width + 5, FlxG.height + 5);
    topBG.updateHitbox();
    topBG.screenCenter();
    topBG.scrollFactor.set();
    add(topBG);

    add_roundedShader(commitInformationBG, roundedEdges);
    commitInformationBG.screenCenter();
    commitInformationBG.x = FlxG.width * 0.03;
    add(commitInformationBG);

    commitInformationBG.onDraw = (spr) -> {
        commitInfoCamera.x = spr.x + (cameraPadding.x * 0.5);
        commitInfoCamera.y = spr.y + (cameraPadding.y * 0.5);
        spr.draw();
    }

    add_roundedShader(fileChangesBG, roundedEdges);
    fileChangesBG.x = (FlxG.width - fileChangesBG.width) * 0.95;
    fileChangesBG.y = commitInformationBG.y;
    add(fileChangesBG);

    fileChangesBG.onDraw = (spr) -> {
        fileChangesCamera.x = spr.x + (cameraPadding.x * 0.5);
        fileChangesCamera.y = spr.y + (cameraPadding.y * 0.5);
        spr.draw();
    }

    commitGroup.camera = commitInfoCamera;
    add(commitGroup);
    initCommitInfo(commitGroup);

    fileChangesGroup.camera = fileChangesCamera;
    add(fileChangesGroup);
    initFileChangesInfo(fileChangesGroup);

    add(selectionGroup);

    add_roundedShader(selectionBG, roundedEdges);
    selectionBG.x = fileChangesBG.x;
    selectionBG.y = FlxG.height - selectionBG.height - 20;
    selectionGroup.add(selectionBG);
    
    initSelection(selectionGroup);

    if (FlxG.sound.music == null) {
        var randomMusic = FlxG.random.getObject(possibleMusics);
        CoolUtil.playMusic(Paths.music(randomMusic), true, 0);
        FlxG.sound.music.fadeIn(1.65, 0, 0.7);
    }
}

var colorFormatting = [
	new FlxTextFormatMarkerPair(new FlxTextFormat(FlxColor.RED), "<r>"),
	new FlxTextFormatMarkerPair(new FlxTextFormat(FlxColor.GREEN), "<g>"),
	new FlxTextFormatMarkerPair(new FlxTextFormat(FlxColor.LIME), "<l>"),
	new FlxTextFormatMarkerPair(new FlxTextFormat(FlxColor.BLUE), "<b>"),
	new FlxTextFormatMarkerPair(new FlxTextFormat(FlxColor.YELLOW), "<y>"),
	new FlxTextFormatMarkerPair(new FlxTextFormat(FlxColor.CYAN), "<c>"),
	new FlxTextFormatMarkerPair(new FlxTextFormat(FlxColor.MAGENTA), "<m>"),
    new FlxTextFormatMarkerPair(new FlxTextFormat(FlxColor.PURPLE), "<pu>"),
	new FlxTextFormatMarkerPair(new FlxTextFormat(FlxColor.PINK), "<pi>"),
	new FlxTextFormatMarkerPair(new FlxTextFormat(FlxColor.ORANGE), "<o>"),
    new FlxTextFormatMarkerPair(new FlxTextFormat(FlxColor.BROWN), "<b>"),
    new FlxTextFormatMarkerPair(new FlxTextFormat(FlxColor.GREY), "<gray>"),
];

//region Initalizers
function initCommitInfo(group:FlxTypedSpriteGroup) {

    var cam = commitInfoCamera;

    var commitNumber = new FlxText(0, 10, cam.width, updateInformation.commitTitle);
    commitNumber.setFormat(Paths.font("Funkin.ttf"), 34, FlxColor.WHITE, "left", FlxTextBorderStyle.OUTLINE, 0xFF684776);
    commitNumber.borderSize = 3;
    group.add(commitNumber);

    var seperator1 = makeSeperator(cam.width, 1.5, 0xFFAE8CAE);
    seperator1.camera = cam;
    centerToCamera(seperator1);
    seperator1.y = commitNumber.y + commitNumber.height + 10;
    group.add(seperator1);

    var avatarOutlineSize:Float = 8;
    avatar = new FlxSprite().makeGraphic(92, 92, 0xFFFFFFFF);
    avatar.shader = new CustomShader("loading");
    avatar.shader.iTime = 0;
    avatar.x = (cam.width - avatar.width) - avatarOutlineSize;
    avatar.y = seperator1.y + seperator1.height + 10;
    group.add(avatar);

    var avatarLoaded = false;
    var outlineColor = new ColorTransform();
    outlineColor.color = 0xFFD6A6E4;

    avatar.onDraw = (spr) -> {
        if (!avatarLoaded) return spr.draw();

        var oldColor = spr.colorTransform;
        var prevSize = {width: spr.width, height: spr.height};
        spr.colorTransform = outlineColor;
        spr.setGraphicSize(spr.width + avatarOutlineSize, spr.height + avatarOutlineSize);
        spr.draw();
        spr.colorTransform = oldColor;
        spr.setGraphicSize(prevSize.width, prevSize.height);
        spr.draw();
    };
    
    FileUtil.call("loadImageFromUrl", [updateInformation.author.avatar_url, (bitmap) -> {
		avatar.loadGraphic(bitmap);
		avatar.setGraphicSize(92, 92);
        avatar.updateHitbox();
        avatar.shader = new CustomShader("engine/circleProfilePicture");
        avatar.x = (cam.width - avatar.width) - avatarOutlineSize;
        avatar.y = seperator1.y + seperator1.height + 10;

        avatarLoaded = true;
	}]);

    var title = new FlxText(0, 0, cam.width - avatar.width - (avatarOutlineSize + 2), updateInformation.title);
    title.setFormat(Paths.font("Funkin.ttf"), 20, FlxColor.WHITE, "left", FlxTextBorderStyle.OUTLINE, 0xFF684776);
    title.borderSize = 2;
    title.updateHitbox();
    title.y = avatar.y;
    group.add(title);

    var maxY = (avatar.y + avatar.height > title.y + title.height) ? avatar.y + avatar.height : title.y + title.height;

    var seperator2 = makeSeperator(cam.width, 1.5, 0xFFAE8CAE);
    seperator2.camera = cam;
    centerToCamera(seperator2);
    seperator2.y = maxY + 10;
    group.add(seperator2);

    var commitMessagesString = "";
    for (message in updateInformation.messages) commitMessagesString += message+"\n";

    // commitMessagesString = Assets.getText(Paths.getPath('data/test.txt'));

    var commitMessages = new FlxText(0, 0, cam.width, commitMessagesString);
    commitMessages.setFormat(Paths.font("Funkin.ttf"), 20, FlxColor.WHITE, "left", FlxTextBorderStyle.OUTLINE, 0xFF6D5A70);
    commitMessages.borderSize = 1;
    commitMessages.updateHitbox();
    commitMessages.y = seperator2.y + seperator2.height + 10;
    commitMessages.applyMarkup(commitMessages.text, colorFormatting);
    group.add(commitMessages);
}

function initFileChangesInfo(group:FlxTypedSpriteGroup) {
    
    var cam = fileChangesCamera;

    var title = new FlxText(0, 10, cam.width, "File Changes: " + updateInformation.files.length);
    title.camera = cam;
    title.setFormat(Paths.font("Funkin.ttf"), 36, FlxColor.WHITE, "left", FlxTextBorderStyle.OUTLINE, 0xFF684776);
    title.borderSize = 3;
    title.updateHitbox();
    group.add(title);

    for (idx=>file in updateInformation.files) {
        var groupTest = _addFileChanges(file, idx);
        groupTest.y = (title.y + title.height + 20)*(idx+1);
        group.add(groupTest);
    }
    // testing
    // for (idx in 0...10) {
    //     var file = updateInformation.files[0];
    //     var groupTest = _addFileChanges(file, idx);
    //     groupTest.y = (title.y + title.height + 20)*(idx+1);
    //     group.add(groupTest);
    // }

    var pumpSpr = new FlxSprite().makeSolid(1, 25);
    pumpSpr.y = group.height;
    pumpSpr.visible = pumpSpr.exists = false;
    group.add(pumpSpr);

}

function _addFileChanges(fileData:Dynamic, idx:Int, ?height:Int = 60) {
    var height = height ?? 60;
    var cam = fileChangesCamera;

    var group = new FlxTypedSpriteGroup();
    group.ID = idx;
    group.camera = cam;

    var name = fileData.filename.split("/").pop();
    var fileName = new FlxText(0, 0, cam.width * 0.85, name);
    fileName.setFormat(Paths.font("Funkin.ttf"), 25, FlxColor.WHITE, "left", FlxTextBorderStyle.OUTLINE, 0xFF684776);
    fileName.borderSize = 2;
    fileName.updateHitbox();

    var bg = new FlxSprite().makeGraphic(cam.width, fileName.height * 2, 0x70000000);
    add_roundedShader(bg, roundedEdges);
    group.add(bg);
    
    fileName.x = 10;
    fileName.y = (bg.height - fileName.height) * 0.5;
    group.add(fileName);

    var deletions = new FlxText(0, 0, 0, "-"+fileData.deletions);
    deletions.setFormat(Paths.font("Funkin.ttf"), 25, 0xFFcb4462, "right");
    deletions.x = bg.width - deletions.width - 10;
    deletions.y = (bg.height - deletions.height) * 0.5;
    group.add(deletions);

    var additions = new FlxText(0, 0, 0, "+"+fileData.additions);
    additions.setFormat(Paths.font("Funkin.ttf"), 25, 0xFF53d14d, "right");
    additions.x = deletions.x - additions.width - 10;
    additions.y = (bg.height - additions.height) * 0.5;
    group.add(additions);


    return group;
}

function initSelection(group:FlxTypedSpriteGroup) {

    var scaleFactor = 0.6;
    var textSize = 22;

    var skipSpr = new FlxSprite().loadGraphic(Paths.image("updater/bksp"));
    skipSpr.scale.set(scaleFactor, scaleFactor);
    skipSpr.updateHitbox();
    skipSpr.x = selectionBG.x + 15;
    skipSpr.y = selectionBG.y + (selectionBG.height - skipSpr.height) * 0.5;
    group.add(skipSpr);

    var continueBack = new FlxText(0, 0, 0, "to skip\nthis update");
    continueBack.setFormat(Paths.font("Funkin.ttf"), textSize, FlxColor.WHITE, "left");
    continueBack.updateHitbox();
    continueBack.x = skipSpr.x + skipSpr.width + 10;
    continueBack.y = selectionBG.y + (selectionBG.height - continueBack.height) * 0.5;
    group.add(continueBack);

    var enterSpr = new FlxSprite().loadGraphic(Paths.image("updater/enter"));
    enterSpr.scale.set(scaleFactor, scaleFactor);
    enterSpr.updateHitbox();
    enterSpr.x = continueBack.x + continueBack.width + 10;
    enterSpr.y = selectionBG.y + (selectionBG.height - enterSpr.height) * 0.5;
    group.add(enterSpr);

    var enterText = new FlxText(0, 0, 0, "to install\nthis update");
    enterText.setFormat(Paths.font("Funkin.ttf"), textSize, FlxColor.WHITE, "left");
    enterText.updateHitbox();
    enterText.x = enterSpr.x + enterSpr.width + 10;
    enterText.y = selectionBG.y + (selectionBG.height - enterText.height) * 0.5;
    group.add(enterText);

    var checkGithub = new FlxSprite().loadGraphic(Paths.image("updater/spc"));
    checkGithub.scale.set(scaleFactor, scaleFactor);
    checkGithub.updateHitbox();
    checkGithub.x = enterText.x + enterText.width + 10;
    checkGithub.y = selectionBG.y + (selectionBG.height - checkGithub.height) * 0.5;
    group.add(checkGithub);

    var checkGithubText = new FlxText(0, 0, 0, "to check\nfor updates");
    checkGithubText.setFormat(Paths.font("Funkin.ttf"), textSize, FlxColor.WHITE, "left");
    checkGithubText.updateHitbox();
    checkGithubText.x = checkGithub.x + checkGithub.width + 10;
    checkGithubText.y = selectionBG.y + (selectionBG.height - checkGithubText.height) * 0.5;
    group.add(checkGithubText);

}
//endregion


var inputMenu:Bool = true;
var inputBuffer:Bool = false;
function update(elapsed:Float) {
    avatar?.shader?.iTime += elapsed;
    
    if (!inputBuffer) return inputBuffer = true;

    if (controls.BACK && inputMenu) {
        inputMenu = false;
        FlxG.mouse.visible = prev_mouseVisible;
        FlxG.autoPause = prev_autoPause;
        FlxG.switchState(new BetaWarningState());
    }
    
    if (controls.ACCEPT && !FlxG.keys.justPressed.SPACE) selectionTime();

    if (FlxG.keys.justPressed.SPACE && inputMenu) {
        inputMenu = false;
        new FlxTimer().start(0.35, () -> inputMenu = true);
        CoolUtil.openURL("https://github.com/CodenameCrew/CodenameEngine");
    }

    // bg?.shader?.iTime += elapsed;

    updateCommitInfoScroll(elapsed);
    updateFileChangesScroll(elapsed);
}

//region Scroll updaters

var commitScroll:Float = 0;
function updateCommitInfoScroll(elapsed:Float) {
    if (FlxG.mouse.wheel != 0 && FlxG.mouse.overlaps(commitInformationBG)) commitScroll += FlxG.mouse.wheel * 35;
    var cam = commitInfoCamera;

    var maxBound = Math.max(0, commitGroup.height - (cam.height - (cameraPadding.y)));
    commitScroll = FlxMath.bound(commitScroll, 0, maxBound);

    cam.scroll.y = lerp(cam.scroll.y, commitScroll, 0.15);
}

var fileChangesScroll:Float = 0;
function updateFileChangesScroll(elapsed:Float) {
    if (FlxG.mouse.wheel != 0 && FlxG.mouse.overlaps(fileChangesBG)) fileChangesScroll += FlxG.mouse.wheel * 35;
    var cam = fileChangesCamera;

    var maxBound = Math.max(0, fileChangesGroup.height - (cam.height - (cameraPadding.y)));
    fileChangesScroll = FlxMath.bound(fileChangesScroll, 0, maxBound);

    cam.scroll.y = lerp(cam.scroll.y, fileChangesScroll, 0.15);
}

//endregion

function selectionTime(forceUpdate:Bool = false) {
    var forceUpdate = forceUpdate ?? false;
    if (!inputMenu) return;
    inputMenu = false;

    if (!forceUpdate && !updateInformation.hasArtifact) {
        persistentUpdate = false;
        persistentDraw = true;
        openSubState(new ModSubState("update.ArtifactMissing"));
        inputMenu = true;
        return;
    }
    
    var ease = FlxEase.quadIn;
    var time = 1;
    
    FlxTween.tween(commitInformationBG, {y: -commitInformationBG.height - commitInformationBG.y}, time, {ease: ease});
    FlxTween.tween(fileChangesBG, {x: FlxG.width + fileChangesBG.x}, time, {ease: ease, startDelay: 0.1});
    FlxTween.tween(selectionGroup, {y: FlxG.height + selectionGroup.y}, time, {ease: ease, startDelay: 0.2});

    FlxTween.tween(bg, {alpha: 0}, time, {ease: FlxEase.quadInOut});
    
    new FlxTimer().start(time + 0.1, () -> {
        MusicBeatState.skipTransIn = MusicBeatState.skipTransOut = true;
        FlxG.switchState(new ModState("update.CommenceUpdate", {
            newBgColor: bgBgColor,
        }));
    });
    
}

function makeSeperator(width:Int, heightMult:Int, color:FlxColor) {
    var seperator = new FlxSprite().makeGraphic(width, 3*heightMult, color);
    add_roundedShader(seperator, (3*heightMult));
    
    return seperator;
}

function destroy() {
    if (FlxG.cameras.list.contains(commitInfoCamera)) FlxG.cameras.remove(commitInfoCamera, true);
    if (FlxG.cameras.list.contains(fileChangesCamera)) FlxG.cameras.remove(fileChangesCamera, true);
}