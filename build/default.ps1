properties {
	$pwd = Split-Path $psake.build_script_file	
	$build_directory  = "$pwd\output\condep-dsl-operations"
	$configuration = "Release"
	$releaseNotes = ""
	$nunitPath = "$pwd\..\src\packages\NUnit.ConsoleRunner.3.8.0\tools"
	$nuget = "$pwd\..\tools\nuget.exe"
}
 
include .\..\tools\psake_ext.ps1

Framework '4.6x64'

function GetNugetAssemblyVersion($assemblyPath) {
    
    if(Test-Path Env:\APPVEYOR_BUILD_VERSION)
    {
        $appVeyorBuildVersion = $env:APPVEYOR_BUILD_VERSION
     
		# Getting the version number. Without the beta part, if its a beta package   
        $version = $appVeyorBuildVersion.Split('.')
        $major = $version[0] 
        $minor = $version[1] 
        $patch = $version[2].Split('-') | Select-Object -First 1

        # Setting beta postfix, if beta build. The beta number must be 5 digits, therefor this operation.
        $betaString = ""
        if($appVeyorBuildVersion.Contains("beta"))
        {
        	$buildNumber = $appVeyorBuildVersion.Split('-') | Select-Object -Last 1 | % {$_.replace("beta","")}
        	switch ($buildNumber.length) 
        	{	 
            	1 {$buildNumber = $buildNumber.Insert(0, '0').Insert(0, '0').Insert(0, '0').Insert(0, '0')} 
            	2 {$buildNumber = $buildNumber.Insert(0, '0').Insert(0, '0').Insert(0, '0')} 
            	3 {$buildNumber = $buildNumber.Insert(0, '0').Insert(0, '0')}
            	4 {$buildNumber = $buildNumber.Insert(0, '0')}                
            	default {$buildNumber = $buildNumber}
        	}
        	$betaString = "-beta$buildNumber" 
        }	
        return "$major.$minor.$patch$betaString"
    }
    else
    {
		#When building on local machine, set versionnumber from assembly info.
        $versionInfo = Get-Item $assemblyPath | % versioninfo
        return "$($versionInfo.FileVersion)"
    }
}

task default -depends Build-All, Test-All, Pack-All
task ci -depends Build-All, Pack-All

task Build-All -depends Clean, RestoreNugetPackages, Build, Check-VersionExists, Create-BuildSpec-ConDep-Dsl-Operations
task Test-All -depends Test
task Pack-All -depends Pack-ConDep-Dsl-Operations

task Check-VersionExists {
	$version = $(GetNugetAssemblyVersion $build_directory\ConDep.Dsl.Operations\ConDep.Dsl.Operations.dll) 
	Exec { 
		$packages = & $nuget list "ConDep.Dsl.Operations" -source "https://www.myget.org/F/condep/api/v3/index.json" -prerelease -allversions
		ForEach($package in $packages){
			$packageName = $package.Split(' ') | Select-Object -First 1
			if($packageName -eq "ConDep.Dsl.Operations"){
				$packageVersionNumber = $package.Split(' ') | Select-Object -Last 1
				if($packageVersionNumber -eq $version){
					throw "ConDep.Dsl.Operations $packageVersionNumber already exists on myget. Have you forgot to update version in appveyor.yml?"
				}
			}
		}
	}
}

task RestoreNugetPackages {
	Exec { & $nuget restore "$pwd\..\src\condep-dsl-operations.sln" }
}

task Build {
	Exec { msbuild "$pwd\..\src\condep-dsl-operations.sln" /t:Build /p:Configuration=$configuration /p:OutDir=$build_directory /p:GenerateProjectSpecificOutputFolder=true}
}

task Test {
    Exec { & $nunitPath\nunit3-console.exe $build_directory\ConDep.Dsl.Operations.Tests\ConDep.Dsl.Operations.Tests.dll --work=".\output" }
}

task Clean {
	Write-Host "Cleaning Build output"  -ForegroundColor Green
	Remove-Item $build_directory -Force -Recurse -ErrorAction SilentlyContinue
}

task Create-BuildSpec-ConDep-Dsl-Operations {
	Generate-Nuspec-File `
		-file "$build_directory\condep.dsl.operations.nuspec" `
		-version $(GetNugetAssemblyVersion $build_directory\ConDep.Dsl.Operations\ConDep.Dsl.Operations.dll) `
		-id "ConDep.Dsl.Operations" `
		-title "ConDep.Dsl.Operations" `
		-licenseUrl "http://www.condep.io/license/" `
		-projectUrl "http://www.condep.io/" `
		-description "ConDep is a highly extendable Domain Specific Language for Continuous Deployment, Continuous Delivery and Infrastructure as Code on Windows. This package contians all the default operations found in ConDep. For additional operations, look for ConDep.Dsl.Operations.Contrib." `
		-iconUrl "https://raw.github.com/condep/ConDep/master/images/ConDepNugetLogo.png" `
		-releaseNotes "$releaseNotes" `
		-tags "Continuous Deployment Delivery Infrastructure WebDeploy Deploy msdeploy IIS automation powershell remote aws azure" `
		-dependencies @(
			@{ Name="ConDep.Dsl"; Version="[5.0.1,6)"},
			@{ Name="SlowCheetah.Tasks.Unofficial"; Version="1.0.0"}
		) `
		-files @(
			@{ Path="ConDep.Dsl.Operations\ConDep.Dsl.Operations.dll"; Target="lib/net45"}, 
			@{ Path="ConDep.Dsl.Operations\ConDep.Dsl.Operations.xml"; Target="lib/net45"}
		)
}

task Pack-ConDep-Dsl-Operations {
	Exec { & $nuget pack "$build_directory\condep.dsl.operations.nuspec" -OutputDirectory "$build_directory" }
}
