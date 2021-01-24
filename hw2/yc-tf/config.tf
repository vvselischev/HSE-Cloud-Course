variable "token" {}
 
variable "folder_id" {}
 
variable "cloud_id" {}
 
variable "zone" {default = "ru-central1-a"}
 
terraform {
  required_providers {
    yandex = {
      version = ">= 0.49.0"
      source = "yandex-cloud/yandex"
    }
  }
}
 
provider "yandex" {
  token     = var.token
  cloud_id  = var.cloud_id
  folder_id = var.folder_id
  zone = var.zone
}
 
data "yandex_compute_image" "base_image" {
  family = "ubuntu-1804-lts"
}
 
resource "yandex_vpc_network" "default" {
  description = "Auto-created default network"
  name = "default"
}
 
resource "yandex_vpc_subnet" "hw2-network" {
  name           = "hw2-network"
  description    = "Subnet from Terraform"
  zone           = var.zone
  network_id     = yandex_vpc_network.default.id
  v4_cidr_blocks = ["10.10.10.0/24"]
}
 
resource "yandex_compute_instance" "hw2-balancer" {
  name        = "hw2-balancer"
  hostname    = "hw2-balancer"
  zone        = var.zone
 
  depends_on = [yandex_vpc_subnet.hw2-network]
 
  resources {
    cores  = 2
    core_fraction = 5
    memory = 1
  }
 
  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.base_image.id
      type     = "network-hdd"
      size     = "13"
    }
  }
 
  network_interface {
    subnet_id = yandex_vpc_subnet.hw2-network.id
    nat       = true
  }
 
  metadata = {
    ssh-keys = "ubuntu:${file("~/.ssh/id_rsa.pub")}"
  }
}

resource "yandex_compute_instance" "hw2-service-1" {
  name        = "hw2-service-1"
  hostname    = "hw2-service-1"
  zone        = var.zone
 
  depends_on = [yandex_vpc_subnet.hw2-network]
 
  resources {
    cores  = 2
    core_fraction = 5
    memory = 1
  }
 
  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.base_image.id
      type     = "network-hdd"
      size     = "13"
    }
  }
 
  network_interface {
    subnet_id = yandex_vpc_subnet.hw2-network.id
    nat       = true
  }
 
  metadata = {
    ssh-keys = "ubuntu:${file("~/.ssh/id_rsa.pub")}"
  }
}

resource "yandex_compute_instance" "hw2-service-2" {
  name        = "hw2-service-2"
  hostname    = "hw2-service-2"
  zone        = var.zone
 
  depends_on = [yandex_vpc_subnet.hw2-network]
 
  resources {
    cores  = 2
    core_fraction = 5
    memory = 1
  }
 
  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.base_image.id
      type     = "network-hdd"
      size     = "13"
    }
  }
 
  network_interface {
    subnet_id = yandex_vpc_subnet.hw2-network.id
    nat       = true
  }
 
  metadata = {
    ssh-keys = "ubuntu:${file("~/.ssh/id_rsa.pub")}"
  }
}

resource "yandex_compute_instance" "hw2-db" {
  name        = "hw2-db"
  hostname    = "hw2-db"
  zone        = var.zone
 
  depends_on = [yandex_vpc_subnet.hw2-network]
 
  resources {
    cores  = 2
    core_fraction = 5
    memory = 1
  }
 
  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.base_image.id
      type     = "network-hdd"
      size     = "13"
    }
  }
 
  network_interface {
    subnet_id = yandex_vpc_subnet.hw2-network.id
    nat       = true
  }
 
  metadata = {
    ssh-keys = "ubuntu:${file("~/.ssh/id_rsa.pub")}"
  }
}
