<?php
namespace Application\View\Helper;

use Zend\View\Helper\AbstractHelper;

class VersionMetaTag extends AbstractHelper
{
    /**
     * @var string
     */
    protected $version;

    /**
     * @param null|string $version
     */
    public function __construct($version = null)
    {
        $this->version = $version;
    }

    /**
     * @return string
     */
    public function __invoke()
    {
        if ($this->version) {
            return '<meta name="version" content="' . $this->version . '">';
        }
        return '';
    }
}
