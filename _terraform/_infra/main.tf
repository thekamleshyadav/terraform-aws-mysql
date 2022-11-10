##################################### Provider #####################################
provider "aws" {
  region = var.region
}

##################################### Backend TF-state files   ######################

#terraform {
#  backend "s3" {
#    region = "us-east-1"
#  }
#}
#


#####################################  VPC   #######################################

module "vpc" {
  source = "../_modules/terraform-aws-vpc"

  name        = "vpc"
  environment = var.environment
  label_order = var.label_order
  cidr_block  = var.vpc_cidr
}

#####################################  Subnets   #####################################

module "subnets" {
  source = "../_modules/terraform-aws-subnet"

  name        = "subnets"
  environment = var.environment
  label_order = var.label_order

  nat_gateway_enabled = var.nat_gateway_enabled
  single_nat_gateway  = var.single_nat_gateway

  availability_zones = var.availability_zones
  vpc_id             = module.vpc.vpc_id
  type               = "public-private"
  igw_id             = module.vpc.igw_id
  cidr_block         = module.vpc.vpc_cidr_block
  ipv6_cidr_block    = module.vpc.ipv6_cidr_block
}

#####################################  KeyPair   #####################################

module "keypair" {
  source  = "./../_modules/terraform-aws-keypair"

  public_key      = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCRp7NTiHswlmteznuukvsZ8t+zP+MESmp/0OkxIyzZXruqBrZl/+9aoVF7Bi7UaFUAlz96/iYApA9ItT2egc+iTMOTDx063GtHSyO+ETmbuV0slG323lcA3gHpIFQ+rydmbwJ2I/J0tA+TcHNntDCwlNqU68fHmZqgOVDV5QE9pH2Ed7F9Kh0EyT4w53wQg7wOwdgNj8yNvkojJkv/PVN2ncOk2eCNRvemt439wXEwNyCeoRAXFxqvIYGZYEt69v/6ZclXlQ3ssGhgk1FzQfUFiegclJrggxBM4fPr5BGztTcrcjk4NaOmx9bKezxtCVDICZFeh7jEUDiqvSrffdat4RIcZBnhgFVknj75LRdH0zj+9QX3XNpcYbvHI4jkbLyw3AHHMayudl49FbfMDZPrXhHOGvhiwSoyMPGWWC0r6UTzzQhvqjmtetm3mt1oo/lsmsD9iUqQ9HuZoygemK8kCfj+OTqKmfXaJje2HifzVNIC29GqBScjuLm0stWNNpc= kamal@kamal"
  key_name        = var.environment
  environment     = var.environment
  label_order     = var.label_order
  enable_key_pair = var.enable_key_pair #true
}

#####################################  SG   #####################################

module "sg_ssh" {
  source      = "./../_modules/terraform-aws-security-group"

  name        = "ssh"
  environment = var.environment
  label_order = var.label_order
  vpc_id        = module.vpc.vpc_id
  allowed_ip    = [module.vpc.vpc_cidr_block]
  allowed_ports = [22]
}

module "sg_mysql" {
  source      = "./../_modules/terraform-aws-security-group"

  name        = "mysql"
  environment = var.environment
  label_order = var.label_order
  vpc_id        = module.vpc.vpc_id
  allowed_ip    = [module.vpc.vpc_cidr_block]
  allowed_ports = [3306]
}

#####################################  Ec2   #####################################

module "ec2_kms_key" {
  source                  = "./../_modules/terraform-aws-kms"
  name                    = "ec2-kms"
  environment             = var.environment
  label_order             = var.label_order
  enabled                 = true
  description             = "KMS key for ec2"
  deletion_window_in_days = 7
  enable_key_rotation     = true
  alias                   = "alias/ec2"
  policy                  = data.aws_iam_policy_document.kms.json
}

data "aws_iam_policy_document" "kms" {
  version = "2012-10-17"
  statement {
    sid    = "Enable IAM User Permissions"
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
    actions   = ["kms:*"]
    resources = ["*"]
  }

}

#ec2_php_script2_clone
module "ec2_php_script2_clone" {
  source = "./../_modules/terraform-aws-ec2"
  name        = "php-script2-clone"
  environment = var.environment
  label_order = var.label_order

  #instance
  instance_enabled = true
  instance_count   = 1
  ami              = "ami-08d658f84a6d84a80"
  instance_type    =  var.php_script2_clone_instance_type #"t2.nano"
  monitoring       = false
  tenancy          = "default"
  hibernation      = false

