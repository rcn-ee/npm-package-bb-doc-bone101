#!/bin/bash -e

#requirements:
#sudo apt-get install bluetooth bluez libbluetooth-dev libudev-dev python

DIR=$PWD

distro=$(lsb_release -cs)

git config --global user.name "Robert Nelson"
git config --global user.email robertcnelson@gmail.com

export NODE_PATH=/usr/local/lib/node_modules

echo "Resetting: /usr/bin/npm"
rm -rf /usr/bin/npm || true
rm -rf /usr/lib/node_modules/npm/ || true

apt update
apt upgrade
apt install nodejs --reinstall

echo "Resetting: /usr/local/lib/node_modules/"
rm -rf /usr/local/lib/node_modules/* || true

#echo "npm: [/usr/bin/npm i -g npm@4.6.1]"
#/usr/bin/npm i -g npm@4.6.1

cd ../
echo "Installing: npm-4.6.1.tgz from source"
wget -c https://registry.npmjs.org/npm/-/npm-4.6.1.tgz
if [ -d ./package/ ] ; then
	rm -rf ./package/
fi
tar xf npm-4.6.1.tgz
cd ./package/
make install
cd ../
cd ./npm-package-bb-doc-bone101/

echo "npm-deb: [`${node_bin} /usr/bin/npm --version`]"

if [ -f /usr/lib/node_modules/npm/bin/npm-cli.js ] ; then
	echo "npm4-/usr/lib/: [`${node_bin} /usr/lib/node_modules/npm/bin/npm-cli.js --version`]"
fi
if [ -f /usr/local/lib/node_modules/npm/bin/npm-cli.js ] ; then
	echo "npm4-/usr/local/lib/: [`${node_bin} /usr/local/lib/node_modules/npm/bin/npm-cli.js --version`]"
fi

npm_options="--unsafe-perm=true --progress=false --loglevel=error --prefix /usr/local"


npm_git_install () {
	if [ -d /usr/local/lib/node_modules/${npm_project}/ ] ; then
		echo "Resetting: /usr/local/lib/node_modules/${npm_project}/"
		rm -rf /usr/local/lib/node_modules/${npm_project}/ || true
	fi

	if [ -d /tmp/${git_project}/ ] ; then
		echo "Resetting: /tmp/${git_project}/"
		rm -rf /tmp/${git_project}/ || true
	fi

	git clone -b ${git_branch} ${git_user}/${git_project} /tmp/${git_project}
	if [ -d /tmp/${git_project}/ ] ; then
		echo "Cloning: ${git_user}/${git_project}"
		cd /tmp/${git_project}/
		package_version=$(cat package.json | grep version | awk -F '"' '{print $4}' || true)
		git_version=$(git rev-parse --short HEAD)

		TERM=dumb ${node_bin} ${npm_bin} install -g ${npm_options}
		cd ${DIR}/
	fi

	echo "Packaging: ${npm_project}"
	wfile="${npm_project}-${package_version}-${git_version}-${node_version}"
	cd /usr/local/lib/node_modules/
	if [ -f ${wfile}.tar.xz ] ; then
		rm -rf ${wfile}.tar.xz || true
	fi
	tar -cJf ${wfile}.tar.xz ${npm_project}/
	cd ${DIR}/

	if [ ! -f ./deploy/${distro}/${wfile}.tar.xz ] ; then
		cp -v /usr/local/lib/node_modules/${wfile}.tar.xz ./deploy/${distro}/
		echo "New Build: ${wfile}.tar.xz"
	fi

	if [ -d /tmp/${git_project}/ ] ; then
		rm -rf /tmp/${git_project}/
	fi
}

npm_pkg_install () {
	if [ -d /usr/local/lib/node_modules/${npm_project}/ ] ; then
		rm -rf /usr/local/lib/node_modules/${npm_project}/ || true
	fi

	TERM=dumb ${node_bin} ${npm_bin} install -g ${npm_options} ${npm_project}@${package_version}

	wfile="${npm_project}-${package_version}-${node_version}"
	cd /usr/local/lib/node_modules/
	if [ -f ${wfile}.tar.xz ] ; then
		rm -rf ${wfile}.tar.xz || true
	fi
	tar -cJf ${wfile}.tar.xz ${npm_project}/
	cd ${DIR}/

	if [ ! -f ./deploy/${distro}/${wfile}.tar.xz ] ; then
		cp -v /usr/local/lib/node_modules/${wfile}.tar.xz ./deploy/${distro}/
		echo "New Build: ${wfile}.tar.xz"
	fi
}

npm_install () {
	node_bin="/usr/bin/nodejs"
	if [ -f /usr/local/lib/node_modules/npm/bin/npm-cli.js ] ; then
		npm_bin="/usr/local/lib/node_modules/npm/bin/npm-cli.js"
	else
		npm_bin="/usr/lib/node_modules/npm/bin/npm-cli.js"
	fi

	unset node_version
	node_version=$(${node_bin} --version || true)

	unset npm_version
	npm_version=$(${node_bin} ${npm_bin} --version || true)


	echo "npm: [`${node_bin} ${npm_bin} --version`]"
	echo "node: [`${node_bin} --version`]"

	npm_project="async"
	package_version="2.0.0-rc.6"
	npm_pkg_install

	npm_project="async"
	package_version="2.1.2"
	npm_pkg_install

	npm_project="async"
	package_version="2.3.0"
	npm_pkg_install

	npm_project="sensortag"
	package_version="1.2.2"
	npm_pkg_install

	npm_project="sensortag"
	package_version="1.2.3"
	npm_pkg_install

	npm_project="sensortag"
	package_version="1.3.0"
	npm_pkg_install
}

npm_install
