resource "aws_instance" "server_consul" {
  count = "${var.consul_server_nodes}"

  ami           = "${module.shared.base_image}"
  instance_type = "${var.instance_type}"
  key_name      = "${aws_key_pair.main.key_name}"
  subnet_id     = "${element(var.subnet_private_ids,count.index)}"

  vpc_security_group_ids = [
    "${aws_security_group.egress.id}",
    "${aws_security_group.admin_access.id}",
    "${aws_security_group.vault_all.id}",
  ]

  iam_instance_profile = "${aws_iam_instance_profile.describe_instances.name}"

  tags {
    Name                     = "${var.environment_name}-server-consul-${count.index}"
    consul_server_datacenter = "${data.aws_region.main.name}"
  }

  connection {
    bastion_host        = "${element(var.bastion_ips,0)}"
    bastion_user        = "${var.bastion_user}"
    bastion_private_key = "${file("~/.ssh/id_rsa")}"

    host        = "${self.private_ip}"
    user        = "${module.shared.base_user}"
    private_key = "${file(module.shared.private_key_path)}"
  }

  #
  # Consul
  #
  provisioner "remote-exec" {
    inline = ["${module.shared.install_consul_server}"]
  }
}