  #Networking
  vpc_security_group_ids_list = [module.sg_ssh.security_group_ids]
  subnet_ids                  = tolist(module.subnets.private_subnet_id)
  assign_eip_address          = false
  associate_public_ip_address = false

  #Keypair
  key_name = module.keypair.name

  #IAM
  instance_profile_enabled = false
  iam_instance_profile     = ""

  #Root Volume
  root_block_device = [
    {
      volume_type           = "gp3"
      volume_size           = var.php_script2_clone_volume_size
      iops                  = 3000
      delete_on_termination = true
      kms_key_id            = module.ec2_kms_key.key_arn

    }

  ]

  #EBS Volume
  ebs_optimized      = false
  ebs_volume_enabled = false

  # Metadata
  metadata_http_tokens_required        = "optional"
  metadata_http_endpoint_enabled       = "enabled"
  metadata_http_put_response_hop_limit = 2

}

#ec2_php_scripts_assign
module "ec2_php_scripts_assign" {
  source = "./../_modules/terraform-aws-ec2"
  name        = "php-scripts-assign"
  environment = var.environment
  label_order = var.label_order

  #instance
  instance_enabled = true
  instance_count   = 1
  ami              = "ami-08d658f84a6d84a80"
  instance_type    =  var.php_scripts_assign_instance_type #"t2.nano"
  monitoring       = false
  tenancy          = "default"
  hibernation      = false

  #Networking
  vpc_security_group_ids_list = [module.sg_ssh.security_group_ids]
  subnet_ids                  = tolist(module.subnets.private_subnet_id)
  assign_eip_address          = false
  associate_public_ip_address = false

  #Keypair
  key_name = module.keypair.name

  #IAM
  instance_profile_enabled = false
  iam_instance_profile     = ""

  #Root Volume
  root_block_device = [
    {
      volume_type           = "gp3"
      volume_size           = var.php_scripts_assign_volume_size
      iops                  = 3000
      delete_on_termination = true
      kms_key_id            = module.ec2_kms_key.key_arn

    }

  ]

  #EBS Volume
  ebs_optimized      = false
  ebs_volume_enabled = false

  # Metadata
  metadata_http_tokens_required        = "optional"
  metadata_http_endpoint_enabled       = "enabled"
  metadata_http_put_response_hop_limit = 2

}


#ec2_php_scripts_feedback
module "ec2_php_scripts_feedback" {
  source = "./../_modules/terraform-aws-ec2"
  name        = "php-scripts-feedback"
  environment = var.environment
  label_order = var.label_order

  #instance
  instance_enabled = true
  instance_count   = 1
  ami              = "ami-08d658f84a6d84a80"
  instance_type    =  var.php_scripts_feedback_instance_type #"t2.nano"
  monitoring       = false
  tenancy          = "default"
  hibernation      = false

  #Networking
  vpc_security_group_ids_list = [module.sg_ssh.security_group_ids]
  subnet_ids                  = tolist(module.subnets.private_subnet_id)
  assign_eip_address          = false
  associate_public_ip_address = false

  #Keypair
  key_name = module.keypair.name

  #IAM
  instance_profile_enabled = false
  iam_instance_profile     = ""

  #Root Volume
  root_block_device = [
    {
      volume_type           = "gp3"
      volume_size           = var.php_scripts_feedback_volume_size
      iops                  = 3000
      delete_on_termination = true
      kms_key_id            = module.ec2_kms_key.key_arn

    }

  ]

  #EBS Volume
  ebs_optimized      = false
  ebs_volume_enabled = false

  # Metadata
  metadata_http_tokens_required        = "optional"
  metadata_http_endpoint_enabled       = "enabled"
  metadata_http_put_response_hop_limit = 2

}

module "s3_extract_files" {
  source = "./../_modules/terraform-aws-s3"

  name        = "extract-files"
  environment = var.environment
  label_order = var.label_order

  versioning = true
  acl        = "private"
}

#####################################  MYSQL   #####################################

module "mysql_autoassign" {
  source = "./../_modules/terraform-aws-mysql"

  name        = "mysql-autoassign"
  environment = var.environment
  label_order = var.label_order

  engine            = "mysql"
  engine_version    = "5.7.21"
  instance_class    = var.mysql_autoassign_instance_class #"db.t2.small"
  allocated_storage = var.mysql_autoassign_allocated_storage

  # DB Details
  database_name = var.mysql_autoassign_database_name #"test"
  username      = "user"
  password      = "esfsgcGdfawAhdxtfjm!"
  port          = "3306"

