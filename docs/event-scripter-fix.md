# Event Scripter fix (optional add-on)

**You only need this if you use the Event Scripter extension and its script editor will not
open on a dark theme. The JD Plain Dark theme itself needs none of this — it stays pure config.**

## The problem

On any FlatLaf dark Look and Feel (this theme, or JDownloader's own `flatlaf-themes` dark),
opening the **Event Scripter** script editor does nothing. In **Settings, Event Scripter**,
clicking **edit** on a script (or **Add**) never opens the *Script Editor* window. The only
trace is a background error like `IllegalStateException: Dialog has not been closed yet`.

This is a JDownloader bug, not a theme bug: two latent `NullPointerException`s in JD's bundled
code fire only under FlatLaf and are swallowed silently, so the editor dialog aborts before it
appears. It has nothing to do with the colours this theme sets; the stock FlatLaf dark theme
triggers it too.

## The fix

`jd-es-fix.jar` is a tiny Java agent that null-guards both code paths at load time with a
bytecode transform. It changes nothing else, is fail-safe (any transform error leaves the
original bytes untouched), and has no effect at all unless you actually open the Event Scripter
editor under FlatLaf.

## Get the jar

Download `jd-es-fix.jar` from the [latest release](https://github.com/junkerderprovinz/jd-plain-dark/releases/latest),
or build it yourself (JDK 21+):

```sh
cd agent
curl -sSL -o asm.jar https://repo1.maven.org/maven2/org/ow2/asm/asm/9.7.1/asm-9.7.1.jar
mkdir -p out
find src -name '*.java' > sources.txt
javac --release 21 -cp asm.jar -d out @sources.txt
jar xf asm.jar org/objectweb/asm
jar cfm jd-es-fix.jar manifest.mf -C out . org
```

## Install

Put `jd-es-fix.jar` somewhere permanent (for example the JDownloader folder) and pass it to
JDownloader's JVM as a `-javaagent`. Two ways:

### Environment variable (simplest, all platforms)

Set this before launching JDownloader:

```
JAVA_TOOL_OPTIONS=-javaagent:/full/path/to/jd-es-fix.jar
```

- **Windows:** `setx JAVA_TOOL_OPTIONS "-javaagent:C:\JDownloader\jd-es-fix.jar"` then relaunch.
- **Linux/macOS:** `export JAVA_TOOL_OPTIONS=-javaagent:/opt/JDownloader/jd-es-fix.jar` in the
  shell (or launcher) that starts JDownloader.

The JVM prints `Picked up JAVA_TOOL_OPTIONS: ...` on start, and the agent logs
`[jd-es-fix] Event Scripter FlatLaf fix armed`.

### JDownloader.jar launch flag

If you start JD directly, add the flag before `-jar`:

```
java -javaagent:/full/path/to/jd-es-fix.jar -jar JDownloader.jar
```

After either method, restart JDownloader and the Event Scripter **edit** / **Add** buttons open
the script editor normally.

## What it patches

- `org.appwork.swing.components.circlebar.BasicCircleProgressBarUI` — rebinds/null-guards the
  `circleBar` field in `getPreferredSize`/`paint`/`update` (FlatLaf's second `updateUI` pass
  leaves it null on the transient progress-circle widget).
- `jsyntaxpane.actions.ScriptAction` — no-ops `install`/`getScriptFromURL` when the static
  `javax.script.ScriptEngine` is null (there is no built-in JavaScript engine since Nashorn was
  removed in Java 15).

Both are pure null-guards; neither changes behaviour when the fields are valid.
