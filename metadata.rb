name             "magento"
maintainer       "Cloudenablers"
maintainer_email "nagalakshmi.n@cloudenablers.com"
license          "Apache 2.0"
description      "Magento app stack"
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          "0.6.3"
recipe           "magento", "Prepares app stack for magento deployments"

%w{ debian ubuntu centos redhat fedora amazon }.each do |os|
  supports os
end

%w{ apt yum apache2 nginx mysql openssl php }.each do |cb|
  depends cb
end

depends "yum-epel"
depends "php-fpm", ">= 0.4.1"