  vpc_security_group_ids = [module.sg_mysql.security_group_ids]

  maintenance_window = "Mon:00:00-Mon:03:00"
  backup_window      = "03:00-06:00"
  multi_az           = false


  # disable backups to create DB faster
  backup_retention_period = 0

  enabled_cloudwatch_logs_exports = ["audit", "general"]

  # DB subnet group
  subnet_ids          = module.subnets.private_subnet_id
  publicly_accessible = true

  # DB parameter group
  family = "mysql5.7"

  # DB option group
  major_engine_version = "5.7"

  # Snapshot name upon DB deletion

  # Database Deletion Protection
  deletion_protection = false

  parameters = [
    {
      name  = "character_set_client"
      value = "utf8"
    },
    {
      name  = "character_set_server"
      value = "utf8"
    }
  ]

  options = [
    {
      option_name = "MARIADB_AUDIT_PLUGIN"

      option_settings = [
        {
          name  = "SERVER_AUDIT_EVENTS"
          value = "CONNECT"
        },
        {
          name  = "SERVER_AUDIT_FILE_ROTATIONS"
          value = "37"
        },
      ]
    },
  ]
}

#####################################  MYSQL2   #####################################
module "mysql_delivery" {
  source = "./../_modules/terraform-aws-mysql"

  name        = "mysql-delivery"
  environment = var.environment
  label_order = var.label_order

  engine            = "mysql"
  engine_version    = "5.7.21"
  instance_class    = var.mysql_delivery_instance_class #"db.t2.small"
  allocated_storage = var.mysql-delivery_allocated_storage

  # DB Details
  database_name = var.mysql-delivery_database_name #"test"
  username      = "user"
  password      = "esfsgcGdfawAhdxtfjm!"
  port          = "3306"

  vpc_security_group_ids = [module.sg_mysql.security_group_ids]

  maintenance_window = "Mon:00:00-Mon:03:00"
  backup_window      = "03:00-06:00"
  multi_az           = false


  # disable backups to create DB faster
  backup_retention_period = 0

  enabled_cloudwatch_logs_exports = ["audit", "general"]

  # DB subnet group
  subnet_ids          = module.subnets.private_subnet_id
  publicly_accessible = true

  # DB parameter group
  family = "mysql5.7"

  # DB option group
  major_engine_version = "5.7"

  # Snapshot name upon DB deletion

  # Database Deletion Protection
  deletion_protection = false

  parameters = [
    {
      name  = "character_set_client"
      value = "utf8"
    },
    {
      name  = "character_set_server"
      value = "utf8"
    }
  ]

  options = [
    {
      option_name = "MARIADB_AUDIT_PLUGIN"

      option_settings = [
        {
          name  = "SERVER_AUDIT_EVENTS"
          value = "CONNECT"
        },
        {
          name  = "SERVER_AUDIT_FILE_ROTATIONS"
          value = "37"
        },
      ]
    },
  ]
}


#####################################  MYSQL3   #####################################
module "mysql_postgresql" {
  source = "./../_modules/terraform-aws-mysql"

  name        = "mysql-postgresql"
  environment = var.environment
  label_order = var.label_order

  engine            = "mysql"
  engine_version    = "9.6"
  instance_class    = var.mysql_postgresql_instance_class #"db.t2.small"
  allocated_storage = var.mysql_postgresql_allocated_storage

  # DB Details
  database_name = var.mysql_postgresql_database_name #"test"
  username      = "user"
  password      = "esfsgcGdfawAhdxtfjm!"
  port          = "3306"

  vpc_security_group_ids = [module.sg_mysql.security_group_ids]

  maintenance_window = "Mon:00:00-Mon:03:00"
  backup_window      = "03:00-06:00"
  multi_az           = false


  # disable backups to create DB faster
  backup_retention_period = 0

  enabled_cloudwatch_logs_exports = ["audit", "general"]

  # DB subnet group
  subnet_ids          = module.subnets.private_subnet_id
  publicly_accessible = true

  # DB parameter group
  family = "mysql5.7"

  # DB option group
  major_engine_version = "5.7"

  # Snapshot name upon DB deletion

  # Database Deletion Protection
  deletion_protection = false

  parameters = [
    {
      name  = "character_set_client"
      value = "utf8"
    },
    {
      name  = "character_set_server"
      value = "utf8"
    }
  ]

