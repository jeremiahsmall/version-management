<?php
namespace Application\View\Helper\Factory;

use Application\View\Helper\VersionMetaTag;
use Interop\Container\ContainerInterface;

class VersionMetaTagFactory
{
    public function __invoke(ContainerInterface $container)
    {
        $config = $container->has('config') ? $container->get('config') : [];
        $version = isset($config['application_version']) ? $config['application_version'] : null;
        return new VersionMetaTag($version);
    }
}
