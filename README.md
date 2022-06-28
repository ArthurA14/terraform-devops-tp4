


## DEVOPS - TP4 - Cloud - Terraform
## ARTHUR ALLIE - EFREI - M1 BDIA APP

### Rappel des objectifs de ce TP : 
- Créer une machine virtuelle Azure (VM) avec une adresse IP publique
- Utiliser Terraform
- Se connecter à la VM avec SSH
- Comprendre les différents services Azure (ACI vs. AVM)
- Mettre à disposition son code dans un repository GitHub

---

- Repository GitHub associé à mon TP : 
https://github.com/ArthurA14/terraform-devops-tp4

---

### Solutions techniques employées : 
Pour réaliser ce travail, j'ai utilisé :
- ***Terraform*** : https://www.terraform.io/downloads
- ***Azure-cli*** : https://docs.microsoft.com/fr-fr/cli/azure/install-azure-cli-linux?pivots=apt
- CLI ***WSL2*** (analogue à Ubuntu, permet de bénéficier des commandes Unix)
- ***Windows 10*** comme OS

---

### Travail réalisé étape par étape : 

### 1. Installations préliminaires (facultatif) : 
J'ouvre un premier *CLI WSL2* et je commence par créer un répertoire de projet en local, que je nomme ***terraform-devops-tp4***:
````bash
$ cd ../..
$ cd Users/arthu/Efrei/DEVOPS
$ mkdir terraform-devops-tp4
$ cd terraform-devops-tp4
````

### 2. Installation de Terraform : 
- Se rendre à l'adresse suivante : https://www.terraform.io/downloads
- Ouvrir un nouveau cli *WSL2*, puis taper les commandes suivantes :
````bash
$ curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -
$ sudo apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
$ sudo apt-get update && sudo apt-get install terraform
````
- Vérifier l'installation et la version de ***Terraform*** installée : 
````bash
$ terraform --version
````
````bash
Terraform v1.2.3
on linux_amd64
````

### 3. Installation de Azure CLI : 
- Se rendre à l'adresse suivante : https://docs.microsoft.com/fr-fr/cli/azure/install-azure-cli-linux?pivots=apt
-  Dans le cli *WSL2*, taper la commande suivante :
````bash
$ sudo apt-get update
$ sudo apt-get upgrade
$ curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
````
- Puis, pour s'authentifier avec *Azure CLI*, taper : 
````bash
$ az login
````
*-> Cela me redirige vers une page web me proposant de me connecter à **Azure** avec l'adresse de mon choix. Ici, je choisis arthur.*****@efrei.net. Je suis alors redirigé vers le portail Azure.*

### 4. Configurer Azure CLI authentication dans Terraform :
- Se rendre à l'adresse suivante : https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/guides/azure_cli
- Dans le répertoire du projet en local, créer le fichier ***provider.tf*** :
````bash
$ touch provider.tf
````
-  Y copier/coller le code suivant : 
````bash
# We strongly recommend using the required_providers block to set the
# Azure Provider source and version being used
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=3.0.0"
    }
  }
}

# Configure the Microsoft Azure Provider
provider "azurerm" {
  features {}

  subscription_id = "765266c6-*********"
}
````
*-> Ici, ***"subscription_id "*** est l'identifiant de souscription au compte Azure que j'utilise.*

---

### 5. Création d'une VM Azure avec Terraform :
*Afin de créer cette machine virtuelle Azure, je dois respecter plusieurs contraintes au niveau des champs, que voici :*
	- Location : ***france central***
	- Azure Subscription ID : ***765266c6-********* *(déjà fait plus haut)*
	- Azure VM name: ***devops-20210311***
	- VM size : ***Standard_D2s_v3***
	- Utiliser Azure CLI pour l'authentification *(déjà fait plus haut)*
	- User administrateur de la VM : ***devops***
	- Créer une clef SSH avec Terraform
	- OS : ***Ubuntu 16.04-LTS***
	- resource group : ***"devops-TP2"***

#### a. Création et remplissage d'un fichier ***var.tf***, avec les champs ci-dessus *(voir https://docs.microsoft.com/fr-fr/azure/developer/terraform/create-linux-virtual-machine-with-infrastructure) :*
````bash
variable "region" {
    type = string
    default = "france central" 
} 
````
*-> Ici, j'ai notamment renseigné le champ suivant, comme demandé dans la consigne :*
	- ***default = "france central"***

