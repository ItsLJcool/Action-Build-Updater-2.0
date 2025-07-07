//a

import Sys;
import flixel.text.FlxTextBorderStyle;
import flixel.text.FlxTextFormatMarkerPair;
import flixel.text.FlxTextFormat;

import funkin.backend.MusicBeatState;

var subCam:FlxCamera = new FlxCamera();
subCam.bgColor = 0;

var colorFormatting = [
	new FlxTextFormatMarkerPair(new FlxTextFormat(FlxColor.RED), "<r>"),
	new FlxTextFormatMarkerPair(new FlxTextFormat(FlxColor.YELLOW), "<y>"),
	new FlxTextFormatMarkerPair(new FlxTextFormat(FlxColor.LIME), "<l>"),
];

function create() {
    persistentUpdate = false;
    persistentDraw = true;

    FlxG.cameras.add(subCam, false);
    subCam.alpha = 0;
    cameras = [subCam];
    

    var fadeInBG = new FlxSprite().makeSolid(FlxG.width, FlxG.height, 0xFF000000);
    fadeInBG.screenCenter();
    fadeInBG.scrollFactor.set();
    fadeInBG.alpha = 0.5;
    add(fadeInBG);
    FlxTween.tween(subCam, {alpha: 1}, 1, {ease: FlxEase.quadOut});

    var warningText = new FlxText(0, 0, FlxG.width*0.65, "<r>Warning!<r>");
    warningText.setFormat(Paths.font("Funkin.ttf"), 48, FlxColor.WHITE, "center", FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
    warningText.borderSize = 4;
    warningText.updateHitbox();
    warningText.screenCenter();
    warningText.y -= 150;
    warningText.applyMarkup(warningText.text, colorFormatting);
    add(warningText);

    var explanationText = new FlxText(0, 0, FlxG.width*0.8, "We couldn't find your <y>Action Build Artifact<y> for this update or for " + Sys.systemName()
    + "\n\nYou can continue to update, but since <y>we can't find the Action Build<y>, it probably means it <l>isn't finished building<l>, or <l>no longer exists<l>. If you see this message again after updating, <r>please check the Gihub Actions.<r>");
    explanationText.setFormat(Paths.font("Funkin.ttf"), 28, FlxColor.WHITE, "center", FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
    explanationText.borderSize = 3;
    explanationText.updateHitbox();
    explanationText.screenCenter();
    explanationText.y = warningText.y + warningText.height + 20;
    explanationText.applyMarkup(explanationText.text, colorFormatting);
    add(explanationText);

    var backSpr = new FlxSprite().loadGraphic(Paths.image("updater/bksp"));
    backSpr.scale.set(0.95, 0.95);
    backSpr.updateHitbox();
    backSpr.x = (FlxG.width - backSpr.width) * 0.15;
    backSpr.y = FlxG.height - backSpr.height - 50;
    add(backSpr);
    drawOffset(backSpr);

    var backText = new FlxText(0, 0, 0, "Go Back");
    backText.setFormat(Paths.font("Funkin.ttf"), 32, FlxColor.WHITE, "left", FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
    backText.borderSize = 3;
    backText.updateHitbox();
    backText.x = backSpr.x + backSpr.width + 10;
    backText.y = backSpr.y + (backSpr.height - backText.height) * 0.5;
    add(backText);

    var continueSpr = new FlxSprite().loadGraphic(Paths.image("updater/enter"));
    continueSpr.scale.set(0.95, 0.95);
    continueSpr.updateHitbox();
    continueSpr.x = (FlxG.width - continueSpr.width) * 0.65;
    continueSpr.y = FlxG.height - continueSpr.height - 50;
    add(continueSpr);
    drawOffset(continueSpr);

    var continueText = new FlxText(0, 0, 0, "Continue\nUpdate");
    continueText.setFormat(Paths.font("Funkin.ttf"), 32, FlxColor.WHITE, "left", FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
    continueText.borderSize = 3;
    continueText.updateHitbox();
    continueText.x = continueSpr.x + continueSpr.width + 10;
    continueText.y = continueSpr.y + (continueSpr.height - continueText.height) * 0.5;
    add(continueText);

}

var offset = FlxPoint.get(5, 5);
function drawOffset(sprite) {
    sprite.onDraw = (spr) -> {
        spr.color = FlxColor.BLACK;
        spr.x += offset.x;
        spr.y += offset.y;
        spr.draw();
        spr.color = FlxColor.WHITE;
        spr.x -= offset.x;
        spr.y -= offset.y;
        spr.draw();
    };
}

var frameBuffer:Bool = false;
function update(elapsed:Float) {
    if (!frameBuffer) return frameBuffer = true;

    if (controls.BACK) {
        
        if (!(FlxG.state is MusicBeatState)) return close();
        FlxG.state.stateScripts.set("inputBuffer", [false]);
        close();
    }
    if (controls.ACCEPT) {
        if (!(FlxG.state is MusicBeatState)) return close();
        FlxG.state.stateScripts.call("selectionTime", [true]);
        FlxG.state.stateScripts.set("inputBuffer", [false]);
        close();
    }
}

function destroy() {
    FlxTween.cancelTweensOf(subCam);
    if (FlxG.cameras.list.contains(subCam)) FlxG.cameras.remove(subCam, true);
}