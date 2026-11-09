# Yömye altyapısı

Türkçe · [English](./README.en.md)

Bu repoda Yömye’nin cloud altyapısı tanımlanır. Terraform ile iki ayrı environment yönetilir.

- [AWS staging](./aws-infrastructure/) environment’ında değişiklikler yayına alınmadan önce gerçek cloud servisleriyle test edilir.
- [GCP production](./gcp-infrastructure/) environment’ında canlı backend barındırılır.

İki environment’ta da aynı uygulama contract’ları kullanılır. Her environment’ın veritabanı, queue’ları, secret’ları, deployment dosyaları, erişim rolleri ve Terraform state’i ayrı tutulur.

## Mimari

![Yömye uygulama mimarisi](https://vsay.site/projects/yomye-me/44444b9a-a331-4203-8e9f-b610a8c895e5-yomye-architecture.png)

[Yömye nasıl çalışıyor?](https://vsay.site/projects/yomye-me/)

## Repo yapısı

```text
.
├── aws-infrastructure/     AWS staging için Terraform dosyaları ve yönetim scriptleri
│   ├── bootstrap/          Remote state bucket kurulumu
│   ├── environment/prod/   Staging environment root dizini
│   ├── modules/            Network, data, compute, Lambda ve deployment modülleri
│   └── scripts/            Staging kurulumu ve yönetimi
└── gcp-infrastructure/     GCP production için Terraform dosyaları ve yönetim scriptleri
    ├── bootstrap/          Remote state bucket kurulumu
    └── scripts/            Production kurulumu ve veritabanı erişimi
```

AWS staging için `aws-infrastructure/environment/prod` dizini kullanılır. Uygulama environment’ı ve GitHub environment değeri `staging` olarak tanımlanır.

## Environment karşılaştırması

| Bileşen | AWS staging | GCP production |
| --- | --- | --- |
| Ingress | Application Load Balancer | Global HTTPS Load Balancer |
| Core ve Chat | Private ağda bir EC2 VM | Kalıcı bir Compute Engine VM |
| Worker | Ollama çalıştıran ayrı bir private EC2 VM | Ollama çalıştıran ayrı ve kalıcı bir Compute Engine VM |
| PostgreSQL | Amazon RDS | Cloud SQL |
| Messaging | SQS | Pub/Sub |
| Notification | AWS Lambda | Cloud Run |
| Configuration | Systems Manager Parameter Store | Parameter Manager |
| Secret yönetimi | AWS Secrets Manager ve secure parameter’lar | Secret Manager ve manual parameter sürümleri |
| Deployment storage | Private S3 bucket’ları | Private GCS bucket’ları ve Artifact Registry |
| GitHub deployment identity | AWS OIDC deployment role | Workload Identity Federation |

## AWS staging

AWS environment’ı `aws-infrastructure/environment/prod` dizininden yönetilir. Terraform modülleriyle aşağıdaki kaynaklar oluşturulur.

- VPC, load balancer için public subnet’ler, uygulama için private subnet ve NAT instance
- Core/Chat için bir EC2 VM ve Worker için ayrı bir EC2 VM
- Private RDS PostgreSQL
- Category, Chat ve Notification için SQS queue’ları
- Notification Lambda
- Deployment dosyaları için S3 bucket’ları
- Parameter Store, Secrets Manager erişimi ve servislerin IAM rolleri
- GitHub Actions için OIDC deployment role
- Grafana Cloud’a veri gönderen OpenTelemetry Collector yapılandırması

Environment yönetiminde aşağıdaki scriptler kullanılır. Yollar `aws-infrastructure` dizinine göre verilmiştir.

| Script | İşlev |
| --- | --- |
| `scripts/populate-ssm-credentials.sh` | Manual olarak girilen staging değerleri alınır ve kaydedilir |
| `scripts/staging-compute.sh` | Staging sunucuları ve veritabanı başlatılır, durdurulur veya durumları görüntülenir |
| `scripts/connect_rds.sh` | AWS Systems Manager üzerinden private RDS’e yerel erişim sağlanır |
| `scripts/rotate-rds-credentials.sh` | RDS credentials rotate edilir |
| `scripts/empty-environment-buckets.sh` | Destroy öncesinde deployment bucket’ları temizlenir |

## GCP production

Production environment’ı `gcp-infrastructure` dizininden yönetilir. Kurulum adımları, mimari bileşenler, bootstrap süreci, GitHub değişkenleri ve scaling notları [GCP production rehberinde](./gcp-infrastructure/README.md) yer alır.

Terraform yapılandırmasıyla aşağıdaki kaynaklar oluşturulur.

- Private VPC, subnet, Cloud Router ve Cloud NAT
- Global HTTPS load balancer ve managed certificate
- Silinmeye karşı korunan Core/Chat ve Worker VM’leri
- Private Cloud SQL PostgreSQL
- Pub/Sub topic ve subscription’ları
- Notification için Cloud Run servisi
- Private GCS deployment bucket’ları ve Artifact Registry
- Parameter Manager ve Secret Manager kaynakları
- Service account’lar ve GitHub Workload Identity Federation

Core/Chat ve Worker VM’leri kalıcı sunucular olarak kullanılır. Deletion protection ve Terraform `prevent_destroy` ile bu sunucuların altyapı değişiklikleri sırasında yanlışlıkla silinip yeniden oluşturulması engellenir.

Production tarafındaki script yolları `gcp-infrastructure` dizinine göre verilmiştir.

| Script | İşlev |
| --- | --- |
| `scripts/populate-parameters.sh` | Local input ile Parameter Manager’da manual parameter sürümleri oluşturulur |
| `scripts/connect-postgres.sh` | Yerel makineden Cloud SQL’e `5432` portu üzerinden erişim için IAP tunnel’ı açılır |
| `scripts/get-database-credentials.sh` | Güncel Cloud SQL bağlantı bilgileri Parameter Manager ve Secret Manager’dan okunur |

## Terraform state

AWS staging ve GCP production için ayrı remote state backend’leri kullanılır. Ana Terraform yapılandırmasının ihtiyaç duyduğu state depolaması, her environment’ın `bootstrap` dizinindeki yapılandırmayla kurulur. Ana dizinde `terraform init` çalıştırılmadan önce backend hazırlanır.

## Terraform komutları

Formatlama, validation ve plan oluşturma adımları için aşağıdaki komutlar kullanılır.

```bash
terraform fmt -recursive
terraform validate
terraform plan -out=environment.tfplan
```

AWS dizini staging, GCP dizini production için kullanılır. Deployment workflow’larıyla binary dosyaları veya container revision’ları yayınlanır. Cloud kaynakları Terraform ile yönetilir.
