#!/bin/zsh
# shellcheck shell=bash

# Author:   Stephen Warneford-Bygrave
# Name:     deploy.sh
# Version:  1.0.0
#
# Idea taken and adapted from https://inesmartins.github.io/simplest-way-to-host-your-ghost-blog-on-github-pages/index.html
#
# Purpose:  placeholder2
#
# Usage:    placeholder3
#
# 1.0.0:    2022-08-21
#           SB - Initial Creation

# Use at your own risk. I will accept no responsibility for loss or damage caused by this script.

##### Declare functions

# This function outputs help if either invoked manually or if an error occurs during input

showHelp()
{
    echo '
    Usage: /path/to/deploy.sh [-h] [-v] -r /path/to/local/repo -b https://example.github.io

        -h | --help         This help message
        -v | --verbose      Verbose mode. Output all the things
        -r | --local-repo   Path to local clone of the github pages repo
        -b | --blog-url     URL of the github pages blog
    '
    exit 1
}

# This function uses the native system logger to output events in this script.

writelog()
{
    # Write to system log
    /usr/bin/logger -is -t "${LOG_PROCESS}" "${1}"
}

##### Define Flags

# Use the total number of arguments provided at run time to determine the amount of iterations needed within the while
# loop (Note: The $# variable is equal to the total number of arguments provided to the script)

while [[ $# -gt 0 ]]; do
    case "${1}" in
    -r | --local-repo)
        shift
        LOCAL_REPO="${1}"
        ;;
    -b | --blog-url)
        shift
        BLOG_URL="${1}"
        ;;
    -v | --verbose)
        set -x
        ;;
    -h | --help)
        showHelp
        exit
        ;;
    *)
        showHelp
        exit
        ;;
    esac
    shift
done

##### Set variables

LOG_PROCESS="deploy"
BLOG_HOST=$(printf %s "${BLOG_URL#*//}")

# Check options are set
if [[ -z ${LOCAL_REPO} || -z ${BLOG_URL} ]]; then
    writelog "Local git repo and blog URL variables not set. Bailing..."
    showHelp
fi

# Check for wget; if it's not installed, exit
if ! which wget; then
    writelog "wget not found. Please install and try again. Bailing..."
    exit 1
fi

##### Run script

# Clear out contents of git repo to make way for 
rm -rf "${LOCAL_REPO:?}"/* &>/dev/null

# Copy blog content
wget --no-check-certificate --recursive --no-host-directories --directory-prefix="${LOCAL_REPO}" --adjust-extension --timeout=30 --no-parent --convert-links https://localhost/

# Copy 404 page
wget --no-check-certificate --no-host-directories --directory-prefix="${LOCAL_REPO}" --adjust-extension --timeout=30 --no-parent --convert-links --content-on-error --timestamping https://localhost/404.html

# Copy sitemaps
wget --no-check-certificate --recursive --no-host-directories --directory-prefix="${LOCAL_REPO}" --adjust-extension --timeout=30 --no-parent --convert-links https://localhost/sitemap.xsl
wget --no-check-certificate --recursive --no-host-directories --directory-prefix="${LOCAL_REPO}" --adjust-extension --timeout=30 --no-parent --convert-links https://localhost/sitemap.xml
wget --no-check-certificate --recursive --no-host-directories --directory-prefix="${LOCAL_REPO}" --adjust-extension --timeout=30 --no-parent --convert-links https://localhost/sitemap-pages.xml
wget --no-check-certificate --recursive --no-host-directories --directory-prefix="${LOCAL_REPO}" --adjust-extension --timeout=30 --no-parent --convert-links https://localhost/sitemap-posts.xml
wget --no-check-certificate --recursive --no-host-directories --directory-prefix="${LOCAL_REPO}" --adjust-extension --timeout=30 --no-parent --convert-links https://localhost/sitemap-authors.xml
wget --no-check-certificate --recursive --no-host-directories --directory-prefix="${LOCAL_REPO}" --adjust-extension --timeout=30 --no-parent --convert-links https://localhost/sitemap-tags.xml

# Small fix for images' srcset property
LC_ALL=C find "${LOCAL_REPO}" -type f -not -wholename "*.git*" -exec sed -i '' -e 's,srcset="/content,srcset="../content,g' {} +; 
LC_ALL=C find "${LOCAL_REPO}" -type f -not -wholename "*.git*" -exec sed -i '' -e 's,jpegg,jpeg,g' {} +;
LC_ALL=C find "${LOCAL_REPO}" -type f -not -wholename "*.git*" -exec sed -i '' -e 's,jpegeg,jpeg,g' {} +;
LC_ALL=C find "${LOCAL_REPO}" -type f -not -wholename "*.git*" -exec sed -i '' -e 's,jpegpeg,jpeg,g' {} +;
LC_ALL=C find "${LOCAL_REPO}" -type f -not -wholename "*.git*" -exec sed -i '' -e 's,jpgg,jpg,g' {} +;
LC_ALL=C find "${LOCAL_REPO}" -type f -not -wholename "*.git*" -exec sed -i '' -e 's,jpgpg,jpg,g' {} +;
LC_ALL=C find "${LOCAL_REPO}" -type f -not -wholename "*.git*" -exec sed -i '' -e 's,jpgjpg,jpg,g' {} +;
LC_ALL=C find "${LOCAL_REPO}" -type f -not -wholename "*.git*" -exec sed -i '' -e 's,pngg,png,g' {} +;
LC_ALL=C find "${LOCAL_REPO}" -type f -not -wholename "*.git*" -exec sed -i '' -e 's,pngng,png,g' {} +;
LC_ALL=C find "${LOCAL_REPO}" -type f -not -wholename "*.git*" -exec sed -i '' -e 's,pngpng,png,g' {} +;

# Replace localhost with real domain
LC_ALL=C find "${LOCAL_REPO}" -type f -not -wholename "*.git*" -exec sed -i '' -e "s,https://localhost,${BLOG_URL},g" {} +; 
LC_ALL=C find "${LOCAL_REPO}" -type f -not -wholename "*.git*" -exec sed -i '' -e "s,localhost,${BLOG_HOST},g" {} +;
LC_ALL=C find "${LOCAL_REPO}" -type f -not -wholename "*.git*" -exec sed -i '' -e 's,http://www.gravatar.com,https://www.gravatar.com,g' {} +

# Set blog CNAME
printf %s "${BLOG_HOST}" > "${LOCAL_REPO}/CNAME"

writelog "Script completed!"
