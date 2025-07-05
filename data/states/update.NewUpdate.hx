//a

import funkin.menus.BetaWarningState;
import flixel.text.FlxTextBorderStyle;
import flixel.text.FlxTextFormatMarkerPair;
import flixel.text.FlxTextFormat;
import funkin.backend.scripting.MultiThreadedScript;
import openfl.geom.ColorTransform;

import flixel.group.FlxTypedSpriteGroup;

import openfl.display.BitmapData;

final FileUtil = new MultiThreadedScript(Paths.script("data/utils/FileUtil"), this);

var bg:FlxSprite = new FlxSprite().makeSolid(FlxG.width, FlxG.height, 0xFF5E446E);
var topBG = new FlxSprite().loadGraphic(Paths.image("updater/menuUpdater"));


var roundedEdges:Int = 10;
var cameraPadding:Int = 35;
var bgColor:FlxColor = 0x60000000;
var commitInformationBG = new FlxSprite().makeGraphic(350, FlxG.height * 0.95, bgColor);

var commitInfoCamera = new FlxCamera(0, 0, commitInformationBG.width - cameraPadding, commitInformationBG.height - cameraPadding);
commitInfoCamera.bgColor = 0;

var fileChangesBG = new FlxSprite().makeGraphic(FlxG.width * 0.65, FlxG.height * 0.75, bgColor);
var fileChangesCamera = new FlxCamera(0, 0, fileChangesBG.width - cameraPadding, fileChangesBG.height - cameraPadding);
fileChangesCamera.bgColor = 0;

var selectionBG = new FlxSprite().makeGraphic(fileChangesBG.width, FlxG.height * 0.15, bgColor);

function create() {

    FlxG.cameras.add(commitInfoCamera, false);
    FlxG.cameras.add(fileChangesCamera, false);

    bg.screenCenter();
    add(bg);

	topBG.setGraphicSize(FlxG.width + 5, FlxG.height + 5);
    topBG.updateHitbox();
    topBG.screenCenter();
    add(topBG);

    add_roundedShader(commitInformationBG, roundedEdges);
    commitInformationBG.screenCenter();
    commitInformationBG.x = FlxG.width * 0.03;
    add(commitInformationBG);

    commitInfoCamera.x = commitInformationBG.x + (cameraPadding * 0.5);
    commitInfoCamera.y = commitInformationBG.y + (cameraPadding * 0.5);

    add_roundedShader(fileChangesBG, roundedEdges);
    fileChangesBG.x = (FlxG.width - fileChangesBG.width) * 0.95;
    fileChangesBG.y = commitInformationBG.y;
    add(fileChangesBG);

    fileChangesCamera.x = fileChangesBG.x + (cameraPadding * 0.5);
    fileChangesCamera.y = fileChangesBG.y + (cameraPadding * 0.5);

    add_roundedShader(selectionBG, roundedEdges);
    selectionBG.x = fileChangesBG.x;
    selectionBG.y = FlxG.height - selectionBG.height - 20;
    add(selectionBG);

    initCommitInfo();

    initFileChangesInfo();

    initSelection();

    trace("hasArtifact: " + updateInformation.hasArtifact);

}

function initCommitInfo() {

    var cam = commitInfoCamera;

    var commitNumber = new FlxText(0, 10, cam.width, updateInformation.commitTitle);
    commitNumber.camera = cam;
    commitNumber.setFormat(Paths.font("Funkin.ttf"), 34, FlxColor.WHITE, "left", FlxTextBorderStyle.OUTLINE, 0xFF684776);
    commitNumber.borderSize = 3;
    add(commitNumber);

    var seperator1 = makeSeperator(cam.width, 1.5, 0xFFAE8CAE);
    seperator1.camera = cam;
    centerToCamera(seperator1);
    seperator1.y = commitNumber.y + commitNumber.height + 10;
    add(seperator1);

    var avatarOutlineSize:Float = 8;
    avatar = new FlxSprite().makeGraphic(92, 92, 0xFFFFFFFF);
    avatar.camera = cam;
    avatar.shader = new CustomShader("loading");
    avatar.shader.iTime = 0;
    avatar.x = (cam.width - avatar.width) - avatarOutlineSize;
    avatar.y = seperator1.y + seperator1.height + 10;
    add(avatar);

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
    }
    
    FileUtil.call("loadImageFromUrl", [updateInformation.author.avatar_url, (bitmap) -> {
		avatar.loadGraphic(bitmap);
		avatar.setGraphicSize(92, 92);
        avatar.updateHitbox();
        avatar.shader = new CustomShader("update.circleProfilePicture");
        avatar.x = (cam.width - avatar.width) - avatarOutlineSize;
        avatar.y = seperator1.y + seperator1.height + 10;

        avatarLoaded = true;
	}]);

    var title = new FlxText(0, 0, cam.width - avatar.width, updateInformation.title);
    title.camera = cam;
    title.setFormat(Paths.font("Funkin.ttf"), 20, FlxColor.WHITE, "left", FlxTextBorderStyle.OUTLINE, 0xFF684776);
    title.borderSize = 2;
    title.updateHitbox();
    title.y = avatar.y;
    add(title);

    var maxY = (avatar.y + avatar.height > title.y + title.height) ? avatar.y + avatar.height : title.y + title.height;

    var seperator2 = makeSeperator(cam.width, 1.5, 0xFFAE8CAE);
    seperator2.camera = cam;
    centerToCamera(seperator2);
    seperator2.y = maxY + 10;
    add(seperator2);

    var commitMessagesString = "";
    for (message in updateInformation.messages) commitMessagesString += message+"\n";

    var commitMessages = new FlxText(0, 0, cam.width, commitMessagesString);
    commitMessages.camera = cam;
    commitMessages.setFormat(Paths.font("Funkin.ttf"), 20, FlxColor.WHITE, "left", FlxTextBorderStyle.OUTLINE, 0xFF6D5A70);
    commitMessages.borderSize = 1;
    commitMessages.updateHitbox();
    commitMessages.y = seperator2.y + seperator2.height + 10;
    commitMessages.applyMarkup(commitMessages.text, colorFormatting);
    add(commitMessages);
}

