locals {
  out_dir = "${path.cwd}"
  exe_cmd_default = "chmod +x {{ .Path }}; {{ .Vars }} {{ .Path }}"
  exe_cmd_sudo = "echo 'vagrant' | {{.Vars}} sudo -S -E sh -eux '{{.Path}}'"
  exe_cmd = "${var.use_sudo == true ? local.exe_cmd_sudo : local.exe_cmd_default}"
  image_dir = "${ var.image_output_path != "" ? var.image_output_path : local.out_dir}"
}

source "null" "ssh" {
  ssh_host     = var.remote_host
  ssh_username = var.ssh_username
  ssh_password = var.ssh_password
}

#
# a build block invokes sources and runs provisioning steps on them. The
# documentation for build blocks can be found here:
# https://www.packer.io/docs/templates/hcl_templates/blocks/build
#
build {
  name = var.image_name
  sources = ["source.null.ssh"]

  provisioner "shell" {
    execute_command = "${local.exe_cmd}" 
    inline = [
      "echo \"Creating lxc container...\"",
      "apt install -y skopeo umoci jq",
      "if lxc-ls | grep -q '^frigate'; then lxc-destroy frigate; fi",
      "lxc-create frigate -t oci -- --url docker://ghcr.io/blakeblackshear/frigate:$FRIGATE_VERSION"
    ]
    env = {
      FRIGATE_VERSION = var.frigate_version
    }
  }
  
  provisioner "file" {
    source      = "config/init"
    destination = "/var/lib/lxc/frigate/rootfs/init"
  }

  provisioner "shell" {
    execute_command = "${local.exe_cmd}" 
    inline = [
      "echo \"Running provisioning...\"",
      "/usr/sbin/chroot /var/lib/lxc/frigate/rootfs/ apt update",
      "/usr/sbin/chroot /var/lib/lxc/frigate/rootfs/ apt upgrade -y",
      "/usr/sbin/chroot /var/lib/lxc/frigate/rootfs/ apt install init ifupdown net-tools apt-utils -y",
      "mkdir -p /var/lib/lxc/frigate/rootfs/config",
      "touch /var/lib/lxc/frigate/rootfs/config/config.yml",
      "echo \"${var.frigate_config}\" > /var/lib/lxc/frigate/rootfs/config/config.yml",
      "/usr/sbin/chroot /var/lib/lxc/frigate/rootfs/ chmod -R 777 /config",
      "echo \"${var.network_config}\" > /etc/network/interfaces",
      "rm -r /var/lib/lxc/frigate/rootfs/lib/systemd/system/systemd-networkd.service"
    ]
  }
  
  provisioner "shell" {  
    execute_command = "${local.exe_cmd}"   
    inline = [
      "echo \"Exporting tarball rootfs...\"",
      "cd /var/lib/lxc/frigate/rootfs/",
      "tar --exclude=dev --exclude=sys --exclude=proc -czf $IMAGE_DIRECTORY/$IMAGE_NAME.tar.gz ./"
    ]
    env = {
      IMAGE_NAME = var.image_name
      IMAGE_DIRECTORY  = local.image_dir
    }
  }
  
  provisioner "shell" { 
    execute_command = "${local.exe_cmd}"    
    inline = [
      "echo \"Destroying container...\"",
      "if lxc-ls | grep -q '^frigate'; then lxc-destroy frigate; fi"
    ]
  }
}