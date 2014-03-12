Widgets.addView(10, 28, 643, 475)
var setupIndex = Widgets.addButton("Setup New Run", 114, 253, 211, 287, function() { setupNewRun(); }, false) - 1;
var startIndex = Widgets.addButton("Start", 16, 219, 211, 253, function() { startRun(); }, false) - 1;
var frictionIndex = Widgets.addSlider("Friction", 15, 298, 211, 331,function(newVal) {Globals.setGlobal(0, newVal);}, function() { return Globals.getGlobal(0);}, 0, .4, 0.18, .005) - 1;
Widgets.addMonitor("Height above Floor", 111, 10, 227, 55, function() { return (Dump("") + Dump(Prims.precision(Globals.getGlobal(31), 2)) + Dump(" m"))})
Widgets.addMonitor("Distance to the right", 226, 10, 351, 55, function() { return (Dump("") + Dump(Prims.precision(Globals.getGlobal(23), 2)) + Dump(" m"))})
Widgets.addMonitor("Total Score", 18, 375, 103, 424, function() { return Globals.getGlobal(40)})
Widgets.addMonitor("Score last run", 102, 375, 211, 424, function() { return scoreDisplay()})
Widgets.addMonitor("Challenge", 18, 423, 102, 472, function() { return (Dump("") + Dump(Globals.getGlobal(42)) + Dump(" of ") + Dump(Globals.getGlobal(62)))})
Widgets.addMonitor("Step", 102, 423, 211, 472, function() { return (Dump("") + Dump(Globals.getGlobal(43)) + Dump(" of ") + Dump(Globals.getGlobal(55)))})
var analyzeDataIndex = Widgets.addButton("Analyze data", 16, 253, 113, 287, function() { analyzeData(); }, false) - 1;
Widgets.addMonitor("Car Mass", 349, 10, 446, 55, function() { return (Dump("") + Dump(Globals.getGlobal(20)) + Dump(" g"))})
Widgets.addMonitor("Friction", 445, 10, 551, 55, function() { return Globals.getGlobal(0)})
Widgets.addButton("Help", 549, 10, 643, 55, function() { displayHelpMessage(); }, false)
Widgets.addOutput()

var session     = new SessionLite(document.getElementsByClassName('view-container')[0]);
var runner      = -1;
var tickCounter = document.getElementById('tick-counter');
var lastUpdate  = 0;
window.addEventListener('load', initPage);
if(useGoogleGraph) {
  session.graph = GoogleGraph
  Grapher.graph = GoogleGraph
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

var lastVisualRefresh = 0
function goForever() {
  go()

  var now = Date.now()
  if (now > (lastVisualRefresh + 1000 / visualRefreshPerSecond)) {
    Widgets.runUpdateFuncs()
    updateTickCounter();
    session.update(collectUpdates());
    lastVisualRefresh = now
  }

  lastUpdate = new Date().getTime();
  runner     = setTimeout(goForever, 1000 / calculationRefreshPerSecond);
}
startup()
goForever()
