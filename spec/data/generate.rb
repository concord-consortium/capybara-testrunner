#!/usr/bin/env ruby

# one-time utility script to generate realistic test data for from_jasmine by visiting actual Jasmine tests 
# (with some specs suitably broken)

require 'capybara'

s = Capybara::Session.new(:selenium)
s.visit("http://localhost:4020/static/tic-tac-toe/en/current/tests.html")

results_script = File.read(File.join(File.dirname(__FILE__), "..", "..", "js", "jasmine_results.js"))
results = s.evaluate_script(results_script)
f = File.open(File.join(File.dirname(__FILE__), "results.json"), "w")
f.write(JSON.pretty_generate(results))
f.close

suites = s.evaluate_script("jsApiReporter.suites()")
f = File.open(File.join(File.dirname(__FILE__), "suites.json"), "w")
f.write(JSON.pretty_generate(suites))
f.close
