%define ver 1

Name:		opencenter-dashboard
Version:	0.2.0
Release:        %{ver}%{?dist}
Summary:	Dashboard for OpenCenter

Group:		System
License:	Apache2
URL:		https://github.com/rcbops/opencenter-dashboard.git
Source0:	opencenter-dashboard-%{version}.tgz
Source1:	opencenter-dashboard.conf
BuildRequires:	make
BuildRequires:	openssl
BuildRequires:	git
Requires:	httpd
Requires:   mod_ssl

%description
Some description


%prep
%setup -q


%build
curl https://raw.github.com/creationix/nvm/master/install.sh | sh
. ~/.bash_profile 
nvm install 0.8.18
nvm alias default 0.8.18
make deploy

%install
rm -rf $RPM_BUILD_ROOT
mkdir -p $RPM_BUILD_ROOT/usr/share/opencenter-dashboard
mkdir -p $RPM_BUILD_ROOT/etc/httpd/conf.d
cp -dpRv $RPM_BUILD_DIR/opencenter-dashboard-%{version}/public/* $RPM_BUILD_ROOT/usr/share/opencenter-dashboard/
install -m 600 $RPM_SOURCE_DIR/opencenter-dashboard.conf $RPM_BUILD_ROOT/etc/httpd/conf.d/opencenter-dashboard.conf


%clean
rm -rf $RPM_BUILD_ROOT

%post
service httpd restart


%files
%defattr(-,root,root,-)
/usr/share/opencenter-dashboard/*
%config(noreplace) /etc/httpd/conf.d/opencenter-dashboard.conf

# *******************************************************
# ATTENTION: changelog is in reverse chronological order
# *******************************************************
%changelog
* Wed Mar 20 2013 RCB Builder (rcb-deploy@lists.rackspace.com) - 0.2.0
- Fixed apache access log location

* Mon Sep 10 2012 Joseph W. Breu (joseph.breu@rackspace.com) - 0.1.0
- Initial build

