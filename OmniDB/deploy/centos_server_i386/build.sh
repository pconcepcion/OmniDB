#!/bin/sh -e

VERSION=2.1.0
ARCH=centos-i386

cd ~/OmniDB/OmniDB

echo -n "Cleaning... "
rm -rf build
rm -rf dist
rm -rf deploy/packages
echo "Done."

echo "Generating bundles... "
pyinstaller OmniDB-lin.spec
echo "Done."

echo -n "Organizing bundles..."
rm -rf build
mkdir deploy/packages
cp dist/omnidb-config/omnidb-config dist/omnidb-server/omnidb-config-server
mv dist/omnidb-server deploy/packages
rm -rf dist
echo "Done."

echo -n "Renaming bundles... "
mv deploy/packages/omnidb-server deploy/packages/omnidb-server_$VERSION-$ARCH
echo "Done."

echo "Generating tar.gz packages... "
cd deploy/packages
tar -czvf omnidb-server_$VERSION-$ARCH.tar.gz omnidb-server_$VERSION-$ARCH
echo "Done"

echo "Generating rpm packages..."
mkdir omnidb-server
cd omnidb-server
mkdir -p BUILD RPMS SOURCES SPECS
cp ../omnidb-server_$VERSION-$ARCH.tar.gz SOURCES/

cat > SPECS/omnidb-server.spec <<EOF
%global _enable_debug_package 0
%global debug_package %{nil}
%global __os_install_post /usr/lib/rpm/brp-compress %{nil}

%define _unpackaged_files_terminate_build 0
%define _topdir /root/OmniDB/OmniDB/deploy/packages/omnidb-server
%define _bindir /usr/bin
%define name omnidb-server
%define version $VERSION
%define arch $ARCH
%define longname %{name}_%{version}-%{arch}
%define configname omnidb-config-server
%define buildroot %{_topdir}/%{longname}-root

BuildRoot: %{buildroot}
BuildArch: i686
Summary: Server to manage multiple databases
License: MIT
Name: %{name}
Version: %{version}
Release: 0
Source: %{longname}.tar.gz
Prefix: /opt
Group: Development/Tools
Vendor: The OmniDB Team
AutoReqProv: no

%description
OmniDB is a web tool that simplifies database management focusing on interactivity, designed to be powerful and lightweight. OmniDB is supported by 2ndQuadrant (https://www.2ndquadrant.com)

%prep
%setup -n %{longname}

%build

%install
mkdir -p %{buildroot}/opt/%{name}
chmod 777 %{buildroot}/opt/%{name}
cp -r ./* %{buildroot}/opt/%{name}
mkdir -p %{buildroot}/%{_bindir}
ln -s /opt/%{name}/%{name} %{buildroot}/%{_bindir}/%{name}
ln -s /opt/%{name}/%{configname} %{buildroot}/%{_bindir}/%{configname}

%files
%defattr(0777,root,root,0777)
/opt/%{name}
/opt/%{name}/*
%{_bindir}/%{name}
%{_bindir}/%{configname}
EOF

rpmbuild -v -bb --clean SPECS/omnidb-server.spec
cp RPMS/i686/omnidb-server-$VERSION-0.i686.rpm ../omnidb-server_$VERSION-$ARCH.rpm
cd ..
echo "Done"

echo -n "Cleaning... "
rm -rf omnidb-server_$VERSION-$ARCH omnidb-server
echo "Done"

cd ../..
echo "All Linux server packages for OmniDB version $VERSION architecture $ARCH were successfully created."
