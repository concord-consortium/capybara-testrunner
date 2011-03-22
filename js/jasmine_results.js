(function () {
  var specResults = jsApiReporter.results(),
      filteredResults = {},
      specId,
      specResult,
      filteredVal,
      expectation,
      i;

  for (specId in specResults) {
    if (specResults.hasOwnProperty(specId)) {

      // specResults is indexed by id of the spec. Filter out just the 'result' property and certain properties
      // of expectation messages (which can include non-serializable data)

      filteredVal = {
        result:   specResults[specId].result, 
        messages: []
      };
      
      for (i = 0; i < specResults[specId].messages.length; i++) {
        expectation = specResults[specId].messages[i];
        filteredVal.messages.push({
          passed: expectation.passed_, 
          message: expectation.message
        });
      }
      
      filteredResults[specId] = filteredVal;
    }
  }
  
  return filteredResults;
  
}());