import wgconfig
import os
import wgconfig.wgexec as wgexec
import boto3
import ipaddress
import json
from botocore.config import Config

boto3_conf = Config(read_timeout=10, retries={"total_max_attempts": 2})
aws_iam = boto3.client('iam', config=boto3_conf)
aws_ssm = boto3.client('ssm', config=boto3_conf)
aws_ec2 = boto3.client('ec2', config=boto3_conf)
aws_lambda = boto3.client('lambda', config=boto3_conf)

iam_group = os.getenv('IAM_WG_GROUP_NAME')
user_ssm_prefix = os.getenv('WG_SSM_USERS_PREFIX')
wg_subnet = os.getenv('WG_SUBNET')
wg_config_ssm_path = os.getenv('WG_SSM_CONFIG_PATH')
wg_listen_port = os.getenv('WG_LISTEN_PORT')
wg_instance_id = os.getenv('WG_INSTANCE_ID')
wg_public_ip = os.getenv('WG_PUBLIC_IP')
vpc_cidr = os.getenv('VPC_CIDR')
wg_is_send_client_conf = os.getenv('WG_IS_SEND_CLIENT_CONF')
wg_admin_email = os.getenv('WG_ADMIN_EMAIL')
wg_send_lambda_name = os.getenv('WG_SEND_LAMBDA_NAME')


def get_iam_group_membership():
    try:
        iam_group_members = aws_iam.get_group(GroupName=iam_group)['Users']
    except Exception as e:
        return None
    iam_group_usernames = []
    for user in iam_group_members:
        iam_group_usernames.append(user['UserName'])
    return iam_group_usernames


def get_ssm_attrs(ssm_path):
    try:
        wg_ssm_config = aws_ssm.get_parameter(Name=ssm_path, WithDecryption=True)
    except Exception as e:
        return None
    if 'Parameter' in wg_ssm_config:
        return wg_ssm_config['Parameter']['Value'].split('\n')
    else:
        return None


def get_existing_users():
    ssm_user_list = aws_ssm.get_parameters_by_path(Path=user_ssm_prefix, Recursive=False,
                                                   WithDecryption=True)
    ssm_user_names = []
    if 'Parameters' in ssm_user_list:
        for user in ssm_user_list['Parameters']:
            ssm_user_names.append(user['Name'].split('/')[-1])
        return ssm_user_names
    else:
        return None


def add_users(iam_users, ssm_users, users2add, wg_conf):
    remaining_users = set(ssm_users).intersection(iam_users)
    available_ips = free_ip(remaining_users)
    print("Number of available IPs:{}".format(len(available_ips)))
    if len(available_ips) > 0:
        for user in users2add:
            private_key = wgexec.generate_privatekey()
            address = available_ips.pop()
            server_public_key = wgexec.get_publickey(wg_conf.interface['PrivateKey'])
            user_conf = {"address": address.__str__(), "private_key": private_key,
                         "public_key": wgexec.get_publickey(private_key)}
            wg_conf_user = wgconfig.WGConfig(user)
            wg_conf_user.add_attr(None, 'PrivateKey', private_key)
            wg_conf_user.add_attr(None, 'Address', address.__str__() + "/32")
            wg_conf_user.add_attr(None, 'DNS', (ipaddress.IPv4Network(wg_subnet).network_address + 1).__str__())
            wg_conf_user.add_peer(server_public_key)
            wg_conf_user.add_attr(server_public_key, 'AllowedIPs', "0.0.0.0/0")
            wg_conf_user.add_attr(server_public_key, 'Endpoint', str(wg_public_ip) + ":" + wg_listen_port)
            user_conf["ClientConf"] = "{}".format("\n".join(wg_conf_user.lines))
            new_ssm_param = aws_ssm.put_parameter(
                Name=user_ssm_prefix + "/" + user,
                Description='Wireguard peer conf for user:{}'.format(user),
                Value=json.dumps(user_conf),
                Type='SecureString',
                Overwrite=True,
                Tier='Standard',
                DataType='text'
            )
            if wg_is_send_client_conf:
                payload = {"user": user, "client_config": user_conf["ClientConf"]}
                try:
                    aws_lambda.invoke(
                        FunctionName=wg_send_lambda_name,
                        InvocationType='Event',
                        LogType='None',
                        Payload=json.dumps(payload),
                    )
                except Exception as e:
                    print("Can't invoke {} lambda function".format(wg_send_lambda_name))
    else:
        return False
    return True


def remove_users(users):
    for user in users:
        print("Removing ssm param for user:{}".format(user))
        aws_ssm.delete_parameter(Name=user_ssm_prefix + "/" + user)
    return True


