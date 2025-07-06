//a
import funkin.backend.scripting.MultiThreadedScript;
import funkin.menus.BetaWarningState;

import Sys;
import Type;
import StringTools;

final UpdateThread = new MultiThreadedScript(Paths.script("data/utils/CheckUpdatesThread"), this);

function create() {

    var updateText = new FlxText(0, 0, FlxG.width*0.65, "Checking for Updates...");
    updateText.setFormat(Paths.font("Funkin.ttf"), 32, FlxColor.WHITE, "center");
    updateText.updateHitbox();
    updateText.screenCenter();
    add(updateText);

    var error = (e) -> {
        if (e != null) __update("Failed to check for updates:\n\n" + e);
        new FlxTimer().start(1, () -> FlxG.switchState(new BetaWarningState()));
    };

    var __update = (text) -> {
        updateText.text = text;
        updateText.updateHitbox();
        updateText.screenCenter();
    }

    var finishedComplete = () -> { FlxG.switchState(new ModState("update.NewUpdate")); };

    var complete = (hash, artifact) -> {
        var needsUpdate = (hash != null);
        if (needsUpdate) {
            __update("Generating Update Information...");
            UpdateThread.call("generateUpdateInformation", [hash, (artifact != null), finishedComplete, __update, error]);
        }
        else error(null);
    };
    
    UpdateThread.call("checkForActionUpdates", [complete, __update, error]);
}
