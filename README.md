# ReductoAi

Ruby wrapper on [ReductoAI API](https://docs.reducto.ai/api-reference)

## Installation

```
bundle add reducto_ai
```

## Usage

Configure once:

```ruby
ReductoAI.configure do |config|
  config.api_key = ENV.fetch("REDUCTO_API_KEY")
end
```

### Choosing an action

- **Parse**: Start here for any document. Converts uploads or URLs into structured chunks and OCR text so later steps can reuse the returned `job_id`.
- **Split**: Use after parsing when you need logical sections. Provide `split_description` names/rules to segment the parsed document into labeled ranges.
- **Extract**: Run when you need structured answers (fields, JSON). Supply instructions or schema to pull values from raw input or an existing parse `job_id`.
- **Edit**: Generate marked-up PDFs using `document_url` plus `edit_instructions` (PDF forms supported via `form_schema`).
- **Pipeline**: Trigger a saved Studio pipeline with `input` + `pipeline_id` to orchestrate Parse/Split/Extract/Edit in one call.

### Async Operations

All resources support async variants that return a `job_id` for polling:

```ruby
client = ReductoAI::Client.new

# Start async parse
# API Reference: https://docs.reducto.ai/api-reference/parse-async
job = client.parse.async(input: "https://example.com/large-doc.pdf")
job_id = job["job_id"]

# Response:
# {
#   "job_id" => "async-123",
#   "status" => "processing"
# }

# Poll for completion
# API Reference: https://docs.reducto.ai/api-reference/get-job
result = client.jobs.retrieve(job_id: job_id)

# Response:
# {
#   "job_id" => "async-123",
#   "status" => "complete",
#   "result" => {...},
#   "usage" => {"credits" => 1.0}
# }

# Or configure webhooks for notifications
# API Reference: https://docs.reducto.ai/api-reference/webhook-portal
client.jobs.configure_webhook
```

Available async methods:
- `client.parse.async(input:, **options)` - [Parse Async API](https://docs.reducto.ai/api-reference/parse-async)
- `client.extract.async(input:, instructions:, **options)` - [Extract Async API](https://docs.reducto.ai/api-reference/extract-async)
- `client.split.async(input:, **options)` - [Split Async API](https://docs.reducto.ai/api-reference/split-async)
- `client.edit.async(input:, instructions:, **options)` - [Edit Async API](https://docs.reducto.ai/api-reference/edit-async)
- `client.pipeline.async(input:, steps:, **options)` - [Pipeline Async API](https://docs.reducto.ai/api-reference/pipeline-async)

### Rails

Create `config/initializers/reducto_ai.rb`:

```ruby
ReductoAI.configure do |c|
  c.api_key = Rails.application.credentials.dig(:reducto, :api_key)
  # c.base_url = "https://platform.reducto.ai"
  # c.open_timeout = 5; c.read_timeout = 30
end

# Optional: override shared client (multi-tenant or custom timeouts)
# ReductoAI.client = ReductoAI::Client.new(api_key: ..., read_timeout: 10)
```

### Quick Start

```ruby
client = ReductoAI::Client.new

# Parse a document
# API Reference: https://docs.reducto.ai/api-reference/parse
parse = client.parse.sync(input: "https://example.com/invoice.pdf")
job_id = parse["job_id"]

# Response:
# {
#   "job_id" => "abc-123",
#   "status" => "complete",
#   "result" => {...}
# }

# Extract structured data
# API Reference: https://docs.reducto.ai/api-reference/extract
extraction = client.extract.sync(
  input: job_id,
  instructions: {
    schema: {
      type: "object",
      properties: {
        invoice_number: { type: "string" },
        total_due: { type: "string" }
      },
      required: ["invoice_number", "total_due"]
    }
  }
)

# Response:
# {
#   "job_id" => "820dca1b-3215-4d24-be09-6494d4c3cd88",
#   "usage" => {"num_pages" => 1, "num_fields" => 2, "credits" => 2.0},
#   "studio_link" => "https://studio.reducto.ai/job/820dca1b-3115-4d24-be09-6494d4c3cd88",
#   "result" => [{"invoice_number" => "INV-2024-001", "total_due" => "$1,234.56"}],
#   "citations" => nil
# }
```

### Complete Example: Multi-invoice Processing

```ruby
client = ReductoAI::Client.new

# 1. Parse the document
# API Reference: https://docs.reducto.ai/api-reference/parse
parse = client.parse.sync(input: "https://example.com/invoices.pdf")

# Response:
# {
#   "job_id" => "parse-123",
#   "status" => "complete",
#   "result" => {...}
# }

# 2. Split into individual invoices
# API Reference: https://docs.reducto.ai/api-reference/split
split = client.split.sync(
  input: parse["job_id"],
  split_description: [
    {
      name: "Invoice",
      description: "All pages that belong to a single invoice",
      partition_key: "invoice_number"
    }
  ],
  split_rules: <<~PROMPT
    The document contains multiple invoices one after another. Each invoice has a unique invoice number formatted like "Invoice #12345" near the top of the first page.
    Segment the document into one partition per invoice. Keep pages contiguous per invoice and include any following appendices until the next invoice number.
    Name each partition using the exact invoice number you detect (e.g., "Invoice #12345").
  PROMPT
)

# Response:
# {
#   "job_id" => "split-456",
#   "result" => {
#     "splits" => [{
#       "name" => "Invoice",
#       "partitions" => [
#         {"name" => "Invoice #12345", "pages" => [0, 1, 2]},
#         {"name" => "Invoice #12346", "pages" => [3, 4]}
#       ]
#     }]
#   }
# }

# 3. Extract data from each invoice
# API Reference: https://docs.reducto.ai/api-reference/extract
invoice_partitions = split.dig("result", "splits").first.fetch("partitions")
invoice_details = invoice_partitions.map do |partition|
  client.extract.sync(
    input: parse["job_id"],
    instructions: {
      schema: {
        type: "object",
        properties: {
          invoice_number: { type: "string" },
          total_due: { type: "string" }
        },
        required: ["invoice_number", "total_due"]
      }
    },
    settings: { page_range: partition["pages"] }
  )
end

# Response per invoice:
# {
#   "job_id" => "extract-789",
#   "result" => [{"invoice_number" => "INV-12345", "total_due" => "$2,500.00"}],
#   "usage" => {"credits" => 2.0}
# }
```

### Direct Split Example

Split a multi-invoice PDF directly without pre-parsing:

```ruby
client = ReductoAI::Client.new

# Split document directly from URL
# API Reference: https://docs.reducto.ai/api-reference/split
response = client.split.sync(
  input: { url: "https://example.com/invoices.pdf" },
  split_description: [
    {
      name: "Invoice",
      description: "Individual invoices within the document",
      partition_key: "invoice_number"
    }
  ]
)

# Response:
# {
#   "usage" => {"num_pages" => 2, "credits" => nil},
#   "result" => {
#     "section_mapping" => nil,
#     "splits" => [{
#       "name" => "Invoice",
#       "pages" => [1, 2],
#       "conf" => "high",
#       "partitions" => [
#         {"name" => "0000569050-001", "pages" => [1], "conf" => "high"},
#         {"name" => "0000569050-002", "pages" => [2], "conf" => "high"}
#       ]
#     }]
#   }
# }

# Access partitions
partitions = response.dig("result", "splits").first["partitions"]
# => [{"name"=>"0000569050-001", "pages"=>[1], "conf"=>"high"}, ...]
```

### Document Classification Example

```ruby
client = ReductoAI::Client.new

# Parse document
# API Reference: https://docs.reducto.ai/api-reference/parse
parse = client.parse.sync(input: "https://example.com/document.pdf")

# Extract with classification
# API Reference: https://docs.reducto.ai/api-reference/extract
extraction = client.extract.sync(
  input: parse["job_id"],
  instructions: {
    schema: {
      type: "object",
      properties: {
        document_type: {
          type: "string",
          enum: ["invoice", "credit", "debit"],
          description: "Document category"
        },
        document_number: {
          type: "string",
          description: "Invoice number or equivalent identifier"
        }
      },
      required: ["document_type", "document_number"]
    }
  },
  settings: { citations: { enabled: false } }
)

# Response:
# {
#   "job_id" => "class-123",
#   "result" => [{"document_type" => "invoice", "document_number" => "INV-2024-001"}],
#   "usage" => {"credits" => 2.0}
# }

document_type = extraction.dig("result", 0, "document_type")
document_number = extraction.dig("result", 0, "document_number")
```

### API Reference

Full endpoint details live in the [Reducto API documentation](https://docs.reducto.ai/).

### Best Practices: Cost-Efficient Document Processing

Follow these patterns to minimize credit usage when processing documents:

#### 1. Parse Once, Reuse Everywhere

**❌ Expensive:** Calling extract/split with URLs directly

```ruby
# DON'T: Each operation parses the document again
extract1 = client.extract.sync(input: url, instructions: schema_a)  # Parse + Extract = 2 credits
extract2 = client.extract.sync(input: url, instructions: schema_b)  # Parse + Extract = 2 credits
split = client.split.sync(input: url, split_description: [...])     # Parse + Split = 3 credits
# Total: 7 credits for a 1-page document
```

**✅ Cost-efficient:** Parse once, reuse `job_id`

```ruby
# DO: Parse once, reuse the job_id
parse = client.parse.sync(input: url)                              # 1 credit
job_id = parse["job_id"]

extract1 = client.extract.sync(input: job_id, instructions: schema_a)  # 1 credit
extract2 = client.extract.sync(input: job_id, instructions: schema_b)  # 1 credit
split = client.split.sync(input: job_id, split_description: [...])     # 2 credits
# Total: 5 credits for a 1-page document (saved 2 credits)
```

#### 2. Split Before Extract for Multi-Document Files

**✅ Best practice:** Split first, then extract per partition

```ruby
# 1. Parse the document once
parse = client.parse.sync(input: "multi-invoice.pdf")  # 1 credit × 10 pages = 10 credits
job_id = parse["job_id"]

# 2. Split into partitions
split = client.split.sync(
  input: job_id,
  split_description: [{ name: "Invoice", description: "..." }]
)  # 2 credits × 10 pages = 20 credits

# 3. Extract only from specific partitions
partitions = split.dig("result", "splits").first["partitions"]
invoices = partitions.map do |partition|
  client.extract.sync(
    input: job_id,
    instructions: { schema: invoice_schema },
    settings: { page_range: partition["pages"] }  # Extract only relevant pages
  )
end  # 1 credit × 10 pages = 10 credits

# Total: 40 credits for 10-page document with 5 invoices
```

#### 3. Use Async for Large Documents

**✅ For documents > 10 pages:** Use async to avoid timeouts

```ruby
# Parse async for large files
job = client.parse.async(input: large_pdf_url)
job_id = job["job_id"]

# Poll or use webhooks
loop do
  result = client.jobs.retrieve(job_id: job_id)
  break if result["status"] == "complete"
  sleep 2
end

# Then reuse the job_id for split/extract
split = client.split.sync(input: job_id, split_description: [...])
```

#### 4. Store and Reuse Parse Results

**✅ For repeated processing:** Store `job_id` to avoid re-parsing

```ruby
# Store the job_id with your document record
document.update(reducto_job_id: parse["job_id"])

# Later: Extract different schemas without re-parsing
schema_v1 = client.extract.sync(input: document.reducto_job_id, instructions: schema_v1)
schema_v2 = client.extract.sync(input: document.reducto_job_id, instructions: schema_v2)
# Only 2 credits instead of 4
```

#### Credit Math Summary

| Operation | Direct URL | With job_id | Savings |
|-----------|-----------|-------------|---------|
| Parse | 1 credit/page | N/A | - |
| Extract | 2 credits/page | 1 credit/page | 50% |
| Split | 3 credits/page | 2 credits/page | 33% |
| Multiple extracts (3×) | 6 credits/page | 3 credits/page | 50% |

**Golden rule:** Always parse once and reuse `job_id` for all subsequent operations.

### Credits & pricing overview

Reducto bills every API call in credits. Current public rates are:

- **Parse**: 1 credit per standard page (2 for complex VLM-enhanced pages).
- **Extract**: 2 credits per page (4 if agent-in-loop mode is enabled). Parsing credits are also charged if you **don't** reuse a previous `job_id`.
- **Split**: 2 credits per page when run standalone; free if you supply a prior parse job.
- **Edit**: 4 credits per page (beta pricing).

You can process ~15k credits/month before overages; additional credits are billed at **$0.015 USD** each according to [Reducto's pricing page](https://reducto.ai/pricing).

#### Why Extract costs 2 credits for 1 page

When you call `extract.sync(input: url, instructions: schema)` with a URL instead of a `job_id`, Reducto automatically performs two operations:

1. **Parse** (1 credit): Converts PDF → structured text
2. **Extract** (1 credit): Applies schema → structured JSON
3. **Total: 2 credits**

**Cost optimization:** Parse once, extract multiple times:

```ruby
# Parse once (1 credit)
parse = client.parse.sync(input: "https://example.com/doc.pdf")
job_id = parse["job_id"]

# Extract multiple schemas (1 credit each)
schema_a = client.extract.sync(input: job_id, instructions: schema_a)
schema_b = client.extract.sync(input: job_id, instructions: schema_b)
# Total: 3 credits instead of 4
```

#### Credit math for the examples above

- **Parse → Split → Extract**: when you start with `ReductoAI.parse` and pass the resulting `job_id` to `split` and `extract`, you pay **1 + 2** = **3 credits per page** (parse + extract). Split reuses the parsed content so it doesn't add extra parse credits.
- **Document type + number extraction**: the JSON-schema `extract` call uses an existing parse job, so it consumes **parse (1) + extract (2) = 3 credits per page**. Enabling agentic or citations may raise the per-page cost per the [credit usage guide](https://docs.reducto.ai/faq/credit-usage-overview).

## Development

```
bundle exec rake test
bundle exec rubocop
```

## TODO

- [ ] Document webhook workflow and retry semantics

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/dpaluy/reducto_ai.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
