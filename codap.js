function doCommand(action,args) {
  if(window.parent && window.parent.DG) {
    var x = window.parent.DG.currGameController.doCommand({action: action, args: args});
    return x;
  } else {
    alert("Not in datagames, couldn't do '" + action + "'!");
  }
}

function record(series) {
  if(window.parent && window.parent.DG) {
    parentCase = doCommand('openCase', {
          collection: "Challenge",
          values: series });

        doCommand('closeCase', {
          collection: "Challenge",
          caseID: parentCase.caseID
        });
  } else {
    alert("Not in datagames, couldn't record!");
  }
}

function logCODAPAction(message, args) {
  doCommand("logAction", { formatStr: message, replaceArgs: args });
}

function openCODAPTable() {
  doCommand("createComponent", { type: "DG.TableView", log: false });
}

function clearCODAPData() {
}

if(window.parent && window.parent.DG) {
  doCommand('initGame', {
    name: "Ramp Game",
    collections: [
      { name: "Challenge",
        attrs: [ { name: "Challenge", type: "numeric", description: "BB", precision: 1 },
                 { name: "Step", type: "numeric", description: "BB", precision: 1 },
                 { name: "Start Height", type: "numeric", description: "AA", precision: 0, units:"ppm" },
                 { name: "Friction", type: "numeric", description: "BB", precision: 0 },
                 { name: "Mass", type: "numeric", description: "BB", precision: 2 },
                 { name: "End Distance", type: "numeric", description: "BB", precision: 0 } ],
                 }
               ]
  });
  openCODAPTable()
}

