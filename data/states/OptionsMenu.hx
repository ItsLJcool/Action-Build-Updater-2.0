//a
import funkin.options.type.Checkbox;
import funkin.options.type.TextOption;
import funkin.options.OptionsScreen;

import funkin.editors.ui.UIState;
import flixel.effects.FlxFlicker;

import funkin.options.OptionsMenu;

function postCreate() {
    main.add(
        new TextOption("Action Build Updater >", "Settings for the Auto Action Builds Updater", function() {
            optionsTree.add(new OptionsScreen("Action Builds Updater", "Change settings for the Action Builds Updater", getOptions()));
        })
    );
}

function getOptions() {
    var updateText = new TextOption("Check For Updates", "Check if there is an update now!");
    updateText.selectCallback = () -> {
        FlxG.game._requestedState = new ModState("update.PreloadCheck", {fallbackState: new OptionsMenu()});
    }
    var archiveCheckBox = new Checkbox("Zip Mods + Addons",
    "(Disabled for now)\n\nThis option will zip your mods and addons folder into a .archives folder so if something goes wrong, you can retrieve them!",
    "archiveFolders", /*FlxG.save.data*/{});
    var checkbox = archiveCheckBox.checkbox;
    checkbox.alpha = 0.5;
    archiveCheckBox.__text.alpha = 0.5;
    checkbox.animation.remove("checked");
    checkbox.animation.remove("checking");
    
    var unchecked = checkbox.animation.getByName("unchecked");
    checkbox.animation.add("checking", unchecked.frames, unchecked.frameRate, unchecked.loop, unchecked.flipX, unchecked.flipY);
    archiveCheckBox.offsets.set("checking", archiveCheckBox.offsets.get("unchecked"));
    return [
        new Checkbox("Auto Check for Updates", "If you want to have Automatic Updates", "autoUpdate", FlxG.save.data),
        archiveCheckBox,
        updateText,
    ];
}