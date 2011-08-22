(function() {
  var specResults = jsApiReporter.results();
  var specSuites = jsApiReporter.suites();
  var filteredResults = {
    finished: jsApiReporter.finished,
    suites: []
  };

  var tempSuites = [];

  function processSpec(spec, parents) {
    suiteName = "";
    for (var k = 0; k < parents.length; k++) {
      suiteName += parents[k].name + ".";
    }
    suiteName = suiteName.slice(0,-1);  // trim off the final period
    tempSuites[suiteName] = (tempSuites[suiteName] || { name: suiteName, results: [] });

    // sometimes there isn't a result for an id??
    var status = (specResults[spec.id] ? specResults[spec.id].result : "unknown");
    var messages = specResults[spec.id].messages;
    if (status == "passed" && messages.length == 0) {
      // this was skipped
      status = "skipped";
    }
    specResult = {
      name: spec.name,
      status: status,
      messages: []
    };
    // collect all the messages
    if (status != 'passed' && status != 'skipped' && messages.length > 0) {
      specResult['messages'] = messages.map(function(message) {
        // collect a string representation of the result message.
        return message.message;
      });
    }
    tempSuites[suiteName].results.push(specResult);
  }

  function processSuite(suite, parents) {
    if (suite.type == "suite") {
      parents.push(suite);
      for (var j = 0; j < suite.children.length; j++) {
        processSuite(suite.children[j], parents);
      }
      parents.pop();
    } else if (suite.type == "spec") {
      processSpec(suite, parents);
    }
  }

  for (var i = 0; i < specSuites.length; i++) {
    processSuite(specSuites[i], []);
  }

  for (var s in tempSuites) {
    if (typeof(s) == "string") {
      var o = tempSuites[s];
      if (o instanceof Object && o.hasOwnProperty('results')) {
        filteredResults.suites.push(o);
      }
    }
  }
  
  return filteredResults;
  
}());
