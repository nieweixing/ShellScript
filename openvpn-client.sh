# ! /bin/bash

set -e

OVPN_USER_KEYS_DIR=/etc/openvpn/client/keys
EASY_RSA_VERSION=easyrsa3
EASY_RSA_DIR=/etc/openvpn/easy-rsa/
PKI_DIR=$EASY_RSA_DIR/$EASY_RSA_VERSION/pki

for user in "$@"
do
  if [ -d "$OVPN_USER_KEYS_DIR/$user" ]; then
    rm -rf $OVPN_USER_KEYS_DIR/$user
    rm -rf  $PKI_DIR/reqs/$user.req
    rm -rf  $PKI_DIR/private/$user.key
    rm -rf  $PKI_DIR/issued/$user.crt
    sed -i '/'"$user"'/d' $PKI_DIR/index.txt  #通过index.txt文件查看到证书的情况，首字母为R的证书就是已经被吊销的证书。
    exit 0
  fi
  cd $EASY_RSA_DIR/$EASY_RSA_VERSION
  # 生成客户端 ssl 证书文件
  ./easyrsa build-client-full $user nopass
  # 整理下生成的文件
  mkdir -p  $OVPN_USER_KEYS_DIR/$user
  cp $PKI_DIR/ca.crt $OVPN_USER_KEYS_DIR/$user/   # CA 根证书
  cp $PKI_DIR/issued/$user.crt $OVPN_USER_KEYS_DIR/$user/   # 客户端证书
  cp $PKI_DIR/private/$user.key $OVPN_USER_KEYS_DIR/$user/  # 客户端证书密钥
  cp /etc/openvpn/client/sample.ovpn $OVPN_USER_KEYS_DIR/$user/$user.ovpn # 客户端配置文件
  sed -i 's/admin/'"$user"'/g' $OVPN_USER_KEYS_DIR/$user/$user.ovpn
  cd $OVPN_USER_KEYS_DIR
  zip -r $user.zip $user
done
exit 0
