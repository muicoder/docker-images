#!/usr/bin/env sh
set -o errexit

KUBOARD_NAME='kuboard'
KUBOARD_NAMESPACE='kube-system'
KUBOARD_URL='https://kuboard.cn/install-script/kuboard.yaml'


### initial for kuboard
kubectl apply -f "$KUBOARD_URL" --validate=false

kubectl -n $KUBOARD_NAMESPACE patch deployment $KUBOARD_NAME --patch "$(
cat <<\EOF
spec:
  revisionHistoryLimit: 1
  template:
    spec:
      terminationGracePeriodSeconds: 3
      containers:
      - name: kuboard
        lifecycle:
          postStart:
            exec:
              command:
                - sh
                - -c
                - |-
                  cd /usr/share/nginx/html/js/ && {
                  sed -i 's~\(.\)=5;if~\1=1000;if~;s~signData\([^=]*\)=[^,]*~signData\1=true~' $(grep KEYUTIL.getKey -rl)
                  sed -i 's~\(.\)=.\.customResourceURL?\(.\)[^;]*~\1=\2("","")~' $(grep analytics -rl)
                  sed -i 's~.\.postersUrl~"https://rancher-mirror.cnrancher.com/index.html"~' $(grep /public/home -rl)
                  sed -i 's~frameHeight:\([^,}][0-9]*\)~frameHeight:Math.max(document.body.scrollHeight,document.body.clientHeight,\1)~;s~url:\([^{]*\)~url:\1{return this.src},URL:\1~' $(grep FRAME_ID -rl)
                  } || exit
EOF
)"
