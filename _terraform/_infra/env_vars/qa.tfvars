#provider
region = "ap-south-1"

#lables
environment = "qa"
label_order = ["name", "environment"]


#Networking
vpc_cidr            = "10.20.0.0/16"
nat_gateway_enabled = false
single_nat_gateway  = true
availability_zones  = ["us-east-1a", "us-east-1b"]

#EC2
#php_script2_clone
php_script2_clone_instance_type = "m5.xlarge"
php_script2_clone_volume_size  = 50

#php_scripts_assign
php_scripts_assign_instance_type = "m5.xlarge"
php_scripts_assign_volume_size  = 50

#php_scripts_feedback
php_scripts_feedback_instance_type  = "m5.xlarge"
php_scripts_feedback_volume_size    = 50

#MYSQL
mysql_autoassign_instance_class  = "db.t4g.xlarge"
mysql_autoassign_allocated_storage = "250"
mysql_autoassign_database_name = "autoassign"

mysql-delivery_instance_class = "db.t4g.micro"
mysql-delivery_allocated_storage = "20"
mysql-delivery_database_name = "delivery"

mysql_postgresql_instance_class = "db.t4g.micro"
mysql_postgresql_allocated_storage = "10"
mysql_postgresql_database_name = "oneclick"

mysql_oneclick4_instance_class = "db.t4g.large"
mysql_oneclick4_allocated_storage = "80"
mysql_oneclick4_database_name = "oneclick"

mysql_oneclick_instance_class = "db.t4g.micro"
mysql_oneclick_allocated_storage = "100"
mysql_oneclick_database_name = "oneclick"

mysql_Main_DB_instance_class = "db.t4g.xlarge"
mysql_Main_DB_allocated_storage = "550"
mysql_Main_DB_database_name = "Main DB"

mysql_reporting_instance_class = "db.t4g.large"
mysql_reporting_allocated_storage = "40"
mysql_reporting_database_name = "reporting"

mysql_session_instance_class = "db.t4g.medium"
mysql_sessio_allocated_storage = "150"
mysql_sessio_database_name = "session"

