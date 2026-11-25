from aws_cdk import (
    CfnOutput,
    Duration,
    RemovalPolicy,
    # Duration,
    Stack,
    # aws_sqs as sqs,
)
from aws_cdk import (
    aws_ec2 as ec2,
)
from aws_cdk import (
    aws_ecs as ecs,
)
from aws_cdk import (
    aws_elasticloadbalancingv2 as elbv2,
)
from aws_cdk import (
    aws_rds as rds,
)
from constructs import Construct


class AWSGroceryStack(Stack):
    def __init__(self, scope: Construct, construct_id: str, **kwargs) -> None:
        super().__init__(scope, construct_id, **kwargs)

        #######################################################################
        # Learning:
        # a) nat_gateways=1 for loading Docker images but requires EIP. Instead
        # removed subnet from vpc
        # b) ...

        #######################################################################
        # 1. Create one VPC with two subnets: isolated_db, loadbalancing
        #######################################################################

        vpc = ec2.Vpc(
            self,
            "AWSGrocery_VPC",
            max_azs=2,
            nat_gateways=0,  # a)
            subnet_configuration=[
                ec2.SubnetConfiguration(
                    name="IsolatedDB",
                    subnet_type=ec2.SubnetType.PRIVATE_ISOLATED,
                    cidr_mask=24,
                ),
                ec2.SubnetConfiguration(
                    name="Loadbalancing",
                    subnet_type=ec2.SubnetType.PUBLIC,
                    cidr_mask=24,
                ),
            ],
        )

        #######################################################################
        # 2. In isolated_db subnet create RDS Datenbank
        #######################################################################

        db_instance = rds.DatabaseInstance(
            self,
            "AWSGrocery_DB",
            engine=rds.DatabaseInstanceEngine.postgres(
                version=rds.PostgresEngineVersion.VER_16
            ),
            instance_type=ec2.InstanceType.of(
                ec2.InstanceClass.T3, ec2.InstanceSize.MICRO
            ),
            vpc=vpc,
            vpc_subnets=ec2.SubnetSelection(
                subnet_type=ec2.SubnetType.PRIVATE_ISOLATED
            ),
            credentials=rds.Credentials.from_generated_secret(
                "dbadmin"
            ),  # Speichert Passwort automatisch im AWS Secrets Manager
            database_name="appdb",
            multi_az=False,
            removal_policy=RemovalPolicy.DESTROY,  # Testing: is destroyed when 'cdk destroy'
            storage_encrypted=True,
        )

        #######################################################################
        # 3. In public subnet create EC Cluster
        #######################################################################

        cluster = ecs.Cluster(self, "EcsCluster", vpc=vpc)
        cluster.add_capacity(
            "AWSGrocery_AutoScalingGroupCapacity",
            instance_type=ec2.InstanceType("t3.micro"),
            min_capacity=1,
            max_capacity=3,
            vpc_subnets=ec2.SubnetSelection(subnet_type=ec2.SubnetType.PUBLIC),
            associate_public_ip_address=True,
        )

        #######################################################################
        # 4. In EC Cluster create grocery_app container with tasks and service
        #######################################################################

        task_definition = ecs.Ec2TaskDefinition(self, "AWSGrocery_TaskDefinition")

        #######################################################################
        # 5. The grocery_app container
        #######################################################################

        container = task_definition.add_container(
            "AWSGrocery_Web",
            image=ecs.ContainerImage.from_asset(
                directory="..", file="./backend/Dockerfile"
            ),
            memory_limit_mib=512,
            environment_files=[ecs.EnvironmentFile.from_asset("../backend/.env")],
            # Update POSTGRES_URI once RDS is installed
            secrets={"DB_SECRET": ecs.Secret.from_secrets_manager(db_instance.secret)},
        )
        container.add_port_mappings(
            ecs.PortMapping(container_port=5000, protocol=ecs.Protocol.TCP)
        )

        #######################################################################
        # 6. The service overlooking start, re-start and monitoring
        #######################################################################

        ecs_service = ecs.Ec2Service(
            self,
            "AWSGrocery_AppEcsService",
            cluster=cluster,
            task_definition=task_definition,
            circuit_breaker=ecs.DeploymentCircuitBreaker(rollback=True),
            desired_count=1,
            min_healthy_percent=0,
        )

        #######################################################################
        # 7. Connect ECS to RDS
        #######################################################################

        db_instance.connections.allow_default_port_from(ecs_service)

        #######################################################################
        # 8. Create loadbalancer
        #######################################################################

        alb = elbv2.ApplicationLoadBalancer(
            self,
            "AWSGrocery_ALB",
            vpc=vpc,
            internet_facing=True,
            vpc_subnets=ec2.SubnetSelection(subnet_type=ec2.SubnetType.PUBLIC),
        )

        listener = alb.add_listener("HttpListener", port=80, open=True)

        #######################################################################
        # 9. Register ECS service at loadbalancer
        #######################################################################

        listener.add_targets(
            "AWSGrocery_EcsTargets",
            port=5000,
            protocol=elbv2.ApplicationProtocol.HTTP,
            targets=[ecs_service],
            health_check=elbv2.HealthCheck(path="/", interval=Duration.seconds(30)),
        )

        #######################################################################
        # 9. Create some output
        #######################################################################

        CfnOutput(
            self,
            "LoadBalancerDNS",
            value=alb.load_balancer_dns_name,
            description="Öffentliche URL des Load Balancers",
        )
