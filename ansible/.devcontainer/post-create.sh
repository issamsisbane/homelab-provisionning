#!/bin/bash
set -e

echo "🔧 Configuration post-création du container Ansible..."

# Permissions SSH
if [ -d /root/.ssh ]; then
    chmod 700 /root/.ssh
    chmod 600 /root/.ssh/* 2>/dev/null || true
    echo "✅ Permissions SSH configurées"
fi

# Créer le dossier de config Ansible s'il n'existe pas
mkdir -p /workspace/reports

# Installer Kubespray et toutes ses dépendances (depuis galaxy.yml)
echo "📦 Installation des collections Ansible..."
ansible-galaxy collection install -r requirements.yml
ansible-galaxy collection install \
    "ansible.utils>=2.5.0" \
    "community.crypto>=2.22.3" \
    "community.general>=7.0.0" \
    "ansible.netcommon>=5.3.0" \
    "ansible.posix>=1.5.4" \
    "community.docker>=3.11.0" \
    "kubernetes.core>=2.4.2"

# Vérifier qu'ansible est bien installé
echo ""
echo "📦 Versions installées :"
ansible --version | head -3
python3 --version

echo ""
echo "✅ Container prêt ! Lance ton playbook avec :"
echo "   ansible-playbook inventory_cluster.yml -i hosts.ini"
