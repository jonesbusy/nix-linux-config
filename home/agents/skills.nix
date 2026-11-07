{
  agent-skills-nix,
  aws-agent-toolkit,
  nixpkgs,
  openai-skills,
  quarkus-skills,
  awesome-copilot,
  jbang-agent-skills,
  softaworks-agent-toolkit,
}:
{ ... }:
let
  lib = nixpkgs.lib;
  # Every skill under skills/ (core-skills, specialized-skills and any future
  # category), flattened to its directory name; the assert below rejects
  # duplicate names across categories.
  awsSkillsRoot = builtins.toPath "${aws-agent-toolkit}/skills";
  findSkillDirectories =
    root:
    let
      entries = builtins.readDir root;
      childDirectories = lib.filterAttrs (_: kind: kind == "directory") entries;
      descendants = lib.concatMap (name: findSkillDirectories (root + "/${name}")) (
        builtins.attrNames childDirectories
      );
      current = lib.optional (builtins.pathExists (root + "/SKILL.md")) {
        name = builtins.unsafeDiscardStringContext (builtins.baseNameOf root);
        source = root;
      };
    in
    current ++ descendants;
  awsSkillDirectories = findSkillDirectories awsSkillsRoot;
  awsSkillNames = map (skill: skill.name) awsSkillDirectories;
  awesomeCopilotSkillNames = [
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
  softaworksSkillNames = [
    "agent-md-refactor"
    "excalidraw"
    "humanizer"
    "professional-communication"
    "writing-clearly-and-concisely"
  ];
  agentSkillNames =
    awsSkillNames
    ++ awesomeCopilotSkillNames
    ++ softaworksSkillNames
    ++ [ "gh-fix-ci" "quarkus-update" ];
  awsExplicitSkills =
    assert builtins.length agentSkillNames == builtins.length (lib.unique agentSkillNames);
    lib.listToAttrs (
      map (
        skill:
        lib.nameValuePair skill.name {
          from = "aws";
          path = lib.removePrefix "${awsSkillsRoot}/" (toString skill.source);
          rename = skill.name;
        }
      ) awsSkillDirectories
    );
in
{
  _file = "home/agents/skills.nix";
  key = "home/agents/skills.nix";
  imports = [ agent-skills-nix.homeManagerModules.default ];

  programs.agent-skills = {
    enable = true;
    sources.aws = {
      path = builtins.toPath "${aws-agent-toolkit}";
      subdir = "skills";
    };
    sources.openai = {
      path = builtins.toPath "${openai-skills}";
      subdir = "skills/.curated";
    };
    sources.quarkus = {
      path = builtins.toPath "${quarkus-skills}";
      subdir = "skills";
    };
    sources.awesome-copilot = {
      path = builtins.toPath "${awesome-copilot}";
      subdir = "skills";
    };
    sources.jbang-agent-skills = {
      path = builtins.toPath "${jbang-agent-skills}";
    };
    sources.softaworks-agent-toolkit = {
      path = builtins.toPath "${softaworks-agent-toolkit}";
      subdir = "skills";
    };
    skills.enableAll = [ "jbang-agent-skills" ];
    skills.explicit = awsExplicitSkills // lib.listToAttrs (map (name: lib.nameValuePair name {
      from = "awesome-copilot";
      path = name;
    }) awesomeCopilotSkillNames) // lib.listToAttrs (map (name: lib.nameValuePair name {
      from = "softaworks-agent-toolkit";
      path = name;
    }) softaworksSkillNames) // {
      "gh-fix-ci" = {
        from = "openai";
        path = "gh-fix-ci";
      };
      "quarkus-update" = {
        from = "quarkus";
        path = "quarkus-update";
      };
    };
    targets.agents = {
      enable = true;
      structure = "symlink-tree";
    };
  };
}
