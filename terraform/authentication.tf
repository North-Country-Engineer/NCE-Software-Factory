resource "aws_cognito_user_pool" "main" {
    name = "your_user_pool_name"

    password_policy {
        minimum_length    = 8
        require_lowercase = true
        require_uppercase = true
        require_numbers   = true
        require_symbols   = false
    }

    auto_verified_attributes = ["email"]

    tags = {
        Name = var.user_pool_name
    }
}

resource "aws_cognito_user_pool_domain" "main" {
    domain      = var.site_domain
    user_pool_id = aws_cognito_user_pool.main.id
}

resource "aws_cognito_user_pool_client" "main" {
    name         = var.user_pool_client
    user_pool_id = aws_cognito_user_pool.main.id
    generate_secret = false

    explicit_auth_flows = [
        "ALLOW_USER_PASSWORD_AUTH",
        "ALLOW_REFRESH_TOKEN_AUTH",
        "ALLOW_USER_SRP_AUTH",
        "ALLOW_CUSTOM_AUTH",
    ]

    allowed_oauth_flows_user_pool_client = true

    allowed_oauth_flows = [
        "code",
        "implicit"
    ]

    allowed_oauth_scopes = [
        "phone",
        "email",
        "openid",
        "profile",
        "aws.cognito.signin.user.admin"
    ]

    callback_urls = [
        "https://${var.site_domain}/callback"
    ]

    logout_urls = [
        "https://${var.site_domain}/logout"
    ]
}

output "cognito_user_pool_id" {
    value = aws_cognito_user_pool.main.id
}

output "cognito_user_pool_client_id" {
    value = aws_cognito_user_pool_client.main.id
}

output "cognito_user_pool_domain" {
    value = aws_cognito_user_pool_domain.main.domain
}