#!/bin/bash

echo "🛠️ Iniciando configuração do VFIO-passthrough..."

# 1. Configura o vfio.conf com os dispositivos corretos
cat <<EOF > /etc/modprobe.d/pve-vfio.conf
options vfio-pci ids=1002:67df,1002:aaf0,8086:8d31,8086:8d26,8086:8d2d,14e4:43a0,1cc1:621a,8086:8d02 disable_vga=1
options vfio-pci disable_idle_d3=1
EOF
echo "✅ pve-vfio.conf criado."

# 2. Blacklist dos drivers conflitantes
cat <<EOF > /etc/modprobe.d/pve-blacklist.conf
blacklist radeon
blacklist amdgpu
blacklist snd_hda_intel
blacklist snd_hda_codec_hdmi
blacklist iwlwifi
blacklist btusb
blacklist btrtl
blacklist btbcm
blacklist btintel
blacklist bluetooth
blacklist ahci
blacklist libahci
blacklist xhci_hcd
blacklist ehci_hcd
blacklist ehci_pci
blacklist usbcore
EOF
echo "✅ pve-blacklist.conf criado."

# 3. Certifique-se de que os módulos vfio estão carregando no boot
grep -qxF 'vfio' /etc/modules || echo 'vfio' >> /etc/modules
grep -qxF 'vfio_iommu_type1' /etc/modules || echo 'vfio_iommu_type1' >> /etc/modules
grep -qxF 'vfio_pci' /etc/modules || echo 'vfio_pci' >> /etc/modules
grep -qxF 'vfio_virqfd' /etc/modules || echo 'vfio_virqfd' >> /etc/modules
echo "✅ Módulos adicionados ao /etc/modules."

# 4. Adiciona parâmetros ao GRUB (se ainda não estiverem)
if ! grep -q 'intel_iommu=on' /etc/default/grub; then
  sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="/GRUB_CMDLINE_LINUX_DEFAULT="quiet intel_iommu=on iommu=pt /' /etc/default/grub
  echo "✅ Parâmetros adicionados ao GRUB."
else
  echo "ℹ️ Parâmetros IOMMU já estavam presentes no GRUB."
fi

# 5. Atualiza GRUB e initramfs
update-grub
update-initramfs -u -k all
echo "✅ GRUB e initramfs atualizados."

echo -e "\n✅ Script concluído com sucesso!"
echo -e "🔁 Agora, reinicie o sistema com: \e[1mreboot\e[0m"
echo -e "Depois, verifique com: \e[1mlspci -nnk | grep -A 2 vfio\e[0m"
