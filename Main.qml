import QtQuick
import Quickshell.Io
import qs.Commons

Item {
  id: root

  property var pluginApi: null
  property alias codexService: codexService

  readonly property string helperPath: decodeURIComponent(
    Qt.resolvedUrl("codex_usage.py").toString().replace(/^file:\/\//, ""))

  QtObject {
    id: codexService

    property var payload: null
    property string fetchState: "idle"
    property string errorMessage: ""
    property date updatedAt: new Date(0)

    function refresh() {
      if (usageProcess.running)
        return;

      var cfg = pluginApi?.pluginSettings || {};
      var defaults = pluginApi?.manifest?.metadata?.defaultSettings || {};
      var codexPath = cfg.codexPath ?? defaults.codexPath ?? "";
      var command = ["python3", root.helperPath];
      if (codexPath.trim() !== "")
        command.push("--codex", codexPath.trim());

      fetchState = "loading";
      errorMessage = "";
      usageProcess.command = command;
      usageProcess.running = true;
    }
  }

  Process {
    id: usageProcess
    stdout: StdioCollector {}
    stderr: StdioCollector {}

    onExited: function(exitCode) {
      var raw = stdout.text.trim();
      try {
        var result = JSON.parse(raw);
        if (exitCode !== 0 || !result.ok) {
          codexService.fetchState = "error";
          codexService.errorMessage = result.error || stderr.text.trim() || ("Codex helper exited with " + exitCode);
          Logger.w("CodexUsage", codexService.errorMessage);
          return;
        }

        codexService.payload = result;
        codexService.fetchState = "success";
        codexService.updatedAt = new Date();
      } catch (error) {
        codexService.fetchState = "error";
        codexService.errorMessage = stderr.text.trim() || raw || error.toString();
        Logger.w("CodexUsage", "Invalid helper output:", codexService.errorMessage);
      }
    }
  }

  Timer {
    repeat: true
    running: pluginApi !== null
    triggeredOnStart: true
    interval: {
      var cfg = pluginApi?.pluginSettings || {};
      var defaults = pluginApi?.manifest?.metadata?.defaultSettings || {};
      var seconds = cfg.refreshIntervalSeconds ?? defaults.refreshIntervalSeconds ?? 300;
      return Math.max(60, seconds) * 1000;
    }
    onTriggered: codexService.refresh()
  }

  IpcHandler {
    target: "plugin:codex-usage"
    function refresh() {
      codexService.refresh();
    }
  }
}