#### b. Création et remplissage d'un fichier ***data.tf*** : 
````bash
data "azurerm_resource_group" "tp4" {
    name = "devops-TP2"
}

# Use already defined Virtual Network and Subnet
data "azurerm_virtual_network" "tp4" { 
    name = "example-network" 
    resource_group_name = data.azurerm_resource_group.tp4.name 
} 

data "azurerm_subnet" "tp4" { 
    name = "internal" 
    resource_group_name = data.azurerm_resource_group.tp4.name 
    virtual_network_name = data.azurerm_virtual_network.tp4.name 
}
````
*-> Ici, j'ai notamment renseigné le champ suivant, afin de spécifier le resource group utilisé :*
	- ***name =  "devops-TP2"***

#### c. Création et remplissage d'un fichier ***vm.tf***, avec les champs ci-dessus :
````bash
# Define a New Public IP Address
resource "azurerm_public_ip" "tp4ip" { 
    name = "myIp1" 
    location = var.region
    resource_group_name = data.azurerm_resource_group.tp4.name
    allocation_method = "Dynamic" 
    sku = "Basic" 
} 

# Define a Network Interface for our VM
resource "azurerm_network_interface" "tp4nic" { 
    name = "tp4-nic" 
    location = var.region
    resource_group_name = data.azurerm_resource_group.tp4.name

    ip_configuration { 
        name = data.azurerm_subnet.tp4.name
        subnet_id = data.azurerm_subnet.tp4.id
        private_ip_address_allocation = "Dynamic" 
        public_ip_address_id = azurerm_public_ip.tp4ip.id 
    } 
} 

# Define the Virtual Machine
resource "azurerm_linux_virtual_machine" "myterraformvm" { 
    name = "devops-20210311"   
    location = var.region
    resource_group_name = data.azurerm_resource_group.tp4.name
    network_interface_ids = [azurerm_network_interface.tp4nic.id]
    size = "Standard_D2s_v3" 
    admin_username = "devops" 
    
    admin_ssh_key {
        username = "devops"
        public_key = tls_private_key.ssh.public_key_openssh
    }

    source_image_reference { 
        publisher = "Canonical" 
        offer = "UbuntuServer" 
        sku = "16.04-LTS" 
        version = "latest" 
    } 

    os_disk { 
        name = "myFDisk"
        caching = "ReadWrite" 
        storage_account_type = "Standard_LRS" 
    } 
} 
````
*-> Ici, j'ai notamment renseigné les champs suivants, comme demandé dans la consigne :*
	- ***location  =  var.region*** *(récupération du champ "default" du fichier var.tf)*
	- ***name  =  "devops-20210311"*** 
	- ***size  =  "Standard_D2s_v3"*** 
	- ***admin_username  =  "devops"*** 
	- ***sku  =  "16.04-LTS"***

---

### 6. Créer une clef SSH avec Terraform
A la fin du fichier ***vm.tf***, inscrire les lignes de code suivantes, relatives à la génération d'une *"private key" ssh :*
````bash
# tls_private_key - RSA key of size 4096 bits
resource "tls_private_key" "ssh" {
    algorithm = "RSA"
    rsa_bits  = 4096
}

# private_key_pem
output "private_key" {
  value = tls_private_key.ssh.private_key_pem
  sensitive = true
}
````
*-> ***"output"*** me permettra d'utiliser ma clé privée par la suite.*

---

### 7. Création de premières ressources, dont la machine virtuelle Azure (VM) avec une adresse IP publique :
Dans mon premier *CLI WSL2*, dans le chemin répertoire du projet *****toto@DESKTOP-OBTCMJQ:/mnt/c/Users/arthu/Efrei/DEVOPS/terraform-devops-tp4$*****, je tape successivemment les commandes suivantes : 

#### a. Préparation de l'espace de travail ou de mise à jour des providers : 
````bash
$ terraform init 
````
*-> Création, dans le répertoire projet, du fichier : ***.terraform.lock.hcl****

#### b. Affichage, sans appliquer, des changements qui correspendent à la configuration : 
````bash
$ terraform plan 
````

#### c. Création ou mise à jour des ressources : 
````bash
terraform apply
````
*-> Création, dans le répertoire projet, du fichier ***terraform.tfstate*** et du répertoire ***"terraform"****
*-> Création de ma machine virtuelle Azure, à l'adresse suivante :* *https://portal.azure.com/#view/HubsExtension/BrowseResourceGroups ***-> devops-tp2 -> devops-20210311 Machine Virtuelle****
*-> Je peux donc y récupérer l'adresse IP publique associée à cette VM, qui est ici : ***20.216.173.169****

