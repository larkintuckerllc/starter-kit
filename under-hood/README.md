# Under the Hood

## Amazon Virtual Private Cloud (VPC)

The VPC infrastructure includes:

* VPC: 172.16.0.0/16
* Subnet (SN) Private: 172.16.128.0/18
* Subnet (SN) Private: 172.16.192.0/18
* Subnet (SN) Public: 172.16.0.0/24
* Subnet (SN) Public: 172.16.1.0/24
* Internet Gateway (IG)
* NAT Gateway (NG) x 2

![vpc](vpc.png)

The VPC infrastructure also includes:

Route Table Public:

| Destination  | Target |
| ------------ | ------ |
| 172.1.0.0/16 | local  |
| 0.0.0.0/0    | IG     |

Route Table Private x 2:

| Destination  | Target |
| ------------ | ------ |
| 172.1.0.0/16 | local  |
| 0.0.0.0/0    | NG     |

Network Access Control List:

Inbound:

| Rule | Type        | Source      | Allow/Deny |
| 100  | ALL Traffic | 0.0.0.0/0   | ALLOW      |
| *    | ALL Traffic | 0.0.0.0/0   | DENY       |

Outbound:

| Rule | Type        | Destination | Allow/Deny |
| 100  | ALL Traffic | 0.0.0.0/0   | ALLOW      |
| *    | ALL Traffic | 0.0.0.0/0   | DENY       |
