
#!/bin/bash -x
############################################
#    Setup K8s cluster
############################################
#
#  title           :k8s_create.sh
#  description     :Setup K8s cluster
#  author          :msantos
#  date            :20180924
#  version         :0.1
#  usage           :bash k8s_create.sh
#  notes           :Prerequissites: OS Ubuntu, introduce like parametre node or master, and in case of node the token like a fichier.
#  bash_version    :
#
#==============================================================================
# Variables
DATE=`date +\%Y\%m\%d_\%Hh\%Mm\%Ss`

MTYPE="$1"
FIC_TOKEN="$2"
UNXJOB="k8s_create"
#     ------------------------------------------------------------------------
#     ------------------------------------------------------------------------

#Fucntion pour vérifier si le fichier avec e command d'ajout du noed c'est present

Test_fichier_vide()
{
  FICHIER=$1
if [[ -s ${FICHIER} ]]
then
# - Fichier pas vide - #
   RETOUR_FCT=0
else
# - Fichier vide - #
  RETOUR_FCT=1
fi
return ${RETOUR_FCT}
}


# ----------------------------------------
# ---------- Programme principal ---------
# ----------------------------------------

# Install DOCKER

apt install -y docker.io
echo "install docker"
## Modify daemon.json
cat << EOF > /etc/docker/daemon.json
   {
 "exec-opts": ["native.cgroupdriver=systemd"]
}
EOF

echo "modif json"
# Install kubernetes
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -

cat << EOF > /etc/apt/sources.list.d/kubernetes.list
# deb http://apt.kubernetes.io/ kubernetes-xenial main
deb http://apt.kubernetes.io/ kubernetes-xenial v.1.11.0
EOF

apt update
apt install -y kubelet kubeadm kubectl

echo "install kubeket"

# Pregunta= es master o nodo
if [ $MTYPE = "master" ]
 then
        echo "install init"
       kubeadm init --pod-network-cidr=10.244.0.0/16 > FIC.txt
        mkdir $HOME/.kube
        sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
        sudo chown $(id -u):$(id -g) $HOME/.kube/config
  ## Verification K8s
echo "avant get pods"
        kubectl get pods --all-namespaces
        if [ $? -ne 0 ]
        then
            echo "========================================="
            echo "== Error - Wrong Master installation ===="
            echo "========================================="
            exit 1

        else
	   kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/v0.9.1/Documentation/kube-flannel.yml
           if [ $? -ne 0 ]
           then
            echo "==============================="
            echo "== Error - Wrong Flannel   ===="
            echo "==============================="
            exit 1
           fi
           echo "fin install master"
           grep "kubeadm join"  FIC.txt > fic_token.txt
	   rm FIC.txt
        fi
#Objetivo leer ek fichero de FIC.txt y obtener linea del token para crear FIC_TOKEN
elif [ $MTYPE = "node" ]
 then
     #Verification fichier vide
     Test_fichier_vide "${FIC_TOKEN}"
     if [ $? -ne 0 ]
     then
        echo "====================================="
        echo "== Erreur Fcihier token est vide ===="
        echo "====================================="
        exit 1

    else

    cp ${FIC_TOKEN} token.sh
    ./token.sh
    ## Verification K8s type on master
    kubectl get nodes
    if [ $? -ne 0 ]
        then
            echo "========================================"
            echo "== Error - Wrong  node installation ===="
            echo "========================================"
            exit

        else
       exit
      fi


    fi
fi

exit
