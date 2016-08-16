#!/bin/sh

help="WARNING: THIS SCRIPT WILL RESET ALL UNCOMMITTED CHANGES."
help="$help\n Make sure you have committed everything you need to keep before you continue."
help="$help\nINSTRUCTIONS: deploy.sh requires a target argument. Use one of these commands:"
help="$help\n $0 staging"
help="$help\n $0 production"

# Verify that there is exactly one argument and it is an expected value.
if [ $# == 1 ] && ([ $1 == 'staging' ] || [ $1 == 'production' ])
then
    printf "\nPreparing to deploy $1...\n"
    target=$1
else
    git status
    printf "\n$help\n"
    exit 1
fi

# Set any needed environment vars for build environment. Some look for the uppercase proxy vars, others lowercase.
export HTTPS_PROXY="https://proxy.myproject.com:3128"
export https_proxy="https://proxy.myproject.com:3128"

# This is an integration environment, so we temporarily install Composer. It will get removed again by the reset.
printf "\nInstalling composer.phar...\n"
wget -O composer.phar https://getcomposer.org/composer.phar
printf "\ncomposer.phar has been installed\n"

# Reset the version config template, since prior builds might have removed it.
git checkout ./config/autoload/version.local.php.dist

# Refresh the local version config file using the template and `git describe`. This is the neat part!
if [ -f ./config/autoload/version.local.php.dist ]
then
    # You must already have at least one tag set on the repo, or `git describe` will not work for this.
    version="$(git describe)"
    rm -f ./config/autoload/version.local.php
    sed "s/'application_version'.*/'application_version' => '$version',/g" <config/autoload/version.local.php.dist >config/autoload/version.local.php
    printf "\nconfig/autoload/version.local.php created with $version.\n"
else
    printf "\nERROR: config/autoload/version.local.php.dist is missing. Cannot continue.\n"
    exit 1
fi

# Reset the environment in preparation for building.
printf "\nrunning \`git reset --hard\`...\n"
# DANGER ZONE: This step will reset all uncommitted changes. Make sure you have committed everything you need to keep.
# For safety, the next line is commented out. Uncomment the next line when you really understand what's going on here.
# git reset --hard

# Deploy the general and target-specific dist files, in case they haven't already been configured.
printf "\ncopying core default dist files with --no-clobber...\n"
cp -n ./config/application.local.config.php.dist ./config/application.local.config.php
cp -n ./config/autoload/local.php.dist ./config/autoload/local.php
cp -n ./config/autoload/log.local.php.dist ./config/autoload/log.local.php
if [ $target == 'staging' ]
then
    printf "\ndeploying staging application config...\n"
    cp ./config/application.config.php.staging.dist ./config/application.config.php
    printf "\ncopying staging default dist files with --no-clobber...\n"
    cp -n ./config/autoload/staging.local.php.dist ./config/autoload/staging.local.php
fi
if [ $target == 'production' ]
then
    printf "\ndeploying production application config...\n"
    cp ./config/application.config.php.production.dist ./config/application.config.php
    printf "\ncopying production default dist files with --no-clobber...\n"
    cp -n ./config/autoload/production.local.php.dist ./config/autoload/production.local.php
fi

# Run Composer
printf "\nrunning composer installation and optimization...\n"
php ./composer.phar install --no-dev
php ./composer.phar dump-autoload --optimize

# Ensure Doctrine proxies and config caching are enabled and refreshed
printf "\nenabling doctrine caching support...\n"
cp config/autoload/doctrine.cache.local.php.dist config/autoload/doctrine.cache.local.php
printf "\nremoving old merged config cache (if there) and enable caching of configs...\n"
rm -f data/cache/*.php
printf "\nre-generating proxies...\n"
php ./vendor/bin/doctrine-module orm:generate-proxies --em=orm_default

# Clean out all unwanted environment-specific and development modules and files for the build
printf "\ndeleting the unwanted files based on which application switch is given...\n"
if [ $target == 'staging' ]
then
    printf "\ndeleting non-staging files and directories...\n"
    rm -Rf ./module/Foo
fi
if [ $target == 'production' ]
then
    printf "\ndeleting non-production files and directories...\n"
    rm -Rf ./module/Bar
fi
printf "\ndeleting development files and directories...\n"
rm -Rf ./module/Dev
rm -Rf ./documentation
rm -Rf ./puphpet
rm -Rf ./composer.*
rm -Rf ./phpcs.xml
rm -Rf ./README.md
rm -Rf ./run-tests.sh
rm -Rf ./Vagrantfile
rm -Rf ./config/autoload/*.dist
rm -Rf ./config/*.dist

printf "\n ================= $target has been built and is ready to deploy ==================== \n"
printf "\nREMINDER: Make sure you re-start the http server to ensure that APC caches get cleared.\n"