function initFileChangesInfo() {
    
    var cam = fileChangesCamera;

    var title = new FlxText(0, 10, cam.width, "File Changes: " + updateInformation.files.length);
    title.camera = cam;
    title.setFormat(Paths.font("Funkin.ttf"), 36, FlxColor.WHITE, "left", FlxTextBorderStyle.OUTLINE, 0xFF684776);
    title.borderSize = 3;
    title.updateHitbox();
    add(title);

    for (idx=>file in updateInformation.files) {
        var groupTest = _addFileChanges(file, idx);
        groupTest.y = (title.y + title.height + 20)*(idx+1);
    }

}

function _addFileChanges(fileData:Dynamic, idx:Int, ?height:Int = 60) {
    var height = height ?? 60;
    var cam = fileChangesCamera;

    var group = new FlxTypedSpriteGroup();
    group.ID = idx;
    group.camera = cam;
    add(group);

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

function initSelection() {

    var scaleFactor = 0.6;
    var textSize = 22;

    var skipSpr = new FlxSprite().loadGraphic(Paths.image("updater/bksp"));
    skipSpr.scale.set(scaleFactor, scaleFactor);
    skipSpr.updateHitbox();
    skipSpr.x = selectionBG.x + 15;
    skipSpr.y = selectionBG.y + (selectionBG.height - skipSpr.height) * 0.5;
    add(skipSpr);

    var continueBack = new FlxText(0, 0, 0, "to skip\nthis update");
    continueBack.setFormat(Paths.font("Funkin.ttf"), textSize, FlxColor.WHITE, "left");
    continueBack.updateHitbox();
    continueBack.x = skipSpr.x + skipSpr.width + 10;
    continueBack.y = selectionBG.y + (selectionBG.height - continueBack.height) * 0.5;
    add(continueBack);

    var enterSpr = new FlxSprite().loadGraphic(Paths.image("updater/enter"));
    enterSpr.scale.set(scaleFactor, scaleFactor);
    enterSpr.updateHitbox();
    enterSpr.x = continueBack.x + continueBack.width + 10;
    enterSpr.y = selectionBG.y + (selectionBG.height - enterSpr.height) * 0.5;
    add(enterSpr);

    var enterText = new FlxText(0, 0, 0, "to install\nthis update");
    enterText.setFormat(Paths.font("Funkin.ttf"), textSize, FlxColor.WHITE, "left");
    enterText.updateHitbox();
    enterText.x = enterSpr.x + enterSpr.width + 10;
    enterText.y = selectionBG.y + (selectionBG.height - enterText.height) * 0.5;
    add(enterText);

    var checkGithub = new FlxSprite().loadGraphic(Paths.image("updater/spc"));
    checkGithub.scale.set(scaleFactor, scaleFactor);
    checkGithub.updateHitbox();
    checkGithub.x = enterText.x + enterText.width + 10;
    checkGithub.y = selectionBG.y + (selectionBG.height - checkGithub.height) * 0.5;
    add(checkGithub);

    var checkGithubText = new FlxText(0, 0, 0, "to check\nfor updates");
    checkGithubText.setFormat(Paths.font("Funkin.ttf"), textSize, FlxColor.WHITE, "left");
    checkGithubText.updateHitbox();
    checkGithubText.x = checkGithub.x + checkGithub.width + 10;
    checkGithubText.y = selectionBG.y + (selectionBG.height - checkGithubText.height) * 0.5;
    add(checkGithubText);

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

function update(elapsed:Float) {
    avatar?.shader?.iTime += elapsed;

    if (controls.BACK) FlxG.switchState(new BetaWarningState());

    // bg?.shader?.iTime += elapsed;
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