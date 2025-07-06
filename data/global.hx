//a

import funkin.editors.ui.UIState;
import funkin.backend.MusicBeatState;

import funkin.backend.system.macros.GitCommitMacro;
import funkin.backend.utils.HttpUtil;

import funkin.backend.system.Conductor;

import haxe.io.Path;
import sys.FileSystem;
import sys.io.File;
import sys.io.Process;
import funkin.backend.utils.NativeAPI;
import funkin.backend.utils.NativeAPI.FileAttribute;
import funkin.backend.utils.FileAttribute;

import funkin.options.OptionsMenu;

var needsUpdate = false;
var preloadCheckUpdate:Bool = true;

function new() {

    updateInformation = {};

    FlxG.save.data.autoUpdate ??= true;
    FlxG.save.flush();
    
    CoolUtil.deleteFolder('./.cache');
    CoolUtil.safeAddAttributes('./.cache/', FileAttribute.HIDDEN); // 0x2
}

//region checking for updates

// this keeps track of only the information we specificaly need, not a billion other endpoints 😭
static var updateInformation:Dynamic = {};

//endregion

//region helper tools

static function add_roundedShader(sprite:FlxSprite, corner_pixel:Float, ?use_pixels:Bool = true, ?custom_size:Bool = false, ?box_size:Array<Float>) {
	var custom_size = custom_size ?? false;
	var box_size = box_size ?? [sprite.width, sprite.height];
	var use_pixels = use_pixels ?? true;
	sprite.shader = new CustomShader("roundedShader");

	sprite.shader.corner_pixel = corner_pixel;
	sprite.shader.use_pixels = use_pixels;
	sprite.shader.custom_size = custom_size;
	sprite.shader.box_size = box_size;
}

static function centerToCamera(sprite:FlxSprite) {
    var camera = sprite?.camera ?? FlxG.camera;
    sprite.x = camera.width * 0.5 - sprite.width * 0.5;
    sprite.y = camera.height * 0.5 - sprite.height * 0.5;
}

//endregion

function preStateSwitch() {
    if (preloadCheckUpdate) {
        preloadCheckUpdate = false;
        MusicBeatState.skipTransIn = MusicBeatState.skipTransOut = true;
        FlxG.game._requestedState = new ModState("update.PreloadCheck");
        return;
    }
}

function destroy() {
    checkForActionUpdates = add_roundedShader = updateInformation = null;
}