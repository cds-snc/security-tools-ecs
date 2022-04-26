output "cartography_repository_url" {
  description = "The ECR URL for the cartography repository"
  value       = aws_ecr_repository.cartography.repository_url
}

output "neo4j_ingestor_repository_url" {
  description = "The ECR URL for the neo4j ingestor repository"
  value       = aws_ecr_repository.neo4j_ingestor.repository_url
}
