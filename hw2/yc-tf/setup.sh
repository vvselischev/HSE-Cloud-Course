#!/usr/bin/env bash

balancer_name="hw2-balancer"
db_instance_name="hw2-db"
service1_name="hw2-service-1"
service2_name="hw2-service-2"
user="ubuntu"
server_script="server.py"
remote_script_path="/home/ubuntu"
default_network_id="enpoql7vc2usdsjr3f4u"

function get_host {
	yc compute instance get $1 | grep -A 1 "one_to_one_nat:" | tail -n 1 | grep -o [\.0-9]*
}

function get_local_host {
	yc compute instance get $1 | grep -B 1 "one_to_one_nat:" | head -n 1 | grep -o [\.0-9]*
}

#terraform import yandex_vpc_network.default $default_network_id
#terraform apply

balancer_host=$(get_host $balancer_name)
db_host=$(get_host $db_instance_name)
service1_host=$(get_host $service1_name)
service2_host=$(get_host $service2_name)

db_local_host=$(get_local_host $db_instance_name)
service1_local_host=$(get_local_host $service1_name)
service2_local_host=$(get_local_host $service2_name)

function init_service {
	ssh "$user@$1" "sudo apt-get update && sudo apt install -y libpq-dev python3-dev && sudo apt install -y python3-pip && sudo pip3 install psycopg2"	
	scp $server_script $user@$1:$remote_script_path
	ssh "$user@$1" "sudo chmod +x $remote_script_path/$server_script"
	ssh "$user@$1" "nohup sudo $remote_script_path/$server_script $2 $4 >>out.txt 2>&1 &"
	yc compute instance remove-one-to-one-nat $3 --network-interface-index 0
}


# Setup db instance
ssh "$user@$db_host" 'sudo apt-get update && sudo apt-get -y install postgresql'
ssh "$user@$db_host" 'sudo -u postgres psql -c "create database service_database;"'
ssh "$user@$db_host" "echo \"\\connect service_database \\\\\\ create type status as enum ('AVAILABLE', 'NOT AVAILABLE');\" | sudo -u postgres psql"
ssh "$user@$db_host" "echo \"\\connect service_database \\\\\\ create table service_status ( id varchar(255) primary key, status status );\" | sudo -u postgres psql"

ssh "$user@$db_host" "echo \"listen_addresses = '*'\" | sudo tee -a /etc/postgresql/10/main/postgresql.conf"
ssh "$user@$db_host" "echo \"host    all             all             0.0.0.0/0            trust\" | sudo tee -a /etc/postgresql/10/main/pg_hba.conf"
ssh "$user@$db_host" "sudo service postgresql restart"
yc compute instance remove-one-to-one-nat $db_instance_name --network-interface-index 0


# Setup balancer instance
ssh "$user@$balancer_host" "sudo apt-get update && sudo apt install -y nginx -y && sudo service nginx start"
ssh "$user@$balancer_host" "sudo rm /etc/nginx/sites-enabled/default"

balancer_conf="upstream hw2balancer {
        server $service1_local_host:80;
        server $service2_local_host:80;
    }

    server {
        listen 80;

        location /healthcheck {
            proxy_pass http://hw2balancer/healthcheck;
        }
    }
"

ssh "$user@$balancer_host" "echo '$balancer_conf' | sudo tee /etc/nginx/sites-available/balancer_conf"
ssh "$user@$balancer_host" "sudo ln /etc/nginx/sites-available/balancer_conf /etc/nginx/sites-enabled/balancer_conf && sudo nginx -s reload"


# Setup services
init_service $service1_host $service1_local_host $service1_name $db_local_host
init_service $service2_host $service2_local_host $service2_name $db_local_host