#### d. Affichage des valeurs générées en sortie par ma configuration :
````bash
$ terraform output private_key  # (cf fin du fichier vm.tf)
$ terraform output --raw private_key > privateKey.txt  # enregistrement de la private key dans un fichier privateKey.txt
````
````
-----BEGIN RSA PRIVATE KEY-----
MIIJKQIBAAKCAgEA6F8IitFUO7Wu0cDXbrXjq3b6iWyBq3MYOaAO9U2TPE59CFeZ
ajHsRdsEYdOJXUSYrJJJkRIcSuym7D8t/2r8u3D2oXXsmk46Javi7ExacXwJxkhM
JQAlrTUMiplSNHvsvPJzpqWNlu7oIMGzKtv2IGftl2P5VGaaot+z93lGz+6ooyYY
...
...
...
PNWsK3IpKn79rnt9YWDKcbK1EnRzVnyrb+THJw4b0kOOZekf09HstmXLOZJ3xsxQ
dDGwh8q/WEQKcGdp0LSoLcslawXPKMX0gijlRFBRRNFC4h+r+ucsJTT90+n776TP
5NrkBApYsv+MBpjoORmoMrQHRLzVjFJUck3dwW6Ftm+4WCSC9ddIk7f/BmnmivwN
6DSqDSOLFpxGrayMLzv7yPSKtxGRW2dIX1LpsZdvVjeOTp00X4zLsafmISSvJEf5
lRS2ZEpdmaAkuzv3GsEk8ZLBUpj9SWDYsZdDm9hlVZqj9/O6QpfddFyyU1tc
-----END RSA PRIVATE KEY-----
````
*-> Ma private key ***private_key*** a bien été générée et enregistrée dans le fichier ***privateKey.txt***, qui se trouve maintenant dans l'arborescence de mon répertoire projet.*

---

### 8. Connexion à la VM Azure avec SSH, en utilisant l'adresse IP publique de ma VM, ainsi que ma private key  :
Toujours dans mon premier *CLI WSL2*, dans le chemin répertoire de mon projet, je tape les commandes suivantes, afin de me connecter à la VM Azure avec SSH :  
````bash
ssh -i privateKey.txt devops@20.216.173.169 cat /etc/os-release
````
*-> Ici, l'adresse IP publique de ma VM est renseignée avec devops@20.216.173.169.*

*Cependant, je rencontre ici, des problèmes de permissions d'accès d'un fichier ou d'un répertoire. Je suis donc contraint de taper les commandes suivantes, afin de :*
	*- déplacer mon fichier ***privateKey.txt*** dans un dossier nommé ***"private"*** , que je crée dans l'arborescense de mon répertoire projet*
	*- copier le contenu de ce dossier ***"private"*** dans le répertoire racine de ssh : ***~/.ssh/****
* Pour ce faire, je tape les commandes supplémentaires suivantes :*
````bash
$ chmod 600 privateKey.txt

$ mv privateKey.txt private
$ chmod 600 private
$ ssh -i private devops@20.216.173.169 cat /etc/os-release
$ sudo chmod 600 private

$ cp private ~/.ssh/
$ # ls -la ~/.ssh/
$ sudo chmod 600 ~/.ssh/private
$ # ls -la ~/.ssh/
$ ssh -i ~/.ssh/private devops@20.216.173.169 cat /etc/os-release
````
*-> Cette fois-ci, ma dernière commande a bien fonctionné :*
````bash
NAME="Ubuntu"
VERSION="16.04.7 LTS (Xenial Xerus)"
ID=ubuntu
ID_LIKE=debian
PRETTY_NAME="Ubuntu 16.04.7 LTS"
VERSION_ID="16.04"
HOME_URL="http://www.ubuntu.com/"
SUPPORT_URL="http://help.ubuntu.com/"
BUG_REPORT_URL="http://bugs.launchpad.net/ubuntu/"
VERSION_CODENAME=xenial
UBUNTU_CODENAME=xenial
````
*-> La connexion à ma VM Azure avec SSH, en utilisant l'adresse IP publique de ma VM, ainsi que ma private key, a bien fonctionné.*

Pour finir, je n'oublie pas de supprimer toutes les ressources de mon compte Azure, pour ne pas consommer davantage de crédit : 
````bash
$ terraform destroy
````
