using System.Globalization;
using System.Threading;
using ConDep.Dsl.Config;
using ConDep.Dsl.Operations.Infrastructure.IIS.AppPool;

namespace ConDep.Dsl.Operations.Remote.Infrastructure.IIS.AppPool
{
    public class IisAppPoolOperation : RemoteOperation
    {
        private readonly string _appPoolName;
        private readonly IisAppPoolOptions.IisAppPoolOptionsValues _appPoolOptions;

        public IisAppPoolOperation(string appPoolName)
        {
            _appPoolName = appPoolName;
        }

        public IisAppPoolOperation(string appPoolName, IisAppPoolOptions.IisAppPoolOptionsValues appPoolOptions) 
        {
            _appPoolName = appPoolName;
            _appPoolOptions = appPoolOptions;   
        }

        public override Result Execute(IOfferRemoteOperations remote, ServerConfig server, ConDepSettings settings, CancellationToken token)
        {
            var appPoolOptions = "$appPoolOptions = $null;";

            if (_appPoolOptions != null)
            {
                appPoolOptions = string.Format("$appPoolOptions = @{{Enable32Bit=${0}; IdentityUsername='{1}'; IdentityPassword='{2}'; IdleTimeoutInMinutes={3}; LoadUserProfile=${4}; ManagedPipeline={5}; NetFrameworkVersion={6}; RecycleTimeInMinutes={7}; DisableOverlappedRecycle=${8}; AlwaysOn=${9}}};"
                    , _appPoolOptions.Enable32Bit.HasValue ? _appPoolOptions.Enable32Bit.Value.ToString() : "false"
                    , _appPoolOptions.IdentityUsername
                    , _appPoolOptions.IdentityPassword
                    , _appPoolOptions.IdleTimeoutInMinutes.HasValue ? _appPoolOptions.IdleTimeoutInMinutes.Value.ToString(CultureInfo.InvariantCulture.NumberFormat) : "$null"
                    , _appPoolOptions.LoadUserProfile.HasValue ? _appPoolOptions.LoadUserProfile.Value.ToString() : "false"
                    , _appPoolOptions.ManagedPipeline.HasValue ? "'" + _appPoolOptions.ManagedPipeline.Value + "'" : "$null"
                    , _appPoolOptions.NetFrameworkVersion == null ? "$null" : ("'" + _appPoolOptions.NetFrameworkVersion + "'")
                    , _appPoolOptions.RecycleTimeInMinutes.HasValue ? _appPoolOptions.RecycleTimeInMinutes.Value.ToString(CultureInfo.InvariantCulture.NumberFormat) : "$null"
                    , _appPoolOptions.DisableOverlappedRecycle.HasValue ? _appPoolOptions.DisableOverlappedRecycle.Value.ToString() : "false"
                    , _appPoolOptions.AlwaysOn.HasValue ? _appPoolOptions.AlwaysOn.Value.ToString() : "false"
                    );
            }
            return remote.Execute.PowerShell(string.Format(@"{0} New-ConDepAppPool '{1}' $appPoolOptions;", appPoolOptions, _appPoolName)).Result;
        }

        public override string Name
        {
            get { return "IIS Application Pool"; }
        }
    }
}