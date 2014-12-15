function doCommand(arg, callback) {
  if(window.parent && window.parent.DG) {
    return window.codapPhone.call(arg, callback);
  } else {
    alert("Not in datagames, couldn't do '" + action + "'!");
  }
}

function record(series) {
  if(window.parent && window.parent.DG) {
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
}

function logCODAPAction(message, args) {
  doCommand({ action: "logAction", args: { formatStr: message, replaceArgs: args }});
}

function openCODAPTable() {
  doCommand({ action: "createComponent", args: { type: "DG.TableView", log: false }});
}

function clearCODAPData() {
}

if(window.parent && window.parent.DG) {

  var initFunc = function(iCmd, callback) {
    var operation = iCmd && iCmd.operation;
    var args      = iCmd && iCmd.args;
    switch(operation) {
      default: callback({ success: false });
    }
  };

  window.codapPhone = new iframePhone.IframePhoneRpcEndpoint(initFunc, "codap-game", window.parent);

  doCommand({
    action: 'initGame',
    args: {
      name: "Ramp Game",
      dimensions: { width: 775, height: 450 },
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

}
