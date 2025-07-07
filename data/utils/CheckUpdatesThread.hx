//a

import funkin.backend.system.macros.GitCommitMacro;
import funkin.backend.utils.HttpUtil;

import Sys;
import Type;
import StringTools;

var url = "https://api.github.com/repos/CodenameCrew/CodenameEngine/";

function checkForActionUpdates(?onComplete:Void->Void, ?onUpdate:Void->Void, ?onError:Void->Void) {
    var newestHash = null;
    var userArtifact = null;

    var onComplete = onComplete ?? (hash, artifact) -> {};
    var onError = onError ?? (e) -> {};
    var onUpdate = onUpdate ?? (info) -> {};
    
    onUpdate("Checking for Updates...");

    try {
        newestHash = Json.parse(HttpUtil.requestText(url+"git/refs/heads/main")).object.sha;
    } catch(e:Error) {
        trace("Failed to get current github hash: " + e);
        onError(e);
        return;
    }

    if (newestHash == null || StringTools.startsWith(newestHash, GitCommitMacro.commitHash)) {
        onComplete(); // calling without any parameters so it will be null, meaning no update.
        return;
    }

    onUpdate("Checking if Artifact Exists...");

    var sysName = Sys.systemName();
    try {
        var artifacts = Json.parse(HttpUtil.requestText(url+"actions/artifacts?accept=application/vnd.github+json&per_page=3")).artifacts;
        // there is a better way than this but this guarentees the right workflow this way.
        // going to convert these into threads later
        for (art in artifacts) {
            var workflow = null;
            onUpdate("Checking to see if Artifact exists for " + sysName);
            try {
                workflow = Json.parse(HttpUtil.requestText(url+"actions/runs/"+art.workflow_run.id)).name.toLowerCase();
                if (!StringTools.contains(workflow, sysName.toLowerCase())) continue;
            } catch(e:Error) { continue; }
            userArtifact = art;
            break;
        }
    } catch(e:Error) {
        trace("Failed to get artifacts: " + e);
        onError(e);
        return;
    }

    // if its null we will just assume the artifact is either gone or failed to load. Alert the user the Action Build might not exist yet.
    if (userArtifact != null && newestHash != userArtifact.workflow_run.head_sha) {
        onComplete(newestHash, userArtifact);
        return;
    }
    onUpdate("Checks done!");
    
    onComplete(newestHash, userArtifact);
}


function generateUpdateInformation(newestHash:String, hasArtifact:Bool, ?onComplete:Void->Void, ?onUpdate:Void->Void, ?onError:Void->Void) {

    var onComplete = onComplete ?? (hash, artifact) -> {};
    var onUpdate = onUpdate ?? (info) -> {};
    var onError = onError ?? (e) -> {};

    var http = null;
    try {
        http = Json.parse(HttpUtil.requestText(url+"commits/"+newestHash));
    } catch(e:Error) {
        trace("Failed to get commit data");
        onError(e);
        return;
    }

    var messageCommit = http.commit.message.split("\n\n");
    for (idx=>info in messageCommit) {
        messageCommit[idx] = StringTools.trim(StringTools.replace(info, "* ", "- "));
        if (info != "---------") continue;
        messageCommit.resize(idx);
        break;
    }

    // fuck off
    var prNumber = messageCommit[0].split("#");
    if (prNumber.length <= 1) prNumber = null;
    else prNumber = prNumber.pop().split(" ");
    if (prNumber != null) prNumber = prNumber.pop().split(")");
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
            onError(e);
            onUpdate("Failed gathering of contributors");
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

    onComplete();
}