  options = [
    {
      option_name = "MARIADB_AUDIT_PLUGIN"

      option_settings = [
        {
          name  = "SERVER_AUDIT_EVENTS"
          value = "CONNECT"
        },
        {
          name  = "SERVER_AUDIT_FILE_ROTATIONS"
          value = "37"
        },
      ]
    },
  ]
}


#####################################  MYSQL4   #####################################

module "mysql_oneclick4" {
  source = "./../_modules/terraform-aws-mysql"

  name        = "mysql-oneclick"
  environment = var.environment
  label_order = var.label_order

  engine            = "mysql"
  engine_version    = "5.7.21"
  instance_class    = var.mysql_oneclick4_instance_class #"db.t2.small"
  allocated_storage = var.mysql_oneclick4_allocated_storage

  # DB Details
  database_name = var.mysql_oneclick4_database_name #"test"
  username      = "user"
  password      = "esfsgcGdfawAhdxtfjm!"
  port          = "3306"

  vpc_security_group_ids = [module.sg_mysql.security_group_ids]

  maintenance_window = "Mon:00:00-Mon:03:00"
  backup_window      = "03:00-06:00"
  multi_az           = false


  # disable backups to create DB faster
  backup_retention_period = 0

  enabled_cloudwatch_logs_exports = ["audit", "general"]

  # DB subnet group
  subnet_ids          = module.subnets.private_subnet_id
  publicly_accessible = true

  # DB parameter group
  family = "mysql5.7"

  # DB option group
  major_engine_version = "5.7"

  # Snapshot name upon DB deletion

  # Database Deletion Protection
  deletion_protection = false

  parameters = [
    {
      name  = "character_set_client"
      value = "utf8"
    },
    {
      name  = "character_set_server"
      value = "utf8"
    }
  ]

  options = [
    {
      option_name = "MARIADB_AUDIT_PLUGIN"

      option_settings = [
        {
          name  = "SERVER_AUDIT_EVENTS"
          value = "CONNECT"
        },
        {
          name  = "SERVER_AUDIT_FILE_ROTATIONS"
          value = "37"
        },
      ]
    },
  ]
}

#####################################  MYSQL5   #####################################

module "mysql_oneclick5" {
  source = "./../_modules/terraform-aws-mysql"

  name        = "mysql-oneclick"
  environment = var.environment
  label_order = var.label_order

  engine            = "mysql"
  engine_version    = "5.7.21"
  instance_class    = var.mysql_oneclick_instance_class #"db.t2.small"
  allocated_storage = var.mysql_oneclick_allocated_storage

  # DB Details
  database_name = var.mysql_oneclick_database_name #"test"
  username      = "user"
  password      = "esfsgcGdfawAhdxtfjm!"
  port          = "3306"

  vpc_security_group_ids = [module.sg_mysql.security_group_ids]

  maintenance_window = "Mon:00:00-Mon:03:00"
  backup_window      = "03:00-06:00"
  multi_az           = false


  # disable backups to create DB faster
  backup_retention_period = 0

  enabled_cloudwatch_logs_exports = ["audit", "general"]

  # DB subnet group
  subnet_ids          = module.subnets.private_subnet_id
  publicly_accessible = true

  # DB parameter group
  family = "mysql5.7"

  # DB option group
  major_engine_version = "5.7"

  # Snapshot name upon DB deletion

  # Database Deletion Protection
  deletion_protection = false

  parameters = [
    {
      name  = "character_set_client"
      value = "utf8"
    },
    {
      name  = "character_set_server"
      value = "utf8"
    }
  ]

  options = [
    {
      option_name = "MARIADB_AUDIT_PLUGIN"

      option_settings = [
        {
          name  = "SERVER_AUDIT_EVENTS"
          value = "CONNECT"
        },
        {
          name  = "SERVER_AUDIT_FILE_ROTATIONS"
          value = "37"
        },
      ]
    },
  ]
}

#####################################  MYSQL6   #####################################
module "mysql-Main-DB" {
  source = "./../_modules/terraform-aws-mysql"

  name        = "mysql-Main-DB"
  environment = var.environment
  label_order = var.label_order

  engine            = "mysql"
  engine_version    = "5.7.21"
  instance_class    = var.mysql_Main_DB_instance_class #"db.t2.small"
  allocated_storage = var.mysql_Main_DB_allocated_storage

  # DB Details
  database_name = var.mysql_Main_DB_database_name #"test"
  username      = "user"
  password      = "esfsgcGdfawAhdxtfjm!"
  port          = "3306"

  vpc_security_group_ids = [module.sg_mysql.security_group_ids]

  maintenance_window = "Mon:00:00-Mon:03:00"
  backup_window      = "03:00-06:00"
  multi_az           = false


