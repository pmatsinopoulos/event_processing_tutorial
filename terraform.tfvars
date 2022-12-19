company_name   = "pmatsinopoulos"
project        = "msk-demo"
region         = "eu-west-1"
profile        = "me"
vpc_cidr_block = "172.32.0.0/24" # 255 IP addresses
vpc_subnets = {
  1 : {
    cidr_block : "172.32.0.0/28" # 16 IP addresses
    region_suffix : "a"
  },
  2 : {
    cidr_block : "172.32.0.16/28" # 16 IP addresses
    region_suffix : "b"
  },
  3 : {
    cidr_block : "172.32.0.32/28" # 16 IP addresses
    region_suffix : "c"
  }
}
aws_managed_kafka_key = "447f4c1e-5b6b-4036-bbc4-6fd746983830"
brokers = {
  instance_type       = "kafka.m5.large"
  storage_volume_size = 1000
}

number_of_nodes = 3
kafka_version   = "3.2.0"
scala_version   = "2.13"
aws_ec2_client = {
  key_pair      = "me-ireland"
  instance_type = "t2.micro"
}
