Widgets.addView(0, 0, 643, 425);
var setupIndex = Widgets.addButton("Setup new run", 98, 224, 211, 258, function() { setupNewRun(); }, false) - 1;
var startIndex = Widgets.addButton("Start", 0, 190, 211, 224, function() { startRun(); }, false) - 1;
var frictionIndex = Widgets.addSlider("Friction", 5, 269, 206, 302,function(newVal) {Globals.setGlobal(0, newVal);}, function() { return Globals.getGlobal(0);}, 0.005, 0.4, 0.18, 0.005) - 1;
Widgets.addMonitor("Height above floor", 136, 1, 265, 46, function() { return (Dump("") + Dump(Prims.precision(Globals.getGlobal(31), 2)) + Dump(" m")); });
Widgets.addMonitor("Distance to the right", 266, 1, 404, 46, function() { return (Dump("") + Dump(Prims.precision(Globals.getGlobal(23), 2)) + Dump(" m")); });
Widgets.addMonitor("Total score", 0, 318, 101, 367, function() { return Globals.getGlobal(40); });
Widgets.addMonitor("Score last run", 102, 318, 211, 367, function() { return scoreDisplay(); });
Widgets.addMonitor("Challenge", 0, 368, 101, 417, function() { return (Dump("") + Dump(Globals.getGlobal(42)) + Dump(" of ") + Dump(Globals.getGlobal(62)));});
Widgets.addMonitor("Step", 102, 368, 211, 417, function() { return (Dump("") + Dump(Globals.getGlobal(43)) + Dump(" of ") + Dump(Globals.getGlobal(55)));});
var analyzeDataIndex = Widgets.addButton("Analyze data", 0, 224, 98, 258, function() { analyzeData(); }, false) - 1;
Widgets.addMonitor("Car mass", 405, 1, 484, 46, function() { return (Dump("") + Dump(Globals.getGlobal(20)) + Dump(" g")); });
Widgets.addMonitor("Friction", 485, 1, 551, 46, function() { return Globals.getGlobal(0); });
Widgets.addButton("Help", 551, 0, 643, 47, function() { displayHelpMessage(); }, false);
Widgets.addOutput();

var session     = new SessionLite(document.getElementsByClassName('view-container')[0]);
var runner      = -1;
var tickCounter = document.getElementById('tick-counter');
var lastUpdate  = 0;
window.addEventListener('load', initPage);
if(useGoogleGraph) {
  session.graph = GoogleGraph;
  Grapher.graph = GoogleGraph;
}

var widgets = Widgets.addTo(session);

var setupButton = widgets[setupIndex];
var startButton = widgets[startIndex];
var frictionSlider = widgets[frictionIndex];
var analyzeButton = widgets[analyzeDataIndex];

function initPage() {
  tickCounter.textContent = '0';
}

// NetLogo code visibility stuff below

const VISIBILITY_CSS = 'display';
const HIDDEN_CSS     = 'none';
const SHOW_STR       = 'Show NetLogo Code';
const HIDE_STR       = 'Hide NetLogo Code';

session.update(collectUpdates());

function updateTickCounter() {
  try {
    tickCounter.textContent = typeof world.ticks() === 'number' ? world.ticks() : '';
  } catch(err) {
  }
}

var lastVisualRefresh = 0;
function goForever() {
  go();

  var now = Date.now();
  if (now > (lastVisualRefresh + 1000 / visualRefreshPerSecond)) {
    Widgets.runUpdateFuncs();
    updateTickCounter();
    session.update(collectUpdates());
    lastVisualRefresh = now;
  }

  lastUpdate = new Date().getTime();
  runner     = setTimeout(goForever, 1000 / calculationRefreshPerSecond);
}
startup();
goForever();