  # disable backups to create DB faster
  backup_retention_period = 0

  enabled_cloudwatch_logs_exports = ["audit", "general"]

  # DB subnet group
  subnet_ids          = module.subnets.public_subnet_id
  publicly_accessible = true

  # DB parameter group
  family = "mysql5.7"

  # DB option group
  major_engine_version = "5.7"

  # Snapshot name upon DB deletion

  # Database Deletion Protection
  deletion_protection = false

  parameters = [
    {
      name  = "character_set_client"
      value = "utf8"
    },
    {
      name  = "character_set_server"
      value = "utf8"
    }
  ]

  options = [
    {
      option_name = "MARIADB_AUDIT_PLUGIN"

      option_settings = [
        {
          name  = "SERVER_AUDIT_EVENTS"
          value = "CONNECT"
        },
        {
          name  = "SERVER_AUDIT_FILE_ROTATIONS"
          value = "37"
        },
      ]
    },
  ]
}


#####################################  MYSQL7   #####################################
module "mysql_reporting" {
  source = "./../_modules/terraform-aws-mysql"

  name        = "mysql-reporting"
  environment = var.environment
  label_order = var.label_order

  engine            = "mysql"
  engine_version    = "5.7.21"
  instance_class    = var.mysql_reporting_instance_class #"db.t2.small"
  allocated_storage = var.mysql_reporting_allocated_storage

  # DB Details
  database_name = var.mysql_reporting_database_name #"test"
  username      = "user"
  password      = "esfsgcGdfawAhdxtfjm!"
  port          = "3306"

  vpc_security_group_ids = [module.sg_mysql.security_group_ids]

  maintenance_window = "Mon:00:00-Mon:03:00"
  backup_window      = "03:00-06:00"
  multi_az           = false


  # disable backups to create DB faster
  backup_retention_period = 0

  enabled_cloudwatch_logs_exports = ["audit", "general"]

  # DB subnet group
  subnet_ids          = module.subnets.private_subnet_id
  publicly_accessible = true

  # DB parameter group
  family = "mysql5.7"

  # DB option group
  major_engine_version = "5.7"

  # Snapshot name upon DB deletion

  # Database Deletion Protection
  deletion_protection = false

  parameters = [
    {
      name  = "character_set_client"
      value = "utf8"
    },
    {
      name  = "character_set_server"
      value = "utf8"
    }
  ]

  options = [
    {
      option_name = "MARIADB_AUDIT_PLUGIN"

      option_settings = [
        {
          name  = "SERVER_AUDIT_EVENTS"
          value = "CONNECT"
        },
        {
          name  = "SERVER_AUDIT_FILE_ROTATIONS"
          value = "37"
        },
      ]
    },
  ]
}


#####################################  MYSQL8   #####################################
module "mysql_session" {
  source = "./../_modules/terraform-aws-mysql"

  name        = "mysql-session"
  environment = var.environment
  label_order = var.label_order

  engine            = "mysql"
  engine_version    = "5.7.21"
  instance_class    = var.mysql_session_instance_class #"db.t2.small"
  allocated_storage = var.mysql_sessio_allocated_storage

  # DB Details
  database_name = var.mysql_session_database_name #"test"
  username      = "user"
  password      = "esfsgcGdfawAhdxtfjm!"
  port          = "3306"

  vpc_security_group_ids = [module.sg_mysql.security_group_ids]

  maintenance_window = "Mon:00:00-Mon:03:00"
  backup_window      = "03:00-06:00"
  multi_az           = false


  # disable backups to create DB faster
  backup_retention_period = 0

  enabled_cloudwatch_logs_exports = ["audit", "general"]

  # DB subnet group
  subnet_ids          = module.subnets.private_subnet_id
  publicly_accessible = true

  # DB parameter group
  family = "mysql5.7"

  # DB option group
  major_engine_version = "5.7"

  # Snapshot name upon DB deletion

  # Database Deletion Protection
  deletion_protection = false

  parameters = [
    {
      name  = "character_set_client"
      value = "utf8"
    },
    {
      name  = "character_set_server"
      value = "utf8"
    }
  ]

  options = [
    {
      option_name = "MARIADB_AUDIT_PLUGIN"

      option_settings = [
        {
          name  = "SERVER_AUDIT_EVENTS"
          value = "CONNECT"
        },
        {
          name  = "SERVER_AUDIT_FILE_ROTATIONS"
          value = "37"
        },
      ]
    },
  ]
}



