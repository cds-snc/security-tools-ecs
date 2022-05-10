# Status: Archived
This repository has been archived and is no longer maintained. This was an experiment using security tools residing in multiple VPC's peered to a central VPC hosting a SSO proxy. The number of NAT gateways was becoming excessive and costly. The CDS security team will no longer be pursueing this architecture in favour of using one VPC as well as exploring EKS.

![status: inactive](https://img.shields.io/badge/status-inactive-red.svg)

This work will renamed to security-tools-ecs and be superseded by https://github.com/cds-snc/security-tools

## Security Tools

### Description

This repository will contain various tools used by CDS to ensure the confidentiality, integrity and availability of CDS applications and services.

### Services

- SSO Proxy : AWS, ECS, Google SSO, [Pomerium](https://github.com/pomerium/pomerium)
- Cloud Asset Inventory: AWS, ECS, Lambda [Cartography](https://github.com/lyft/cartography), Neo4j, Elasticsearch

### License

This code is released under the MIT License. See [LICENSE](LICENSE).
