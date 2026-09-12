/**
 * CloudFront in front of the website.
 *
 * Two things make this worth its own file rather than a few lines.
 *
 * THE CERTIFICATE MUST LIVE IN us-east-1. CloudFront reads its certificate from
 * there and nowhere else, whatever region everything else is in. That is why
 * there is a second provider below — not a mistake, and not a hint that the
 * platform is in Virginia.
 *
 * AND HTML IS NOT A STATIC ASSET HERE. The container renders per-URL head tags
 * — title, description, canonical, JSON-LD — so two URLs that serve the same
 * bundle serve different HTML. Caching HTML on the path alone is correct and
 * desirable; caching it for a week is not, because an admin editing page SEO
 * expects to see it. Short TTL for documents, a year for the hashed assets
 * Vite emits, which is the split those filenames exist for.
 */

provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"

  default_tags {
    tags = {
      Project   = "aajoo-homes"
      ManagedBy = "terraform"
      Repo      = "ajoo-admin-website/infra/terraform"
    }
  }
}

resource "aws_acm_certificate" "cdn" {
  provider          = aws.us_east_1
  domain_name       = var.web_hostname
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }

  tags = { Name = "${local.name}-cdn" }
}

output "cdn_acm_validation_records" {
  description = "The CloudFront certificate's own validation record. Separate from the ALB's."
  value = [
    for o in aws_acm_certificate.cdn.domain_validation_options : {
      name  = o.resource_record_name
      type  = o.resource_record_type
      value = o.resource_record_value
    }
  ]
}

# ── Cache behaviour ────────────────────────────────────────────────────────
/**
 * Documents: cached briefly, and keyed on everything that changes the answer.
 *
 * Five minutes is long enough to absorb a crawl or a burst of traffic on one
 * listing, short enough that a CMS edit appears without anybody running an
 * invalidation. The query string is part of the key because the SPA's own
 * routes carry one (`/property?id=`), and those are different pages.
 */
resource "aws_cloudfront_cache_policy" "html" {
  name        = "${local.name}-html"
  default_ttl = 300
  min_ttl     = 0
  max_ttl     = 3600

  parameters_in_cache_key_and_forwarded_to_origin {
    enable_accept_encoding_brotli = true
    enable_accept_encoding_gzip   = true

    cookies_config { cookie_behavior = "none" }
    headers_config { header_behavior = "none" }
    query_strings_config { query_string_behavior = "all" }
  }
}

/**
 * Assets: a year, because the filename changes when the content does.
 *
 * Vite emits `index-l4HBGzes.js` and friends. A new build is a new name, so
 * there is nothing to invalidate and no reason to re-ask.
 */
resource "aws_cloudfront_cache_policy" "assets" {
  name        = "${local.name}-assets"
  default_ttl = 31536000
  min_ttl     = 31536000
  max_ttl     = 31536000

  parameters_in_cache_key_and_forwarded_to_origin {
    enable_accept_encoding_brotli = true
    enable_accept_encoding_gzip   = true

    cookies_config { cookie_behavior = "none" }
    headers_config { header_behavior = "none" }
    query_strings_config { query_string_behavior = "none" }
  }
}

/**
 * What reaches the origin.
 *
 * The renderer needs the Host to build canonical URLs, and the user agent
 * because crawler responses are the thing the SEO acceptance tests check. It
 * does NOT need cookies, and forwarding them would make every response
 * uncacheable.
 */
resource "aws_cloudfront_origin_request_policy" "web" {
  name = "${local.name}-web"

  cookies_config { cookie_behavior = "none" }
  query_strings_config { query_string_behavior = "all" }

  headers_config {
    header_behavior = "whitelist"
    headers {
      items = ["Host", "User-Agent", "Accept-Language", "CloudFront-Viewer-Country"]
    }
  }
}

resource "aws_cloudfront_distribution" "web" {
  enabled         = true
  is_ipv6_enabled = true
  comment         = "${local.name} website"
  aliases         = [var.web_hostname]
  price_class     = "PriceClass_200" # includes India; excludes South America and Australia

  origin {
    domain_name = var.origin_hostname
    origin_id   = "alb"

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "https-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }

    /**
     * The shared secret that makes the ALB rule work. Without this header the
     * load balancer answers 404, so the site cannot be reached except through
     * CloudFront — see the rule in web.tf.
     */
    custom_header {
      name  = "X-Origin-Verify"
      value = random_password.cloudfront_origin_secret.result
    }
  }

  default_cache_behavior {
    target_origin_id       = "alb"
    viewer_protocol_policy = "redirect-to-https"
    compress               = true

    # HEAD and GET only. Nothing on this hostname writes: the app talks to the
    # API on its own hostname.
    allowed_methods = ["GET", "HEAD", "OPTIONS"]
    cached_methods  = ["GET", "HEAD"]

    cache_policy_id          = aws_cloudfront_cache_policy.html.id
    origin_request_policy_id = aws_cloudfront_origin_request_policy.web.id
  }

  ordered_cache_behavior {
    path_pattern           = "/assets/*"
    target_origin_id       = "alb"
    viewer_protocol_policy = "redirect-to-https"
    compress               = true
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]

    cache_policy_id = aws_cloudfront_cache_policy.assets.id
  }

  /**
   * No custom_error_response mapping 404 to index.html.
   *
   * That is the standard SPA trick and it would be wrong here. The renderer
   * answers every route itself and returns real status codes — a listing that
   * does not exist must answer 404, not 200 with the shell, or every dead URL
   * becomes an indexable page. The platform has already had the reverse of
   * this bug: pages that rendered fine and answered 404.
   */

  restrictions {
    geo_restriction { restriction_type = "none" }
  }

  viewer_certificate {
    acm_certificate_arn      = aws_acm_certificate.cdn.arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }

  tags = { Name = "${local.name}-web" }
}

output "cloudfront_domain_name" {
  description = "Point www.aajoohomes.com here once the certificate has issued."
  value       = aws_cloudfront_distribution.web.domain_name
}

output "cloudfront_distribution_id" {
  description = "For `aws cloudfront create-invalidation` after a CMS change that must appear now."
  value       = aws_cloudfront_distribution.web.id
}
