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

# Vérifier qu'ansible est bien installé
echo ""
echo "📦 Versions installées :"
ansible --version | head -3
python3 --version

echo ""
echo "✅ Container prêt ! Lance ton playbook avec :"
echo "   ansible-playbook inventory_cluster.yml -i hosts.ini"
