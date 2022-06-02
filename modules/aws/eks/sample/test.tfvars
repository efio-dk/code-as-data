name_prefix = "stage-"

config = {
  vpc_id               = "vpc-03189122694735365"
  subnet_ids           = ["subnet-08e3d1118eb6b4d84", "subnet-06bcacd8e0871b2a1", "subnet-02ff3c3900eb2f3d5"]
  worker_node_count    = 1
  worker_instance_type = "t3.small"
  worker_volume_size   = 20
  api_allowed_ips = [
    "83.151.137.82/32", // efio office
  ]
  addons = ["aws-ebs-csi-driver"]
}