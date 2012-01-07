﻿using System.Collections.Generic;
using ConDep.Dsl.Builders;
using ConDep.Dsl.Operations.WebDeploy.Model;
using ConDep.Dsl.Operations.WebDeploy.Options;
using NUnit.Framework;

namespace ConDep.Dsl.Tests
{
	[TestFixture]
	public abstract class ProviderTestFixture<TProvider> : SimpleTestFixture where TProvider : class, IProvide
	{
		private ProviderCollection _providers;
		private List<IProvide> _internalProviders;
		private readonly Notification _notification = new Notification();

		protected ProviderCollection Providers
		{
			get
			{
				if (_providers == null)
				{
					_internalProviders = new List<IProvide>();
					_providers = new ProviderCollection(_internalProviders);
				}
				return _providers;
			}
		}

		protected TProvider Provider
		{
			get { return _internalProviders[0] as TProvider; }
		}

		protected Notification Notification
		{
			get { return _notification; }
		}

		protected override void Given()
		{
        }

		protected override void After()
		{
		}

		[Test]
		public void should_have_no_notifications()
		{
            Provider.IsValid(Notification);
            Assert.That(Notification.HasErrors, Is.False);
		}

		//[Test]
		//public virtual void should_return_webdeploy_provider_options_without_issues()
		//{
		//   Provider.GetWebDeployDestinationObject();
		//}

		//[Test]
		//public virtual void should_return_webdeploy_deploy_object_without_issues()
		//{
		//   Provider.GetWebDeploySourceObject(new Microsoft.Web.Deployment.DeploymentBaseOptions());
		//}

	}
}   