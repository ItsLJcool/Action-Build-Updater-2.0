//a
import funkin.backend.scripting.MultiThreadedScript;
import funkin.menus.BetaWarningState;
import funkin.backend.scripting.GlobalScript;

import Sys;
import Type;
import StringTools;

final UpdateThread = new MultiThreadedScript(Paths.script("data/utils/CheckUpdatesThread"), this);

var fallbackState = data?.fallbackState ?? new BetaWarningState();
function create() {

    updateText = new FlxText(0, 0, FlxG.width*0.65, "Checking for Updates...");
    updateText.setFormat(Paths.font("Funkin.ttf"), 32, FlxColor.WHITE, "center");
    updateText.updateHitbox();
    updateText.screenCenter();
    add(updateText);

    var updateInformation = (text) -> {
        updateTextInfo.doIt = true;
        updateTextInfo.text = text;
    };

    var error = (e) -> {
        if (e != null) updateInformation("Failed to check for updates:\n\n" + e);
        new FlxTimer().start(1, () -> FlxG.switchState(fallbackState));
    };

    var finishedComplete = () -> { FlxG.switchState(new ModState("update.NewUpdate")); };

    var complete = (hash, artifact) -> {
        var needsUpdate = (hash != null);
        if (needsUpdate) {
            GlobalScript.scripts.set("needsUpdate", needsUpdate);
            updateInformation("Generating Update Information...");
            UpdateThread.call("generateUpdateInformation", [hash, (artifact != null), finishedComplete, updateInformation, error]);
        }
        else error(null);
    };
    
    UpdateThread.call("checkForActionUpdates", [complete, updateInformation, error]);
}

var updateTextInfo = {
    doIt: false,
    text: "",
};

function update(elapsed:Float) {
    if (updateTextInfo?.doIt) {
        updateTextInfo.doIt = false;
        updateText.text = updateTextInfo.text;
        updateText.updateHitbox();
        updateText.screenCenter();
    }
}