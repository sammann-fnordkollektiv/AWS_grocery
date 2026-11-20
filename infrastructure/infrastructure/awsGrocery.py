from aws_cdk import (
    CfnOutput,
    Stack,
)
from aws_cdk import (
    aws_ec2 as ec2,
)
from constructs import Construct


class ContainerEc2Stack(Stack):
    def __init__(self, scope: Construct, construct_id: str, **kwargs) -> None:
        super().__init__(scope, construct_id, **kwargs)

        # Virtual Private Cloud

        vpc = ec2.Vpc(
            self,
            "Vpc",
            max_azs=1,
            nat_gateways=0,
            subnet_configuration=[
                ec2.SubnetConfiguration(
                    name="public",
                    subnet_type=ec2.SubnetType.PUBLIC,
                    map_public_ip_on_launch=True,
                )
            ],
        )

        # Security Groups

        security_group = ec2.SecurityGroup(
            self,
            "InstanceSecurityGroup",
            vpc=vpc,
            description="ssh access from all the interwobs",
            allow_all_outbound=True,
        )

        security_group.add_ingress_rule(
            ec2.Peer.any_ipv4(),
            ec2.Port.tcp(22),
            "ssh access from all the interwobs",
        )

        # TODO vars.tf?
        key_pair_name = "Deine erste EC2-Instanz starten"
        key_pair = ec2.KeyPair.from_key_pair_name(
            self,
            "ExistingKeyPair",
            key_pair_name,
        )

        instance = ec2.Instance(
            self,
            "ContainerHost",
            vpc=vpc,
            vpc_subnets=ec2.SubnetSelection(subnet_type=ec2.SubnetType.PUBLIC),
            instance_type=ec2.InstanceType("t3.micro"),
            machine_image=ec2.MachineImage.latest_amazon_linux2023(),
            security_group=security_group,
            key_pair=key_pair,
        )

        instance.add_user_data(
            "set -eux",
            "apt-get update",
            "apt-get install -y docker.io",
            "systemctl enable --now docker",
            'printf "PasswordAuthentication no\\nPubkeyAuthentication yes\\nPermitRootLogin no\\n" '
            "> /etc/ssh/sshd_config.d/99-key-only.conf",
            "sshd -t && systemctl reload ssh",
            ## TODO: _do_after_launch.sh
        )

        CfnOutput(
            self,
            "PublicIp",
            value=instance.instance_public_ip,
        )

        CfnOutput(
            self,
            "SshCommand",
            value=f"ssh ec2-user@{instance.instance_public_ip}",
        )
