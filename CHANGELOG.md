## [Unreleased]

## [0.2.3] - 2026-07-26

### Changed
- Updated YARD to 0.9.44, Rake to 13.4.2, IRB to 1.18.0, Minitest to 6.0.6, and RuboCop to 1.88.2.
- Updated the development dependencies after merging the complete dependency queue.

## [0.2.2] - 2026-07-12

### Changed
- Updated RubyGems and GitHub Actions dependencies.

## [0.2.1] - 2026-07-12

### Changed
- Updated Faraday, Yard, RuboCop, Addressable, Svix, and Minitest dependencies.

## [0.2.0] - 2026-03-30

### Added
- Async payload support for parse/extract/split/edit/pipeline using current Reducto async options
- `Resources::Jobs` lifecycle helpers: status normalization, predicates, and `wait`
- Svix-backed webhook verification helpers and a thin Rails request verifier
- New job/webhook error classes and configuration for webhook secrets
- `RateLimitError` exception class for HTTP 429 responses
- Path traversal protection in job_id validation
- `AsyncPayload` module for shared async options handling
- Comprehensive test coverage for async operations, webhook verification, and job lifecycle

### Changed
- README examples now reflect current async lifecycle and webhook portal behavior
- Test suite expanded to cover async payload translation, job polling, webhook verification, and edge cases
- `RequestVerifier` now extracts only webhook headers (svix-*) instead of full Rack environment
- Consolidated `normalize_input` method into shared `AsyncPayload` module
- Simplified `Jobs` class to use `include ReductoAI::JobStatus` instead of delegation
- Lazy-load Svix gem only when webhook verification is used
- Case-insensitive status normalization via downcase lookup
- Replaced deprecated `Faraday::UploadIO` with `Faraday::Multipart::FilePart`
- HTTP 403 now handled as standard client error

### Fixed
- Security: Path traversal vulnerability in cancel/retrieve job_id interpolation
- Security: Rack environment variable leak in webhook header extraction
- Error handling: Added user-friendly message for invalid Svix secret format
- Error handling: HTTP 429 (rate limit) now raises dedicated exception
- Error handling: HTTP 403 (forbidden) now properly caught as client error
- Code quality: Removed dead `raise_exceptions` configuration attribute

## [0.1.3] - 2026-01-04

### Added
- CI testing for Ruby 4.0 (experimental)

### Changed
- Bump faraday-multipart from 1.1.0 to 1.2.0
- Bump irb from 1.15.2 to 1.16.0
- Bump minitest from 5.26.2 to 6.0.1
- Bump rubocop from 1.81.1 to 1.82.1
- Bump yard from 0.9.37 to 0.9.38

## [0.1.1] - 2025-11-12

### Added
- Comprehensive YARD documentation to public API
- GitHub Actions workflow for automated gem publishing on version tags

## [0.1.0] - 2025-10-17

### Added
- Initial release
