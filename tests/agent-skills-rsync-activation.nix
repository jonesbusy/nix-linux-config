let
  config = (builtins.getFlake (toString ../.)).homeConfigurations.valentin.config;
  before = config.home.activation.hermesAgentSkillsRsyncCompatibility;
  after = config.home.activation.hermesAgentSkillsRsyncCompatibilityCleanup;
  contains = needle: haystack: builtins.replaceStrings [ needle ] [ "" ] haystack != haystack;
in
assert builtins.elem "writeBoundary" before.after;
assert builtins.elem "agent-skills" before.before;
assert builtins.elem "agent-skills" after.after;
assert contains "--no-owner --no-group" before.data;
assert contains "export -f rsync" before.data;
assert contains "unset -f rsync" after.data;
true
