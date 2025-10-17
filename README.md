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

### Async variants

All core actions also expose async helpers (`parse_async`, `split_async`, `extract_async`, `edit_async`, `pipeline_async`) that return a `job_id`. Poll results with `ReductoAI.retrieve_parse(job_id: ...)` or subscribe via webhooks (`configure_webhook`).

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

### Module helpers

```ruby
parse = ReductoAI.parse(input: "https://example.com/invoices.pdf")

split = ReductoAI.split(
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

invoice_partitions = split.dig("result", "splits").first.fetch("partitions")
invoice_numbers = invoice_partitions.map { |partition| partition["name"] }

invoice_details = invoice_partitions.map do |partition|
  ReductoAI.extract(
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
```

#### Example: classify document type and number

```ruby
parse = ReductoAI.parse(input: "https://example.com/invoice.pdf")

extraction = ReductoAI.extract(
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

document_type = extraction.dig("result", 0, "document_type")
document_number = extraction.dig("result", 0, "document_number")
```

### Action classes

```ruby
client = ReductoAI::Client.new

parse_action = ReductoAI::Actions::Parse.new(client: client)
parse_action.call(input: "doc", enhance: { summarize_figures: true })
```

### API Reference

Full endpoint details live in the [Reducto API documentation](https://docs.reducto.ai/).

### Credits & pricing overview

Reducto bills every API call in credits. Current public rates are:

- **Parse**: 1 credit per standard page (2 for complex VLM-enhanced pages).
- **Extract**: 2 credits per page (4 if agent-in-loop mode is enabled). Parsing credits are also charged if you **don’t** reuse a previous `job_id`.
- **Split**: 2 credits per page when run standalone; free if you supply a prior parse job.
- **Edit**: 4 credits per page (beta pricing).

You can process ~15k credits/month before overages; additional credits are billed at **$0.015 USD** each according to [Reducto’s pricing page](https://reducto.ai/pricing).

#### Credit math for the examples above

- **Parse → Split → Extract**: when you start with `ReductoAI.parse` and pass the resulting `job_id` to `split` and `extract`, you pay **1 + 2** = **3 credits per page** (parse + extract). Split reuses the parsed content so it doesn’t add extra parse credits.
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
