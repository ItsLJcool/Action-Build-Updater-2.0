//a
import haxe.io.Path;

var musicPath = "updater/";
public function getUpdaterAudioPaths() {
    var musicFiles = [];
    for (audio in Paths.getFolderContent("music/"+musicPath)) {
        if (Path.extension(audio) != "ogg") continue;
        audio = Path.withoutExtension(audio);
        musicFiles.push(musicPath+audio);
    }

    return musicFiles;
}