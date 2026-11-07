{ pkgs }:

pkgs.writeText "k3s.service" ''
  [Unit]
  Description=K3s Lightweight Kubernetes
  Documentation=https://docs.k3s.io
  Wants=network-online.target
  After=network-online.target

  [Service]
  Type=notify
  Delegate=yes
  KillMode=process
  Restart=always
  RestartSec=5s
  LimitNOFILE=1048576
  LimitNPROC=infinity
  LimitCORE=infinity
  TasksMax=infinity
  TimeoutStartSec=0
  Environment=PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
  ExecStart=${pkgs.k3s}/bin/k3s server --config /etc/rancher/k3s/config.yaml

  [Install]
  WantedBy=multi-user.target
''
