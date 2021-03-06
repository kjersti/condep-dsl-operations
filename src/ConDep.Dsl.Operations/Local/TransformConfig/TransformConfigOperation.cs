using System.IO;
using System.Threading;
using ConDep.Dsl.Config;
using ConDep.Dsl.Logging;
using ConDep.Dsl.Operations.Application.Local.TransformConfig;

namespace ConDep.Dsl.Operations.Local.TransformConfig
{
	public class TransformConfigOperation : LocalOperation
	{
		private readonly string _configDirPath;
		private readonly string _configName;
		private readonly string _transformName;
	    private const string CONDEP_CONFIG_EXTENSION = ".orig.condep";

	    public TransformConfigOperation(string configDirPath, string configName, string transformName)
		{
			_configDirPath = configDirPath;
			_configName = configName;
			_transformName = transformName;
		}


	    public override Result Execute(ConDepSettings settings, CancellationToken token)
	    {
	        var result = Result.SuccessChanged();

            var configFilePath = Path.Combine(_configDirPath, _configName);
            var transformFilePath = Path.Combine(_configDirPath, _transformName);
            var backupPath = "";


            if (ConDepConfigBackupExist(_configDirPath, _configName))
            {
                Logger.Info("Using [{0}] as configuration file to transform", _configDirPath + CONDEP_CONFIG_EXTENSION);
                backupPath = Path.Combine(_configDirPath, _configName + CONDEP_CONFIG_EXTENSION);
            }
            else
            {
                BackupConfigFile(_configDirPath, _configName);
            }

            Logger.Info("Transforming [{0}] using [{1}]", configFilePath, transformFilePath);
            var trans = new SlowCheetah.Tasks.TransformXml
            {
                BuildEngine = new TransformConfigBuildEngine(),
                Source = string.IsNullOrWhiteSpace(backupPath) ? configFilePath : backupPath,
                Transform = transformFilePath,
                Destination = configFilePath
            };

            result.Data.Config = trans.Source;
            result.Data.Trasform = trans.Transform;

            var success = trans.Execute();
	        if (!success)
	        {
	            result.Success = false;
                Logger.Error($"Failed to transform [{_configName}] file.");
            }

            return result;
        }

        public override string Name => "Transform Config";

	    private bool ConDepConfigBackupExist(string dir, string name)
	    {
	        return File.Exists(Path.Combine(dir, name + CONDEP_CONFIG_EXTENSION));
	    }

	    private void BackupConfigFile(string dir, string name)
	    {
            Logger.Info("Backing up [{0}] to [{1}]", name, name + CONDEP_CONFIG_EXTENSION);
            File.Copy(Path.Combine(dir, name), Path.Combine(dir, name + CONDEP_CONFIG_EXTENSION));
	    }
	}
}