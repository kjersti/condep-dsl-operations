properties {
	$pwd = Split-Path $psake.build_script_file	
	$build_directory  = "$pwd\output"
	$configuration = "Release"
	$condep_dsl = "ConDep.Dsl"
	$nugetVersion = "1.0.0"
	$preString = "beta"
	$releaseNotes = ""
}
 
include .\..\tools\psake_ext.ps1

function Get-Versions {
	$versionTxt = "$(Get-Content .\versions.json)"
	$versionObj = $versionTxt | ConvertFrom-Json
	return $versionObj
}

function GetNugetAssemblyVersion($assemblyPath) {
	$versionInfo = Get-Item $assemblyPath | % versioninfo

	return "$($versionInfo.FileMajorPart).$($versionInfo.FileMinorPart).$($versionInfo.FileBuildPart)-$preString"
}

task default -depends Build-All, Pack-All
task ci -depends Build-All, Pack-All

task Build-All -depends Clean, Build, Create-BuildSpec-ConDep-Dsl-Remote-Resources, Create-BuildSpec-ConDep-Dsl, Create-BuildSpec-ConDep-Dsl-Operations
task Pack-All -depends Pack-ConDep-Dsl-Remote.Resources, Pack-ConDep-Dsl-Operations, Pack-ConDep-Dsl

task Build {
	Exec { msbuild "$pwd\..\src\condep-dsl.sln" /t:Build /p:Configuration=$configuration /p:OutDir=$build_directory\condep-dsl\ /p:GenerateProjectSpecificOutputFolder=true}
}

task Clean {
	Write-Host "Cleaning Build output"  -ForegroundColor Green
	Remove-Item $build_directory -Force -Recurse -ErrorAction SilentlyContinue
}

task Create-BuildSpec-ConDep-Dsl {
	Generate-Nuspec-File `
		-file "$build_directory\condep-dsl\condep.dsl.nuspec" `
		-version $(GetNugetAssemblyVersion $build_directory\condep-dsl\ConDep.Dsl\ConDep.Dsl.dll) `
		-id "ConDep.Dsl" `
		-title "ConDep.Dsl" `
		-licenseUrl "http://www.con-dep.net/license/" `
		-projectUrl "http://www.con-dep.net/" `
		-description "Note: This package is for extending the ConDep DSL. If you're looking for ConDep to do deployment or infrastructure as code, please use the ConDep package. ConDep is a highly extendable Domain Specific Language for Continuous Deployment, Continuous Delivery and Infrastructure as Code on Windows." `
		-iconUrl "https://raw.github.com/torresdal/ConDep/master/images/ConDepNugetLogo.png" `
		-releaseNotes "$releaseNotes" `
		-tags "Continuous Deployment Delivery Infrastructure WebDeploy Deploy msdeploy IIS automation powershell remote" `
		-dependencies @(
			@{ Name="log4net"; Version="[2.0.0]"},
			@{ Name="Newtonsoft.Json"; Version="4.5.11"},
			@{ Name="SlowCheetah.Tasks.Unofficial"; Version="1.0.0"},
			@{ Name="Microsoft.AspNet.WebApi.Client"; Version="4.0.20710.0"}
		) `
		-files @(
			@{ Path="ConDep.Dsl\ConDep.Dsl.dll"; Target="lib/net40"}, 
			@{ Path="ConDep.Dsl\ConDep.Dsl.xml"; Target="lib/net40"}
		)
}

task Create-BuildSpec-ConDep-Dsl-Operations {
	Generate-Nuspec-File `
		-file "$build_directory\condep-dsl\condep.dsl.operations.nuspec" `
		-version $(GetNugetAssemblyVersion $build_directory\condep-dsl\ConDep.Dsl.Operations\ConDep.Dsl.Operations.dll) `
		-id "ConDep.Dsl.Operations" `
		-title "ConDep.Dsl.Operations" `
		-licenseUrl "http://www.con-dep.net/license/" `
		-projectUrl "http://www.con-dep.net/" `
		-description "Note: This package is for extending the ConDep DSL. If you're looking for ConDep to do deployment or infrastructure as code, please use the ConDep package. ConDep is a highly extendable Domain Specific Language for Continuous Deployment, Continuous Delivery and Infrastructure as Code on Windows." `
		-iconUrl "https://raw.github.com/torresdal/ConDep/master/images/ConDepNugetLogo.png" `
		-releaseNotes "$releaseNotes" `
		-tags "Continuous Deployment Delivery Infrastructure WebDeploy Deploy msdeploy IIS automation powershell remote" `
		-dependencies @(
			@{ Name="ConDep.Dsl"; Version="[3.0.0-beta,4)"},
			@{ Name="SlowCheetah.Tasks.Unofficial"; Version="1.0.0"}
		) `
		-files @(
			@{ Path="ConDep.Dsl.Operations\ConDep.Dsl.Operations.dll"; Target="lib/net40"}, 
			@{ Path="ConDep.Dsl.Operations\ConDep.Dsl.Operations.xml"; Target="lib/net40"}
		)
}

task Create-BuildSpec-ConDep-Dsl-Remote-Resources {
	Generate-Nuspec-File `
		-file "$build_directory\condep-dsl\condep.dsl.remote.resources.nuspec" `
		-version $(GetNugetAssemblyVersion $build_directory\condep-dsl\ConDep.Dsl.Remote.Resources\ConDep.Dsl.Remote.Resources.dll) `
		-id "ConDep.Dsl.Remote.Resources" `
		-title "ConDep.Dsl.Remote.Resources" `
		-licenseUrl "http://www.con-dep.net/license/" `
		-projectUrl "http://www.con-dep.net/" `
		-description "Remote resources used by ConDep operations server side." `
		-iconUrl "https://raw.github.com/torresdal/ConDep/master/images/ConDepNugetLogo.png" `
		-releaseNotes "$releaseNotes" `
		-tags "Continuous Deployment Delivery Infrastructure WebDeploy Deploy msdeploy IIS automation powershell remote" `
		-files @(
			@{ Path="ConDep.Dsl.Remote.Resources\ConDep.Dsl.Remote.Resources.dll"; Target="lib/net40"}
		)
}

task Pack-ConDep-Dsl-Remote.Resources {
	Exec { nuget pack "$build_directory\condep-dsl\condep.dsl.remote.resources.nuspec" -OutputDirectory "$build_directory\condep-dsl\" }
}

task Pack-ConDep-Dsl-Operations {
	Exec { nuget pack "$build_directory\condep-dsl\condep.dsl.operations.nuspec" -OutputDirectory "$build_directory\condep-dsl\" }
}

task Pack-ConDep-Dsl {
	Exec { nuget pack "$build_directory\condep-dsl\condep.dsl.nuspec" -OutputDirectory "$build_directory\condep-dsl\" }
}