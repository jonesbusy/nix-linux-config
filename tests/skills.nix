let
  config = (builtins.getFlake (toString ../.)).homeConfigurations.valentin.config;
  skills = config.programs.agent-skills.skills.explicit;
  namesFrom =
    source:
    builtins.sort builtins.lessThan (
      builtins.filter (name: skills.${name}.from == source) (builtins.attrNames skills)
    );
in
assert
  namesFrom "awesome-copilot" == [
    "codeql"
    "create-readme"
    "github-actions-efficiency"
    "github-actions-hardening"
    "github-actions-runtime-upgrade-conventions"
    "github-issues"
    "java-development"
    "lean-comments"
    "quarkus-application-development"
    "quarkus-native-and-container"
  ];
assert
  namesFrom "softaworks-agent-toolkit" == [
    "agent-md-refactor"
    "excalidraw"
    "humanizer"
    "professional-communication"
    "writing-clearly-and-concisely"
  ];
assert builtins.all (
  name:
  builtins.pathExists (
    config.programs.agent-skills.sources.softaworks-agent-toolkit.path + "/skills/${name}/SKILL.md"
  )
) (namesFrom "softaworks-agent-toolkit");
assert config.programs.agent-skills.skills.enableAll == [ "jbang-agent-skills" ];
assert builtins.pathExists (
  config.programs.agent-skills.sources.jbang-agent-skills.path + "/jbang/SKILL.md"
);
assert builtins.pathExists (
  config.programs.agent-skills.sources.jbang-agent-skills.path + "/jbang-scripting/SKILL.md"
);
assert skills."gh-fix-ci".from == "openai";
assert skills."quarkus-update".from == "quarkus";
true
