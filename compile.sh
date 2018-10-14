#/bin/bash
if [[ $EUID -ne 0 ]]; then
   echo -e "$0 must be run as root."
   exit 1
fi
echo "Enter number of threads to compile (~1.5gb ram usage per thread)"
read thr
apt-get update
apt-get install -y git build-essential libtool autotools-dev autoconf pkg-config libssl-dev libcrypto++-dev libevent-dev libminiupnpc-dev libgmp-dev libboost-all-dev devscripts libdb++-dev libsodium-dev libqt5gui5 libqt5core5a libqt5dbus5 qttools5-dev qttools5-dev-tools libprotobuf-dev protobuf-compiler libcrypto++-dev libminiupnpc-dev qt5-default
add-apt-repository ppa:bitcoin/bitcoin -y
apt-get update
apt-get install libdb4.8-dev libdb4.8++-dev gcc-5 g++-5 libssl1.0-dev libzmq3-dev -y --auto-remove
git clone https://github.com/phoenixkonsole/transcendence.git
cd transcendence
update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-5 100
update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-5 100
./autogen
./configure
make -j $thr
