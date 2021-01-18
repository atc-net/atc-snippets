# General GitHub repository setup on `atc-net`

NOTE: This repository in only usefull for ATC members - but all a allowed to copy and/or get inspired.

This is a guide / how to setup a repository in atc-net on GitHub.

The guide is a example on how to setup a repository based on a project name called "Hallo World Project". And by using the template, you can find the "Hallo World Project" and replace for correct naming and format.
The place-holders will look like this:

```
Kebab-version:

   [atc-[hallo-world-project]]]

    => atc-hallo-world-project
```

```
Pascal-dot-version:

   [Atc.[Hallo.World.Project]]]

   => Atc.Hallo.World.Project
```

Rule number one - `Name is King`.

Steps:
- Importent - Spend time on finding the right name for you project.
- Create gitgub repositiory by using `kebab-version`.


# dotnet repository

For a dotnet project, use the `repository-dotnet-template`

Steps:
- Create 3 branches:
  - main
  - stable
  - release

- Fix filename for .sln
  - Replace Pascal-dot-version

- Fix foldername under `/src`
  - Replace Pascal-dot-version

- Fix filename for `/src/Atc.[Hallo.World.Project]/Atc.[Hallo.World.Project].csproj`
  - Replace Pascal-dot-version

- Fix file content for `.sln`
  - Replace Pascal-dot-version

- Fix file content for `.csproj`
  - Replace Kebab-version
  - Replace Pascal-dot-version
  - Replace [PROJECT-TEXT]
  - Ensure
    - Sdk
    - TargetFramework
    - PackAsTool

- Fix GitHub Workflows under `/.github/workflows`
  - `pre-integration.yml`
  - `post-integration.yml`
    - Replace Kebab-version
    - Replace Pascal-dot-version
  - `release.yml`
    - Replace Pascal-dot-version
 
 - Fix README.md
   - Replace Kebab-version
   - Replace Pascal-dot-version
   - Replace [PROJECT-TEXT]

 - After first PR is pushed into the repository, an update can be made under `Branch protection rule` ->
`Require branches to be up to date before merging` with checkmarks on:
   - dotnet-test
   - dotnet5-build (macos-latest)
   - dotnet5-build (ubuntu-latest)
   - dotnet5-build (windows-latest)