def free_ip(remaining_users):
    ip_all = set(ipaddress.IPv4Network(wg_subnet).hosts()) - {ipaddress.IPv4Network(wg_subnet).network_address + 1}
    for user in remaining_users:
        user_attributes = aws_ssm.get_parameter(Name=user_ssm_prefix + "/" + user, WithDecryption=True)
        ip_all = ip_all - {ipaddress.IPv4Address(json.loads(user_attributes['Parameter']['Value'])['address'])}
    return ip_all


def read_wg_config():
    wg_ssm_config = get_ssm_attrs(wg_config_ssm_path)
    if wg_ssm_config is not None:
        wc = wgconfig.WGConfig('wg0')
        wc.lines = wg_ssm_config
        wc.parse_lines()
        return wc
    else:
        # wg config not found, let create it
        return None


def create_new_wg_conf():
    server_ip = (ipaddress.IPv4Network(wg_subnet).network_address + 1).__str__()
    server_private_key = wgexec.generate_privatekey()
    wg_conf = wgconfig.WGConfig('wg0')
    wg_conf.add_attr(None, 'PrivateKey', server_private_key)
    wg_conf.add_attr(None, 'Address', server_ip + "/" + str(ipaddress.IPv4Network(wg_subnet).prefixlen))
    wg_conf.add_attr(None, 'ListenPort', wg_listen_port)
    # Construct internal dns server address
    vpc_dns_address = (ipaddress.IPv4Network('10.11.0.0/16').network_address + 2).__str__()
    # Following section needed to use internal AWS DNS,
    # this enable access to AWS resources by the names which doesn't have external resolution/IP
    wg_conf.add_attr(None, 'PostUp', 'iptables -A FORWARD -i %i -j ACCEPT; iptables -A FORWARD -o %i -j ACCEPT; '
                                     'iptables -t nat -A POSTROUTING -o ens5 -j MASQUERADE; '
                                     'iptables -A PREROUTING -t nat -i %i -p udp --dport 53  -j DNAT --to-destination {0}; '
                                     'iptables -A PREROUTING -t nat -i %i -p tcp --dport 53  -j DNAT --to-destination {0}'.format(
        vpc_dns_address))
    wg_conf.add_attr(None, 'PostDown', 'iptables -D FORWARD -i %.i -j ACCEPT; iptables -D FORWARD -o %i -j ACCEPT; '
                                       'iptables -t nat -D POSTROUTING -o ens5 -j MASQUERADE; '
                                       'iptables -D PREROUTING -t nat -i %i -p udp --dport 53  -j DNAT --to-destination {0}; '
                                       'iptables -D PREROUTING -t nat -i %i -p tcp --dport 53  -j DNAT --to-destination {0}'.format(
        vpc_dns_address))
    return wg_conf


def get_wg_config():
    wg_conf_old = read_wg_config()
    if wg_conf_old is None:
        wg_conf = create_new_wg_conf()
    else:
        wg_conf = wg_conf_old
        for peer in wg_conf.peers:
            wg_conf.del_peer(peer)
    return wg_conf


def add_users_to_wg_config(wg_conf, users):
    # Create peers section
    for user in users:
        peer_conf = json.loads(get_ssm_attrs(user_ssm_prefix + "/" + user)[0])
        wg_conf.add_peer(wgexec.get_publickey(peer_conf['private_key']), "#{}".format(user))
        wg_conf.add_attr(wgexec.get_publickey(peer_conf['private_key']), 'AllowedIPs', peer_conf['address'] + "/32")
    return wg_conf


def restart_instance():
    instance_id = get_ssm_attrs(wg_instance_id)
    if instance_id is not None:
        try:
            ec2_result = aws_ec2.reboot_instances(
                InstanceIds=instance_id,
                DryRun=False
            )
        except Exception as e:
            print(e)
            return False
        return True
    return False


def handler(event, context):
    iam = get_iam_group_membership()
    print("Iam group {} users:{}".format(iam_group, iam))
    ssm = get_existing_users()
    print("User exist in SSM:{}".format(ssm))
    if iam is not None and ssm is not None:
        users2add = list(set(iam) - set(ssm))
        users2remove = list(set(ssm) - set(iam))
        print("Users to add:{}".format(users2add))
        print("Users to remove:{}".format(users2remove))
        wg_conf = get_wg_config()
        if len(users2remove) > 0:
            remove_users(users2remove)
        if len(users2add) > 0:
            add_users(iam, ssm, users2add, wg_conf)
        wg_conf_new = add_users_to_wg_config(wg_conf, iam)
        aws_ssm.put_parameter(
            Name=wg_config_ssm_path,
            Description='Wireguard server conf',
            Value="{}".format("\n".join(wg_conf_new.lines)),
            Type='SecureString',
            Overwrite=True,
            Tier='Standard',
            DataType='text'
        )
    print("WG EC2 Instance restart:{}".format(restart_instance()))
