function doCommand(arg, callback) {
  window.codapPhone.call(arg, callback);
}

function record(series) {
  doCommand({
    action: 'openCase',
    args: {
      collection: "Challenge",
      values: series
    }
  }, function(result) {
    doCommand({
      action: 'closeCase',
      args: {
        collection: "Challenge",
        caseID: result.caseID
      }
    });
  });
}

function logCODAPAction(message, args) {
  doCommand({ action: "logAction", args: { formatStr: message, replaceArgs: args }});
}

function openCODAPTable() {
  doCommand({ action: "createComponent", args: { type: "DG.TableView", log: false }});
}

function clearCODAPData() {
}

var initFunc = function(iCmd, callback) {
  var operation = iCmd && iCmd.operation;
  var args      = iCmd && iCmd.args;
  switch(operation) {
    case 'saveState':
      if (typeof saveGameState !== "undefined")
        callback(saveGameState());
      break;
    case 'restoreState':
      if (typeof restoreGameState !== "undefined")
        callback(restoreGameState(args.state));
      break;
    default:
      callback({ success: false });
  }
};

window.codapPhone = new iframePhone.IframePhoneRpcEndpoint(initFunc, "codap-game", window.parent);

doCommand({
  action: 'initGame',
  args: {
    name: "Ramp Game",
    dimensions: { width: 645, height: 423 },
    collections: [
      {
        name: "Challenge",
        attrs: [ { name: "Challenge", type: "numeric", description: "BB", precision: 1 },
                 { name: "Step", type: "numeric", description: "BB", precision: 1 },
                 { name: "Start Height", type: "numeric", description: "AA", precision: 2, },
                 { name: "Friction", type: "numeric", description: "BB", precision: 2 },
                 { name: "Mass", type: "numeric", description: "BB", precision: 2 },
                 { name: "End Distance", type: "numeric", description: "BB", precision: 2 } ],
      }
    ]
  }
});
