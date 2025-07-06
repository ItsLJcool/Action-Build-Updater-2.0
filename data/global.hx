//a

import funkin.menus.BetaWarningState;
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

import Sys;
import Type;
import StringTools;

var url = "https://api.github.com/repos/CodenameCrew/CodenameEngine/";
var needsUpdate = false;

function new() {

    updateInformation = {};

    FlxG.save.data.autoUpdate ??= true;
    FlxG.save.flush();
    
    CoolUtil.deleteFolder('./.cache');
    CoolUtil.safeAddAttributes('./.cache/', FileAttribute.HIDDEN); // 0x2

    // if (FlxG.save.data.autoUpdate) needsUpdate = checkForActionUpdates();
    needsUpdate = checkForActionUpdates();
}

//region checking for updates

// this keeps track of only the information we specificaly need, not a billion other endpoints 😭
static var updateInformation:Dynamic = {};
static function checkForActionUpdates() {
    var newestHash = null;
    try {
        newestHash = Json.parse(HttpUtil.requestText(url+"git/refs/heads/main")).object.sha;
    } catch(e:Error) {
        trace("Failed to get current github hash: " + e);
        return false;
    }

    if (newestHash == null || StringTools.startsWith(newestHash, GitCommitMacro.commitHash)) return false;

    var userArtifact = null;
    var sysName = Sys.systemName().toLowerCase();
    try {
        var artifacts = Json.parse(HttpUtil.requestText(url+"actions/artifacts?accept=application/vnd.github+json&per_page=3")).artifacts;
        for (art in artifacts) {
            var workflow = null;
            try {
                workflow = Json.parse(HttpUtil.requestText(url+"actions/runs/"+art.workflow_run.id)).name.toLowerCase();
                if (!StringTools.contains(workflow, sysName)) continue;
            } catch(e:Error) { continue; }
            userArtifact = art;
            break;
        }
    } catch(e:Error) {
        trace("Failed to get artifacts: " + e);
        return false;
    }

    // if its null we will just assume the artifact is either gone or failed to load. Alert the user the Action Build might not exist yet.
    if (userArtifact != null && newestHash != userArtifact.workflow_run.head_sha) return false;

    generateUpdateInformation(newestHash, (userArtifact != null));
    
    return true;
}

function generateUpdateInformation(newestHash:String, hasArtifact:Bool) {
    var http = null;
    try {
        http = Json.parse(HttpUtil.requestText(url+"commits/"+newestHash));
    } catch(e:Error) {
        trace("Failed to get commit data");
        return false;
    }

    var messageCommit = http.commit.message.split("\n\n");
    for (idx=>info in messageCommit) {
        messageCommit[idx] = StringTools.trim(StringTools.replace(info, "* ", "- "));
        if (info != "---------") continue;
        messageCommit.resize(idx);
        break;
    }

    // fuck off
    var prNumber = messageCommit[0].split("(#");
    if (prNumber.length <= 1) prNumber = null;
    else prNumber = prNumber.pop().split(")");
    if (prNumber != null) {
        prNumber = prNumber.shift();
        commitTitle = "Pull Request #"+prNumber;
    }
    else {
        var contributors = null;
        try {
            contributors = Json.parse(HttpUtil.requestText(url+"contributors?anon=1&per_page=100"));
        } catch(e:Error) {
            trace("Failed gathering of contributors: " + e);
        }

        var commitAmounts:Int = 0;
        if (contributors != null) {
            for (user in contributors) {
                if (user.contributions == null) continue;
                commitAmounts += user.contributions;
            }
            commitTitle = "Commit #"+commitAmounts;
        } else commitTitle = "Commit #???";
    }

    var title = messageCommit.shift().split("(#"+prNumber+")");
    if (title == null) title = messageCommit[0];
    else title = title.shift();

    var updatedFiles = [];
    for (file in http.files) {
        updatedFiles.push({
            additions: file.additions,
            deletions: file.deletions,
            changes: file.changes,

            filename: file.filename,

            status: file.status,
        }); 
    }

    updateInformation = {
        commitTitle: StringTools.trim(commitTitle),
        title: StringTools.trim(title),
        messages: messageCommit,
        files: updatedFiles,

        stats: http.stats,

        author: {
            avatar_url: http.author.avatar_url,
            url: http.author.url,
            type: http.author.type,
            commitDate: http.commit.author.date,
            name: http.author.login,
        },

        hasArtifact: hasArtifact,
    };
}

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
    if (needsUpdate) {
        needsUpdate = false;
        FlxG.game._requestedState = new ModState("update.NewUpdate");
    }
}

function destroy() {
    checkForActionUpdates = add_roundedShader = updateInformation = null;
}